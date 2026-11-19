import 'dart:math';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/round_rest_entity.dart';
import '../../domain/repositories/match_repository.dart';
import '../../domain/services/schedule_generator.dart';
import '../datasources/match_remote_data_source.dart';
import '../models/match_dto.dart';
import '../models/round_rest_dto.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;
  final TeamRepository teamRepository;

  MatchRepositoryImpl({
    required this.remoteDataSource,
    required this.teamRepository,
  });

  @override
  Future<Either<Failure, List<MatchEntity>>> getMatches({
    required String tournamentId,
    int? round,
  }) async {
    try {
      final dtos = await remoteDataSource.getMatches(tournamentId, round: round);
      final entities = dtos.map((d) => d.toEntity()).toList();
      return Right(entities);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoundRestEntity>>> getRoundRests({
    required String tournamentId,
  }) async {
    try {
      final dtos = await remoteDataSource.getRoundRests(tournamentId);
      final entities = dtos.map((d) => d.toEntity()).toList();
      return Right(entities);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduleGenerationResult>> generateNextRound({
    required String tournamentId,
  }) async {
    try {
      // 1. Get active teams
      final teamsResult = await teamRepository.getTeams(includeArchived: false);
      final List<TeamEntity> teams = teamsResult.fold((l) => [], (r) => r);

      if (teams.length < 2) {
        return const Left(ValidationFailure('O‘yinlar yaratish uchun kamida 2 ta jamoa kerak'));
      }

      // 2. Get existing matches & rests
      final existingMatchesDtos = await remoteDataSource.getMatches(tournamentId);
      final existingRestsDtos = await remoteDataSource.getRoundRests(tournamentId);

      final existingMatches = existingMatchesDtos.map((d) => d.toEntity()).toList();
      final existingRests = existingRestsDtos.map((d) => d.toEntity()).toList();

      final targetRound = existingMatches.isEmpty
          ? 1
          : (existingMatches.map((m) => m.round).reduce(max) + 1);

      // 3. Generate round
      final result = ScheduleGenerator.generateRound(
        tournamentId: tournamentId,
        targetRound: targetRound,
        teams: teams,
        existingMatches: existingMatches,
        existingRests: existingRests,
      );

      // 4. Save to database
      final matchDtos = result.matches.map((m) => MatchDto.fromEntity(m)).toList();
      await remoteDataSource.saveMatches(matchDtos);

      if (result.restingTeam != null) {
        final restDto = RoundRestDto(
          id: const Uuid().v4(),
          tournamentId: tournamentId,
          round: targetRound,
          teamId: result.restingTeam!.id,
          createdAt: DateTime.now().toIso8601String(),
        );
        await remoteDataSource.saveRoundRest(restDto);
      }

      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleGenerationResult>>> generateFullSchedule({
    required String tournamentId,
    int totalRounds = 22,
  }) async {
    try {
      final teamsResult = await teamRepository.getTeams(includeArchived: false);
      final List<TeamEntity> teams = teamsResult.fold((l) => [], (r) => r);

      if (teams.length < 2) {
        return const Left(ValidationFailure('O‘yinlar yaratish uchun kamida 2 ta jamoa kerak'));
      }

      final existingMatchesDtos = await remoteDataSource.getMatches(tournamentId);
      final existingRestsDtos = await remoteDataSource.getRoundRests(tournamentId);

      List<MatchEntity> accumulatedMatches =
          existingMatchesDtos.map((d) => d.toEntity()).toList();
      List<RoundRestEntity> accumulatedRests =
          existingRestsDtos.map((d) => d.toEntity()).toList();

      final startRound = accumulatedMatches.isEmpty
          ? 1
          : (accumulatedMatches.map((m) => m.round).reduce(max) + 1);

      final List<ScheduleGenerationResult> results = [];

      for (int round = startRound; round < startRound + totalRounds; round++) {
        final roundResult = ScheduleGenerator.generateRound(
          tournamentId: tournamentId,
          targetRound: round,
          teams: teams,
          existingMatches: accumulatedMatches,
          existingRests: accumulatedRests,
        );

        final matchDtos = roundResult.matches.map((m) => MatchDto.fromEntity(m)).toList();
        await remoteDataSource.saveMatches(matchDtos);
        accumulatedMatches.addAll(roundResult.matches);

        if (roundResult.restingTeam != null) {
          final rest = RoundRestEntity(
            id: const Uuid().v4(),
            tournamentId: tournamentId,
            round: round,
            teamId: roundResult.restingTeam!.id,
            createdAt: DateTime.now(),
          );
          accumulatedRests.add(rest);
          await remoteDataSource.saveRoundRest(RoundRestDto.fromEntity(rest));
        }

        results.add(roundResult);
      }

      return Right(results);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduleGenerationResult>> randomizeUpcomingMatches({
    required String tournamentId,
    required int round,
  }) async {
    try {
      final teamsResult = await teamRepository.getTeams(includeArchived: false);
      final List<TeamEntity> teams = teamsResult.fold((l) => [], (r) => r);

      // Check if there are live or finished matches in this round
      final currentRoundMatches = await remoteDataSource.getMatches(tournamentId, round: round);
      final hasCompletedOrLive = currentRoundMatches.any(
        (m) => m.status == 'finished' || m.status == 'live',
      );

      if (hasCompletedOrLive) {
        return const Left(ValidationFailure(
          'Ushbu turda tugallangan yoki jonli o‘yinlar bor. Faqat kutilayotgan o‘yinlar qayta taqsimlanishi mumkin.',
        ));
      }

      // Delete upcoming matches & rest for this round
      await remoteDataSource.deleteUpcomingMatchesForRound(tournamentId, round);
      await remoteDataSource.deleteRoundRest(tournamentId, round);

      // Fetch all matches from other rounds to use as history
      final allMatchesDtos = await remoteDataSource.getMatches(tournamentId);
      final allRestsDtos = await remoteDataSource.getRoundRests(tournamentId);

      final otherMatches = allMatchesDtos
          .where((m) => m.round != round)
          .map((d) => d.toEntity())
          .toList();
      final otherRests = allRestsDtos
          .where((r) => r.round != round)
          .map((d) => d.toEntity())
          .toList();

      final result = ScheduleGenerator.generateRound(
        tournamentId: tournamentId,
        targetRound: round,
        teams: teams,
        existingMatches: otherMatches,
        existingRests: otherRests,
      );

      final matchDtos = result.matches.map((m) => MatchDto.fromEntity(m)).toList();
      await remoteDataSource.saveMatches(matchDtos);

      if (result.restingTeam != null) {
        final restDto = RoundRestDto(
          id: const Uuid().v4(),
          tournamentId: tournamentId,
          round: round,
          teamId: result.restingTeam!.id,
          createdAt: DateTime.now().toIso8601String(),
        );
        await remoteDataSource.saveRoundRest(restDto);
      }

      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> updateMatchScore({
    required String matchId,
    required int? homeScore,
    required int? awayScore,
    required MatchStatus status,
  }) async {
    try {
      await remoteDataSource.updateMatchScore(
        matchId,
        homeScore,
        awayScore,
        status.toDbString(),
      );

      // Return refreshed entity
      final matches = await remoteDataSource.getMatches(AppConstants.defaultTournamentId);
      final updated = matches.firstWhere((m) => m.id == matchId);
      return Right(updated.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> updateMatchTimeSlot({
    required String matchId,
    required String newTimeSlot,
    required int newSlotIndex,
  }) async {
    try {
      await remoteDataSource.updateMatchTimeSlot(matchId, newTimeSlot, newSlotIndex);
      final matches = await remoteDataSource.getMatches(AppConstants.defaultTournamentId);
      final updated = matches.firstWhere((m) => m.id == matchId);
      return Right(updated.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMatch(String matchId) async {
    try {
      await remoteDataSource.deleteMatch(matchId);
      return const Right(true);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteRound({
    required String tournamentId,
    required int round,
  }) async {
    try {
      await remoteDataSource.deleteRound(tournamentId, round);
      return const Right(true);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resetTournament(String tournamentId) async {
    try {
      await remoteDataSource.resetTournament(tournamentId);
      return const Right(true);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

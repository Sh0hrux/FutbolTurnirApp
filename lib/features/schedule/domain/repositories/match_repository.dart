import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/match_entity.dart';
import '../entities/round_rest_entity.dart';
import '../services/schedule_generator.dart';

abstract class MatchRepository {
  Future<Either<Failure, List<MatchEntity>>> getMatches({
    required String tournamentId,
    int? round,
  });

  Future<Either<Failure, List<RoundRestEntity>>> getRoundRests({
    required String tournamentId,
  });

  Future<Either<Failure, ScheduleGenerationResult>> generateNextRound({
    required String tournamentId,
  });

  Future<Either<Failure, List<ScheduleGenerationResult>>> generateFullSchedule({
    required String tournamentId,
    int totalRounds = 22,
  });

  Future<Either<Failure, ScheduleGenerationResult>> randomizeUpcomingMatches({
    required String tournamentId,
    required int round,
  });

  Future<Either<Failure, MatchEntity>> updateMatchScore({
    required String matchId,
    required int? homeScore,
    required int? awayScore,
    required MatchStatus status,
  });

  Future<Either<Failure, MatchEntity>> updateMatchTimeSlot({
    required String matchId,
    required String newTimeSlot,
    required int newSlotIndex,
  });

  Future<Either<Failure, bool>> deleteMatch(String matchId);

  Future<Either<Failure, bool>> deleteRound({
    required String tournamentId,
    required int round,
  });

  Future<Either<Failure, bool>> resetTournament(String tournamentId);
}

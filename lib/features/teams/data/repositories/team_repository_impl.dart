import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_data_source.dart';
import '../models/team_dto.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteDataSource remoteDataSource;

  TeamRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TeamEntity>>> getTeams({
    int page = 1,
    int limit = 50,
    bool includeArchived = false,
  }) async {
    try {
      final dtos = await remoteDataSource.getTeams(
        page: page,
        limit: limit,
        includeArchived: includeArchived,
      );
      final entities = dtos.map((dto) => dto.toEntity()).toList();
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
  Future<Either<Failure, TeamEntity>> getTeamById(String id) async {
    try {
      final dto = await remoteDataSource.getTeamById(id);
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> createTeam({
    required String name,
    required int colorValue,
    String? logoPath,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final dto = TeamDto(
        id: const Uuid().v4(),
        name: name.trim(),
        colorValue: colorValue,
        logoPath: logoPath,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
      final createdDto = await remoteDataSource.createTeam(dto);
      return Right(createdDto.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> updateTeam(TeamEntity team) async {
    try {
      final updatedTeam = team.copyWith(updatedAt: DateTime.now());
      final dto = TeamDto.fromEntity(updatedTeam);
      final resultDto = await remoteDataSource.updateTeam(dto);
      return Right(resultDto.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteOrArchiveTeam(String teamId, {bool forceArchive = false}) async {
    try {
      final result = await remoteDataSource.deleteOrArchiveTeam(teamId, forceArchive: forceArchive);
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
  Future<Either<Failure, bool>> unarchiveTeam(String teamId) async {
    try {
      final result = await remoteDataSource.unarchiveTeam(teamId);
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
  Future<Either<Failure, bool>> hasTeamPlayedMatches(String teamId) async {
    try {
      final result = await remoteDataSource.hasTeamPlayedMatches(teamId);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}


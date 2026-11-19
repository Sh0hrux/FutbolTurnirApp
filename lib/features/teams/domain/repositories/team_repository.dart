import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/team_entity.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<TeamEntity>>> getTeams({
    int page = 1,
    int limit = 50,
    bool includeArchived = false,
  });

  Future<Either<Failure, TeamEntity>> getTeamById(String id);

  Future<Either<Failure, TeamEntity>> createTeam({
    required String name,
    required int colorValue,
    String? logoPath,
  });

  Future<Either<Failure, TeamEntity>> updateTeam(TeamEntity team);

  /// Checks if team has matches: if yes, archives it; if no, permanently deletes it.
  Future<Either<Failure, bool>> deleteOrArchiveTeam(String teamId, {bool forceArchive = false});

  Future<Either<Failure, bool>> unarchiveTeam(String teamId);

  Future<Either<Failure, bool>> hasTeamPlayedMatches(String teamId);
}


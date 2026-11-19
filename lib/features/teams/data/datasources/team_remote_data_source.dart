import '../models/team_dto.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamDto>> getTeams({int page = 1, int limit = 50, bool includeArchived = false});
  Future<TeamDto> getTeamById(String id);
  Future<TeamDto> createTeam(TeamDto team);
  Future<TeamDto> updateTeam(TeamDto team);
  Future<bool> deleteOrArchiveTeam(String teamId, {bool forceArchive = false});
  Future<bool> unarchiveTeam(String teamId);
  Future<bool> hasTeamPlayedMatches(String teamId);
}


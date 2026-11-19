import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../models/team_dto.dart';

abstract class TeamLocalDataSource {
  Future<List<TeamDto>> getTeams({int page = 1, int limit = 50, bool includeArchived = false});
  Future<TeamDto?> getTeamById(String id);
  Future<TeamDto> insertTeam(TeamDto team);
  Future<TeamDto> updateTeam(TeamDto team);
  Future<bool> hasTeamPlayedAnyMatch(String teamId);
  Future<void> archiveTeam(String teamId);
  Future<void> unarchiveTeam(String teamId);
  Future<void> deleteTeamPermanently(String teamId);
}

class TeamLocalDataSourceImpl implements TeamLocalDataSource {
  final AppDatabase database;

  TeamLocalDataSourceImpl({required this.database});

  @override
  Future<List<TeamDto>> getTeams({
    int page = 1,
    int limit = 50,
    bool includeArchived = false,
  }) async {
    final teams = await database.getAllTeams(includeArchived: includeArchived);
    // Apply pagination in-memory or limit/offset
    final startIndex = (page - 1) * limit;
    if (startIndex >= teams.length) return [];
    final endIndex = (startIndex + limit).clamp(0, teams.length);
    final paged = teams.sublist(startIndex, endIndex);

    return paged.map((t) => TeamDto.fromDrift(t)).toList();
  }

  @override
  Future<TeamDto?> getTeamById(String id) async {
    final team = await database.getTeamById(id);
    if (team == null) return null;
    return TeamDto.fromDrift(team);
  }

  @override
  Future<TeamDto> insertTeam(TeamDto team) async {
    final entry = TeamsCompanion.insert(
      id: team.id,
      name: team.name,
      colorValue: team.colorValue,
      logoPath: Value(team.logoPath),
      isArchived: Value(team.isArchived),
      createdAt: DateTime.parse(team.createdAt),
      updatedAt: DateTime.parse(team.updatedAt),
    );
    await database.insertTeam(entry);
    return team;
  }

  @override
  Future<TeamDto> updateTeam(TeamDto team) async {
    final row = Team(
      id: team.id,
      name: team.name,
      colorValue: team.colorValue,
      logoPath: team.logoPath,
      isArchived: team.isArchived,
      createdAt: DateTime.parse(team.createdAt),
      updatedAt: DateTime.parse(team.updatedAt),
    );
    await database.updateTeam(row);
    return team;
  }

  @override
  Future<bool> hasTeamPlayedAnyMatch(String teamId) {
    return database.hasTeamPlayedAnyMatch(teamId);
  }

  @override
  Future<void> archiveTeam(String teamId) async {
    await database.archiveTeam(teamId);
  }

  @override
  Future<void> unarchiveTeam(String teamId) async {
    await database.unarchiveTeam(teamId);
  }

  @override
  Future<void> deleteTeamPermanently(String teamId) async {
    await database.deleteTeamPermanently(teamId);
  }
}


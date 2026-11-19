import 'dart:math';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/team_dto.dart';
import 'team_local_data_source.dart';
import 'team_remote_data_source.dart';

class MockTeamRemoteDataSource implements TeamRemoteDataSource {
  final TeamLocalDataSource localDataSource;
  final Random _random = Random();

  MockTeamRemoteDataSource({required this.localDataSource});

  Future<void> _simulateNetwork() async {
    int delay = AppConfig.artificialDelayMs;
    if (AppConfig.simulateErrors) {
      delay += 250 + _random.nextInt(350); // 300-800ms when simulating errors
    } else {
      delay = delay.clamp(0, 150); // Fast 0-150ms by default
    }
    if (delay > 0) {
      await Future.delayed(Duration(milliseconds: delay));
    }

    // Simulated error check
    if (AppConfig.simulateErrors) {
      if (_random.nextBool()) {
        throw const NetworkFailureException();
      } else {
        throw const ServerException('Serverda vaqtincha nosozlik (Simulyatsiya)');
      }
    }
  }

  @override
  Future<List<TeamDto>> getTeams({
    int page = 1,
    int limit = 50,
    bool includeArchived = false,
  }) async {
    await _simulateNetwork();
    return localDataSource.getTeams(
      page: page,
      limit: limit,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<TeamDto> getTeamById(String id) async {
    await _simulateNetwork();
    final team = await localDataSource.getTeamById(id);
    if (team == null) {
      throw const NotFoundException('Jamoa topilmadi');
    }
    return team;
  }

  @override
  Future<TeamDto> createTeam(TeamDto team) async {
    await _simulateNetwork();
    return localDataSource.insertTeam(team);
  }

  @override
  Future<TeamDto> updateTeam(TeamDto team) async {
    await _simulateNetwork();
    return localDataSource.updateTeam(team);
  }

  @override
  Future<bool> deleteOrArchiveTeam(String teamId, {bool forceArchive = false}) async {
    await _simulateNetwork();
    final hasMatches = await localDataSource.hasTeamPlayedAnyMatch(teamId);
    if (hasMatches || forceArchive) {
      await localDataSource.archiveTeam(teamId);
      return true; // Archived
    } else {
      await localDataSource.deleteTeamPermanently(teamId);
      return false; // Permanently deleted
    }
  }

  @override
  Future<bool> unarchiveTeam(String teamId) async {
    await _simulateNetwork();
    await localDataSource.unarchiveTeam(teamId);
    return true;
  }

  @override
  Future<bool> hasTeamPlayedMatches(String teamId) async {
    await _simulateNetwork();
    return localDataSource.hasTeamPlayedAnyMatch(teamId);
  }
}

class NetworkFailureException extends NetworkException {
  const NetworkFailureException([super.message = 'Tarmoq bilan aloqa yo‘q']);
}


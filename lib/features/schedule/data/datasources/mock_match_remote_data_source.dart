import 'dart:math';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/match_dto.dart';
import '../models/round_rest_dto.dart';
import 'match_local_data_source.dart';
import 'match_remote_data_source.dart';

class MockMatchRemoteDataSource implements MatchRemoteDataSource {
  final MatchLocalDataSource localDataSource;
  final Random _random = Random();

  MockMatchRemoteDataSource({required this.localDataSource});

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

    if (AppConfig.simulateErrors) {
      if (_random.nextBool()) {
        throw const NetworkException('Tarmoq uzilishi yuz berdi (Simulyatsiya)');
      } else {
        throw const ServerException('Server o‘yin ma‘lumotlarini qayta ishlay olmadi');
      }
    }
  }

  @override
  Future<List<MatchDto>> getMatches(String tournamentId, {int? round}) async {
    await _simulateNetwork();
    return localDataSource.getMatches(tournamentId, round: round);
  }

  @override
  Future<List<RoundRestDto>> getRoundRests(String tournamentId) async {
    await _simulateNetwork();
    return localDataSource.getRoundRests(tournamentId);
  }

  @override
  Future<void> saveMatches(List<MatchDto> matches) async {
    await _simulateNetwork();
    await localDataSource.insertMatches(matches);
  }

  @override
  Future<void> saveRoundRest(RoundRestDto rest) async {
    await _simulateNetwork();
    await localDataSource.insertRoundRest(rest);
  }

  @override
  Future<void> updateMatchScore(
    String matchId,
    int? homeScore,
    int? awayScore,
    String status,
  ) async {
    await _simulateNetwork();
    await localDataSource.updateMatchScore(matchId, homeScore, awayScore, status);
  }

  @override
  Future<void> updateMatchTimeSlot(
    String matchId,
    String newTimeSlot,
    int newSlotIndex,
  ) async {
    await _simulateNetwork();
    await localDataSource.updateMatchTimeSlot(matchId, newTimeSlot, newSlotIndex);
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await _simulateNetwork();
    await localDataSource.deleteMatch(matchId);
  }

  @override
  Future<void> deleteUpcomingMatchesForRound(String tournamentId, int round) async {
    await _simulateNetwork();
    await localDataSource.deleteUpcomingMatchesForRound(tournamentId, round);
  }

  @override
  Future<void> deleteRoundRest(String tournamentId, int round) async {
    await _simulateNetwork();
    await localDataSource.deleteRoundRest(tournamentId, round);
  }

  @override
  Future<void> deleteRound(String tournamentId, int round) async {
    await _simulateNetwork();
    await localDataSource.deleteRound(tournamentId, round);
  }

  @override
  Future<void> resetTournament(String tournamentId) async {
    await _simulateNetwork();
    await localDataSource.resetTournament(tournamentId);
  }
}

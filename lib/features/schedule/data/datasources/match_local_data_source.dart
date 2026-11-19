import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../models/match_dto.dart';
import '../models/round_rest_dto.dart';

abstract class MatchLocalDataSource {
  Future<List<MatchDto>> getMatches(String tournamentId, {int? round});
  Future<List<RoundRestDto>> getRoundRests(String tournamentId);
  Future<void> insertMatches(List<MatchDto> matches);
  Future<void> insertRoundRest(RoundRestDto rest);
  Future<void> updateMatchScore(String matchId, int? homeScore, int? awayScore, String status);
  Future<void> updateMatchTimeSlot(String matchId, String newTimeSlot, int newSlotIndex);
  Future<void> deleteMatch(String matchId);
  Future<void> deleteUpcomingMatchesForRound(String tournamentId, int round);
  Future<void> deleteRoundRest(String tournamentId, int round);
  Future<void> deleteRound(String tournamentId, int round);
  Future<void> resetTournament(String tournamentId);
}

class MatchLocalDataSourceImpl implements MatchLocalDataSource {
  final AppDatabase database;

  MatchLocalDataSourceImpl({required this.database});

  @override
  Future<List<MatchDto>> getMatches(String tournamentId, {int? round}) async {
    final List<Matche> rows;
    if (round != null) {
      rows = await database.getMatchesByRound(tournamentId, round);
    } else {
      rows = await database.getMatchesForTournament(tournamentId);
    }
    return rows.map((r) => MatchDto.fromDrift(r)).toList();
  }

  @override
  Future<List<RoundRestDto>> getRoundRests(String tournamentId) async {
    final rows = await database.getAllRests(tournamentId);
    return rows.map((r) => RoundRestDto.fromDrift(r)).toList();
  }

  @override
  Future<void> insertMatches(List<MatchDto> matches) async {
    final entries = matches.map((m) {
      return MatchesCompanion.insert(
        id: m.id,
        tournamentId: m.tournamentId,
        round: m.round,
        slotIndex: m.slotIndex,
        timeSlot: m.timeSlot,
        homeTeamId: m.homeTeamId,
        awayTeamId: m.awayTeamId,
        homeScore: Value(m.homeScore),
        awayScore: Value(m.awayScore),
        status: m.status,
        createdAt: DateTime.parse(m.createdAt),
        updatedAt: DateTime.parse(m.updatedAt),
      );
    }).toList();

    await database.insertMatchesBatch(entries);
  }

  @override
  Future<void> insertRoundRest(RoundRestDto rest) async {
    final entry = RoundRestsCompanion.insert(
      id: rest.id,
      tournamentId: rest.tournamentId,
      round: rest.round,
      teamId: rest.teamId,
      createdAt: DateTime.parse(rest.createdAt),
    );
    await database.insertRoundRest(entry);
  }

  @override
  Future<void> updateMatchScore(
    String matchId,
    int? homeScore,
    int? awayScore,
    String status,
  ) async {
    await database.updateMatchResult(
      matchId: matchId,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    );
  }

  @override
  Future<void> updateMatchTimeSlot(
    String matchId,
    String newTimeSlot,
    int newSlotIndex,
  ) async {
    await database.updateMatchTimeSlot(
      matchId: matchId,
      newTimeSlot: newTimeSlot,
      newSlotIndex: newSlotIndex,
    );
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await database.deleteMatch(matchId);
  }

  @override
  Future<void> deleteUpcomingMatchesForRound(String tournamentId, int round) async {
    await database.deleteUpcomingMatchesForRound(tournamentId, round);
  }

  @override
  Future<void> deleteRoundRest(String tournamentId, int round) async {
    await database.deleteRoundRest(tournamentId, round);
  }

  @override
  Future<void> deleteRound(String tournamentId, int round) async {
    await database.deleteEntireRound(tournamentId, round);
  }

  @override
  Future<void> resetTournament(String tournamentId) async {
    await database.resetTournament(tournamentId);
  }
}

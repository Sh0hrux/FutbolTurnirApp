import '../models/match_dto.dart';
import '../models/round_rest_dto.dart';

abstract class MatchRemoteDataSource {
  Future<List<MatchDto>> getMatches(String tournamentId, {int? round});
  Future<List<RoundRestDto>> getRoundRests(String tournamentId);
  Future<void> saveMatches(List<MatchDto> matches);
  Future<void> saveRoundRest(RoundRestDto rest);
  Future<void> updateMatchScore(String matchId, int? homeScore, int? awayScore, String status);
  Future<void> updateMatchTimeSlot(String matchId, String newTimeSlot, int newSlotIndex);
  Future<void> deleteMatch(String matchId);
  Future<void> deleteUpcomingMatchesForRound(String tournamentId, int round);
  Future<void> deleteRoundRest(String tournamentId, int round);
  Future<void> deleteRound(String tournamentId, int round);
  Future<void> resetTournament(String tournamentId);
}

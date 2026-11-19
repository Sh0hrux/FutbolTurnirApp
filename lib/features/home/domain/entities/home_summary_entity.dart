import 'package:equatable/equatable.dart';
import '../../../schedule/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standing_row_entity.dart';
import '../../../teams/domain/entities/team_entity.dart';

class HomeSummaryEntity extends Equatable {
  final String tournamentName;
  final int totalTeamsCount;
  final int totalMatchesCount;
  final int finishedMatchesCount;
  final MatchEntity? nextMatch;
  final int? nextRoundNumber;
  final List<StandingRowEntity> top3Standings;
  final List<MatchEntity> recentFinishedMatches;
  final Map<String, TeamEntity> teamsMap;

  const HomeSummaryEntity({
    required this.tournamentName,
    required this.totalTeamsCount,
    required this.totalMatchesCount,
    required this.finishedMatchesCount,
    this.nextMatch,
    this.nextRoundNumber,
    required this.top3Standings,
    required this.recentFinishedMatches,
    required this.teamsMap,
  });

  @override
  List<Object?> get props => [
        tournamentName,
        totalTeamsCount,
        totalMatchesCount,
        finishedMatchesCount,
        nextMatch,
        nextRoundNumber,
        top3Standings,
        recentFinishedMatches,
        teamsMap,
      ];
}

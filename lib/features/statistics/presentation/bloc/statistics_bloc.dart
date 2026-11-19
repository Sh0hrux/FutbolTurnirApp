import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../schedule/domain/entities/match_entity.dart';
import '../../../schedule/domain/repositories/match_repository.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/tournament_statistics_entity.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final TeamRepository teamRepository;
  final MatchRepository matchRepository;

  StatisticsBloc({
    required this.teamRepository,
    required this.matchRepository,
  }) : super(const StatisticsInitial()) {
    on<LoadStatisticsEvent>(_onLoadStatistics);
  }

  Future<void> _onLoadStatistics(
    LoadStatisticsEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(const StatisticsLoading());

    final teamsRes = await teamRepository.getTeams(includeArchived: false);
    if (teamsRes.isLeft) {
      emit(StatisticsFailure(teamsRes.leftOrNull!.message));
      return;
    }
    final teams = teamsRes.rightOrNull!;

    final matchesRes = await matchRepository.getMatches(
      tournamentId: AppConstants.defaultTournamentId,
    );
    if (matchesRes.isLeft) {
      emit(StatisticsFailure(matchesRes.leftOrNull!.message));
      return;
    }
    final matches = matchesRes.rightOrNull!;

    // Filter to finished matches
    final finishedMatches = matches.where((m) =>
        m.status == MatchStatus.finished &&
        m.homeScore != null &&
        m.awayScore != null).toList();

    // Per-team counters
    final stats = <String, _TeamStatCalc>{};
    for (final t in teams) {
      stats[t.id] = _TeamStatCalc(team: t);
    }

    int totalGoals = 0;

    for (final m in finishedMatches) {
      final h = stats[m.homeTeamId];
      final a = stats[m.awayTeamId];

      if (h == null || a == null) continue;

      final hs = m.homeScore!;
      final asCore = m.awayScore!;
      totalGoals += (hs + asCore);

      h.played += 1;
      a.played += 1;

      h.goalsFor += hs;
      h.goalsAgainst += asCore;

      a.goalsFor += asCore;
      a.goalsAgainst += hs;

      if (hs > asCore) {
        h.won += 1;
        h.points += 3;
        a.lost += 1;
      } else if (hs == asCore) {
        h.drawn += 1;
        h.points += 1;
        a.drawn += 1;
        a.points += 1;
      } else {
        a.won += 1;
        a.points += 3;
        h.lost += 1;
      }
    }

    final statList = stats.values.toList();
    final playedTeams = statList.where((s) => s.played > 0).toList();

    TeamStatMetric? topScoring;
    TeamStatMetric? bestDefense;
    TeamStatMetric? mostWins;
    TeamStatMetric? mostLosses;
    TeamStatMetric? bestGD;
    TeamStatMetric? topPoints;

    if (playedTeams.isNotEmpty) {
      // 1. Top Scoring
      final sortedByGF = List<_TeamStatCalc>.from(playedTeams)
        ..sort((a, b) => b.goalsFor.compareTo(a.goalsFor));
      topScoring = TeamStatMetric(
        team: sortedByGF.first.team,
        value: sortedByGF.first.goalsFor,
        label: '${sortedByGF.first.goalsFor} ta gol',
      );

      // 2. Best Defense (least goals against)
      final sortedByGA = List<_TeamStatCalc>.from(playedTeams)
        ..sort((a, b) => a.goalsAgainst.compareTo(b.goalsAgainst));
      bestDefense = TeamStatMetric(
        team: sortedByGA.first.team,
        value: sortedByGA.first.goalsAgainst,
        label: '${sortedByGA.first.goalsAgainst} ta o‘tkazilgan',
      );

      // 3. Most Wins
      final sortedByWins = List<_TeamStatCalc>.from(playedTeams)
        ..sort((a, b) => b.won.compareTo(a.won));
      mostWins = TeamStatMetric(
        team: sortedByWins.first.team,
        value: sortedByWins.first.won,
        label: '${sortedByWins.first.won} ta g‘alaba',
      );

      // 4. Most Losses
      final sortedByLosses = List<_TeamStatCalc>.from(playedTeams)
        ..sort((a, b) => b.lost.compareTo(a.lost));
      mostLosses = TeamStatMetric(
        team: sortedByLosses.first.team,
        value: sortedByLosses.first.lost,
        label: '${sortedByLosses.first.lost} ta mag‘lubiyat',
      );

      // 5. Best Goal Difference
      final sortedByGD = List<_TeamStatCalc>.from(playedTeams)
        ..sort((a, b) => (b.goalsFor - b.goalsAgainst).compareTo(a.goalsFor - a.goalsAgainst));
      final gdVal = sortedByGD.first.goalsFor - sortedByGD.first.goalsAgainst;
      bestGD = TeamStatMetric(
        team: sortedByGD.first.team,
        value: gdVal,
        label: '${gdVal > 0 ? "+" : ""}$gdVal to‘plar farqi',
      );

      // 6. Top Points
      final sortedByPoints = List<_TeamStatCalc>.from(playedTeams)
        ..sort((a, b) => b.points.compareTo(a.points));
      topPoints = TeamStatMetric(
        team: sortedByPoints.first.team,
        value: sortedByPoints.first.points,
        label: '${sortedByPoints.first.points} ochko',
      );
    }

    final double avgGoals = finishedMatches.isEmpty
        ? 0.0
        : (totalGoals / finishedMatches.length);

    // Detailed team stats list
    statList.sort((a, b) => b.points.compareTo(a.points));
    final detailedStats = statList.map((s) {
      return DetailedTeamStat(
        team: s.team,
        played: s.played,
        won: s.won,
        drawn: s.drawn,
        lost: s.lost,
        goalsFor: s.goalsFor,
        goalsAgainst: s.goalsAgainst,
        goalDifference: s.goalsFor - s.goalsAgainst,
        points: s.points,
      );
    }).toList();

    emit(StatisticsSuccess(
      TournamentStatisticsEntity(
        topScoringTeam: topScoring,
        bestDefenseTeam: bestDefense,
        mostWinsTeam: mostWins,
        mostLossesTeam: mostLosses,
        bestGoalDiffTeam: bestGD,
        topPointsTeam: topPoints,
        totalGoals: totalGoals,
        totalMatchesPlayed: finishedMatches.length,
        averageGoalsPerMatch: avgGoals,
        teamStats: detailedStats,
      ),
    ));
  }
}

class _TeamStatCalc {
  final TeamEntity team;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;

  _TeamStatCalc({required this.team});
}

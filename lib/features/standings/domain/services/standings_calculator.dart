import '../../../schedule/domain/entities/match_entity.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../entities/standing_row_entity.dart';

class StandingsCalculator {
  /// Calculates the official tournament standings from teams and matches
  static List<StandingRowEntity> calculate({
    required List<TeamEntity> teams,
    required List<MatchEntity> matches,
  }) {
    // Filter to only finished matches with valid scores
    final finishedMatches = matches.where((m) =>
        m.status == MatchStatus.finished &&
        m.homeScore != null &&
        m.awayScore != null).toList();

    // Intermediate statistics per team
    final stats = <String, _TeamStat>{};
    for (final team in teams) {
      stats[team.id] = _TeamStat(
        teamId: team.id,
        teamName: team.name,
        colorValue: team.colorValue,
        logoPath: team.logoPath,
      );
    }

    // Accumulate match results
    for (final match in finishedMatches) {
      final homeStat = stats[match.homeTeamId];
      final awayStat = stats[match.awayTeamId];

      if (homeStat == null || awayStat == null) continue;

      final hScore = match.homeScore!;
      final aScore = match.awayScore!;

      homeStat.played += 1;
      awayStat.played += 1;

      homeStat.goalsFor += hScore;
      homeStat.goalsAgainst += aScore;

      awayStat.goalsFor += aScore;
      awayStat.goalsAgainst += hScore;

      if (hScore > aScore) {
        homeStat.won += 1;
        homeStat.points += 3;
        awayStat.lost += 1;
      } else if (hScore == aScore) {
        homeStat.drawn += 1;
        homeStat.points += 1;
        awayStat.drawn += 1;
        awayStat.points += 1;
      } else {
        awayStat.won += 1;
        awayStat.points += 3;
        homeStat.lost += 1;
      }
    }

    final statList = stats.values.toList();

    // Sort teams using official criteria:
    // 1. Points (descending)
    // 2. Goal Difference (descending)
    // 3. Goals For (descending)
    // 4. Head-to-Head (o'zaro uchrashuv)
    // 5. Team name (ascending)
    statList.sort((a, b) {
      // 1. Points
      if (a.points != b.points) {
        return b.points.compareTo(a.points);
      }

      // 2. Goal Difference
      final aGd = a.goalsFor - a.goalsAgainst;
      final bGd = b.goalsFor - b.goalsAgainst;
      if (aGd != bGd) {
        return bGd.compareTo(aGd);
      }

      // 3. Goals For
      if (a.goalsFor != b.goalsFor) {
        return b.goalsFor.compareTo(a.goalsFor);
      }

      // 4. Head-to-Head
      final h2h = _compareHeadToHead(a.teamId, b.teamId, finishedMatches);
      if (h2h != 0) {
        return h2h;
      }

      // 5. Name fallback
      return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
    });

    // Build final standing row entities with 1-based pos
    return List.generate(statList.length, (index) {
      final s = statList[index];
      return StandingRowEntity(
        pos: index + 1,
        teamId: s.teamId,
        teamName: s.teamName,
        colorValue: s.colorValue,
        logoPath: s.logoPath,
        played: s.played,
        won: s.won,
        drawn: s.drawn,
        lost: s.lost,
        goalsFor: s.goalsFor,
        goalsAgainst: s.goalsAgainst,
        goalDifference: s.goalsFor - s.goalsAgainst,
        points: s.points,
      );
    });
  }

  /// Compares Head-to-Head matches between teamA and teamB
  /// Returns negative if A is better, positive if B is better, 0 if equal.
  static int _compareHeadToHead(
    String teamAId,
    String teamBId,
    List<MatchEntity> matches,
  ) {
    int aPoints = 0;
    int bPoints = 0;
    int aGoals = 0;
    int bGoals = 0;

    for (final m in matches) {
      if ((m.homeTeamId == teamAId && m.awayTeamId == teamBId) ||
          (m.homeTeamId == teamBId && m.awayTeamId == teamAId)) {
        final aScore = m.homeTeamId == teamAId ? m.homeScore! : m.awayScore!;
        final bScore = m.homeTeamId == teamBId ? m.homeScore! : m.awayScore!;

        aGoals += aScore;
        bGoals += bScore;

        if (aScore > bScore) {
          aPoints += 3;
        } else if (aScore == bScore) {
          aPoints += 1;
          bPoints += 1;
        } else {
          bPoints += 3;
        }
      }
    }

    if (aPoints != bPoints) {
      return bPoints.compareTo(aPoints); // higher points first
    }

    final aGd = aGoals - bGoals;
    final bGd = bGoals - aGoals;
    if (aGd != bGd) {
      return bGd.compareTo(aGd);
    }

    if (aGoals != bGoals) {
      return bGoals.compareTo(aGoals);
    }

    return 0;
  }
}

class _TeamStat {
  final String teamId;
  final String teamName;
  final int colorValue;
  final String? logoPath;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;

  _TeamStat({
    required this.teamId,
    required this.teamName,
    required this.colorValue,
    this.logoPath,
  });
}

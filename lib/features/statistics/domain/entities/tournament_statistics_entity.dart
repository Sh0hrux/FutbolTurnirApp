import 'package:equatable/equatable.dart';
import '../../../teams/domain/entities/team_entity.dart';

class TeamStatMetric extends Equatable {
  final TeamEntity team;
  final num value;
  final String label;

  const TeamStatMetric({
    required this.team,
    required this.value,
    required this.label,
  });

  @override
  List<Object?> get props => [team, value, label];
}

class DetailedTeamStat extends Equatable {
  final TeamEntity team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const DetailedTeamStat({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  @override
  List<Object?> get props => [
        team,
        played,
        won,
        drawn,
        lost,
        goalsFor,
        goalsAgainst,
        goalDifference,
        points,
      ];
}

class TournamentStatisticsEntity extends Equatable {
  final TeamStatMetric? topScoringTeam;
  final TeamStatMetric? bestDefenseTeam;
  final TeamStatMetric? mostWinsTeam;
  final TeamStatMetric? mostLossesTeam;
  final TeamStatMetric? bestGoalDiffTeam;
  final TeamStatMetric? topPointsTeam;
  final int totalGoals;
  final int totalMatchesPlayed;
  final double averageGoalsPerMatch;
  final List<DetailedTeamStat> teamStats;

  const TournamentStatisticsEntity({
    this.topScoringTeam,
    this.bestDefenseTeam,
    this.mostWinsTeam,
    this.mostLossesTeam,
    this.bestGoalDiffTeam,
    this.topPointsTeam,
    required this.totalGoals,
    required this.totalMatchesPlayed,
    required this.averageGoalsPerMatch,
    required this.teamStats,
  });

  @override
  List<Object?> get props => [
        topScoringTeam,
        bestDefenseTeam,
        mostWinsTeam,
        mostLossesTeam,
        bestGoalDiffTeam,
        topPointsTeam,
        totalGoals,
        totalMatchesPlayed,
        averageGoalsPerMatch,
        teamStats,
      ];
}

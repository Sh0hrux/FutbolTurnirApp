import 'package:equatable/equatable.dart';

class StandingRowEntity extends Equatable {
  final int pos;
  final String teamId;
  final String teamName;
  final int colorValue;
  final String? logoPath;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const StandingRowEntity({
    required this.pos,
    required this.teamId,
    required this.teamName,
    required this.colorValue,
    this.logoPath,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.goalDifference = 0,
    this.points = 0,
  });

  StandingRowEntity copyWith({
    int? pos,
    String? teamId,
    String? teamName,
    int? colorValue,
    String? logoPath,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDifference,
    int? points,
  }) {
    return StandingRowEntity(
      pos: pos ?? this.pos,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      colorValue: colorValue ?? this.colorValue,
      logoPath: logoPath ?? this.logoPath,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDifference: goalDifference ?? this.goalDifference,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
        pos,
        teamId,
        teamName,
        colorValue,
        logoPath,
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

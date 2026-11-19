import 'package:equatable/equatable.dart';

enum MatchStatus {
  upcoming,
  live,
  finished;

  static MatchStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'live':
        return MatchStatus.live;
      case 'finished':
        return MatchStatus.finished;
      case 'upcoming':
      default:
        return MatchStatus.upcoming;
    }
  }

  String toDbString() {
    switch (this) {
      case MatchStatus.live:
        return 'live';
      case MatchStatus.finished:
        return 'finished';
      case MatchStatus.upcoming:
        return 'upcoming';
    }
  }
}

class MatchEntity extends Equatable {
  final String id;
  final String tournamentId;
  final int round;
  final int slotIndex;
  final String timeSlot;
  final String homeTeamId;
  final String awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchEntity({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.slotIndex,
    required this.timeSlot,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.status = MatchStatus.upcoming,
    required this.createdAt,
    required this.updatedAt,
  });

  MatchEntity copyWith({
    String? id,
    String? tournamentId,
    int? round,
    int? slotIndex,
    String? timeSlot,
    String? homeTeamId,
    String? awayTeamId,
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchEntity(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      round: round ?? this.round,
      slotIndex: slotIndex ?? this.slotIndex,
      timeSlot: timeSlot ?? this.timeSlot,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        round,
        slotIndex,
        timeSlot,
        homeTeamId,
        awayTeamId,
        homeScore,
        awayScore,
        status,
        createdAt,
        updatedAt,
      ];
}

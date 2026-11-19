import 'package:equatable/equatable.dart';
import '../../domain/entities/match_entity.dart';

sealed class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

class LoadScheduleEvent extends ScheduleEvent {
  final int? selectedRound;
  const LoadScheduleEvent({this.selectedRound});

  @override
  List<Object?> get props => [selectedRound];
}

class SelectRoundEvent extends ScheduleEvent {
  final int round;
  const SelectRoundEvent(this.round);

  @override
  List<Object?> get props => [round];
}

class GenerateNextRoundEvent extends ScheduleEvent {
  const GenerateNextRoundEvent();
}

class GenerateFullScheduleEvent extends ScheduleEvent {
  final int totalRounds;
  const GenerateFullScheduleEvent({this.totalRounds = 22});

  @override
  List<Object?> get props => [totalRounds];
}

class RandomizeRoundEvent extends ScheduleEvent {
  final int round;
  const RandomizeRoundEvent(this.round);

  @override
  List<Object?> get props => [round];
}

class UpdateMatchScoreEvent extends ScheduleEvent {
  final String matchId;
  final int? homeScore;
  final int? awayScore;
  final MatchStatus status;

  const UpdateMatchScoreEvent({
    required this.matchId,
    required this.homeScore,
    required this.awayScore,
    required this.status,
  });

  @override
  List<Object?> get props => [matchId, homeScore, awayScore, status];
}

class UpdateMatchSlotEvent extends ScheduleEvent {
  final String matchId;
  final String newTimeSlot;
  final int newSlotIndex;

  const UpdateMatchSlotEvent({
    required this.matchId,
    required this.newTimeSlot,
    required this.newSlotIndex,
  });

  @override
  List<Object?> get props => [matchId, newTimeSlot, newSlotIndex];
}

class DeleteMatchEvent extends ScheduleEvent {
  final String matchId;
  const DeleteMatchEvent(this.matchId);

  @override
  List<Object?> get props => [matchId];
}

class DeleteRoundEvent extends ScheduleEvent {
  final int round;
  const DeleteRoundEvent(this.round);

  @override
  List<Object?> get props => [round];
}

class ResetTournamentEvent extends ScheduleEvent {
  const ResetTournamentEvent();
}

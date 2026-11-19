import 'package:equatable/equatable.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/round_rest_entity.dart';

sealed class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleSuccess extends ScheduleState {
  final int selectedRound;
  final List<int> availableRounds;
  final List<MatchEntity> allMatches;
  final List<RoundRestEntity> allRests;
  final Map<String, TeamEntity> teamsMap;
  final bool isActionLoading;
  final String? actionMessage;

  const ScheduleSuccess({
    required this.selectedRound,
    required this.availableRounds,
    required this.allMatches,
    required this.allRests,
    required this.teamsMap,
    this.isActionLoading = false,
    this.actionMessage,
  });

  /// Matches filtered for currently selected round
  List<MatchEntity> get currentRoundMatches =>
      allMatches.where((m) => m.round == selectedRound).toList();

  /// Resting team for currently selected round
  TeamEntity? get currentRoundRestingTeam {
    final rest = allRests.where((r) => r.round == selectedRound).firstOrNull;
    if (rest == null) return null;
    return teamsMap[rest.teamId];
  }

  ScheduleSuccess copyWith({
    int? selectedRound,
    List<int>? availableRounds,
    List<MatchEntity>? allMatches,
    List<RoundRestEntity>? allRests,
    Map<String, TeamEntity>? teamsMap,
    bool? isActionLoading,
    String? actionMessage,
  }) {
    return ScheduleSuccess(
      selectedRound: selectedRound ?? this.selectedRound,
      availableRounds: availableRounds ?? this.availableRounds,
      allMatches: allMatches ?? this.allMatches,
      allRests: allRests ?? this.allRests,
      teamsMap: teamsMap ?? this.teamsMap,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        selectedRound,
        availableRounds,
        allMatches,
        allRests,
        teamsMap,
        isActionLoading,
        actionMessage,
      ];
}

class ScheduleFailure extends ScheduleState {
  final String message;
  const ScheduleFailure(this.message);

  @override
  List<Object?> get props => [message];
}

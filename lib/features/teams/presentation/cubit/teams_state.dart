import 'package:equatable/equatable.dart';
import '../../domain/entities/team_entity.dart';

sealed class TeamsState extends Equatable {
  const TeamsState();

  @override
  List<Object?> get props => [];
}

class TeamsInitial extends TeamsState {
  const TeamsInitial();
}

class TeamsLoading extends TeamsState {
  const TeamsLoading();
}

class TeamStatsInfo extends Equatable {
  final int played;
  final int points;
  final bool hasMatches;

  const TeamStatsInfo({
    this.played = 0,
    this.points = 0,
    this.hasMatches = false,
  });

  @override
  List<Object?> get props => [played, points, hasMatches];
}

class TeamsSuccess extends TeamsState {
  final List<TeamEntity> teams;
  final Map<String, TeamStatsInfo> statsMap;
  final bool isFromCache;
  final bool isOffline;
  final bool isActionLoading;
  final String? actionMessage;

  const TeamsSuccess({
    required this.teams,
    this.statsMap = const {},
    this.isFromCache = false,
    this.isOffline = false,
    this.isActionLoading = false,
    this.actionMessage,
  });

  TeamsSuccess copyWith({
    List<TeamEntity>? teams,
    Map<String, TeamStatsInfo>? statsMap,
    bool? isFromCache,
    bool? isOffline,
    bool? isActionLoading,
    String? actionMessage,
  }) {
    return TeamsSuccess(
      teams: teams ?? this.teams,
      statsMap: statsMap ?? this.statsMap,
      isFromCache: isFromCache ?? this.isFromCache,
      isOffline: isOffline ?? this.isOffline,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        teams,
        statsMap,
        isFromCache,
        isOffline,
        isActionLoading,
        actionMessage,
      ];
}

class TeamsFailure extends TeamsState {
  final String message;

  const TeamsFailure(this.message);

  @override
  List<Object?> get props => [message];
}


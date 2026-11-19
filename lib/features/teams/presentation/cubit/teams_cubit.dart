import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../schedule/domain/repositories/match_repository.dart';
import '../../../standings/domain/repositories/standings_repository.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/repositories/team_repository.dart';
import 'teams_state.dart';

class TeamsCubit extends Cubit<TeamsState> {
  final TeamRepository repository;
  final MatchRepository? matchRepository;
  final StandingsRepository? standingsRepository;
  bool _includeArchived = true;

  TeamsCubit({
    required this.repository,
    this.matchRepository,
    this.standingsRepository,
  }) : super(const TeamsInitial());

  bool get includeArchived => _includeArchived;

  Future<void> loadTeams({bool? includeArchived}) async {
    if (includeArchived != null) {
      _includeArchived = includeArchived;
    }

    final currentSuccess = state is TeamsSuccess ? (state as TeamsSuccess) : null;
    if (currentSuccess == null) {
      emit(const TeamsLoading());
    }

    final result = await repository.getTeams(includeArchived: _includeArchived);

    final statsMap = <String, TeamStatsInfo>{};

    if (standingsRepository != null) {
      final standingsRes = await standingsRepository!.getStandings(
        tournamentId: AppConstants.defaultTournamentId,
      );
      if (standingsRes.isRight) {
        for (final row in standingsRes.rightOrNull!) {
          statsMap[row.teamId] = TeamStatsInfo(
            played: row.played,
            points: row.points,
            hasMatches: row.played > 0,
          );
        }
      }
    }

    if (matchRepository != null) {
      final matchesRes = await matchRepository!.getMatches(
        tournamentId: AppConstants.defaultTournamentId,
      );
      if (matchesRes.isRight) {
        final matches = matchesRes.rightOrNull!;
        for (final m in matches) {
          final curHome = statsMap[m.homeTeamId] ?? const TeamStatsInfo();
          statsMap[m.homeTeamId] = TeamStatsInfo(
            played: curHome.played,
            points: curHome.points,
            hasMatches: true,
          );
          final curAway = statsMap[m.awayTeamId] ?? const TeamStatsInfo();
          statsMap[m.awayTeamId] = TeamStatsInfo(
            played: curAway.played,
            points: curAway.points,
            hasMatches: true,
          );
        }
      }
    }

    result.fold(
      (failure) {
        if (currentSuccess != null) {
          emit(currentSuccess.copyWith(actionMessage: failure.message));
        } else {
          emit(TeamsFailure(failure.message));
        }
      },
      (teams) => emit(TeamsSuccess(
        teams: teams,
        statsMap: statsMap,
        isFromCache: false,
        isOffline: false,
      )),
    );
  }

  Future<bool> addTeam({required String name, required int colorValue, String? logoPath}) async {
    final currentState = state;
    if (currentState is TeamsSuccess) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    final result = await repository.createTeam(
      name: name,
      colorValue: colorValue,
      logoPath: logoPath,
    );

    return result.fold(
      (failure) {
        if (currentState is TeamsSuccess) {
          emit(currentState.copyWith(isActionLoading: false, actionMessage: failure.message));
        } else {
          emit(TeamsFailure(failure.message));
        }
        return false;
      },
      (newTeam) {
        loadTeams();
        return true;
      },
    );
  }

  Future<bool> updateTeam(TeamEntity team) async {
    final currentState = state;
    if (currentState is TeamsSuccess) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    final result = await repository.updateTeam(team);

    return result.fold(
      (failure) {
        if (currentState is TeamsSuccess) {
          emit(currentState.copyWith(isActionLoading: false, actionMessage: failure.message));
        } else {
          emit(TeamsFailure(failure.message));
        }
        return false;
      },
      (updatedTeam) {
        loadTeams();
        return true;
      },
    );
  }

  Future<bool> deleteOrArchiveTeam(String teamId, {bool forceArchive = false}) async {
    final currentState = state;
    if (currentState is TeamsSuccess) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    final result = await repository.deleteOrArchiveTeam(teamId, forceArchive: forceArchive);

    return result.fold(
      (failure) {
        if (currentState is TeamsSuccess) {
          emit(currentState.copyWith(isActionLoading: false, actionMessage: failure.message));
        } else {
          emit(TeamsFailure(failure.message));
        }
        return false;
      },
      (wasArchived) {
        loadTeams();
        return true;
      },
    );
  }

  Future<bool> unarchiveTeam(String teamId) async {
    final currentState = state;
    if (currentState is TeamsSuccess) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    final result = await repository.unarchiveTeam(teamId);

    return result.fold(
      (failure) {
        if (currentState is TeamsSuccess) {
          emit(currentState.copyWith(isActionLoading: false, actionMessage: failure.message));
        } else {
          emit(TeamsFailure(failure.message));
        }
        return false;
      },
      (_) {
        loadTeams();
        return true;
      },
    );
  }

  Future<bool> checkTeamHasMatches(String teamId) async {
    final result = await repository.hasTeamPlayedMatches(teamId);
    return result.fold((l) => false, (hasMatches) => hasMatches);
  }
}


import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/round_rest_entity.dart';
import '../../domain/repositories/match_repository.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final MatchRepository matchRepository;
  final TeamRepository teamRepository;

  ScheduleBloc({
    required this.matchRepository,
    required this.teamRepository,
  }) : super(const ScheduleInitial()) {
    on<LoadScheduleEvent>(_onLoadSchedule);
    on<SelectRoundEvent>(_onSelectRound);
    on<GenerateNextRoundEvent>(_onGenerateNextRound);
    on<GenerateFullScheduleEvent>(_onGenerateFullSchedule);
    on<RandomizeRoundEvent>(_onRandomizeRound);
    on<UpdateMatchScoreEvent>(_onUpdateMatchScore);
    on<UpdateMatchSlotEvent>(_onUpdateMatchSlot);
    on<DeleteMatchEvent>(_onDeleteMatch);
    on<DeleteRoundEvent>(_onDeleteRound);
    on<ResetTournamentEvent>(_onResetTournament);
  }

  Future<void> _onLoadSchedule(
    LoadScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());

    // 1. Load teams map
    final teamsRes = await teamRepository.getTeams(includeArchived: true);
    if (teamsRes.isLeft) {
      emit(ScheduleFailure(teamsRes.leftOrNull!.message));
      return;
    }
    final teams = teamsRes.rightOrNull!;
    final teamsMap = {for (var t in teams) t.id: t};

    // 2. Load matches & rests
    final matchesRes = await matchRepository.getMatches(
      tournamentId: AppConstants.defaultTournamentId,
    );
    final restsRes = await matchRepository.getRoundRests(
      tournamentId: AppConstants.defaultTournamentId,
    );

    if (matchesRes.isLeft) {
      emit(ScheduleFailure(matchesRes.leftOrNull!.message));
      return;
    }

    final allMatches = matchesRes.rightOrNull!;
    final allRests = restsRes.fold<List<RoundRestEntity>>((l) => [], (r) => r);

    final availableRounds = allMatches.map((m) => m.round).toSet().toList()..sort();
    final selectedRound = event.selectedRound ??
        (availableRounds.isNotEmpty ? availableRounds.first : 1);

    emit(ScheduleSuccess(
      selectedRound: selectedRound,
      availableRounds: availableRounds,
      allMatches: allMatches,
      allRests: allRests,
      teamsMap: teamsMap,
    ));
  }

  void _onSelectRound(
    SelectRoundEvent event,
    Emitter<ScheduleState> emit,
  ) {
    if (state is ScheduleSuccess) {
      final s = state as ScheduleSuccess;
      emit(s.copyWith(selectedRound: event.round));
    }
  }

  Future<void> _onGenerateNextRound(
    GenerateNextRoundEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.generateNextRound(
      tournamentId: AppConstants.defaultTournamentId,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        } else {
          emit(ScheduleFailure(failure.message));
        }
      },
      (generationResult) {
        final newRound = generationResult.matches.firstOrNull?.round ?? 1;
        add(LoadScheduleEvent(selectedRound: newRound));
      },
    );
  }

  Future<void> _onGenerateFullSchedule(
    GenerateFullScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.generateFullSchedule(
      tournamentId: AppConstants.defaultTournamentId,
      totalRounds: event.totalRounds,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        } else {
          emit(ScheduleFailure(failure.message));
        }
      },
      (_) => add(const LoadScheduleEvent()),
    );
  }

  Future<void> _onRandomizeRound(
    RandomizeRoundEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.randomizeUpcomingMatches(
      tournamentId: AppConstants.defaultTournamentId,
      round: event.round,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        } else {
          emit(ScheduleFailure(failure.message));
        }
      },
      (_) => add(LoadScheduleEvent(selectedRound: event.round)),
    );
  }

  Future<void> _onUpdateMatchScore(
    UpdateMatchScoreEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.updateMatchScore(
      matchId: event.matchId,
      homeScore: event.homeScore,
      awayScore: event.awayScore,
      status: event.status,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        }
      },
      (_) {
        final currentRound = state is ScheduleSuccess
            ? (state as ScheduleSuccess).selectedRound
            : null;
        add(LoadScheduleEvent(selectedRound: currentRound));
      },
    );
  }

  Future<void> _onUpdateMatchSlot(
    UpdateMatchSlotEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.updateMatchTimeSlot(
      matchId: event.matchId,
      newTimeSlot: event.newTimeSlot,
      newSlotIndex: event.newSlotIndex,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        }
      },
      (_) {
        final currentRound = state is ScheduleSuccess
            ? (state as ScheduleSuccess).selectedRound
            : null;
        add(LoadScheduleEvent(selectedRound: currentRound));
      },
    );
  }

  Future<void> _onDeleteMatch(
    DeleteMatchEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.deleteMatch(event.matchId);

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        }
      },
      (_) {
        final currentRound = state is ScheduleSuccess
            ? (state as ScheduleSuccess).selectedRound
            : null;
        add(LoadScheduleEvent(selectedRound: currentRound));
      },
    );
  }

  Future<void> _onDeleteRound(
    DeleteRoundEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    int? nextRound;
    if (state is ScheduleSuccess) {
      final s = state as ScheduleSuccess;
      emit(s.copyWith(isActionLoading: true));
      final remaining = s.availableRounds.where((r) => r != event.round).toList();
      if (remaining.isNotEmpty) {
        final lower = remaining.where((r) => r < event.round).toList();
        nextRound = lower.isNotEmpty ? lower.last : remaining.first;
      }
    }

    final result = await matchRepository.deleteRound(
      tournamentId: AppConstants.defaultTournamentId,
      round: event.round,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        }
      },
      (_) {
        add(LoadScheduleEvent(selectedRound: nextRound));
      },
    );
  }

  Future<void> _onResetTournament(
    ResetTournamentEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is ScheduleSuccess) {
      emit((state as ScheduleSuccess).copyWith(isActionLoading: true));
    }

    final result = await matchRepository.resetTournament(
      AppConstants.defaultTournamentId,
    );

    result.fold(
      (failure) {
        if (state is ScheduleSuccess) {
          emit((state as ScheduleSuccess).copyWith(
            isActionLoading: false,
            actionMessage: failure.message,
          ));
        }
      },
      (_) => add(const LoadScheduleEvent()),
    );
  }
}

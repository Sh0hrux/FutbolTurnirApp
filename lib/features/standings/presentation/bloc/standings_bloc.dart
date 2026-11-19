import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/standings_repository.dart';
import 'standings_event.dart';
import 'standings_state.dart';

class StandingsBloc extends Bloc<StandingsEvent, StandingsState> {
  final StandingsRepository repository;

  StandingsBloc({required this.repository}) : super(const StandingsInitial()) {
    on<LoadStandingsEvent>(_onLoadStandings);
  }

  Future<void> _onLoadStandings(
    LoadStandingsEvent event,
    Emitter<StandingsState> emit,
  ) async {
    final currentSuccess = state is StandingsSuccess ? (state as StandingsSuccess) : null;
    if (currentSuccess == null) {
      emit(const StandingsLoading());
    }

    final result = await repository.getStandings(
      tournamentId: AppConstants.defaultTournamentId,
    );

    result.fold(
      (failure) {
        if (currentSuccess != null) {
          emit(currentSuccess.copyWith(errorMessage: failure.message));
        } else {
          emit(StandingsFailure(failure.message));
        }
      },
      (standings) => emit(StandingsSuccess(standings: standings)),
    );
  }
}

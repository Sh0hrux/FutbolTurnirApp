import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../schedule/domain/entities/match_entity.dart';
import '../../../schedule/domain/repositories/match_repository.dart';
import '../../../standings/domain/entities/standing_row_entity.dart';
import '../../../standings/domain/repositories/standings_repository.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/home_summary_entity.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TeamRepository teamRepository;
  final MatchRepository matchRepository;
  final StandingsRepository standingsRepository;

  HomeBloc({
    required this.teamRepository,
    required this.matchRepository,
    required this.standingsRepository,
  }) : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentSuccess = state is HomeSuccess ? (state as HomeSuccess) : null;
    if (currentSuccess == null) {
      emit(const HomeLoading());
    }

    // 1. Teams
    final teamsRes = await teamRepository.getTeams(includeArchived: false);
    if (teamsRes.isLeft) {
      if (currentSuccess != null) {
        emit(HomeSuccess(currentSuccess.summary, errorMessage: teamsRes.leftOrNull!.message));
      } else {
        emit(HomeFailure(teamsRes.leftOrNull!.message));
      }
      return;
    }
    final teams = teamsRes.rightOrNull!;
    final teamsMap = {for (var t in teams) t.id: t};

    // 2. Matches
    final matchesRes = await matchRepository.getMatches(
      tournamentId: AppConstants.defaultTournamentId,
    );
    if (matchesRes.isLeft) {
      if (currentSuccess != null) {
        emit(HomeSuccess(currentSuccess.summary, errorMessage: matchesRes.leftOrNull!.message));
      } else {
        emit(HomeFailure(matchesRes.leftOrNull!.message));
      }
      return;
    }
    final matches = matchesRes.rightOrNull!;

    // 3. Standings
    final standingsRes = await standingsRepository.getStandings(
      tournamentId: AppConstants.defaultTournamentId,
    );
    final standings = standingsRes.fold<List<StandingRowEntity>>((l) => [], (r) => r);
    final top3 = standings.take(3).toList();

    // Stats calculations
    final finishedMatches = matches.where((m) => m.status == MatchStatus.finished).toList();
    final upcomingMatches = matches.where((m) => m.status == MatchStatus.upcoming).toList();

    // Next match (first upcoming match chronologically)
    final nextMatch = upcomingMatches.firstOrNull;
    final nextRoundNumber = nextMatch?.round;

    // Recent results (latest finished matches, reversed)
    final recentFinished = finishedMatches.reversed.take(4).toList();

    final summary = HomeSummaryEntity(
      tournamentName: AppConstants.defaultTournamentName,
      totalTeamsCount: teams.length,
      totalMatchesCount: matches.length,
      finishedMatchesCount: finishedMatches.length,
      nextMatch: nextMatch,
      nextRoundNumber: nextRoundNumber,
      top3Standings: top3,
      recentFinishedMatches: recentFinished,
      teamsMap: teamsMap,
    );

    emit(HomeSuccess(summary));
  }
}

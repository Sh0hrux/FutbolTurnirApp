import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/schedule/domain/repositories/match_repository.dart';
import 'package:football_tournament_manager/features/statistics/presentation/bloc/statistics_bloc.dart';
import 'package:football_tournament_manager/features/statistics/presentation/bloc/statistics_event.dart';
import 'package:football_tournament_manager/features/statistics/presentation/bloc/statistics_state.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamRepository extends Mock implements TeamRepository {}
class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late StatisticsBloc bloc;
  late MockTeamRepository mockTeamRepository;
  late MockMatchRepository mockMatchRepository;

  final now = DateTime.now();
  final tTeam = TeamEntity(
    id: 'team-1',
    name: 'Arsenal',
    colorValue: 0xFFE53935,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockTeamRepository = MockTeamRepository();
    mockMatchRepository = MockMatchRepository();

    bloc = StatisticsBloc(
      teamRepository: mockTeamRepository,
      matchRepository: mockMatchRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is StatisticsInitial', () {
    expect(bloc.state, const StatisticsInitial());
  });

  blocTest<StatisticsBloc, StatisticsState>(
    'emits [StatisticsLoading, StatisticsSuccess] when loading statistics succeeds',
    build: () {
      when(() => mockTeamRepository.getTeams(includeArchived: any(named: 'includeArchived')))
          .thenAnswer((_) async => Right([tTeam]));
      when(() => mockMatchRepository.getMatches(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadStatisticsEvent()),
    expect: () => [
      const StatisticsLoading(),
      isA<StatisticsSuccess>(),
    ],
  );
}

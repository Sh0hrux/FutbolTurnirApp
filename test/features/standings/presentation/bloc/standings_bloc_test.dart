import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/standings/domain/entities/standing_row_entity.dart';
import 'package:football_tournament_manager/features/standings/domain/repositories/standings_repository.dart';
import 'package:football_tournament_manager/features/standings/presentation/bloc/standings_bloc.dart';
import 'package:football_tournament_manager/features/standings/presentation/bloc/standings_event.dart';
import 'package:football_tournament_manager/features/standings/presentation/bloc/standings_state.dart';
import 'package:mocktail/mocktail.dart';

class MockStandingsRepository extends Mock implements StandingsRepository {}

void main() {
  late StandingsBloc bloc;
  late MockStandingsRepository mockRepository;

  const tRow = StandingRowEntity(
    pos: 1,
    teamId: 'team-1',
    teamName: 'Arsenal',
    colorValue: 0xFFE53935,
    points: 3,
  );

  setUp(() {
    mockRepository = MockStandingsRepository();
    bloc = StandingsBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is StandingsInitial', () {
    expect(bloc.state, const StandingsInitial());
  });

  blocTest<StandingsBloc, StandingsState>(
    'emits [StandingsLoading, StandingsSuccess] when loading standings succeeds',
    build: () {
      when(() => mockRepository.getStandings(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async => const Right([tRow]));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadStandingsEvent()),
    expect: () => [
      const StandingsLoading(),
      const StandingsSuccess(standings: [tRow]),
    ],
  );
}

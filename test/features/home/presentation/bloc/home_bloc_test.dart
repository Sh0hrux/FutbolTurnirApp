import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/home/presentation/bloc/home_bloc.dart';
import 'package:football_tournament_manager/features/home/presentation/bloc/home_event.dart';
import 'package:football_tournament_manager/features/home/presentation/bloc/home_state.dart';
import 'package:football_tournament_manager/features/schedule/domain/repositories/match_repository.dart';
import 'package:football_tournament_manager/features/standings/domain/repositories/standings_repository.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamRepository extends Mock implements TeamRepository {}
class MockMatchRepository extends Mock implements MatchRepository {}
class MockStandingsRepository extends Mock implements StandingsRepository {}

void main() {
  late HomeBloc bloc;
  late MockTeamRepository mockTeamRepository;
  late MockMatchRepository mockMatchRepository;
  late MockStandingsRepository mockStandingsRepository;

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
    mockStandingsRepository = MockStandingsRepository();

    bloc = HomeBloc(
      teamRepository: mockTeamRepository,
      matchRepository: mockMatchRepository,
      standingsRepository: mockStandingsRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is HomeInitial', () {
    expect(bloc.state, const HomeInitial());
  });

  blocTest<HomeBloc, HomeState>(
    'emits [HomeLoading, HomeSuccess] when loading home data succeeds',
    build: () {
      when(() => mockTeamRepository.getTeams(includeArchived: any(named: 'includeArchived')))
          .thenAnswer((_) async => Right([tTeam]));
      when(() => mockMatchRepository.getMatches(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockStandingsRepository.getStandings(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadHomeDataEvent()),
    expect: () => [
      const HomeLoading(),
      isA<HomeSuccess>(),
    ],
  );
}

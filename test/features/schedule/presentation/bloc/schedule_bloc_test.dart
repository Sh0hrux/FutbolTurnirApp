import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/schedule/domain/entities/match_entity.dart';
import 'package:football_tournament_manager/features/schedule/domain/repositories/match_repository.dart';
import 'package:football_tournament_manager/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:football_tournament_manager/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:football_tournament_manager/features/schedule/presentation/bloc/schedule_state.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}
class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late ScheduleBloc bloc;
  late MockMatchRepository mockMatchRepository;
  late MockTeamRepository mockTeamRepository;

  final now = DateTime.now();
  final tTeam = TeamEntity(
    id: 'team-1',
    name: 'Arsenal',
    colorValue: 0xFFE53935,
    createdAt: now,
    updatedAt: now,
  );
  final tMatch = MatchEntity(
    id: 'm1',
    tournamentId: 't1',
    round: 1,
    slotIndex: 0,
    timeSlot: '17:00 – 18:00',
    homeTeamId: 'team-1',
    awayTeamId: 'team-2',
    status: MatchStatus.upcoming,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockMatchRepository = MockMatchRepository();
    mockTeamRepository = MockTeamRepository();

    bloc = ScheduleBloc(
      matchRepository: mockMatchRepository,
      teamRepository: mockTeamRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is ScheduleInitial', () {
    expect(bloc.state, const ScheduleInitial());
  });

  blocTest<ScheduleBloc, ScheduleState>(
    'emits [ScheduleLoading, ScheduleSuccess] when loading schedule succeeds',
    build: () {
      when(() => mockTeamRepository.getTeams(includeArchived: any(named: 'includeArchived')))
          .thenAnswer((_) async => Right([tTeam]));
      when(() => mockMatchRepository.getMatches(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async => Right([tMatch]));
      when(() => mockMatchRepository.getRoundRests(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadScheduleEvent()),
    expect: () => [
      const ScheduleLoading(),
      isA<ScheduleSuccess>(),
    ],
  );
}

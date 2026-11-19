import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/error/failures.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:football_tournament_manager/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:football_tournament_manager/features/teams/presentation/cubit/teams_state.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late TeamsCubit cubit;
  late MockTeamRepository mockRepository;

  final tTeam = TeamEntity(
    id: 'team-1',
    name: 'Arsenal',
    colorValue: 0xFFE53935,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockTeamRepository();
    cubit = TeamsCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is TeamsInitial', () {
    expect(cubit.state, const TeamsInitial());
  });

  blocTest<TeamsCubit, TeamsState>(
    'emits [TeamsLoading, TeamsSuccess] when loadTeams succeeds',
    build: () {
      when(() => mockRepository.getTeams(includeArchived: any(named: 'includeArchived')))
          .thenAnswer((_) async => Right([tTeam]));
      return cubit;
    },
    act: (cubit) => cubit.loadTeams(),
    expect: () => [
      const TeamsLoading(),
      TeamsSuccess(teams: [tTeam]),
    ],
  );

  blocTest<TeamsCubit, TeamsState>(
    'emits [TeamsLoading, TeamsFailure] when loadTeams fails',
    build: () {
      when(() => mockRepository.getTeams(includeArchived: any(named: 'includeArchived')))
          .thenAnswer((_) async => const Left(ServerFailure('Serverda xatolik')));
      return cubit;
    },
    act: (cubit) => cubit.loadTeams(),
    expect: () => [
      const TeamsLoading(),
      const TeamsFailure('Serverda xatolik'),
    ],
  );
}


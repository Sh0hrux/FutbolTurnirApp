import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/error/exceptions.dart';
import 'package:football_tournament_manager/core/error/failures.dart';
import 'package:football_tournament_manager/features/teams/data/datasources/team_remote_data_source.dart';
import 'package:football_tournament_manager/features/teams/data/models/team_dto.dart';
import 'package:football_tournament_manager/features/teams/data/repositories/team_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamRemoteDataSource extends Mock implements TeamRemoteDataSource {}

void main() {
  late TeamRepositoryImpl repository;
  late MockTeamRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(
      TeamDto(
        id: 'test-fallback',
        name: 'Fallback',
        colorValue: 0xFF123456,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockTeamRemoteDataSource();
    repository = TeamRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  final tTeamDto = TeamDto(
    id: 'team-1',
    name: 'Arsenal',
    colorValue: 0xFFE53935,
    isArchived: false,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );

  test('getTeams should return List<TeamEntity> on success', () async {
    when(() => mockRemoteDataSource.getTeams(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          includeArchived: any(named: 'includeArchived'),
        )).thenAnswer((_) async => [tTeamDto]);

    final result = await repository.getTeams();

    expect(result.isRight, true);
    result.fold(
      (l) => fail('Should succeed'),
      (teams) {
        expect(teams.length, 1);
        expect(teams.first.name, 'Arsenal');
      },
    );
  });

  test('getTeams should return NetworkFailure on NetworkException', () async {
    when(() => mockRemoteDataSource.getTeams(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          includeArchived: any(named: 'includeArchived'),
        )).thenThrow(const NetworkException('Aloqa yo‘q'));

    final result = await repository.getTeams();

    expect(result.isLeft, true);
    result.fold(
      (failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'Aloqa yo‘q');
      },
      (r) => fail('Should fail'),
    );
  });

  test('createTeam should return created TeamEntity', () async {
    when(() => mockRemoteDataSource.createTeam(any())).thenAnswer((_) async => tTeamDto);

    final result = await repository.createTeam(
      name: 'Arsenal',
      colorValue: 0xFFE53935,
    );

    expect(result.isRight, true);
    result.fold(
      (l) => fail('Should succeed'),
      (team) => expect(team.name, 'Arsenal'),
    );
  });
}


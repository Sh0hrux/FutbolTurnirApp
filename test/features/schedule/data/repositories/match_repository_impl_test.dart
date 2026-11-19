import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/error/exceptions.dart';
import 'package:football_tournament_manager/core/error/failures.dart';
import 'package:football_tournament_manager/features/schedule/data/datasources/match_remote_data_source.dart';
import 'package:football_tournament_manager/features/schedule/data/models/match_dto.dart';
import 'package:football_tournament_manager/features/schedule/data/repositories/match_repository_impl.dart';
import 'package:football_tournament_manager/features/schedule/domain/entities/match_entity.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRemoteDataSource extends Mock implements MatchRemoteDataSource {}
class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MatchRepositoryImpl repository;
  late MockMatchRemoteDataSource mockRemoteDataSource;
  late MockTeamRepository mockTeamRepository;

  final now = DateTime.now();
  final tMatchDto = MatchDto(
    id: 'm1',
    tournamentId: 't1',
    round: 1,
    slotIndex: 0,
    timeSlot: '17:00 – 18:00',
    homeTeamId: 'team-1',
    awayTeamId: 'team-2',
    status: 'upcoming',
    createdAt: now.toIso8601String(),
    updatedAt: now.toIso8601String(),
  );

  setUp(() {
    mockRemoteDataSource = MockMatchRemoteDataSource();
    mockTeamRepository = MockTeamRepository();
    repository = MatchRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      teamRepository: mockTeamRepository,
    );
  });

  test('getMatches returns list of MatchEntity on success', () async {
    when(() => mockRemoteDataSource.getMatches('t1', round: any(named: 'round')))
        .thenAnswer((_) async => [tMatchDto]);

    final result = await repository.getMatches(tournamentId: 't1');

    expect(result.isRight, true);
    result.fold(
      (l) => fail('Should succeed'),
      (matches) {
        expect(matches.length, 1);
        expect(matches.first.id, 'm1');
        expect(matches.first.timeSlot, '17:00 – 18:00');
      },
    );
  });

  test('getMatches returns NetworkFailure on NetworkException', () async {
    when(() => mockRemoteDataSource.getMatches('t1', round: any(named: 'round')))
        .thenThrow(const NetworkException('Aloqa xatosi'));

    final result = await repository.getMatches(tournamentId: 't1');

    expect(result.isLeft, true);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (r) => fail('Should fail'),
    );
  });

  test('updateMatchScore updates score and returns entity', () async {
    when(() => mockRemoteDataSource.updateMatchScore('m1', 2, 1, 'finished'))
        .thenAnswer((_) async {});
    when(() => mockRemoteDataSource.getMatches(any()))
        .thenAnswer((_) async => [
              MatchDto(
                id: 'm1',
                tournamentId: 't1',
                round: 1,
                slotIndex: 0,
                timeSlot: '17:00 – 18:00',
                homeTeamId: 'team-1',
                awayTeamId: 'team-2',
                homeScore: 2,
                awayScore: 1,
                status: 'finished',
                createdAt: now.toIso8601String(),
                updatedAt: now.toIso8601String(),
              ),
            ]);

    final result = await repository.updateMatchScore(
      matchId: 'm1',
      homeScore: 2,
      awayScore: 1,
      status: MatchStatus.finished,
    );

    expect(result.isRight, true);
    result.fold(
      (l) => fail('Should succeed'),
      (updated) {
        expect(updated.homeScore, 2);
        expect(updated.awayScore, 1);
        expect(updated.status, MatchStatus.finished);
      },
    );
  });
}

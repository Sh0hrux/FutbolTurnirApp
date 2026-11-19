import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../schedule/domain/repositories/match_repository.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/standing_row_entity.dart';
import '../../domain/repositories/standings_repository.dart';
import '../../domain/services/standings_calculator.dart';

class StandingsRepositoryImpl implements StandingsRepository {
  final TeamRepository teamRepository;
  final MatchRepository matchRepository;

  StandingsRepositoryImpl({
    required this.teamRepository,
    required this.matchRepository,
  });

  @override
  Future<Either<Failure, List<StandingRowEntity>>> getStandings({
    required String tournamentId,
  }) async {
    final teamsResult = await teamRepository.getTeams(includeArchived: false);
    if (teamsResult.isLeft) {
      return Left(teamsResult.leftOrNull!);
    }
    final teams = teamsResult.rightOrNull!;

    final matchesResult = await matchRepository.getMatches(tournamentId: tournamentId);
    if (matchesResult.isLeft) {
      return Left(matchesResult.leftOrNull!);
    }
    final matches = matchesResult.rightOrNull!;

    final standings = StandingsCalculator.calculate(teams: teams, matches: matches);
    return Right(standings);
  }
}

import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/standing_row_entity.dart';

abstract class StandingsRepository {
  Future<Either<Failure, List<StandingRowEntity>>> getStandings({
    required String tournamentId,
  });
}

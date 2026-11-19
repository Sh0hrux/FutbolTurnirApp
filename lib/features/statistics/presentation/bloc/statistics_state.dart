import 'package:equatable/equatable.dart';
import '../../domain/entities/tournament_statistics_entity.dart';

sealed class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

class StatisticsSuccess extends StatisticsState {
  final TournamentStatisticsEntity statistics;

  const StatisticsSuccess(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class StatisticsFailure extends StatisticsState {
  final String message;

  const StatisticsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

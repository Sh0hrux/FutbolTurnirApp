import 'package:equatable/equatable.dart';

sealed class StandingsEvent extends Equatable {
  const StandingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStandingsEvent extends StandingsEvent {
  const LoadStandingsEvent();
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/standing_row_entity.dart';

sealed class StandingsState extends Equatable {
  const StandingsState();

  @override
  List<Object?> get props => [];
}

class StandingsInitial extends StandingsState {
  const StandingsInitial();
}

class StandingsLoading extends StandingsState {
  const StandingsLoading();
}

class StandingsSuccess extends StandingsState {
  final List<StandingRowEntity> standings;
  final bool isFromCache;
  final bool isOffline;
  final String? errorMessage;

  const StandingsSuccess({
    required this.standings,
    this.isFromCache = false,
    this.isOffline = false,
    this.errorMessage,
  });

  StandingsSuccess copyWith({
    List<StandingRowEntity>? standings,
    bool? isFromCache,
    bool? isOffline,
    String? errorMessage,
  }) {
    return StandingsSuccess(
      standings: standings ?? this.standings,
      isFromCache: isFromCache ?? this.isFromCache,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [standings, isFromCache, isOffline, errorMessage];
}

class StandingsFailure extends StandingsState {
  final String message;
  const StandingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

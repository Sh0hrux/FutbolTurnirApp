import 'package:equatable/equatable.dart';

class RoundRestEntity extends Equatable {
  final String id;
  final String tournamentId;
  final int round;
  final String teamId;
  final DateTime createdAt;

  const RoundRestEntity({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.teamId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, tournamentId, round, teamId, createdAt];
}

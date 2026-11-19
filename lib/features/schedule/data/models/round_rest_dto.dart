import 'package:json_annotation/json_annotation.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/round_rest_entity.dart';

part 'round_rest_dto.g.dart';

@JsonSerializable()
class RoundRestDto {
  final String id;
  final String tournamentId;
  final int round;
  final String teamId;
  final String createdAt;

  const RoundRestDto({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.teamId,
    required this.createdAt,
  });

  factory RoundRestDto.fromJson(Map<String, dynamic> json) => _$RoundRestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RoundRestDtoToJson(this);

  RoundRestEntity toEntity() => RoundRestEntity(
        id: id,
        tournamentId: tournamentId,
        round: round,
        teamId: teamId,
        createdAt: DateTime.parse(createdAt),
      );

  factory RoundRestDto.fromEntity(RoundRestEntity entity) => RoundRestDto(
        id: entity.id,
        tournamentId: entity.tournamentId,
        round: entity.round,
        teamId: entity.teamId,
        createdAt: entity.createdAt.toIso8601String(),
      );

  factory RoundRestDto.fromDrift(RoundRest row) => RoundRestDto(
        id: row.id,
        tournamentId: row.tournamentId,
        round: row.round,
        teamId: row.teamId,
        createdAt: row.createdAt.toIso8601String(),
      );
}

import 'package:json_annotation/json_annotation.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/match_entity.dart';

part 'match_dto.g.dart';

@JsonSerializable()
class MatchDto {
  final String id;
  final String tournamentId;
  final int round;
  final int slotIndex;
  final String timeSlot;
  final String homeTeamId;
  final String awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final String createdAt;
  final String updatedAt;

  const MatchDto({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.slotIndex,
    required this.timeSlot,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchDto.fromJson(Map<String, dynamic> json) => _$MatchDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MatchDtoToJson(this);

  MatchEntity toEntity() => MatchEntity(
        id: id,
        tournamentId: tournamentId,
        round: round,
        slotIndex: slotIndex,
        timeSlot: timeSlot,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        homeScore: homeScore,
        awayScore: awayScore,
        status: MatchStatus.fromString(status),
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory MatchDto.fromEntity(MatchEntity entity) => MatchDto(
        id: entity.id,
        tournamentId: entity.tournamentId,
        round: entity.round,
        slotIndex: entity.slotIndex,
        timeSlot: entity.timeSlot,
        homeTeamId: entity.homeTeamId,
        awayTeamId: entity.awayTeamId,
        homeScore: entity.homeScore,
        awayScore: entity.awayScore,
        status: entity.status.toDbString(),
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt.toIso8601String(),
      );

  factory MatchDto.fromDrift(Matche row) => MatchDto(
        id: row.id,
        tournamentId: row.tournamentId,
        round: row.round,
        slotIndex: row.slotIndex,
        timeSlot: row.timeSlot,
        homeTeamId: row.homeTeamId,
        awayTeamId: row.awayTeamId,
        homeScore: row.homeScore,
        awayScore: row.awayScore,
        status: row.status,
        createdAt: row.createdAt.toIso8601String(),
        updatedAt: row.updatedAt.toIso8601String(),
      );
}

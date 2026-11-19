import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/team_entity.dart';
import '../../../../core/database/app_database.dart';

part 'team_dto.g.dart';

@JsonSerializable()
class TeamDto {
  final String id;
  final String name;
  final int colorValue;
  final String? logoPath;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;

  const TeamDto({
    required this.id,
    required this.name,
    required this.colorValue,
    this.logoPath,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamDto.fromJson(Map<String, dynamic> json) => _$TeamDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TeamDtoToJson(this);

  TeamEntity toEntity() => TeamEntity(
        id: id,
        name: name,
        colorValue: colorValue,
        logoPath: logoPath,
        isArchived: isArchived,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory TeamDto.fromEntity(TeamEntity entity) => TeamDto(
        id: entity.id,
        name: entity.name,
        colorValue: entity.colorValue,
        logoPath: entity.logoPath,
        isArchived: entity.isArchived,
        createdAt: entity.createdAt.toIso8601String(),
        updatedAt: entity.updatedAt.toIso8601String(),
      );

  factory TeamDto.fromDrift(Team row) => TeamDto(
        id: row.id,
        name: row.name,
        colorValue: row.colorValue,
        logoPath: row.logoPath,
        isArchived: row.isArchived,
        createdAt: row.createdAt.toIso8601String(),
        updatedAt: row.updatedAt.toIso8601String(),
      );
}


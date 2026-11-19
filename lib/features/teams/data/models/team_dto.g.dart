// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamDto _$TeamDtoFromJson(Map<String, dynamic> json) => TeamDto(
  id: json['id'] as String,
  name: json['name'] as String,
  colorValue: (json['colorValue'] as num).toInt(),
  logoPath: json['logoPath'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$TeamDtoToJson(TeamDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'colorValue': instance.colorValue,
  'logoPath': instance.logoPath,
  'isArchived': instance.isArchived,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

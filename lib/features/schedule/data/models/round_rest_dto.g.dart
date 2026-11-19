// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_rest_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundRestDto _$RoundRestDtoFromJson(Map<String, dynamic> json) => RoundRestDto(
  id: json['id'] as String,
  tournamentId: json['tournamentId'] as String,
  round: (json['round'] as num).toInt(),
  teamId: json['teamId'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$RoundRestDtoToJson(RoundRestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'round': instance.round,
      'teamId': instance.teamId,
      'createdAt': instance.createdAt,
    };

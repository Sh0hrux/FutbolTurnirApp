// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchDto _$MatchDtoFromJson(Map<String, dynamic> json) => MatchDto(
  id: json['id'] as String,
  tournamentId: json['tournamentId'] as String,
  round: (json['round'] as num).toInt(),
  slotIndex: (json['slotIndex'] as num).toInt(),
  timeSlot: json['timeSlot'] as String,
  homeTeamId: json['homeTeamId'] as String,
  awayTeamId: json['awayTeamId'] as String,
  homeScore: (json['homeScore'] as num?)?.toInt(),
  awayScore: (json['awayScore'] as num?)?.toInt(),
  status: json['status'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$MatchDtoToJson(MatchDto instance) => <String, dynamic>{
  'id': instance.id,
  'tournamentId': instance.tournamentId,
  'round': instance.round,
  'slotIndex': instance.slotIndex,
  'timeSlot': instance.timeSlot,
  'homeTeamId': instance.homeTeamId,
  'awayTeamId': instance.awayTeamId,
  'homeScore': instance.homeScore,
  'awayScore': instance.awayScore,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

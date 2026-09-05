// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TournamentResultDto _$TournamentResultDtoFromJson(Map<String, dynamic> json) =>
    _TournamentResultDto(
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String,
      tournamentType: json['tournament_type'] as String,
      status: json['status'] as String,
      bannerImageUrl: json['banner_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      location: json['location'] as Map<String, dynamic>?,
      entryFee: json['entry_fee'],
      maxTeams: (json['max_teams'] as num?)?.toInt(),
      approvedTeamsCount: (json['approved_teams_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TournamentResultDtoToJson(
  _TournamentResultDto instance,
) => <String, dynamic>{
  'tournament_id': instance.tournamentId,
  'tournament_name': instance.tournamentName,
  'tournament_type': instance.tournamentType,
  'status': instance.status,
  'banner_image_url': instance.bannerImageUrl,
  'logo_url': instance.logoUrl,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'location': instance.location,
  'entry_fee': instance.entryFee,
  'max_teams': instance.maxTeams,
  'approved_teams_count': instance.approvedTeamsCount,
};

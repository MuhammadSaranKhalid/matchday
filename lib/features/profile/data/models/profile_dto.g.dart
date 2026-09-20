// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileDto _$ProfileDtoFromJson(Map<String, dynamic> json) => _ProfileDto(
  userId: json['user_id'] as String,
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
  bio: json['bio'] as String?,
  profilePhotoUrl: json['profile_photo_url'] as String?,
  coverPhotoUrl: json['cover_photo_url'] as String?,
  location: json['location'] as Map<String, dynamic>?,
  onboardedAt: json['onboarded_at'] as String?,
);

Map<String, dynamic> _$ProfileDtoToJson(_ProfileDto instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'display_name': instance.displayName,
      'bio': instance.bio,
      'profile_photo_url': instance.profilePhotoUrl,
      'cover_photo_url': instance.coverPhotoUrl,
      'location': instance.location,
      'onboarded_at': instance.onboardedAt,
    };

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/follow_list_entry.dart';

part 'follow_list_entry_dto.freezed.dart';
part 'follow_list_entry_dto.g.dart';

/// Wire-format mirror of a single entry in the `list-follow-list` edge
/// function response array.
///
/// Response shape (per edge-function contract):
/// ```json
/// {
///   "user_id": "<uuid>",
///   "display_name": "...",
///   "username": "...",
///   "avatar_url": "<url|null>",
///   "you_follow": true,
///   "they_follow_you": false
/// }
/// ```
@freezed
abstract class FollowListEntryDto with _$FollowListEntryDto {
  const factory FollowListEntryDto({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'you_follow') required bool youFollow,
    @JsonKey(name: 'they_follow_you') required bool theyFollowYou,
  }) = _FollowListEntryDto;

  // REQUIRED: private constructor allows the toEntity() custom method.
  const FollowListEntryDto._();

  factory FollowListEntryDto.fromJson(Map<String, dynamic> json) =>
      _$FollowListEntryDtoFromJson(json);

  /// Maps to the pure-Dart [FollowListEntry] domain entity.
  FollowListEntry toEntity() => FollowListEntry(
        userId: UserId(userId),
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        youFollow: youFollow,
        theyFollowYou: theyFollowYou,
      );
}

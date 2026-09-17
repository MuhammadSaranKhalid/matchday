// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_channel_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatChannelDto {

@JsonKey(name: 'chat_id') String get channelId;@JsonKey(name: 'channel_key') String get channelKey;@JsonKey(name: 'kind') String get kind;@JsonKey(name: 'context_type') String get contextType;@JsonKey(name: 'title') String? get title;@JsonKey(name: 'team_id') String? get teamId;@JsonKey(name: 'match_id') String? get matchId;@JsonKey(name: 'last_message_seq') int? get lastMessageSeq;@JsonKey(name: 'last_message_at') String? get lastMessageAt;@JsonKey(name: 'team_name') String? get teamName;@JsonKey(name: 'team_logo_url') String? get teamLogoUrl;@JsonKey(name: 'team_logo_monogram') String? get teamLogoMonogram;@JsonKey(name: 'team_primary_color') String? get teamPrimaryColor;@JsonKey(name: 'dm_other_user_id') String? get dmOtherUserId;@JsonKey(name: 'dm_other_user_name') String? get dmOtherUserName;@JsonKey(name: 'dm_other_user_username') String? get dmOtherUserUsername;@JsonKey(name: 'dm_other_user_avatar_url') String? get dmOtherUserAvatarUrl;@JsonKey(name: 'you_follow') bool get youFollow;@JsonKey(name: 'they_follow_you') bool get theyFollowYou;@JsonKey(name: 'is_accepted') bool get isAccepted;@JsonKey(name: 'is_pinned') bool get isPinned;@JsonKey(name: 'is_archived') bool get isArchived;@JsonKey(name: 'is_muted') bool get isMuted;@JsonKey(name: 'last_message_body') String? get lastMessageBody;@JsonKey(name: 'last_message_sender_id') String? get lastMessageSenderId;@JsonKey(name: 'last_message_from_me') bool get lastMessageFromMe;@JsonKey(name: 'unread_count') int get unreadCount;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of ChatChannelDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatChannelDtoCopyWith<ChatChannelDto> get copyWith => _$ChatChannelDtoCopyWithImpl<ChatChannelDto>(this as ChatChannelDto, _$identity);

  /// Serializes this ChatChannelDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatChannelDto&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelKey, channelKey) || other.channelKey == channelKey)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.contextType, contextType) || other.contextType == contextType)&&(identical(other.title, title) || other.title == title)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.lastMessageSeq, lastMessageSeq) || other.lastMessageSeq == lastMessageSeq)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.teamLogoUrl, teamLogoUrl) || other.teamLogoUrl == teamLogoUrl)&&(identical(other.teamLogoMonogram, teamLogoMonogram) || other.teamLogoMonogram == teamLogoMonogram)&&(identical(other.teamPrimaryColor, teamPrimaryColor) || other.teamPrimaryColor == teamPrimaryColor)&&(identical(other.dmOtherUserId, dmOtherUserId) || other.dmOtherUserId == dmOtherUserId)&&(identical(other.dmOtherUserName, dmOtherUserName) || other.dmOtherUserName == dmOtherUserName)&&(identical(other.dmOtherUserUsername, dmOtherUserUsername) || other.dmOtherUserUsername == dmOtherUserUsername)&&(identical(other.dmOtherUserAvatarUrl, dmOtherUserAvatarUrl) || other.dmOtherUserAvatarUrl == dmOtherUserAvatarUrl)&&(identical(other.youFollow, youFollow) || other.youFollow == youFollow)&&(identical(other.theyFollowYou, theyFollowYou) || other.theyFollowYou == theyFollowYou)&&(identical(other.isAccepted, isAccepted) || other.isAccepted == isAccepted)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.lastMessageBody, lastMessageBody) || other.lastMessageBody == lastMessageBody)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageFromMe, lastMessageFromMe) || other.lastMessageFromMe == lastMessageFromMe)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,channelId,channelKey,kind,contextType,title,teamId,matchId,lastMessageSeq,lastMessageAt,teamName,teamLogoUrl,teamLogoMonogram,teamPrimaryColor,dmOtherUserId,dmOtherUserName,dmOtherUserUsername,dmOtherUserAvatarUrl,youFollow,theyFollowYou,isAccepted,isPinned,isArchived,isMuted,lastMessageBody,lastMessageSenderId,lastMessageFromMe,unreadCount,createdAt,updatedAt]);

@override
String toString() {
  return 'ChatChannelDto(channelId: $channelId, channelKey: $channelKey, kind: $kind, contextType: $contextType, title: $title, teamId: $teamId, matchId: $matchId, lastMessageSeq: $lastMessageSeq, lastMessageAt: $lastMessageAt, teamName: $teamName, teamLogoUrl: $teamLogoUrl, teamLogoMonogram: $teamLogoMonogram, teamPrimaryColor: $teamPrimaryColor, dmOtherUserId: $dmOtherUserId, dmOtherUserName: $dmOtherUserName, dmOtherUserUsername: $dmOtherUserUsername, dmOtherUserAvatarUrl: $dmOtherUserAvatarUrl, youFollow: $youFollow, theyFollowYou: $theyFollowYou, isAccepted: $isAccepted, isPinned: $isPinned, isArchived: $isArchived, isMuted: $isMuted, lastMessageBody: $lastMessageBody, lastMessageSenderId: $lastMessageSenderId, lastMessageFromMe: $lastMessageFromMe, unreadCount: $unreadCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChatChannelDtoCopyWith<$Res>  {
  factory $ChatChannelDtoCopyWith(ChatChannelDto value, $Res Function(ChatChannelDto) _then) = _$ChatChannelDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'chat_id') String channelId,@JsonKey(name: 'channel_key') String channelKey,@JsonKey(name: 'kind') String kind,@JsonKey(name: 'context_type') String contextType,@JsonKey(name: 'title') String? title,@JsonKey(name: 'team_id') String? teamId,@JsonKey(name: 'match_id') String? matchId,@JsonKey(name: 'last_message_seq') int? lastMessageSeq,@JsonKey(name: 'last_message_at') String? lastMessageAt,@JsonKey(name: 'team_name') String? teamName,@JsonKey(name: 'team_logo_url') String? teamLogoUrl,@JsonKey(name: 'team_logo_monogram') String? teamLogoMonogram,@JsonKey(name: 'team_primary_color') String? teamPrimaryColor,@JsonKey(name: 'dm_other_user_id') String? dmOtherUserId,@JsonKey(name: 'dm_other_user_name') String? dmOtherUserName,@JsonKey(name: 'dm_other_user_username') String? dmOtherUserUsername,@JsonKey(name: 'dm_other_user_avatar_url') String? dmOtherUserAvatarUrl,@JsonKey(name: 'you_follow') bool youFollow,@JsonKey(name: 'they_follow_you') bool theyFollowYou,@JsonKey(name: 'is_accepted') bool isAccepted,@JsonKey(name: 'is_pinned') bool isPinned,@JsonKey(name: 'is_archived') bool isArchived,@JsonKey(name: 'is_muted') bool isMuted,@JsonKey(name: 'last_message_body') String? lastMessageBody,@JsonKey(name: 'last_message_sender_id') String? lastMessageSenderId,@JsonKey(name: 'last_message_from_me') bool lastMessageFromMe,@JsonKey(name: 'unread_count') int unreadCount,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$ChatChannelDtoCopyWithImpl<$Res>
    implements $ChatChannelDtoCopyWith<$Res> {
  _$ChatChannelDtoCopyWithImpl(this._self, this._then);

  final ChatChannelDto _self;
  final $Res Function(ChatChannelDto) _then;

/// Create a copy of ChatChannelDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = null,Object? channelKey = null,Object? kind = null,Object? contextType = null,Object? title = freezed,Object? teamId = freezed,Object? matchId = freezed,Object? lastMessageSeq = freezed,Object? lastMessageAt = freezed,Object? teamName = freezed,Object? teamLogoUrl = freezed,Object? teamLogoMonogram = freezed,Object? teamPrimaryColor = freezed,Object? dmOtherUserId = freezed,Object? dmOtherUserName = freezed,Object? dmOtherUserUsername = freezed,Object? dmOtherUserAvatarUrl = freezed,Object? youFollow = null,Object? theyFollowYou = null,Object? isAccepted = null,Object? isPinned = null,Object? isArchived = null,Object? isMuted = null,Object? lastMessageBody = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageFromMe = null,Object? unreadCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelKey: null == channelKey ? _self.channelKey : channelKey // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,contextType: null == contextType ? _self.contextType : contextType // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSeq: freezed == lastMessageSeq ? _self.lastMessageSeq : lastMessageSeq // ignore: cast_nullable_to_non_nullable
as int?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as String?,teamName: freezed == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String?,teamLogoUrl: freezed == teamLogoUrl ? _self.teamLogoUrl : teamLogoUrl // ignore: cast_nullable_to_non_nullable
as String?,teamLogoMonogram: freezed == teamLogoMonogram ? _self.teamLogoMonogram : teamLogoMonogram // ignore: cast_nullable_to_non_nullable
as String?,teamPrimaryColor: freezed == teamPrimaryColor ? _self.teamPrimaryColor : teamPrimaryColor // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserId: freezed == dmOtherUserId ? _self.dmOtherUserId : dmOtherUserId // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserName: freezed == dmOtherUserName ? _self.dmOtherUserName : dmOtherUserName // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserUsername: freezed == dmOtherUserUsername ? _self.dmOtherUserUsername : dmOtherUserUsername // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserAvatarUrl: freezed == dmOtherUserAvatarUrl ? _self.dmOtherUserAvatarUrl : dmOtherUserAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,youFollow: null == youFollow ? _self.youFollow : youFollow // ignore: cast_nullable_to_non_nullable
as bool,theyFollowYou: null == theyFollowYou ? _self.theyFollowYou : theyFollowYou // ignore: cast_nullable_to_non_nullable
as bool,isAccepted: null == isAccepted ? _self.isAccepted : isAccepted // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,lastMessageBody: freezed == lastMessageBody ? _self.lastMessageBody : lastMessageBody // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageFromMe: null == lastMessageFromMe ? _self.lastMessageFromMe : lastMessageFromMe // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatChannelDto].
extension ChatChannelDtoPatterns on ChatChannelDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatChannelDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatChannelDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatChannelDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatChannelDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatChannelDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatChannelDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'chat_id')  String channelId, @JsonKey(name: 'channel_key')  String channelKey, @JsonKey(name: 'kind')  String kind, @JsonKey(name: 'context_type')  String contextType, @JsonKey(name: 'title')  String? title, @JsonKey(name: 'team_id')  String? teamId, @JsonKey(name: 'match_id')  String? matchId, @JsonKey(name: 'last_message_seq')  int? lastMessageSeq, @JsonKey(name: 'last_message_at')  String? lastMessageAt, @JsonKey(name: 'team_name')  String? teamName, @JsonKey(name: 'team_logo_url')  String? teamLogoUrl, @JsonKey(name: 'team_logo_monogram')  String? teamLogoMonogram, @JsonKey(name: 'team_primary_color')  String? teamPrimaryColor, @JsonKey(name: 'dm_other_user_id')  String? dmOtherUserId, @JsonKey(name: 'dm_other_user_name')  String? dmOtherUserName, @JsonKey(name: 'dm_other_user_username')  String? dmOtherUserUsername, @JsonKey(name: 'dm_other_user_avatar_url')  String? dmOtherUserAvatarUrl, @JsonKey(name: 'you_follow')  bool youFollow, @JsonKey(name: 'they_follow_you')  bool theyFollowYou, @JsonKey(name: 'is_accepted')  bool isAccepted, @JsonKey(name: 'is_pinned')  bool isPinned, @JsonKey(name: 'is_archived')  bool isArchived, @JsonKey(name: 'is_muted')  bool isMuted, @JsonKey(name: 'last_message_body')  String? lastMessageBody, @JsonKey(name: 'last_message_sender_id')  String? lastMessageSenderId, @JsonKey(name: 'last_message_from_me')  bool lastMessageFromMe, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatChannelDto() when $default != null:
return $default(_that.channelId,_that.channelKey,_that.kind,_that.contextType,_that.title,_that.teamId,_that.matchId,_that.lastMessageSeq,_that.lastMessageAt,_that.teamName,_that.teamLogoUrl,_that.teamLogoMonogram,_that.teamPrimaryColor,_that.dmOtherUserId,_that.dmOtherUserName,_that.dmOtherUserUsername,_that.dmOtherUserAvatarUrl,_that.youFollow,_that.theyFollowYou,_that.isAccepted,_that.isPinned,_that.isArchived,_that.isMuted,_that.lastMessageBody,_that.lastMessageSenderId,_that.lastMessageFromMe,_that.unreadCount,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'chat_id')  String channelId, @JsonKey(name: 'channel_key')  String channelKey, @JsonKey(name: 'kind')  String kind, @JsonKey(name: 'context_type')  String contextType, @JsonKey(name: 'title')  String? title, @JsonKey(name: 'team_id')  String? teamId, @JsonKey(name: 'match_id')  String? matchId, @JsonKey(name: 'last_message_seq')  int? lastMessageSeq, @JsonKey(name: 'last_message_at')  String? lastMessageAt, @JsonKey(name: 'team_name')  String? teamName, @JsonKey(name: 'team_logo_url')  String? teamLogoUrl, @JsonKey(name: 'team_logo_monogram')  String? teamLogoMonogram, @JsonKey(name: 'team_primary_color')  String? teamPrimaryColor, @JsonKey(name: 'dm_other_user_id')  String? dmOtherUserId, @JsonKey(name: 'dm_other_user_name')  String? dmOtherUserName, @JsonKey(name: 'dm_other_user_username')  String? dmOtherUserUsername, @JsonKey(name: 'dm_other_user_avatar_url')  String? dmOtherUserAvatarUrl, @JsonKey(name: 'you_follow')  bool youFollow, @JsonKey(name: 'they_follow_you')  bool theyFollowYou, @JsonKey(name: 'is_accepted')  bool isAccepted, @JsonKey(name: 'is_pinned')  bool isPinned, @JsonKey(name: 'is_archived')  bool isArchived, @JsonKey(name: 'is_muted')  bool isMuted, @JsonKey(name: 'last_message_body')  String? lastMessageBody, @JsonKey(name: 'last_message_sender_id')  String? lastMessageSenderId, @JsonKey(name: 'last_message_from_me')  bool lastMessageFromMe, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatChannelDto():
return $default(_that.channelId,_that.channelKey,_that.kind,_that.contextType,_that.title,_that.teamId,_that.matchId,_that.lastMessageSeq,_that.lastMessageAt,_that.teamName,_that.teamLogoUrl,_that.teamLogoMonogram,_that.teamPrimaryColor,_that.dmOtherUserId,_that.dmOtherUserName,_that.dmOtherUserUsername,_that.dmOtherUserAvatarUrl,_that.youFollow,_that.theyFollowYou,_that.isAccepted,_that.isPinned,_that.isArchived,_that.isMuted,_that.lastMessageBody,_that.lastMessageSenderId,_that.lastMessageFromMe,_that.unreadCount,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'chat_id')  String channelId, @JsonKey(name: 'channel_key')  String channelKey, @JsonKey(name: 'kind')  String kind, @JsonKey(name: 'context_type')  String contextType, @JsonKey(name: 'title')  String? title, @JsonKey(name: 'team_id')  String? teamId, @JsonKey(name: 'match_id')  String? matchId, @JsonKey(name: 'last_message_seq')  int? lastMessageSeq, @JsonKey(name: 'last_message_at')  String? lastMessageAt, @JsonKey(name: 'team_name')  String? teamName, @JsonKey(name: 'team_logo_url')  String? teamLogoUrl, @JsonKey(name: 'team_logo_monogram')  String? teamLogoMonogram, @JsonKey(name: 'team_primary_color')  String? teamPrimaryColor, @JsonKey(name: 'dm_other_user_id')  String? dmOtherUserId, @JsonKey(name: 'dm_other_user_name')  String? dmOtherUserName, @JsonKey(name: 'dm_other_user_username')  String? dmOtherUserUsername, @JsonKey(name: 'dm_other_user_avatar_url')  String? dmOtherUserAvatarUrl, @JsonKey(name: 'you_follow')  bool youFollow, @JsonKey(name: 'they_follow_you')  bool theyFollowYou, @JsonKey(name: 'is_accepted')  bool isAccepted, @JsonKey(name: 'is_pinned')  bool isPinned, @JsonKey(name: 'is_archived')  bool isArchived, @JsonKey(name: 'is_muted')  bool isMuted, @JsonKey(name: 'last_message_body')  String? lastMessageBody, @JsonKey(name: 'last_message_sender_id')  String? lastMessageSenderId, @JsonKey(name: 'last_message_from_me')  bool lastMessageFromMe, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatChannelDto() when $default != null:
return $default(_that.channelId,_that.channelKey,_that.kind,_that.contextType,_that.title,_that.teamId,_that.matchId,_that.lastMessageSeq,_that.lastMessageAt,_that.teamName,_that.teamLogoUrl,_that.teamLogoMonogram,_that.teamPrimaryColor,_that.dmOtherUserId,_that.dmOtherUserName,_that.dmOtherUserUsername,_that.dmOtherUserAvatarUrl,_that.youFollow,_that.theyFollowYou,_that.isAccepted,_that.isPinned,_that.isArchived,_that.isMuted,_that.lastMessageBody,_that.lastMessageSenderId,_that.lastMessageFromMe,_that.unreadCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatChannelDto extends ChatChannelDto {
  const _ChatChannelDto({@JsonKey(name: 'chat_id') required this.channelId, @JsonKey(name: 'channel_key') required this.channelKey, @JsonKey(name: 'kind') required this.kind, @JsonKey(name: 'context_type') required this.contextType, @JsonKey(name: 'title') this.title, @JsonKey(name: 'team_id') this.teamId, @JsonKey(name: 'match_id') this.matchId, @JsonKey(name: 'last_message_seq') this.lastMessageSeq, @JsonKey(name: 'last_message_at') this.lastMessageAt, @JsonKey(name: 'team_name') this.teamName, @JsonKey(name: 'team_logo_url') this.teamLogoUrl, @JsonKey(name: 'team_logo_monogram') this.teamLogoMonogram, @JsonKey(name: 'team_primary_color') this.teamPrimaryColor, @JsonKey(name: 'dm_other_user_id') this.dmOtherUserId, @JsonKey(name: 'dm_other_user_name') this.dmOtherUserName, @JsonKey(name: 'dm_other_user_username') this.dmOtherUserUsername, @JsonKey(name: 'dm_other_user_avatar_url') this.dmOtherUserAvatarUrl, @JsonKey(name: 'you_follow') this.youFollow = false, @JsonKey(name: 'they_follow_you') this.theyFollowYou = false, @JsonKey(name: 'is_accepted') this.isAccepted = true, @JsonKey(name: 'is_pinned') this.isPinned = false, @JsonKey(name: 'is_archived') this.isArchived = false, @JsonKey(name: 'is_muted') this.isMuted = false, @JsonKey(name: 'last_message_body') this.lastMessageBody, @JsonKey(name: 'last_message_sender_id') this.lastMessageSenderId, @JsonKey(name: 'last_message_from_me') this.lastMessageFromMe = false, @JsonKey(name: 'unread_count') this.unreadCount = 0, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): super._();
  factory _ChatChannelDto.fromJson(Map<String, dynamic> json) => _$ChatChannelDtoFromJson(json);

@override@JsonKey(name: 'chat_id') final  String channelId;
@override@JsonKey(name: 'channel_key') final  String channelKey;
@override@JsonKey(name: 'kind') final  String kind;
@override@JsonKey(name: 'context_type') final  String contextType;
@override@JsonKey(name: 'title') final  String? title;
@override@JsonKey(name: 'team_id') final  String? teamId;
@override@JsonKey(name: 'match_id') final  String? matchId;
@override@JsonKey(name: 'last_message_seq') final  int? lastMessageSeq;
@override@JsonKey(name: 'last_message_at') final  String? lastMessageAt;
@override@JsonKey(name: 'team_name') final  String? teamName;
@override@JsonKey(name: 'team_logo_url') final  String? teamLogoUrl;
@override@JsonKey(name: 'team_logo_monogram') final  String? teamLogoMonogram;
@override@JsonKey(name: 'team_primary_color') final  String? teamPrimaryColor;
@override@JsonKey(name: 'dm_other_user_id') final  String? dmOtherUserId;
@override@JsonKey(name: 'dm_other_user_name') final  String? dmOtherUserName;
@override@JsonKey(name: 'dm_other_user_username') final  String? dmOtherUserUsername;
@override@JsonKey(name: 'dm_other_user_avatar_url') final  String? dmOtherUserAvatarUrl;
@override@JsonKey(name: 'you_follow') final  bool youFollow;
@override@JsonKey(name: 'they_follow_you') final  bool theyFollowYou;
@override@JsonKey(name: 'is_accepted') final  bool isAccepted;
@override@JsonKey(name: 'is_pinned') final  bool isPinned;
@override@JsonKey(name: 'is_archived') final  bool isArchived;
@override@JsonKey(name: 'is_muted') final  bool isMuted;
@override@JsonKey(name: 'last_message_body') final  String? lastMessageBody;
@override@JsonKey(name: 'last_message_sender_id') final  String? lastMessageSenderId;
@override@JsonKey(name: 'last_message_from_me') final  bool lastMessageFromMe;
@override@JsonKey(name: 'unread_count') final  int unreadCount;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of ChatChannelDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatChannelDtoCopyWith<_ChatChannelDto> get copyWith => __$ChatChannelDtoCopyWithImpl<_ChatChannelDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatChannelDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatChannelDto&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelKey, channelKey) || other.channelKey == channelKey)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.contextType, contextType) || other.contextType == contextType)&&(identical(other.title, title) || other.title == title)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.lastMessageSeq, lastMessageSeq) || other.lastMessageSeq == lastMessageSeq)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.teamLogoUrl, teamLogoUrl) || other.teamLogoUrl == teamLogoUrl)&&(identical(other.teamLogoMonogram, teamLogoMonogram) || other.teamLogoMonogram == teamLogoMonogram)&&(identical(other.teamPrimaryColor, teamPrimaryColor) || other.teamPrimaryColor == teamPrimaryColor)&&(identical(other.dmOtherUserId, dmOtherUserId) || other.dmOtherUserId == dmOtherUserId)&&(identical(other.dmOtherUserName, dmOtherUserName) || other.dmOtherUserName == dmOtherUserName)&&(identical(other.dmOtherUserUsername, dmOtherUserUsername) || other.dmOtherUserUsername == dmOtherUserUsername)&&(identical(other.dmOtherUserAvatarUrl, dmOtherUserAvatarUrl) || other.dmOtherUserAvatarUrl == dmOtherUserAvatarUrl)&&(identical(other.youFollow, youFollow) || other.youFollow == youFollow)&&(identical(other.theyFollowYou, theyFollowYou) || other.theyFollowYou == theyFollowYou)&&(identical(other.isAccepted, isAccepted) || other.isAccepted == isAccepted)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.lastMessageBody, lastMessageBody) || other.lastMessageBody == lastMessageBody)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageFromMe, lastMessageFromMe) || other.lastMessageFromMe == lastMessageFromMe)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,channelId,channelKey,kind,contextType,title,teamId,matchId,lastMessageSeq,lastMessageAt,teamName,teamLogoUrl,teamLogoMonogram,teamPrimaryColor,dmOtherUserId,dmOtherUserName,dmOtherUserUsername,dmOtherUserAvatarUrl,youFollow,theyFollowYou,isAccepted,isPinned,isArchived,isMuted,lastMessageBody,lastMessageSenderId,lastMessageFromMe,unreadCount,createdAt,updatedAt]);

@override
String toString() {
  return 'ChatChannelDto(channelId: $channelId, channelKey: $channelKey, kind: $kind, contextType: $contextType, title: $title, teamId: $teamId, matchId: $matchId, lastMessageSeq: $lastMessageSeq, lastMessageAt: $lastMessageAt, teamName: $teamName, teamLogoUrl: $teamLogoUrl, teamLogoMonogram: $teamLogoMonogram, teamPrimaryColor: $teamPrimaryColor, dmOtherUserId: $dmOtherUserId, dmOtherUserName: $dmOtherUserName, dmOtherUserUsername: $dmOtherUserUsername, dmOtherUserAvatarUrl: $dmOtherUserAvatarUrl, youFollow: $youFollow, theyFollowYou: $theyFollowYou, isAccepted: $isAccepted, isPinned: $isPinned, isArchived: $isArchived, isMuted: $isMuted, lastMessageBody: $lastMessageBody, lastMessageSenderId: $lastMessageSenderId, lastMessageFromMe: $lastMessageFromMe, unreadCount: $unreadCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatChannelDtoCopyWith<$Res> implements $ChatChannelDtoCopyWith<$Res> {
  factory _$ChatChannelDtoCopyWith(_ChatChannelDto value, $Res Function(_ChatChannelDto) _then) = __$ChatChannelDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'chat_id') String channelId,@JsonKey(name: 'channel_key') String channelKey,@JsonKey(name: 'kind') String kind,@JsonKey(name: 'context_type') String contextType,@JsonKey(name: 'title') String? title,@JsonKey(name: 'team_id') String? teamId,@JsonKey(name: 'match_id') String? matchId,@JsonKey(name: 'last_message_seq') int? lastMessageSeq,@JsonKey(name: 'last_message_at') String? lastMessageAt,@JsonKey(name: 'team_name') String? teamName,@JsonKey(name: 'team_logo_url') String? teamLogoUrl,@JsonKey(name: 'team_logo_monogram') String? teamLogoMonogram,@JsonKey(name: 'team_primary_color') String? teamPrimaryColor,@JsonKey(name: 'dm_other_user_id') String? dmOtherUserId,@JsonKey(name: 'dm_other_user_name') String? dmOtherUserName,@JsonKey(name: 'dm_other_user_username') String? dmOtherUserUsername,@JsonKey(name: 'dm_other_user_avatar_url') String? dmOtherUserAvatarUrl,@JsonKey(name: 'you_follow') bool youFollow,@JsonKey(name: 'they_follow_you') bool theyFollowYou,@JsonKey(name: 'is_accepted') bool isAccepted,@JsonKey(name: 'is_pinned') bool isPinned,@JsonKey(name: 'is_archived') bool isArchived,@JsonKey(name: 'is_muted') bool isMuted,@JsonKey(name: 'last_message_body') String? lastMessageBody,@JsonKey(name: 'last_message_sender_id') String? lastMessageSenderId,@JsonKey(name: 'last_message_from_me') bool lastMessageFromMe,@JsonKey(name: 'unread_count') int unreadCount,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$ChatChannelDtoCopyWithImpl<$Res>
    implements _$ChatChannelDtoCopyWith<$Res> {
  __$ChatChannelDtoCopyWithImpl(this._self, this._then);

  final _ChatChannelDto _self;
  final $Res Function(_ChatChannelDto) _then;

/// Create a copy of ChatChannelDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = null,Object? channelKey = null,Object? kind = null,Object? contextType = null,Object? title = freezed,Object? teamId = freezed,Object? matchId = freezed,Object? lastMessageSeq = freezed,Object? lastMessageAt = freezed,Object? teamName = freezed,Object? teamLogoUrl = freezed,Object? teamLogoMonogram = freezed,Object? teamPrimaryColor = freezed,Object? dmOtherUserId = freezed,Object? dmOtherUserName = freezed,Object? dmOtherUserUsername = freezed,Object? dmOtherUserAvatarUrl = freezed,Object? youFollow = null,Object? theyFollowYou = null,Object? isAccepted = null,Object? isPinned = null,Object? isArchived = null,Object? isMuted = null,Object? lastMessageBody = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageFromMe = null,Object? unreadCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ChatChannelDto(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelKey: null == channelKey ? _self.channelKey : channelKey // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,contextType: null == contextType ? _self.contextType : contextType // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSeq: freezed == lastMessageSeq ? _self.lastMessageSeq : lastMessageSeq // ignore: cast_nullable_to_non_nullable
as int?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as String?,teamName: freezed == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String?,teamLogoUrl: freezed == teamLogoUrl ? _self.teamLogoUrl : teamLogoUrl // ignore: cast_nullable_to_non_nullable
as String?,teamLogoMonogram: freezed == teamLogoMonogram ? _self.teamLogoMonogram : teamLogoMonogram // ignore: cast_nullable_to_non_nullable
as String?,teamPrimaryColor: freezed == teamPrimaryColor ? _self.teamPrimaryColor : teamPrimaryColor // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserId: freezed == dmOtherUserId ? _self.dmOtherUserId : dmOtherUserId // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserName: freezed == dmOtherUserName ? _self.dmOtherUserName : dmOtherUserName // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserUsername: freezed == dmOtherUserUsername ? _self.dmOtherUserUsername : dmOtherUserUsername // ignore: cast_nullable_to_non_nullable
as String?,dmOtherUserAvatarUrl: freezed == dmOtherUserAvatarUrl ? _self.dmOtherUserAvatarUrl : dmOtherUserAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,youFollow: null == youFollow ? _self.youFollow : youFollow // ignore: cast_nullable_to_non_nullable
as bool,theyFollowYou: null == theyFollowYou ? _self.theyFollowYou : theyFollowYou // ignore: cast_nullable_to_non_nullable
as bool,isAccepted: null == isAccepted ? _self.isAccepted : isAccepted // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,lastMessageBody: freezed == lastMessageBody ? _self.lastMessageBody : lastMessageBody // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageFromMe: null == lastMessageFromMe ? _self.lastMessageFromMe : lastMessageFromMe // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

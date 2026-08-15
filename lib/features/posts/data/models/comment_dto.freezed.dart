// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentDto {

@JsonKey(name: 'comment_id') String get commentId;@JsonKey(name: 'post_id') String get postId;@JsonKey(name: 'author_id') String get authorId;@JsonKey(name: 'parent_comment_id') String? get parentCommentId; String get text;@JsonKey(name: 'mentioned_user_ids') List<String> get mentionedUserIds;@JsonKey(name: 'likes_count') int get likesCount;@JsonKey(name: 'is_liked') bool get isLiked; String get status;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'edited_at') String? get editedAt; Map<String, dynamic>? get author;
/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentDtoCopyWith<CommentDto> get copyWith => _$CommentDtoCopyWithImpl<CommentDto>(this as CommentDto, _$identity);

  /// Serializes this CommentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentDto&&(identical(other.commentId, commentId) || other.commentId == commentId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.parentCommentId, parentCommentId) || other.parentCommentId == parentCommentId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.mentionedUserIds, mentionedUserIds)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&const DeepCollectionEquality().equals(other.author, author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commentId,postId,authorId,parentCommentId,text,const DeepCollectionEquality().hash(mentionedUserIds),likesCount,isLiked,status,createdAt,editedAt,const DeepCollectionEquality().hash(author));

@override
String toString() {
  return 'CommentDto(commentId: $commentId, postId: $postId, authorId: $authorId, parentCommentId: $parentCommentId, text: $text, mentionedUserIds: $mentionedUserIds, likesCount: $likesCount, isLiked: $isLiked, status: $status, createdAt: $createdAt, editedAt: $editedAt, author: $author)';
}


}

/// @nodoc
abstract mixin class $CommentDtoCopyWith<$Res>  {
  factory $CommentDtoCopyWith(CommentDto value, $Res Function(CommentDto) _then) = _$CommentDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'comment_id') String commentId,@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'author_id') String authorId,@JsonKey(name: 'parent_comment_id') String? parentCommentId, String text,@JsonKey(name: 'mentioned_user_ids') List<String> mentionedUserIds,@JsonKey(name: 'likes_count') int likesCount,@JsonKey(name: 'is_liked') bool isLiked, String status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'edited_at') String? editedAt, Map<String, dynamic>? author
});




}
/// @nodoc
class _$CommentDtoCopyWithImpl<$Res>
    implements $CommentDtoCopyWith<$Res> {
  _$CommentDtoCopyWithImpl(this._self, this._then);

  final CommentDto _self;
  final $Res Function(CommentDto) _then;

/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commentId = null,Object? postId = null,Object? authorId = null,Object? parentCommentId = freezed,Object? text = null,Object? mentionedUserIds = null,Object? likesCount = null,Object? isLiked = null,Object? status = null,Object? createdAt = null,Object? editedAt = freezed,Object? author = freezed,}) {
  return _then(_self.copyWith(
commentId: null == commentId ? _self.commentId : commentId // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,parentCommentId: freezed == parentCommentId ? _self.parentCommentId : parentCommentId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mentionedUserIds: null == mentionedUserIds ? _self.mentionedUserIds : mentionedUserIds // ignore: cast_nullable_to_non_nullable
as List<String>,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentDto].
extension CommentDtoPatterns on CommentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentDto value)  $default,){
final _that = this;
switch (_that) {
case _CommentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'comment_id')  String commentId, @JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'author_id')  String authorId, @JsonKey(name: 'parent_comment_id')  String? parentCommentId,  String text, @JsonKey(name: 'mentioned_user_ids')  List<String> mentionedUserIds, @JsonKey(name: 'likes_count')  int likesCount, @JsonKey(name: 'is_liked')  bool isLiked,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'edited_at')  String? editedAt,  Map<String, dynamic>? author)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
return $default(_that.commentId,_that.postId,_that.authorId,_that.parentCommentId,_that.text,_that.mentionedUserIds,_that.likesCount,_that.isLiked,_that.status,_that.createdAt,_that.editedAt,_that.author);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'comment_id')  String commentId, @JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'author_id')  String authorId, @JsonKey(name: 'parent_comment_id')  String? parentCommentId,  String text, @JsonKey(name: 'mentioned_user_ids')  List<String> mentionedUserIds, @JsonKey(name: 'likes_count')  int likesCount, @JsonKey(name: 'is_liked')  bool isLiked,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'edited_at')  String? editedAt,  Map<String, dynamic>? author)  $default,) {final _that = this;
switch (_that) {
case _CommentDto():
return $default(_that.commentId,_that.postId,_that.authorId,_that.parentCommentId,_that.text,_that.mentionedUserIds,_that.likesCount,_that.isLiked,_that.status,_that.createdAt,_that.editedAt,_that.author);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'comment_id')  String commentId, @JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'author_id')  String authorId, @JsonKey(name: 'parent_comment_id')  String? parentCommentId,  String text, @JsonKey(name: 'mentioned_user_ids')  List<String> mentionedUserIds, @JsonKey(name: 'likes_count')  int likesCount, @JsonKey(name: 'is_liked')  bool isLiked,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'edited_at')  String? editedAt,  Map<String, dynamic>? author)?  $default,) {final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
return $default(_that.commentId,_that.postId,_that.authorId,_that.parentCommentId,_that.text,_that.mentionedUserIds,_that.likesCount,_that.isLiked,_that.status,_that.createdAt,_that.editedAt,_that.author);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentDto extends CommentDto {
  const _CommentDto({@JsonKey(name: 'comment_id') required this.commentId, @JsonKey(name: 'post_id') required this.postId, @JsonKey(name: 'author_id') required this.authorId, @JsonKey(name: 'parent_comment_id') this.parentCommentId, required this.text, @JsonKey(name: 'mentioned_user_ids') final  List<String> mentionedUserIds = const <String>[], @JsonKey(name: 'likes_count') this.likesCount = 0, @JsonKey(name: 'is_liked') this.isLiked = false, this.status = 'active', @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'edited_at') this.editedAt, final  Map<String, dynamic>? author}): _mentionedUserIds = mentionedUserIds,_author = author,super._();
  factory _CommentDto.fromJson(Map<String, dynamic> json) => _$CommentDtoFromJson(json);

@override@JsonKey(name: 'comment_id') final  String commentId;
@override@JsonKey(name: 'post_id') final  String postId;
@override@JsonKey(name: 'author_id') final  String authorId;
@override@JsonKey(name: 'parent_comment_id') final  String? parentCommentId;
@override final  String text;
 final  List<String> _mentionedUserIds;
@override@JsonKey(name: 'mentioned_user_ids') List<String> get mentionedUserIds {
  if (_mentionedUserIds is EqualUnmodifiableListView) return _mentionedUserIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentionedUserIds);
}

@override@JsonKey(name: 'likes_count') final  int likesCount;
@override@JsonKey(name: 'is_liked') final  bool isLiked;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'edited_at') final  String? editedAt;
 final  Map<String, dynamic>? _author;
@override Map<String, dynamic>? get author {
  final value = _author;
  if (value == null) return null;
  if (_author is EqualUnmodifiableMapView) return _author;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentDtoCopyWith<_CommentDto> get copyWith => __$CommentDtoCopyWithImpl<_CommentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentDto&&(identical(other.commentId, commentId) || other.commentId == commentId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.parentCommentId, parentCommentId) || other.parentCommentId == parentCommentId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._mentionedUserIds, _mentionedUserIds)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&const DeepCollectionEquality().equals(other._author, _author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commentId,postId,authorId,parentCommentId,text,const DeepCollectionEquality().hash(_mentionedUserIds),likesCount,isLiked,status,createdAt,editedAt,const DeepCollectionEquality().hash(_author));

@override
String toString() {
  return 'CommentDto(commentId: $commentId, postId: $postId, authorId: $authorId, parentCommentId: $parentCommentId, text: $text, mentionedUserIds: $mentionedUserIds, likesCount: $likesCount, isLiked: $isLiked, status: $status, createdAt: $createdAt, editedAt: $editedAt, author: $author)';
}


}

/// @nodoc
abstract mixin class _$CommentDtoCopyWith<$Res> implements $CommentDtoCopyWith<$Res> {
  factory _$CommentDtoCopyWith(_CommentDto value, $Res Function(_CommentDto) _then) = __$CommentDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'comment_id') String commentId,@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'author_id') String authorId,@JsonKey(name: 'parent_comment_id') String? parentCommentId, String text,@JsonKey(name: 'mentioned_user_ids') List<String> mentionedUserIds,@JsonKey(name: 'likes_count') int likesCount,@JsonKey(name: 'is_liked') bool isLiked, String status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'edited_at') String? editedAt, Map<String, dynamic>? author
});




}
/// @nodoc
class __$CommentDtoCopyWithImpl<$Res>
    implements _$CommentDtoCopyWith<$Res> {
  __$CommentDtoCopyWithImpl(this._self, this._then);

  final _CommentDto _self;
  final $Res Function(_CommentDto) _then;

/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commentId = null,Object? postId = null,Object? authorId = null,Object? parentCommentId = freezed,Object? text = null,Object? mentionedUserIds = null,Object? likesCount = null,Object? isLiked = null,Object? status = null,Object? createdAt = null,Object? editedAt = freezed,Object? author = freezed,}) {
  return _then(_CommentDto(
commentId: null == commentId ? _self.commentId : commentId // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,parentCommentId: freezed == parentCommentId ? _self.parentCommentId : parentCommentId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mentionedUserIds: null == mentionedUserIds ? _self._mentionedUserIds : mentionedUserIds // ignore: cast_nullable_to_non_nullable
as List<String>,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self._author : author // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on

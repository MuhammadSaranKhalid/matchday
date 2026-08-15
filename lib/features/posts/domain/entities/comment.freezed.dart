// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Comment {

 String get id; String get postId; String get authorId; String? get parentCommentId; String get text; List<String> get mentionedUserIds; int get likesCount; bool get isLiked; CommentStatus get status; DateTime get createdAt; DateTime? get editedAt; String? get authorName; String? get authorUsername; String? get authorPhotoUrl; List<Comment> get replies;
/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentCopyWith<Comment> get copyWith => _$CommentCopyWithImpl<Comment>(this as Comment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comment&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.parentCommentId, parentCommentId) || other.parentCommentId == parentCommentId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.mentionedUserIds, mentionedUserIds)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorUsername, authorUsername) || other.authorUsername == authorUsername)&&(identical(other.authorPhotoUrl, authorPhotoUrl) || other.authorPhotoUrl == authorPhotoUrl)&&const DeepCollectionEquality().equals(other.replies, replies));
}


@override
int get hashCode => Object.hash(runtimeType,id,postId,authorId,parentCommentId,text,const DeepCollectionEquality().hash(mentionedUserIds),likesCount,isLiked,status,createdAt,editedAt,authorName,authorUsername,authorPhotoUrl,const DeepCollectionEquality().hash(replies));

@override
String toString() {
  return 'Comment(id: $id, postId: $postId, authorId: $authorId, parentCommentId: $parentCommentId, text: $text, mentionedUserIds: $mentionedUserIds, likesCount: $likesCount, isLiked: $isLiked, status: $status, createdAt: $createdAt, editedAt: $editedAt, authorName: $authorName, authorUsername: $authorUsername, authorPhotoUrl: $authorPhotoUrl, replies: $replies)';
}


}

/// @nodoc
abstract mixin class $CommentCopyWith<$Res>  {
  factory $CommentCopyWith(Comment value, $Res Function(Comment) _then) = _$CommentCopyWithImpl;
@useResult
$Res call({
 String id, String postId, String authorId, String? parentCommentId, String text, List<String> mentionedUserIds, int likesCount, bool isLiked, CommentStatus status, DateTime createdAt, DateTime? editedAt, String? authorName, String? authorUsername, String? authorPhotoUrl, List<Comment> replies
});




}
/// @nodoc
class _$CommentCopyWithImpl<$Res>
    implements $CommentCopyWith<$Res> {
  _$CommentCopyWithImpl(this._self, this._then);

  final Comment _self;
  final $Res Function(Comment) _then;

/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? postId = null,Object? authorId = null,Object? parentCommentId = freezed,Object? text = null,Object? mentionedUserIds = null,Object? likesCount = null,Object? isLiked = null,Object? status = null,Object? createdAt = null,Object? editedAt = freezed,Object? authorName = freezed,Object? authorUsername = freezed,Object? authorPhotoUrl = freezed,Object? replies = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,parentCommentId: freezed == parentCommentId ? _self.parentCommentId : parentCommentId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mentionedUserIds: null == mentionedUserIds ? _self.mentionedUserIds : mentionedUserIds // ignore: cast_nullable_to_non_nullable
as List<String>,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,authorUsername: freezed == authorUsername ? _self.authorUsername : authorUsername // ignore: cast_nullable_to_non_nullable
as String?,authorPhotoUrl: freezed == authorPhotoUrl ? _self.authorPhotoUrl : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<Comment>,
  ));
}

}


/// Adds pattern-matching-related methods to [Comment].
extension CommentPatterns on Comment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comment value)  $default,){
final _that = this;
switch (_that) {
case _Comment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comment value)?  $default,){
final _that = this;
switch (_that) {
case _Comment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String postId,  String authorId,  String? parentCommentId,  String text,  List<String> mentionedUserIds,  int likesCount,  bool isLiked,  CommentStatus status,  DateTime createdAt,  DateTime? editedAt,  String? authorName,  String? authorUsername,  String? authorPhotoUrl,  List<Comment> replies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comment() when $default != null:
return $default(_that.id,_that.postId,_that.authorId,_that.parentCommentId,_that.text,_that.mentionedUserIds,_that.likesCount,_that.isLiked,_that.status,_that.createdAt,_that.editedAt,_that.authorName,_that.authorUsername,_that.authorPhotoUrl,_that.replies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String postId,  String authorId,  String? parentCommentId,  String text,  List<String> mentionedUserIds,  int likesCount,  bool isLiked,  CommentStatus status,  DateTime createdAt,  DateTime? editedAt,  String? authorName,  String? authorUsername,  String? authorPhotoUrl,  List<Comment> replies)  $default,) {final _that = this;
switch (_that) {
case _Comment():
return $default(_that.id,_that.postId,_that.authorId,_that.parentCommentId,_that.text,_that.mentionedUserIds,_that.likesCount,_that.isLiked,_that.status,_that.createdAt,_that.editedAt,_that.authorName,_that.authorUsername,_that.authorPhotoUrl,_that.replies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String postId,  String authorId,  String? parentCommentId,  String text,  List<String> mentionedUserIds,  int likesCount,  bool isLiked,  CommentStatus status,  DateTime createdAt,  DateTime? editedAt,  String? authorName,  String? authorUsername,  String? authorPhotoUrl,  List<Comment> replies)?  $default,) {final _that = this;
switch (_that) {
case _Comment() when $default != null:
return $default(_that.id,_that.postId,_that.authorId,_that.parentCommentId,_that.text,_that.mentionedUserIds,_that.likesCount,_that.isLiked,_that.status,_that.createdAt,_that.editedAt,_that.authorName,_that.authorUsername,_that.authorPhotoUrl,_that.replies);case _:
  return null;

}
}

}

/// @nodoc


class _Comment extends Comment {
  const _Comment({required this.id, required this.postId, required this.authorId, this.parentCommentId, required this.text, final  List<String> mentionedUserIds = const [], this.likesCount = 0, this.isLiked = false, this.status = CommentStatus.active, required this.createdAt, this.editedAt, this.authorName, this.authorUsername, this.authorPhotoUrl, final  List<Comment> replies = const []}): _mentionedUserIds = mentionedUserIds,_replies = replies,super._();
  

@override final  String id;
@override final  String postId;
@override final  String authorId;
@override final  String? parentCommentId;
@override final  String text;
 final  List<String> _mentionedUserIds;
@override@JsonKey() List<String> get mentionedUserIds {
  if (_mentionedUserIds is EqualUnmodifiableListView) return _mentionedUserIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentionedUserIds);
}

@override@JsonKey() final  int likesCount;
@override@JsonKey() final  bool isLiked;
@override@JsonKey() final  CommentStatus status;
@override final  DateTime createdAt;
@override final  DateTime? editedAt;
@override final  String? authorName;
@override final  String? authorUsername;
@override final  String? authorPhotoUrl;
 final  List<Comment> _replies;
@override@JsonKey() List<Comment> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}


/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentCopyWith<_Comment> get copyWith => __$CommentCopyWithImpl<_Comment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comment&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.parentCommentId, parentCommentId) || other.parentCommentId == parentCommentId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._mentionedUserIds, _mentionedUserIds)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorUsername, authorUsername) || other.authorUsername == authorUsername)&&(identical(other.authorPhotoUrl, authorPhotoUrl) || other.authorPhotoUrl == authorPhotoUrl)&&const DeepCollectionEquality().equals(other._replies, _replies));
}


@override
int get hashCode => Object.hash(runtimeType,id,postId,authorId,parentCommentId,text,const DeepCollectionEquality().hash(_mentionedUserIds),likesCount,isLiked,status,createdAt,editedAt,authorName,authorUsername,authorPhotoUrl,const DeepCollectionEquality().hash(_replies));

@override
String toString() {
  return 'Comment(id: $id, postId: $postId, authorId: $authorId, parentCommentId: $parentCommentId, text: $text, mentionedUserIds: $mentionedUserIds, likesCount: $likesCount, isLiked: $isLiked, status: $status, createdAt: $createdAt, editedAt: $editedAt, authorName: $authorName, authorUsername: $authorUsername, authorPhotoUrl: $authorPhotoUrl, replies: $replies)';
}


}

/// @nodoc
abstract mixin class _$CommentCopyWith<$Res> implements $CommentCopyWith<$Res> {
  factory _$CommentCopyWith(_Comment value, $Res Function(_Comment) _then) = __$CommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String postId, String authorId, String? parentCommentId, String text, List<String> mentionedUserIds, int likesCount, bool isLiked, CommentStatus status, DateTime createdAt, DateTime? editedAt, String? authorName, String? authorUsername, String? authorPhotoUrl, List<Comment> replies
});




}
/// @nodoc
class __$CommentCopyWithImpl<$Res>
    implements _$CommentCopyWith<$Res> {
  __$CommentCopyWithImpl(this._self, this._then);

  final _Comment _self;
  final $Res Function(_Comment) _then;

/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? postId = null,Object? authorId = null,Object? parentCommentId = freezed,Object? text = null,Object? mentionedUserIds = null,Object? likesCount = null,Object? isLiked = null,Object? status = null,Object? createdAt = null,Object? editedAt = freezed,Object? authorName = freezed,Object? authorUsername = freezed,Object? authorPhotoUrl = freezed,Object? replies = null,}) {
  return _then(_Comment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,parentCommentId: freezed == parentCommentId ? _self.parentCommentId : parentCommentId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mentionedUserIds: null == mentionedUserIds ? _self._mentionedUserIds : mentionedUserIds // ignore: cast_nullable_to_non_nullable
as List<String>,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,authorUsername: freezed == authorUsername ? _self.authorUsername : authorUsername // ignore: cast_nullable_to_non_nullable
as String?,authorPhotoUrl: freezed == authorPhotoUrl ? _self.authorPhotoUrl : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<Comment>,
  ));
}


}

// dart format on

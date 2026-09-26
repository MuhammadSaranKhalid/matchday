// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostPublisherDto {

 String get id; String get type;@JsonKey(name: 'display_name') String get displayName; String? get username;@JsonKey(name: 'photo_url') String? get photoUrl;
/// Create a copy of PostPublisherDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostPublisherDtoCopyWith<PostPublisherDto> get copyWith => _$PostPublisherDtoCopyWithImpl<PostPublisherDto>(this as PostPublisherDto, _$identity);

  /// Serializes this PostPublisherDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostPublisherDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,displayName,username,photoUrl);

@override
String toString() {
  return 'PostPublisherDto(id: $id, type: $type, displayName: $displayName, username: $username, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class $PostPublisherDtoCopyWith<$Res>  {
  factory $PostPublisherDtoCopyWith(PostPublisherDto value, $Res Function(PostPublisherDto) _then) = _$PostPublisherDtoCopyWithImpl;
@useResult
$Res call({
 String id, String type,@JsonKey(name: 'display_name') String displayName, String? username,@JsonKey(name: 'photo_url') String? photoUrl
});




}
/// @nodoc
class _$PostPublisherDtoCopyWithImpl<$Res>
    implements $PostPublisherDtoCopyWith<$Res> {
  _$PostPublisherDtoCopyWithImpl(this._self, this._then);

  final PostPublisherDto _self;
  final $Res Function(PostPublisherDto) _then;

/// Create a copy of PostPublisherDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? displayName = null,Object? username = freezed,Object? photoUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PostPublisherDto].
extension PostPublisherDtoPatterns on PostPublisherDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostPublisherDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostPublisherDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostPublisherDto value)  $default,){
final _that = this;
switch (_that) {
case _PostPublisherDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostPublisherDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostPublisherDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type, @JsonKey(name: 'display_name')  String displayName,  String? username, @JsonKey(name: 'photo_url')  String? photoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostPublisherDto() when $default != null:
return $default(_that.id,_that.type,_that.displayName,_that.username,_that.photoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type, @JsonKey(name: 'display_name')  String displayName,  String? username, @JsonKey(name: 'photo_url')  String? photoUrl)  $default,) {final _that = this;
switch (_that) {
case _PostPublisherDto():
return $default(_that.id,_that.type,_that.displayName,_that.username,_that.photoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type, @JsonKey(name: 'display_name')  String displayName,  String? username, @JsonKey(name: 'photo_url')  String? photoUrl)?  $default,) {final _that = this;
switch (_that) {
case _PostPublisherDto() when $default != null:
return $default(_that.id,_that.type,_that.displayName,_that.username,_that.photoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostPublisherDto extends PostPublisherDto {
  const _PostPublisherDto({required this.id, this.type = 'user', @JsonKey(name: 'display_name') required this.displayName, this.username, @JsonKey(name: 'photo_url') this.photoUrl}): super._();
  factory _PostPublisherDto.fromJson(Map<String, dynamic> json) => _$PostPublisherDtoFromJson(json);

@override final  String id;
@override@JsonKey() final  String type;
@override@JsonKey(name: 'display_name') final  String displayName;
@override final  String? username;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;

/// Create a copy of PostPublisherDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostPublisherDtoCopyWith<_PostPublisherDto> get copyWith => __$PostPublisherDtoCopyWithImpl<_PostPublisherDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostPublisherDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostPublisherDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,displayName,username,photoUrl);

@override
String toString() {
  return 'PostPublisherDto(id: $id, type: $type, displayName: $displayName, username: $username, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class _$PostPublisherDtoCopyWith<$Res> implements $PostPublisherDtoCopyWith<$Res> {
  factory _$PostPublisherDtoCopyWith(_PostPublisherDto value, $Res Function(_PostPublisherDto) _then) = __$PostPublisherDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String type,@JsonKey(name: 'display_name') String displayName, String? username,@JsonKey(name: 'photo_url') String? photoUrl
});




}
/// @nodoc
class __$PostPublisherDtoCopyWithImpl<$Res>
    implements _$PostPublisherDtoCopyWith<$Res> {
  __$PostPublisherDtoCopyWithImpl(this._self, this._then);

  final _PostPublisherDto _self;
  final $Res Function(_PostPublisherDto) _then;

/// Create a copy of PostPublisherDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? displayName = null,Object? username = freezed,Object? photoUrl = freezed,}) {
  return _then(_PostPublisherDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PostCountsDto {

 int get likes; int get comments; int get shares;
/// Create a copy of PostCountsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCountsDtoCopyWith<PostCountsDto> get copyWith => _$PostCountsDtoCopyWithImpl<PostCountsDto>(this as PostCountsDto, _$identity);

  /// Serializes this PostCountsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostCountsDto&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.shares, shares) || other.shares == shares));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,likes,comments,shares);

@override
String toString() {
  return 'PostCountsDto(likes: $likes, comments: $comments, shares: $shares)';
}


}

/// @nodoc
abstract mixin class $PostCountsDtoCopyWith<$Res>  {
  factory $PostCountsDtoCopyWith(PostCountsDto value, $Res Function(PostCountsDto) _then) = _$PostCountsDtoCopyWithImpl;
@useResult
$Res call({
 int likes, int comments, int shares
});




}
/// @nodoc
class _$PostCountsDtoCopyWithImpl<$Res>
    implements $PostCountsDtoCopyWith<$Res> {
  _$PostCountsDtoCopyWithImpl(this._self, this._then);

  final PostCountsDto _self;
  final $Res Function(PostCountsDto) _then;

/// Create a copy of PostCountsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? likes = null,Object? comments = null,Object? shares = null,}) {
  return _then(_self.copyWith(
likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as int,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PostCountsDto].
extension PostCountsDtoPatterns on PostCountsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostCountsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostCountsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostCountsDto value)  $default,){
final _that = this;
switch (_that) {
case _PostCountsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostCountsDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostCountsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int likes,  int comments,  int shares)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostCountsDto() when $default != null:
return $default(_that.likes,_that.comments,_that.shares);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int likes,  int comments,  int shares)  $default,) {final _that = this;
switch (_that) {
case _PostCountsDto():
return $default(_that.likes,_that.comments,_that.shares);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int likes,  int comments,  int shares)?  $default,) {final _that = this;
switch (_that) {
case _PostCountsDto() when $default != null:
return $default(_that.likes,_that.comments,_that.shares);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostCountsDto extends PostCountsDto {
  const _PostCountsDto({this.likes = 0, this.comments = 0, this.shares = 0}): super._();
  factory _PostCountsDto.fromJson(Map<String, dynamic> json) => _$PostCountsDtoFromJson(json);

@override@JsonKey() final  int likes;
@override@JsonKey() final  int comments;
@override@JsonKey() final  int shares;

/// Create a copy of PostCountsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCountsDtoCopyWith<_PostCountsDto> get copyWith => __$PostCountsDtoCopyWithImpl<_PostCountsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostCountsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostCountsDto&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.shares, shares) || other.shares == shares));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,likes,comments,shares);

@override
String toString() {
  return 'PostCountsDto(likes: $likes, comments: $comments, shares: $shares)';
}


}

/// @nodoc
abstract mixin class _$PostCountsDtoCopyWith<$Res> implements $PostCountsDtoCopyWith<$Res> {
  factory _$PostCountsDtoCopyWith(_PostCountsDto value, $Res Function(_PostCountsDto) _then) = __$PostCountsDtoCopyWithImpl;
@override @useResult
$Res call({
 int likes, int comments, int shares
});




}
/// @nodoc
class __$PostCountsDtoCopyWithImpl<$Res>
    implements _$PostCountsDtoCopyWith<$Res> {
  __$PostCountsDtoCopyWithImpl(this._self, this._then);

  final _PostCountsDto _self;
  final $Res Function(_PostCountsDto) _then;

/// Create a copy of PostCountsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? likes = null,Object? comments = null,Object? shares = null,}) {
  return _then(_PostCountsDto(
likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as int,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PostViewerInteractionsDto {

 bool get liked; bool get bookmarked;@JsonKey(name: 'following_publisher') bool get followingPublisher;
/// Create a copy of PostViewerInteractionsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostViewerInteractionsDtoCopyWith<PostViewerInteractionsDto> get copyWith => _$PostViewerInteractionsDtoCopyWithImpl<PostViewerInteractionsDto>(this as PostViewerInteractionsDto, _$identity);

  /// Serializes this PostViewerInteractionsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostViewerInteractionsDto&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.bookmarked, bookmarked) || other.bookmarked == bookmarked)&&(identical(other.followingPublisher, followingPublisher) || other.followingPublisher == followingPublisher));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liked,bookmarked,followingPublisher);

@override
String toString() {
  return 'PostViewerInteractionsDto(liked: $liked, bookmarked: $bookmarked, followingPublisher: $followingPublisher)';
}


}

/// @nodoc
abstract mixin class $PostViewerInteractionsDtoCopyWith<$Res>  {
  factory $PostViewerInteractionsDtoCopyWith(PostViewerInteractionsDto value, $Res Function(PostViewerInteractionsDto) _then) = _$PostViewerInteractionsDtoCopyWithImpl;
@useResult
$Res call({
 bool liked, bool bookmarked,@JsonKey(name: 'following_publisher') bool followingPublisher
});




}
/// @nodoc
class _$PostViewerInteractionsDtoCopyWithImpl<$Res>
    implements $PostViewerInteractionsDtoCopyWith<$Res> {
  _$PostViewerInteractionsDtoCopyWithImpl(this._self, this._then);

  final PostViewerInteractionsDto _self;
  final $Res Function(PostViewerInteractionsDto) _then;

/// Create a copy of PostViewerInteractionsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? liked = null,Object? bookmarked = null,Object? followingPublisher = null,}) {
  return _then(_self.copyWith(
liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,bookmarked: null == bookmarked ? _self.bookmarked : bookmarked // ignore: cast_nullable_to_non_nullable
as bool,followingPublisher: null == followingPublisher ? _self.followingPublisher : followingPublisher // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PostViewerInteractionsDto].
extension PostViewerInteractionsDtoPatterns on PostViewerInteractionsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostViewerInteractionsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostViewerInteractionsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostViewerInteractionsDto value)  $default,){
final _that = this;
switch (_that) {
case _PostViewerInteractionsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostViewerInteractionsDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostViewerInteractionsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool liked,  bool bookmarked, @JsonKey(name: 'following_publisher')  bool followingPublisher)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostViewerInteractionsDto() when $default != null:
return $default(_that.liked,_that.bookmarked,_that.followingPublisher);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool liked,  bool bookmarked, @JsonKey(name: 'following_publisher')  bool followingPublisher)  $default,) {final _that = this;
switch (_that) {
case _PostViewerInteractionsDto():
return $default(_that.liked,_that.bookmarked,_that.followingPublisher);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool liked,  bool bookmarked, @JsonKey(name: 'following_publisher')  bool followingPublisher)?  $default,) {final _that = this;
switch (_that) {
case _PostViewerInteractionsDto() when $default != null:
return $default(_that.liked,_that.bookmarked,_that.followingPublisher);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostViewerInteractionsDto extends PostViewerInteractionsDto {
  const _PostViewerInteractionsDto({this.liked = false, this.bookmarked = false, @JsonKey(name: 'following_publisher') this.followingPublisher = false}): super._();
  factory _PostViewerInteractionsDto.fromJson(Map<String, dynamic> json) => _$PostViewerInteractionsDtoFromJson(json);

@override@JsonKey() final  bool liked;
@override@JsonKey() final  bool bookmarked;
@override@JsonKey(name: 'following_publisher') final  bool followingPublisher;

/// Create a copy of PostViewerInteractionsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostViewerInteractionsDtoCopyWith<_PostViewerInteractionsDto> get copyWith => __$PostViewerInteractionsDtoCopyWithImpl<_PostViewerInteractionsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostViewerInteractionsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostViewerInteractionsDto&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.bookmarked, bookmarked) || other.bookmarked == bookmarked)&&(identical(other.followingPublisher, followingPublisher) || other.followingPublisher == followingPublisher));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liked,bookmarked,followingPublisher);

@override
String toString() {
  return 'PostViewerInteractionsDto(liked: $liked, bookmarked: $bookmarked, followingPublisher: $followingPublisher)';
}


}

/// @nodoc
abstract mixin class _$PostViewerInteractionsDtoCopyWith<$Res> implements $PostViewerInteractionsDtoCopyWith<$Res> {
  factory _$PostViewerInteractionsDtoCopyWith(_PostViewerInteractionsDto value, $Res Function(_PostViewerInteractionsDto) _then) = __$PostViewerInteractionsDtoCopyWithImpl;
@override @useResult
$Res call({
 bool liked, bool bookmarked,@JsonKey(name: 'following_publisher') bool followingPublisher
});




}
/// @nodoc
class __$PostViewerInteractionsDtoCopyWithImpl<$Res>
    implements _$PostViewerInteractionsDtoCopyWith<$Res> {
  __$PostViewerInteractionsDtoCopyWithImpl(this._self, this._then);

  final _PostViewerInteractionsDto _self;
  final $Res Function(_PostViewerInteractionsDto) _then;

/// Create a copy of PostViewerInteractionsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? liked = null,Object? bookmarked = null,Object? followingPublisher = null,}) {
  return _then(_PostViewerInteractionsDto(
liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,bookmarked: null == bookmarked ? _self.bookmarked : bookmarked // ignore: cast_nullable_to_non_nullable
as bool,followingPublisher: null == followingPublisher ? _self.followingPublisher : followingPublisher // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PostDto {

@JsonKey(name: 'post_id') String get postId;@JsonKey(name: 'created_by_user_id') String? get createdByUserId;@JsonKey(name: 'author_id') String? get authorId; Map<String, dynamic>? get publisher;@JsonKey(name: 'post_kind') String get postKind;@JsonKey(name: 'post_type') String? get postType; String? get text; String get visibility; String get status;@JsonKey(name: 'expected_media_count') int get expectedMediaCount; List<dynamic> get media; Map<String, dynamic>? get counts; Map<String, dynamic>? get viewer;@JsonKey(name: 'published_at') String? get publishedAt;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'linked_match_id') String? get linkedMatchId;@JsonKey(name: 'linked_tournament_id') String? get linkedTournamentId;@JsonKey(name: 'linked_team_id') String? get linkedTeamId; Map<String, dynamic>? get author; Map<String, dynamic>? get team;@JsonKey(name: 'is_liked') bool get isLiked;@JsonKey(name: 'is_bookmarked') bool get isBookmarked;@JsonKey(name: 'likes_count') int get likesCount;@JsonKey(name: 'comments_count') int get commentsCount;@JsonKey(name: 'shares_count') int get sharesCount;
/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDtoCopyWith<PostDto> get copyWith => _$PostDtoCopyWithImpl<PostDto>(this as PostDto, _$identity);

  /// Serializes this PostDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDto&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&const DeepCollectionEquality().equals(other.publisher, publisher)&&(identical(other.postKind, postKind) || other.postKind == postKind)&&(identical(other.postType, postType) || other.postType == postType)&&(identical(other.text, text) || other.text == text)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.status, status) || other.status == status)&&(identical(other.expectedMediaCount, expectedMediaCount) || other.expectedMediaCount == expectedMediaCount)&&const DeepCollectionEquality().equals(other.media, media)&&const DeepCollectionEquality().equals(other.counts, counts)&&const DeepCollectionEquality().equals(other.viewer, viewer)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.linkedMatchId, linkedMatchId) || other.linkedMatchId == linkedMatchId)&&(identical(other.linkedTournamentId, linkedTournamentId) || other.linkedTournamentId == linkedTournamentId)&&(identical(other.linkedTeamId, linkedTeamId) || other.linkedTeamId == linkedTeamId)&&const DeepCollectionEquality().equals(other.author, author)&&const DeepCollectionEquality().equals(other.team, team)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,postId,createdByUserId,authorId,const DeepCollectionEquality().hash(publisher),postKind,postType,text,visibility,status,expectedMediaCount,const DeepCollectionEquality().hash(media),const DeepCollectionEquality().hash(counts),const DeepCollectionEquality().hash(viewer),publishedAt,createdAt,linkedMatchId,linkedTournamentId,linkedTeamId,const DeepCollectionEquality().hash(author),const DeepCollectionEquality().hash(team),isLiked,isBookmarked,likesCount,commentsCount,sharesCount]);

@override
String toString() {
  return 'PostDto(postId: $postId, createdByUserId: $createdByUserId, authorId: $authorId, publisher: $publisher, postKind: $postKind, postType: $postType, text: $text, visibility: $visibility, status: $status, expectedMediaCount: $expectedMediaCount, media: $media, counts: $counts, viewer: $viewer, publishedAt: $publishedAt, createdAt: $createdAt, linkedMatchId: $linkedMatchId, linkedTournamentId: $linkedTournamentId, linkedTeamId: $linkedTeamId, author: $author, team: $team, isLiked: $isLiked, isBookmarked: $isBookmarked, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount)';
}


}

/// @nodoc
abstract mixin class $PostDtoCopyWith<$Res>  {
  factory $PostDtoCopyWith(PostDto value, $Res Function(PostDto) _then) = _$PostDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'created_by_user_id') String? createdByUserId,@JsonKey(name: 'author_id') String? authorId, Map<String, dynamic>? publisher,@JsonKey(name: 'post_kind') String postKind,@JsonKey(name: 'post_type') String? postType, String? text, String visibility, String status,@JsonKey(name: 'expected_media_count') int expectedMediaCount, List<dynamic> media, Map<String, dynamic>? counts, Map<String, dynamic>? viewer,@JsonKey(name: 'published_at') String? publishedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'linked_match_id') String? linkedMatchId,@JsonKey(name: 'linked_tournament_id') String? linkedTournamentId,@JsonKey(name: 'linked_team_id') String? linkedTeamId, Map<String, dynamic>? author, Map<String, dynamic>? team,@JsonKey(name: 'is_liked') bool isLiked,@JsonKey(name: 'is_bookmarked') bool isBookmarked,@JsonKey(name: 'likes_count') int likesCount,@JsonKey(name: 'comments_count') int commentsCount,@JsonKey(name: 'shares_count') int sharesCount
});




}
/// @nodoc
class _$PostDtoCopyWithImpl<$Res>
    implements $PostDtoCopyWith<$Res> {
  _$PostDtoCopyWithImpl(this._self, this._then);

  final PostDto _self;
  final $Res Function(PostDto) _then;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? postId = null,Object? createdByUserId = freezed,Object? authorId = freezed,Object? publisher = freezed,Object? postKind = null,Object? postType = freezed,Object? text = freezed,Object? visibility = null,Object? status = null,Object? expectedMediaCount = null,Object? media = null,Object? counts = freezed,Object? viewer = freezed,Object? publishedAt = freezed,Object? createdAt = null,Object? linkedMatchId = freezed,Object? linkedTournamentId = freezed,Object? linkedTeamId = freezed,Object? author = freezed,Object? team = freezed,Object? isLiked = null,Object? isBookmarked = null,Object? likesCount = null,Object? commentsCount = null,Object? sharesCount = null,}) {
  return _then(_self.copyWith(
postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as String?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,postKind: null == postKind ? _self.postKind : postKind // ignore: cast_nullable_to_non_nullable
as String,postType: freezed == postType ? _self.postType : postType // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expectedMediaCount: null == expectedMediaCount ? _self.expectedMediaCount : expectedMediaCount // ignore: cast_nullable_to_non_nullable
as int,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<dynamic>,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,viewer: freezed == viewer ? _self.viewer : viewer // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,linkedMatchId: freezed == linkedMatchId ? _self.linkedMatchId : linkedMatchId // ignore: cast_nullable_to_non_nullable
as String?,linkedTournamentId: freezed == linkedTournamentId ? _self.linkedTournamentId : linkedTournamentId // ignore: cast_nullable_to_non_nullable
as String?,linkedTeamId: freezed == linkedTeamId ? _self.linkedTeamId : linkedTeamId // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,team: freezed == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,isBookmarked: null == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,sharesCount: null == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PostDto].
extension PostDtoPatterns on PostDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostDto value)  $default,){
final _that = this;
switch (_that) {
case _PostDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'created_by_user_id')  String? createdByUserId, @JsonKey(name: 'author_id')  String? authorId,  Map<String, dynamic>? publisher, @JsonKey(name: 'post_kind')  String postKind, @JsonKey(name: 'post_type')  String? postType,  String? text,  String visibility,  String status, @JsonKey(name: 'expected_media_count')  int expectedMediaCount,  List<dynamic> media,  Map<String, dynamic>? counts,  Map<String, dynamic>? viewer, @JsonKey(name: 'published_at')  String? publishedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'linked_match_id')  String? linkedMatchId, @JsonKey(name: 'linked_tournament_id')  String? linkedTournamentId, @JsonKey(name: 'linked_team_id')  String? linkedTeamId,  Map<String, dynamic>? author,  Map<String, dynamic>? team, @JsonKey(name: 'is_liked')  bool isLiked, @JsonKey(name: 'is_bookmarked')  bool isBookmarked, @JsonKey(name: 'likes_count')  int likesCount, @JsonKey(name: 'comments_count')  int commentsCount, @JsonKey(name: 'shares_count')  int sharesCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostDto() when $default != null:
return $default(_that.postId,_that.createdByUserId,_that.authorId,_that.publisher,_that.postKind,_that.postType,_that.text,_that.visibility,_that.status,_that.expectedMediaCount,_that.media,_that.counts,_that.viewer,_that.publishedAt,_that.createdAt,_that.linkedMatchId,_that.linkedTournamentId,_that.linkedTeamId,_that.author,_that.team,_that.isLiked,_that.isBookmarked,_that.likesCount,_that.commentsCount,_that.sharesCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'created_by_user_id')  String? createdByUserId, @JsonKey(name: 'author_id')  String? authorId,  Map<String, dynamic>? publisher, @JsonKey(name: 'post_kind')  String postKind, @JsonKey(name: 'post_type')  String? postType,  String? text,  String visibility,  String status, @JsonKey(name: 'expected_media_count')  int expectedMediaCount,  List<dynamic> media,  Map<String, dynamic>? counts,  Map<String, dynamic>? viewer, @JsonKey(name: 'published_at')  String? publishedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'linked_match_id')  String? linkedMatchId, @JsonKey(name: 'linked_tournament_id')  String? linkedTournamentId, @JsonKey(name: 'linked_team_id')  String? linkedTeamId,  Map<String, dynamic>? author,  Map<String, dynamic>? team, @JsonKey(name: 'is_liked')  bool isLiked, @JsonKey(name: 'is_bookmarked')  bool isBookmarked, @JsonKey(name: 'likes_count')  int likesCount, @JsonKey(name: 'comments_count')  int commentsCount, @JsonKey(name: 'shares_count')  int sharesCount)  $default,) {final _that = this;
switch (_that) {
case _PostDto():
return $default(_that.postId,_that.createdByUserId,_that.authorId,_that.publisher,_that.postKind,_that.postType,_that.text,_that.visibility,_that.status,_that.expectedMediaCount,_that.media,_that.counts,_that.viewer,_that.publishedAt,_that.createdAt,_that.linkedMatchId,_that.linkedTournamentId,_that.linkedTeamId,_that.author,_that.team,_that.isLiked,_that.isBookmarked,_that.likesCount,_that.commentsCount,_that.sharesCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'created_by_user_id')  String? createdByUserId, @JsonKey(name: 'author_id')  String? authorId,  Map<String, dynamic>? publisher, @JsonKey(name: 'post_kind')  String postKind, @JsonKey(name: 'post_type')  String? postType,  String? text,  String visibility,  String status, @JsonKey(name: 'expected_media_count')  int expectedMediaCount,  List<dynamic> media,  Map<String, dynamic>? counts,  Map<String, dynamic>? viewer, @JsonKey(name: 'published_at')  String? publishedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'linked_match_id')  String? linkedMatchId, @JsonKey(name: 'linked_tournament_id')  String? linkedTournamentId, @JsonKey(name: 'linked_team_id')  String? linkedTeamId,  Map<String, dynamic>? author,  Map<String, dynamic>? team, @JsonKey(name: 'is_liked')  bool isLiked, @JsonKey(name: 'is_bookmarked')  bool isBookmarked, @JsonKey(name: 'likes_count')  int likesCount, @JsonKey(name: 'comments_count')  int commentsCount, @JsonKey(name: 'shares_count')  int sharesCount)?  $default,) {final _that = this;
switch (_that) {
case _PostDto() when $default != null:
return $default(_that.postId,_that.createdByUserId,_that.authorId,_that.publisher,_that.postKind,_that.postType,_that.text,_that.visibility,_that.status,_that.expectedMediaCount,_that.media,_that.counts,_that.viewer,_that.publishedAt,_that.createdAt,_that.linkedMatchId,_that.linkedTournamentId,_that.linkedTeamId,_that.author,_that.team,_that.isLiked,_that.isBookmarked,_that.likesCount,_that.commentsCount,_that.sharesCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostDto extends PostDto {
  const _PostDto({@JsonKey(name: 'post_id') required this.postId, @JsonKey(name: 'created_by_user_id') this.createdByUserId, @JsonKey(name: 'author_id') this.authorId, final  Map<String, dynamic>? publisher, @JsonKey(name: 'post_kind') this.postKind = 'standard', @JsonKey(name: 'post_type') this.postType, this.text, this.visibility = 'public', this.status = 'active', @JsonKey(name: 'expected_media_count') this.expectedMediaCount = 0, final  List<dynamic> media = const <dynamic>[], final  Map<String, dynamic>? counts, final  Map<String, dynamic>? viewer, @JsonKey(name: 'published_at') this.publishedAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'linked_match_id') this.linkedMatchId, @JsonKey(name: 'linked_tournament_id') this.linkedTournamentId, @JsonKey(name: 'linked_team_id') this.linkedTeamId, final  Map<String, dynamic>? author, final  Map<String, dynamic>? team, @JsonKey(name: 'is_liked') this.isLiked = false, @JsonKey(name: 'is_bookmarked') this.isBookmarked = false, @JsonKey(name: 'likes_count') this.likesCount = 0, @JsonKey(name: 'comments_count') this.commentsCount = 0, @JsonKey(name: 'shares_count') this.sharesCount = 0}): _publisher = publisher,_media = media,_counts = counts,_viewer = viewer,_author = author,_team = team,super._();
  factory _PostDto.fromJson(Map<String, dynamic> json) => _$PostDtoFromJson(json);

@override@JsonKey(name: 'post_id') final  String postId;
@override@JsonKey(name: 'created_by_user_id') final  String? createdByUserId;
@override@JsonKey(name: 'author_id') final  String? authorId;
 final  Map<String, dynamic>? _publisher;
@override Map<String, dynamic>? get publisher {
  final value = _publisher;
  if (value == null) return null;
  if (_publisher is EqualUnmodifiableMapView) return _publisher;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'post_kind') final  String postKind;
@override@JsonKey(name: 'post_type') final  String? postType;
@override final  String? text;
@override@JsonKey() final  String visibility;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'expected_media_count') final  int expectedMediaCount;
 final  List<dynamic> _media;
@override@JsonKey() List<dynamic> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

 final  Map<String, dynamic>? _counts;
@override Map<String, dynamic>? get counts {
  final value = _counts;
  if (value == null) return null;
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _viewer;
@override Map<String, dynamic>? get viewer {
  final value = _viewer;
  if (value == null) return null;
  if (_viewer is EqualUnmodifiableMapView) return _viewer;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'published_at') final  String? publishedAt;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'linked_match_id') final  String? linkedMatchId;
@override@JsonKey(name: 'linked_tournament_id') final  String? linkedTournamentId;
@override@JsonKey(name: 'linked_team_id') final  String? linkedTeamId;
 final  Map<String, dynamic>? _author;
@override Map<String, dynamic>? get author {
  final value = _author;
  if (value == null) return null;
  if (_author is EqualUnmodifiableMapView) return _author;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _team;
@override Map<String, dynamic>? get team {
  final value = _team;
  if (value == null) return null;
  if (_team is EqualUnmodifiableMapView) return _team;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'is_liked') final  bool isLiked;
@override@JsonKey(name: 'is_bookmarked') final  bool isBookmarked;
@override@JsonKey(name: 'likes_count') final  int likesCount;
@override@JsonKey(name: 'comments_count') final  int commentsCount;
@override@JsonKey(name: 'shares_count') final  int sharesCount;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostDtoCopyWith<_PostDto> get copyWith => __$PostDtoCopyWithImpl<_PostDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostDto&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&const DeepCollectionEquality().equals(other._publisher, _publisher)&&(identical(other.postKind, postKind) || other.postKind == postKind)&&(identical(other.postType, postType) || other.postType == postType)&&(identical(other.text, text) || other.text == text)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.status, status) || other.status == status)&&(identical(other.expectedMediaCount, expectedMediaCount) || other.expectedMediaCount == expectedMediaCount)&&const DeepCollectionEquality().equals(other._media, _media)&&const DeepCollectionEquality().equals(other._counts, _counts)&&const DeepCollectionEquality().equals(other._viewer, _viewer)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.linkedMatchId, linkedMatchId) || other.linkedMatchId == linkedMatchId)&&(identical(other.linkedTournamentId, linkedTournamentId) || other.linkedTournamentId == linkedTournamentId)&&(identical(other.linkedTeamId, linkedTeamId) || other.linkedTeamId == linkedTeamId)&&const DeepCollectionEquality().equals(other._author, _author)&&const DeepCollectionEquality().equals(other._team, _team)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,postId,createdByUserId,authorId,const DeepCollectionEquality().hash(_publisher),postKind,postType,text,visibility,status,expectedMediaCount,const DeepCollectionEquality().hash(_media),const DeepCollectionEquality().hash(_counts),const DeepCollectionEquality().hash(_viewer),publishedAt,createdAt,linkedMatchId,linkedTournamentId,linkedTeamId,const DeepCollectionEquality().hash(_author),const DeepCollectionEquality().hash(_team),isLiked,isBookmarked,likesCount,commentsCount,sharesCount]);

@override
String toString() {
  return 'PostDto(postId: $postId, createdByUserId: $createdByUserId, authorId: $authorId, publisher: $publisher, postKind: $postKind, postType: $postType, text: $text, visibility: $visibility, status: $status, expectedMediaCount: $expectedMediaCount, media: $media, counts: $counts, viewer: $viewer, publishedAt: $publishedAt, createdAt: $createdAt, linkedMatchId: $linkedMatchId, linkedTournamentId: $linkedTournamentId, linkedTeamId: $linkedTeamId, author: $author, team: $team, isLiked: $isLiked, isBookmarked: $isBookmarked, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount)';
}


}

/// @nodoc
abstract mixin class _$PostDtoCopyWith<$Res> implements $PostDtoCopyWith<$Res> {
  factory _$PostDtoCopyWith(_PostDto value, $Res Function(_PostDto) _then) = __$PostDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'created_by_user_id') String? createdByUserId,@JsonKey(name: 'author_id') String? authorId, Map<String, dynamic>? publisher,@JsonKey(name: 'post_kind') String postKind,@JsonKey(name: 'post_type') String? postType, String? text, String visibility, String status,@JsonKey(name: 'expected_media_count') int expectedMediaCount, List<dynamic> media, Map<String, dynamic>? counts, Map<String, dynamic>? viewer,@JsonKey(name: 'published_at') String? publishedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'linked_match_id') String? linkedMatchId,@JsonKey(name: 'linked_tournament_id') String? linkedTournamentId,@JsonKey(name: 'linked_team_id') String? linkedTeamId, Map<String, dynamic>? author, Map<String, dynamic>? team,@JsonKey(name: 'is_liked') bool isLiked,@JsonKey(name: 'is_bookmarked') bool isBookmarked,@JsonKey(name: 'likes_count') int likesCount,@JsonKey(name: 'comments_count') int commentsCount,@JsonKey(name: 'shares_count') int sharesCount
});




}
/// @nodoc
class __$PostDtoCopyWithImpl<$Res>
    implements _$PostDtoCopyWith<$Res> {
  __$PostDtoCopyWithImpl(this._self, this._then);

  final _PostDto _self;
  final $Res Function(_PostDto) _then;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? postId = null,Object? createdByUserId = freezed,Object? authorId = freezed,Object? publisher = freezed,Object? postKind = null,Object? postType = freezed,Object? text = freezed,Object? visibility = null,Object? status = null,Object? expectedMediaCount = null,Object? media = null,Object? counts = freezed,Object? viewer = freezed,Object? publishedAt = freezed,Object? createdAt = null,Object? linkedMatchId = freezed,Object? linkedTournamentId = freezed,Object? linkedTeamId = freezed,Object? author = freezed,Object? team = freezed,Object? isLiked = null,Object? isBookmarked = null,Object? likesCount = null,Object? commentsCount = null,Object? sharesCount = null,}) {
  return _then(_PostDto(
postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as String?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self._publisher : publisher // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,postKind: null == postKind ? _self.postKind : postKind // ignore: cast_nullable_to_non_nullable
as String,postType: freezed == postType ? _self.postType : postType // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expectedMediaCount: null == expectedMediaCount ? _self.expectedMediaCount : expectedMediaCount // ignore: cast_nullable_to_non_nullable
as int,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<dynamic>,counts: freezed == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,viewer: freezed == viewer ? _self._viewer : viewer // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,linkedMatchId: freezed == linkedMatchId ? _self.linkedMatchId : linkedMatchId // ignore: cast_nullable_to_non_nullable
as String?,linkedTournamentId: freezed == linkedTournamentId ? _self.linkedTournamentId : linkedTournamentId // ignore: cast_nullable_to_non_nullable
as String?,linkedTeamId: freezed == linkedTeamId ? _self.linkedTeamId : linkedTeamId // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self._author : author // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,team: freezed == team ? _self._team : team // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,isBookmarked: null == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,sharesCount: null == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

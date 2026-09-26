// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_media_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaVariantDto {

 String get path; int get width; int get height;@JsonKey(name: 'size_bytes') int get sizeBytes;@JsonKey(name: 'mime_type') String get mimeType;
/// Create a copy of MediaVariantDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaVariantDtoCopyWith<MediaVariantDto> get copyWith => _$MediaVariantDtoCopyWithImpl<MediaVariantDto>(this as MediaVariantDto, _$identity);

  /// Serializes this MediaVariantDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaVariantDto&&(identical(other.path, path) || other.path == path)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,width,height,sizeBytes,mimeType);

@override
String toString() {
  return 'MediaVariantDto(path: $path, width: $width, height: $height, sizeBytes: $sizeBytes, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $MediaVariantDtoCopyWith<$Res>  {
  factory $MediaVariantDtoCopyWith(MediaVariantDto value, $Res Function(MediaVariantDto) _then) = _$MediaVariantDtoCopyWithImpl;
@useResult
$Res call({
 String path, int width, int height,@JsonKey(name: 'size_bytes') int sizeBytes,@JsonKey(name: 'mime_type') String mimeType
});




}
/// @nodoc
class _$MediaVariantDtoCopyWithImpl<$Res>
    implements $MediaVariantDtoCopyWith<$Res> {
  _$MediaVariantDtoCopyWithImpl(this._self, this._then);

  final MediaVariantDto _self;
  final $Res Function(MediaVariantDto) _then;

/// Create a copy of MediaVariantDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? width = null,Object? height = null,Object? sizeBytes = null,Object? mimeType = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaVariantDto].
extension MediaVariantDtoPatterns on MediaVariantDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaVariantDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaVariantDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaVariantDto value)  $default,){
final _that = this;
switch (_that) {
case _MediaVariantDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaVariantDto value)?  $default,){
final _that = this;
switch (_that) {
case _MediaVariantDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int width,  int height, @JsonKey(name: 'size_bytes')  int sizeBytes, @JsonKey(name: 'mime_type')  String mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaVariantDto() when $default != null:
return $default(_that.path,_that.width,_that.height,_that.sizeBytes,_that.mimeType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int width,  int height, @JsonKey(name: 'size_bytes')  int sizeBytes, @JsonKey(name: 'mime_type')  String mimeType)  $default,) {final _that = this;
switch (_that) {
case _MediaVariantDto():
return $default(_that.path,_that.width,_that.height,_that.sizeBytes,_that.mimeType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int width,  int height, @JsonKey(name: 'size_bytes')  int sizeBytes, @JsonKey(name: 'mime_type')  String mimeType)?  $default,) {final _that = this;
switch (_that) {
case _MediaVariantDto() when $default != null:
return $default(_that.path,_that.width,_that.height,_that.sizeBytes,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaVariantDto extends MediaVariantDto {
  const _MediaVariantDto({required this.path, required this.width, required this.height, @JsonKey(name: 'size_bytes') this.sizeBytes = 0, @JsonKey(name: 'mime_type') this.mimeType = 'image/webp'}): super._();
  factory _MediaVariantDto.fromJson(Map<String, dynamic> json) => _$MediaVariantDtoFromJson(json);

@override final  String path;
@override final  int width;
@override final  int height;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;
@override@JsonKey(name: 'mime_type') final  String mimeType;

/// Create a copy of MediaVariantDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaVariantDtoCopyWith<_MediaVariantDto> get copyWith => __$MediaVariantDtoCopyWithImpl<_MediaVariantDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaVariantDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaVariantDto&&(identical(other.path, path) || other.path == path)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,width,height,sizeBytes,mimeType);

@override
String toString() {
  return 'MediaVariantDto(path: $path, width: $width, height: $height, sizeBytes: $sizeBytes, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$MediaVariantDtoCopyWith<$Res> implements $MediaVariantDtoCopyWith<$Res> {
  factory _$MediaVariantDtoCopyWith(_MediaVariantDto value, $Res Function(_MediaVariantDto) _then) = __$MediaVariantDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, int width, int height,@JsonKey(name: 'size_bytes') int sizeBytes,@JsonKey(name: 'mime_type') String mimeType
});




}
/// @nodoc
class __$MediaVariantDtoCopyWithImpl<$Res>
    implements _$MediaVariantDtoCopyWith<$Res> {
  __$MediaVariantDtoCopyWithImpl(this._self, this._then);

  final _MediaVariantDto _self;
  final $Res Function(_MediaVariantDto) _then;

/// Create a copy of MediaVariantDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? width = null,Object? height = null,Object? sizeBytes = null,Object? mimeType = null,}) {
  return _then(_MediaVariantDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PostMediaDto {

@JsonKey(name: 'media_id') String get mediaId;@JsonKey(name: 'post_id') String get postId; int get position; int get width; int get height; String? get blurhash; String get status; Map<String, dynamic> get variants;
/// Create a copy of PostMediaDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostMediaDtoCopyWith<PostMediaDto> get copyWith => _$PostMediaDtoCopyWithImpl<PostMediaDto>(this as PostMediaDto, _$identity);

  /// Serializes this PostMediaDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostMediaDto&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.position, position) || other.position == position)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurhash, blurhash) || other.blurhash == blurhash)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.variants, variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaId,postId,position,width,height,blurhash,status,const DeepCollectionEquality().hash(variants));

@override
String toString() {
  return 'PostMediaDto(mediaId: $mediaId, postId: $postId, position: $position, width: $width, height: $height, blurhash: $blurhash, status: $status, variants: $variants)';
}


}

/// @nodoc
abstract mixin class $PostMediaDtoCopyWith<$Res>  {
  factory $PostMediaDtoCopyWith(PostMediaDto value, $Res Function(PostMediaDto) _then) = _$PostMediaDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'media_id') String mediaId,@JsonKey(name: 'post_id') String postId, int position, int width, int height, String? blurhash, String status, Map<String, dynamic> variants
});




}
/// @nodoc
class _$PostMediaDtoCopyWithImpl<$Res>
    implements $PostMediaDtoCopyWith<$Res> {
  _$PostMediaDtoCopyWithImpl(this._self, this._then);

  final PostMediaDto _self;
  final $Res Function(PostMediaDto) _then;

/// Create a copy of PostMediaDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaId = null,Object? postId = null,Object? position = null,Object? width = null,Object? height = null,Object? blurhash = freezed,Object? status = null,Object? variants = null,}) {
  return _then(_self.copyWith(
mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,blurhash: freezed == blurhash ? _self.blurhash : blurhash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PostMediaDto].
extension PostMediaDtoPatterns on PostMediaDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostMediaDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostMediaDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostMediaDto value)  $default,){
final _that = this;
switch (_that) {
case _PostMediaDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostMediaDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostMediaDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'media_id')  String mediaId, @JsonKey(name: 'post_id')  String postId,  int position,  int width,  int height,  String? blurhash,  String status,  Map<String, dynamic> variants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostMediaDto() when $default != null:
return $default(_that.mediaId,_that.postId,_that.position,_that.width,_that.height,_that.blurhash,_that.status,_that.variants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'media_id')  String mediaId, @JsonKey(name: 'post_id')  String postId,  int position,  int width,  int height,  String? blurhash,  String status,  Map<String, dynamic> variants)  $default,) {final _that = this;
switch (_that) {
case _PostMediaDto():
return $default(_that.mediaId,_that.postId,_that.position,_that.width,_that.height,_that.blurhash,_that.status,_that.variants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'media_id')  String mediaId, @JsonKey(name: 'post_id')  String postId,  int position,  int width,  int height,  String? blurhash,  String status,  Map<String, dynamic> variants)?  $default,) {final _that = this;
switch (_that) {
case _PostMediaDto() when $default != null:
return $default(_that.mediaId,_that.postId,_that.position,_that.width,_that.height,_that.blurhash,_that.status,_that.variants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostMediaDto extends PostMediaDto {
  const _PostMediaDto({@JsonKey(name: 'media_id') required this.mediaId, @JsonKey(name: 'post_id') this.postId = '', this.position = 0, this.width = 1080, this.height = 1080, this.blurhash, this.status = 'feed_ready', final  Map<String, dynamic> variants = const <String, dynamic>{}}): _variants = variants,super._();
  factory _PostMediaDto.fromJson(Map<String, dynamic> json) => _$PostMediaDtoFromJson(json);

@override@JsonKey(name: 'media_id') final  String mediaId;
@override@JsonKey(name: 'post_id') final  String postId;
@override@JsonKey() final  int position;
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;
@override final  String? blurhash;
@override@JsonKey() final  String status;
 final  Map<String, dynamic> _variants;
@override@JsonKey() Map<String, dynamic> get variants {
  if (_variants is EqualUnmodifiableMapView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_variants);
}


/// Create a copy of PostMediaDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostMediaDtoCopyWith<_PostMediaDto> get copyWith => __$PostMediaDtoCopyWithImpl<_PostMediaDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostMediaDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostMediaDto&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.position, position) || other.position == position)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurhash, blurhash) || other.blurhash == blurhash)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._variants, _variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaId,postId,position,width,height,blurhash,status,const DeepCollectionEquality().hash(_variants));

@override
String toString() {
  return 'PostMediaDto(mediaId: $mediaId, postId: $postId, position: $position, width: $width, height: $height, blurhash: $blurhash, status: $status, variants: $variants)';
}


}

/// @nodoc
abstract mixin class _$PostMediaDtoCopyWith<$Res> implements $PostMediaDtoCopyWith<$Res> {
  factory _$PostMediaDtoCopyWith(_PostMediaDto value, $Res Function(_PostMediaDto) _then) = __$PostMediaDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'media_id') String mediaId,@JsonKey(name: 'post_id') String postId, int position, int width, int height, String? blurhash, String status, Map<String, dynamic> variants
});




}
/// @nodoc
class __$PostMediaDtoCopyWithImpl<$Res>
    implements _$PostMediaDtoCopyWith<$Res> {
  __$PostMediaDtoCopyWithImpl(this._self, this._then);

  final _PostMediaDto _self;
  final $Res Function(_PostMediaDto) _then;

/// Create a copy of PostMediaDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaId = null,Object? postId = null,Object? position = null,Object? width = null,Object? height = null,Object? blurhash = freezed,Object? status = null,Object? variants = null,}) {
  return _then(_PostMediaDto(
mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,blurhash: freezed == blurhash ? _self.blurhash : blurhash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on

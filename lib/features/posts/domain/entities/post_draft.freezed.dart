// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProcessedPhoto {

 File get file; String get blurhash; int get width; int get height;/// True while the BlurHash is still being computed in the background — the
/// composer shows a loading overlay on the thumbnail until it resolves.
 bool get hashPending;
/// Create a copy of ProcessedPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessedPhotoCopyWith<ProcessedPhoto> get copyWith => _$ProcessedPhotoCopyWithImpl<ProcessedPhoto>(this as ProcessedPhoto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessedPhoto&&(identical(other.file, file) || other.file == file)&&(identical(other.blurhash, blurhash) || other.blurhash == blurhash)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.hashPending, hashPending) || other.hashPending == hashPending));
}


@override
int get hashCode => Object.hash(runtimeType,file,blurhash,width,height,hashPending);

@override
String toString() {
  return 'ProcessedPhoto(file: $file, blurhash: $blurhash, width: $width, height: $height, hashPending: $hashPending)';
}


}

/// @nodoc
abstract mixin class $ProcessedPhotoCopyWith<$Res>  {
  factory $ProcessedPhotoCopyWith(ProcessedPhoto value, $Res Function(ProcessedPhoto) _then) = _$ProcessedPhotoCopyWithImpl;
@useResult
$Res call({
 File file, String blurhash, int width, int height, bool hashPending
});




}
/// @nodoc
class _$ProcessedPhotoCopyWithImpl<$Res>
    implements $ProcessedPhotoCopyWith<$Res> {
  _$ProcessedPhotoCopyWithImpl(this._self, this._then);

  final ProcessedPhoto _self;
  final $Res Function(ProcessedPhoto) _then;

/// Create a copy of ProcessedPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = null,Object? blurhash = null,Object? width = null,Object? height = null,Object? hashPending = null,}) {
  return _then(_self.copyWith(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as File,blurhash: null == blurhash ? _self.blurhash : blurhash // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,hashPending: null == hashPending ? _self.hashPending : hashPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessedPhoto].
extension ProcessedPhotoPatterns on ProcessedPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessedPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessedPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessedPhoto value)  $default,){
final _that = this;
switch (_that) {
case _ProcessedPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessedPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessedPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( File file,  String blurhash,  int width,  int height,  bool hashPending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessedPhoto() when $default != null:
return $default(_that.file,_that.blurhash,_that.width,_that.height,_that.hashPending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( File file,  String blurhash,  int width,  int height,  bool hashPending)  $default,) {final _that = this;
switch (_that) {
case _ProcessedPhoto():
return $default(_that.file,_that.blurhash,_that.width,_that.height,_that.hashPending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( File file,  String blurhash,  int width,  int height,  bool hashPending)?  $default,) {final _that = this;
switch (_that) {
case _ProcessedPhoto() when $default != null:
return $default(_that.file,_that.blurhash,_that.width,_that.height,_that.hashPending);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessedPhoto implements ProcessedPhoto {
  const _ProcessedPhoto({required this.file, required this.blurhash, required this.width, required this.height, this.hashPending = false});
  

@override final  File file;
@override final  String blurhash;
@override final  int width;
@override final  int height;
/// True while the BlurHash is still being computed in the background — the
/// composer shows a loading overlay on the thumbnail until it resolves.
@override@JsonKey() final  bool hashPending;

/// Create a copy of ProcessedPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessedPhotoCopyWith<_ProcessedPhoto> get copyWith => __$ProcessedPhotoCopyWithImpl<_ProcessedPhoto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessedPhoto&&(identical(other.file, file) || other.file == file)&&(identical(other.blurhash, blurhash) || other.blurhash == blurhash)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.hashPending, hashPending) || other.hashPending == hashPending));
}


@override
int get hashCode => Object.hash(runtimeType,file,blurhash,width,height,hashPending);

@override
String toString() {
  return 'ProcessedPhoto(file: $file, blurhash: $blurhash, width: $width, height: $height, hashPending: $hashPending)';
}


}

/// @nodoc
abstract mixin class _$ProcessedPhotoCopyWith<$Res> implements $ProcessedPhotoCopyWith<$Res> {
  factory _$ProcessedPhotoCopyWith(_ProcessedPhoto value, $Res Function(_ProcessedPhoto) _then) = __$ProcessedPhotoCopyWithImpl;
@override @useResult
$Res call({
 File file, String blurhash, int width, int height, bool hashPending
});




}
/// @nodoc
class __$ProcessedPhotoCopyWithImpl<$Res>
    implements _$ProcessedPhotoCopyWith<$Res> {
  __$ProcessedPhotoCopyWithImpl(this._self, this._then);

  final _ProcessedPhoto _self;
  final $Res Function(_ProcessedPhoto) _then;

/// Create a copy of ProcessedPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = null,Object? blurhash = null,Object? width = null,Object? height = null,Object? hashPending = null,}) {
  return _then(_ProcessedPhoto(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as File,blurhash: null == blurhash ? _self.blurhash : blurhash // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,hashPending: null == hashPending ? _self.hashPending : hashPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PostDraft {

 String? get text; List<ProcessedPhoto> get photos; PostAuthorContext get authorContext; String? get contextEntityId;
/// Create a copy of PostDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDraftCopyWith<PostDraft> get copyWith => _$PostDraftCopyWithImpl<PostDraft>(this as PostDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDraft&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.authorContext, authorContext) || other.authorContext == authorContext)&&(identical(other.contextEntityId, contextEntityId) || other.contextEntityId == contextEntityId));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(photos),authorContext,contextEntityId);

@override
String toString() {
  return 'PostDraft(text: $text, photos: $photos, authorContext: $authorContext, contextEntityId: $contextEntityId)';
}


}

/// @nodoc
abstract mixin class $PostDraftCopyWith<$Res>  {
  factory $PostDraftCopyWith(PostDraft value, $Res Function(PostDraft) _then) = _$PostDraftCopyWithImpl;
@useResult
$Res call({
 String? text, List<ProcessedPhoto> photos, PostAuthorContext authorContext, String? contextEntityId
});




}
/// @nodoc
class _$PostDraftCopyWithImpl<$Res>
    implements $PostDraftCopyWith<$Res> {
  _$PostDraftCopyWithImpl(this._self, this._then);

  final PostDraft _self;
  final $Res Function(PostDraft) _then;

/// Create a copy of PostDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = freezed,Object? photos = null,Object? authorContext = null,Object? contextEntityId = freezed,}) {
  return _then(_self.copyWith(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<ProcessedPhoto>,authorContext: null == authorContext ? _self.authorContext : authorContext // ignore: cast_nullable_to_non_nullable
as PostAuthorContext,contextEntityId: freezed == contextEntityId ? _self.contextEntityId : contextEntityId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PostDraft].
extension PostDraftPatterns on PostDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostDraft value)  $default,){
final _that = this;
switch (_that) {
case _PostDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostDraft value)?  $default,){
final _that = this;
switch (_that) {
case _PostDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? text,  List<ProcessedPhoto> photos,  PostAuthorContext authorContext,  String? contextEntityId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostDraft() when $default != null:
return $default(_that.text,_that.photos,_that.authorContext,_that.contextEntityId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? text,  List<ProcessedPhoto> photos,  PostAuthorContext authorContext,  String? contextEntityId)  $default,) {final _that = this;
switch (_that) {
case _PostDraft():
return $default(_that.text,_that.photos,_that.authorContext,_that.contextEntityId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? text,  List<ProcessedPhoto> photos,  PostAuthorContext authorContext,  String? contextEntityId)?  $default,) {final _that = this;
switch (_that) {
case _PostDraft() when $default != null:
return $default(_that.text,_that.photos,_that.authorContext,_that.contextEntityId);case _:
  return null;

}
}

}

/// @nodoc


class _PostDraft extends PostDraft {
  const _PostDraft({this.text, final  List<ProcessedPhoto> photos = const [], this.authorContext = PostAuthorContext.personal, this.contextEntityId}): _photos = photos,super._();
  

@override final  String? text;
 final  List<ProcessedPhoto> _photos;
@override@JsonKey() List<ProcessedPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  PostAuthorContext authorContext;
@override final  String? contextEntityId;

/// Create a copy of PostDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostDraftCopyWith<_PostDraft> get copyWith => __$PostDraftCopyWithImpl<_PostDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostDraft&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.authorContext, authorContext) || other.authorContext == authorContext)&&(identical(other.contextEntityId, contextEntityId) || other.contextEntityId == contextEntityId));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_photos),authorContext,contextEntityId);

@override
String toString() {
  return 'PostDraft(text: $text, photos: $photos, authorContext: $authorContext, contextEntityId: $contextEntityId)';
}


}

/// @nodoc
abstract mixin class _$PostDraftCopyWith<$Res> implements $PostDraftCopyWith<$Res> {
  factory _$PostDraftCopyWith(_PostDraft value, $Res Function(_PostDraft) _then) = __$PostDraftCopyWithImpl;
@override @useResult
$Res call({
 String? text, List<ProcessedPhoto> photos, PostAuthorContext authorContext, String? contextEntityId
});




}
/// @nodoc
class __$PostDraftCopyWithImpl<$Res>
    implements _$PostDraftCopyWith<$Res> {
  __$PostDraftCopyWithImpl(this._self, this._then);

  final _PostDraft _self;
  final $Res Function(_PostDraft) _then;

/// Create a copy of PostDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = freezed,Object? photos = null,Object? authorContext = null,Object? contextEntityId = freezed,}) {
  return _then(_PostDraft(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<ProcessedPhoto>,authorContext: null == authorContext ? _self.authorContext : authorContext // ignore: cast_nullable_to_non_nullable
as PostAuthorContext,contextEntityId: freezed == contextEntityId ? _self.contextEntityId : contextEntityId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

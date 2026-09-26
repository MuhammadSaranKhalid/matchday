// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'composer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComposerState {

 List<ProcessedPhoto> get photos; bool get busy; Failure? get error; PostPublisherSelection get publisher; PostKind get postKind; String? get linkedMatchId; String? get linkedTournamentId; String? get linkedTeamId;
/// Create a copy of ComposerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComposerStateCopyWith<ComposerState> get copyWith => _$ComposerStateCopyWithImpl<ComposerState>(this as ComposerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComposerState&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.error, error) || other.error == error)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.postKind, postKind) || other.postKind == postKind)&&(identical(other.linkedMatchId, linkedMatchId) || other.linkedMatchId == linkedMatchId)&&(identical(other.linkedTournamentId, linkedTournamentId) || other.linkedTournamentId == linkedTournamentId)&&(identical(other.linkedTeamId, linkedTeamId) || other.linkedTeamId == linkedTeamId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(photos),busy,error,publisher,postKind,linkedMatchId,linkedTournamentId,linkedTeamId);

@override
String toString() {
  return 'ComposerState(photos: $photos, busy: $busy, error: $error, publisher: $publisher, postKind: $postKind, linkedMatchId: $linkedMatchId, linkedTournamentId: $linkedTournamentId, linkedTeamId: $linkedTeamId)';
}


}

/// @nodoc
abstract mixin class $ComposerStateCopyWith<$Res>  {
  factory $ComposerStateCopyWith(ComposerState value, $Res Function(ComposerState) _then) = _$ComposerStateCopyWithImpl;
@useResult
$Res call({
 List<ProcessedPhoto> photos, bool busy, Failure? error, PostPublisherSelection publisher, PostKind postKind, String? linkedMatchId, String? linkedTournamentId, String? linkedTeamId
});




}
/// @nodoc
class _$ComposerStateCopyWithImpl<$Res>
    implements $ComposerStateCopyWith<$Res> {
  _$ComposerStateCopyWithImpl(this._self, this._then);

  final ComposerState _self;
  final $Res Function(ComposerState) _then;

/// Create a copy of ComposerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photos = null,Object? busy = null,Object? error = freezed,Object? publisher = null,Object? postKind = null,Object? linkedMatchId = freezed,Object? linkedTournamentId = freezed,Object? linkedTeamId = freezed,}) {
  return _then(_self.copyWith(
photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<ProcessedPhoto>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,publisher: null == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as PostPublisherSelection,postKind: null == postKind ? _self.postKind : postKind // ignore: cast_nullable_to_non_nullable
as PostKind,linkedMatchId: freezed == linkedMatchId ? _self.linkedMatchId : linkedMatchId // ignore: cast_nullable_to_non_nullable
as String?,linkedTournamentId: freezed == linkedTournamentId ? _self.linkedTournamentId : linkedTournamentId // ignore: cast_nullable_to_non_nullable
as String?,linkedTeamId: freezed == linkedTeamId ? _self.linkedTeamId : linkedTeamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ComposerState].
extension ComposerStatePatterns on ComposerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComposerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComposerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComposerState value)  $default,){
final _that = this;
switch (_that) {
case _ComposerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComposerState value)?  $default,){
final _that = this;
switch (_that) {
case _ComposerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProcessedPhoto> photos,  bool busy,  Failure? error,  PostPublisherSelection publisher,  PostKind postKind,  String? linkedMatchId,  String? linkedTournamentId,  String? linkedTeamId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComposerState() when $default != null:
return $default(_that.photos,_that.busy,_that.error,_that.publisher,_that.postKind,_that.linkedMatchId,_that.linkedTournamentId,_that.linkedTeamId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProcessedPhoto> photos,  bool busy,  Failure? error,  PostPublisherSelection publisher,  PostKind postKind,  String? linkedMatchId,  String? linkedTournamentId,  String? linkedTeamId)  $default,) {final _that = this;
switch (_that) {
case _ComposerState():
return $default(_that.photos,_that.busy,_that.error,_that.publisher,_that.postKind,_that.linkedMatchId,_that.linkedTournamentId,_that.linkedTeamId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProcessedPhoto> photos,  bool busy,  Failure? error,  PostPublisherSelection publisher,  PostKind postKind,  String? linkedMatchId,  String? linkedTournamentId,  String? linkedTeamId)?  $default,) {final _that = this;
switch (_that) {
case _ComposerState() when $default != null:
return $default(_that.photos,_that.busy,_that.error,_that.publisher,_that.postKind,_that.linkedMatchId,_that.linkedTournamentId,_that.linkedTeamId);case _:
  return null;

}
}

}

/// @nodoc


class _ComposerState extends ComposerState {
  const _ComposerState({final  List<ProcessedPhoto> photos = const [], this.busy = false, this.error, this.publisher = PostPublisherSelection.user, this.postKind = PostKind.standard, this.linkedMatchId, this.linkedTournamentId, this.linkedTeamId}): _photos = photos,super._();
  

 final  List<ProcessedPhoto> _photos;
@override@JsonKey() List<ProcessedPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  bool busy;
@override final  Failure? error;
@override@JsonKey() final  PostPublisherSelection publisher;
@override@JsonKey() final  PostKind postKind;
@override final  String? linkedMatchId;
@override final  String? linkedTournamentId;
@override final  String? linkedTeamId;

/// Create a copy of ComposerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComposerStateCopyWith<_ComposerState> get copyWith => __$ComposerStateCopyWithImpl<_ComposerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComposerState&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.error, error) || other.error == error)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.postKind, postKind) || other.postKind == postKind)&&(identical(other.linkedMatchId, linkedMatchId) || other.linkedMatchId == linkedMatchId)&&(identical(other.linkedTournamentId, linkedTournamentId) || other.linkedTournamentId == linkedTournamentId)&&(identical(other.linkedTeamId, linkedTeamId) || other.linkedTeamId == linkedTeamId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_photos),busy,error,publisher,postKind,linkedMatchId,linkedTournamentId,linkedTeamId);

@override
String toString() {
  return 'ComposerState(photos: $photos, busy: $busy, error: $error, publisher: $publisher, postKind: $postKind, linkedMatchId: $linkedMatchId, linkedTournamentId: $linkedTournamentId, linkedTeamId: $linkedTeamId)';
}


}

/// @nodoc
abstract mixin class _$ComposerStateCopyWith<$Res> implements $ComposerStateCopyWith<$Res> {
  factory _$ComposerStateCopyWith(_ComposerState value, $Res Function(_ComposerState) _then) = __$ComposerStateCopyWithImpl;
@override @useResult
$Res call({
 List<ProcessedPhoto> photos, bool busy, Failure? error, PostPublisherSelection publisher, PostKind postKind, String? linkedMatchId, String? linkedTournamentId, String? linkedTeamId
});




}
/// @nodoc
class __$ComposerStateCopyWithImpl<$Res>
    implements _$ComposerStateCopyWith<$Res> {
  __$ComposerStateCopyWithImpl(this._self, this._then);

  final _ComposerState _self;
  final $Res Function(_ComposerState) _then;

/// Create a copy of ComposerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photos = null,Object? busy = null,Object? error = freezed,Object? publisher = null,Object? postKind = null,Object? linkedMatchId = freezed,Object? linkedTournamentId = freezed,Object? linkedTeamId = freezed,}) {
  return _then(_ComposerState(
photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<ProcessedPhoto>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,publisher: null == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as PostPublisherSelection,postKind: null == postKind ? _self.postKind : postKind // ignore: cast_nullable_to_non_nullable
as PostKind,linkedMatchId: freezed == linkedMatchId ? _self.linkedMatchId : linkedMatchId // ignore: cast_nullable_to_non_nullable
as String?,linkedTournamentId: freezed == linkedTournamentId ? _self.linkedTournamentId : linkedTournamentId // ignore: cast_nullable_to_non_nullable
as String?,linkedTeamId: freezed == linkedTeamId ? _self.linkedTeamId : linkedTeamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

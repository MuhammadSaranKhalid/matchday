// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'format_preset_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FormatPresetDto {

 String get id; String get label; Map<String, dynamic> get config;@JsonKey(name: 'default_scoring_mode') String? get defaultScoringMode;
/// Create a copy of FormatPresetDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormatPresetDtoCopyWith<FormatPresetDto> get copyWith => _$FormatPresetDtoCopyWithImpl<FormatPresetDto>(this as FormatPresetDto, _$identity);

  /// Serializes this FormatPresetDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FormatPresetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.config, config)&&(identical(other.defaultScoringMode, defaultScoringMode) || other.defaultScoringMode == defaultScoringMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,const DeepCollectionEquality().hash(config),defaultScoringMode);

@override
String toString() {
  return 'FormatPresetDto(id: $id, label: $label, config: $config, defaultScoringMode: $defaultScoringMode)';
}


}

/// @nodoc
abstract mixin class $FormatPresetDtoCopyWith<$Res>  {
  factory $FormatPresetDtoCopyWith(FormatPresetDto value, $Res Function(FormatPresetDto) _then) = _$FormatPresetDtoCopyWithImpl;
@useResult
$Res call({
 String id, String label, Map<String, dynamic> config,@JsonKey(name: 'default_scoring_mode') String? defaultScoringMode
});




}
/// @nodoc
class _$FormatPresetDtoCopyWithImpl<$Res>
    implements $FormatPresetDtoCopyWith<$Res> {
  _$FormatPresetDtoCopyWithImpl(this._self, this._then);

  final FormatPresetDto _self;
  final $Res Function(FormatPresetDto) _then;

/// Create a copy of FormatPresetDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? config = null,Object? defaultScoringMode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,defaultScoringMode: freezed == defaultScoringMode ? _self.defaultScoringMode : defaultScoringMode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FormatPresetDto].
extension FormatPresetDtoPatterns on FormatPresetDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FormatPresetDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FormatPresetDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FormatPresetDto value)  $default,){
final _that = this;
switch (_that) {
case _FormatPresetDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FormatPresetDto value)?  $default,){
final _that = this;
switch (_that) {
case _FormatPresetDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  Map<String, dynamic> config, @JsonKey(name: 'default_scoring_mode')  String? defaultScoringMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FormatPresetDto() when $default != null:
return $default(_that.id,_that.label,_that.config,_that.defaultScoringMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  Map<String, dynamic> config, @JsonKey(name: 'default_scoring_mode')  String? defaultScoringMode)  $default,) {final _that = this;
switch (_that) {
case _FormatPresetDto():
return $default(_that.id,_that.label,_that.config,_that.defaultScoringMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  Map<String, dynamic> config, @JsonKey(name: 'default_scoring_mode')  String? defaultScoringMode)?  $default,) {final _that = this;
switch (_that) {
case _FormatPresetDto() when $default != null:
return $default(_that.id,_that.label,_that.config,_that.defaultScoringMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FormatPresetDto extends FormatPresetDto {
  const _FormatPresetDto({required this.id, required this.label, required final  Map<String, dynamic> config, @JsonKey(name: 'default_scoring_mode') this.defaultScoringMode}): _config = config,super._();
  factory _FormatPresetDto.fromJson(Map<String, dynamic> json) => _$FormatPresetDtoFromJson(json);

@override final  String id;
@override final  String label;
 final  Map<String, dynamic> _config;
@override Map<String, dynamic> get config {
  if (_config is EqualUnmodifiableMapView) return _config;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_config);
}

@override@JsonKey(name: 'default_scoring_mode') final  String? defaultScoringMode;

/// Create a copy of FormatPresetDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormatPresetDtoCopyWith<_FormatPresetDto> get copyWith => __$FormatPresetDtoCopyWithImpl<_FormatPresetDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FormatPresetDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormatPresetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._config, _config)&&(identical(other.defaultScoringMode, defaultScoringMode) || other.defaultScoringMode == defaultScoringMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,const DeepCollectionEquality().hash(_config),defaultScoringMode);

@override
String toString() {
  return 'FormatPresetDto(id: $id, label: $label, config: $config, defaultScoringMode: $defaultScoringMode)';
}


}

/// @nodoc
abstract mixin class _$FormatPresetDtoCopyWith<$Res> implements $FormatPresetDtoCopyWith<$Res> {
  factory _$FormatPresetDtoCopyWith(_FormatPresetDto value, $Res Function(_FormatPresetDto) _then) = __$FormatPresetDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, Map<String, dynamic> config,@JsonKey(name: 'default_scoring_mode') String? defaultScoringMode
});




}
/// @nodoc
class __$FormatPresetDtoCopyWithImpl<$Res>
    implements _$FormatPresetDtoCopyWith<$Res> {
  __$FormatPresetDtoCopyWithImpl(this._self, this._then);

  final _FormatPresetDto _self;
  final $Res Function(_FormatPresetDto) _then;

/// Create a copy of FormatPresetDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? config = null,Object? defaultScoringMode = freezed,}) {
  return _then(_FormatPresetDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,defaultScoringMode: freezed == defaultScoringMode ? _self.defaultScoringMode : defaultScoringMode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

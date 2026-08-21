import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/geo_place.dart';
import '../../domain/entities/place_suggestion.dart';

part 'place_picker_state.freezed.dart';

/// State for a single place-autocomplete field.
@freezed
abstract class PlacePickerState with _$PlacePickerState {
  const factory PlacePickerState({
    /// What the user has typed. Not necessarily a resolved place.
    @Default('') String query,

    /// Live predictions for [query].
    @Default(<PlaceSuggestion>[]) List<PlaceSuggestion> suggestions,

    /// The resolved place, once a suggestion is picked or GPS returns.
    /// Null while the user is still typing free text.
    GeoPlace? picked,

    /// An autocomplete request is in flight.
    @Default(false) bool searching,

    /// A place-details or GPS resolution is in flight — distinct from
    /// [searching] because it blocks the field while the coordinate lands.
    @Default(false) bool resolving,

    Failure? error,
  }) = _PlacePickerState;

  const PlacePickerState._();

  /// True once we hold coordinates — the whole point of the field.
  bool get hasCoordinates => picked?.hasCoordinates ?? false;

  bool get showSuggestions => suggestions.isNotEmpty && picked == null;
}

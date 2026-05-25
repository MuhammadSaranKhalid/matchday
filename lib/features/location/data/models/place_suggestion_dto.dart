import '../../domain/entities/place_suggestion.dart';

/// Wire model for one element of the `suggestions` array returned by
/// Places API (New) Autocomplete. Parsed by hand rather than via
/// json_serializable because the payload is deeply nested and irregular
/// (`placePrediction.structuredFormat.mainText.text`), not a flat row.
class PlaceSuggestionDto {
  const PlaceSuggestionDto({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
  });

  final String placeId;
  final String primaryText;
  final String? secondaryText;

  /// Returns null for rows we can't use (query predictions carry no placeId).
  static PlaceSuggestionDto? fromJson(Map<String, dynamic> json) {
    final prediction = json['placePrediction'] as Map<String, dynamic>?;
    if (prediction == null) return null;

    final placeId = prediction['placeId'] as String?;
    final structured = prediction['structuredFormat'] as Map<String, dynamic>?;
    final main = _text(structured?['mainText']);
    final secondary = _text(structured?['secondaryText']);
    final flat = _text(prediction['text']);
    final primary = main ?? flat;

    if (placeId == null || primary == null) return null;
    return PlaceSuggestionDto(
      placeId: placeId,
      primaryText: primary,
      secondaryText: secondary,
    );
  }

  static String? _text(Object? node) =>
      (node as Map<String, dynamic>?)?['text'] as String?;

  PlaceSuggestion toEntity() => PlaceSuggestion(
        placeId: placeId,
        primaryText: primaryText,
        secondaryText: secondaryText,
      );
}

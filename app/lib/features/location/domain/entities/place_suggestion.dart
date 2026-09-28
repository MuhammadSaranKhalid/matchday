/// A single prediction row from a place-autocomplete query. Carries only what
/// the dropdown needs to render plus the [placeId] required to resolve full
/// coordinates in a follow-up details call.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
  });

  final String placeId;

  /// The main line, e.g. "Mardan".
  final String primaryText;

  /// The disambiguating line, e.g. "Khyber Pakhtunkhwa, Pakistan".
  final String? secondaryText;

  /// Single-line label, e.g. "Mardan, Khyber Pakhtunkhwa, Pakistan".
  String get fullText =>
      secondaryText == null || secondaryText!.isEmpty
          ? primaryText
          : '$primaryText, $secondaryText';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceSuggestion &&
          other.placeId == placeId &&
          other.primaryText == primaryText &&
          other.secondaryText == secondaryText;

  @override
  int get hashCode => Object.hash(placeId, primaryText, secondaryText);
}

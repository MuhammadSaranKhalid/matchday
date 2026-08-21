import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/geo_place.dart';
import '../controllers/place_picker_controller.dart';

/// A city/place input that resolves to real coordinates.
///
/// Replaces free-text city fields. The point is not autocomplete convenience
/// — it is that `location.lat` / `location.lng` get populated, which is what
/// makes proximity discovery possible at all. A free-text city cannot be
/// ranked by distance and fragments the facet list ("Gulberg, Lahore" vs
/// "Lahore" vs "lahore").
///
/// Three ways to land a coordinate, in descending precision:
///   1. Pick a prediction → Places details → exact coordinates.
///   2. "Use my location" → device GPS → reverse-geocoded. The path that
///      works for villages no gazetteer lists.
///   3. Keep as typed → no coordinates. Allowed, but the field says plainly
///      what is lost.
class PlaceAutocompleteField extends ConsumerStatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.field,
    required this.onResolved,
    this.initialText = '',
    this.label = 'City or village',
    this.hintText = 'Start typing a place',
  });

  /// Distinguishes this picker's provider instance from others on screen.
  final String field;

  /// Fires whenever the resolved place changes — including with a
  /// coordinate-less [GeoPlace.manual] when the user keeps their typed text,
  /// so the caller always knows the current value.
  final ValueChanged<GeoPlace?> onResolved;

  final String initialText;
  final String label;
  final String hintText;

  @override
  ConsumerState<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState
    extends ConsumerState<PlaceAutocompleteField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = placePickerProvider(widget.field);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    // Report resolution changes upward without rebuilding on every keystroke.
    ref.listen(provider.select((s) => s.picked), (_, next) {
      widget.onResolved(next);
      // Mirror the canonical label back into the field once resolved.
      if (next != null && _ctrl.text != state.query) {
        _ctrl.value = TextEditingValue(
          text: state.query,
          selection: TextSelection.collapsed(offset: state.query.length),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(
              color: state.hasCoordinates ? CkColors.green : CkColors.line,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: notifier.setQuery,
                  autocorrect: false,
                  style: CkType.body(fontSize: 15),
                  cursorColor: CkColors.red,
                  decoration: InputDecoration(
                    isDense: true,
                    // See the note in explore_search_field.dart: the app
                    // theme's `filled` + enabled/focused OutlineInputBorder
                    // survive `border: none`, painting a nested white box.
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: widget.hintText,
                    hintStyle:
                        CkType.body(fontSize: 14, color: CkColors.soft),
                  ),
                ),
              ),
              if (state.searching || state.resolving)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: CkColors.muted,
                  ),
                )
              else if (state.hasCoordinates)
                const Icon(Icons.check_circle, size: 17, color: CkColors.green)
              else
                _GpsButton(onTap: notifier.useCurrentLocation),
            ],
          ),
        ),

        // ── Predictions ──
        if (state.showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: CkColors.surface,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              children: [
                for (final s in state.suggestions.take(5))
                  InkWell(
                    onTap: () => notifier.select(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: CkColors.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.primaryText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CkType.body(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (s.secondaryText?.isNotEmpty == true)
                                  Text(
                                    s.secondaryText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CkType.body(
                                      fontSize: 11,
                                      color: CkColors.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // ── Escape hatch: typed text with no coordinate ──
        if (state.query.trim().isNotEmpty &&
            !state.hasCoordinates &&
            !state.searching &&
            !state.resolving) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: notifier.keepAsTyped,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Can’t find it? Use “${_short(state.query)}” as typed — '
              'your team won’t show up in nearby searches.',
              style: CkType.body(
                fontSize: 11,
                color: CkColors.muted,
                height: 1.4,
              ),
            ),
          ),
        ],

        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(
            state.error!.message,
            style: CkType.body(fontSize: 11, color: CkInkRed.value),
          ),
        ],
      ],
    );
  }

  static String _short(String s) =>
      s.length <= 24 ? s.trim() : '${s.trim().substring(0, 24)}…';
}

/// Local alias so this widget does not import the v2 kit for one colour.
abstract final class CkInkRed {
  static const value = Color(0xFF8C2218);
}

class _GpsButton extends StatelessWidget {
  const _GpsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location, size: 15, color: CkColors.ink),
              const SizedBox(width: 5),
              Text(
                'GPS',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                  color: CkColors.ink,
                ),
              ),
            ],
          ),
        ),
      );
}

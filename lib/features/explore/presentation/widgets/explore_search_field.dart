import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// The sticky search input at the top of the Explore tab.
///
/// Always visible — never behind an icon. Three visual states from the
/// design: idle (paper-2 fill, hairline border), focused (white fill, 1.5px
/// ink border, red caret, inline CANCEL), and filled (white fill, hairline
/// border, circular clear button).
class ExploreSearchField extends StatelessWidget {
  const ExploreSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onCancel,
    required this.onSubmitted,
    required this.focused,
    this.statusLine,
    this.statusMuted = false,
    this.loading = false,
    this.readOnly = false,
    this.below,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmitted;
  final bool focused;

  /// Mono line under the field, e.g. `6 RESULTS FOR “LAH” · ALL`.
  final String? statusLine;

  /// Renders [statusLine] in `soft` rather than `muted` — the design uses the
  /// lighter tone for the transient "Refreshing results…" message.
  final bool statusMuted;

  /// Draws the sliding indeterminate bar along the field's bottom edge.
  final bool loading;

  /// See-all shows the query but is not editable — tapping returns to search.
  final bool readOnly;

  /// Extra content between the field and the container's bottom edge, e.g.
  /// the See-all scope row.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    // Focused-empty gets the ink border; a filled field keeps the hairline so
    // the results underneath stay the focus.
    final inkBorder = focused && !hasText;

    return Container(
      color: CkColors.paper,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: (focused || hasText) ? CkColors.surface : CkColors.paper2,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(
                color: inkBorder ? CkColors.ink : CkColors.line,
                width: inkBorder ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                V2Svg(
                  V2Icons.search,
                  size: 16,
                  color: (focused || hasText) ? CkColors.ink : CkColors.muted,
                  strokeWidth: 1.6,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    readOnly: readOnly,
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    style: CkType.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: CkColors.red,
                    cursorWidth: 1.5,
                    decoration: InputDecoration(
                      isDense: true,
                      // The app theme sets `filled: true` + OutlineInputBorder
                      // on `enabledBorder`/`focusedBorder`. `border: none`
                      // alone does NOT override those slots, so the field
                      // would paint its own white rounded box inside this
                      // container. Neutralise every slot — same treatment as
                      // messages/inbox_search_bar.dart.
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      // Design is `padding: 11px 13px`. 12 lands the row at
                      // ~44px total — the design's density while still
                      // clearing the minimum touch target.
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: 'Search players, teams, matches',
                      hintStyle:
                          CkType.body(fontSize: 14, color: CkColors.soft),
                    ),
                  ),
                ),
                // Focused + empty → CANCEL inside the field (artboard 04).
                if (focused && !hasText)
                  GestureDetector(
                    onTap: onCancel,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'CANCEL',
                        style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                          color: CkColors.soft,
                        ),
                      ),
                    ),
                  )
                // Filled → circular grey clear button (artboards 05 · 07).
                else if (hasText && !readOnly)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: _ClearGlyph(),
                    ),
                  ),
              ],
            ),
          ),
          if (statusLine != null)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                statusLine!,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: statusMuted ? CkColors.soft : CkColors.muted,
                ),
              ),
            ),
          if (below != null) below!,
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: ExploreSlidingBar(),
            ),
        ],
      ),
    );
  }
}

/// The circular grey ✕ that clears a filled field.
class _ClearGlyph extends StatelessWidget {
  const _ClearGlyph();

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: CkColors.paper2,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 10.5, color: CkColors.muted),
      );
}

/// A 40%-wide red segment sliding left→right along a 2px track.
///
/// The design's `mdbar` animation, not Material's indeterminate bar — that
/// one pulses from both edges and reads as a different, busier object.
class ExploreSlidingBar extends StatefulWidget {
  const ExploreSlidingBar({super.key});

  @override
  State<ExploreSlidingBar> createState() => _ExploreSlidingBarState();
}

class _ExploreSlidingBarState extends State<ExploreSlidingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 2,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  // -40% → 100%, matching the design's keyframes.
                  final t = Curves.easeInOut.transform(_c.value);
                  final left = -0.4 * w + t * (w * 1.4);
                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 0,
                        width: w * 0.4,
                        height: 2,
                        child: const ColoredBox(color: CkColors.red),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
}

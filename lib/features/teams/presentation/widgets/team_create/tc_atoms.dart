import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/team_create_state.dart';
import '../../utils/team_display.dart';
import '../team_crest.dart';

/// 12-swatch curated palette — port of `palette` in design/screens/TeamCreate.jsx.
/// Mix of dark saturated + accent + neutrals chosen to look right next to
/// cream paper.
const List<String> kTeamCreatePalette = [
  '#1E5A2C', // dark green
  '#8C2218', // deep red
  '#1F2D4F', // dark blue
  '#3F3527', // brown
  '#7B4413', // burnt orange
  '#5E2A6B', // purple
  '#1F6E6F', // teal
  '#A22B1E', // brick red
  '#161107', // ink
  '#E24A3F', // bright red
  '#E6AC3D', // amber
  '#F8EAC6', // cream
];

/// Mono-style section label — uppercase JetBrains Mono with letter-spacing.
class TcLabel extends StatelessWidget {
  const TcLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.10,
          color: CkColors.ink2,
        ),
      ),
    );
  }
}

/// Themed text input — paper background, hairline border, rounded.
/// Owns its own [TextEditingController] so the caret doesn't reset every
/// rebuild; only syncs from the external [value] when it diverges from
/// what the user is currently typing.
class TcInput extends StatefulWidget {
  const TcInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.maxLength,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.maxWidth,
    this.hasError = false,
    this.autofocus = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final double? maxWidth;
  final bool hasError;
  final bool autofocus;

  @override
  State<TcInput> createState() => _TcInputState();
}

class _TcInputState extends State<TcInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(TcInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only push the external value back into the field when it changes from
    // outside our own onChanged (e.g. draft restore, or a sibling step
    // editing the same shared property). Without this guard, every onChanged
    // round-trip would reset the caret to the end and break fast typing.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textAlign: widget.textAlign,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      style: widget.textStyle ?? CkType.body(fontSize: 14, color: CkColors.ink),
      decoration: InputDecoration(
        counterText: '',
        isCollapsed: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: CkColors.paper,
        hintText: widget.placeholder,
        hintStyle: CkType.body(fontSize: 14, color: CkColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.hasError ? CkColors.red : CkColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.hasError ? CkColors.red : CkColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.hasError ? CkColors.red : CkColors.ink,
              width: 1.5),
        ),
      ),
    );
    if (widget.maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: field,
      );
    }
    return field;
  }
}

/// Tappable selection tile with title + subtitle. Used by Team-type and
/// crest-kind grids.
class TcSelectTile extends StatelessWidget {
  const TcSelectTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.dim = false,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Fades the tile to ~50% opacity (used when an upload makes the
  /// generated styles a fallback).
  final bool dim;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? CkColors.paper : CkColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: 8),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.01,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 12, color: CkColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 6×2 swatch grid — port of `ColorGrid` in the JSX. Selected swatch carries
/// a tick (white on dark, ink on cream).
class TcColorGrid extends StatelessWidget {
  const TcColorGrid({
    super.key,
    required this.palette,
    required this.value,
    required this.onChanged,
  });

  final List<String> palette;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: palette.map((hex) {
        final selected = hex.toUpperCase() == value.toUpperCase();
        final color = parseHexColor(hex, fallback: CkColors.ink);
        final tickColor = _onColor(color);
        return InkWell(
          onTap: () => onChanged(hex),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? CkColors.ink : CkColors.hairline,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? Center(
                    child: Icon(Icons.check_rounded,
                        color: tickColor, size: 16, weight: 800),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Pick the right foreground color for a given background — black for light
/// backgrounds, paper for dark.
Color _onColor(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.179 ? CkColors.ink : CkColors.paper;
}

Color onColor(Color bg) => _onColor(bg);

/// Renders the team crest at the requested size, picking the right shape
/// (monogram glyph, initial, shield, or uploaded image).
class TcCrestPreview extends StatelessWidget {
  const TcCrestPreview({
    super.key,
    required this.crestKind,
    required this.primaryHex,
    required this.monogram,
    this.logoPath,
    this.size = 132,
    this.radius = 28,
  });

  final CrestKind crestKind;
  final String primaryHex;
  final String monogram;
  final String? logoPath;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => TeamCrest(
    name: monogram, monogram: monogram, primaryColor: primaryHex,
    crestKind: crestKind, size: size,
    localLogoPath: crestKind == CrestKind.upload ? logoPath : null,
  );
}

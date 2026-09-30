import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/radii.dart';

/// Style variants for [SearchField].
enum SearchFieldVariant {
  /// Standard rectangular outlined search field.
  standard,

  /// Capsule-shaped search field (e.g. Inbox / Messages).
  pill,

  /// Prominent search bar with filled surface (e.g. Explore).
  prominent,
}

/// Standardized search input primitive.
///
/// Encapsulates search icon, clear button behavior, focus states, and loading
/// spinner while allowing contextual variants (standard, pill, prominent).
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.variant = SearchFieldVariant.standard,
    this.loading = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hintText;
  final SearchFieldVariant variant;
  final bool loading;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  bool _ownsController = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = switch (widget.variant) {
      SearchFieldVariant.pill => BorderRadius.circular(Radii.pill),
      SearchFieldVariant.prominent => BorderRadius.circular(Radii.card),
      SearchFieldVariant.standard => BorderRadius.circular(Radii.control),
    };

    final (fillColor, borderColor) = switch (widget.variant) {
      SearchFieldVariant.pill => (Palette.paper2, Palette.hairline),
      SearchFieldVariant.prominent => (Palette.surface, Palette.line),
      SearchFieldVariant.standard => (Palette.surface, Palette.line),
    };

    return SizedBox(
      height: 44,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: Palette.ink,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: Palette.soft,
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search,
              size: 20,
              color: Palette.muted,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: widget.loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.muted,
                    ),
                  ),
                )
              : _hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Palette.muted,
                      ),
                      onPressed: _handleClear,
                      splashRadius: 16,
                    )
                  : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: Palette.ink, width: 1.5),
          ),
        ),
      ),
    );
  }
}

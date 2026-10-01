import 'package:flutter/material.dart';

import '../foundation/radii.dart';
import '../theme/app_theme.dart';

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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final borderRadius = switch (widget.variant) {
      SearchFieldVariant.pill => BorderRadius.circular(Radii.pill),
      SearchFieldVariant.prominent => BorderRadius.circular(layout.cardRadius),
      SearchFieldVariant.standard => BorderRadius.circular(layout.controlRadius),
    };

    final (fillColor, borderColor) = switch (widget.variant) {
      SearchFieldVariant.pill => (status.neutralSurface, scheme.outlineVariant),
      SearchFieldVariant.prominent => (scheme.surface, scheme.outline),
      SearchFieldVariant.standard => (scheme.surface, scheme.outline),
    };

    return SizedBox(
      height: layout.controlHeight,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.outline,
              ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search,
              size: 20,
              color: scheme.outline,
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: layout.minimumTapTarget,
            minHeight: layout.minimumTapTarget,
          ),
          suffixIcon: widget.loading
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.outline,
                    ),
                  ),
                )
              : _hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: scheme.outline,
                      ),
                      onPressed: _handleClear,
                      tooltip: 'Clear search',
                    )
                  : null,
          suffixIconConstraints: BoxConstraints(
            minWidth: layout.minimumTapTarget,
            minHeight: layout.minimumTapTarget,
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
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

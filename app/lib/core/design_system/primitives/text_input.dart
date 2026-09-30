import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;

import '../foundation/palette.dart';
import '../foundation/radii.dart';

/// Standardized text input field with consistent label, error, and helper typography.
class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
  });

  const TextInput.multiline({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 4,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Palette.ink2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Palette.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefix,
            suffixIcon: suffix,
            errorText: hasError ? errorText : null,
            filled: true,
            fillColor: Palette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Palette.soft,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.control),
              borderSide: const BorderSide(color: Palette.line, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.control),
              borderSide: const BorderSide(color: Palette.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.control),
              borderSide: const BorderSide(color: Palette.ink, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.control),
              borderSide: const BorderSide(color: Palette.red, width: 1.5),
            ),
          ),
        ),
        if (!hasError && helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Palette.muted,
            ),
          ),
        ],
      ],
    );
  }
}

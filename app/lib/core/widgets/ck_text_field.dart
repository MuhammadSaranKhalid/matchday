import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;

import '../design_system/design_system.dart';

/// Backward compatibility wrapper for [TextInput].
///
/// Use [TextInput] from `package:matchday/core/design_system/design_system.dart` directly.
@Deprecated('Use TextInput from package:matchday/core/design_system/design_system.dart')
class CkTextField extends StatelessWidget {
  const CkTextField({
    super.key,
    required this.label,
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
    this.suffix,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
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
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextInput(
      label: label,
      controller: controller,
      hint: hint,
      errorText: errorText,
      helperText: helperText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofocus: autofocus,
      enabled: enabled,
      maxLength: maxLength,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      suffix: suffix,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/circk_theme.dart';

/// Circk's standard labelled text input: a clear label above a themed
/// [TextField], with optional helper / error text below.
///
/// The field decoration itself comes from [buildCirckTheme]'s
/// `inputDecorationTheme`; this widget adds the above-field label and the
/// inline error affordance the designs call for.
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
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CkColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
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
          style: CkType.body(fontSize: 16, color: CkColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            suffixIcon: suffix,
            errorText: hasError ? errorText : null,
          ),
        ),
        if (!hasError && helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: CkType.body(fontSize: 12, color: CkColors.muted),
          ),
        ],
      ],
    );
  }
}

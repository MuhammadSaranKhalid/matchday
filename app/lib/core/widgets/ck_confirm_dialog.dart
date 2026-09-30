import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Legacy confirmation dialog facade.
///
/// Prefer [showConfirmationDialog] from `package:matchday/core/design_system/design_system.dart`.
@Deprecated('Use showConfirmationDialog from package:matchday/core/design_system/design_system.dart')
Future<bool> showCkConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  String? emphasis,
  String? bodyTail,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) {
  return showConfirmationDialog(
    context,
    icon: icon,
    title: title,
    body: body,
    emphasis: emphasis,
    bodyTail: bodyTail,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    destructive: destructive,
  );
}

import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildTextFieldComponent() {
  return WidgetbookComponent(
    name: 'TextInput',
    useCases: [
      WidgetbookUseCase(
        name: 'Single & Multiline',
        builder: (context) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                TextInput(
                  label: 'Team Name',
                  hint: 'e.g. Lahore Lions',
                ),
                SizedBox(height: 16),
                TextInput(
                  label: 'With Helper Text',
                  hint: 'Username',
                  helperText: 'Must be between 3 and 20 characters',
                ),
                SizedBox(height: 16),
                TextInput(
                  label: 'With Error Text',
                  hint: 'Email',
                  errorText: 'Please enter a valid email address',
                ),
                SizedBox(height: 16),
                TextInput.multiline(
                  label: 'Tournament Description',
                  hint: 'Rules, prize pool, ground details...',
                  maxLines: 4,
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

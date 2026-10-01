import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildSegmentedControlComponent() {
  return WidgetbookComponent(
    name: 'SegmentedControl',
    useCases: [
      WidgetbookUseCase(
        name: 'Two Segments (Matches)',
        builder: (context) {
          return const _SegmentedControlDemo(
            options: [
              SegmentOption(value: 'confirmed', label: 'Confirmed', count: 3),
              SegmentOption(value: 'past', label: 'Past', count: 12),
            ],
            initialValue: 'confirmed',
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Three Segments (Tournaments)',
        builder: (context) {
          return const _SegmentedControlDemo(
            options: [
              SegmentOption(value: 'organizing', label: 'Organising', count: 2),
              SegmentOption(value: 'playing', label: 'Playing', count: 1),
              SegmentOption(value: 'following', label: 'Following', count: 5),
            ],
            initialValue: 'organizing',
          );
        },
      ),
    ],
  );
}

class _SegmentedControlDemo extends StatefulWidget {
  const _SegmentedControlDemo({
    required this.options,
    required this.initialValue,
  });

  final List<SegmentOption<String>> options;
  final String initialValue;

  @override
  State<_SegmentedControlDemo> createState() => _SegmentedControlDemoState();
}

class _SegmentedControlDemoState extends State<_SegmentedControlDemo> {
  late String _selected = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SegmentedControl<String>(
          options: widget.options,
          value: _selected,
          onChanged: (val) => setState(() => _selected = val),
        ),
      ),
    );
  }
}

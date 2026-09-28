import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/scoring_top_bar.dart';

void main() {
  testWidgets('ScoringTopBar renders close button, live pill, and match type',
      (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScoringTopBar(
            matchType: MatchType.friendly,
            onClose: () => closed = true,
            onMenuAction: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('SCORING'), findsOneWidget);
    expect(find.text('FRIENDLY'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  testWidgets('ScoringTopBar renders Undo button and fires onUndo',
      (tester) async {
    var undone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScoringTopBar(
            matchType: MatchType.friendly,
            onClose: () {},
            onMenuAction: (_) {},
            onUndo: () => undone = true,
            canUndo: true,
          ),
        ),
      ),
    );

    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undone, isTrue);
  });
}

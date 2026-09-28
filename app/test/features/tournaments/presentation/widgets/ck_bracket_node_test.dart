import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/presentation/widgets/ck_bracket_node.dart';

void main() {
  group('CkBracketNode widget tests', () {
    testWidgets('renders team names, seeds, scores and round label',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CkBracketNode(
              teamAName: 'Model Town CC',
              teamBName: 'Cantt CC',
              seedA: 1,
              seedB: 8,
              scoreA: '184/4',
              scoreB: '142/9',
              roundLabel: 'Quarter-Final 1',
              winnerTeamId: 'team-a',
              teamAId: 'team-a',
              teamBId: 'team-b',
            ),
          ),
        ),
      );

      expect(find.text('Model Town CC'), findsOneWidget);
      expect(find.text('Cantt CC'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('184/4'), findsOneWidget);
      expect(find.text('142/9'), findsOneWidget);
      expect(find.text('QUARTER-FINAL 1'), findsOneWidget);
    });
  });
}

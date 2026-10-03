import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_fee_entry.dart';
import 'package:matchday/features/tournaments/presentation/widgets/record_payment_sheet.dart';

void main() {
  const partialEntry = TournamentFeeEntry(
    entryId: 'entry-1',
    registrationId: 'registration-1',
    teamId: 'team-1',
    teamName: 'Lahore Lions',
    entryFee: 3000,
    amountPaid: 1000,
  );

  testWidgets('defaults to outstanding balance and returns one payment event', (
    tester,
  ) async {
    RecordPaymentOutcome? outcome;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  outcome = await showRecordPaymentSheet(
                    context,
                    entry: partialEntry,
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);

    expect(field.controller?.text, '2000');

    expect(find.textContaining('3,000 / 3,000'), findsOneWidget);

    await tester.tap(find.text('Save Payment Record'));
    await tester.pumpAndSettle();

    expect(outcome, isNotNull);
    expect(outcome!.amountReceived, 2000);
  });

  testWidgets('does not offer the original full fee as a second payment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showRecordPaymentSheet(context, entry: partialEntry);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2,000 · remaining'), findsOneWidget);

    expect(find.textContaining('3,000 · full'), findsNothing);
  });
}

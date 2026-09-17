import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/auth/domain/repositories/auth_repository.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/safety/presentation/providers/safety_providers.dart';
import 'package:matchday/features/settings/presentation/screens/settings_screen.dart';
import 'package:matchday/features/settings/presentation/screens/legal_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements AuthRepository {}

void main() {
  testWidgets(
    'deletion requires exact confirmation and reports server failure',
    (tester) async {
      final repo = MockAuth();
      when(
        () => repo.deleteAccount(),
      ).thenAnswer((_) async => const Left(ServerFailure('Deletion failed')));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            blockedAccountsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Delete account'), 250);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Delete account'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'delete');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Delete account'),
            )
            .onPressed,
        isNull,
      );
      verifyNever(() => repo.deleteAccount());
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();
      verify(() => repo.deleteAccount()).called(1);
      await tester.scrollUntilVisible(find.text('Deletion failed'), 250);
      await tester.pumpAndSettle();
      expect(find.text('Deletion failed'), findsOneWidget);
    },
  );
  testWidgets('privacy is readable inside the app without opening a browser', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(document: 'privacy')),
    );
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Who operates Matchday'), findsOneWidget);
  });
}

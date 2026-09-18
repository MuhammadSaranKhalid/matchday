import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/core/supabase/supabase_client_provider.dart';
import 'package:matchday/features/profile/domain/entities/profile.dart';
import 'package:matchday/features/profile/presentation/providers/profile_providers.dart';
import 'package:matchday/features/shell/presentation/screens/menu_screen.dart';
import '../../../../helpers/mock_auth.dart';

const _profile = Profile(
  userId: ProfileUserId('u1'),
  username: 'saran',
  displayName: 'Muhammad Saran',
  city: 'Lahore',
);

/// The menu is a full-screen route, so it brings its own [Scaffold] and header
/// — nothing wraps it here. It reads two things and only two: the profile (for
/// the name and avatar) and the signed-in user (for the email).
Future<void> _pumpMenu(
  WidgetTester tester, {
  Profile? profile = _profile,
  double textScale = 1.0,
}) async {
  final supabase = createMockSupabaseClient(
    id: 'u1',
    email: 'saran@gmail.com',
  );

  // The artboard's viewport.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // MaterialApp rebuilds MediaQuery from the view, so an ancestor MediaQuery
  // would be discarded — the scale has to be set on the platform dispatcher.
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, __) => const MenuScreen())],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(supabase),
        myProfileProvider.overrideWith((ref) => Future.value(profile)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('MenuScreen — artboard 2b, "Nothing on the right"', () {
    testWidgets('three groups, nine rows, in the canvas order', (tester) async {
      await _pumpMenu(tester);

      expect(find.text('Menu'), findsOneWidget);

      expect(find.text('YOURS'), findsOneWidget);
      expect(find.text('My Matches'), findsOneWidget);
      expect(find.text('My Teams'), findsOneWidget);
      expect(find.text('My Challenges'), findsOneWidget);
      expect(find.text('My Tournaments'), findsOneWidget);

      expect(find.text('ACTIVITY'), findsOneWidget);
      expect(find.text('Invites & requests'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);

      // The whole panel fits the artboard viewport, so nothing needs scrolling
      // to reach — including the pinned footer.
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('nothing on the right: no badge, no subtitle, no live card',
        (tester) async {
      await _pumpMenu(tester);

      // The counts the panel used to carry. They live on the screens that own
      // them now, one tap deeper.
      expect(find.textContaining('upcoming'), findsNothing);
      expect(find.textContaining('pending'), findsNothing);
      expect(find.textContaining('open'), findsNothing);
      expect(find.text('Live now'), findsNothing);
      expect(find.text('LIVE'), findsNothing);

      // The prose subtitles that used to sit under each label.
      expect(find.text('Fixtures you are playing in'), findsNothing);
      expect(find.text('Squads you own or belong to'), findsNothing);
      expect(find.text('Challenges you posted'), findsNothing);

      // And the roadmap group, which 2b drops entirely.
      expect(find.text('NOT BUILT YET'), findsNothing);
      expect(find.text('Clubs'), findsNothing);

      // The version stamp went with the rest of the furniture.
      expect(find.text('MATCHDAY · v2.0'), findsNothing);
    });

    testWidgets('the identity block names the account, not the profile',
        (tester) async {
      await _pumpMenu(tester);

      expect(find.text('Muhammad Saran'), findsOneWidget);
      expect(find.text('saran@gmail.com'), findsOneWidget);

      // 2b replaces "@handle · role · city" and the posts/followers line with
      // the one fact the block is for: which account this is.
      expect(find.text('@saran'), findsNothing);
      expect(find.textContaining('Followers'), findsNothing);
      expect(find.textContaining('Posts'), findsNothing);
      expect(find.textContaining('Lahore'), findsNothing);
    });

    testWidgets('Help & Support is the one row wearing a pill, not a chevron',
        (tester) async {
      await _pumpMenu(tester);

      expect(find.text('SOON'), findsOneWidget);

      // It is inert: the row is drawn, but it is not a destination.
      final row = find.ancestor(
        of: find.text('Help & Support'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(row.first).onTap, isNull);
    });

    testWidgets('sign out asks before it signs out', (tester) async {
      await _pumpMenu(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to sign out of Matchday?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to sign out of Matchday?'),
          findsNothing);
    });

    testWidgets('a profile that has not loaded still renders the navigation',
        (tester) async {
      await _pumpMenu(tester, profile: null);

      // The rows are the point; the identity block degrades to empty strings
      // rather than taking the page down with it.
      expect(find.text('My Matches'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('saran@gmail.com'), findsOneWidget);
    });

    // Regression: CkType.display and CkType.mono take letterSpacing in *em*
    // and multiply it by fontSize (circk_theme.dart). The canvas states its
    // tracking in px ("letter-spacing:-.5px"), so copying those numbers across
    // verbatim yields -0.5 * 25 = -12.5px and every glyph lands on top of the
    // one before it. find.text() still passes in that state — it reads the
    // widget, not the paint — so the band has to be asserted directly.
    testWidgets('tracking stays in em, never raw canvas px', (tester) async {
      await _pumpMenu(tester);

      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts, isNotEmpty);

      for (final t in texts) {
        final style = t.style;
        final size = style?.fontSize;
        final spacing = style?.letterSpacing;
        if (style == null || size == null || spacing == null) continue;

        expect(
          spacing.abs(),
          lessThanOrEqualTo(size * 0.25),
          reason: '"${t.data}" is tracked ${spacing}px on a ${size}px face — '
              'that reads as an em value passed where px were meant, or the '
              'reverse.',
        );
      }
    });

    testWidgets('survives 120% OS text scale without overflowing',
        (tester) async {
      await _pumpMenu(tester, textScale: 1.2);

      expect(tester.takeException(), isNull);
      expect(find.text('My Tournaments'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}

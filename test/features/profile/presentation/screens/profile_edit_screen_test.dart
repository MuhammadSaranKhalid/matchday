import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/core/supabase/supabase_client_provider.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/profile/domain/entities/profile.dart';
import '../../../../helpers/mock_auth.dart';
import 'package:matchday/features/profile/domain/repositories/avatar_picker.dart';
import 'package:matchday/features/profile/domain/repositories/profile_repository.dart';
import 'package:matchday/features/profile/presentation/providers/profile_providers.dart';
import 'package:matchday/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfileRepository {}

class _MockPicker extends Mock implements AvatarPicker {}

const _profile = Profile(
  userId: ProfileUserId('u1'),
  username: 'saran',
  displayName: 'Muhammad Saran',
  city: 'Lahore',
);

Future<void> _pump(WidgetTester tester) async {
  final repo = _MockRepo();
  when(() => repo.isUsernameAvailable(any()))
      .thenAnswer((_) async => const Right(true));

  final user = User(
    id: const UserId('u1'),
    email: Email.create('muhammadsarankhalid@gmail.com')
        .toOption()
        .toNullable()!,
    displayName: 'Muhammad Saran',
  );

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const ProfileEditScreen()),
    ],
  );
  addTearDown(router.dispose);

  // The controller seeds itself from `myProfileProvider` in `build()`, so the
  // profile has to be resolved before the screen mounts. That is what happens
  // in the app: the provider is keepAlive, and the only way in is the Edit
  // button on the profile screen, which renders inside its resolved data.
  final container = ProviderContainer.test(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repo),
      avatarPickerProvider.overrideWithValue(_MockPicker()),
      myProfileProvider.overrideWith((ref) => Future.value(_profile)),
      supabaseClientProvider.overrideWithValue(
        createMockSupabaseClient(id: user.id.value, email: user.email.value),
      ),
    ],
  );
  await container.read(myProfileProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('ProfileEditScreen — artboard 1a', () {
    testWidgets('three sections, four editable things, one Save',
        (tester) async {
      await _pump(tester);

      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      expect(find.text('IDENTITY'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);

      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('0 / 200'), findsOneWidget);

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(
        find.text('muhammadsarankhalid@gmail.com'),
        findsOneWidget,
      );
      // The privacy row is parked — its call site is commented out in the
      // Account group. Restore this assertion when the row comes back.
      // expect(find.text('Private account & blocking'), findsOneWidget);
    });

    testWidgets('location is gone — no field, no label, no GPS',
        (tester) async {
      await _pump(tester);

      // The canvas is explicit: "No location field anywhere in this flow, and
      // no GPS permission is requested from it."
      expect(find.text('City'), findsNothing);
      expect(find.text('Location'), findsNothing);
      expect(find.textContaining('Lahore'), findsNothing);
      expect(find.textContaining('location'), findsNothing);
      expect(find.byIcon(Icons.my_location), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('Save is present but dead until something changes',
        (tester) async {
      await _pump(tester);

      final pill = find.ancestor(
        of: find.text('Save'),
        matching: find.byType(InkWell),
      );
      // "not hidden" — a disabled Save still occupies its slot.
      expect(pill, findsWidgets);
      expect(tester.widget<InkWell>(pill.first).onTap, isNull);

      await tester.enterText(find.byType(TextField).first, 'Saran Khalid');
      await tester.pump();

      expect(tester.widget<InkWell>(pill.first).onTap, isNotNull);
    });

    testWidgets('backing out with edits asks before discarding them',
        (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Saran Khalid');
      await tester.pump();

      await tester.tap(find.byType(InkWell).first); // the back disc
      await tester.pumpAndSettle();

      expect(find.text('Discard your changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('the username is locked, and says so rather than going quiet',
        (tester) async {
      await _pump(tester);

      // It still reads as a field, and still shows the handle.
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('@saran'), findsOneWidget);
      expect(
        find.text('Username changes are coming in a later update.'),
        findsOneWidget,
      );

      // Name and bio are the only editable fields while it is locked.
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.tap(find.text('@saran'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("You can't change your username yet"), findsOneWidget);
    });

    testWidgets('the locked email explains itself rather than editing',
        (tester) async {
      await _pump(tester);

      await tester.tap(find.text('muhammadsarankhalid@gmail.com'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Email is your sign-in'), findsOneWidget);
    });

    // The canvas states every one of these in artboard 2a, the build spec
    // drawn against 1a. They are asserted rather than eyeballed because the
    // whole brief was "exactly".
    testWidgets('geometry matches the 2a build spec', (tester) async {
      await _pump(tester);

      Rect rect(Finder f) => tester.getRect(f.first);

      // "44 status + 50 bar", the status bar being the SafeArea inset.
      final bar = rect(
        find.ancestor(
          of: find.text('Edit profile'),
          matching: find.byType(Row),
        ).last,
      );
      expect(bar.height, 50);
      expect(bar.left, 16);

      // "back 38 disc in 44 target"
      final target = rect(find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 44 && w.height == 44,
      ));
      expect(target.size, const Size(44, 44));

      // "Save · 38 h · 20 side pad"
      expect(
        rect(find.ancestor(
          of: find.text('Save'),
          matching: find.byType(Container),
        )).height,
        38,
      );

      // Cover strip 112 h inside a 112 + 46 clearance block.
      final media = rect(find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 158,
      ));
      expect(media.height, 112 + 46);
      final coverBottom = media.top + 112;

      // "Cover pill 32 h top/right 16"
      final coverPill = rect(find.ancestor(
        of: find.text('COVER'),
        matching: find.byType(Container),
      ));
      expect(coverPill.height, 32);
      expect(coverPill.top - media.top, 16);
      expect(390 - coverPill.right, 16);

      // "Avatar 88 circle · x 20 · overhangs cover by 36"
      final avatar = rect(find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 88,
      ));
      expect(avatar.size, const Size(88, 88));
      expect(avatar.left, 20);
      expect(avatar.bottom - coverBottom, 36);

      // "Field 50 h", on a 20pt gutter.
      final nameBox = rect(find.ancestor(
        of: find.byType(TextField).first,
        matching: find.byType(Container),
      ));
      expect(nameBox.height, 50);
      expect(nameBox.left, 20);
      expect(nameBox.width, 350);

      // Username is locked for now, but it keeps the field's box exactly —
      // "same 50/r13 box so it reads as a field, not a row".
      final usernameBox = rect(find.ancestor(
        of: find.text('@saran'),
        matching: find.byType(Container),
      ));
      expect(usernameBox.height, 50);
      expect(usernameBox.left, 20);
      expect(usernameBox.width, 350);

      // "Locked email · same 50/r13 box so it reads as a field, not a row"
      expect(
        rect(find.ancestor(
          of: find.text('muhammadsarankhalid@gmail.com'),
          matching: find.byType(Container),
        )).height,
        50,
      );
    });

    // Regression guard, same as the Menu screen: CkType.display/mono take
    // letterSpacing in em and multiply by fontSize, while the canvas states it
    // in px. Copying canvas numbers across verbatim collapses the glyphs.
    testWidgets('tracking stays in em, never raw canvas px', (tester) async {
      await _pump(tester);

      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final size = t.style?.fontSize;
        final spacing = t.style?.letterSpacing;
        if (size == null || spacing == null) continue;
        expect(
          spacing.abs(),
          lessThanOrEqualTo(size * 0.25),
          reason: '"${t.data}" is tracked ${spacing}px on a ${size}px face.',
        );
      }
    });
  });
}

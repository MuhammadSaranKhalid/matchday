import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/profile/domain/entities/profile.dart';
import 'package:matchday/features/profile/domain/repositories/avatar_picker.dart';
import 'package:matchday/features/profile/domain/repositories/profile_repository.dart';
import 'package:matchday/features/profile/domain/value_objects/display_name.dart';
import 'package:matchday/features/profile/presentation/controllers/profile_edit_controller.dart';
import 'package:matchday/features/profile/presentation/providers/profile_providers.dart';
import 'package:matchday/features/profile/presentation/state/profile_edit_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfileRepository {}

class _MockPicker extends Mock implements AvatarPicker {}

const _profile = Profile(
  userId: ProfileUserId('u1'),
  username: 'saran',
  displayName: 'Muhammad Saran',
  bio: 'Right-arm off-spin.',
  city: 'Lahore',
);

void main() {
  late _MockRepo repo;
  late _MockPicker picker;

  setUpAll(() {
    registerFallbackValue(DisplayName.create('Someone').getRight().toNullable()!);
  });

  setUp(() {
    repo = _MockRepo();
    picker = _MockPicker();
    when(() => repo.isUsernameAvailable(any()))
        .thenAnswer((_) async => const Right(true));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer.test(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        avatarPickerProvider.overrideWithValue(picker),
        myProfileProvider.overrideWith((ref) => Future.value(_profile)),
      ],
    );
    // The controller seeds itself from the resolved profile.
    await container.read(myProfileProvider.future);
    // It is autoDispose, and `read(.notifier)` leaves no listener behind — so
    // it would be torn down across the first await, taking the debounce timer
    // with it. A live subscription keeps it mounted for the test, exactly as
    // the screen's `ref.watch` does.
    container.listen(profileEditControllerProvider, (_, __) {});
    return container;
  }

  group('dirty tracking (artboard 2a)', () {
    test('Save is dead until something differs, and dies again on revert',
        () async {
      final c = await makeContainer();
      final n = c.read(profileEditControllerProvider.notifier);

      expect(c.read(profileEditControllerProvider).dirty, isFalse);
      expect(c.read(profileEditControllerProvider).canSave, isFalse);

      n.setDisplayName('Muhammad Sarann');
      expect(c.read(profileEditControllerProvider).dirty, isTrue);
      expect(c.read(profileEditControllerProvider).canSave, isTrue);

      // Reverting to the server value puts it back to sleep.
      n.setDisplayName('Muhammad Saran');
      expect(c.read(profileEditControllerProvider).dirty, isFalse);
      expect(c.read(profileEditControllerProvider).canSave, isFalse);
    });

    test('a cover pick counts as dirty on its own', () async {
      final c = await makeContainer();
      when(() => picker.pickCover())
          .thenAnswer((_) async => File('/tmp/cover.jpg'));

      await c.read(profileEditControllerProvider.notifier).pickCover();

      expect(c.read(profileEditControllerProvider).dirty, isTrue);
    });
  });

  group('username availability (artboard 2a)', () {
    test('checks 400ms after typing stops, and holds Save down until it lands',
        () async {
      final c = await makeContainer();
      final n = c.read(profileEditControllerProvider.notifier);

      n.setUsername('saran_offspin');
      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.checking,
      );
      // Dirty, but not saveable while the answer is outstanding.
      expect(c.read(profileEditControllerProvider).dirty, isTrue);
      expect(c.read(profileEditControllerProvider).canSave, isFalse);
      verifyNever(() => repo.isUsernameAvailable(any()));

      await Future<void>.delayed(const Duration(milliseconds: 500));

      verify(() => repo.isUsernameAvailable('saran_offspin')).called(1);
      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.available,
      );
      expect(c.read(profileEditControllerProvider).canSave, isTrue);
    });

    test('a taken handle blocks Save', () async {
      when(() => repo.isUsernameAvailable(any()))
          .thenAnswer((_) async => const Right(false));
      final c = await makeContainer();

      c.read(profileEditControllerProvider.notifier).setUsername('taken_one');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.taken,
      );
      expect(c.read(profileEditControllerProvider).canSave, isFalse);
    });

    test('typing back to your own handle clears the chip entirely', () async {
      final c = await makeContainer();
      final n = c.read(profileEditControllerProvider.notifier);

      n.setUsername('saran_x');
      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.checking,
      );

      n.setUsername('saran');
      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.untouched,
      );
      expect(c.read(profileEditControllerProvider).dirty, isFalse);
    });

    test('a failed check does not read as taken', () async {
      when(() => repo.isUsernameAvailable(any()))
          .thenAnswer((_) async => const Left(NetworkFailure('offline')));
      final c = await makeContainer();

      c.read(profileEditControllerProvider.notifier).setUsername('saran_new');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Reverts to untouched so a blip cannot strand the user on a form they
      // cannot save; the server has the last word.
      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.untouched,
      );
      expect(c.read(profileEditControllerProvider).canSave, isTrue);
    });

    test('only the newest request may publish a result', () async {
      final answers = <String, bool>{'aaa_first': false, 'bbb_second': true};
      when(() => repo.isUsernameAvailable(any())).thenAnswer((inv) async {
        final name = inv.positionalArguments.first as String;
        // The first request is deliberately the slow one.
        await Future<void>.delayed(
          Duration(milliseconds: name == 'aaa_first' ? 300 : 10),
        );
        return Right(answers[name]!);
      });

      final c = await makeContainer();
      final n = c.read(profileEditControllerProvider.notifier);

      n.setUsername('aaa_first');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      n.setUsername('bbb_second');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // The slow "taken" for aaa_first must not overwrite bbb_second.
      expect(
        c.read(profileEditControllerProvider).usernameStatus,
        UsernameStatus.available,
      );
    });
  });

  group('save', () {
    test('sends no city or geo — 1a removes location from this form', () async {
      when(
        () => repo.updateProfile(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatar: any(named: 'avatar'),
          cover: any(named: 'cover'),
        ),
      ).thenAnswer((_) async => const Right(_profile));

      final c = await makeContainer();
      c.read(profileEditControllerProvider.notifier).setDisplayName('Saran K');

      final ok = await c.read(profileEditControllerProvider.notifier).save();
      expect(ok, isTrue);

      final call = verify(
        () => repo.updateProfile(
          displayName: captureAny(named: 'displayName'),
          username: captureAny(named: 'username'),
          bio: captureAny(named: 'bio'),
          avatar: any(named: 'avatar'),
          cover: any(named: 'cover'),
        ),
      )..called(1);

      // An unchanged handle is never sent, so the cooldown is never tripped.
      expect(call.captured[1], isNull);
    });

    test('an empty name is refused on the field, in the canvas words',
        () async {
      final c = await makeContainer();
      c.read(profileEditControllerProvider.notifier).setDisplayName('   ');

      final ok = await c.read(profileEditControllerProvider.notifier).save();

      expect(ok, isFalse);
      expect(
        c.read(profileEditControllerProvider).nameError,
        "Your name can't be empty.",
      );
      verifyNever(
        () => repo.updateProfile(displayName: any(named: 'displayName')),
      );
    });

    test('a failed save keeps every edit', () async {
      when(
        () => repo.updateProfile(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatar: any(named: 'avatar'),
          cover: any(named: 'cover'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('nope')));

      final c = await makeContainer();
      final n = c.read(profileEditControllerProvider.notifier);
      n.setDisplayName('Saran K');
      n.setBio('New bio');

      expect(await n.save(), isFalse);

      final s = c.read(profileEditControllerProvider);
      expect(s.displayName, 'Saran K');
      expect(s.bio, 'New bio');
      expect(s.saving, isFalse);
      expect(s.error, isA<ServerFailure>());
    });

    test('newlines in the bio collapse to spaces', () async {
      when(
        () => repo.updateProfile(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          bio: any(named: 'bio'),
          avatar: any(named: 'avatar'),
          cover: any(named: 'cover'),
        ),
      ).thenAnswer((_) async => const Right(_profile));

      final c = await makeContainer();
      c
          .read(profileEditControllerProvider.notifier)
          .setBio('Off-spin.\n\nModel Town, Lahore.');

      await c.read(profileEditControllerProvider.notifier).save();

      final call = verify(
        () => repo.updateProfile(
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          bio: captureAny(named: 'bio'),
          avatar: any(named: 'avatar'),
          cover: any(named: 'cover'),
        ),
      )..called(1);
      expect(call.captured.single, 'Off-spin. Model Town, Lahore.');
    });
  });
}

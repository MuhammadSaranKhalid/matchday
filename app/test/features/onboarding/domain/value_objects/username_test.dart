import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/profile/domain/value_objects/username.dart';

void main() {
  group('Username.create', () {
    test('rejects empty', () {
      expect(Username.create('   ').isLeft(), isTrue);
    });

    test('rejects shorter than 3', () {
      expect(Username.create('ab').isLeft(), isTrue);
    });

    test('rejects longer than 20', () {
      expect(Username.create('a' * 21).isLeft(), isTrue);
    });

    test('rejects a leading digit with a helpful message', () {
      final result = Username.create('9ahmed');
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Must start with a letter',
        ),
      );
    });

    test('rejects disallowed characters', () {
      expect(Username.create('ahmed khan').isLeft(), isTrue);
      expect(Username.create('ahmed!').isLeft(), isTrue);
    });

    test('rejects reserved handles', () {
      for (final r in ['admin', 'circk', 'support']) {
        expect(Username.create(r).isLeft(), isTrue, reason: r);
      }
    });

    test('lowercases and accepts a valid handle', () {
      final result = Username.create('  Ahmed_K92 ');
      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.value, 'ahmed_k92');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/posts/domain/value_objects/post_text.dart';

void main() {
  group('PostText Value Object', () {
    test('creates valid PostText with standard string', () {
      final result = PostText.create('Great match today!', hasPhotos: false);
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should succeed'),
        (vo) => expect(vo.value, equals('Great match today!')),
      );
    });

    test('rejects empty text when there are no photos', () {
      final result = PostText.create('   ', hasPhotos: false);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('text or a photo')),
        (_) => fail('Should fail'),
      );
    });

    test('accepts empty or null text when photos are attached', () {
      final result = PostText.create('', hasPhotos: true);
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should succeed'),
        (vo) => expect(vo.value, isNull),
      );
    });

    test('rejects text exceeding 2000 characters', () {
      final text2001 = 'x' * 2001;
      final result = PostText.create(text2001, hasPhotos: true);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('2000')),
        (_) => fail('Should fail'),
      );
    });

    test('accepts text at exactly 2000 characters', () {
      final text2000 = 'x' * 2000;
      final result = PostText.create(text2000, hasPhotos: false);
      expect(result.isRight(), isTrue);
    });
  });
}

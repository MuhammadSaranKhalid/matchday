import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/posts/domain/entities/media_variant.dart';
import 'package:matchday/features/posts/domain/entities/post_media.dart';

void main() {
  group('PostMedia Responsive Variant Selection (Points 11, 33, 34)', () {
    final media = PostMedia(
      mediaId: 'm1',
      postId: 'p1',
      position: 0,
      width: 1080,
      height: 1350,
      status: PostMediaStatus.optimized,
      variants: const {
        360: MediaVariant(
          path: 'posts/p1/m1/v1/360.webp',
          width: 360,
          height: 450,
          sizeBytes: 15000,
          mimeType: 'image/webp',
        ),
        540: MediaVariant(
          path: 'posts/p1/m1/v1/540.webp',
          width: 540,
          height: 675,
          sizeBytes: 28000,
          mimeType: 'image/webp',
        ),
        720: MediaVariant(
          path: 'posts/p1/m1/v1/720.webp',
          width: 720,
          height: 900,
          sizeBytes: 45000,
          mimeType: 'image/webp',
        ),
        1080: MediaVariant(
          path: 'posts/p1/m1/v1/1080.webp',
          width: 1080,
          height: 1350,
          sizeBytes: 85000,
          mimeType: 'image/webp',
        ),
        2048: MediaVariant(
          path: 'posts/p1/m1/v1/2048.webp',
          width: 2048,
          height: 2560,
          sizeBytes: 220000,
          mimeType: 'image/webp',
        ),
      },
    );

    test('selects 360 for physical width <= 360', () {
      final selected = media.selectVariant(320);
      expect(selected?.width, equals(360));
    });

    test('selects 540 for physical width between 361 and 540', () {
      final selected = media.selectVariant(470);
      expect(selected?.width, equals(540));
    });

    test('selects 720 for physical width between 541 and 720', () {
      final selected = media.selectVariant(630);
      expect(selected?.width, equals(720));
    });

    test('selects 1080 for physical width between 721 and 1080', () {
      final selected = media.selectVariant(970);
      expect(selected?.width, equals(1080));
    });

    test('falls back upward when lower variant is missing', () {
      final partialMedia = PostMedia(
        mediaId: 'm2',
        postId: 'p1',
        position: 0,
        width: 1080,
        height: 1350,
        status: PostMediaStatus.feedReady,
        variants: const {
          1080: MediaVariant(
            path: 'posts/p1/m2/v1/1080.webp',
            width: 1080,
            height: 1350,
            sizeBytes: 85000,
            mimeType: 'image/webp',
          ),
        },
      );

      // Under feed-ready, 540 is not yet generated, so requests for 400px should fallback to 1080
      final selected = partialMedia.selectVariant(400);
      expect(selected?.width, equals(1080));
    });

    test('aspectRatio correctly calculated', () {
      expect(media.aspectRatio, closeTo(1080 / 1350, 0.001));
    });
  });
}

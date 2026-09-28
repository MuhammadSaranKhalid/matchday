import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/posts/data/models/post_media_dto.dart';

void main() {
  group('MediaVariantDto Deserialization Compatibility', () {
    test('parses worker format with bytes and mime', () {
      final json = {
        'path': 'posts/uid/pid/mid/1080.webp',
        'width': 1080,
        'height': 1350,
        'bytes': 84210,
        'mime': 'image/webp',
      };

      final dto = MediaVariantDto.fromJson(json);

      expect(dto.path, equals('posts/uid/pid/mid/1080.webp'));
      expect(dto.width, equals(1080));
      expect(dto.height, equals(1350));
      expect(dto.sizeBytes, equals(84210));
      expect(dto.mimeType, equals('image/webp'));
    });

    test('parses firebase format with sizeBytes and mimeType', () {
      final json = {
        'path': 'posts/uid/pid/mid/540.webp',
        'width': 540,
        'height': 675,
        'sizeBytes': 32100,
        'mimeType': 'image/webp',
      };

      final dto = MediaVariantDto.fromJson(json);

      expect(dto.sizeBytes, equals(32100));
      expect(dto.mimeType, equals('image/webp'));
    });

    test('parses snake_case size_bytes and mime_type', () {
      final json = {
        'path': 'posts/uid/pid/mid/720.webp',
        'width': 720,
        'height': 900,
        'size_bytes': 51200,
        'mime_type': 'image/webp',
      };

      final dto = MediaVariantDto.fromJson(json);

      expect(dto.sizeBytes, equals(51200));
      expect(dto.mimeType, equals('image/webp'));
    });
  });

  group('PostMediaDto toEntity Mapping', () {
    test('maps raw variants map correctly with mixed keys', () {
      final json = {
        'media_id': 'm-123',
        'post_id': 'p-456',
        'position': 0,
        'width': 1080,
        'height': 1350,
        'blurhash': 'LEHV6n004n-s_300000000_3',
        'status': 'optimized',
        'variants': {
          '360': {
            'path': 'posts/p/m/360.webp',
            'width': 360,
            'height': 450,
            'bytes': 15000,
            'mime': 'image/webp',
          },
          '1080': {
            'path': 'posts/p/m/1080.webp',
            'width': 1080,
            'height': 1350,
            'size_bytes': 85000,
            'mime_type': 'image/webp',
          },
        },
      };

      final dto = PostMediaDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.mediaId, equals('m-123'));
      expect(entity.variants.containsKey(360), isTrue);
      expect(entity.variants[360]?.sizeBytes, equals(15000));
      expect(entity.variants.containsKey(1080), isTrue);
      expect(entity.variants[1080]?.sizeBytes, equals(85000));
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matchday/features/notifications/data/models/notification_dto.dart';
import 'package:matchday/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:matchday/features/notifications/domain/entities/app_notification.dart';
import 'package:matchday/features/notifications/presentation/widgets/notification_icon.dart';
import 'package:matchday/core/theme/circk_theme.dart';

Map<String, dynamic> row(String id) => {
  'notification_id': id,
  'recipient_id': 'recipient',
  'type_key': 'future.surprise',
  'title': 'A newly introduced event',
  'body': 'Server supplied text',
  'tier': 'unknown',
  'icon': 'new_icon',
  'icon_path': 'v2/new-icon.svg',
  'tone': 'achievement',
  'created_at': '2026-09-12T00:00:00Z',
};
void main() {
  test('unknown notification type preserves copy and remote SVG identity', () {
    final n = NotificationDto.fromJson(row('a')).toEntity();
    expect(n.typeKey, 'future.surprise');
    expect(n.body, 'Server supplied text');
    expect(n.iconPath, 'v2/new-icon.svg');
    expect(n.tier, NotificationTier.fyi);
    expect(n.copyWith(isRead: true).tone, 'achievement');
  });
  test('changed grouped copy changes entity equality', () {
    final first = NotificationDto.fromJson(row('a'));
    expect(
      first.toEntity(),
      isNot(first.copyWith(body: 'Updated summary').toEntity()),
    );
  });
  test('colors are independent of icon identity and unknown tones use ink', () {
    expect(NotificationIcon.colorFor('achievement'), CkColors.amberInk);
    expect(NotificationIcon.colorFor('success'), CkColors.greenInk);
    expect(NotificationIcon.colorFor('future-tone'), CkColors.ink2);
    for (final tone in [
      'neutral',
      'brand',
      'success',
      'warning',
      'achievement',
    ]) {
      final contrast =
          (CkColors.paper2.computeLuminance() + 0.05) /
          (NotificationIcon.colorFor(tone).computeLuminance() + 0.05);
      expect(contrast, greaterThanOrEqualTo(3));
    }
  });
  test('cursor includes timestamp and id and limits each page', () async {
    late Map<String, dynamic> params;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        params = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode([row('b')]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final remote = NotificationsRemoteDataSource(client);
    final result = await remote.listMine(
      before: NotificationDto.fromJson(row('a')),
    );
    expect(params['p_before_id'], 'a');
    expect(params['p_before_created'], '2026-09-12T00:00:00Z');
    expect(params['p_limit'], 40);
    expect(result.single.notificationId, 'b');
    expect(remote.iconUrl('../other.svg'), isNull);
    expect(remote.iconUrl('https://untrusted.test/x.svg'), isNull);
    expect(
      remote.iconUrl('v2/new-icon.svg'),
      endsWith('/notification-icons/v2/new-icon.svg'),
    );
  });
}

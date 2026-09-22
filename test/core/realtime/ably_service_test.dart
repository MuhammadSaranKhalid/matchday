import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/realtime/ably_service.dart';

class _FakeChannel {
  _FakeChannel(this.name);

  final String name;
  int detachCalls = 0;

  Future<void> detach() async {
    detachCalls += 1;
  }
}

void main() {
  test('shared channel detaches only after final lease releases', () async {
    final channels = <String, _FakeChannel>{};
    final registry = ReferenceCountedChannelRegistry<_FakeChannel>(
      resolve: (name) => channels.putIfAbsent(name, () => _FakeChannel(name)),
      detach: (channel) => channel.detach(),
    );

    final first = registry.acquire('match:m1:state');
    final second = registry.acquire('match:m1:state');

    expect(identical(first.channel, second.channel), isTrue);
    expect(registry.leaseCount('match:m1:state'), 2);

    await first.release();
    expect(channels['match:m1:state']!.detachCalls, 0);
    expect(registry.leaseCount('match:m1:state'), 1);

    await second.release();
    expect(channels['match:m1:state']!.detachCalls, 1);
    expect(registry.leaseCount('match:m1:state'), 0);
  });

  test('duplicate lease release is harmless', () async {
    final channel = _FakeChannel('match:m1:state');
    final registry = ReferenceCountedChannelRegistry<_FakeChannel>(
      resolve: (_) => channel,
      detach: (value) => value.detach(),
    );

    final lease = registry.acquire(channel.name);
    await lease.release();
    await lease.release();

    expect(channel.detachCalls, 1);
  });

  test('connection notifier delivers reconnect transitions', () async {
    final notifier = RealtimeConnectionNotifier();
    final observed = <RealtimeConnectionStatus>[];
    final subscription = notifier.changes.listen(observed.add);

    notifier.update(RealtimeConnectionStatus.disconnected);
    notifier.update(RealtimeConnectionStatus.connected);
    await Future<void>.delayed(Duration.zero);

    expect(observed, [
      RealtimeConnectionStatus.disconnected,
      RealtimeConnectionStatus.connected,
    ]);

    await subscription.cancel();
    await notifier.dispose();
  });
}

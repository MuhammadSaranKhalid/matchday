import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/log/ck_log.dart';

void main() {
  setUp(() {
    CkLog.recent.clear();
    CkLog.mute.clear();
  });

  test('renders channel, event and fields on one scannable line', () {
    CkLog.write(CkLogChannel.realtime, 'snapshot', data: {
      'match': 'dddddddd-0000-4000-8000-000000000001',
      'why': 'subscribed',
      'took': const Duration(milliseconds: 411),
    });

    final line = CkLog.recent.single.message;
    expect(line, contains('match.rt'));
    expect(line, contains('snapshot'));
    expect(line, contains('why=subscribed'));
    // Durations render as ms, not as Dart's `0:00:00.411000`.
    expect(line, contains('took=411ms'));
  });

  test('collapses uuids so rows can be matched by eye', () {
    CkLog.write(CkLogChannel.matchStart, 'derive',
        data: {'match': 'dddddddd-0000-4000-8000-000000000001'});

    expect(CkLog.recent.single.message, contains('match=dddddddd'));
    expect(CkLog.recent.single.message, isNot(contains('4000-8000')));
  });

  test('drops null fields rather than printing key=null', () {
    CkLog.write(CkLogChannel.matchStart, 'derive',
        data: {'phase': 'toss', 'batting': null});

    final line = CkLog.recent.single.message;
    expect(line, contains('phase=toss'));
    expect(line, isNot(contains('batting')));
  });

  test('a muted channel records nothing', () {
    CkLog.mute.add(CkLogChannel.realtime);
    CkLog.write(CkLogChannel.realtime, 'broadcast');
    CkLog.write(CkLogChannel.matchStart, 'derive');

    expect(CkLog.recent, hasLength(1));
    expect(CkLog.recent.single.channel, CkLogChannel.matchStart);
  });

  test('the ring buffer stays bounded under a long session', () {
    for (var i = 0; i < 400; i++) {
      CkLog.write(CkLogChannel.realtime, 'poll', data: {'n': i});
    }

    expect(CkLog.recent.length, lessThanOrEqualTo(300));
    // Oldest evicted, newest retained.
    expect(CkLog.recent.last.message, contains('n=399'));
  });

  test('sample output', () {
    CkLog.write(CkLogChannel.realtime, 'subscribe',
        data: {'match': 'dddddddd-0000-4000-8000-000000000001', 'replay': '10m/25'});
    CkLog.write(CkLogChannel.realtime, 'snapshot', data: {
      'match': 'dddddddd-0000-4000-8000-000000000001',
      'why': 'open',
      'took': const Duration(milliseconds: 411),
    });
    CkLog.write(CkLogChannel.realtime, 'channel',
        data: {'match': 'dddddddd-0000-4000-8000-000000000001', 'status': 'subscribed'});
    CkLog.write(CkLogChannel.matchStart, 'derive', data: {
      'match': 'dddddddd-0000-4000-8000-000000000001',
      'phase': 'toss',
      'role': 'battingCaptain',
      'xi': 6,
    });
    CkLog.write(CkLogChannel.rpc, 'record_match_toss·ok',
        data: {'took': const Duration(milliseconds: 240)});
    CkLog.write(CkLogChannel.realtime, 'broadcast',
        data: {'match': 'dddddddd-0000-4000-8000-000000000001', 'replayed': false});

    for (final l in CkLog.recent) {
      // ignore: avoid_print
      print(l.message);
    }

    expect(CkLog.recent, hasLength(6));
  });
}

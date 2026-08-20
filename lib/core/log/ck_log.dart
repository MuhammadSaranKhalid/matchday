import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Structured diagnostic logging.
///
/// Built on `dart:developer`'s [developer.log] rather than a package, for two
/// reasons: it adds no dependency to a pubspec with a documented resolution
/// conflict (§4), and it is what DevTools' Logging view and `flutter logs`
/// already consume — so channel names become filters for free.
///
/// Lines are timestamped from process start, which is what makes them useful
/// for the realtime work: "the reconnect fired 4.2s after the drop" is the
/// question being asked, and a wall clock does not answer it as readably.
///
/// ```
/// [  0.412s] match.rt     snapshot·hit   match=dddddddd phase=toss took=411ms
/// [ 12.310s] match.rt     broadcast      match=dddddddd phase=lineup replayed=false
/// [ 12.311s] match.start  transition     toss→lineup role=battingCaptain
/// ```
///
/// Nothing here logs names, emails or tokens — ids only, truncated to their
/// first 8 characters, which is enough to correlate rows by eye.
abstract final class CkLog {
  const CkLog._();

  /// Master switch. Debug builds log by default; flip [forceEnabled] to carry
  /// logging into a profile build for on-ground testing, where the failures
  /// this instrumentation exists for actually happen.
  static bool forceEnabled = false;

  static bool get enabled => kDebugMode || forceEnabled;

  /// Per-channel mute, so a noisy area can be silenced without touching call
  /// sites — e.g. `CkLog.mute.add(CkLogChannel.realtime)` while working on UI.
  static final Set<String> mute = <String>{};

  static final Stopwatch _since = Stopwatch()..start();

  /// Ring buffer of recent lines, so a screen can show its own log without a
  /// debugger attached. Bounded — this is a debugging aid, not a store.
  static final List<CkLogLine> recent = <CkLogLine>[];
  static const _recentLimit = 300;

  static void write(
    String channel,
    String event, {
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
    int level = 500, // developer.log: FINE=500, INFO=800, WARNING=900
  }) {
    if (!enabled || mute.contains(channel)) return;

    final fields = data == null || data.isEmpty ? '' : ' ${_fields(data)}';
    final elapsed = (_since.elapsedMilliseconds / 1000).toStringAsFixed(3);
    final message = '[${elapsed.padLeft(7)}s] '
        '${channel.padRight(12)} ${event.padRight(16)}$fields';

    recent.add(CkLogLine(channel: channel, event: event, message: message));
    if (recent.length > _recentLimit) recent.removeAt(0);

    developer.log(
      message,
      name: channel,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Warning-level convenience — the things worth spotting in a scroll-back.
  static void warn(
    String channel,
    String event, {
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      write(
        channel,
        event,
        data: data,
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );

  static String _fields(Map<String, Object?> data) => data.entries
      .where((e) => e.value != null)
      .map((e) => '${e.key}=${_value(e.value)}')
      .join(' ');

  static String _value(Object? v) {
    if (v is Duration) return '${v.inMilliseconds}ms';
    return short(v);
  }

  /// Collapse a uuid to something the eye can match across lines; pass
  /// anything else through unchanged.
  static String short(Object? v) {
    final s = v.toString();
    if (s.length == 36 && s[8] == '-' && s[13] == '-') return s.substring(0, 8);
    return s;
  }
}

/// A captured line, for in-app display.
class CkLogLine {
  CkLogLine({
    required this.channel,
    required this.event,
    required this.message,
  }) : at = DateTime.now();

  final String channel;
  final String event;
  final String message;
  final DateTime at;
}

/// Channel names. Kept as constants so they can be used as DevTools filters
/// and passed to [CkLog.mute] without stringly-typed drift.
abstract final class CkLogChannel {
  const CkLogChannel._();

  /// Realtime transport: subscribe, broadcast, replay, snapshot, poll.
  static const realtime = 'match.rt';

  /// Match-start state machine: phase, role, selections.
  static const matchStart = 'match.start';

  /// Server calls: RPC name, duration, outcome.
  static const rpc = 'match.rpc';

  /// Riverpod provider lifecycle.
  static const providers = 'riverpod';

  /// Client-engine vs server-engine agreement, per delivery.
  ///
  /// The scoring screen computes each delivery locally so the scoreboard can
  /// move without waiting for the network, then compares that prediction to
  /// the server's authoritative answer when it lands. Every delivery is
  /// therefore a parity test, run on real matches.
  ///
  /// A line on this channel is either coverage (`ok`, carrying the rule
  /// categories the delivery exercised) or a genuine divergence (`MISMATCH`)
  /// — the latter is the signal that the two engines have drifted and is the
  /// one thing that must never be ignored.
  static const parity = 'match.parity';
}

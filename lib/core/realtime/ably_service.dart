import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RealtimeConnectionStatus { connected, disconnected }

class RealtimeConnectionNotifier {
  final StreamController<RealtimeConnectionStatus> _controller =
      StreamController<RealtimeConnectionStatus>.broadcast();

  Stream<RealtimeConnectionStatus> get changes => _controller.stream;

  void update(RealtimeConnectionStatus status) {
    if (!_controller.isClosed) _controller.add(status);
  }

  Future<void> dispose() => _controller.close();
}

class ChannelLease<T> {
  ChannelLease(this.channel, this._onRelease);

  final T channel;
  final Future<void> Function() _onRelease;
  bool _released = false;

  Future<void> release() async {
    if (_released) return;
    _released = true;
    await _onRelease();
  }
}

class ReferenceCountedChannelRegistry<T> {
  ReferenceCountedChannelRegistry({
    required this.resolve,
    required this.detach,
  });

  final T Function(String name) resolve;
  final Future<void> Function(T channel) detach;
  final Map<String, ({T channel, int count})> _entries = {};

  ChannelLease<T> acquire(String name) {
    final current = _entries[name];
    final channel = current?.channel ?? resolve(name);
    _entries[name] = (channel: channel, count: (current?.count ?? 0) + 1);
    return ChannelLease<T>(channel, () => release(name));
  }

  int leaseCount(String name) => _entries[name]?.count ?? 0;

  Future<void> release(String name) async {
    final current = _entries[name];
    if (current == null) return;
    if (current.count > 1) {
      _entries[name] = (channel: current.channel, count: current.count - 1);
      return;
    }
    _entries.remove(name);
    await detach(current.channel);
  }

  Future<void> dispose() async {
    final channels = _entries.values.map((entry) => entry.channel).toList();
    _entries.clear();
    for (final channel in channels) {
      await detach(channel);
    }
  }
}

typedef AblyChannelLease = ChannelLease<ably.RealtimeChannel>;

/// Manages the Ably Realtime client connection, channel lifecycles, and
/// authentication via Supabase Edge Functions.
///
/// Implements [WidgetsBindingObserver] to disconnect the WebSocket when
/// backgrounded, preserving slots against the Ably Free tier (200 CCU cap).
class AblyService with WidgetsBindingObserver {
  AblyService(this._supabase) {
    WidgetsBinding.instance.addObserver(this);
  }

  final SupabaseClient _supabase;
  ably.Realtime? _realtime;
  late final ReferenceCountedChannelRegistry<ably.RealtimeChannel> _channels =
      ReferenceCountedChannelRegistry<ably.RealtimeChannel>(
        resolve: (name) => client.channels.get(name),
        detach: (channel) => channel.detach(),
      );
  final RealtimeConnectionNotifier _connectionNotifier =
      RealtimeConnectionNotifier();

  Stream<RealtimeConnectionStatus> get connectionChanges =>
      _connectionNotifier.changes;

  /// Retrieves or initializes the shared [ably.Realtime] instance.
  ably.Realtime get client {
    if (_realtime != null) return _realtime!;

    final clientOptions = ably.ClientOptions(
      clientId: _supabase.auth.currentUser?.id,
      autoConnect: true,
      authCallback: (ably.TokenParams params) async {
        // getSession() returns the current session, automatically refreshing
        // the access token asynchronously if expired, eliminating competing
        // refresh race conditions with Supabase Flutter's lifecycle observer.
        final session = await _supabase.auth.getSession();
        if (session == null) {
          throw Exception(
            '[AblyService] User is not authenticated with Supabase.',
          );
        }

        debugPrint(
          '[AblyService] Requesting Ably token via Edge Function ably-auth...',
        );
        final response = await _supabase.functions.invoke(
          'ably-auth',
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );

        if (response.status != 200 || response.data == null) {
          debugPrint(
            '[AblyService] Token request failed. Status: ${response.status}',
          );
          throw Exception(
            '[AblyService] Failed to obtain token request. Status: ${response.status}',
          );
        }

        final raw = response.data;
        final map =
            raw is Map
                ? Map<String, dynamic>.from(raw)
                : throw Exception(
                  '[AblyService] Malformed token request payload',
                );

        debugPrint('[AblyService] Ably token acquired successfully.');
        return ably.TokenRequest.fromMap(map);
      },
    );

    debugPrint(
      '[AblyService] Initializing Realtime client for user: ${_supabase.auth.currentUser?.id}',
    );
    _realtime = ably.Realtime(options: clientOptions);
    _listenToConnectionChanges(_realtime!);
    return _realtime!;
  }

  AblyChannelLease acquireChannel(String channelName) {
    final lease = _channels.acquire(channelName);
    debugPrint(
      '[AblyService] acquireChannel: $channelName '
      '(leases: ${_channels.leaseCount(channelName)})',
    );
    return lease;
  }

  /// Compatibility API for existing consumers. New code should retain the
  /// returned [AblyChannelLease] from [acquireChannel].
  ably.RealtimeChannel getChannel(String channelName) {
    return acquireChannel(channelName).channel;
  }

  /// Compatibility counterpart to [getChannel]. Releases one channel lease.
  Future<void> releaseChannel(String channelName) async {
    await _channels.release(channelName);
    debugPrint(
      '[AblyService] releaseChannel: $channelName '
      '(leases: ${_channels.leaseCount(channelName)})',
    );
  }

  Timer? _backgroundGraceTimer;
  final List<VoidCallback> _resumeListeners = [];
  final List<void Function(ably.ConnectionStateChange change)>
  _connectionStateListeners = [];
  StreamSubscription<ably.ConnectionStateChange>? _connectionSubscription;

  /// Registers a listener to be notified when the app resumes into foreground.
  void addResumeListener(VoidCallback listener) =>
      _resumeListeners.add(listener);

  /// Unregisters a resume listener.
  void removeResumeListener(VoidCallback listener) =>
      _resumeListeners.remove(listener);

  /// Registers a listener for Ably connection state transitions.
  void addConnectionStateListener(
    void Function(ably.ConnectionStateChange change) listener,
  ) {
    _connectionStateListeners.add(listener);
  }

  /// Unregisters a connection state listener.
  void removeConnectionStateListener(
    void Function(ably.ConnectionStateChange change) listener,
  ) {
    _connectionStateListeners.remove(listener);
  }

  void _listenToConnectionChanges(ably.Realtime client) {
    _connectionSubscription?.cancel();
    _connectionSubscription = client.connection.on().listen((change) {
      debugPrint(
        '[AblyService] Connection state changed: ${change.previous} -> ${change.current}',
      );
      for (final listener in List.of(_connectionStateListeners)) {
        try {
          listener(change);
        } catch (e) {
          debugPrint('[AblyService] Error in connection state listener: $e');
        }
      }
      _connectionNotifier.update(
        change.current == ably.ConnectionState.connected
            ? RealtimeConnectionStatus.connected
            : RealtimeConnectionStatus.disconnected,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Start a 15-second grace period before closing socket.
      // Quick app switching (e.g. 2FA copy, image picker) avoids disconnect/reconnect overhead.
      _backgroundGraceTimer?.cancel();
      _backgroundGraceTimer = Timer(const Duration(seconds: 15), () {
        debugPrint(
          '[AblyService] Grace period expired, closing connection to preserve CCU.',
        );
        _realtime?.connection.close();
      });
    } else if (state == AppLifecycleState.resumed) {
      _backgroundGraceTimer?.cancel();
      _backgroundGraceTimer = null;

      debugPrint(
        '[AblyService] App resumed to foreground, ensuring connection.',
      );
      _realtime?.connection.connect();

      for (final listener in List<VoidCallback>.from(_resumeListeners)) {
        try {
          listener();
        } catch (e) {
          debugPrint('[AblyService] Error in resume listener: $e');
        }
      }
    }
  }

  /// Clean teardown.
  void dispose() {
    _backgroundGraceTimer?.cancel();
    _resumeListeners.clear();
    _connectionSubscription?.cancel();
    _connectionStateListeners.clear();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_channels.dispose());
    unawaited(_connectionNotifier.dispose());
    _realtime?.close();
    _realtime = null;
  }
}

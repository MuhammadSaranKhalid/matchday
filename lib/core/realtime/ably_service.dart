import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Set<String> _activeChannels = {};

  /// Retrieves or initializes the shared [ably.Realtime] instance.
  ably.Realtime get client {
    if (_realtime != null) return _realtime!;

    final clientOptions = ably.ClientOptions(
      clientId: _supabase.auth.currentUser?.id,
      autoConnect: true,
      authCallback: (ably.TokenParams params) async {
        final session = _supabase.auth.currentSession;
        if (session == null) {
          throw Exception('[AblyService] User is not authenticated with Supabase.');
        }

        debugPrint('[AblyService] Requesting Ably token via Edge Function ably-auth...');
        final response = await _supabase.functions.invoke(
          'ably-auth',
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );

        if (response.status != 200 || response.data == null) {
          debugPrint('[AblyService] Token request failed. Status: ${response.status}');
          throw Exception(
            '[AblyService] Failed to obtain token request. Status: ${response.status}',
          );
        }

        final raw = response.data;
        final map = raw is Map
            ? Map<String, dynamic>.from(raw)
            : throw Exception('[AblyService] Malformed token request payload');

        debugPrint('[AblyService] Ably token acquired successfully.');
        return ably.TokenRequest.fromMap(map);
      },
    );

    debugPrint('[AblyService] Initializing Realtime client for user: ${_supabase.auth.currentUser?.id}');
    _realtime = ably.Realtime(options: clientOptions);
    return _realtime!;
  }

  /// Gets or creates a channel reference and registers it in the active set.
  ably.RealtimeChannel getChannel(String channelName) {
    _activeChannels.add(channelName);
    debugPrint('[AblyService] getChannel: $channelName (active channels: ${_activeChannels.length})');
    return client.channels.get(channelName);
  }

  /// Detaches the channel if active to free channel capacity on Ably.
  Future<void> releaseChannel(String channelName) async {
    if (_activeChannels.contains(channelName)) {
      _activeChannels.remove(channelName);
      debugPrint('[AblyService] releaseChannel: $channelName');
      if (_realtime != null) {
        final channel = _realtime!.channels.get(channelName);
        await channel.detach();
      }
    }
  }

  Timer? _backgroundGraceTimer;
  final List<VoidCallback> _resumeListeners = [];

  /// Registers a listener to be notified when the app resumes into foreground.
  void addResumeListener(VoidCallback listener) => _resumeListeners.add(listener);

  /// Unregisters a resume listener.
  void removeResumeListener(VoidCallback listener) => _resumeListeners.remove(listener);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Start a 15-second grace period before closing socket.
      // Quick app switching (e.g. 2FA copy, image picker) avoids disconnect/reconnect overhead.
      _backgroundGraceTimer?.cancel();
      _backgroundGraceTimer = Timer(const Duration(seconds: 15), () {
        debugPrint('[AblyService] Grace period expired, closing connection to preserve CCU.');
        _realtime?.connection.close();
      });
    } else if (state == AppLifecycleState.resumed) {
      _backgroundGraceTimer?.cancel();
      _backgroundGraceTimer = null;

      debugPrint('[AblyService] App resumed to foreground, ensuring connection.');
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
    WidgetsBinding.instance.removeObserver(this);
    _realtime?.close();
    _realtime = null;
    _activeChannels.clear();
  }
}

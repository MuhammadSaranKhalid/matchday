import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Stream of online/offline status.
///
/// `connectivity_plus` returns a list of active interfaces; we collapse
/// that to a single bool — any interface other than `none` counts as
/// online. This is a heuristic; actual reachability is verified by the
/// sync service when it tries to push.
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) async* {
  final connectivity = Connectivity();

  // Seed the stream with the current status so consumers see a value
  // immediately instead of waiting for the first change event.
  final initial = await connectivity.checkConnectivity();
  yield _isOnlineFrom(initial);

  yield* connectivity.onConnectivityChanged.map(_isOnlineFrom);
}

bool _isOnlineFrom(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

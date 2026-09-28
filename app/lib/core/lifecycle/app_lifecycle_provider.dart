import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lifecycle_provider.g.dart';

/// Counts app resumes. Increments every time the app returns to the
/// foreground; the value itself is meaningless.
///
/// It exists so a provider can declare "rebuild me when the user comes back"
/// by watching it:
///
/// ```dart
/// @riverpod
/// Stream<Foo> liveFoo(Ref ref, String id) {
///   ref.watch(appResumeCountProvider);   // re-subscribe on resume
///   return ref.watch(fooRepositoryProvider).watchFoo(id);
/// }
/// ```
///
/// Why rebuild rather than nudge: a WebSocket that was backgrounded is
/// frequently a zombie — it reports connected but delivers nothing, and no
/// amount of polling on top of it helps. Tearing the subscription down and
/// rebuilding it guarantees a live connection and a fresh snapshot in one
/// step. Timers are also unreliable across suspension, so the periodic
/// refresh inside a stream can't be relied on to cover this.
@Riverpod(keepAlive: true)
class AppResumeCount extends _$AppResumeCount {
  @override
  int build() {
    final listener = AppLifecycleListener(onResume: () => state++);
    ref.onDispose(listener.dispose);
    return 0;
  }
}

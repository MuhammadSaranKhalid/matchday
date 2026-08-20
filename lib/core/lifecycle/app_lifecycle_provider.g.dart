// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lifecycle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AppResumeCount)
final appResumeCountProvider = AppResumeCountProvider._();

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
final class AppResumeCountProvider
    extends $NotifierProvider<AppResumeCount, int> {
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
  AppResumeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appResumeCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appResumeCountHash();

  @$internal
  @override
  AppResumeCount create() => AppResumeCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$appResumeCountHash() => r'd833ff3afbce9380f5c1cda1c3d74f0df110f41a';

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

abstract class _$AppResumeCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

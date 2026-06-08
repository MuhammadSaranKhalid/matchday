// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_thread_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams the messages in a chat and exposes the write actions.
///
/// Per the controller-action-returns convention used in matches/, action
/// methods return `Future<Either<Failure, T>>` and the widget folds the
/// result. The state stream itself carries the message list — no submit
/// error slot.
///
/// Family argument is a plain `String chatId` (Riverpod serialises args for
/// the provider key; raw strings stringify cleanly). Internally we wrap in
/// `ChatId(...)` before crossing the repository boundary.
///
/// Autodispose (bare `@riverpod`), matching every other family-based
/// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
/// `authorPosts`, etc.). When the user leaves a thread the subscription
/// drops; on re-entry the cache emits instantly so first paint is unchanged
/// and the realtime channel reconnects in the background.
///
/// Why not `keepAlive`: the previous keepAlive posture made this the only
/// family in the codebase that retained per-key state for the session — a
/// user who opened 40 chats would hold 40 buffered message lists + 40 live
/// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
/// re-entry is cheap; the memory savings are not (#47).

@ProviderFor(MessageThread)
final messageThreadProvider = MessageThreadFamily._();

/// Streams the messages in a chat and exposes the write actions.
///
/// Per the controller-action-returns convention used in matches/, action
/// methods return `Future<Either<Failure, T>>` and the widget folds the
/// result. The state stream itself carries the message list — no submit
/// error slot.
///
/// Family argument is a plain `String chatId` (Riverpod serialises args for
/// the provider key; raw strings stringify cleanly). Internally we wrap in
/// `ChatId(...)` before crossing the repository boundary.
///
/// Autodispose (bare `@riverpod`), matching every other family-based
/// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
/// `authorPosts`, etc.). When the user leaves a thread the subscription
/// drops; on re-entry the cache emits instantly so first paint is unchanged
/// and the realtime channel reconnects in the background.
///
/// Why not `keepAlive`: the previous keepAlive posture made this the only
/// family in the codebase that retained per-key state for the session — a
/// user who opened 40 chats would hold 40 buffered message lists + 40 live
/// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
/// re-entry is cheap; the memory savings are not (#47).
final class MessageThreadProvider
    extends $StreamNotifierProvider<MessageThread, List<Message>> {
  /// Streams the messages in a chat and exposes the write actions.
  ///
  /// Per the controller-action-returns convention used in matches/, action
  /// methods return `Future<Either<Failure, T>>` and the widget folds the
  /// result. The state stream itself carries the message list — no submit
  /// error slot.
  ///
  /// Family argument is a plain `String chatId` (Riverpod serialises args for
  /// the provider key; raw strings stringify cleanly). Internally we wrap in
  /// `ChatId(...)` before crossing the repository boundary.
  ///
  /// Autodispose (bare `@riverpod`), matching every other family-based
  /// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
  /// `authorPosts`, etc.). When the user leaves a thread the subscription
  /// drops; on re-entry the cache emits instantly so first paint is unchanged
  /// and the realtime channel reconnects in the background.
  ///
  /// Why not `keepAlive`: the previous keepAlive posture made this the only
  /// family in the codebase that retained per-key state for the session — a
  /// user who opened 40 chats would hold 40 buffered message lists + 40 live
  /// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
  /// re-entry is cheap; the memory savings are not (#47).
  MessageThreadProvider._({
    required MessageThreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageThreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageThreadHash();

  @override
  String toString() {
    return r'messageThreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MessageThread create() => MessageThread();

  @override
  bool operator ==(Object other) {
    return other is MessageThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageThreadHash() => r'd57d1145c0cfb6ec022f90b34b77dae11a16b7ca';

/// Streams the messages in a chat and exposes the write actions.
///
/// Per the controller-action-returns convention used in matches/, action
/// methods return `Future<Either<Failure, T>>` and the widget folds the
/// result. The state stream itself carries the message list — no submit
/// error slot.
///
/// Family argument is a plain `String chatId` (Riverpod serialises args for
/// the provider key; raw strings stringify cleanly). Internally we wrap in
/// `ChatId(...)` before crossing the repository boundary.
///
/// Autodispose (bare `@riverpod`), matching every other family-based
/// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
/// `authorPosts`, etc.). When the user leaves a thread the subscription
/// drops; on re-entry the cache emits instantly so first paint is unchanged
/// and the realtime channel reconnects in the background.
///
/// Why not `keepAlive`: the previous keepAlive posture made this the only
/// family in the codebase that retained per-key state for the session — a
/// user who opened 40 chats would hold 40 buffered message lists + 40 live
/// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
/// re-entry is cheap; the memory savings are not (#47).

final class MessageThreadFamily extends $Family
    with
        $ClassFamilyOverride<
          MessageThread,
          AsyncValue<List<Message>>,
          List<Message>,
          Stream<List<Message>>,
          String
        > {
  MessageThreadFamily._()
    : super(
        retry: null,
        name: r'messageThreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Streams the messages in a chat and exposes the write actions.
  ///
  /// Per the controller-action-returns convention used in matches/, action
  /// methods return `Future<Either<Failure, T>>` and the widget folds the
  /// result. The state stream itself carries the message list — no submit
  /// error slot.
  ///
  /// Family argument is a plain `String chatId` (Riverpod serialises args for
  /// the provider key; raw strings stringify cleanly). Internally we wrap in
  /// `ChatId(...)` before crossing the repository boundary.
  ///
  /// Autodispose (bare `@riverpod`), matching every other family-based
  /// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
  /// `authorPosts`, etc.). When the user leaves a thread the subscription
  /// drops; on re-entry the cache emits instantly so first paint is unchanged
  /// and the realtime channel reconnects in the background.
  ///
  /// Why not `keepAlive`: the previous keepAlive posture made this the only
  /// family in the codebase that retained per-key state for the session — a
  /// user who opened 40 chats would hold 40 buffered message lists + 40 live
  /// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
  /// re-entry is cheap; the memory savings are not (#47).

  MessageThreadProvider call(String chatId) =>
      MessageThreadProvider._(argument: chatId, from: this);

  @override
  String toString() => r'messageThreadProvider';
}

/// Streams the messages in a chat and exposes the write actions.
///
/// Per the controller-action-returns convention used in matches/, action
/// methods return `Future<Either<Failure, T>>` and the widget folds the
/// result. The state stream itself carries the message list — no submit
/// error slot.
///
/// Family argument is a plain `String chatId` (Riverpod serialises args for
/// the provider key; raw strings stringify cleanly). Internally we wrap in
/// `ChatId(...)` before crossing the repository boundary.
///
/// Autodispose (bare `@riverpod`), matching every other family-based
/// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
/// `authorPosts`, etc.). When the user leaves a thread the subscription
/// drops; on re-entry the cache emits instantly so first paint is unchanged
/// and the realtime channel reconnects in the background.
///
/// Why not `keepAlive`: the previous keepAlive posture made this the only
/// family in the codebase that retained per-key state for the session — a
/// user who opened 40 chats would hold 40 buffered message lists + 40 live
/// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
/// re-entry is cheap; the memory savings are not (#47).

abstract class _$MessageThread extends $StreamNotifier<List<Message>> {
  late final _$args = ref.$arg as String;
  String get chatId => _$args;

  Stream<List<Message>> build(String chatId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Message>>, List<Message>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Message>>, List<Message>>,
              AsyncValue<List<Message>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

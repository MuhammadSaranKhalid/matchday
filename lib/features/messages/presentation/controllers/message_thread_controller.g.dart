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
/// `keepAlive: true`: backgrounding the app (or briefly removing the thread
/// widget from the tree during a navigation) shouldn't drop the broadcast
/// subscription. The family auto-disposes per chatId when no listener is
/// ever attached for that id, so memory stays bounded — only chats the user
/// actually opens hold a subscription, and they hold it for the session.

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
/// `keepAlive: true`: backgrounding the app (or briefly removing the thread
/// widget from the tree during a navigation) shouldn't drop the broadcast
/// subscription. The family auto-disposes per chatId when no listener is
/// ever attached for that id, so memory stays bounded — only chats the user
/// actually opens hold a subscription, and they hold it for the session.
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
  /// `keepAlive: true`: backgrounding the app (or briefly removing the thread
  /// widget from the tree during a navigation) shouldn't drop the broadcast
  /// subscription. The family auto-disposes per chatId when no listener is
  /// ever attached for that id, so memory stays bounded — only chats the user
  /// actually opens hold a subscription, and they hold it for the session.
  MessageThreadProvider._({
    required MessageThreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageThreadProvider',
         isAutoDispose: false,
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

String _$messageThreadHash() => r'd44f8e072d629fd2560aa63e5fd5482aed0ea4e3';

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
/// `keepAlive: true`: backgrounding the app (or briefly removing the thread
/// widget from the tree during a navigation) shouldn't drop the broadcast
/// subscription. The family auto-disposes per chatId when no listener is
/// ever attached for that id, so memory stays bounded — only chats the user
/// actually opens hold a subscription, and they hold it for the session.

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
        isAutoDispose: false,
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
  /// `keepAlive: true`: backgrounding the app (or briefly removing the thread
  /// widget from the tree during a navigation) shouldn't drop the broadcast
  /// subscription. The family auto-disposes per chatId when no listener is
  /// ever attached for that id, so memory stays bounded — only chats the user
  /// actually opens hold a subscription, and they hold it for the session.

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
/// `keepAlive: true`: backgrounding the app (or briefly removing the thread
/// widget from the tree during a navigation) shouldn't drop the broadcast
/// subscription. The family auto-disposes per chatId when no listener is
/// ever attached for that id, so memory stays bounded — only chats the user
/// actually opens hold a subscription, and they hold it for the session.

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

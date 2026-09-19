// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_thread_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Thread controller over the universal ChatRepository.

@ProviderFor(MessageThread)
final messageThreadProvider = MessageThreadFamily._();

/// Thread controller over the universal ChatRepository.
final class MessageThreadProvider
    extends $StreamNotifierProvider<MessageThread, List<ChatMessage>> {
  /// Thread controller over the universal ChatRepository.
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

String _$messageThreadHash() => r'e3e36b1cbee045151d82ec2b2123b23b791193ed';

/// Thread controller over the universal ChatRepository.

final class MessageThreadFamily extends $Family
    with
        $ClassFamilyOverride<
          MessageThread,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>,
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

  /// Thread controller over the universal ChatRepository.

  MessageThreadProvider call(String chatId) =>
      MessageThreadProvider._(argument: chatId, from: this);

  @override
  String toString() => r'messageThreadProvider';
}

/// Thread controller over the universal ChatRepository.

abstract class _$MessageThread extends $StreamNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get chatId => _$args;

  Stream<List<ChatMessage>> build(String chatId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

import 'package:equatable/equatable.dart';

enum ChatSyncPhase {
  unhydrated,
  syncing,
  ready,
  failed,
}

class ChatSyncState extends Equatable {
  const ChatSyncState({
    required this.channelId,
    required this.phase,
    this.lastError,
    this.hasMoreHistory = true,
    this.newestSyncedMessageSeq,
    this.oldestCachedMessageSeq,
  });

  final String channelId;
  final ChatSyncPhase phase;
  final String? lastError;
  final bool hasMoreHistory;
  final int? newestSyncedMessageSeq;
  final int? oldestCachedMessageSeq;

  bool get isInitialLoading =>
      phase == ChatSyncPhase.unhydrated || phase == ChatSyncPhase.syncing;

  @override
  List<Object?> get props => [
        channelId,
        phase,
        lastError,
        hasMoreHistory,
        newestSyncedMessageSeq,
        oldestCachedMessageSeq,
      ];
}

import '../../domain/entities/chat_message.dart';

/// Counts only server-sequenced incoming messages newer than the previous
/// highest sequence. Prepending older history therefore never increments the
/// "new messages" pill.
int countNewIncomingMessages({
  required List<ChatMessage> previous,
  required List<ChatMessage> current,
}) {
  if (previous.isEmpty) return 0;

  var previousHighest = 0;
  for (final message in previous) {
    final seq = message.messageSeq;
    if (seq != null && seq > previousHighest) previousHighest = seq;
  }

  return current.where((message) {
    final seq = message.messageSeq;
    return !message.fromMe && seq != null && seq > previousHighest;
  }).length;
}

/// Finds the first incoming message beyond the durable read horizon. Because
/// it is sequence-based, loading older history does not move the divider.
int firstUnreadMessageIndex({
  required List<ChatMessage> messages,
  required int? lastReadMessageSeq,
}) {
  final horizon = lastReadMessageSeq ?? 0;
  return messages.indexWhere(
    (message) =>
        !message.fromMe &&
        message.messageSeq != null &&
        message.messageSeq! > horizon,
  );
}

bool startsNewSenderCluster({
  ChatMessage? previous,
  required ChatMessage current,
  Duration maxGap = const Duration(minutes: 5),
}) {
  if (previous == null) return true;
  if (previous.senderId != current.senderId) return true;

  final a = previous.createdAt.toLocal();
  final b = current.createdAt.toLocal();
  final differentDay =
      a.year != b.year || a.month != b.month || a.day != b.day;
  if (differentDay) return true;

  return current.createdAt.difference(previous.createdAt).abs() > maxGap;
}

bool isDifferentCalendarDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year != right.year ||
      left.month != right.month ||
      left.day != right.day;
}

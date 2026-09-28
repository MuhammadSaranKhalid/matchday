import 'package:equatable/equatable.dart';

class ChatDraft extends Equatable {
  const ChatDraft({
    required this.body,
    this.replyToMessageId,
  });

  final String body;
  final String? replyToMessageId;

  bool get isEmpty => body.trim().isEmpty && replyToMessageId == null;

  @override
  List<Object?> get props => [body, replyToMessageId];
}

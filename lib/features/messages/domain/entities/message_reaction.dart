import 'package:equatable/equatable.dart';

class MessageReaction extends Equatable {
  const MessageReaction({
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
    this.isRemoved = false,
  });

  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;
  final bool isRemoved;

  @override
  List<Object?> get props => [messageId, userId, reaction, createdAt, isRemoved];
}

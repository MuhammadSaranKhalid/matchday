import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:matchday/features/messages/domain/entities/chat.dart';
import 'package:matchday/features/messages/domain/repositories/chat_repository.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository chatRepo;
  late MessagesRepositoryImpl repo;

  setUp(() {
    chatRepo = _MockChatRepository();
    repo = MessagesRepositoryImpl(chatRepo);
  });

  group('MessagesRepositoryImpl - DM Message Requests', () {
    const testChatId = ChatId('chat-123');

    test('acceptDmRequest calls chatRepo and returns unit on success', () async {
      when(() => chatRepo.acceptDirectRequest(testChatId.value))
          .thenAnswer((_) async => const Right(unit));

      final result = await repo.acceptDmRequest(testChatId);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => chatRepo.acceptDirectRequest(testChatId.value)).called(1);
    });

    test('acceptDmRequest maps ServerFailure from chatRepo', () async {
      when(() => chatRepo.acceptDirectRequest(testChatId.value))
          .thenAnswer((_) async => const Left(ServerFailure('Failed to accept')));

      final result = await repo.acceptDmRequest(testChatId);

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('declineDmRequest calls chatRepo and returns unit on success', () async {
      when(() => chatRepo.declineDirectRequest(testChatId.value))
          .thenAnswer((_) async => const Right(unit));

      final result = await repo.declineDmRequest(testChatId);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => chatRepo.declineDirectRequest(testChatId.value)).called(1);
    });

    test('declineDmRequest maps AuthFailure from chatRepo', () async {
      when(() => chatRepo.declineDirectRequest(testChatId.value))
          .thenAnswer((_) async => const Left(AuthFailure('Not authenticated')));

      final result = await repo.declineDmRequest(testChatId);

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    });
  });

  group('Chat entity request classification getters', () {
    test('isRequest is true for incoming unaccepted DM where I do not follow them', () {
      final chat = Chat(
        id: const ChatId('c1'),
        kind: ChatKind.dm,
        name: 'Adeel',
        teamId: null,
        unreadCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAccepted: false,
        lastMessageFromMe: false,
        youFollow: false,
        theyFollowYou: false,
      );

      expect(chat.isRequest, isTrue);
      expect(chat.isPendingOutgoingRequest, isFalse);
    });

    test('isRequest is false when I follow them (mutual or one-way following)', () {
      final chat = Chat(
        id: const ChatId('c2'),
        kind: ChatKind.dm,
        name: 'Adeel',
        teamId: null,
        unreadCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAccepted: false,
        lastMessageFromMe: false,
        youFollow: true,
        theyFollowYou: false,
      );

      expect(chat.isRequest, isFalse);
      expect(chat.isPendingOutgoingRequest, isFalse);
    });

    test('isPendingOutgoingRequest is true for my outgoing unaccepted DM when they do not follow me', () {
      final chat = Chat(
        id: const ChatId('c3'),
        kind: ChatKind.dm,
        name: 'Adeel',
        teamId: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAccepted: false,
        lastMessageFromMe: true,
        youFollow: false,
        theyFollowYou: false,
      );

      expect(chat.isRequest, isFalse);
      expect(chat.isPendingOutgoingRequest, isTrue);
    });

    test('isRequest and isPendingOutgoingRequest are false for already accepted chats', () {
      final chat = Chat(
        id: const ChatId('c4'),
        kind: ChatKind.dm,
        name: 'Adeel',
        teamId: null,
        unreadCount: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAccepted: true,
        lastMessageFromMe: false,
        youFollow: false,
        theyFollowYou: false,
      );

      expect(chat.isRequest, isFalse);
      expect(chat.isPendingOutgoingRequest, isFalse);
    });

    test('team and match chats are never requests', () {
      final teamChat = Chat(
        id: const ChatId('c5'),
        kind: ChatKind.team,
        name: 'Lahore Qalandars',
        teamId: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAccepted: false,
      );

      final matchChat = Chat(
        id: const ChatId('c6'),
        kind: ChatKind.match,
        name: 'Match Chat',
        teamId: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAccepted: false,
      );

      expect(teamChat.isRequest, isFalse);
      expect(teamChat.isPendingOutgoingRequest, isFalse);
      expect(matchChat.isRequest, isFalse);
      expect(matchChat.isPendingOutgoingRequest, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/messages/data/datasources/messages_local_datasource.dart';
import 'package:matchday/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:matchday/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:matchday/features/messages/domain/entities/chat.dart';

class _MockRemote extends Mock implements MessagesRemoteDataSource {}
class _MockLocal extends Mock implements MessagesLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late MessagesRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repo = MessagesRepositoryImpl(remote, local);
  });

  group('MessagesRepositoryImpl - DM Message Requests', () {
    const testChatId = ChatId('chat-123');

    test('acceptDmRequest calls remote and returns unit on success', () async {
      when(() => remote.acceptDmRequest(testChatId.value))
          .thenAnswer((_) async {});

      final result = await repo.acceptDmRequest(testChatId);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => remote.acceptDmRequest(testChatId.value)).called(1);
    });

    test('acceptDmRequest maps ServerException to ServerFailure', () async {
      when(() => remote.acceptDmRequest(testChatId.value))
          .thenThrow(ServerException('Failed to accept'));

      final result = await repo.acceptDmRequest(testChatId);

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('declineDmRequest calls remote and returns unit on success', () async {
      when(() => remote.declineDmRequest(testChatId.value))
          .thenAnswer((_) async {});

      final result = await repo.declineDmRequest(testChatId);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => remote.declineDmRequest(testChatId.value)).called(1);
    });

    test('declineDmRequest maps UnauthorizedException to AuthFailure', () async {
      when(() => remote.declineDmRequest(testChatId.value))
          .thenThrow(UnauthorizedException('Not authenticated'));

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
    });

    test('isPendingOutgoingRequest is true when I sent the request and they do not follow me', () {
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
  });
}

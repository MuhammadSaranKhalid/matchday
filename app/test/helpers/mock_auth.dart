import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}
class MockGoTrueClient extends Mock implements sb.GoTrueClient {}

sb.User createMockSupabaseUser({
  String id = 'user-1',
  String? email = 'test@example.com',
  Map<String, dynamic>? userMetadata,
}) {
  return sb.User(
    id: id,
    appMetadata: const {},
    userMetadata: userMetadata ?? const {},
    aud: 'authenticated',
    createdAt: DateTime(2026, 1, 1).toIso8601String(),
    email: email,
  );
}

sb.Session createMockSession({
  String id = 'user-1',
  String? email = 'test@example.com',
}) {
  final user = createMockSupabaseUser(id: id, email: email);
  return sb.Session(
    accessToken: 'mock-access-token',
    tokenType: 'bearer',
    user: user,
  );
}

sb.AuthState createMockAuthState({
  String id = 'user-1',
  String? email = 'test@example.com',
  sb.AuthChangeEvent event = sb.AuthChangeEvent.signedIn,
}) {
  final session = createMockSession(id: id, email: email);
  return sb.AuthState(event, session);
}

MockSupabaseClient createMockSupabaseClient({
  String id = 'user-1',
  String? email = 'test@example.com',
}) {
  final client = MockSupabaseClient();
  final auth = MockGoTrueClient();
  final user = createMockSupabaseUser(id: id, email: email);
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(user);
  return client;
}

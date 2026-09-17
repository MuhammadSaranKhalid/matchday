import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../supabase/supabase_client_provider.dart';
import 'ably_service.dart';

part 'ably_provider.g.dart';

/// Provides the singleton [AblyService] across the application.
@Riverpod(keepAlive: true)
AblyService ablyService(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final service = AblyService(supabase);

  ref.onDispose(service.dispose);
  return service;
}

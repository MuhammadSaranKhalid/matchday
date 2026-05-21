import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// Riverpod wrapper around the singleton Supabase client.
///
/// `Supabase.initialize(...)` is called once from main() before runApp.
/// All data sources read the client through this provider so they're
/// trivially overridable in tests.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

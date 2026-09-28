import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'notifications_remote_datasource.dart';

part 'notifications_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRemoteDataSource notificationsRemoteDataSource(Ref ref) =>
    NotificationsRemoteDataSource(ref.watch(supabaseClientProvider));

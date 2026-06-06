import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import 'messages_remote_datasource.dart';

part 'messages_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
MessagesRemoteDataSource messagesRemoteDataSource(Ref ref) =>
    MessagesRemoteDataSource(ref.watch(supabaseClientProvider));

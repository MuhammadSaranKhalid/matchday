import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'onboarding_remote_datasource.dart';

part 'onboarding_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
OnboardingRemoteDataSource onboardingRemoteDataSource(Ref ref) =>
    OnboardingRemoteDataSource(ref.watch(supabaseClientProvider));

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_providers.dart';
import '../widgets/profile_view.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByUsernameProvider(username));

    return profileAsync.when(
      data: (profile) => profile != null
          ? ProfileView(
              isSelf: false,
              profile: profile,
            )
          : const ProfileNotFoundView(),
      loading: () => const ProfileLoadingView(
        isSelf: false,
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error loading profile:\n$err'),
        ),
      ),
    );
  }
}

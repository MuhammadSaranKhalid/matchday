import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_view.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return switch (profileAsync) {
      AsyncData(:final value) => value != null
          ? ProfileView(profile: value)
          : const ProfileNotFoundView(),
      AsyncError(:final error) => Scaffold(
          backgroundColor: CkColors.paper,
          body: Center(
            child: Text("Couldn't load profile: $error", style: const TextStyle(color: CkColors.muted)),
          ),
        ),
      _ => const ProfileLoadingView(),
    };
  }
}

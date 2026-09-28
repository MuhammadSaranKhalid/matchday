// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
///
/// Authenticated users land in the four-tab shell (Home · Explore · Matches ·
/// Pool — N5 in docs/navigation-ia-design.md) via a
/// [StatefulShellRoute] so each tab keeps its own navigation stack. Own
/// profile is a root-level route reached from the drawer masthead.
/// The onboarding gate (signed-in but profile incomplete → /onboarding) is
/// added in Feature 2 alongside the `profiles` table.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
///
/// Authenticated users land in the four-tab shell (Home · Explore · Matches ·
/// Pool — N5 in docs/navigation-ia-design.md) via a
/// [StatefulShellRoute] so each tab keeps its own navigation stack. Own
/// profile is a root-level route reached from the drawer masthead.
/// The onboarding gate (signed-in but profile incomplete → /onboarding) is
/// added in Feature 2 alongside the `profiles` table.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Auth-aware router.
  ///
  /// The redirect callback reads the current-user stream's latest value.
  /// When it flips (sign in / sign out), the router re-evaluates and moves
  /// the user accordingly.
  ///
  /// Authenticated users land in the four-tab shell (Home · Explore · Matches ·
  /// Pool — N5 in docs/navigation-ia-design.md) via a
  /// [StatefulShellRoute] so each tab keeps its own navigation stack. Own
  /// profile is a root-level route reached from the drawer masthead.
  /// The onboarding gate (signed-in but profile incomplete → /onboarding) is
  /// added in Feature 2 alongside the `profiles` table.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'5385953c1b738b19437eb6ad6e62453050b04af6';

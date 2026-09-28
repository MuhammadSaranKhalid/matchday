// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_creation_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamCreationDraft)
final teamCreationDraftProvider = TeamCreationDraftProvider._();

final class TeamCreationDraftProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  TeamCreationDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamCreationDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamCreationDraftHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    return teamCreationDraft(ref);
  }
}

String _$teamCreationDraftHash() => r'9d1b577341decd9abe2b7a188e72cfd54ab580d4';

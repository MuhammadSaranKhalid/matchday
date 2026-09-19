import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../controllers/team_create_controller.dart';

part 'team_creation_draft_provider.g.dart';

/// Locally persisted create-team draft.
///
/// This provider belongs in presentation/providers, not inside a widget.
@riverpod
Stream<Map<String, dynamic>?> teamCreationDraft(Ref ref) =>
    ref.watch(wizardDraftStoreProvider).watch(TeamCreateController.draftKey);

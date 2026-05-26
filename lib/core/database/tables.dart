import 'package:drift/drift.dart';

/// Local-only persistence for in-progress multi-step wizards (onboarding,
/// team-create, match-setup). Lets a user resume a half-filled flow after
/// killing the app. Keyed by a caller-defined string (e.g.
/// `onboarding:<userId>`); [payload] is the wizard's JSON-encoded draft.
///
/// This is the only drift table in the app. The product is online-only, so
/// no other domain data is mirrored locally. Wizard drafts are transient
/// presentation state, not domain data — they carry no `user_id`/`updated_at`
/// LWW columns and are cleared on sign-out.
@DataClassName('WizardDraftRow')
class WizardDrafts extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

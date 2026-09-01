import 'package:meta/meta.dart';

import 'tournament.dart';
import 'tournament_registration.dart';

/// A tournament plus the registration that puts you in it.
///
/// The hub's "Playing" bucket needs both: the cup for the card's identity, and
/// the registration for the payload the canvas shows — which team you are
/// playing as, whether the squad is confirmed, and whether the fee is settled.
@immutable
class MyTournamentEntry {
  const MyTournamentEntry({
    required this.tournament,
    required this.registration,
  });

  final Tournament tournament;
  final TournamentRegistration registration;

  bool get isAwaitingApproval => registration.isPending;

  bool get isPast =>
      tournament.status == TournamentStatus.completed ||
      tournament.status == TournamentStatus.cancelled ||
      tournament.status == TournamentStatus.abandoned;

  bool get isCurrent => registration.isApproved && !isPast;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyTournamentEntry &&
          other.registration.registrationId == registration.registrationId;

  @override
  int get hashCode => registration.registrationId.hashCode;
}

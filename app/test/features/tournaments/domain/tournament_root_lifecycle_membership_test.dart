import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/data/models/tournament_dto.dart';
import 'package:matchday/features/tournaments/data/models/tournament_membership_dto.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_membership.dart';

void main() {
  group('Phase 2 — Tournament Root Authority vs Historical Provenance', () {
    test(
      '1. created_by represents historical provenance; ownerUserId represents current authority',
      () {
        final tournament = Tournament(
          id: 't-100',
          name: 'Super Cup 2026',
          type: TournamentType.knockout,
          status: TournamentStatus.draft,
          privacy: TournamentPrivacy.public,
          createdBy: 'user-original-creator',
          ownerUserId: 'user-current-owner',
          venues: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        // Provenance remains frozen
        expect(tournament.createdBy, equals('user-original-creator'));
        // Current authority is held by the new owner
        expect(tournament.ownerUserId, equals('user-current-owner'));
        expect(tournament.effectiveOwnerUserId, equals('user-current-owner'));
        // Distinct concepts
        expect(tournament.createdBy, isNot(equals(tournament.ownerUserId)));
      },
    );

    test(
      '2. TournamentDto decodes owner_user_id and falls back gracefully to created_by',
      () {
        final jsonWithNewOwner = {
          'tournament_id': 't-101',
          'tournament_name': 'Premier League',
          'status': 'draft',
          'privacy': 'public',
          'created_by': 'user-creator',
          'owner_user_id': 'user-owner',
          'revision': 2,
          'entry_revision': 3,
          'organizers': ['user-creator'],
          'venues': <dynamic>[],
        };

        final dto = TournamentDto.fromJson(jsonWithNewOwner);
        expect(dto.ownerUserId, equals('user-owner'));
        expect(dto.createdBy, equals('user-creator'));
        expect(dto.revision, equals(2));
        expect(dto.entryRevision, equals(3));

        final entity = dto.toEntity();
        expect(entity.ownerUserId, equals('user-owner'));
        expect(entity.createdBy, equals('user-creator'));
        expect(entity.revision, equals(2));
        expect(entity.entryRevision, equals(3));

        // Legacy fallback when owner_user_id is not yet in json
        final jsonLegacy = {
          'tournament_id': 't-102',
          'tournament_name': 'Old League',
          'status': 'draft',
          'privacy': 'public',
          'created_by': 'user-old-creator',
          'entry_revision': 1,
          'organizers': ['user-old-creator'],
          'venues': <dynamic>[],
        };

        final legacyDto = TournamentDto.fromJson(jsonLegacy);
        expect(legacyDto.ownerUserId, equals('user-old-creator'));
        expect(
          legacyDto.toEntity().effectiveOwnerUserId,
          equals('user-old-creator'),
        );
      },
    );
  });

  group('Phase 2 — Orthogonal Tournament Lifecycle & Status Projection', () {
    test(
      '3. Draft status projection: publication = draft always yields status = draft',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.draft,
          registrationState: TournamentRegistrationState.notOpen,
          entryState: TournamentEntryState.editable,
          competitionState: TournamentCompetitionState.notStarted,
          terminationState: TournamentTerminationState.none,
        );
        expect(status, equals(TournamentStatus.draft));
      },
    );

    test(
      '4. Registration status projection: published + registration open yields status = registration',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.open,
          entryState: TournamentEntryState.editable,
          competitionState: TournamentCompetitionState.notStarted,
          terminationState: TournamentTerminationState.none,
        );
        expect(status, equals(TournamentStatus.registration));
      },
    );

    test(
      '5. Upcoming status projection: published + registration closed + competition not started',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.closed,
          entryState: TournamentEntryState.locked,
          competitionState: TournamentCompetitionState.notStarted,
          terminationState: TournamentTerminationState.none,
        );
        expect(status, equals(TournamentStatus.upcoming));
      },
    );

    test(
      '6. Live status projection: published + competition inProgress yields status = live',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.closed,
          entryState: TournamentEntryState.locked,
          competitionState: TournamentCompetitionState.inProgress,
          terminationState: TournamentTerminationState.none,
        );
        expect(status, equals(TournamentStatus.live));
      },
    );

    test(
      '7. Completed status projection: published + competition completed yields status = completed',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.closed,
          entryState: TournamentEntryState.locked,
          competitionState: TournamentCompetitionState.completed,
          terminationState: TournamentTerminationState.none,
        );
        expect(status, equals(TournamentStatus.completed));
      },
    );

    test(
      '8. Termination precedence: cancelled overrides ordinary display status',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.open,
          entryState: TournamentEntryState.editable,
          competitionState: TournamentCompetitionState.notStarted,
          terminationState: TournamentTerminationState.cancelled,
        );
        expect(status, equals(TournamentStatus.cancelled));
      },
    );

    test(
      '9. Termination precedence: abandoned overrides ordinary live competition status',
      () {
        final status = Tournament.derivePublicStatus(
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.closed,
          entryState: TournamentEntryState.locked,
          competitionState: TournamentCompetitionState.inProgress,
          terminationState: TournamentTerminationState.abandoned,
        );
        expect(status, equals(TournamentStatus.abandoned));
      },
    );

    test(
      '10. Tournament entity projectedPublicStatus property matches derivePublicStatus',
      () {
        final tournament = Tournament(
          id: 't-200',
          name: 'Champions Cup',
          type: TournamentType.roundRobin,
          status: TournamentStatus.upcoming, // legacy compatibility field
          privacy: TournamentPrivacy.public,
          publicationState: TournamentPublicationState.published,
          registrationState: TournamentRegistrationState.closed,
          entryState: TournamentEntryState.locked,
          competitionState: TournamentCompetitionState.inProgress,
          terminationState: TournamentTerminationState.none,
          venues: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        // The orthogonal fields project live, overriding stale legacy status
        expect(tournament.projectedPublicStatus, equals(TournamentStatus.live));
      },
    );
  });

  group('Phase 2 — Tournament Memberships & Delegation Model', () {
    test(
      '11. TournamentMembership domain entity encapsulates delegated staff state and lifecycle',
      () {
        final membership = TournamentMembership(
          id: 'mem-1',
          tournamentId: 't-100',
          userId: 'user-manager-1',
          roleKey: 'manager',
          status: TournamentMembershipStatus.active,
          appointedBy: 'user-owner',
          appointedAt: DateTime(2026, 2, 1),
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 1),
        );

        expect(membership.isActive, isTrue);
        expect(membership.isManager, isTrue);
        expect(membership.isOwner, isFalse);
      },
    );

    test(
      '12. TournamentMembershipDto round-trip preserves identity, audit, and removal history',
      () {
        final now = DateTime.now();
        final dto = TournamentMembershipDto(
          membershipId: 'mem-2',
          tournamentId: 't-100',
          userId: 'user-manager-2',
          roleKey: 'manager',
          status: 'removed',
          appointedBy: 'user-owner',
          appointedAt: now.subtract(const Duration(days: 30)).toIso8601String(),
          removedBy: 'user-owner',
          removedAt: now.toIso8601String(),
          createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
          updatedAt: now.toIso8601String(),
        );

        final entity = dto.toEntity();
        expect(entity.id, equals('mem-2'));
        expect(entity.status, equals(TournamentMembershipStatus.removed));
        expect(entity.isActive, isFalse);
        expect(entity.removedBy, equals('user-owner'));
        expect(entity.removedAt, isNotNull);

        final backToJson = dto.toJson();
        expect(backToJson['status'], equals('removed'));
        expect(backToJson['removed_by'], equals('user-owner'));
      },
    );
  });

  group('Phase 2 — Capability Model & Scope Isolation Invariants', () {
    // Canonical Capability Catalogue for Tournaments
    const allTournamentCapabilities = <String>[
      'tournament.profile.edit',
      'tournament.settings.edit',
      'tournament.publish',
      'tournament.registration.manage',
      'tournament.registration.review',
      'tournament.entries.manage',
      'tournament.entries.lock',
      'tournament.structure.manage',
      'tournament.draw.manage',
      'tournament.draw.publish',
      'tournament.fixture.schedule',
      'tournament.fixture.reschedule',
      'tournament.match.setup',
      'tournament.match.score',
      'tournament.official.assign',
      'tournament.result.override',
      'tournament.announcement.send',
      'tournament.awards.manage',
      'tournament.cancel',
      'tournament.abandon',
      'tournament.staff.manage',
      'tournament.ownership.transfer',
    ];

    const ownerOnlyCapabilities = <String>[
      'tournament.cancel',
      'tournament.abandon',
      'tournament.staff.manage',
      'tournament.ownership.transfer',
    ];

    test(
      '13. Canonical tournament capability set contains exactly 22 defined permissions',
      () {
        expect(allTournamentCapabilities.length, equals(22));
        for (final cap in allTournamentCapabilities) {
          expect(cap, startsWith('tournament.'));
        }
      },
    );

    test(
      '14. Manager default bundle excludes Owner-only governance capabilities',
      () {
        final managerCapabilities =
            allTournamentCapabilities
                .where((cap) => !ownerOnlyCapabilities.contains(cap))
                .toList();

        expect(managerCapabilities.length, equals(18));
        expect(
          managerCapabilities,
          isNot(contains('tournament.ownership.transfer')),
        );
        expect(managerCapabilities, isNot(contains('tournament.staff.manage')));
        expect(managerCapabilities, isNot(contains('tournament.cancel')));
        expect(managerCapabilities, isNot(contains('tournament.abandon')));

        // Operational capabilities are included
        expect(managerCapabilities, contains('tournament.profile.edit'));
        expect(managerCapabilities, contains('tournament.fixture.reschedule'));
        expect(managerCapabilities, contains('tournament.match.setup'));
        expect(managerCapabilities, contains('tournament.match.score'));
        expect(managerCapabilities, contains('tournament.result.override'));
      },
    );

    test(
      '15. Scope isolation invariant: Team roles do not grant Tournament administration',
      () {
        // Invariant: Team capability keys live in team scope
        const teamPermissions = <String>[
          'team.roster.write',
          'team.staff.appoint',
          'team.tournament.enter',
        ];

        for (final perm in teamPermissions) {
          expect(allTournamentCapabilities, isNot(contains(perm)));
        }

        // Conversely, no tournament management capability leaks to team scope
        for (final perm in allTournamentCapabilities) {
          expect(perm, startsWith('tournament.'));
          expect(teamPermissions, isNot(contains(perm)));
        }
      },
    );

    test(
      '16. Authority invariant: isOrganizedBy recognizes ownerUserId and organizers array, NOT past creator after ownership transfer',
      () {
        final tournament = Tournament(
          id: 't-300',
          name: 'Transitional Cup',
          type: TournamentType.knockout,
          status: TournamentStatus.draft,
          privacy: TournamentPrivacy.public,
          ownerUserId: 'user-canonical-owner',
          createdBy: 'user-historical-creator',
          venues: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        // Canonical owner has organizer access
        expect(tournament.isOrganizedBy('user-canonical-owner'), isTrue);
        // Historical creator receives NO organizer authority after ownership has transferred
        expect(tournament.isOrganizedBy('user-historical-creator'), isFalse);
        // Historical provenance is preserved via dedicated helper
        expect(tournament.wasCreatedBy('user-historical-creator'), isTrue);
        expect(tournament.wasCreatedBy('user-canonical-owner'), isFalse);
        // Unrelated user is rejected
        expect(tournament.isOrganizedBy('user-stranger'), isFalse);
      },
    );

    test(
      '17. Ownership transfer invariant: User A creates, ownership transfers to User B -> A has no authority, B has authority',
      () {
        // 1. User A creates tournament
        final initialTournament = Tournament(
          id: 't-301',
          name: 'Ownership Transfer Test',
          type: TournamentType.knockout,
          status: TournamentStatus.draft,
          privacy: TournamentPrivacy.public,
          createdBy: 'user-a',
          ownerUserId: 'user-a',
          venues: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(initialTournament.isOrganizedBy('user-a'), isTrue);
        expect(initialTournament.isOrganizedBy('user-b'), isFalse);

        // 2. Ownership transfers to User B
        final transferredTournament = Tournament(
          id: initialTournament.id,
          name: initialTournament.name,
          type: initialTournament.type,
          status: initialTournament.status,
          privacy: initialTournament.privacy,
          createdBy:
              initialTournament
                  .createdBy, // createdBy remains user-a (immutable provenance)
          ownerUserId: 'user-b', // transferred ownership
          venues: initialTournament.venues,
          createdAt: initialTournament.createdAt,
          updatedAt: DateTime(2026, 6, 1),
        );

        // 3. created_by remains User A
        expect(transferredTournament.createdBy, equals('user-a'));
        expect(transferredTournament.wasCreatedBy('user-a'), isTrue);

        // 4. User A receives NO Owner/Organizer authority merely because A created it
        expect(transferredTournament.isOrganizedBy('user-a'), isFalse);
        expect(transferredTournament.effectiveOwnerUserId, equals('user-b'));

        // 5. User B receives Owner authority
        expect(transferredTournament.isOrganizedBy('user-b'), isTrue);
        expect(transferredTournament.wasCreatedBy('user-b'), isFalse);
      },
    );

    test(
      '18. Historical membership user anonymization / status transition model',
      () {
        final activeMembership = TournamentMembership(
          id: 'mem-3',
          tournamentId: 't-301',
          userId: 'user-c',
          roleKey: 'manager',
          status: TournamentMembershipStatus.active,
          appointedBy: 'user-b',
          appointedAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(activeMembership.isActive, isTrue);

        // When user is deleted from system, status transitions to removed and removedAt is stamped
        final anonymized = TournamentMembership(
          id: activeMembership.id,
          tournamentId: activeMembership.tournamentId,
          userId: null, // anonymized user_id
          roleKey: activeMembership.roleKey,
          status: TournamentMembershipStatus.removed,
          appointedBy: activeMembership.appointedBy,
          appointedAt: activeMembership.appointedAt,
          removedAt: DateTime(2026, 6, 1),
          createdAt: activeMembership.createdAt,
          updatedAt: DateTime(2026, 6, 1),
        );

        expect(anonymized.isActive, isFalse);
        expect(anonymized.status, equals(TournamentMembershipStatus.removed));
        expect(anonymized.removedAt, isNotNull);
        expect(anonymized.userId, isNull);
      },
    );
  });
}

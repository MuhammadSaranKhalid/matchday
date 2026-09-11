import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/domain/entities/team_relationship.dart';

Team _team({String owner = 'owner1'}) => Team(
      id: const TeamId('t1'),
      createdBy: owner,
      name: 'Lyari Lions',
      type: TeamType.club,
      privacy: TeamPrivacy.public,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('Team.relationshipFor', () {
    test('null user → none', () {
      expect(_team().relationshipFor(userId: null), TeamRelationship.none);
    });

    test('every rung maps straight through from the roster row', () {
      final team = _team(owner: 'someoneElse');
      for (final (role, expected) in const [
        (MemberRole.owner, TeamRelationship.owner),
        (MemberRole.manager, TeamRelationship.manager),
        (MemberRole.captain, TeamRelationship.captain),
        (MemberRole.player, TeamRelationship.player),
      ]) {
        expect(
          team.relationshipFor(userId: 'u1', rosterRole: role),
          expected,
          reason: '$role should map to $expected',
        );
      }
    });

    test('the roster row wins over teams.ownerId', () {
      // ownerId is only a denormalised mirror now. If the two ever disagree,
      // the membership row is the authority — that is what the SQL predicates
      // read.
      expect(
        _team(owner: 'u1')
            .relationshipFor(userId: 'u1', rosterRole: MemberRole.player),
        TeamRelationship.player,
      );
    });

    test('no roster row means no claim — createdBy is NOT a fallback', () {
      // The team-row fallback was removed 2026-09-11 with `owner_id`.
      // `created_by` is history: a creator who has since left the team must
      // not read as its owner, and "roster not loaded yet" must not be
      // answered by guessing. Both cases are `none`.
      expect(
        _team(owner: 'u1').relationshipFor(userId: 'u1'),
        TeamRelationship.none,
      );
      expect(
        _team(owner: 'someoneElse').relationshipFor(userId: 'u1'),
        TeamRelationship.none,
      );
    });

    test('the owner is recognised from their roster row, not the team row', () {
      expect(
        _team(owner: 'someoneElse')
            .relationshipFor(userId: 'u1', rosterRole: MemberRole.owner),
        TeamRelationship.owner,
      );
    });
  });

  group('MemberRole ladder', () {
    test('declaration order is power order, matching the Postgres enum', () {
      expect(MemberRole.player.index, lessThan(MemberRole.captain.index));
      expect(MemberRole.captain.index, lessThan(MemberRole.manager.index));
      expect(MemberRole.manager.index, lessThan(MemberRole.owner.index));
    });

    test('isStaff mirrors is_team_manager (>= manager)', () {
      expect(MemberRole.owner.isStaff, isTrue);
      expect(MemberRole.manager.isStaff, isTrue);
      expect(MemberRole.captain.isStaff, isFalse);
      expect(MemberRole.player.isStaff, isFalse);
    });

    test('hasMatchAuthority mirrors is_team_captain (>= captain)', () {
      expect(MemberRole.owner.hasMatchAuthority, isTrue);
      expect(MemberRole.manager.hasMatchAuthority, isTrue);
      expect(MemberRole.captain.hasMatchAuthority, isTrue);
      expect(MemberRole.player.hasMatchAuthority, isFalse);
    });

    test('unknown wire values degrade to the lowest rung, never the highest',
        () {
      expect(MemberRole.fromWire('vice_captain'), MemberRole.player);
      expect(MemberRole.fromWire('wicket_keeper'), MemberRole.player);
      expect(MemberRole.fromWire(null), MemberRole.player);
      expect(MemberRole.fromWire('owner'), MemberRole.owner);
    });
  });

  group('TeamRelationship capabilities', () {
    test('the captain can run the match but not the club', () {
      // This is the whole point of the 2026-09-10 change: before it, a captain
      // held none of these.
      const c = TeamRelationship.captain;
      expect(c.canPickXi, isTrue);
      expect(c.canScore, isTrue);
      expect(c.canAppointScorer, isTrue);

      expect(c.canEditRoster, isFalse);
      expect(c.canInvite, isFalse);
      expect(c.canSendChallenge, isFalse);
      expect(c.canChangeRoles, isFalse);
    });

    test('a plain player can do nothing but leave', () {
      const p = TeamRelationship.player;
      expect(p.canPickXi, isFalse);
      expect(p.canScore, isFalse);
      expect(p.canEditRoster, isFalse);
      expect(p.canPostAsTeam, isFalse);
      expect(p.canLeave, isTrue);
    });

    test('only the owner appoints staff, transfers or disbands', () {
      for (final r in [
        TeamRelationship.manager,
        TeamRelationship.captain,
        TeamRelationship.player,
        TeamRelationship.none,
      ]) {
        expect(r.canAppointStaff, isFalse, reason: '$r');
        expect(r.canTransferOwnership, isFalse, reason: '$r');
        expect(r.canDisband, isFalse, reason: '$r');
      }
      expect(TeamRelationship.owner.canAppointStaff, isTrue);
      expect(TeamRelationship.owner.canTransferOwnership, isTrue);
      expect(TeamRelationship.owner.canDisband, isTrue);
    });

    test('the owner cannot leave without transferring first', () {
      // Mirrors leave_team() raising 42501 for the owner.
      expect(TeamRelationship.owner.canLeave, isFalse);
      expect(TeamRelationship.manager.canLeave, isTrue);
    });

    test('a stranger has no capability at all', () {
      const n = TeamRelationship.none;
      expect(n.isMember, isFalse);
      expect(n.canLeave, isFalse);
      expect(n.canScore, isFalse);
      expect(n.canEditRoster, isFalse);
    });

    group('canGrant — "never grant a rung at or above your own"', () {
      test('the owner may grant anything below owner', () {
        const o = TeamRelationship.owner;
        expect(o.canGrant(MemberRole.manager), isTrue);
        expect(o.canGrant(MemberRole.captain), isTrue);
        expect(o.canGrant(MemberRole.player), isTrue);
        // Ownership moves only via transfer_team_ownership().
        expect(o.canGrant(MemberRole.owner), isFalse);
      });

      test('a manager may move people between player and captain only', () {
        const m = TeamRelationship.manager;
        expect(m.canGrant(MemberRole.player), isTrue);
        expect(m.canGrant(MemberRole.captain), isTrue);
        expect(m.canGrant(MemberRole.manager), isFalse);
        expect(m.canGrant(MemberRole.owner), isFalse);
      });

      test('captain, player and stranger may grant nothing', () {
        for (final r in [
          TeamRelationship.captain,
          TeamRelationship.player,
          TeamRelationship.none,
        ]) {
          for (final target in MemberRole.values) {
            expect(r.canGrant(target), isFalse, reason: '$r -> $target');
          }
        }
      });
    });
  });
}

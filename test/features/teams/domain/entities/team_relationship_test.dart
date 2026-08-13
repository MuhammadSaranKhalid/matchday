import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/domain/entities/team_relationship.dart';

Team _team({String owner = 'owner1', List<String> managers = const []}) => Team(
      id: const TeamId('t1'),
      ownerId: owner,
      name: 'Lions',
      type: TeamType.club,
      privacy: TeamPrivacy.public,
      managers: managers,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('Team.relationshipFor', () {
    test('null user → none', () {
      expect(
        _team().relationshipFor(userId: null),
        TeamRelationship.none,
      );
    });

    test('owner wins regardless of roster role', () {
      expect(
        _team(owner: 'u1').relationshipFor(
          userId: 'u1',
          rosterRole: MemberRole.player,
        ),
        TeamRelationship.owner,
      );
    });

    test('manager (not owner) → manager', () {
      expect(
        _team(owner: 'someoneElse', managers: ['u1'])
            .relationshipFor(userId: 'u1'),
        TeamRelationship.manager,
      );
    });

    test('roster role maps through when not owner/manager', () {
      final team = _team(owner: 'someoneElse');
      expect(
        team.relationshipFor(userId: 'u1', rosterRole: MemberRole.captain),
        TeamRelationship.captain,
      );
      expect(
        team.relationshipFor(userId: 'u1', rosterRole: MemberRole.viceCaptain),
        TeamRelationship.viceCaptain,
      );
      expect(
        team.relationshipFor(userId: 'u1', rosterRole: MemberRole.wicketKeeper),
        TeamRelationship.wicketKeeper,
      );
      expect(
        team.relationshipFor(userId: 'u1', rosterRole: MemberRole.player),
        TeamRelationship.player,
      );
    });

    test('not owner/manager and no roster role → none', () {
      expect(
        _team(owner: 'someoneElse').relationshipFor(userId: 'u1'),
        TeamRelationship.none,
      );
    });
  });
}

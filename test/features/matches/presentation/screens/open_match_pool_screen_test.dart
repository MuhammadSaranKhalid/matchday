import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_request.dart';
import 'package:matchday/features/matches/presentation/providers/match_pool_providers.dart';
import 'package:matchday/features/matches/presentation/providers/matches_feed_providers.dart';
import 'package:matchday/features/matches/presentation/screens/open_match_pool_screen.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

/// Covers how the Pool board picks between artboards 01–05.
void main() {
  OpenMatchPoolItem item(String id, String name, {MatchBallType? ball}) {
    final request = MatchRequest(
      id: MatchRequestId(id),
      fromTeamId: TeamId('team-$id'),
      requestedBy: 'user-1',
      status: MatchRequestStatus.pending,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      proposedVenue: 'Gaddafi B Ground',
      proposedFormat: MatchFormat(
        oversPerInnings: 12,
        playersPerTeam: 11,
        maxOversPerBowler: 3,
        ballType: ball ?? MatchBallType.tape,
      ),
    );
    return OpenMatchPoolItem(
      request: request,
      fromTeam: Team(
        id: TeamId('team-$id'),
        ownerId: 'user-2',
        name: name,
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        managers: const ['user-2'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      formatLabel: '12 Overs · TAPE',
      venue: 'Gaddafi B Ground',
      shareCode: '123456',
      timeLabel: '',
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required bool managesTeam,
    required List<OpenMatchPoolItem> board,
    PoolFacet facet = PoolFacet.all,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          viewerManagesTeamProvider.overrideWith((ref) async => managesTeam),
          openMatchPoolProvider.overrideWith((ref) async => board),
          openMatchPoolFilterProvider.overrideWith(
            () => _StubFilter(facet),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OpenMatchPoolScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('populated board lists challenges under a counted header',
      (tester) async {
    await pump(
      tester,
      managesTeam: true,
      board: [item('1', 'Lahore Lions'), item('2', 'Gulberg Giants')],
    );

    expect(find.text('OPEN CHALLENGES · 2'), findsOneWidget);
    expect(find.text('Lahore Lions'), findsOneWidget);
    expect(find.text('Gulberg Giants'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
  });

  testWidgets('the board creates nothing — no post button anywhere',
      (tester) async {
    await pump(tester, managesTeam: true, board: [item('1', 'Lahore Lions')]);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.textContaining('Post a pool request'), findsNothing);
    expect(find.textContaining('+ Post'), findsNothing);
    expect(find.textContaining('Looking for a match'), findsNothing);
    expect(find.textContaining('My challenges'), findsNothing);
  });

  testWidgets('a genuinely quiet pool gets the empty explainer',
      (tester) async {
    await pump(tester, managesTeam: true, board: const []);

    expect(find.text('No open challenges yet'), findsOneWidget);
    expect(find.text('Have a share code?'), findsOneWidget);
  });

  testWidgets('a facet that matches nothing keeps the facets reachable',
      (tester) async {
    // The board holds a tape-ball challenge; the Leather facet empties it.
    await pump(
      tester,
      managesTeam: true,
      board: [item('1', 'Lahore Lions')],
      facet: PoolFacet.leather,
    );

    expect(find.text('No open challenges yet'), findsNothing);
    expect(find.text('LEATHER'), findsOneWidget);
    expect(
      find.text('No open challenges under Leather.'),
      findsOneWidget,
    );
  });

  testWidgets('no team: the gate fronts a read-only board', (tester) async {
    await pump(
      tester,
      managesTeam: false,
      board: [item('1', 'Lahore Lions')],
    );

    expect(find.text('You need a team to take part'), findsOneWidget);
    expect(find.text("WHAT'S ON THE BOARD"), findsOneWidget);
    expect(find.text('Lahore Lions'), findsOneWidget);
    expect(
      find.text('BROWSE ONLY · JOIN A TEAM TO APPLY'),
      findsOneWidget,
    );

    // No facets: nothing here is actionable, so there is nothing to cut.
    expect(find.text('ALL'), findsNothing);
  });
}

class _StubFilter extends OpenMatchPoolFilter {
  _StubFilter(this._facet);
  final PoolFacet _facet;

  @override
  PoolFacet build() => _facet;
}

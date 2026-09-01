import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/presentation/widgets/pool/pool_facet_bar.dart';
import 'package:matchday/features/matches/presentation/widgets/pool/pool_states.dart';
import 'package:matchday/features/matches/presentation/providers/match_pool_providers.dart';

/// Covers the Pool board's non-populated states — `Pool.dc.html` artboards
/// 02 (empty), 04 (error) and 05 (no team) — plus the facet row from 01.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  group('PoolEmptyState (artboard 02)', () {
    testWidgets('explains the board instead of selling a create button',
        (tester) async {
      await pump(tester, const PoolEmptyState());

      expect(find.text('No open challenges yet'), findsOneWidget);
      expect(
        find.textContaining('stay up for 48 hours'),
        findsOneWidget,
      );

      // Posting is a you-noun and lives in the side panel, so the empty board
      // offers no way to create anything.
      expect(find.textContaining('Post'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('keeps the share-code row for in-person handoffs',
        (tester) async {
      var tapped = 0;
      await pump(tester, PoolEmptyState(onEnterCode: () => tapped++));

      expect(find.text('Have a share code?'), findsOneWidget);
      expect(find.text('ENTER'), findsOneWidget);

      await tester.tap(find.text('Have a share code?'));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  group('PoolErrorState (artboard 04)', () {
    testWidgets('states the cause, offers retry, prints the code',
        (tester) async {
      var retries = 0;
      await pump(
        tester,
        PoolErrorState(
          onRetry: () => retries++,
          code: 'Error 503 · pool_unavailable',
        ),
      );

      expect(find.text("Couldn't load the pool"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('ERROR 503 · POOL_UNAVAILABLE'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('omits the code line rather than printing an empty rule',
        (tester) async {
      await pump(tester, PoolErrorState(onRetry: () {}));

      expect(find.text("Couldn't load the pool"), findsOneWidget);
      expect(find.textContaining('pool_unavailable'), findsNothing);
    });
  });

  group('PoolNoTeamGate (artboard 05)', () {
    testWidgets('says where teams come from without linking into them',
        (tester) async {
      await pump(tester, const PoolNoTeamGate());

      expect(find.text('You need a team to take part'), findsOneWidget);
      expect(find.textContaining('under My teams'), findsOneWidget);

      // The Pool tab creates nothing, not even a team.
      expect(find.byType(TextButton), findsNothing);
      expect(find.textContaining('Create'), findsNothing);
    });
  });

  group('PoolFacetBar (artboard 01)', () {
    testWidgets('renders the four facets and reports selection',
        (tester) async {
      PoolFacet? picked;
      await pump(
        tester,
        PoolFacetBar(
          selected: PoolFacet.all,
          onSelect: (f) => picked = f,
        ),
      );

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('TAPE-BALL'), findsOneWidget);
      expect(find.text('LEATHER'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);

      await tester.tap(find.text('LEATHER'));
      await tester.pump();
      expect(picked, PoolFacet.leather);
    });
  });

  group('PoolLoadingState (artboard 03)', () {
    testWidgets('paints card-shaped skeletons, not a spinner', (tester) async {
      await pump(tester, const PoolLoadingState());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}

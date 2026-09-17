import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/widgets/v2/ck_shimmer.dart';
import 'package:matchday/features/notifications/presentation/widgets/notifications_shimmer_skeleton.dart';

void main() {
  testWidgets('renders NotificationsShimmerSkeleton with CkShimmer and rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationsShimmerSkeleton(itemCount: 5),
        ),
      ),
    );

    // Initial pump without settling animation infinite loop
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(NotificationsShimmerSkeleton), findsOneWidget);
    expect(find.byType(CkShimmer), findsOneWidget);
    // 1 box in head dot, 1 in head label, plus per row (bar, icon, title, time, body = 5 boxes)
    // 2 + 5 * 5 = 27 CkShimmerBoxes
    expect(find.byType(CkShimmerBox), findsNWidgets(27));
  });
}

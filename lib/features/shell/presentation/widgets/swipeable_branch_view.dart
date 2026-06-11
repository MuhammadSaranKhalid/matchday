import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hosts the five branch [Navigator]s of the app shell inside a [PageView] so
/// the tabs can be swiped through with a smooth, finger-tracking transition
/// (Home ⇄ Matches ⇄ Pavilion ⇄ Messages ⇄ You).
///
/// Wired as the `navigatorContainerBuilder` of the [StatefulShellRoute] in
/// `app_router.dart`, replacing the default `IndexedStack` container. The
/// branch widgets passed in [children] are go_router's keep-alive branch
/// proxies (`AutomaticKeepAliveClientMixin`), so every tab retains its own
/// navigation + scroll state across swipes — the same guarantee the
/// IndexedStack gave. (Branches are marked `preload: true` in the router so a
/// swipe reveals real content immediately instead of a blank page.)
///
/// Inner horizontal scrollables (segmented filters, chip rows, media
/// carousels) keep working: as the deeper same-axis scrollable they win the
/// gesture arena, so the PageView only pages when the drag is over a
/// non-horizontally-scrolling area.
///
/// Two-way sync with go_router's branch index:
/// - swipe settles → [PageView.onPageChanged] → `goBranch` updates the route;
/// - external switch (bottom-nav tap, deep link, push) → [didUpdateWidget]
///   glides the pager to the new branch.
class SwipeableBranchView extends StatefulWidget {
  const SwipeableBranchView({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<SwipeableBranchView> createState() => _SwipeableBranchViewState();
}

class _SwipeableBranchViewState extends State<SwipeableBranchView> {
  late final PageController _controller =
      PageController(initialPage: widget.navigationShell.currentIndex);

  @override
  void didUpdateWidget(covariant SwipeableBranchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The active branch changed from outside the PageView (a bottom-nav tap, a
    // deep link, a push payload). Glide the pager to match.
    final target = widget.navigationShell.currentIndex;
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // A settled swipe selects that branch. Guard against the echo from
    // animateToPage, which fires onPageChanged with the already-current index.
    if (index != widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      onPageChanged: _onPageChanged,
      children: widget.children,
    );
  }
}

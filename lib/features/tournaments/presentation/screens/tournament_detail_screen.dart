import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/ck_standings_table.dart';
import '../widgets/tournament_bracket_view.dart';
import '../widgets/tournament_fixtures_tab.dart';
import '../widgets/tournament_overview_tab.dart';
import '../widgets/tournament_stats_tab.dart';
import '../widgets/tournament_teams_tab.dart';

/// The main read surface for a tournament.
class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    this.initialTab = 0,
  });

  final String tournamentId;
  final int initialTab;

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  int _followCount = 42;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
      _followCount += _isFollowing ? 1 : -1;
    });
  }

  void _shareTournament(Tournament tournament) {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out ${tournament.name} on Matchday Cricket!\nhttps://matchday.cricket/tournaments/${tournament.id}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) {
        final isKnockout = tournament.type == TournamentType.knockout;

        final tabs = [
          const Tab(text: 'Overview'),
          const Tab(text: 'Fixtures'),
          Tab(text: isKnockout ? 'Bracket' : 'Standings'),
          const Tab(text: 'Teams'),
          const Tab(text: 'Stats'),
        ];

        return Scaffold(
          backgroundColor: CkColors.paper,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Top Hero Banner + Identity Zone
                SliverToBoxAdapter(
                  child: _buildHeaderContent(tournament),
                ),

                // Pinned Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: CkColors.ink,
                      unselectedLabelColor: CkColors.muted,
                      indicatorColor: CkColors.red,
                      indicatorWeight: 2.5,
                      labelStyle: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: CkType.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: tabs,
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                TournamentOverviewTab(tournament: tournament),
                TournamentFixturesTab(tournament: tournament),
                if (isKnockout)
                  TournamentBracketView(tournament: tournament)
                else
                  _buildStandingsTab(tournament),
                TournamentTeamsTab(tournament: tournament),
                TournamentStatsTab(tournament: tournament),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CkColors.paper,
        appBar: AppBar(backgroundColor: CkColors.paper),
        body: Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildHeaderContent(Tournament tournament) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Cover Banner with Overlapping Crest ────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner Graphic
            if (tournament.bannerImageUrl != null)
              Image.network(
                tournament.bannerImageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              _buildGenerativeBanner(),

            // Top Floating Navigation Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavCircle(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      Row(
                        children: [
                          _buildNavCircle(
                            icon: _isFollowing
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            iconColor:
                                _isFollowing ? CkColors.red : CkColors.ink,
                            onTap: _toggleFollow,
                          ),
                          const SizedBox(width: 8),
                          _buildNavCircle(
                            icon: Icons.share_outlined,
                            onTap: () => _shareTournament(tournament),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Overlapping Tournament Crest
            Positioned(
              left: 20,
              bottom: -28,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: CkColors.paper,
                    width: 3.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(40, 30, 15, 0.12),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: _buildLogo(tournament, 56),
              ),
            ),
          ],
        ),

        // ─── Tournament Identity & Meta Zone ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges Row (Status & Privacy)
              Row(
                children: [
                  _buildStatusPill(tournament.status),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: CkColors.paper2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: CkColors.line),
                    ),
                    child: Text(
                      tournament.type.label.toUpperCase(),
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink2,
                      ),
                    ),
                  ),
                  if (tournament.privacy == TournamentPrivacy.private) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: CkColors.paper2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 10, color: CkColors.muted),
                          const SizedBox(width: 3),
                          Text(
                            'UNLISTED',
                            style: CkType.mono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                tournament.name,
                style: CkType.display(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle Info Row
              Row(
                children: [
                  if (tournament.city != null) ...[
                    const Icon(Icons.location_on_outlined,
                        size: 13.5, color: CkColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      tournament.city!,
                      style: CkType.body(fontSize: 12.5, color: CkColors.ink2),
                    ),
                    const SizedBox(width: 10),
                    Text('·',
                        style: CkType.mono(
                            fontSize: 12, color: CkColors.soft)),
                    const SizedBox(width: 10),
                  ],
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: CkColors.muted),
                  const SizedBox(width: 5),
                  Text(
                    _buildDateString(tournament),
                    style: CkType.mono(fontSize: 11, color: CkColors.muted),
                  ),
                  const SizedBox(width: 10),
                  Text('·',
                      style: CkType.mono(
                          fontSize: 12, color: CkColors.soft)),
                  const SizedBox(width: 10),
                  Text(
                    '$_followCount followers',
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavCircle({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = CkColors.ink,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: CkColors.paper.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }

  Widget _buildStatusPill(TournamentStatus status) {
    Color bg;
    Color fg;
    Border? border;

    switch (status) {
      case TournamentStatus.live:
        bg = CkColors.red;
        fg = Colors.white;
        break;
      case TournamentStatus.registration:
        bg = CkColors.cream;
        fg = CkColors.amberDark;
        border = Border.all(color: CkColors.creamBorder);
        break;
      case TournamentStatus.upcoming:
        bg = CkColors.paper2;
        fg = CkColors.ink2;
        border = Border.all(color: CkColors.line);
        break;
      case TournamentStatus.completed:
        bg = CkColors.greenSoft;
        fg = CkColors.greenInk;
        border = Border.all(color: CkColors.greenBorder);
        break;
      case TournamentStatus.draft:
        bg = CkColors.paper2;
        fg = CkColors.muted;
        border = Border.all(color: CkColors.soft);
        break;
      case TournamentStatus.cancelled:
      case TournamentStatus.abandoned:
        bg = CkColors.redSoft;
        fg = CkColors.redInk;
        border = Border.all(color: CkColors.redBorder);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
      child: Text(
        status.label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStandingsTab(Tournament tournament) {
    final standingsStream =
        ref.watch(tournamentStandingsStreamProvider(tournament.id));

    return standingsStream.when(
      data: (standings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CkStandingsTable(standings: standings),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildLogo(Tournament t, double size) {
    final monogram = t.name.length >= 2
        ? t.name.substring(0, 2).toUpperCase()
        : 'TD';

    if (t.logoUrl != null && t.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          t.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Center(
        child: Text(
          monogram,
          style: CkType.display(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B5414),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerativeBanner() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF29251E), // CkColors.ink
            Color(0xFF3D372E),
            Color(0xFF29251E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background geometric pitch crease / trophy watermark
          const Positioned(
            right: 20,
            top: 20,
            bottom: 20,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.emoji_events,
                size: 96,
                color: CkColors.cream,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CkColors.creamBorder.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDateString(Tournament t) {
    if (t.startDate == null) return 'Dates TBA';
    final start = '${t.startDate!.day}/${t.startDate!.month}';
    if (t.endDate == null) return start;
    final end = '${t.endDate!.day}/${t.endDate!.month}';
    return '$start – $end';
  }
}

/// Custom delegate to pin TabBar below the header in NestedScrollView.
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(
          bottom: BorderSide(color: CkColors.hairline),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

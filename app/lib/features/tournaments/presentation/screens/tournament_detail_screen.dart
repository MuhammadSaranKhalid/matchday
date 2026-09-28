import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/ck_standings_table.dart';
import '../widgets/tournament_bracket_view.dart';
import '../widgets/tournament_fixtures_tab.dart';
import '../widgets/tournament_group_hub_tab.dart';
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

/// 168pt banner + the identity zone beneath it. Fixed so the pinned
/// header has a stable maxExtent; the zone ellipsises rather than growing.
const double _headerMaxExtent = 300;

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {

  /// Writes a real `follows` row with `target_type = 'tournament'`. The
  /// follows feature already modelled [TournamentFollowTarget] end to end;
  /// this screen was the only consumer that never called it, which is why
  /// the hub's Following bucket — a query over exactly these rows — could
  /// never fill.
  void _toggleFollow() => ref
      .read(followToggleProvider('tournament', widget.tournamentId).notifier)
      .toggle();

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
        // Artboard 13b: two groups feeding a bracket is its own shape. The
        // group table and the bracket are different questions, so they get
        // different tabs — and Fixtures folds into Groups, because in a
        // hybrid every fixture belongs to a group or to the playoffs.
        final isHybrid = tournament.type == TournamentType.groupKnockout;

        final tabs = isHybrid
            ? const [
                Tab(text: 'Overview'),
                Tab(text: 'Groups'),
                Tab(text: 'Playoffs'),
                Tab(text: 'Stats'),
              ]
            : [
                const Tab(text: 'Overview'),
                const Tab(text: 'Fixtures'),
                Tab(text: isKnockout ? 'Bracket' : 'Standings'),
                const Tab(text: 'Teams'),
                const Tab(text: 'Stats'),
              ];

        return DefaultTabController(
          length: tabs.length,
          initialIndex: widget.initialTab.clamp(0, tabs.length - 1),
          child: Scaffold(
          backgroundColor: CkColors.paper,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Artboard 09–15 header. Expanded it is the banner and the
                // floating crest; on scroll it collapses to a 56pt bar over
                // about 120pt of travel. The banner fades and the logo
                // *scales into* the monogram — it does not slide away — so the
                // identity never leaves the screen.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CollapsingHeader(
                    tournament: tournament,
                    expanded: _buildHeaderContent(tournament),
                    logo: (size) => _buildLogo(tournament, size),
                    maxHeight: _headerMaxExtent,
                  ),
                ),

                // Pinned Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
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
              children: isHybrid
                  ? [
                      TournamentGroupHubTab(tournament: tournament),
                      _buildStandingsTab(tournament),
                      TournamentBracketView(tournament: tournament),
                      TournamentStatsTab(tournament: tournament),
                    ]
                  : [
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
                height: 168,
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
                          Consumer(
                            builder: (context, ref, _) {
                              final following = ref
                                      .watch(followToggleProvider(
                                          'tournament', widget.tournamentId))
                                      .value ??
                                  false;
                              return _buildNavCircle(
                                icon: following
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                iconColor:
                                    following ? CkColors.red : CkColors.ink,
                                onTap: _toggleFollow,
                              );
                            },
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
    // Form and the next fixture are read off the same board the rest of the
    // detail screen uses, so the table can never disagree with the fixtures
    // tab about who beat whom.
    final board = ref.watch(tournamentLiveBoardProvider(tournament.id)).value ??
        const <TournamentLiveMatch>[];

    return standingsStream.when(
      data: (standings) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: CkStandingsTable(
          standings: standings,
          qualificationCutRank: _cutRankFor(tournament, standings.length),
          cutLabel: _cutLabelFor(tournament, standings.length),
          contextFor: (s) => _contextFor(s.teamId, board),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  /// How many teams go through. A league sends four to the semi-finals; a
  /// group sends the top two. Zero hides the rule rather than guessing.
  int _cutRankFor(Tournament t, int teams) {
    if (teams < 3) return 0;
    return switch (t.type) {
      TournamentType.league => teams >= 6 ? 4 : 2,
      TournamentType.roundRobin => teams >= 6 ? 4 : 2,
      TournamentType.groupKnockout => 2,
      _ => 0,
    };
  }

  String? _cutLabelFor(Tournament t, int teams) {
    final cut = _cutRankFor(t, teams);
    if (cut == 0) return null;
    return cut == 2
        ? 'Top 2 advance to semi-finals'
        : 'Top $cut advance to semi-finals';
  }

  /// Last five results, oldest first, plus what they play next.
  StandingContext _contextFor(String teamId, List<TournamentLiveMatch> board) {
    final theirs = board
        .where((m) => m.teamAId == teamId || m.teamBId == teamId)
        .toList()
      ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));

    final form = <String>[];
    for (final m in theirs.where((m) => m.isFinished)) {
      form.add(switch (m.status) {
        'tied' => 'T',
        'no_result' || 'abandoned' => 'N',
        _ when m.winnerId == null => 'N',
        _ => m.winnerId == teamId ? 'W' : 'L',
      });
    }

    String? next;
    for (final m in theirs) {
      if (m.isFinished || m.isLive) continue;
      final opponentId = m.teamAId == teamId ? m.teamBId : m.teamAId;
      final opponent = m.displayNameFor(opponentId);
      next = 'v $opponent, ${DateFormat('E').format(m.scheduledStartTime)}';
      break;
    }

    return StandingContext(
      form: form.length <= 5 ? form : form.sublist(form.length - 5),
      nextFixture: next,
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


/// The tournament detail header (artboards 09–15).
///
/// Expanded it is a 168pt banner with the crest floating −24 over its edge.
/// On scroll it collapses to a 56pt bar over about 120pt of travel: the banner
/// fades out, and the crest **scales into** the 28pt monogram rather than
/// sliding away, so the identity is continuous from one state to the other.
/// The tab strip pins directly under whichever state is showing, which is why
/// this is a pinned persistent header rather than a sliver that scrolls off.
class _CollapsingHeader extends SliverPersistentHeaderDelegate {
  const _CollapsingHeader({
    required this.tournament,
    required this.expanded,
    required this.logo,
    required this.maxHeight,
  });

  final Tournament tournament;
  final Widget expanded;
  final Widget Function(double size) logo;
  final double maxHeight;

  static const _collapsedHeight = 56.0;

  /// The canvas specifies the travel, not just the endpoints.
  static const _travel = 120.0;

  @override
  double get minExtent => _collapsedHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = (shrinkOffset / _travel).clamp(0.0, 1.0);

    return ClipRect(
      child: Material(
        color: CkColors.paper,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The expanded state fades as it is scrolled over. OverflowBox
            // lets the natural content keep its own height while the sliver
            // shrinks around it, so nothing reflows on the way down.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: maxHeight,
              child: Opacity(
                opacity: 1 - t,
                // A generous but *bounded* ceiling: the content lays out at
                // its natural height and the ClipRect trims anything past the
                // sliver, rather than throwing an overflow.
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: maxHeight * 2,
                  child: expanded,
                ),
              ),
            ),
            if (t > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _collapsedHeight,
                child: Opacity(
                  opacity: t,
                  child: _CollapsedBar(
                    tournament: tournament,
                    // The crest scales down into the monogram across the same
                    // travel, so the two states share one object.
                    logo: logo(28 + (48 - 28) * (1 - t)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingHeader old) =>
      old.tournament != tournament || old.maxHeight != maxHeight;
}

class _CollapsedBar extends StatelessWidget {
  const _CollapsedBar({required this.tournament, required this.logo});

  final Tournament tournament;
  final Widget logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Material(
              color: CkColors.paper2,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.arrow_back, size: 17, color: CkColors.ink),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 28, height: 28, child: FittedBox(child: logo)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tournament.name,
                maxLines: 1,
                // Tail-ellipsised, per the canvas: the start of a cup's name
                // is what identifies it.
                overflow: TextOverflow.ellipsis,
                style: CkType.display(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

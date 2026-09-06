import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_push_nav.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../controllers/teams_list_controller.dart';
import '../state/my_teams_view.dart';
import '../widgets/my_teams/crest_palette.dart';
import '../widgets/my_teams/role_pill.dart';

/// "My teams" — the faithful Flutter realisation of the matchday v2 design
/// (`design/screens/MyTeams.jsx`). [TeamsListController] builds the
/// [MyTeamsView] (including the active filter) directly from provider data, so
/// this screen is a pure renderer: it watches the view and forwards user
/// affordances back to the controller / router.
class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncView = ref.watch(teamsListControllerProvider);
    final controller = ref.read(teamsListControllerProvider.notifier);

    switch (asyncView) {
      case AsyncData(value: final view):
        final t = view.teams;
        final leadCount = t.captain.length + t.vc.length;
        final manageCount = t.manage.length + t.draft.length + t.scorer.length;

        return Scaffold(
          backgroundColor: CkColors.paper,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: CkColors.ink,
              onRefresh: controller.refresh,
              child: ColoredBox(
                color: CkColors.paper,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        CkPushNav(
                          title: 'My Teams',
                          onBack: () => context.pop(),
                          // One primary action at a time: while the list is
                          // empty the card below owns "Create", so the nav
                          // pill would be a second identical CTA.
                          action: view.isEmpty
                              ? null
                              : CkNavPill(
                                  label: 'Create',
                                  onTap: () => context.push('/teams/create'),
                                ),
                        ),
                        Expanded(
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 12),
                            children: [
                              // ── Empty-state card — dashed border, a faded
                              //    crest row that ends in an open slot, then
                              //    the two things you can actually do here:
                              //    start a side, or find the one you play for.
                              if (view.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    20,
                                    18,
                                    0,
                                  ),
                                  child: CustomPaint(
                                    painter: _EmptyDashedBorderPainter(
                                      color: CkColors.line,
                                      radius: 16,
                                      strokeWidth: 1.2,
                                      dashLength: 5,
                                      dashGap: 4,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        22,
                                        20,
                                        20,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Three crests then an empty slot —
                                          // the row says "teams, and a space
                                          // for yours" without a caption.
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _dimCrest(MyTeamsCrests.ll),
                                              const SizedBox(width: 7),
                                              _dimCrest(MyTeamsCrests.mk),
                                              const SizedBox(width: 7),
                                              _dimCrest(MyTeamsCrests.gg),
                                              const SizedBox(width: 7),
                                              _emptyCrestSlot(),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'No teams yet',
                                            textAlign: TextAlign.center,
                                            style: CkType.display(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.025,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              'Start your mohalla side, or find the team you already play for.',
                                              textAlign: TextAlign.center,
                                              style: CkType.body(
                                                fontSize: 13,
                                                color: CkColors.ink2,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _emptyCta(
                                                  label: 'Create a team',
                                                  primary: true,
                                                  onTap: () => context.push(
                                                    '/teams/create',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _emptyCta(
                                                  label: 'Find a team',
                                                  primary: false,
                                                  onTap: () => context.push(
                                                    '/explore/teams',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // ── "STATUS · WHAT NEEDS YOU" banner ────────
                              if (view.needsYou.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          4,
                                          0,
                                          4,
                                          8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              'STATUS · WHAT NEEDS YOU',
                                              style: CkType.mono(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.10,
                                                color: CkColors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: CkColors.ink,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${view.needsYou.length}',
                                                style: CkType.mono(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.10,
                                                  color: CkColors.paper,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      for (
                                        var i = 0;
                                        i < view.needsYou.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(height: 6),
                                        _needsYouCard(
                                          context,
                                          view.needsYou[i],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                              // ── Today / Live match hero card ────────────
                              if (view.today != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          view.today!.live
                                              ? CkColors.ink
                                              : CkColors.paper,
                                      borderRadius: BorderRadius.circular(14),
                                      border:
                                          view.today!.live
                                              ? null
                                              : Border.all(
                                                color: CkColors.hairline,
                                              ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // top row
                                        Row(
                                          children: [
                                            if (view.today!.live)
                                              const LivePill()
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: CkColors.cream,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'TODAY · ${view.today!.when ?? ''}',
                                                  style: CkType.mono(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.10,
                                                    color: CkInk.amber,
                                                  ),
                                                ),
                                              ),
                                            if (view.today!.ctx != null) ...[
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  view.today!.ctx!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: CkType.mono(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.10,
                                                    color:
                                                        view.today!.live
                                                            ? CkColors.paper
                                                                .withValues(
                                                                  alpha: 0.60,
                                                                )
                                                            : CkColors.muted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (view.today!.role != null) ...[
                                              const Spacer(),
                                              Text(
                                                view.today!.role!,
                                                style: CkType.body(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      view.today!.live
                                                          ? CkColors.paper
                                                              .withValues(
                                                                alpha: 0.85,
                                                              )
                                                          : CkColors.ink,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // sides
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _todayMiniCrest(view.today!.a),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _sideName(
                                                name: view.today!.a.name,
                                                score: view.today!.aScore,
                                                fg:
                                                    view.today!.live
                                                        ? CkColors.paper
                                                        : CkColors.ink,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                'VS',
                                                style: CkType.mono(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.10,
                                                  color:
                                                      view.today!.live
                                                          ? CkColors.paper
                                                              .withValues(
                                                                alpha: 0.55,
                                                              )
                                                          : CkColors.muted,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: _sideName(
                                                name: view.today!.b.name,
                                                score: view.today!.bScore,
                                                fg:
                                                    view.today!.live
                                                        ? CkColors.paper
                                                        : CkColors.ink,
                                                alignEnd: true,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            _todayMiniCrest(view.today!.b),
                                          ],
                                        ),
                                        if (view.today!.note != null) ...[
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color:
                                                      view.today!.live
                                                          ? CkColors.paper
                                                              .withValues(
                                                                alpha: 0.12,
                                                              )
                                                          : CkColors.hairline,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    view.today!.note!,
                                                    style: CkType.body(
                                                      fontSize: 12,
                                                      color:
                                                          view.today!.live
                                                              ? CkColors.paper
                                                                  .withValues(
                                                                    alpha: 0.75,
                                                                  )
                                                              : CkColors.ink2,
                                                    ),
                                                  ),
                                                ),
                                                if (view.today!.venue != null)
                                                  Text(
                                                    view.today!.venue!,
                                                    style: CkType.mono(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.10,
                                                      color:
                                                          view.today!.live
                                                              ? CkColors.paper
                                                                  .withValues(
                                                                    alpha: 0.60,
                                                                  )
                                                              : CkColors.muted,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                              // ── Invites ─────────────────────────────────
                              if (view.invites.isNotEmpty) ...[
                                Subhead(
                                  'Invites',
                                  accent: CkColors.red,
                                  count: view.invites.length,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < view.invites.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(height: 8),
                                        // Direct invite card — Accept / Decline.
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CkColors.paper,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: CkColors.hairline,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _inviteMiniCrest(
                                                    view.invites[i].crest,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            // INVITE chip
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    CkColors
                                                                        .cream,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                'INVITE',
                                                                style: CkType.mono(
                                                                  fontSize: 8.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  letterSpacing:
                                                                      0.08,
                                                                  color:
                                                                      CkInk
                                                                          .amber,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                view
                                                                    .invites[i]
                                                                    .fromName
                                                                    .toUpperCase(),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: CkType.mono(
                                                                  fontSize: 9,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  letterSpacing:
                                                                      0.10,
                                                                  color:
                                                                      CkColors
                                                                          .muted,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          '${view.invites[i].fromName} invited you to ${view.invites[i].crest.name}.',
                                                          style: CkType.display(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing:
                                                                -0.02,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          '${view.invites[i].role}${view.invites[i].crest.city == null ? '' : ' · ${view.invites[i].crest.city}'}',
                                                          style: CkType.body(
                                                            fontSize: 12,
                                                            color:
                                                                CkColors.muted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {},
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: Container(
                                                        height: 38,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                          color: CkColors.ink,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Accept',
                                                          style: CkType.body(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                CkColors.paper,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {},
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: Container(
                                                        height: 38,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                          color: CkColors.paper,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                CkColors
                                                                    .hairline,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Decline',
                                                          style: CkType.body(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: CkColors.ink,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // ── You lead (captain + vc) ─────────────────
                              if (leadCount > 0) ...[
                                const Subhead('Teams you lead'),
                                for (final row in t.captain)
                                  TeamRow(
                                    vm: row,
                                    isFirst: identical(row, t.captain.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}/manage',
                                            ),
                                  ),
                                for (final row in t.vc)
                                  TeamRow(
                                    vm: row,
                                    isFirst:
                                        t.captain.isEmpty &&
                                        identical(row, t.vc.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}/manage',
                                            ),
                                  ),
                              ],

                              // ── You play ────────────────────────────────
                              if (t.playing.isNotEmpty) ...[
                                const Subhead('Teams you play in'),
                                for (final row in t.playing)
                                  TeamRow(
                                    vm: row,
                                    isFirst: identical(row, t.playing.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}',
                                            ),
                                  ),
                              ],

                              // ── You manage (manage + draft + scorer) ────
                              if (manageCount > 0) ...[
                                const Subhead('Teams you manage'),
                                for (final row in t.manage)
                                  TeamRow(
                                    vm: row,
                                    isFirst: identical(row, t.manage.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}/manage',
                                            ),
                                  ),
                                for (final row in t.draft)
                                  TeamRow(
                                    vm: row,
                                    isFirst:
                                        t.manage.isEmpty &&
                                        identical(row, t.draft.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}/manage',
                                            ),
                                  ),
                                for (final row in t.scorer)
                                  TeamRow(
                                    vm: row,
                                    isFirst:
                                        t.manage.isEmpty &&
                                        t.draft.isEmpty &&
                                        identical(row, t.scorer.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}/manage',
                                            ),
                                  ),
                              ],

                              // ── Awaiting approval ───────────────────────
                              if (t.pending.isNotEmpty) ...[
                                Subhead(
                                  'Awaiting approval',
                                  accent: CkColors.amber,
                                  count: t.pending.length,
                                ),
                                for (final row in t.pending)
                                  TeamRow(
                                    vm: row,
                                    isFirst: identical(row, t.pending.first),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}',
                                            ),
                                  ),
                              ],

                              // ── Following ───────────────────────────────
                              if (view.following.isNotEmpty) ...[
                                Subhead(
                                  'Following',
                                  count: view.following.length,
                                ),
                                for (final row in view.following)
                                  TeamRow(
                                    vm: row,
                                    isFirst: identical(
                                      row,
                                      view.following.first,
                                    ),
                                    withChevron: true,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}',
                                            ),
                                  ),
                              ],

                              // ── Archived ────────────────────────────────
                              if (t.archived.isNotEmpty) ...[
                                Subhead('Archived', count: t.archived.length),
                                for (final row in t.archived)
                                  TeamRow(
                                    vm: row,
                                    isFirst: identical(row, t.archived.first),
                                    withChevron: false,
                                    onTap:
                                        row.teamId == null
                                            ? null
                                            : () => context.push(
                                              '/teams/${row.teamId}',
                                            ),
                                  ),
                              ],

                              // ── Suggested ───────────────────────────────
                              if (view.suggested.isNotEmpty) ...[
                                Subhead(
                                  view.suggestedTitle ?? 'Near you · Karachi',
                                ),
                                // Horizontal scroll of suggested team cards.
                                SizedBox(
                                  height: 132,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      4,
                                    ),
                                    itemCount: view.suggested.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (_, i) {
                                      final item = view.suggested[i];
                                      return Container(
                                        width: 168,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CkColors.paper,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: CkColors.hairline,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: item.crest.color,
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                item.crest.mono,
                                                style: CkType.display(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.03,
                                                  color: CkColors.paper,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.crest.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: CkType.display(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.02,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Expanded(
                                              child: Text(
                                                item.meta,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: CkType.body(
                                                  fontSize: 11,
                                                  color: CkColors.muted,
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: CkColors.paper,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: CkColors.hairline,
                                                  ),
                                                ),
                                                child: Text(
                                                  '+ Follow',
                                                  style: CkType.body(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: CkColors.ink,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // ── "Play, don't just watch." nudge ─────────
                              if (view.showCreateNudge)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    18,
                                    14,
                                    0,
                                  ),
                                  child: CustomPaint(
                                    painter: _NudgeDashedBorderPainter(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: CkColors.paper2,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.add,
                                              size: 18,
                                              color: CkColors.ink,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Play, don't just watch.",
                                                  style: CkType.display(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.02,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Create your own side or join one near Karachi.',
                                                  style: CkType.body(
                                                    fontSize: 11.5,
                                                    color: CkColors.muted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap:
                                                () => context.push(
                                                  '/teams/create',
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 7,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: CkColors.ink,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Start',
                                                style: CkType.body(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: CkColors.paper,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case AsyncError():
        return Scaffold(
          backgroundColor: CkColors.paper,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load teams',
                    style: CkType.body(fontSize: 14, color: CkColors.ink2),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Go back',
                        style: CkType.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case AsyncLoading():
        return const Scaffold(
          backgroundColor: CkColors.paper,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: CircularProgressIndicator(color: CkColors.ink),
            ),
          ),
        );
    }
  }

  // ── Empty-state crest (used 3×) ────────────────────────────────────
  Widget _dimCrest(CrestStyle crest) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        crest.mono,
        style: CkType.display(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03,
          color: CkColors.muted,
        ),
      ),
    );
  }

  /// The open slot at the end of the empty-state crest row — same tile
  /// geometry as [_dimCrest] but dashed and carrying a "+", so the row reads
  /// as teams with a space left for yours.
  Widget _emptyCrestSlot() {
    return CustomPaint(
      painter: _EmptyDashedBorderPainter(
        color: CkColors.line,
        radius: 9,
        strokeWidth: 1.2,
        dashLength: 3,
        dashGap: 3,
      ),
      child: const SizedBox(
        width: 36,
        height: 36,
        child: Center(child: Icon(Icons.add, size: 15, color: CkColors.muted)),
      ),
    );
  }

  /// Empty-state CTA pill. Same primary/secondary grammar as [_actionBtn]
  /// (filled ink vs paper + hairline) at the taller 42pt empty-card scale.
  Widget _emptyCta({
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primary ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }

  // ── Needs-you accent color + card (card used 1× via loop) ──────────
  Color _accent(NeedsYouItem item) {
    switch (item.tone) {
      case NeedsYouTone.red:
        return CkColors.red;
      case NeedsYouTone.amber:
        return CkColors.amber;
      case NeedsYouTone.ink:
        return CkColors.ink;
    }
  }

  Widget _needsYouCard(BuildContext context, NeedsYouItem item) {
    // Flutter disallows borderRadius with non-uniform border colors, so the
    // accent left edge is rendered as an inner stripe clipped to the
    // rounded corners rather than as a border side.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: _accent(item)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (RolePill.hasSpec(item.role)) ...[
                          RolePill(role: item.role),
                          const SizedBox(width: 6),
                        ],
                        if (item.subTag != null)
                          Flexible(
                            child: Text(
                              item.subTag!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.mono(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.10,
                                color: CkColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      style: CkType.body(fontSize: 12, color: CkColors.ink2),
                    ),
                    if (item.actions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < item.actions.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            _actionBtn(context, item.actions[i], i == 0),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(BuildContext context, NeedsYouAction action, bool primary) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: primary ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        action.label,
        style: CkType.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primary ? CkColors.paper : CkColors.ink,
        ),
      ),
    );
    final teamId = action.manageTeamId;
    if (teamId == null) return pill; // inert (e.g. "Later")
    return InkWell(
      onTap: () => context.push('/teams/$teamId/manage'),
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }

  // ── Today mini-crest (image used 2×, mono used 3×) + side name (2×) ─
  Widget _todayMiniCrestMono(CrestStyle crest) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: crest.color,
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Text(
      crest.mono,
      style: CkType.display(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.03,
        color: CkColors.paper,
      ),
    ),
  );

  Widget _todayMiniCrest(CrestStyle crest) {
    if (crest.logoUrl == null || crest.logoUrl!.isEmpty) {
      return _todayMiniCrestMono(crest);
    }
    return Builder(
      builder: (context) {
        final memW = (32 * MediaQuery.devicePixelRatioOf(context)).round();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            color: CkColors.paper2,
            child: CachedNetworkImage(
              imageUrl: crest.logoUrl!,
              fit: BoxFit.cover,
              width: 32,
              height: 32,
              memCacheWidth: memW,
              errorWidget: (_, __, ___) => _todayMiniCrestMono(crest),
              placeholder: (_, __) => _todayMiniCrestMono(crest),
            ),
          ),
        );
      },
    );
  }

  Widget _sideName({
    required String name,
    required String? score,
    required Color fg,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: fg,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score ?? '—',
          style: CkType.mono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: fg,
          ),
        ),
      ],
    );
  }

  // ── Invite mini-crest (image used 1×, mono used 2×) ────────────────
  Widget _inviteMiniCrestMono(CrestStyle crest) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: crest.color,
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.center,
    child: Text(
      crest.mono,
      style: CkType.display(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.03,
        color: CkColors.paper,
      ),
    ),
  );

  Widget _inviteMiniCrest(CrestStyle crest) {
    if (crest.logoUrl == null || crest.logoUrl!.isEmpty) {
      return _inviteMiniCrestMono(crest);
    }
    return Builder(
      builder: (context) {
        final memW = (40 * MediaQuery.devicePixelRatioOf(context)).round();
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            color: CkColors.paper2,
            child: CachedNetworkImage(
              imageUrl: crest.logoUrl!,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              memCacheWidth: memW,
              errorWidget: (_, __, ___) => _inviteMiniCrestMono(crest),
              placeholder: (_, __) => _inviteMiniCrestMono(crest),
            ),
          ),
        );
      },
    );
  }
}

/// Section subhead — clean mono uppercase label.
class Subhead extends StatelessWidget {
  const Subhead(this.label, {super.key, this.accent, this.count});

  final String label;
  final Color? accent;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: accent ?? CkColors.muted,
        ),
      ),
    );
  }
}

/// Modern team card row used across all team sections.
class TeamRow extends StatelessWidget {
  const TeamRow({
    super.key,
    required this.vm,
    this.isFirst = false,
    this.withChevron = true,
    this.onTap,
  });

  final TeamRowVm vm;
  final bool isFirst;
  final bool withChevron;
  final VoidCallback? onTap;

  bool get _inactive =>
      vm.role == MyTeamsRole.archived || vm.role == MyTeamsRole.pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Opacity(
            opacity: _inactive ? 0.74 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _crestWithBadge(
                    context,
                    crest: vm.crest,
                    dim: vm.role == MyTeamsRole.archived,
                    badge: vm.notifCount,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                vm.crest.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CkType.display(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.01,
                                ),
                              ),
                            ),
                            if (vm.verified) ...[
                              const SizedBox(width: 6),
                              const VerifiedTick(),
                            ],
                            if (RolePill.hasSpec(vm.role)) ...[
                              const SizedBox(width: 6),
                              RolePill(role: vm.role),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        _metaLine(),
                      ],
                    ),
                  ),
                  if (withChevron) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: CkColors.muted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monoTile(CrestStyle crest, bool dim) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: dim ? CkColors.paper2 : crest.color,
      borderRadius: BorderRadius.circular(11),
      border:
          dim
              ? Border.all(color: CkColors.line, style: BorderStyle.solid)
              : null,
    ),
    alignment: Alignment.center,
    child: Text(
      crest.mono,
      style: CkType.display(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.03,
        color: dim ? CkColors.muted : CkColors.paper,
      ),
    ),
  );

  Widget _crestWithBadge(
    BuildContext context, {
    required CrestStyle crest,
    required bool dim,
    int? badge,
  }) {
    final showImage =
        !dim && (crest.logoUrl != null && crest.logoUrl!.isNotEmpty);
    final memW = (44 * MediaQuery.devicePixelRatioOf(context)).round();
    final tile =
        showImage
            ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 44,
                height: 44,
                color: CkColors.paper2,
                child: CachedNetworkImage(
                  imageUrl: crest.logoUrl!,
                  fit: BoxFit.cover,
                  width: 44,
                  height: 44,
                  memCacheWidth: memW,
                  errorWidget: (_, __, ___) => _monoTile(crest, dim),
                  placeholder: (_, __) => _monoTile(crest, dim),
                ),
              ),
            )
            : _monoTile(crest, dim);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (badge != null && badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.paper, width: 2),
                ),
                child: Text(
                  '$badge',
                  style: CkType.display(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(TextStyle style) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text('·', style: style),
  );

  Widget _metaLine() {
    final style = CkType.mono(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.02,
      color: CkColors.muted,
    );
    final parts = <Widget>[];
    if (vm.jersey != null) {
      parts.add(Text('#${vm.jersey}', style: style));
      parts.add(_dot(style));
    }
    parts.add(
      Flexible(
        child: Text(
          vm.meta ?? vm.crest.city ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
    if (vm.live) {
      parts.add(_dot(style));
      parts.add(const LivePill());
    }
    return Row(children: parts);
  }
}

/// Paints a dashed rounded-rect border. Used by the empty-state and
/// create-nudge cards.
class _EmptyDashedBorderPainter extends CustomPainter {
  _EmptyDashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var d = 0.0;
      final total = m.length;
      while (d < total) {
        final extract = m.extractPath(d, (d + dashLength).clamp(0, total));
        canvas.drawPath(extract, paint);
        d += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_EmptyDashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.dashGap != dashGap;
}

class _NudgeDashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = CkColors.line
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        final extract = m.extractPath(d, (d + 5).clamp(0, m.length));
        canvas.drawPath(extract, paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

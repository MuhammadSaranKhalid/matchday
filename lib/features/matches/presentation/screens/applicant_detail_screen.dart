import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/match_pool_application.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_providers.dart';
import '../widgets/host/applicant_xi_list.dart';
import '../widgets/host/host_detail_view.dart';
import '../widgets/host/host_kit.dart';
import '../widgets/host/host_sheets.dart';
import '../widgets/pool/pool_challenge_card.dart';
import '../widgets/pool/pool_icons.dart';
import '../widgets/pool/pool_states.dart';

/// One applicant, in full — `Pool.dc.html` artboard 16.
///
/// The board's cards do not decide; this screen does. It is the only place the
/// single Accept lives, alongside the one Reject, so the host reads the XI and
/// the message before either.
class ApplicantDetailScreen extends ConsumerStatefulWidget {
  const ApplicantDetailScreen({
    super.key,
    required this.requestId,
    required this.applicationId,
  });

  final String requestId;
  final String applicationId;

  @override
  ConsumerState<ApplicantDetailScreen> createState() =>
      _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState
    extends ConsumerState<ApplicantDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(poolApplicationsProvider(widget.requestId));
    final request = ref.watch(matchChallengeProvider(widget.requestId)).value;

    void back() => context.canPop()
        ? context.pop()
        : context.go('/challenges/${widget.requestId}');

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: HostTopBar(title: 'Applicant', onBack: back),
          ),
          Expanded(
            child: switch (apps) {
              AsyncLoading() =>
                const SingleChildScrollView(child: PoolLoadingState()),
              AsyncError() => Center(
                  child: PoolErrorState(
                    onRetry: () => ref.invalidate(
                      poolApplicationsProvider(widget.requestId),
                    ),
                  ),
                ),
              AsyncData(value: final list) => switch (_find(list)) {
                  null => Center(
                      child: Text(
                        'This application is no longer available.',
                        style: CkType.body(
                          fontSize: 13,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                  final app => _Body(
                      application: app,
                      playersPerSide: request?.playersPerSide ?? 11,
                      busy: _busy,
                      onAccept: () => _accept(app, list),
                      onReject: () => _reject(app),
                    ),
                },
            },
          ),
        ],
      ),
    );
  }

  MatchPoolApplication? _find(List<MatchPoolApplication> list) {
    for (final a in list) {
      if (a.id == widget.applicationId) return a;
    }
    return null;
  }

  Future<void> _accept(
    MatchPoolApplication app,
    List<MatchPoolApplication> all,
  ) async {
    final applicant =
        ref.read(teamProvider(app.applicantTeamId.value)).value;

    // The sheet needs to name who else loses out, so gather the other pending
    // teams before opening it.
    final others = <String>[];
    for (final other in all) {
      if (other.id == app.id) continue;
      if (other.status != PoolApplicationStatus.pending) continue;
      final team =
          ref.read(teamProvider(other.applicantTeamId.value)).value;
      others.add(team?.name ?? 'A team');
    }

    final confirmed = await showAcceptApplicantSheet(
      context,
      applicant: applicant,
      otherApplicantNames: others,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final result = await ref
        .read(matchPoolRepositoryProvider)
        .acceptPoolApplication(applicationId: app.id);
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) => _toast(failure.message),
      (matchId) {
        _invalidate();
        context.go('/matches/${matchId.value}');
      },
    );
  }

  Future<void> _reject(MatchPoolApplication app) async {
    final applicant =
        ref.read(teamProvider(app.applicantTeamId.value)).value;

    final decision =
        await showRejectApplicantSheet(context, applicant: applicant);
    if (decision == null || !mounted) return;

    setState(() => _busy = true);
    final result = await ref
        .read(matchPoolRepositoryProvider)
        .rejectPoolApplication(
          applicationId: app.id,
          reason: decision.reason,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) => _toast(failure.message),
      (_) {
        _invalidate();
        if (context.canPop()) context.pop();
      },
    );
  }

  void _invalidate() {
    ref.invalidate(poolApplicationsProvider(widget.requestId));
    ref.invalidate(matchChallengeProvider(widget.requestId));
    ref.invalidate(myChallengesProvider);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.application,
    required this.playersPerSide,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final MatchPoolApplication application;
  final int playersPerSide;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team =
        ref.watch(teamProvider(application.applicantTeamId.value)).value;
    final roster =
        ref.watch(rosterProvider(application.applicantTeamId.value)).value ??
            const [];
    final entries = resolveXi(
      xi: application.applicantXi,
      roster: roster,
      keeperId: application.applicantKeeperId,
    );
    final message = application.message?.trim();
    final pending = application.status == PoolApplicationStatus.pending;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Crest(
                      short: teamMonogram(team),
                      color: teamCrestColor(team),
                      logoUrl: team?.logoUrl,
                      size: 46,
                      radius: 13,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  team?.name ?? 'Applicant',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CkType.display(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: CkColors.ink,
                                    letterSpacing: -0.01,
                                  ),
                                ),
                              ),
                              if (team?.isVerified ?? false) ...[
                                const SizedBox(width: 6),
                                const PoolIcon(PoolIcons.verified, size: 13),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Applied ${compactAgo(application.createdAt)}'
                                .toUpperCase(),
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.05,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusPill(application.status),
                  ],
                ),
              ),
              if (message != null && message.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CkColors.line),
                  ),
                  child: Text(
                    '“$message”',
                    style: CkType.body(
                      fontSize: 13,
                      height: 1.55,
                      color: CkColors.ink2,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              HostSectionLabel(
                'Their XI',
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                trailing: Text(
                  (entries.length == 1
                          ? '1 player'
                          : '${entries.length} players')
                      .toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: CkColors.muted,
                  ),
                ),
              ),
              ApplicantXiList(entries: entries),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (pending)
          HostBottomBar(
            child: Row(
              children: [
                _RejectButton(onTap: busy ? null : onReject),
                const SizedBox(width: 10),
                Expanded(
                  child: HostActionButton(
                    label: 'Accept & create match',
                    onTap: onAccept,
                    busy: busy,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statusPill(PoolApplicationStatus status) => switch (status) {
        PoolApplicationStatus.pending => CkStatusPill.card('Pending'),
        PoolApplicationStatus.accepted => CkStatusPill.banner(
            'Accepted',
            background: CkColors.greenSoft,
            foreground: CkColors.greenInk,
          ),
        PoolApplicationStatus.rejected => CkStatusPill.banner(
            'Declined',
            background: CkColors.soft,
            foreground: CkColors.paper,
          ),
        PoolApplicationStatus.withdrawn => CkStatusPill.banner(
            'Withdrawn',
            background: CkColors.soft,
            foreground: CkColors.paper,
          ),
      };
}

/// Outlined in red rather than filled: rejecting is destructive but it is not
/// the primary action on this screen, and two filled buttons would tie.
class _RejectButton extends StatelessWidget {
  const _RejectButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.red),
        ),
        child: Text(
          'Reject',
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CkColors.red,
            letterSpacing: -0.01,
          ),
        ),
      ),
    );
  }
}

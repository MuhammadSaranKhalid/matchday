import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_button.dart';
import '../../controllers/match_start_controller.dart';
import '../../providers/match_start_providers.dart';
import '../../state/match_start_state.dart';
import '../../state/match_start_views.dart';
import '../lineup_picker.dart';
import 'match_start_atoms.dart';

/// Stage 2 — the batting side selects the opening pair.
///
/// Authorization is `cricket.match.setup` on the batting team (or a match-scoped
/// setup grant for an official), not a hard-coded "captain" role check.
class MatchStartLineupStage
    extends ConsumerWidget {
  const MatchStartLineupStage({
    super.key,
    required this.matchId,
    required this.state,
  });

  final String matchId;
  final MatchStartState state;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    if (
      !state.canManageBattingSetup
    ) {
      return const Center(
        child:
            MatchStartWaitingCard(
          eyebrow:
              'WAITING ON THE BATTING SIDE',
          title:
              'They’re selecting the openers.',
          body:
              'A team member with match setup permission, or the assigned match official, will lock the opening pair and start the match.',
        ),
      );
    }

    final candidates =
        ref.watch(
      matchStartLineupProvider(
        matchId,
      ),
    );

    return switch (candidates) {
      AsyncError(:final error) =>
        Center(
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  32,
            ),
            child:
                Text(
              failureMessageOf(
                error,
              ),
              textAlign:
                  TextAlign.center,
              style:
                  CkType.body(
                fontSize:
                    13,
                color:
                    CkColors.muted,
              ),
            ),
          ),
        ),
      AsyncData(:final value) =>
        _Picker(
          matchId:
              matchId,
          state:
              state,
          candidates:
              value,
        ),
      _ =>
        const MatchStartLoader(),
    };
  }
}

class _Picker
    extends ConsumerWidget {
  const _Picker({
    required this.matchId,
    required this.state,
    required this.candidates,
  });

  final String matchId;
  final MatchStartState state;
  final List<MatchStartLineupCandidate>
      candidates;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    String? nameOf(
      String? refId,
    ) {
      if (refId == null) {
        return null;
      }

      for (
        final c in candidates
      ) {
        if (c.refId == refId) {
          return c.name;
        }
      }

      return null;
    }

    final controller =
        ref.read(
      matchStartControllerProvider(
        matchId,
      ).notifier,
    );

    return Column(
      children: [
        _SlotsRow(
          strikerLabel:
              nameOf(
            state.striker,
          ),
          nonStrikerLabel:
              nameOf(
            state.nonStriker,
          ),
        ),
        Expanded(
          child:
              ListView.builder(
            padding:
                const EdgeInsets.symmetric(
              vertical:
                  4,
            ),
            itemCount:
                candidates.length,
            itemBuilder:
                (
              context,
              i,
            ) {
              final candidate =
                  candidates[i];

              return LineupRosterRow(
                name:
                    candidate.name,
                photoUrl:
                    candidate.photoUrl,
                jersey:
                    candidate.jersey,
                badge:
                    switch (
                      candidate.refId
                    ) {
                  final id
                      when id ==
                          state
                              .striker =>
                    'STR',
                  final id
                      when id ==
                          state
                              .nonStriker =>
                    'NS',
                  _ =>
                    null,
                },
                onTap:
                    () => controller
                        .tapOpener(
                  candidate.refId,
                ),
              );
            },
          ),
        ),
        Container(
          decoration:
              const BoxDecoration(
            color:
                CkColors.paper,
            border:
                Border(
              top:
                  BorderSide(
                color:
                    CkColors.hairline,
              ),
            ),
          ),
          padding:
              const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            24,
          ),
          child:
              CkButton(
            label:
                'Start match — first ball',
            busy:
                state.isBusy,
            onPressed:
                state.isLineupReady
                    ? () async {
                        final res =
                            await controller
                                .submitOpenersAndStart();

                        if (!context.mounted) {
                          return;
                        }

                        res.fold(
                          (failure) =>
                              ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content:
                                  Text(
                                failure.message,
                              ),
                            ),
                          ),
                          (_) =>
                              context.go(
                            '/matches/$matchId/score',
                          ),
                        );
                      }
                    : null,
          ),
        ),
      ],
    );
  }
}

class _SlotsRow
    extends StatelessWidget {
  const _SlotsRow({
    this.strikerLabel,
    this.nonStrikerLabel,
  });

  final String? strikerLabel;
  final String? nonStrikerLabel;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        12,
      ),
      decoration:
          const BoxDecoration(
        color:
            CkColors.paper,
        border:
            Border(
          bottom:
              BorderSide(
            color:
                CkColors.hairline,
          ),
        ),
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                LineupSlotCard(
              label:
                  'ON STRIKE',
              value:
                  strikerLabel,
              hot:
                  true,
            ),
          ),
          const SizedBox(
            width:
                8,
          ),
          Expanded(
            child:
                LineupSlotCard(
              label:
                  'NON-STRIKER',
              value:
                  nonStrikerLabel,
            ),
          ),
        ],
      ),
    );
  }
}

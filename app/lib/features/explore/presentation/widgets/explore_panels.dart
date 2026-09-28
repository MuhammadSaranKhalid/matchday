import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import 'explore_atoms.dart';

/// Recents + suggestion chips, shown when the field is focused and empty
/// (artboard 04).
class RecentSearchesPanel extends StatelessWidget {
  const RecentSearchesPanel({
    super.key,
    required this.recents,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> recents;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  /// Static prompts, not personalised. They exist to teach the shape of a
  /// useful query on a cold account, so they name entity kinds rather than
  /// specific cities we may have no data for.
  static const _suggestions = <String>[
    'Tape-ball teams',
    'All-rounders',
    'Wicket-keepers',
    'Live matches',
    'Verified teams',
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            ExploreSectionHeader(
              label: 'Recent',
              trailingLabel: 'Clear all',
              trailingColor: CkColors.red,
              onTrailingTap: onClearAll,
            ),
            for (final r in recents)
              RuledRow(
                onTap: () => onTap(r),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 16,
                      color: CkColors.soft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onRemove(r),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: CkColors.soft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const ExploreSectionHeader(label: 'Try searching'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _suggestions)
                  _SuggestionChip(label: s, onTap: () => onTap(s)),
              ],
            ),
          ),
        ],
      );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CkColors.line),
          ),
          child: Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.ink,
            ),
          ),
        ),
      );
}

/// Zero hits (artboard 07). A circular glyph, a calm headline, a spelling
/// nudge, then ruled routes out — never a dead end.
///
/// The design offers three routes: "Search all of Pakistan", "Turn off near
/// me scope", and "Add X as a team". The first two are geo scopes that do not
/// exist in v1 (there is no location scope to widen or drop), so showing them
/// would be theatre. Only the real one ships.
class ExploreNoResults extends StatelessWidget {
  const ExploreNoResults({
    super.key,
    required this.query,
    required this.onClear,
    this.onCreateTeam,
  });

  final String query;
  final VoidCallback onClear;
  final VoidCallback? onCreateTeam;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.line),
              ),
              child: const Center(
                child: V2Svg(
                  V2Icons.search,
                  size: 24,
                  color: CkColors.soft,
                  strokeWidth: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches for \u201C$query\u201D',
              textAlign: TextAlign.center,
              style: CkType.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check the spelling, or they may not be on matchday yet. '
              'Here\u2019s where to look next.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            if (onCreateTeam != null)
              _RouteOutRow(
                icon: V2Icons.plus,
                label: 'Add \u201C${_titleCase(query)}\u201D as a team',
                onTap: onCreateTeam!,
              ),
            _RouteOutRow(
              icon: V2Icons.close,
              label: 'Clear the search',
              onTap: onClear,
            ),
          ],
        ),
      );

  /// "zorabad rangers" → "Zorabad Rangers", so the CTA reads like the team
  /// name the user is about to create.
  static String _titleCase(String s) => s
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// One ruled "here is where to look next" row: cream icon tile, label,
/// chevron.
class _RouteOutRow extends StatelessWidget {
  const _RouteOutRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: CkColors.cream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CkColors.creamBorder),
                    ),
                    child: Center(
                      child: V2Svg(
                        icon,
                        size: 15,
                        color: CkColors.ink,
                        strokeWidth: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: CkColors.soft,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Inline error with retry. Branches on the [Failure] type so a dropped
/// connection does not read like a server fault.
class ExploreError extends StatelessWidget {
  const ExploreError({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (failure) {
      NetworkFailure() => (
          'You’re offline',
          'Explore needs a connection. Check your network and try again.',
        ),
      AuthFailure() => (
          'Session expired',
          'Sign in again to keep searching.',
        ),
      _ => (
          'Something went wrong',
          failure.message,
        ),
    };

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.redSoft,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: CkType.display(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CkInk.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: CkType.body(fontSize: 12, color: CkColors.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          _InkButton(label: 'Retry', onTap: onRetry),
        ],
      ),
    );
  }
}

/// "Be the first" — the cold-start moment. Shown when browse comes back with
/// nothing at all, which on a young database is the common case.
class ExploreBeTheFirst extends StatelessWidget {
  const ExploreBeTheFirst({super.key, this.onCreateTeam});

  final VoidCallback? onCreateTeam;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          children: [
            Text(
              'Nothing here yet',
              textAlign: TextAlign.center,
              style: CkType.display(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: Text(
                'Cricket here starts with you. Create a team so the next '
                'player who looks finds someone.',
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 12,
                  color: CkColors.muted,
                  height: 1.5,
                ),
              ),
            ),
            if (onCreateTeam != null) ...[
              const SizedBox(height: 16),
              _InkButton(label: 'Create a team', onTap: onCreateTeam!),
            ],
          ],
        ),
      );
}

/// Ink pill button — the design's primary action shape on this screen.
class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label.toUpperCase(),
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: CkColors.paper,
              ),
            ),
          ),
        ),
      );
}

/// Shimmer-free skeleton rows for the first browse paint. Deliberately plain
/// — a skeleton that animates draws more attention than the content it
/// stands in for.
class ExploreRowSkeleton extends StatelessWidget {
  const ExploreRowSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < count; i++)
            RuledRow(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CkColors.paper2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: CkColors.paper2,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: 9,
                          width: 90,
                          decoration: BoxDecoration(
                            color: CkColors.hairline,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

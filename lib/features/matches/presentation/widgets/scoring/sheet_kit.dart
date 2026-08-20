// Shared chrome and controls for the scoring bottom sheets.
// Extracted from scoring_screen.dart, which had grown past 3,200
// lines. Purely presentational — no Riverpod, no repository access.

import 'package:flutter/material.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/util/initials.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';

class SheetPerson {
  const SheetPerson({
    required this.id,
    required this.name,
    this.role = '',
    this.photoUrl,
  });
  final String id; // match_player_id
  final String name;
  final String role;

  /// Avatar URL, or null for players without one (always null for unclaimed
  /// placeholders). The tile falls back to the player's monogram.
  final String? photoUrl;
}

class SheetScrim extends StatelessWidget {
  const SheetScrim({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Color(0x38281E0F),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            22 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2, bottom: 14),
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetHead extends StatelessWidget {
  const SheetHead({super.key, 
    required this.kicker,
    required this.title,
    this.subtitle,
    this.kickerColor,
  });
  final String kicker;
  final String title;
  final String? subtitle;
  final Color? kickerColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: kickerColor ?? CkColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle!,
                style: CkType.body(
                  fontSize: 13,
                  color: CkColors.ink2,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({super.key, 
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: disabled
                ? CkColors.paper2
                : danger
                    ? CkColors.red
                    : CkColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: disabled ? CkColors.muted : CkColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class SheetGhostButton extends StatelessWidget {
  const SheetGhostButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.paper,
            border: Border.all(color: CkColors.hairline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class SheetChoiceButton extends StatelessWidget {
  const SheetChoiceButton({super.key, 
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    this.tone = SheetChoiceTone.ink,
  });
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final SheetChoiceTone tone;
  @override
  Widget build(BuildContext context) {
    final accent =
        tone == SheetChoiceTone.red ? CkColors.red : CkColors.ink;
    final activeBg =
        tone == SheetChoiceTone.red ? CkColors.redSoft : CkColors.paper2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? activeBg : CkColors.paper,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: active ? accent : CkColors.hairline,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: CkType.body(
                  fontSize: 11,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SheetChoiceTone { ink, red }

class SheetRunChips extends StatelessWidget {
  const SheetRunChips({super.key, 
    required this.value,
    required this.options,
    required this.onPick,
    this.accent = CkColors.ink,
  });
  final int value;
  final List<int> options;
  final ValueChanged<int> onPick;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: [
        for (final r in options)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onPick(r),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                decoration: BoxDecoration(
                  color: value == r ? accent : CkColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: value == r
                      ? null
                      : Border.all(color: CkColors.hairline),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$r',
                  style: CkType.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: value == r ? CkColors.paper : CkColors.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SheetPersonGrid extends StatelessWidget {
  const SheetPersonGrid({super.key, 
    required this.people,
    required this.value,
    required this.onPick,
  });
  final List<SheetPerson> people;
  final String? value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 56,
      ),
      itemCount: people.length,
      itemBuilder: (_, i) {
        final p = people[i];
        final on = p.id == value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onPick(p.id),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: on ? CkColors.paper2 : CkColors.paper,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: on ? CkColors.ink : CkColors.hairline,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Avatar(
                    mono: personInitials(p.name),
                    imageUrl: p.photoUrl,
                    size: 30,
                    tone: on ? AvatarTone.ink : AvatarTone.paper,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          p.role,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.mono(
                            fontSize: 8.5,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


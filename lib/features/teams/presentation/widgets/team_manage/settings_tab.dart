import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/team.dart';
import '../edit_team_sheet.dart';
import '../team_avatar.dart';

/// Team Settings and details tab.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Primary Edit Action Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamAvatar(
                    name: team.name,
                    primaryColor: team.primaryColor,
                    logoUrl: team.logoUrl,
                    monogram: team.logoMonogram,
                    size: 44,
                    radius: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: CkType.display(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.01,
                          ),
                        ),
                        if (team.tagline != null && team.tagline!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            team.tagline!,
                            style: CkType.body(
                              fontSize: 12,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showEditTeamSheet(context, team),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Team Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    foregroundColor: CkColors.paper,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Text(
          'TEAM CONFIGURATION',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),

        _settingTile(
          context: context,
          title: 'Team Logo & Brand Colors',
          value: team.logoUrl != null && team.logoUrl!.isNotEmpty
              ? 'Custom Logo Uploaded'
              : (team.logoMonogram != null
                  ? 'Monogram (${team.logoMonogram})'
                  : 'Preset Colors'),
          icon: Icons.palette_outlined,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          context: context,
          title: 'Team Name',
          value: team.name,
          icon: Icons.shield_outlined,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          context: context,
          title: 'Tagline & Description',
          value: team.tagline ??
              (team.description != null && team.description!.isNotEmpty
                  ? team.description!
                  : 'Not set'),
          icon: Icons.notes_rounded,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          context: context,
          title: 'Location & Home Ground',
          value: '${team.city ?? "No city"} · ${team.homeGround ?? "No ground specified"}',
          icon: Icons.location_on_outlined,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          context: context,
          title: 'Squad Capacity',
          value: '25 Players Max',
          icon: Icons.groups_outlined,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Squad capacity is fixed at 25 players.')),
          ),
        ),
        _settingTile(
          context: context,
          title: 'Team Privacy',
          value: team.privacy == TeamPrivacy.private
              ? 'Private Team (Invite-only)'
              : 'Public Team (Discoverable)',
          icon: Icons.lock_outline_rounded,
          onTap: () => showEditTeamSheet(context, team),
        ),
      ],
    );
  }

  Widget _settingTile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CkColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CkType.body(fontSize: 11, color: CkColors.muted)),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: CkType.display(fontSize: 13.5, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}

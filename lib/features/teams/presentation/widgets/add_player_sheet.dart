import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../providers/team_membership_providers.dart';

/// Modern dual-mode sheet for adding a player to a team:
/// 1. Search registered Matchday players by username/name.
/// 2. Add an offline teammate with optional phone number & cricket style attributes.
class AddPlayerSheet extends ConsumerStatefulWidget {
  const AddPlayerSheet({super.key, required this.team});
  final Team team;

  static Future<void> show(BuildContext context, Team team) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPlayerSheet(team: team),
    );
  }

  @override
  ConsumerState<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends ConsumerState<AddPlayerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jerseyController = TextEditingController();
  PlayingRole? _selectedPlayingRole;
  BattingStyle? _selectedBattingStyle;
  BowlingStyle? _selectedBowlingStyle;
  bool _isSubmittingOffline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearching = true;
        _searchError = null;
      });
      final res = await ref.read(teamMembershipRepositoryProvider).searchUsers(query);
      if (!mounted) return;
      res.fold(
        (failure) => setState(() {
          _isSearching = false;
          _searchError = failure.message;
        }),
        (results) => setState(() {
          _isSearching = false;
          _searchResults = results;
        }),
      );
    });
  }

  Future<void> _showSendInviteSheet(Map<String, dynamic> user) async {
    final uid = user['user_id'] as String;
    final name = user['display_name'] as String? ??
        user['username'] as String? ??
        'Player';
    final username = user['username'] as String?;
    final avatar = user['profile_photo_url'] as String?;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteDetailsModal(
        team: widget.team,
        userId: uid,
        name: name,
        username: username,
        avatarUrl: avatar,
        onSent: () {
          ref.invalidate(teamPendingInvitesProvider(widget.team.id.value));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invitation sent to $name!'),
                backgroundColor: const Color(0xFF1E5A2C),
              ),
            );
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _submitOfflinePlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a player name')),
      );
      return;
    }

    final nameRes = PlayerDisplayName.create(name);
    if (nameRes.isLeft()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameRes.getLeft().toNullable()!.message)),
      );
      return;
    }

    JerseyNumber? jersey;
    final jerseyText = _jerseyController.text.trim();
    if (jerseyText.isNotEmpty) {
      final n = int.tryParse(jerseyText);
      if (n != null) {
        final jRes = JerseyNumber.create(n);
        if (jRes.isLeft()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jRes.getLeft().toNullable()!.message)),
          );
          return;
        }
        jersey = jRes.getRight().toNullable();
      }
    }

    setState(() => _isSubmittingOffline = true);

    final phone = _phoneController.text.trim();
    final res = await ref.read(teamMembershipRepositoryProvider).addUnclaimedPlayer(
          teamId: widget.team.id,
          displayName: nameRes.getRight().toNullable()!,
          phoneNumber: phone.isNotEmpty ? phone : null,
          jerseyNumber: jersey,
          playingRole: _selectedPlayingRole,
          battingStyle: _selectedBattingStyle,
          bowlingStyle: _selectedBowlingStyle,
        );

    if (!mounted) return;
    setState(() => _isSubmittingOffline = false);

    res.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: CkColors.red,
          ),
        );
      },
      (_) {
        ref.invalidate(rosterProvider(widget.team.id.value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to the squad!'),
            backgroundColor: const Color(0xFF1E5A2C),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: CkColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Text('Add to Squad', style: CkType.display(fontSize: 19)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: CkColors.muted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: CkColors.paper,
                unselectedLabelColor: CkColors.muted,
                labelStyle: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: CkType.display(fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Search Users'),
                  Tab(text: 'Offline Teammate'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchTab(),
                  _buildOfflineTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: CkType.body(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by @username or name...',
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: CkColors.muted,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: CkColors.paper2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: CkColors.ink),
                )
              : _searchError != null
                  ? Center(
                      child: Text(
                        _searchError!,
                        style: const TextStyle(color: CkColors.red),
                      ),
                    )
                  : _searchController.text.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_search_outlined,
                                  size: 44,
                                  color: CkColors.soft,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Find Matchday players',
                                  style: CkType.display(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Type a username or full name to add registered cricketers to your roster.',
                                  textAlign: TextAlign.center,
                                  style: CkType.body(
                                    fontSize: 12,
                                    color: CkColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'No users found for "${_searchController.text}"',
                                style: CkType.body(
                                  fontSize: 13,
                                  color: CkColors.muted,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: CkColors.hairline,
                              ),
                              itemBuilder: (_, idx) {
                                final u = _searchResults[idx];
                                final name = u['display_name'] as String? ??
                                    u['username'] as String? ??
                                    'Player';
                                final uname = u['username'] as String?;
                                final playerProfiles = u['player_profiles'];
                                String? role;
                                if (playerProfiles is Map<String, dynamic>) {
                                  role = playerProfiles['player_role'] as String?;
                                } else if (playerProfiles is List &&
                                    playerProfiles.isNotEmpty) {
                                  role = (playerProfiles.first
                                          as Map<String, dynamic>)[
                                      'player_role'] as String?;
                                }
                                final avatar =
                                    u['profile_photo_url'] as String?;

                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: CkColors.paper2,
                                    backgroundImage:
                                        avatar != null && avatar.isNotEmpty
                                            ? NetworkImage(avatar)
                                            : null,
                                    child: avatar == null || avatar.isEmpty
                                        ? Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: CkType.display(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    name,
                                    style: CkType.display(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (uname != null && uname.isNotEmpty)
                                        Text(
                                          '@$uname',
                                          style: CkType.body(
                                            fontSize: 12,
                                            color: CkColors.muted,
                                          ),
                                        ),
                                      if (role != null && role.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CkColors.paper2,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            role.replaceAll('_', ' '),
                                            style: CkType.mono(
                                              fontSize: 9.5,
                                              color: CkColors.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _showSendInviteSheet(u),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CkColors.ink,
                                      foregroundColor: CkColors.paper,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Invite',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
        ),
      ],
    );
  }

  Widget _buildOfflineTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        Text('PLAYER NAME *', style: _labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: CkType.body(fontSize: 14),
          decoration: _inputDecoration('e.g. Babar Azam'),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PHONE NUMBER (OPTIONAL)', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: CkType.body(fontSize: 14),
                    decoration: _inputDecoration('+92 300 1234567'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('JERSEY #', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _jerseyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: CkType.body(fontSize: 14),
                    decoration: _inputDecoration('#56'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('PLAYING ROLE', style: _labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlayingRole.values.map((role) {
            final isSelected = _selectedPlayingRole == role;
            return ChoiceChip(
              label: Text(
                role.label,
                style: CkType.body(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? CkColors.paper : CkColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: CkColors.ink,
              backgroundColor: CkColors.paper2,
              side: BorderSide(
                color: isSelected ? CkColors.ink : CkColors.hairline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedPlayingRole = selected ? role : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text('BATTING STYLE', style: _labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BattingStyle.values.map((style) {
            final isSelected = _selectedBattingStyle == style;
            return ChoiceChip(
              label: Text(
                style.label,
                style: CkType.body(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? CkColors.paper : CkColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: CkColors.ink,
              backgroundColor: CkColors.paper2,
              side: BorderSide(
                color: isSelected ? CkColors.ink : CkColors.hairline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedBattingStyle = selected ? style : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text('BOWLING STYLE', style: _labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BowlingStyle.values.map((style) {
            final isSelected = _selectedBowlingStyle == style;
            return ChoiceChip(
              label: Text(
                style.label,
                style: CkType.body(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? CkColors.paper : CkColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: CkColors.ink,
              backgroundColor: CkColors.paper2,
              side: BorderSide(
                color: isSelected ? CkColors.ink : CkColors.hairline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedBowlingStyle = selected ? style : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        CkButton(
          label: _isSubmittingOffline
              ? 'Adding Teammate...'
              : 'Add Teammate to Squad',
          icon: _isSubmittingOffline
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CkColors.paper,
                  ),
                )
              : const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 18,
                  color: CkColors.paper,
                ),
          onPressed: _isSubmittingOffline ? null : _submitOfflinePlayer,
        ),
      ],
    );
  }

  TextStyle get _labelStyle => CkType.mono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
        color: CkColors.muted,
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: CkType.body(fontSize: 13, color: CkColors.muted),
        filled: true,
        fillColor: CkColors.paper2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CkColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CkColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
        ),
      );
}

class _InviteDetailsModal extends ConsumerStatefulWidget {
  const _InviteDetailsModal({
    required this.team,
    required this.userId,
    required this.name,
    this.username,
    this.avatarUrl,
    required this.onSent,
  });

  final Team team;
  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final VoidCallback onSent;

  @override
  ConsumerState<_InviteDetailsModal> createState() =>
      _InviteDetailsModalState();
}

class _InviteDetailsModalState extends ConsumerState<_InviteDetailsModal> {
  MemberRole _selectedRole = MemberRole.player;
  final _jerseyController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _jerseyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    setState(() => _isSending = true);
    final jerseyText = _jerseyController.text.trim();
    int? jerseyNumber;
    if (jerseyText.isNotEmpty) {
      jerseyNumber = int.tryParse(jerseyText);
    }
    final note = _noteController.text.trim();

    final res = await ref.read(teamMembershipRepositoryProvider).sendTeamInvite(
          teamId: widget.team.id,
          inviteeId: widget.userId,
          role: _selectedRole,
          jerseyNumber: jerseyNumber,
          message: note.isNotEmpty ? note : null,
        );

    if (mounted) {
      res.fold(
        (failure) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send invite: ${failure.message}'),
              backgroundColor: CkColors.red,
            ),
          );
        },
        (_) {
          Navigator.of(context).pop();
          widget.onSent();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text('Send Team Invite', style: CkType.display(fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: CkColors.muted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Row(
                  children: [
                    Avatar(
                      mono: widget.name.isNotEmpty
                          ? widget.name[0].toUpperCase()
                          : '?',
                      imageUrl: widget.avatarUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: CkType.display(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.username != null)
                            Text(
                              '@${widget.username}',
                              style: CkType.body(
                                fontSize: 12,
                                color: CkColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'INVITED ROLE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _roleChip('Squad Player', MemberRole.player),
                  _roleChip('Captain', MemberRole.captain),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'JERSEY NUMBER (OPTIONAL)',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _jerseyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: CkType.body(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 7 or 18',
                  hintStyle: CkType.body(fontSize: 13, color: CkColors.muted),
                  filled: true,
                  fillColor: CkColors.paper2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: CkColors.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ATTACH NOTE / MESSAGE (OPTIONAL)',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 500,
                style: CkType.body(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Join our squad for this weekend tournament!',
                  hintStyle: CkType.body(fontSize: 13, color: CkColors.muted),
                  filled: true,
                  fillColor: CkColors.paper2,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: CkColors.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CkButton(
                label:
                    _isSending ? 'Sending Invitation...' : 'Send Invitation',
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CkColors.paper,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: CkColors.paper,
                      ),
                onPressed: _isSending ? null : _sendInvite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label, MemberRole role) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(
        label,
        style: CkType.body(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? CkColors.paper : CkColors.ink,
        ),
      ),
      selected: isSelected,
      selectedColor: CkColors.ink,
      backgroundColor: CkColors.paper2,
      side: BorderSide(
        color: isSelected ? CkColors.ink : CkColors.hairline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRole = role);
        }
      },
    );
  }
}

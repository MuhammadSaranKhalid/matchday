import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/ck_text_field.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// 4-Step Team Registration Wizard for Tournament Entrants (Artboards 29–33).
class TeamRegistrationSheet extends ConsumerStatefulWidget {
  const TeamRegistrationSheet({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TeamRegistrationSheet> createState() =>
      _TeamRegistrationSheetState();
}

class _TeamRegistrationSheetState extends ConsumerState<TeamRegistrationSheet> {
  int _currentStep = 0;
  String? _selectedTeamId;
  final Set<String> _selectedPlayerIds = {};
  String? _captainPlayerId;
  String? _wicketKeeperPlayerId;

  // Guest players added for this tournament entry
  final List<Map<String, String>> _guestPlayers = [];

  // Step 3 Payment fields
  final _txRefController = TextEditingController();
  final _messageController = TextEditingController();
  bool _paymentProofUploaded = false;

  // Step 4 Declaration
  bool _rulesAgreed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _txRefController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// The organiser sets these in the create wizard (step 5, written to
  /// `rules.min_squad` / `rules.max_squad`). They used to be hardcoded 11–16
  /// here, so a cup that asked for 12–18 still enforced 11–16.
  int _minSquad(Tournament t) =>
      (t.rules['min_squad'] as num?)?.toInt() ?? 11;

  int _maxSquad(Tournament t) =>
      (t.rules['max_squad'] as num?)?.toInt() ?? 16;

  /// "20 Overs", or "100 Balls" for The Hundred — read from the keys the
  /// create wizard actually writes.
  String _formatLine(Tournament t) {
    final balls = (t.format['balls_per_innings'] as num?)?.toInt();
    if (balls != null) return '$balls Balls';
    final overs = (t.format['max_overs'] as num?)?.toInt() ?? 20;
    return '$overs Overs';
  }

  void _nextStep(Tournament tournament) {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      if (_selectedTeamId == null) {
        setState(() => _errorMessage = 'Please select a team to register.');
        return;
      }
    } else if (_currentStep == 1) {
      final totalPlayers = _selectedPlayerIds.length + _guestPlayers.length;
      final min = _minSquad(tournament);
      final max = _maxSquad(tournament);
      if (totalPlayers < min) {
        setState(() => _errorMessage =
            'Minimum $min players required in squad ($totalPlayers selected).');
        return;
      }
      if (totalPlayers > max) {
        setState(() => _errorMessage =
            'Maximum $max players allowed in squad ($totalPlayers selected).');
        return;
      }
      if (_captainPlayerId == null) {
        setState(() => _errorMessage = 'Please designate a Captain (C).');
        return;
      }
      if (_wicketKeeperPlayerId == null) {
        setState(() => _errorMessage = 'Please designate a Wicketkeeper (WK).');
        return;
      }
    } else if (_currentStep == 2) {
      // Step 2 is payment / message
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    setState(() => _errorMessage = null);
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_rulesAgreed) {
      setState(() => _errorMessage =
          'Please agree to tournament eligibility rules and match schedules.');
      return;
    }

    final allPlayerIds = [
      ..._selectedPlayerIds,
      ..._guestPlayers.map((g) => 'guest_${g['name']}'),
    ];

    final noteParts = <String>[];
    if (_txRefController.text.trim().isNotEmpty) {
      noteParts.add('Payment Ref: ${_txRefController.text.trim()}');
    }
    if (_captainPlayerId != null) {
      noteParts.add('Captain: $_captainPlayerId');
    }
    if (_wicketKeeperPlayerId != null) {
      noteParts.add('WK: $_wicketKeeperPlayerId');
    }
    if (_messageController.text.trim().isNotEmpty) {
      noteParts.add(_messageController.text.trim());
    }

    final reg = await ref
        .read(tournamentsControllerProvider.notifier)
        .registerTeam(
          tournamentId: widget.tournamentId,
          teamId: _selectedTeamId!,
          squadPlayerIds: allPlayerIds,
          message: noteParts.isEmpty ? null : noteParts.join(' | '),
        );

    if (reg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '🎉 Registration submitted! The organizer has been notified.'),
          backgroundColor: CkColors.greenInk,
        ),
      );
      context.pop();
    }
  }

  void _showAddGuestDialog() {
    final nameCtrl = TextEditingController();
    String guestRole = 'Batsman';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ADD GUEST PLAYER',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CkTextField(
                    controller: nameCtrl,
                    label: 'Player Full Name',
                    hint: 'e.g. Usama Mir',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PLAYING ROLE',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Batsman',
                      'Bowler',
                      'All-Rounder',
                      'Wicketkeeper'
                    ].map((role) {
                      final isSel = guestRole == role;
                      return ChoiceChip(
                        label: Text(role),
                        selected: isSel,
                        selectedColor: CkColors.ink,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : CkColors.ink,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: CkColors.paper2,
                        onSelected: (_) {
                          setModalState(() => guestRole = role);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  CkButton(
                    label: 'Add to Tournament Squad',
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _guestPlayers.add({
                            'name': nameCtrl.text.trim(),
                            'role': guestRole,
                          });
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    variant: CkButtonVariant.primary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final myTeamsAsync = ref.watch(myTeamsProvider);
    final registrationsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournamentId));
    final isBusy = ref.watch(tournamentsControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: CkColors.canvas,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Team Registration',
          style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: tournamentAsync.when(
        data: (tournament) {
          // Check if user already has an existing registration for this tournament (Artboard 33)
          return myTeamsAsync.when(
            data: (myTeams) {
              return registrationsAsync.when(
                data: (registrations) {
                  final mine = registrations
                      .where((r) =>
                          myTeams.any((t) => t.id.value == r.teamId))
                      .toList();

                  // Scoped to the team the manager picked, not to *any* team
                  // they run. Matching on any of them meant that once Team A
                  // was in, Team B could never be entered — the manager got
                  // Team A's status screen instead of the wizard. Club
                  // officials running several sides are exactly the people
                  // who register more than once.
                  //
                  // With no team picked yet the status view still wins when
                  // there is nothing left to enter, so a single-team manager
                  // lands straight on their tracker as before.
                  final registeredTeamIds =
                      mine.map((r) => r.teamId).toSet();
                  final hasFreeTeam = myTeams
                      .any((t) => !registeredTeamIds.contains(t.id.value));

                  final selected = _selectedTeamId;
                  final existingReg = selected != null
                      ? mine.where((r) => r.teamId == selected).firstOrNull
                      : (mine.isNotEmpty && !hasFreeTeam ? mine.first : null);

                  if (existingReg != null) {
                    return _buildExistingRegistrationView(
                        existingReg, tournament);
                  }

                  return _buildWizardContent(tournament, myTeams, isBusy);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildWizardContent(
      Tournament tournament, List<Team> myTeams, bool isBusy) {
    return SafeArea(
      child: Column(
        children: [
          // Step Progress Bar (Artboards 29–32)
          _buildStepHeader(),

          if (_errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CkColors.redSurface,
                  borderRadius: BorderRadius.circular(CkRadii.sm),
                  border: Border.all(color: CkColors.redBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: CkColors.redInk),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: CkType.body(
                          fontSize: 12.5,
                          color: CkColors.redInk,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Step Content Pages
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStep(tournament, myTeams),
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(tournament, isBusy),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final steps = ['Team', 'Squad', 'Payment', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isDone = idx < _currentStep;
          final isCurrent = idx == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? CkColors.greenInk
                                  : isCurrent
                                      ? CkColors.ink
                                      : CkColors.paper2,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check,
                                      size: 12, color: Colors.white)
                                  : Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? Colors.white
                                            : CkColors.muted,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            steps[idx],
                            style: CkType.mono(
                              fontSize: 10.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isCurrent
                                  ? CkColors.ink
                                  : isDone
                                      ? CkColors.greenInk
                                      : CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDone
                              ? CkColors.greenInk
                              : isCurrent
                                  ? CkColors.ink
                                  : CkColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(Tournament tournament, List<Team> myTeams) {
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectTeam(tournament, myTeams);
      case 1:
        return _buildStep2SquadPicker(tournament);
      case 2:
        return _buildStep3PaymentProof(tournament);
      case 3:
        return _buildStep4ReviewSubmit(tournament, myTeams);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Select Team (Artboard 29) ────────────────────────────────────
  Widget _buildStep1SelectTeam(Tournament tournament, List<Team> myTeams) {
    if (myTeams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, size: 48, color: CkColors.soft),
            const SizedBox(height: 12),
            Text('No Teams Managed', style: CkType.display(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'You need to be a manager or captain of a team to register for tournaments.',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CkButton(
              label: '+ Create New Team',
              onPressed: () => context.push('/teams/new'),
              variant: CkButtonVariant.secondary,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tournament Requirements Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOURNAMENT REQUIREMENTS',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Format',
                      style: CkType.body(fontSize: 13, color: CkColors.muted)),
                  Text(
                    // `max_overs` is the key the create wizard writes;
                    // `overs` never existed, so this line used to read
                    // "20 Overs" for every cup including a 50-over one.
                    '${_formatLine(tournament)} · ${tournament.type.label}',
                    style: CkType.display(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 16, color: CkColors.hairline),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Squad Requirement',
                      style: CkType.body(fontSize: 13, color: CkColors.muted)),
                  Text(
                      'Min ${_minSquad(tournament)}, '
                      'Max ${_maxSquad(tournament)} Players',
                      style: CkType.display(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const Divider(height: 16, color: CkColors.hairline),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entry Fee',
                      style: CkType.body(fontSize: 13, color: CkColors.muted)),
                  Text(
                    tournament.entryFee != null && tournament.entryFee! > 0
                        ? 'PKR ${tournament.entryFee!.toStringAsFixed(0)}'
                        : 'Free Entry',
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tournament.entryFee != null &&
                              tournament.entryFee! > 0
                          ? CkColors.ink
                          : CkColors.greenInk,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'SELECT YOUR TEAM',
          style: CkType.mono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: CkColors.ink,
          ),
        ),
        const SizedBox(height: 10),

        ...myTeams.map((team) {
          final isSelected = _selectedTeamId == team.id.value;
          final monogram = team.name.length >= 2
              ? team.name.substring(0, 2).toUpperCase()
              : team.name;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(CkRadii.md),
              onTap: () {
                setState(() {
                  _selectedTeamId = team.id.value;
                  _selectedPlayerIds.clear();
                  _captainPlayerId = null;
                  _wicketKeeperPlayerId = null;
                  _guestPlayers.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? CkColors.paper : CkColors.paper,
                  borderRadius: BorderRadius.circular(CkRadii.md),
                  border: Border.all(
                    color: isSelected ? CkColors.ink : CkColors.hairline,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CkColors.ink2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          monogram,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: CkType.display(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            team.city ?? 'Local Club',
                            style: CkType.body(
                                fontSize: 12, color: CkColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: team.id.value,
                      groupValue: _selectedTeamId,
                      activeColor: CkColors.ink,
                      onChanged: (val) {
                        setState(() {
                          _selectedTeamId = val;
                          _selectedPlayerIds.clear();
                          _captainPlayerId = null;
                          _wicketKeeperPlayerId = null;
                          _guestPlayers.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Step 2: Squad Selection & Roles (Artboard 30) ─────────────────────────
  Widget _buildStep2SquadPicker(Tournament tournament) {
    final rosterAsync = ref.watch(rosterProvider(_selectedTeamId!));
    final totalCount = _selectedPlayerIds.length + _guestPlayers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Squad count header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: totalCount >= 11 && totalCount <= 16
                ? CkColors.greenSurface
                : CkColors.paper,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(
              color: totalCount >= 11 && totalCount <= 16
                  ? CkColors.greenBorder
                  : CkColors.hairline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SQUAD SELECTION',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: totalCount >= 11 && totalCount <= 16
                      ? CkColors.greenInk
                      : CkColors.ink,
                ),
              ),
              Text(
                '$totalCount / 16 Selected (Min 11)',
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: totalCount >= 11 && totalCount <= 16
                      ? CkColors.greenInk
                      : CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        rosterAsync.when(
          data: (roster) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEAM ROSTER PLAYERS',
                  style: CkType.mono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                ),
                const SizedBox(height: 8),

                ...roster.map((member) {
                  final pid = member.member.playerId;
                  final isSelected = _selectedPlayerIds.contains(pid);
                  final isCaptain = _captainPlayerId == pid;
                  final isWk = _wicketKeeperPlayerId == pid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: CkColors.paper,
                      borderRadius: BorderRadius.circular(CkRadii.md),
                      border: Border.all(
                        color: isSelected ? CkColors.ink : CkColors.hairline,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: CkColors.ink,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedPlayerIds.add(pid);
                                  if (_captainPlayerId == null) {
                                    _captainPlayerId = pid;
                                  }
                                } else {
                                  _selectedPlayerIds.remove(pid);
                                  if (_captainPlayerId == pid) {
                                    _captainPlayerId = null;
                                  }
                                  if (_wicketKeeperPlayerId == pid) {
                                    _wicketKeeperPlayerId = null;
                                  }
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.displayName,
                                  style: CkType.display(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  member.member.role.name.toUpperCase(),
                                  style: CkType.body(
                                      fontSize: 11.5, color: CkColors.muted),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) ...[
                            // Captain toggle chip
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _captainPlayerId =
                                      _captainPlayerId == pid ? null : pid;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCaptain
                                      ? CkColors.cream
                                      : CkColors.paper2,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCaptain
                                        ? CkColors.creamBorder
                                        : CkColors.hairline,
                                  ),
                                ),
                                child: Text(
                                  'C',
                                  style: CkType.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isCaptain
                                        ? CkColors.amberDark
                                        : CkColors.muted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Wicketkeeper toggle chip
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _wicketKeeperPlayerId =
                                      _wicketKeeperPlayerId == pid ? null : pid;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isWk
                                      ? CkColors.greenSurface
                                      : CkColors.paper2,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isWk
                                        ? CkColors.greenBorder
                                        : CkColors.hairline,
                                  ),
                                ),
                                child: Text(
                                  'WK',
                                  style: CkType.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isWk
                                        ? CkColors.greenInk
                                        : CkColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                if (_guestPlayers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'GUEST PLAYERS',
                    style: CkType.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._guestPlayers.map((guest) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(CkRadii.md),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guest['name'] ?? '',
                                style: CkType.display(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${guest['role']} · Guest',
                                style: CkType.body(
                                    fontSize: 11.5, color: CkColors.muted),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: CkColors.redInk),
                            onPressed: () {
                              setState(() {
                                _guestPlayers.remove(guest);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),
                CkButton(
                  label: '+ Add Guest Player',
                  onPressed: _showAddGuestDialog,
                  variant: CkButtonVariant.secondary,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString()),
        ),
      ],
    );
  }

  // ─── Step 3: Payment & Proof (Artboard 31) ────────────────────────────────
  Widget _buildStep3PaymentProof(Tournament tournament) {
    final hasFee = tournament.entryFee != null && tournament.entryFee! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFee) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENTRY FEE PAYABLE',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CkColors.muted,
                      ),
                    ),
                    Text(
                      'PKR ${tournament.entryFee!.toStringAsFixed(0)}',
                      style: CkType.display(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CkColors.ink,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: CkColors.hairline),
                Text(
                  'ORGANIZER PAYMENT DETAILS',
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tournament.rules['paymentDetails']?.toString() ??
                      'JazzCash / EasyPaisa: 0300-1234567\nBank Alfalah: PK36 ALFH 0123 4567 8901 2345\nAccount Title: Tournament Organizer',
                  style: CkType.body(fontSize: 12.5, color: CkColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CkTextField(
            controller: _txRefController,
            label: 'Transaction ID / Reference #',
            hint: 'e.g. JC-982347102',
          ),
          const SizedBox(height: 16),
          // Proof Upload Simulator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _paymentProofUploaded
                  ? CkColors.greenSurface
                  : CkColors.paper,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(
                color: _paymentProofUploaded
                    ? CkColors.greenBorder
                    : CkColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _paymentProofUploaded
                        ? CkColors.greenInk
                        : CkColors.paper2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _paymentProofUploaded ? Icons.receipt_long : Icons.upload_file,
                    color: _paymentProofUploaded ? Colors.white : CkColors.ink,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paymentProofUploaded
                            ? 'Receipt Attached'
                            : 'Upload Payment Receipt',
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _paymentProofUploaded
                            ? 'receipt_payment_proof.jpg'
                            : 'Screenshot or PDF payment proof',
                        style:
                            CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _paymentProofUploaded = !_paymentProofUploaded;
                    });
                  },
                  child: Text(
                    _paymentProofUploaded ? 'Change' : 'Attach',
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CkColors.greenSurface,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.greenBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: CkColors.greenInk, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FREE ENTRY TOURNAMENT',
                        style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CkColors.greenInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No registration fees required.',
                        style: CkType.body(
                            fontSize: 12.5, color: CkColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        CkTextField(
          controller: _messageController,
          label: 'Message for Tournament Organizer (Optional)',
          hint: 'e.g. Excited to participate; our kit color is Navy Blue.',
          maxLines: 2,
        ),
      ],
    );
  }

  // ─── Step 4: Review & Submit (Artboard 32) ────────────────────────────────
  Widget _buildStep4ReviewSubmit(Tournament tournament, List<Team> myTeams) {
    final selectedTeam = myTeams
        .where((t) => t.id.value == _selectedTeamId)
        .firstOrNull;
    final teamName = selectedTeam?.name ?? 'Selected Team';
    final totalSquad = _selectedPlayerIds.length + _guestPlayers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REGISTRATION SUMMARY',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Team',
                      style: CkType.body(fontSize: 13, color: CkColors.muted)),
                  Text(
                    teamName,
                    style: CkType.display(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Divider(height: 16, color: CkColors.hairline),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Squad Members',
                      style: CkType.body(fontSize: 13, color: CkColors.muted)),
                  Text(
                    '$totalSquad Players (${_guestPlayers.length} guests)',
                    style: CkType.display(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 16, color: CkColors.hairline),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entry Fee',
                      style: CkType.body(fontSize: 13, color: CkColors.muted)),
                  Text(
                    tournament.entryFee != null && tournament.entryFee! > 0
                        ? 'PKR ${tournament.entryFee!.toStringAsFixed(0)}'
                        : 'Free',
                    style: CkType.display(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (_txRefController.text.trim().isNotEmpty) ...[
                const Divider(height: 16, color: CkColors.hairline),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Ref',
                        style:
                            CkType.body(fontSize: 13, color: CkColors.muted)),
                    Text(
                      _txRefController.text.trim(),
                      style: CkType.mono(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Declaration checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _rulesAgreed,
              activeColor: CkColors.ink,
              onChanged: (val) {
                setState(() {
                  _rulesAgreed = val ?? false;
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rulesAgreed = !_rulesAgreed),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'I confirm that all squad members meet tournament eligibility rules and will adhere to the official fixture schedule and code of conduct.',
                    style: CkType.body(
                        fontSize: 12.5, color: CkColors.ink2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Existing Registration View (Artboard 33) ─────────────────────────────
  Widget _buildExistingRegistrationView(
      TournamentRegistration reg, Tournament tournament) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: reg.isApproved
                    ? CkColors.greenSurface
                    : reg.isPending
                        ? CkColors.cream
                        : CkColors.redSurface,
                borderRadius: BorderRadius.circular(CkRadii.md),
                border: Border.all(
                  color: reg.isApproved
                      ? CkColors.greenBorder
                      : reg.isPending
                          ? CkColors.creamBorder
                          : CkColors.redBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reg.status.label.toUpperCase(),
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: reg.isApproved
                              ? CkColors.greenInk
                              : reg.isPending
                                  ? CkColors.amberDark
                                  : CkColors.redInk,
                        ),
                      ),
                      Text(
                        'Registered ${reg.registeredAt.day}/${reg.registeredAt.month}/${reg.registeredAt.year}',
                        style: CkType.mono(
                            fontSize: 10, color: CkColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reg.isApproved
                        ? '🎉 Entry Approved & Confirmed'
                        : reg.isPending
                            ? '⏳ Application Under Organizer Review'
                            : 'Entry Not Accepted',
                    style: CkType.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reg.isApproved
                        ? 'Your team is seeded and ready for fixtures.'
                        : reg.isPending
                            ? 'The tournament director will review your squad and fee proof shortly.'
                            // The organiser's words, not the manager's own
                            // application note — showing `message` here told
                            // a declined team their own covering letter was
                            // the reason.
                            : reg.decisionReason ??
                                'Registration was declined.',
                    style: CkType.body(fontSize: 13, color: CkColors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(CkRadii.md),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUBMITTED SQUAD DETAILS',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${reg.squad.length} Players Registered',
                    style: CkType.display(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (reg.seedNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Seed Number: #${reg.seedNumber}',
                      style: CkType.mono(
                          fontSize: 12, color: CkColors.greenInk),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            CkButton(
              label: 'View Tournament Schedule →',
              onPressed: () => context.pop(),
              variant: CkButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Tournament tournament, bool isBusy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: CkButton(
                label: '← Back',
                onPressed: isBusy ? null : _prevStep,
                variant: CkButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: CkButton(
              label: _currentStep == 3
                  ? (isBusy ? 'Submitting...' : 'Submit Entry 🏏')
                  : 'Continue →',
              onPressed: isBusy
                  ? null
                  : _currentStep == 3
                      ? _submitRegistration
                      : () => _nextStep(tournament),
              variant: CkButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }
}

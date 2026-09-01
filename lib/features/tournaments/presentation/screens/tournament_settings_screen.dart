import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../data/datasources/tournaments_datasource_providers.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/tournament_wizard_kit.dart';

/// Artboard 27d — keeps the promise made on step 6 of the create wizard, and
/// states plainly *which fields the locked draw has frozen* rather than
/// silently disabling them.
class TournamentSettingsScreen extends ConsumerStatefulWidget {
  const TournamentSettingsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentSettingsScreen> createState() =>
      _TournamentSettingsScreenState();
}

class _TournamentSettingsScreenState
    extends ConsumerState<TournamentSettingsScreen> {
  final _name = TextEditingController();
  final _prize = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _seeded = false;

  // Newly picked artwork, uploaded on save. The tournament already exists
  // here, so unlike the wizard there is no ordering problem.
  File? _logoFile;
  File? _bannerFile;

  @override
  void dispose() {
    _name.dispose();
    _prize.dispose();
    super.dispose();
  }

  void _seed(Tournament t) {
    if (_seeded) return;
    _seeded = true;
    _name.text = t.name;
    _prize.text = t.prizeDetails ?? '';
    _start = t.startDate;
    _end = t.endDate;
  }

  /// Once the draw is locked, format and team count are frozen: changing them
  /// mid-tournament would invalidate scorecards already recorded.
  bool _drawLocked(Tournament t) => const {
        TournamentStatus.upcoming,
        TournamentStatus.live,
        TournamentStatus.completed,
      }.contains(t.status);

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _pickArtwork({required bool logo}) async {
    final picker = ref.read(tournamentArtworkPickerProvider);
    final file = logo ? await picker.pickLogo() : await picker.pickBanner();
    if (file == null || !mounted) return;
    setState(() {
      if (logo) {
        _logoFile = file;
      } else {
        _bannerFile = file;
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the tournament a longer name.')),
      );
      return;
    }

    final updates = <String, dynamic>{
      'tournament_name': name,
      'prize_details': _prize.text.trim().isEmpty ? null : _prize.text.trim(),
      if (_start != null)
        'start_date': _start!.toIso8601String().split('T').first,
      if (_end != null) 'end_date': _end!.toIso8601String().split('T').first,
    };

    final controller = ref.read(tournamentsControllerProvider.notifier);
    final ok = await controller.updateTournament(widget.tournamentId, updates);

    if (ok && (_logoFile != null || _bannerFile != null)) {
      final artworkOk = await controller.uploadArtwork(
        tournamentId: widget.tournamentId,
        banner: _bannerFile,
        logo: _logoFile,
      );
      if (!mounted) return;
      if (!artworkOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: CkColors.redInk,
            content: Text('Settings saved, but the artwork did not upload.'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Settings saved.')));
      context.pop();
    } else {
      final state = ref.read(tournamentsControllerProvider);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: CkColors.redInk,
          content: Text(state.hasError ? '${state.error}' : 'Save failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final busy = ref.watch(tournamentsControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text('Tournament settings', style: CkType.display(fontSize: 17)),
      ),
      body: tournamentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$e',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ),
        ),
        data: (t) {
          _seed(t);
          final locked = _drawLocked(t);
          final dateFmt = DateFormat('d MMM yyyy');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (locked)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CkColors.cream,
                    borderRadius: BorderRadius.circular(CkRadii.md),
                    border: Border.all(color: CkColors.creamBorder),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: CkType.body(
                        fontSize: 12.5,
                        height: 1.55,
                        color: CkColors.amberDark,
                      ),
                      children: [
                        const TextSpan(text: 'The draw is locked, so '),
                        TextSpan(
                          text: 'format, team count and seeding can no longer '
                              'change',
                          style: CkType.body(
                            fontSize: 12.5,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                            color: CkColors.amberDark,
                          ),
                        ),
                        const TextSpan(
                          text: '. Everything below is still editable.',
                        ),
                      ],
                    ),
                  ),
                ),
              if (locked) const SizedBox(height: 20),
              Text(
                'EDITABLE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                ),
              ),
              const SizedBox(height: 10),
              const _Label('Tournament name'),
              TextField(
                controller: _name,
                style: CkType.body(fontSize: 14),
                decoration: _dec('Model Town Super Cup'),
              ),
              const SizedBox(height: 16),
              const _Label('Dates'),
              Row(
                children: [
                  Expanded(
                    child: _DateBox(
                      label: 'Start',
                      value: _start == null ? 'Not set' : dateFmt.format(_start!),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateBox(
                      label: 'End',
                      value: _end == null ? 'Not set' : dateFmt.format(_end!),
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Label('Prize breakdown'),
              TextField(
                controller: _prize,
                maxLines: 3,
                style: CkType.body(fontSize: 14),
                decoration: _dec('Winner PKR 100,000 · Runner-up PKR 40,000'),
              ),
              const SizedBox(height: 16),
              const WizardLabel('Banner & logo', optional: true),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizardUploadSlot(
                    label: 'Logo',
                    width: 74,
                    preview: _logoFile != null
                        ? FileImage(_logoFile!) as ImageProvider
                        : (t.logoUrl != null
                            ? NetworkImage(t.logoUrl!)
                            : null),
                    onClear: _logoFile == null
                        ? null
                        : () => setState(() => _logoFile = null),
                    onTap: () => _pickArtwork(logo: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WizardUploadSlot(
                      label: 'Banner · 1080×420',
                      preview: _bannerFile != null
                          ? FileImage(_bannerFile!) as ImageProvider
                          : (t.bannerImageUrl != null
                              ? NetworkImage(t.bannerImageUrl!)
                              : null),
                      onClear: _bannerFile == null
                          ? null
                          : () => setState(() => _bannerFile = null),
                      onTap: () => _pickArtwork(logo: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const WizardHelper(
                'Replacing an image takes effect for everyone the next time '
                'they open the tournament.',
              ),
              const SizedBox(height: 16),
              _ReadOnlyRow(
                label: 'Grounds',
                value: t.venues.isEmpty
                    ? 'None added'
                    : '${t.venues.length} added',
              ),
              const SizedBox(height: 24),
              Text(
                locked ? 'LOCKED BY THE DRAW' : 'STRUCTURE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: locked ? CkColors.amberDark : CkColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              _ReadOnlyRow(
                label: 'Type & team count',
                value: '${t.type.label} · '
                    '${t.maxTeams ?? t.approvedTeamsCount} teams',
                locked: locked,
              ),
              _ReadOnlyRow(
                label: 'Match format',
                value: '${t.maxOvers} overs · ${t.ballType}',
                locked: locked,
              ),
              if (locked) ...[
                const SizedBox(height: 6),
                Text(
                  'Changing these mid-tournament would invalidate scorecards '
                  'already recorded.',
                  style: CkType.body(
                    fontSize: 11.5,
                    height: 1.45,
                    color: CkColors.muted,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: busy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CkColors.ink,
                  disabledBackgroundColor: CkColors.soft,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CkRadii.sm),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save changes',
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: CkType.body(fontSize: 13.5, color: CkColors.soft),
        filled: true,
        fillColor: CkColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CkRadii.sm),
          borderSide: const BorderSide(color: CkColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CkRadii.sm),
          borderSide: const BorderSide(color: CkColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CkRadii.sm),
          borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: CkType.display(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.surface,
      borderRadius: BorderRadius.circular(CkRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CkRadii.sm),
            border: Border.all(color: CkColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CkColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.value,
    this.locked = false,
  });

  final String label;
  final String value;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: locked ? CkColors.muted : CkColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CkType.body(fontSize: 12, color: CkColors.muted),
                ),
              ],
            ),
          ),
          if (locked)
            const Icon(Icons.lock_outline, size: 16, color: CkColors.amberInk),
        ],
      ),
    );
  }
}

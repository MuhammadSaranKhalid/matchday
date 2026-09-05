import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/tournaments_datasource_providers.dart';
import '../../domain/entities/ground.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../controllers/tournaments_controller.dart';
import '../widgets/ground_picker_sheet.dart';
import '../widgets/tournament_publish_dialog.dart';
import '../widgets/tournament_wizard_kit.dart';

/// The six-step create wizard, artboards 16–22.
///
/// Progressive disclosure: one decision-group per step, each step's title
/// asking a question in plain language. Validation is per-field and inline —
/// the message sits under the field, never as a toast — and Continue goes
/// inert rather than red while a step is invalid.
class TournamentCreateWizardScreen extends ConsumerStatefulWidget {
  const TournamentCreateWizardScreen({super.key});

  @override
  ConsumerState<TournamentCreateWizardScreen> createState() =>
      _TournamentCreateWizardScreenState();
}

/// One editable prize line on step 5.
class _PrizeRow {
  _PrizeRow(this.label, String amount)
      : amount = TextEditingController(text: amount);

  String label;
  final TextEditingController amount;

  void dispose() => amount.dispose();
}

class _TournamentCreateWizardScreenState
    extends ConsumerState<TournamentCreateWizardScreen> {
  static const _totalSteps = 6;
  static const _nameLimit = 100;

  int _currentStep = 0;

  // Step 1 — identity & privacy
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  TournamentPrivacy _privacy = TournamentPrivacy.public;

  // Held on device until the tournament row exists — the storage policy
  // authorises on the tournament id in the object path, so these cannot be
  // uploaded before publish.
  File? _logoFile;
  File? _bannerFile;

  // Step 2 — type & structure
  TournamentType _type = TournamentType.knockout;
  int _minTeams = 4;
  int _maxTeams = 8;
  bool _thirdPlace = false;

  // Step 3 — match format
  String _formatPreset = 'T20';
  int _perInnings = 20; // overs, or balls when the preset is The Hundred
  int _perBowler = 4;
  String _ballType = 'Leather (Red)';

  // Step 4 — schedule & venues
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _regDeadline;
  final _cityController = TextEditingController();
  final List<Ground> _grounds = [];

  // Step 5 — fees, prizes & squads
  final _feeController = TextEditingController();
  final List<_PrizeRow> _prizes = [
    _PrizeRow('Winner', ''),
    _PrizeRow('Runner up', ''),
  ];
  int _minSquad = 11;
  int _maxSquad = 16;

  /// Per-field validation messages, keyed by field name.
  final Map<String, String> _errors = {};

  /// Resolved once the auth stream emits. Null means "no signed-in user yet",
  /// in which case the draft is neither loaded nor saved: reading
  /// `currentUserStreamProvider.value` synchronously in initState races the
  /// stream and would key every early draft under a shared literal, letting a
  /// draft leak between accounts on the same device.
  String? _draftKey;
  bool _draftLoadScheduled = false;

  /// Called from build once the user is known. Awaiting the auth future in
  /// initState instead would strand a pending read if the screen is torn down
  /// first, which disposes the provider mid-load.
  void _onUserResolved(String key) {
    _draftKey = key;
    if (_draftLoadScheduled) return;
    _draftLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final draft = await ref.read(wizardDraftStoreProvider).load(key);
      if (draft != null && mounted) _restoreFromDraft(draft);
    });
  }

  /// Presets pre-fill the two numbers below them; both stay editable and the
  /// helper names the default they came from.
  static const _presets = <String, ({int perInnings, int perBowler})>{
    'T20': (perInnings: 20, perBowler: 4),
    'ODI': (perInnings: 50, perBowler: 10),
    // Balls, not overs — The Hundred is 100 balls a side, 20 per bowler.
    'The Hundred': (perInnings: 100, perBowler: 20),
    'Custom limited overs': (perInnings: 20, perBowler: 4),
  };

  bool get _isHundred => _formatPreset == 'The Hundred';
  String get _unit => _isHundred ? 'Balls' : 'Overs';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.add(const Duration(days: 7));
    _endDate = now.add(const Duration(days: 14));
    _regDeadline = now.add(const Duration(days: 5));

  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _feeController.dispose();
    for (final p in _prizes) {
      p.dispose();
    }
    super.dispose();
  }

  // ─── Draft ────────────────────────────────────────────────────────────────

  void _restoreFromDraft(Map<String, dynamic> d) {
    setState(() {
      _currentStep = (d['step'] as int? ?? 0).clamp(0, _totalSteps - 1);
      _nameController.text = d['name'] as String? ?? '';
      _descController.text = d['description'] as String? ?? '';
      _cityController.text = d['city'] as String? ?? '';
      _feeController.text = d['fee'] as String? ?? '';

      if (d['privacy'] != null) {
        _privacy = TournamentPrivacy.fromWire(d['privacy'] as String);
      }
      if (d['type'] != null) _type = TournamentType.fromWire(d['type'] as String);
      _minTeams = d['minTeams'] as int? ?? _minTeams;
      _maxTeams = d['maxTeams'] as int? ?? _maxTeams;
      _thirdPlace = d['thirdPlace'] as bool? ?? _thirdPlace;

      _formatPreset = d['formatPreset'] as String? ?? _formatPreset;
      _perInnings = d['perInnings'] as int? ?? _perInnings;
      _perBowler = d['perBowler'] as int? ?? _perBowler;
      _ballType = d['ballType'] as String? ?? _ballType;

      _startDate = _parseDate(d['startDate']);
      _endDate = _parseDate(d['endDate']);
      _regDeadline = _parseDate(d['regDeadline']);

      final grounds = d['grounds'];
      if (grounds is List) {
        _grounds
          ..clear()
          ..addAll(
            grounds.whereType<Map<String, dynamic>>().map(
                  (g) => Ground(
                    id: g['id'] as String? ?? '',
                    name: g['name'] as String? ?? 'Ground',
                    city: g['city'] as String?,
                    surface: GroundSurface.fromWire(g['surface'] as String?),
                    hasFloodlights: g['floodlights'] as bool? ?? false,
                  ),
                )
                // A draft written before grounds became rows has no id;
                // drop those rather than sending an empty FK.
                .where((g) => g.id.isNotEmpty),
          );
      }

      final prizes = d['prizes'];
      if (prizes is List && prizes.isNotEmpty) {
        for (final p in _prizes) {
          p.dispose();
        }
        _prizes
          ..clear()
          ..addAll(
            prizes.whereType<Map<String, dynamic>>().map(
                  (p) => _PrizeRow(
                    p['label'] as String? ?? 'Prize',
                    p['amount'] as String? ?? '',
                  ),
                ),
          );
      }

      _minSquad = d['minSquad'] as int? ?? _minSquad;
      _maxSquad = d['maxSquad'] as int? ?? _maxSquad;

      // Temp-directory files can be evicted between sessions, so only restore
      // what still exists on disk.
      _logoFile = _existingFile(d['logoPath']);
      _bannerFile = _existingFile(d['bannerPath']);
    });
  }

  static DateTime? _parseDate(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static File? _existingFile(Object? path) {
    if (path is! String || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<void> _persistDraft() async {
    final key = _draftKey;
    if (key == null) return;
    await ref.read(wizardDraftStoreProvider).save(key, {
      'step': _currentStep,
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'city': _cityController.text.trim(),
      'fee': _feeController.text.trim(),
      'privacy': _privacy.wire,
      'type': _type.wire,
      'minTeams': _minTeams,
      'maxTeams': _maxTeams,
      'thirdPlace': _thirdPlace,
      'formatPreset': _formatPreset,
      'perInnings': _perInnings,
      'perBowler': _perBowler,
      'ballType': _ballType,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'regDeadline': _regDeadline?.toIso8601String(),
      'grounds': _grounds
          .map((g) => {
                'id': g.id,
                'name': g.name,
                'city': g.city,
                'surface': g.surface?.wire,
                'floodlights': g.hasFloodlights,
              })
          .toList(),
      'prizes': _prizes
          .map((p) => {'label': p.label, 'amount': p.amount.text.trim()})
          .toList(),
      'minSquad': _minSquad,
      'maxSquad': _maxSquad,
      'logoPath': _logoFile?.path,
      'bannerPath': _bannerFile?.path,
    });
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Re-runs the current step's rules. Returns true when the step may advance.
  bool _validateStep() {
    final next = <String, String>{};
    final dateFmt = DateFormat('d MMM yyyy');

    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().length < 3) {
          next['name'] = 'Give your tournament a name of at least 3 characters.';
        }
      case 1:
        if (_minTeams > _maxTeams) {
          next['teams'] =
              'Minimum teams cannot be more than the maximum ($_maxTeams).';
        }
      case 2:
        if (_perInnings < 1) {
          next['perInnings'] = '$_unit per innings must be at least 1.';
        }
        if (_perBowler < 1 || _perBowler > _perInnings) {
          next['perBowler'] =
              'The bowler cap must be between 1 and $_perInnings.';
        }
      case 3:
        if (_startDate != null &&
            _endDate != null &&
            _endDate!.isBefore(_startDate!)) {
          next['endDate'] =
              'End date must be on or after the start date '
              '(${dateFmt.format(_startDate!)}).';
        }
        if (_regDeadline != null &&
            _startDate != null &&
            _regDeadline!.isAfter(_startDate!)) {
          next['regDeadline'] =
              'Registration deadline must be on or before the start date '
              '(${dateFmt.format(_startDate!)}).';
        }
      case 4:
        if (_minSquad > _maxSquad) {
          next['squad'] =
              'Minimum squad size cannot exceed the maximum ($_maxSquad).';
        }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(next);
    });
    return next.isEmpty;
  }

  /// Continue is inert while the step is invalid, so validity is recomputed on
  /// every edit rather than only on tap.
  bool get _stepIsValid {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().length >= 3;
      case 1:
        return _minTeams <= _maxTeams;
      case 2:
        return _perInnings >= 1 &&
            _perBowler >= 1 &&
            _perBowler <= _perInnings;
      case 3:
        final endOk = _startDate == null ||
            _endDate == null ||
            !_endDate!.isBefore(_startDate!);
        final regOk = _startDate == null ||
            _regDeadline == null ||
            !_regDeadline!.isAfter(_startDate!);
        return endOk && regOk;
      case 4:
        return _minSquad <= _maxSquad;
      default:
        return true;
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (!_validateStep()) return;
    await _persistDraft();
    if (!mounted) return;

    if (_currentStep < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      setState(() {
        _currentStep++;
        _errors.clear();
      });
    } else {
      await _publish();
    }
  }

  void _back() {
    if (_currentStep == 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep--;
      _errors.clear();
    });
    _persistDraft();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = step;
      _errors.clear();
    });
  }

  Future<void> _close() async {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _saveAndExit() async {
    await _persistDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved. Resume it from Home.')),
    );
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  // ─── Publish ──────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    final confirmed = await showPublishTournamentDialog(
      context,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      registrationDeadline: _regDeadline,
    );
    if (confirmed != true || !mounted) return;

    final params = CreateTournamentParams(
      name: _nameController.text.trim(),
      type: _type,
      privacy: _privacy,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      format: {
        // The Hundred is balls-based; everything else is overs.
        if (_isHundred) ...{
          'balls_per_innings': _perInnings,
          'max_balls_per_bowler': _perBowler,
          'balls_per_over': 5,
        } else ...{
          'max_overs': _perInnings,
          'max_overs_per_bowler': _perBowler,
        },
        'format_preset': _formatPreset,
        'ball_type': _ballType,
      },
      rules: {
        'min_squad': _minSquad,
        'max_squad': _maxSquad,
        'third_place_match': _thirdPlace,
        'prizes': _prizes
            .where((p) => p.amount.text.trim().isNotEmpty)
            .map((p) => {'label': p.label, 'amount': p.amount.text.trim()})
            .toList(),
      },
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _regDeadline,
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      groundIds: _grounds.map((g) => g.id).toList(),
      // Mirrored so older reads of `tournaments.venues` keep working while
      // the column is deprecated.
      venues: _grounds
          .map((g) => TournamentVenue(name: g.name, city: g.city))
          .toList(),
      prizeDetails: _prizeSummary(),
      entryFee: double.tryParse(_feeController.text.trim()),
      minTeams: _minTeams,
      maxTeams: _maxTeams,
    );

    final controller = ref.read(tournamentsControllerProvider.notifier);
    final tournament = await controller.createTournament(params);
    if (tournament == null || !mounted) {
      if (mounted) _showFailure();
      return;
    }

    final published = await controller.publishTournament(tournament.id);
    if (!mounted) return;
    if (!published) {
      _showFailure();
      return;
    }

    // Artwork goes up only now: the storage policy authorises on
    // `is_tournament_organizer(<first path segment>::uuid)`, so the folder has
    // to be a tournament that already exists. Running it after publish rather
    // than before also keeps a failed upload from poisoning the error state
    // that `_showFailure` reads — the cup is live either way, and matchday
    // falls back to the seam pattern when there is no banner.
    if (_logoFile != null || _bannerFile != null) {
      await controller.uploadArtwork(
        tournamentId: tournament.id,
        banner: _bannerFile,
        logo: _logoFile,
      );
      if (!mounted) return;
    }

    final key = _draftKey;
    if (key != null) await ref.read(wizardDraftStoreProvider).clear(key);
    if (!mounted) return;

    // Artboard 22 replaces the wizard rather than stacking on it — the wizard
    // is finished, and Back from here should not re-enter step 6.
    context.pushReplacement(
      '/tournaments/${tournament.id}/published',
    );
  }

  void _showFailure() {
    final state = ref.read(tournamentsControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CkColors.redInk,
        content: Text(
          state.hasError ? '${state.error}' : 'Could not publish. Try again.',
        ),
      ),
    );
  }

  String? _prizeSummary() {
    final filled =
        _prizes.where((p) => p.amount.text.trim().isNotEmpty).toList();
    if (filled.isEmpty) return null;
    return filled.map((p) => '${p.label}: ${p.amount.text.trim()}').join(' · ');
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  static const _titles = [
    'Name your tournament',
    'How will it be played?',
    'Match format',
    'When and where',
    'Money and squads',
    'Check it over',
  ];

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(tournamentsControllerProvider).isLoading;

    final user = ref.watch(currentUserStreamProvider).value;
    if (user != null) {
      final key = 'tournament_create:${user.id.value}';
      if (key != _draftKey) _onUserResolved(key);
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            WizardNavBar(onClose: _close, onSaveAndExit: _saveAndExit),
            WizardStepHeader(
              step: _currentStep + 1,
              totalSteps: _totalSteps,
              title: _titles[_currentStep],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _stepBody(),
              ),
            ),
            WizardFooter(
              onBack: _currentStep == 0 ? null : _back,
              onContinue: _stepIsValid ? _next : null,
              continueLabel: _currentStep == _totalSteps - 1
                  ? 'Publish tournament'
                  : 'Continue',
              showChevron: _currentStep != _totalSteps - 1,
              busy: busy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() => switch (_currentStep) {
        0 => _step1Identity(),
        1 => _step2Structure(),
        2 => _step3Format(),
        3 => _step4Schedule(),
        4 => _step5Money(),
        _ => _step6Review(),
      };

  // ─── Step 1 · Identity & privacy (artboard 16) ────────────────────────────

  Widget _step1Identity() {
    final len = _nameController.text.characters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardLabel('Tournament name'),
        const SizedBox(height: 6),
        WizardTextField(
          controller: _nameController,
          hint: 'Model Town Super Cup 2026',
          maxLength: _nameLimit,
          hasError: _errors.containsKey('name'),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() => _errors.remove('name')),
        ),
        if (_errors['name'] != null)
          WizardFieldError(_errors['name']!)
        else ...[
          const SizedBox(height: 6),
          WizardHelper(
            'Shown on every fixture and share card.',
            counter: '$len / $_nameLimit',
          ),
        ],
        const SizedBox(height: 14),
        const WizardLabel('Description', optional: true),
        const SizedBox(height: 6),
        WizardTextField(
          controller: _descController,
          hint: 'Eight clubs, two grounds, one weekend. '
              'Floodlit finals at Model Town Ground.',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        const WizardLabel('Who can find it'),
        const SizedBox(height: 8),
        // Two cards, not a switch: each choice needs a sentence of consequence.
        WizardChoiceCard(
          radioLeading: true,
          selected: _privacy == TournamentPrivacy.public,
          title: 'Public',
          subtitle: 'Listed in Explore and search. Any manager nearby can '
              'apply to register a team.',
          onTap: () => setState(() => _privacy = TournamentPrivacy.public),
        ),
        const SizedBox(height: 8),
        WizardChoiceCard(
          radioLeading: true,
          selected: _privacy == TournamentPrivacy.private,
          title: 'Private · invite only',
          subtitle: 'Hidden everywhere. Only teams you send the link to '
              'can join.',
          onTap: () => setState(() => _privacy = TournamentPrivacy.private),
        ),
        const SizedBox(height: 14),
        const WizardLabel('Artwork', optional: true),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WizardUploadSlot(
              label: 'Logo',
              width: 74,
              preview: _logoFile == null ? null : FileImage(_logoFile!),
              onClear: _logoFile == null
                  ? null
                  : () => setState(() => _logoFile = null),
              onTap: () => _pickArtwork(logo: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: WizardUploadSlot(
                label: 'Banner · 1080×420',
                preview: _bannerFile == null ? null : FileImage(_bannerFile!),
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
          'Skip these and matchday draws a seam-pattern banner from your '
          'tournament name.',
        ),
      ],
    );
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
    await _persistDraft();
  }

  // ─── Step 2 · Type & structure (artboard 17) ──────────────────────────────

  Widget _step2Structure() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Each card carries a hairline mini-diagram, because "round robin"
        // means nothing to a first-time organiser.
        WizardChoiceCard(
          selected: _type == TournamentType.knockout,
          leading: const _StructureDiagram.knockout(),
          title: 'Knockout',
          subtitle: 'Lose once and you are out. Fastest — '
              '8 teams finish in 7 matches.',
          onTap: () => setState(() => _type = TournamentType.knockout),
        ),
        const SizedBox(height: 8),
        WizardChoiceCard(
          selected: _type == TournamentType.roundRobin,
          leading: const _StructureDiagram.roundRobin(),
          title: 'Round Robin',
          subtitle: 'Everyone plays everyone once. Fairest, but '
              '8 teams means 28 matches.',
          onTap: () => setState(() => _type = TournamentType.roundRobin),
        ),
        const SizedBox(height: 8),
        WizardChoiceCard(
          selected: _type == TournamentType.league,
          leading: const _StructureDiagram.league(),
          title: 'League + Playoffs',
          subtitle: 'Points table over the season, top 4 advance to '
              'semi-finals.',
          onTap: () => setState(() => _type = TournamentType.league),
        ),
        const SizedBox(height: 8),
        const WizardComingSoonCard(title: 'Group + Knockout'),
        const SizedBox(height: 8),
        const WizardComingSoonCard(title: 'Double Elimination'),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('Min teams'),
                  const SizedBox(height: 6),
                  WizardStepper(
                    value: _minTeams,
                    min: 2,
                    max: 64,
                    onChanged: (v) => setState(() {
                      _minTeams = v;
                      _errors.remove('teams');
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('Max teams'),
                  const SizedBox(height: 6),
                  WizardStepper(
                    value: _maxTeams,
                    min: 2,
                    max: 64,
                    onChanged: (v) => setState(() {
                      _maxTeams = v;
                      _errors.remove('teams');
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_errors['teams'] != null) WizardFieldError(_errors['teams']!),
        const SizedBox(height: 14),
        _ToggleRow(
          title: '3rd place playoff',
          subtitle: 'One extra match between the losing semi-finalists.',
          value: _thirdPlace,
          onChanged: (v) => setState(() => _thirdPlace = v),
        ),
      ],
    );
  }

  // ─── Step 3 · Match format (artboard 18) ──────────────────────────────────

  Widget _step3Format() {
    final preset = _presets[_formatPreset]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardLabel('Format'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in _presets.keys)
              WizardChip(
                label: name,
                selected: _formatPreset == name,
                onTap: () => setState(() {
                  _formatPreset = name;
                  final p = _presets[name]!;
                  _perInnings = p.perInnings;
                  _perBowler = p.perBowler;
                  _errors.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        WizardHelper(
          _formatPreset == 'Custom limited overs'
              ? 'Set the overs and the bowler cap to match your ground rules.'
              : '$_formatPreset sets ${preset.perInnings} '
                  '${_isHundred ? 'balls' : 'overs'} a side and caps every '
                  'bowler at ${preset.perBowler}'
                  '${_isHundred ? ' balls' : ''}. Change either below if your '
                  'ground rules differ.',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizardLabel('$_unit / innings'),
                  const SizedBox(height: 6),
                  WizardStepper(
                    value: _perInnings,
                    min: 1,
                    max: _isHundred ? 200 : 90,
                    step: _isHundred ? 5 : 1,
                    onChanged: (v) => setState(() {
                      _perInnings = v;
                      _errors.clear();
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('Max / bowler'),
                  const SizedBox(height: 6),
                  WizardStepper(
                    value: _perBowler,
                    min: 1,
                    max: _perInnings,
                    onChanged: (v) => setState(() {
                      _perBowler = v;
                      _errors.clear();
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_errors['perInnings'] != null)
          WizardFieldError(_errors['perInnings']!)
        else if (_errors['perBowler'] != null)
          WizardFieldError(_errors['perBowler']!)
        else ...[
          const SizedBox(height: 6),
          WizardHelper(_bowlerCapHelper()),
        ],
        const SizedBox(height: 16),
        const WizardLabel('Ball'),
        const SizedBox(height: 8),
        for (final ball in const [
          ('Leather (Red)', 'Daytime cricket. Standard for club competition.'),
          ('Leather (White)', 'Floodlit matches and coloured kit.'),
          ('Tape Ball', 'Street and night cricket. Kept in its own stats bucket.'),
        ]) ...[
          WizardChoiceCard(
            selected: _ballType == ball.$1,
            title: ball.$1,
            subtitle: ball.$2,
            onTap: () => setState(() => _ballType = ball.$1),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        WizardSummaryBlock(
          eyebrow: 'Your match will run',
          headline: '$_perInnings ${_isHundred ? 'balls' : 'overs'} a side · '
              'max $_perBowler per bowler · $_ballType',
          footnote: _durationEstimate(),
        ),
      ],
    );
  }

  String _bowlerCapHelper() {
    final needed = (_perInnings / _perBowler).ceil();
    final unit = _isHundred ? 'balls' : 'overs';
    if (_formatPreset == 'Custom limited overs') {
      return 'Needs at least $needed bowlers per side.';
    }
    return '$_formatPreset default ($_perInnings $unit, $_perBowler per '
        'bowler) — needs at least $needed bowlers per side.';
  }

  /// Rough time on the ground: ~4.2 min an over both innings, plus a 15-minute
  /// break. Deliberately approximate — the canvas says "About".
  String _durationEstimate() {
    final overs = _isHundred ? _perInnings / 5 : _perInnings;
    final minutes = (overs * 2 * 4.2).round() + 15;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final parts = [
      if (h > 0) '$h hour${h == 1 ? '' : 's'}',
      if (m > 0) '$m minutes',
    ];
    return 'About ${parts.join(' ')} including the innings break.';
  }

  // ─── Step 4 · Schedule & venues (artboard 19) ─────────────────────────────

  Widget _step4Schedule() {
    final fmt = DateFormat('d MMM yy');
    final fmtLong = DateFormat('d MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('Start date'),
                  const SizedBox(height: 6),
                  WizardPickerField(
                    icon: Icons.calendar_today_outlined,
                    value: _startDate == null ? '—' : fmt.format(_startDate!),
                    onTap: () => _pickDate(
                      initial: _startDate,
                      onPicked: (d) => setState(() {
                        _startDate = d;
                        _errors.clear();
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('End date'),
                  const SizedBox(height: 6),
                  WizardPickerField(
                    icon: Icons.calendar_today_outlined,
                    hasError: _errors.containsKey('endDate'),
                    value: _endDate == null ? '—' : fmt.format(_endDate!),
                    onTap: () => _pickDate(
                      initial: _endDate,
                      onPicked: (d) => setState(() {
                        _endDate = d;
                        _errors.clear();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_errors['endDate'] != null) WizardFieldError(_errors['endDate']!),
        const SizedBox(height: 14),
        const WizardLabel('Registration deadline'),
        const SizedBox(height: 6),
        WizardPickerField(
          icon: Icons.calendar_today_outlined,
          hasError: _errors.containsKey('regDeadline'),
          value: _regDeadline == null ? '—' : fmtLong.format(_regDeadline!),
          onTap: () => _pickDate(
            initial: _regDeadline,
            onPicked: (d) => setState(() {
              _regDeadline = d;
              _errors.clear();
            }),
          ),
        ),
        if (_errors['regDeadline'] != null)
          WizardFieldError(_errors['regDeadline']!),
        const SizedBox(height: 14),
        const WizardLabel('City'),
        const SizedBox(height: 6),
        WizardTextField(
          controller: _cityController,
          hint: 'Lahore, Punjab',
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        WizardLabel(
          'Grounds',
          trailing: _grounds.isEmpty ? 'none yet' : '${_grounds.length} added',
        ),
        const SizedBox(height: 6),
        WizardListCard(
          children: [
            for (var i = 0; i < _grounds.length; i++)
              _GroundRow(
                index: i,
                ground: _grounds[i],
                onRemove: () => setState(() => _grounds.removeAt(i)),
              ),
            _AddRow(label: 'Add another ground', onTap: _addGround),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _addGround() async {
    final city = _cityController.text.trim();
    final ground = await showGroundPickerSheet(
      context,
      city: city.isEmpty ? null : city,
    );
    if (ground == null || !mounted) return;

    if (_grounds.any((g) => g.id == ground.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ground.name} is already on the list.')),
      );
      return;
    }

    setState(() => _grounds.add(ground));
    await _persistDraft();
  }

  // ─── Step 5 · Fees, prizes & squad (artboard 20) ──────────────────────────

  Widget _step5Money() {
    final money = NumberFormat.decimalPattern();
    final total = _prizes.fold<int>(
      0,
      (sum, p) => sum + (int.tryParse(p.amount.text.trim()) ?? 0),
    );
    final fee = int.tryParse(_feeController.text.trim()) ?? 0;
    final collected = fee * _maxTeams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardLabel('Entry fee per team'),
        const SizedBox(height: 6),
        WizardMoneyField(
          controller: _feeController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        // The disclaimer sits directly under the fee field, before any prize
        // input — an organiser must read it while typing the number.
        const WizardCreamNote(
          eyebrow: 'Collected offline',
          body: 'matchday does not process payments. You collect cash or bank '
              'transfers yourself and tap Mark Paid on each team in the '
              'console.',
          bold: 'Mark Paid',
        ),
        const SizedBox(height: 16),
        const WizardLabel('Prize breakdown', optional: true),
        const SizedBox(height: 6),
        WizardListCard(
          children: [
            for (var i = 0; i < _prizes.length; i++)
              _PrizeRowTile(
                row: _prizes[i],
                onChanged: () => setState(() {}),
                onRemove: _prizes.length <= 1
                    ? null
                    : () => setState(() {
                          _prizes.removeAt(i).dispose();
                        }),
              ),
            _AddRow(
              label: 'Add a prize',
              trailing: 'Trophy only?',
              onTap: () => setState(
                () => _prizes.add(_PrizeRow('Prize ${_prizes.length + 1}', '')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WizardSummaryBlock(
          eyebrow: 'Total pool',
          headline: 'PKR ${money.format(total)}',
          footnote: fee == 0
              ? 'Free entry — the pool comes from your sponsors.'
              : '$_maxTeams teams at PKR ${money.format(fee)} collects '
                  'PKR ${money.format(collected)}'
                  '${total > collected ? ' — the rest comes from your sponsors.' : '.'}',
        ),
        const SizedBox(height: 16),
        const WizardLabel('Squad size'),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('Min'),
                  const SizedBox(height: 6),
                  WizardStepper(
                    value: _minSquad,
                    min: 2,
                    max: 30,
                    onChanged: (v) => setState(() {
                      _minSquad = v;
                      _errors.remove('squad');
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardLabel('Max'),
                  const SizedBox(height: 6),
                  WizardStepper(
                    value: _maxSquad,
                    min: 2,
                    max: 30,
                    onChanged: (v) => setState(() {
                      _maxSquad = v;
                      _errors.remove('squad');
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_errors['squad'] != null)
          WizardFieldError(_errors['squad']!)
        else ...[
          const SizedBox(height: 6),
          const WizardHelper(
            'Managers can name unclaimed guest players to reach the minimum.',
          ),
        ],
      ],
    );
  }

  // ─── Step 6 · Review & publish (artboard 21) ──────────────────────────────

  Widget _step6Review() {
    final money = NumberFormat.decimalPattern();
    final dateFmt = DateFormat('d MMM');
    final dateFmtY = DateFormat('d MMM yyyy');
    final name = _nameController.text.trim();
    final initials = name.isEmpty
        ? '??'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.characters.first)
            .join()
            .toUpperCase();

    final total = _prizes.fold<int>(
      0,
      (sum, p) => sum + (int.tryParse(p.amount.text.trim()) ?? 0),
    );
    final fee = int.tryParse(_feeController.text.trim()) ?? 0;

    final schedule = _startDate == null || _endDate == null
        ? 'Dates not set'
        : '${dateFmt.format(_startDate!)} – ${dateFmtY.format(_endDate!)}'
            '${_cityController.text.trim().isEmpty ? '' : ' · ${_cityController.text.trim()}'}';
    final scheduleSub = [
      if (_regDeadline != null)
        'Registration closes ${dateFmt.format(_regDeadline!)}',
      if (_grounds.isNotEmpty) _grounds.map((g) => g.name).join(', '),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardListCard(
          children: [
            // Every group is editable in place — review is never a dead end.
            _ReviewIdentity(
              initials: initials,
              name: name.isEmpty ? 'Untitled tournament' : name,
              subtitle: '${_privacy == TournamentPrivacy.public ? 'Public' : 'Private'}'
                  '${_cityController.text.trim().isEmpty ? '' : ' · ${_cityController.text.trim()}'}',
              onEdit: () => _goToStep(0),
            ),
            _ReviewGroup(
              title: 'Structure',
              onEdit: () => _goToStep(1),
              pairs: [
                (
                  'Type',
                  '${_type.label}${_thirdPlace ? ' + 3rd place' : ''}',
                  false
                ),
                ('Teams', '$_minTeams – $_maxTeams', true),
                ('Format', '$_formatPreset · $_ballType', false),
                (
                  _isHundred ? 'Balls · bowler cap' : 'Overs · bowler cap',
                  '$_perInnings · $_perBowler',
                  true
                ),
              ],
            ),
            _ReviewGroup(
              title: 'Schedule',
              onEdit: () => _goToStep(3),
              lines: [schedule, if (scheduleSub.isNotEmpty) scheduleSub],
            ),
            _ReviewGroup(
              title: 'Money & squads',
              onEdit: () => _goToStep(4),
              lines: [
                fee == 0
                    ? 'Free entry'
                    : 'PKR ${money.format(fee)} entry · collected offline',
                'Prize pool PKR ${money.format(total)} · '
                    'squads of $_minSquad–$_maxSquad',
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        WizardSummaryBlock(
          eyebrow: 'What happens when you publish',
          headline: _privacy == TournamentPrivacy.public
              ? 'The cup appears in Explore and managers can start applying.'
              : 'Only teams you send the link to can see and join the cup.',
          footnote: 'Fixtures are generated later, once you approve teams and '
              'lock the draw.',
        ),
      ],
    );
  }
}

// ─── Local pieces ────────────────────────────────────────────────────────────

/// Hairline mini-diagrams for the structure cards: a bracket, a mesh, a table.
class _StructureDiagram extends StatelessWidget {
  const _StructureDiagram.knockout() : _kind = 0;
  const _StructureDiagram.roundRobin() : _kind = 1;
  const _StructureDiagram.league() : _kind = 2;

  final int _kind;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 40,
        height: 38,
        child: CustomPaint(painter: _StructurePainter(_kind)),
      );
}

class _StructurePainter extends CustomPainter {
  const _StructurePainter(this.kind);

  final int kind;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = CkColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final soft = Paint()
      ..color = CkColors.soft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    RRect box(double x, double y, double w, double h) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(1.5));

    switch (kind) {
      case 0: // bracket
        canvas
          ..drawRRect(box(0, 2, 13, 6), ink)
          ..drawRRect(box(0, 14, 13, 6), ink)
          ..drawRRect(box(0, 26, 13, 6), ink)
          ..drawRRect(box(22, 8, 13, 6), ink)
          ..drawRRect(box(22, 23, 13, 6), ink)
          ..drawLine(const Offset(13, 5), const Offset(18, 5), soft)
          ..drawLine(const Offset(18, 5), const Offset(18, 11), soft)
          ..drawLine(const Offset(18, 11), const Offset(22, 11), soft)
          ..drawLine(const Offset(13, 17), const Offset(18, 17), soft)
          ..drawLine(const Offset(13, 29), const Offset(22, 29), soft);
      case 1: // mesh — everyone plays everyone
        const c = Offset(20, 19);
        canvas.drawCircle(c, 13, soft);
        final nodes = [
          const Offset(20, 6),
          const Offset(31, 25),
          const Offset(9, 25),
        ];
        for (final n in nodes) {
          canvas.drawCircle(n, 3, ink);
        }
        for (var i = 0; i < nodes.length; i++) {
          for (var j = i + 1; j < nodes.length; j++) {
            canvas.drawLine(nodes[i], nodes[j], soft);
          }
        }
      default: // table
        for (var i = 0; i < 4; i++) {
          final y = 4.0 + i * 8;
          canvas
            ..drawLine(Offset(2, y), Offset(38, y), i == 0 ? ink : soft)
            ..drawRRect(box(2, y + 2, 8, 4), i < 2 ? ink : soft);
        }
    }
  }

  @override
  bool shouldRepaint(_StructurePainter old) => old.kind != kind;
}

/// Label + consequence + switch, in a hairline card.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
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
                    fontSize: 11.5,
                    height: 1.45,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: CkColors.paper,
            activeTrackColor: CkColors.ink,
          ),
        ],
      ),
    );
  }
}

class _GroundRow extends StatelessWidget {
  const _GroundRow({
    required this.index,
    required this.ground,
    required this.onRemove,
  });

  final int index;
  final Ground ground;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Text(
            'G${index + 1}',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ground.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ground.facilities != null)
                  Text(
                    ground.facilities!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 15, color: CkColors.muted),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove ${ground.name}',
          ),
        ],
      ),
    );
  }
}

class _PrizeRowTile extends StatelessWidget {
  const _PrizeRowTile({
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final _PrizeRow row;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          WizardMoneyField(
            controller: row.amount,
            compact: true,
            onChanged: (_) => onChanged(),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 15, color: CkColors.muted),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove ${row.label}',
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, required this.onTap, this.trailing});

  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.add, size: 15, color: CkColors.ink),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: CkType.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: CkType.body(fontSize: 12, color: CkColors.soft),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewIdentity extends StatelessWidget {
  const _ReviewIdentity({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.onEdit,
  });

  final String initials;
  final String name;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: CkType.display(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: CkType.display(fontSize: 17, height: 1.2),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _EditLink(onTap: onEdit),
        ],
      ),
    );
  }
}

class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({
    required this.title,
    required this.onEdit,
    this.pairs = const [],
    this.lines = const [],
  });

  final String title;
  final VoidCallback onEdit;

  /// (label, value, mono)
  final List<(String, String, bool)> pairs;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                  ),
                ),
              ),
              _EditLink(onTap: onEdit),
            ],
          ),
          if (pairs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              children: [
                for (final p in pairs)
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.$1,
                            style: CkType.body(
                              fontSize: 11,
                              color: CkColors.muted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            p.$2,
                            style: p.$3
                                ? CkType.mono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                    color: CkColors.ink,
                                  )
                                : CkType.display(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          for (final line in lines) ...[
            const SizedBox(height: 5),
            Text(
              line,
              style: CkType.body(
                fontSize: 12.5,
                height: 1.45,
                color: CkColors.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          'Edit',
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CkColors.ink2,
          ),
        ),
      ),
    );
  }
}

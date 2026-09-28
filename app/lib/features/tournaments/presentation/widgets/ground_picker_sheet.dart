import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/ground.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';
import 'tournament_wizard_kit.dart';

/// Picks a ground for a tournament, or creates one.
///
/// Search comes first deliberately: grounds are global, so the duplicate risk
/// is real ("Model Town Ground" vs "model town ground"). Showing existing
/// matches before offering "Add" is the cheap version of de-duplication —
/// the same posture team search already takes.
Future<Ground?> showGroundPickerSheet(
  BuildContext context, {
  String? city,
}) {
  return showModalBottomSheet<Ground>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: CkColors.ink.withValues(alpha: 0.32),
    builder: (_) => _GroundPickerSheet(city: city),
  );
}

class _GroundPickerSheet extends ConsumerStatefulWidget {
  const _GroundPickerSheet({this.city});

  final String? city;

  @override
  ConsumerState<_GroundPickerSheet> createState() => _GroundPickerSheetState();
}

class _GroundPickerSheetState extends ConsumerState<_GroundPickerSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  String _submitted = '';

  @override
  void initState() {
    super.initState();
    _query.addListener(_onTyped);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// Debounced so a provider is not created per keystroke.
  void _onTyped() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _submitted = _query.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final typed = _query.text.trim();
    final results = ref.watch(
      groundSearchProvider(query: _submitted.isEmpty ? null : _submitted),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a ground', style: CkType.display(fontSize: 19)),
                    const SizedBox(height: 4),
                    Text(
                      'Search first — most grounds are already here.',
                      style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                    ),
                    const SizedBox(height: 14),
                    WizardTextField(
                      controller: _query,
                      hint: 'Model Town Ground',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Flexible(
                child: results.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    child: Text(
                      '$e',
                      style:
                          CkType.body(fontSize: 12.5, color: CkColors.muted),
                    ),
                  ),
                  data: (grounds) => _Results(
                    grounds: grounds,
                    typed: typed,
                    onPick: (g) => Navigator.pop(context, g),
                    onCreate: () => _create(typed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(String name) async {
    final created = await showDialog<Ground>(
      context: context,
      builder: (_) => _NewGroundDialog(name: name, city: widget.city),
    );
    if (created != null && mounted) Navigator.pop(context, created);
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.grounds,
    required this.typed,
    required this.onPick,
    required this.onCreate,
  });

  final List<Ground> grounds;
  final String typed;
  final ValueChanged<Ground> onPick;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    // Only offer creation once something has been typed — an empty query
    // lists nearby grounds, and "Add ''" is meaningless.
    final canCreate = typed.length >= 2;
    final exactExists = grounds.any(
      (g) => g.name.toLowerCase() == typed.toLowerCase(),
    );

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 14),
      children: [
        if (grounds.isEmpty && !canCreate)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Text(
              'No grounds yet. Type a name to add the first one.',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.muted,
              ),
            ),
          ),
        for (final g in grounds)
          ListTile(
            onTap: () => onPick(g),
            title: Text(
              g.name,
              style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (g.city != null) g.city!,
                if (g.facilities != null) g.facilities!,
                if (g.distanceKm != null)
                  '${g.distanceKm!.toStringAsFixed(g.distanceKm! < 10 ? 1 : 0)} km',
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 11.5, color: CkColors.muted),
            ),
            trailing: const Icon(Icons.chevron_right,
                size: 18, color: CkColors.soft),
          ),
        if (canCreate && !exactExists) ...[
          if (grounds.isNotEmpty) const WizardDivider(),
          ListTile(
            onTap: onCreate,
            leading: const Icon(Icons.add, size: 18, color: CkColors.ink),
            title: Text(
              'Add "$typed"',
              style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              grounds.isEmpty
                  ? 'Create it as a new ground'
                  : 'Only if none of the above is the same place',
              style: CkType.body(fontSize: 11.5, color: CkColors.muted),
            ),
          ),
        ],
      ],
    );
  }
}

/// Captures the facilities the wizard used to throw into free text.
class _NewGroundDialog extends ConsumerStatefulWidget {
  const _NewGroundDialog({required this.name, this.city});

  final String name;
  final String? city;

  @override
  ConsumerState<_NewGroundDialog> createState() => _NewGroundDialogState();
}

class _NewGroundDialogState extends ConsumerState<_NewGroundDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _city = TextEditingController(text: widget.city ?? '');
  GroundSurface? _surface;
  bool _floodlights = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ground = await ref
        .read(tournamentsControllerProvider.notifier)
        .createGround(
          name: _name.text,
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          surface: _surface,
          hasFloodlights: _floodlights,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (ground == null) {
      final state = ref.read(tournamentsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CkColors.redInk,
          content: Text(
            state.hasError ? '${state.error}' : 'Could not add that ground.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(context, ground);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CkColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CkRadii.md),
      ),
      title: Text('New ground', style: CkType.display(fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WizardLabel('Name'),
            const SizedBox(height: 6),
            WizardTextField(
              controller: _name,
              hint: 'Model Town Ground',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            const WizardLabel('City'),
            const SizedBox(height: 6),
            WizardTextField(
              controller: _city,
              hint: 'Lahore',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            const WizardLabel('Surface', optional: true),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in GroundSurface.values)
                  WizardChip(
                    label: s.label,
                    selected: _surface == s,
                    onTap: () => setState(
                      () => _surface = _surface == s ? null : s,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _floodlights,
              onChanged: (v) => setState(() => _floodlights = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: CkColors.paper,
              activeTrackColor: CkColors.ink,
              title: Text(
                'Floodlights',
                style: CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Can this ground host night matches?',
                style: CkType.body(fontSize: 11.5, color: CkColors.muted),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: CkColors.ink),
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add ground', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

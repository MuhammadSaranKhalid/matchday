import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/team_name.dart';
import '../providers/teams_providers.dart';

/// Shows the bottom sheet to edit team details (and upload logo).
Future<bool?> showEditTeamSheet(BuildContext context, Team team) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CkColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => EditTeamSheet(team: team),
  );
}

class EditTeamSheet extends ConsumerStatefulWidget {
  const EditTeamSheet({super.key, required this.team});
  final Team team;

  @override
  ConsumerState<EditTeamSheet> createState() => _EditTeamSheetState();
}

class _EditTeamSheetState extends ConsumerState<EditTeamSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cityController;
  late final TextEditingController _homeGroundController;
  late final TextEditingController _monogramController;

  late TeamPrivacy _privacy;
  late String _primaryColor;
  String? _currentLogoUrl;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String? _error;

  static const _presetColors = [
    '#2E7D32', // Forest Green
    '#1565C0', // Navy Blue
    '#C62828', // Crimson Red
    '#6A1B9A', // Royal Purple
    '#E65100', // Deep Orange
    '#00838F', // Teal
    '#29251E', // Pitch Black
    '#4E342E', // Brown
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    _taglineController = TextEditingController(text: widget.team.tagline ?? '');
    _descriptionController =
        TextEditingController(text: widget.team.description ?? '');
    _cityController = TextEditingController(text: widget.team.city ?? '');
    _homeGroundController =
        TextEditingController(text: widget.team.homeGround ?? '');
    _monogramController =
        TextEditingController(text: widget.team.logoMonogram ?? '');
    _privacy = widget.team.privacy;
    _primaryColor = widget.team.primaryColor ?? '#2E7D32';
    _currentLogoUrl = widget.team.logoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _homeGroundController.dispose();
    _monogramController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large (max 2 MB)')),
        );
      }
      return;
    }

    setState(() => _isUploadingLogo = true);
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final repo = ref.read(teamsRepositoryProvider);
    final res = await repo.uploadTeamLogo(
      teamId: widget.team.id,
      bytes: bytes,
      extension: ext,
    );
    if (!mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: ${f.message}')),
      ),
      (url) {
        setState(() {
          _currentLogoUrl = url;
        });
        ref.invalidate(teamProvider(widget.team.id.value));
        ref.invalidate(myTeamsProvider);
        ref.invalidate(allTeamsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team logo updated!')),
        );
      },
    );
    if (mounted) {
      setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _handleSave() async {
    final nameRes = TeamName.create(_nameController.text.trim());
    if (nameRes.isLeft()) {
      setState(() {
        _error = nameRes.getLeft().toNullable()!.message;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final repo = ref.read(teamsRepositoryProvider);
    final result = await repo.updateTeam(
      teamId: widget.team.id,
      name: nameRes.getRight().toNullable()!,
      privacy: _privacy,
      tagline: _taglineController.text.trim().isEmpty
          ? null
          : _taglineController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      homeGround: _homeGroundController.text.trim().isEmpty
          ? null
          : _homeGroundController.text.trim(),
      logoMonogram: _monogramController.text.trim().isEmpty
          ? null
          : _monogramController.text.trim().toUpperCase(),
      primaryColor: _primaryColor,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _error = failure.message;
        });
      },
      (updatedTeam) {
        ref.invalidate(teamProvider(widget.team.id.value));
        ref.invalidate(myTeamsProvider);
        ref.invalidate(allTeamsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team details updated successfully!')),
        );
      },
    );
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return CkColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Team Details',
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Logo Uploader Avatar
              Center(
                child: GestureDetector(
                  onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _parseHex(_primaryColor),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: CkColors.hairline,
                            width: 2,
                          ),
                          image:
                              (_currentLogoUrl != null &&
                                      _currentLogoUrl!.isNotEmpty)
                                  ? DecorationImage(
                                    image: NetworkImage(_currentLogoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child:
                            (_currentLogoUrl == null ||
                                    _currentLogoUrl!.isEmpty)
                                ? Text(
                                  _monogramController.text.isNotEmpty
                                      ? _monogramController.text
                                      : widget.team.name.isNotEmpty
                                      ? widget.team.name
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : 'T',
                                  style: CkType.display(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: CkColors.ink,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CkColors.surface,
                              width: 2,
                            ),
                          ),
                          child:
                              _isUploadingLogo
                                  ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                  child: Text(
                    _isUploadingLogo ? 'Uploading logo...' : 'Change Team Logo',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CkColors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CkColors.redSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CkColors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: CkType.body(fontSize: 12, color: CkColors.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Team Name
              const _FieldLabel(label: 'TEAM NAME *'),
              TextField(
                controller: _nameController,
                style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: _inputDec(hint: 'e.g. Lahore Lions'),
              ),
              const SizedBox(height: 16),

              // Tagline & Monogram
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'TAGLINE / MOTTO'),
                        TextField(
                          controller: _taglineController,
                          style: CkType.body(fontSize: 14),
                          decoration: _inputDec(hint: 'e.g. Roar with Pride'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'MONOGRAM'),
                        TextField(
                          controller: _monogramController,
                          maxLength: 3,
                          textCapitalization: TextCapitalization.characters,
                          style: CkType.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _inputDec(
                            hint: 'LL',
                          ).copyWith(counterText: ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              const _FieldLabel(label: 'ABOUT / BIO'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: CkType.body(fontSize: 14),
                decoration: _inputDec(
                  hint: 'Tell players and opponents about your squad...',
                ),
              ),
              const SizedBox(height: 16),

              // City & Home Ground
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'CITY'),
                        TextField(
                          controller: _cityController,
                          style: CkType.body(fontSize: 14),
                          decoration: _inputDec(hint: 'e.g. Lahore'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'HOME GROUND'),
                        TextField(
                          controller: _homeGroundController,
                          style: CkType.body(fontSize: 14),
                          decoration: _inputDec(hint: 'e.g. Model Town Ground'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Brand Color Palette
              const _FieldLabel(label: 'PRIMARY BRAND COLOR'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hex in _presetColors)
                    GestureDetector(
                      onTap: () => setState(() => _primaryColor = hex),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _parseHex(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _primaryColor == hex
                                    ? CkColors.ink
                                    : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child:
                            _primaryColor == hex
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                                : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Privacy Toggle
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Row(
                  children: [
                    Icon(
                      _privacy == TeamPrivacy.public
                          ? Icons.public_rounded
                          : Icons.lock_outline_rounded,
                      size: 22,
                      color: CkColors.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _privacy == TeamPrivacy.public
                                ? 'Public Team'
                                : 'Private Team',
                            style: CkType.display(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _privacy == TeamPrivacy.public
                                ? 'Visible in discovery; players can request to join'
                                : 'Hidden from discovery; invite-only roster',
                            style: CkType.body(
                              fontSize: 11,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _privacy == TeamPrivacy.public,
                      activeTrackColor: CkColors.ink,
                      onChanged: (val) {
                        setState(() {
                          _privacy =
                              val ? TeamPrivacy.public : TeamPrivacy.private;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CkButton(
                  label: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: CkType.body(fontSize: 13, color: CkColors.soft),
      filled: true,
      fillColor: CkColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CkColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CkColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

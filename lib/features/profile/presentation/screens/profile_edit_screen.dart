// Profile editor — loads the signed-in user's real profile, edits name /
// username / bio / location, lets them pick a new avatar, and saves to Supabase
// (text fields + avatar upload). Visual layout ports `V21ProfileEdit`.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/core/widgets/v2/v2_kit.dart';
import 'package:matchday/features/onboarding/presentation/providers/onboarding_providers.dart';
import '../controllers/profile_edit_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _city;

  // Seeded from the loaded profile; passed through on save so we don't wipe geo
  // or trip the username cooldown on an unchanged handle.
  String? _originalUsername;
  String? _avatarUrl;
  String? _placeId;
  double? _lat;
  double? _lng;
  String? _countryCode;

  bool _locating = false;
  int _bioLen = 0;
  String _initials = '?';

  @override
  void initState() {
    super.initState();
    final p = ref.read(myProfileProvider).value;
    _name = TextEditingController(text: p?.displayName ?? '')
      ..addListener(_recomputeInitials);
    _username = TextEditingController(text: p?.username ?? '');
    _bio = TextEditingController(text: p?.bio ?? '')..addListener(_recomputeBioLen);
    _bioLen = _bio.text.length;
    _city = TextEditingController(text: p?.city ?? '');
    _originalUsername = p?.username;
    _avatarUrl = p?.avatarUrl;
    _placeId = p?.placeId;
    _lat = p?.latitude;
    _lng = p?.longitude;
    _countryCode = p?.countryCode;
    _recomputeInitials();
  }

  void _recomputeInitials() {
    final words = _name.text.trim().split(RegExp(r'\s+'));
    final letters =
        words.where((w) => w.isNotEmpty).map((w) => w[0]).join();
    final next = letters.isEmpty
        ? '?'
        : letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
    if (next != _initials) setState(() => _initials = next);
  }

  void _recomputeBioLen() {
    if (_bio.text.length != _bioLen) setState(() => _bioLen = _bio.text.length);
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _city.text = 'Korangi, Karachi';
      _locating = false;
    });
  }

  Future<void> _save() async {
    final ok = await ref.read(profileEditControllerProvider.notifier).save(
          displayName: _name.text,
          username: _username.text,
          originalUsername: _originalUsername,
          bio: _bio.text,
          city: _city.text,
          placeId: _placeId,
          latitude: _lat,
          longitude: _lng,
          countryCode: _countryCode,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.maybePop(context);
    } else {
      final err = ref.read(profileEditControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err?.message ?? 'Could not save your profile.')),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edit = ref.watch(profileEditControllerProvider);
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _nav(context, saving: edit.saving),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatarAndName(edit.avatar),
                    const SizedBox(height: 16),
                    _usernameField(),
                    const SizedBox(height: 12),
                    _bioField(),
                    const SizedBox(height: 4),
                    _locationField(),
                    const SizedBox(height: 18),
                    _privacyNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(BuildContext context, {required bool saving}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: saving ? null : () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: V2Svg(V2Icons.chevronLeft,
                  size: 22, color: CkColors.ink, strokeWidth: 2),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'EDIT PROFILE',
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: saving ? null : _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: CkColors.paper),
                    )
                  : Text(
                      'Save',
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarAndName(File? picked) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: _avatarImage(picked),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref
                      .read(profileEditControllerProvider.notifier)
                      .pickAvatar(),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CkColors.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: CkColors.paper, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF281E0F).withValues(alpha: 0.18),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const V2Svg(V2Icons.camera,
                        size: 16, color: CkColors.ink, strokeWidth: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('NAME'),
                const SizedBox(height: 4),
                _EditField(controller: _name),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Picked file > existing avatar URL > initials.
  Widget _avatarImage(File? picked) {
    if (picked != null) {
      return Image.file(picked, width: 88, height: 88, fit: BoxFit.cover);
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsAvatar(),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() => Container(
        color: CkColors.ink,
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: CkType.display(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.03,
            color: CkColors.paper,
          ),
        ),
      );

  Widget _usernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('USERNAME'),
        const SizedBox(height: 4),
        _EditField(
          controller: _username,
          prefix: '@',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
          ],
        ),
      ],
    );
  }

  Widget _bioField() {
    final over = _bioLen > 150;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('BIO'),
        const SizedBox(height: 4),
        _EditField(controller: _bio, minLines: 3, maxLines: 5, maxLength: 200),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_bioLen / 200',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: over ? CkColors.amber : CkColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('LOCATION'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _EditField(controller: _city)),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _locating ? null : _useGps,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const V2Svg(V2Icons.pin,
                        size: 12, color: CkColors.ink2, strokeWidth: 2),
                    const SizedBox(width: 5),
                    Text(
                      _locating ? 'Locating…' : 'GPS',
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CkColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _privacyNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: CkType.body(fontSize: 11, color: CkColors.muted, height: 1.45),
          children: [
            const TextSpan(text: 'Private account toggle lives in '),
            TextSpan(
              text: 'Pavilion → Settings → Privacy',
              style: CkType.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CkColors.ink2,
                height: 1.45,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: CkType.mono(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.10,
        color: CkColors.muted,
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    this.prefix,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? prefix;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      cursorColor: CkColors.ink,
      style: CkType.body(fontSize: 14, color: CkColors.ink, height: 1.45),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: CkColors.paper,
        prefixText: prefix,
        prefixStyle: CkType.body(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CkColors.muted,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: _border(CkColors.hairline),
        enabledBorder: _border(CkColors.hairline),
        focusedBorder: _border(CkColors.hairline),
      ),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c, width: 1.0),
      );
}

// Profile editor — loads the signed-in user's real profile, edits name /
// username / bio / location, lets them pick a new avatar, and saves to Supabase
// (text fields + avatar upload). Visual layout ports `V21ProfileEdit`.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/core/widgets/v2/v2_kit.dart';
import '../controllers/profile_edit_controller.dart';
import '../state/profile_edit_state.dart';

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileEditControllerProvider);
    final ctrl = ref.read(profileEditControllerProvider.notifier);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _nav(context, ref: ref, state: state, ctrl: ctrl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatarAndName(state: state, ctrl: ctrl),
                    const SizedBox(height: 16),
                    _usernameField(state: state, ctrl: ctrl),
                    const SizedBox(height: 12),
                    _bioField(state: state, ctrl: ctrl),
                    const SizedBox(height: 4),
                    _locationField(state: state, ctrl: ctrl),
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

  Widget _nav(
    BuildContext context, {
    required WidgetRef ref,
    required ProfileEditState state,
    required ProfileEditController ctrl,
  }) {
    final saving = state.saving;
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
            onTap: saving
                ? null
                : () async {
                    final ok = await ctrl.save();
                    if (ok && context.mounted) {
                      Navigator.maybePop(context);
                    } else if (!ok && context.mounted) {
                      final err = ref.read(profileEditControllerProvider).error;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err.message)),
                        );
                      }
                    }
                  },
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

  Widget _avatarAndName({
    required ProfileEditState state,
    required ProfileEditController ctrl,
  }) {
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
                  child: _avatarImage(state),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: ctrl.pickAvatar,
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
                _EditField(
                  initialValue: state.displayName,
                  onChanged: ctrl.setDisplayName,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Picked file > existing avatar URL > initials.
  Widget _avatarImage(ProfileEditState state) {
    if (state.avatar != null) {
      return Image.file(state.avatar!, width: 88, height: 88, fit: BoxFit.cover);
    }
    if (state.currentAvatarUrl != null && state.currentAvatarUrl!.isNotEmpty) {
      return Image.network(
        state.currentAvatarUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsAvatar(state.displayName),
      );
    }
    return _initialsAvatar(state.displayName);
  }

  Widget _initialsAvatar(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).join();
    final initials = letters.isEmpty
        ? '?'
        : letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();

    return Container(
      color: CkColors.ink,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: CkType.display(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.03,
          color: CkColors.paper,
        ),
      ),
    );
  }

  Widget _usernameField({
    required ProfileEditState state,
    required ProfileEditController ctrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('USERNAME'),
        const SizedBox(height: 4),
        _EditField(
          initialValue: state.username,
          onChanged: ctrl.setUsername,
          prefix: '@',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
          ],
        ),
      ],
    );
  }

  Widget _bioField({
    required ProfileEditState state,
    required ProfileEditController ctrl,
  }) {
    final over = state.bio.length > 200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('BIO'),
        const SizedBox(height: 4),
        _EditField(
          initialValue: state.bio,
          onChanged: ctrl.setBio,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${state.bio.length} / 200',
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

  Widget _locationField({
    required ProfileEditState state,
    required ProfileEditController ctrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('LOCATION'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _EditField(
                // Use a key based on city to force update when GPS is clicked
                key: ValueKey(state.city),
                initialValue: state.city,
                onChanged: ctrl.setCity,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: ctrl.useGps,
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
                      'GPS',
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

class _EditField extends StatefulWidget {
  const _EditField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.prefix,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? prefix;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      cursorColor: CkColors.ink,
      style: CkType.body(fontSize: 14, color: CkColors.ink, height: 1.45),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: CkColors.paper,
        prefixText: widget.prefix,
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

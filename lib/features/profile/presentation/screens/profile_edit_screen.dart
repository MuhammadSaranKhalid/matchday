import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/profile_edit_controller.dart';

/// Edit profile — artboard **1a · Single scroll (recommended)**.
///
/// > Four editable things, three sections, one Save. Media sits at the top
/// > because it is what people came to change; account facts sit at the bottom
/// > because they are read-only.
///
/// Location is gone entirely — field, GPS button and label. The canvas is
/// explicit that nothing replaces it: "an edit form should hold only what a
/// person actually maintains." City is still set on teams and tournaments, and
/// [ProfileRepository.updateProfile] leaves the stored value alone when this
/// screen sends none.
///
/// Every measurement here comes from artboard 2a, the build spec drawn against
/// this screen.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;

  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileEditControllerProvider);
    _name = TextEditingController(text: s.displayName);
    _bio = TextEditingController(text: s.bio);
    for (final f in [_nameFocus, _bioFocus]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _exit() => context.canPop() ? context.pop() : context.go('/profile');

  /// "Back with edits opens the discard dialog; back with none exits
  /// silently." — artboard 2a.
  Future<void> _handleBack() async {
    if (!ref.read(profileEditControllerProvider).dirty) return _exit();
    final discard = await showDiscardChangesDialog(context);
    if (discard == true && mounted) _exit();
  }

  void _toast(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final ok = await ref.read(profileEditControllerProvider.notifier).save();
    if (!mounted) return;
    if (ok) {
      // "pops back to the profile — no success screen".
      _exit();
      return;
    }
    final failure = ref.read(profileEditControllerProvider).error;
    if (failure != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileEditControllerProvider);
    final c = ref.read(profileEditControllerProvider.notifier);
    final email = ref.watch(currentUserStreamProvider).value?.email.value ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: CkColors.paper,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppBar(
                onBack: _handleBack,
                canSave: s.canSave,
                saving: s.saving,
                onSave: _save,
              ),
              Container(height: 1, color: CkColors.hairline),
              Expanded(
                child: AbsorbPointer(
                  // "screen stays interactive-locked" while the save is away.
                  absorbing: s.saving,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      _Media(
                        coverUrl: s.currentCoverUrl,
                        cover: s.cover,
                        avatarUrl: s.currentAvatarUrl,
                        avatar: s.avatar,
                        initials: _initials(s.displayName),
                        onCover: c.pickCover,
                        onAvatar: c.pickAvatar,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Group(
                              header: 'Identity',
                              children: [
                                _Labelled(
                                  label: 'Name',
                                  error: s.nameError,
                                  child: _FieldBox(
                                    focused: _nameFocus.hasFocus,
                                    error: s.nameError != null,
                                    child: _PlainField(
                                      controller: _name,
                                      focusNode: _nameFocus,
                                      hint: 'Your name',
                                      onChanged: c.setDisplayName,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                ),
                                // ── Username: LOCKED for now ─────────────────────────────
                                // Editing lands next phase. The controller keeps its live
                                // availability check and 400ms debounce, and their tests —
                                // only this field and the chip are switched off, so turning
                                // it back on is swapping the two blocks below.
                                _Labelled(
                                  label: 'Username',
                                  helper:
                                      'Username changes are coming in a later '
                                      'update.',
                                  child: _LockedField(
                                    value: '@${s.username}',
                                    onTap:
                                        () => _toast(
                                          context,
                                          "You can't change your username yet",
                                        ),
                                  ),
                                ),
                                // NEXT PHASE — restore this in place of the locked field
                                // above. Needs `_username` + `_usernameFocus` back in the
                                // State, the `padding` argument on _FieldBox, and the
                                // profile_edit_state.dart import for UsernameStatus.
                                //
                                // _Labelled(
                                //   label: 'Username',
                                //   error: s.usernameError,
                                //   helper: 'Changeable once every '
                                //       '$usernameCooldownDays days.',
                                //   child: _FieldBox(
                                //     focused: _usernameFocus.hasFocus,
                                //     error: s.usernameError != null,
                                //     padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
                                //     child: Row(
                                //       children: [
                                //         Text('@', style: CkType.body(
                                //             fontSize: 15, color: CkColors.muted)),
                                //         const SizedBox(width: 2),
                                //         Expanded(
                                //           child: _PlainField(
                                //             controller: _username,
                                //             focusNode: _usernameFocus,
                                //             hint: 'username',
                                //             onChanged: c.setUsername,
                                //           ),
                                //         ),
                                //         if (s.usernameStatus != UsernameStatus.untouched) ...[
                                //           const SizedBox(width: 6),
                                //           _AvailabilityChip(status: s.usernameStatus),
                                //         ],
                                //       ],
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _Group(
                              header: 'About',
                              children: [
                                _BioBox(
                                  controller: _bio,
                                  focusNode: _bioFocus,
                                  onChanged: c.setBio,
                                ),
                                _BioFooter(length: s.bio.length),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _Group(
                              header: 'Account',
                              children: [
                                _LockedField(
                                  value: email,
                                  onTap:
                                      () => _toast(
                                        context,
                                        'Email is your sign-in',
                                      ),
                                ),
                                // const _PrivacyRow(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

/// The server enforces the cooldown (`profiles.username_changed_at`, migration
/// 20260101000100). The canvas says 7; the trigger says 30. One number, stated
/// once, so the copy can never drift from what the database will actually do.
const usernameCooldownDays = 30;

// ─── App bar ────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.onBack,
    required this.canSave,
    required this.saving,
    required this.onSave,
  });

  final VoidCallback onBack;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            // 38 disc inside a 44 tap target.
            InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: CkColors.paper2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _Glyph.svg(
                      _Glyph.back,
                      size: 18,
                      color: CkColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit profile',
                style: CkType.display(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Disabled is a filled paper pill, never a hidden one — the canvas is
            // explicit: "not hidden". A Save that vanishes reads as a bug.
            InkWell(
              onTap: canSave ? onSave : null,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: canSave ? CkColors.ink : CkColors.paper2,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child:
                    saving
                        ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CkColors.paper,
                          ),
                        )
                        : Text(
                          'Save',
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.0143, // −0.2px on a 14px face
                            color: canSave ? CkColors.paper : CkColors.soft,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cover + avatar ─────────────────────────────────────────────────────────

class _Media extends StatelessWidget {
  const _Media({
    required this.coverUrl,
    required this.cover,
    required this.avatarUrl,
    required this.avatar,
    required this.initials,
    required this.onCover,
    required this.onAvatar,
  });

  final String? coverUrl;
  final File? cover;
  final String? avatarUrl;
  final File? avatar;
  final String initials;
  final VoidCallback onCover;
  final VoidCallback onAvatar;

  bool get _hasCover => cover != null || (coverUrl?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    // 112 strip + 46 clearance. Sized to contain the overhang rather than
    // letting it spill, so the avatar stays tappable.
    return SizedBox(
      height: 112 + 46,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onCover,
              child: Container(
                height: 112,
                decoration: const BoxDecoration(
                  color: CkColors.paper2,
                  border: Border(bottom: BorderSide(color: CkColors.hairline)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover != null)
                      Image.file(cover!, fit: BoxFit.cover)
                    else if (_hasCover)
                      Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    // The dash is an empty-state marker only.
                    if (!_hasCover)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD8D2C4),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: CkColors.paper,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: CkColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Glyph.svg(
                              _Glyph.camera,
                              size: 15,
                              color: CkColors.ink,
                              strokeWidth: 1.8,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'COVER',
                              style: CkType.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.08,
                                color: CkColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // bottom −36 of a 112 strip inside a 158 box.
          Positioned(
            left: 20,
            top: 60,
            child: _Avatar(url: avatarUrl, file: avatar, initials: initials),
          ),
          Positioned(
            left: 88,
            top: 118,
            child: GestureDetector(
              onTap: onAvatar,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.paper, width: 2.5),
                ),
                alignment: Alignment.center,
                child: _Glyph.svg(
                  _Glyph.camera,
                  size: 14,
                  color: CkColors.paper,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.file,
    required this.initials,
  });

  final String? url;
  final File? file;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      initials,
      style: CkType.display(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: CkColors.ink2,
      ),
    );

    return Container(
      width: 88,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE6EE),
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.paper, width: 3),
      ),
      alignment: Alignment.center,
      child:
          file != null
              ? Image.file(file!, width: 88, height: 88, fit: BoxFit.cover)
              : (url == null || url!.isEmpty)
              ? fallback
              : Image.network(
                url!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
    );
  }
}

// ─── Form scaffolding ───────────────────────────────────────────────────────

class _Group extends StatelessWidget {
  const _Group({required this.header, required this.children});

  final String header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          header.toUpperCase(),
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.11,
            color: CkColors.muted,
          ),
        ),
        for (final child in children) ...[const SizedBox(height: 9), child],
      ],
    );
  }
}

/// Label over box, 6 apart. Sentence-case Inter, not mono uppercase — the
/// canvas is explicit that mono stays for section headers and counters.
class _Labelled extends StatelessWidget {
  const _Labelled({
    required this.label,
    required this.child,
    this.helper,
    this.error,
  });

  final String label;
  final Widget child;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final note = error ?? helper;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CkColors.ink2,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note,
            style: CkType.body(
              fontSize: 11.5,
              height: 1.5,
              color: error != null ? CkColors.red : CkColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.child,
    required this.focused,
    this.error = false,
    // Kept for the commented-out username field, which insets its right edge
    // to 12 to sit the availability chip closer to the border.
    // ignore: unused_element_parameter
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final Widget child;
  final bool focused;
  final bool error;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: padding,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color:
              error
                  ? CkColors.red
                  : focused
                  ? CkColors.ink
                  : CkColors.line,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

/// A borderless field — the box around it owns the chrome.
class _PlainField extends StatelessWidget {
  const _PlainField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      cursorColor: CkColors.red,
      cursorWidth: 1.5,
      cursorHeight: 19,
      style: CkType.body(fontSize: 15, color: CkColors.ink),
      // The box around this field owns all the chrome, so every border, the
      // fill and the padding the app theme supplies are switched off here.
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintText: hint,
        hintStyle: CkType.body(fontSize: 15, color: CkColors.soft),
      ),
    );
  }
}

// NEXT PHASE — the availability chip, paired with the commented-out username
// field above. The three colour pairs are the canvas's own (2a): available
// #E7EFE8 / #2F6B4A, checking #F3F0E9 / #8A8170, taken #FBE9E5 / #8C2218.
//
// class _AvailabilityChip extends StatelessWidget {
//   const _AvailabilityChip({required this.status});
//
//   final UsernameStatus status;
//
//   @override
//   Widget build(BuildContext context) {
//     final (String label, Color bg, Color ink) = switch (status) {
//       UsernameStatus.available =>
//         ('Available', const Color(0xFFE7EFE8), const Color(0xFF2F6B4A)),
//       UsernameStatus.checking =>
//         ('Checking…', CkColors.paper2, CkColors.muted),
//       UsernameStatus.taken =>
//         ('Taken', const Color(0xFFFBE9E5), const Color(0xFF8C2218)),
//       UsernameStatus.invalid =>
//         ('Invalid', const Color(0xFFFBE9E5), const Color(0xFF8C2218)),
//       UsernameStatus.untouched => ('', CkColors.paper2, CkColors.muted),
//     };
//
//     return Container(
//       height: 24,
//       padding: const EdgeInsets.symmetric(horizontal: 9),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       alignment: Alignment.center,
//       child: Text(
//         label.toUpperCase(),
//         style: CkType.mono(
//           fontSize: 9.5,
//           fontWeight: FontWeight.w700,
//           letterSpacing: 0.08,
//           color: ink,
//         ),
//       ),
//     );
//   }
// }

// ─── Bio ────────────────────────────────────────────────────────────────────

class _BioBox extends StatelessWidget {
  const _BioBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 92),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: CkColors.line),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          // Grows to four lines, then scrolls inside the box.
          minLines: 1,
          maxLines: 4,
          cursorColor: CkColors.red,
          cursorWidth: 1.5,
          style: CkType.body(fontSize: 14.5, height: 1.5, color: CkColors.ink),
          decoration: InputDecoration(
            isCollapsed: true,
            filled: false,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            hintText:
                'Right-arm off-spin, opens the batting when nobody else will.',
            hintMaxLines: 3,
            hintStyle: CkType.body(
              fontSize: 14.5,
              height: 1.5,
              color: CkColors.soft,
            ),
          ),
        ),
      ),
    );
  }
}

class _BioFooter extends StatelessWidget {
  const _BioFooter({required this.length});

  final int length;

  static const _max = 200;

  @override
  Widget build(BuildContext context) {
    final over = length > _max;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            'Shown under your name on your profile.',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
        ),
        Text(
          '$length / $_max',
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: over ? CkColors.red : CkColors.soft,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}

// ─── Account ────────────────────────────────────────────────────────────────

/// A read-only field. Same 50/r13 box as an editable one so it still reads as
/// a field rather than a row — the lock glyph does the explaining.
class _LockedField extends StatelessWidget {
  const _LockedField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(fontSize: 14.5, color: CkColors.muted),
              ),
            ),
            const SizedBox(width: 9),
            _Glyph.svg(
              _Glyph.lockSmall,
              size: 15,
              color: CkColors.soft,
              strokeWidth: 1.9,
            ),
          ],
        ),
      ),
    );
  }
}

/// The beige privacy paragraph became a real row you can tap.
///
/// Parked: its call site in the Account group is commented out.
// ignore: unused_element
class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: InkWell(
          onTap: () => context.push('/settings'),
          // A floor, not a fixed height: the row is two lines of text, and it
          // has to be allowed to grow when the OS text scale pushes them past
          // 52 rather than overflow.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                _Glyph.svg(
                  _Glyph.lockLarge,
                  size: 21,
                  color: CkColors.ink,
                  strokeWidth: 1.8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private account & blocking',
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Settings → Privacy',
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                _Glyph.svg(
                  _Glyph.chevron,
                  size: 16,
                  color: CkColors.muted,
                  strokeWidth: 1.8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Discard guard (artboard 1c) ────────────────────────────────────────────

/// "Your name and bio edits haven't been saved. Nothing on your profile has
/// changed yet." Keep editing is the filled, default action — discarding work
/// is never the easy one.
Future<bool?> showDiscardChangesDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: CkColors.ink.withValues(alpha: 0.42),
    builder:
        (ctx) => Dialog(
          backgroundColor: CkColors.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Discard your changes?',
                  style: CkType.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your name and bio edits haven't been saved. Nothing on your "
                  'profile has changed yet.',
                  style: CkType.body(
                    fontSize: 13.5,
                    height: 1.6,
                    color: CkColors.ink2,
                  ),
                ),
                const SizedBox(height: 18),
                _DialogButton(
                  label: 'Keep editing',
                  filled: true,
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
                const SizedBox(height: 9),
                _DialogButton(
                  label: 'Discard',
                  filled: false,
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ),
        ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: filled ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: const Color(0xFFE6D2CC)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: CkType.display(
            fontSize: 15,
            fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
            color: filled ? CkColors.paper : CkColors.red,
          ),
        ),
      ),
    );
  }
}

// ─── Glyphs ─────────────────────────────────────────────────────────────────

abstract final class _Glyph {
  static const back = '<path d="M14 6l-6 6 6 6M8.5 12H20"/>';
  static const chevron = '<path d="M9.5 5.5l6.5 6.5-6.5 6.5"/>';
  static const camera =
      '<path d="M4 8.5h3l1.6-2.2h6.8L17 8.5h3v10H4z"/>'
      '<circle cx="12" cy="13" r="3.1"/>';
  static const lockSmall =
      '<rect x="5" y="10.5" width="14" height="9.5" rx="2"/>'
      '<path d="M8.5 10.5V8a3.5 3.5 0 017 0v2.5"/>';
  static const lockLarge =
      '<rect x="4.5" y="10" width="15" height="10" rx="2.2"/>'
      '<path d="M8.2 10V7.6a3.8 3.8 0 017.6 0V10"/>';

  static Widget svg(
    String body, {
    required double size,
    required Color color,
    double strokeWidth = 1.9,
  }) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
      'viewBox="0 0 24 24" fill="none" stroke="$hex" '
      'stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
    );
  }
}

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';
import '../widgets/circk_brand.dart';

/// Sign-in screen — "matchday." (Variant A: minimal & calm).
///
/// Two phases, chosen by pattern-matching on [AuthState] rather than a local
/// boolean (single source of truth):
///  1. [_EmailForm]  — email entry (primary) + Google (secondary).
///  2. [_CodeForm]   — 6-digit OTP entry after the code is dispatched.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side effects: error snackbar only. Post-auth navigation is handled by
    // the router's `redirect` callback (BEST_PRACTICES §8.1), which moves an
    // authenticated user off /sign-in to /home (or /onboarding if profile is
    // incomplete) the moment the auth stream emits.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next is AuthFailed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });

    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      // Don't reflow the layout when the keyboard opens: the email field stays
      // put and the bottom-anchored "OR / Continue with Google" section stays
      // at the bottom (the keyboard just covers it) instead of sliding up
      // under the email field.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: switch (state) {
          AuthOtpSent() ||
          AuthVerifyingOtp() ||
          AuthFailed(email: != null) => const _CodeForm(),
          _ => const _EmailForm(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Phase 1 — Email entry (Variant A)
// ─────────────────────────────────────────────────────────────
class _EmailForm extends ConsumerStatefulWidget {
  const _EmailForm();
  @override
  ConsumerState<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends ConsumerState<_EmailForm> {
  final _email = TextEditingController();
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get _valid => _emailRe.hasMatch(_email.text.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isSendingOtp = state is AuthSendingOtp;
    final isGoogleLoading = state is AuthSigningInWithGoogle;
    final isBusy = isSendingOtp || isGoogleLoading;

    return Stack(
      children: [
        // Background pitch motif — bottom-right corner.
        const Positioned(
          right: -60,
          bottom: 60,
          child: IgnorePointer(child: PitchMotif(size: 300, opacity: 0.04)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          // Scrollable so the keyboard never overflows the column; the
          // ConstrainedBox + IntrinsicHeight keep the Spacer working (button
          // pinned to the bottom) when there IS enough vertical room.
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: CkWordmark(fontSize: 22),
                          ),
                          const SizedBox(height: 48),

                          // Headline + tagline.
                          Text(
                            'Get on the field.',
                            style: CkType.display(
                              fontSize: 36,
                              letterSpacing: -0.04,
                              height: 0.98,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cricket for the club, the village, the mohalla.',
                            style: CkType.body(
                              fontSize: 14,
                              height: 1.5,
                              color: CkColors.ink2,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Email + Send code.
                          Text('EMAIL ADDRESS', style: _labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _email,
                            enabled: !isBusy,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            style: CkType.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed:
                                (!_valid || isBusy)
                                    ? null
                                    : () => ref
                                        .read(authControllerProvider.notifier)
                                        .sendOtp(_email.text),
                            child:
                                isSendingOtp
                                    ? const _BtnSpinner(color: CkColors.paper)
                                    : const Text('Send code'),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "We'll email you a 6-digit code · no password",
                              style: CkType.body(
                                fontSize: 11,
                                color: CkColors.muted,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // OR divider.
                          _OrDivider(),
                          const SizedBox(height: 22),

                          // Google — secondary.
                          OutlinedButton.icon(
                            onPressed:
                                isBusy
                                    ? null
                                    : () =>
                                        ref
                                            .read(
                                              authControllerProvider.notifier,
                                            )
                                            .signInWithGoogle(),
                            icon:
                                isGoogleLoading
                                    ? const _BtnSpinner(color: CkColors.ink)
                                    : const GoogleG(size: 20),
                            label: const Text('Continue with Google'),
                          ),
                          const SizedBox(height: 18),

                          _TermsFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Phase 2 — OTP entry
// ─────────────────────────────────────────────────────────────
class _CodeForm extends ConsumerStatefulWidget {
  const _CodeForm();
  @override
  ConsumerState<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends ConsumerState<_CodeForm> {
  static const _len = 6;
  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _focusNodes = List.generate(_len, (_) => FocusNode());
  final _keyNodes = List.generate(_len, (_) => FocusNode(skipTraversal: true));

  Timer? _timer;
  int _resendIn = 28;

  String get _code => _controllers.map((c) => c.text).join();
  bool get _filled => _code.length == _len;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendIn = 28;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _resendIn = (_resendIn - 1).clamp(0, 28));
      if (_resendIn == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String v) {
    // Keep only the last typed digit; support paste of the full code.
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _distribute(digits);
      return;
    }
    _controllers[i].text = digits;
    _controllers[i].selection = TextSelection.collapsed(offset: digits.length);
    if (digits.isNotEmpty && i < _len - 1) {
      _focusNodes[i + 1].requestFocus();
    }
    setState(() {});
  }

  void _distribute(String digits) {
    final take = digits.substring(0, digits.length.clamp(0, _len));
    for (var j = 0; j < _len; j++) {
      _controllers[j].text = j < take.length ? take[j] : '';
    }
    final next = (take.length).clamp(0, _len - 1);
    _focusNodes[next].requestFocus();
    setState(() {});
  }

  void _onKey(int i, KeyEvent e) {
    if (e is KeyDownEvent &&
        e.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _focusNodes[i - 1].requestFocus();
      _controllers[i - 1].clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isVerifying = state is AuthVerifyingOtp;

    final email = switch (state) {
      AuthOtpSent(:final email) => email,
      AuthVerifyingOtp(:final email) => email,
      AuthFailed(email: final e?) => e,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Check your\ninbox',
            style: CkType.display(fontSize: 32, height: 1.05),
          ),
          const SizedBox(height: 8),
          // Sent to <email> · change
          Text.rich(
            TextSpan(
              style: CkType.body(fontSize: 15, color: CkColors.muted),
              children: [
                const TextSpan(text: 'Sent to '),
                TextSpan(
                  text: email?.value ?? 'you@example.com',
                  style: CkType.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
                const TextSpan(text: '  ·  '),
                TextSpan(
                  text: 'change',
                  style: CkType.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CkColors.red,
                  ),
                  recognizer: _tap(
                    () =>
                        ref
                            .read(authControllerProvider.notifier)
                            .cancelOtpFlow(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 6 OTP boxes.
          Row(
            children: [
              for (var i = 0; i < _len; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _otpBox(index: i, enabled: !isVerifying)),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Resend.
          _resendIn > 0
              ? Text.rich(
                TextSpan(
                  style: CkType.body(fontSize: 13, color: CkColors.muted),
                  children: [
                    const TextSpan(text: 'Resend in '),
                    TextSpan(
                      text: '0:${_resendIn.toString().padLeft(2, '0')}',
                      style: CkType.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              )
              : GestureDetector(
                onTap:
                    isVerifying
                        ? null
                        : () {
                          ref.read(authControllerProvider.notifier).resendOtp();
                          _startTimer();
                        },
                child: Text(
                  'Resend code',
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CkColors.red,
                  ),
                ),
              ),

          const Spacer(),

          FilledButton(
            onPressed:
                (!_filled || isVerifying)
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .verifyOtp(_code),
            child:
                isVerifying
                    ? const _BtnSpinner(color: CkColors.paper)
                    : const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _otpBox({required int index, required bool enabled}) {
    return KeyboardListener(
      focusNode: _keyNodes[index],
      onKeyEvent: (e) => _onKey(index, e),
      child: SizedBox(
        height: 60,
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: enabled,
          autofocus: index == 0,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          showCursor: false,
          autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: CkType.display(fontSize: 28),
          decoration: const InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => _onChanged(index, v),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small shared bits
// ─────────────────────────────────────────────────────────────
final TextStyle _labelStyle = CkType.body(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.96, // 0.08em @ 12px
  color: CkColors.muted,
);

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: CkColors.hairline, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: CkType.mono(fontSize: 11)),
        ),
        const Expanded(child: Divider(color: CkColors.hairline, height: 1)),
      ],
    );
  }
}

class _TermsFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final link = CkType.body(
      fontSize: 11,
      color: CkColors.ink2,
    ).copyWith(decoration: TextDecoration.underline);
    return Center(
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: CkType.body(fontSize: 11, height: 1.5, color: CkColors.soft),
          children: [
            const TextSpan(text: 'By continuing you agree to our '),
            TextSpan(text: 'Terms', style: link),
            const TextSpan(text: ' & '),
            TextSpan(text: 'Privacy Policy', style: link),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

GestureRecognizer _tap(VoidCallback onTap) =>
    TapGestureRecognizer()..onTap = onTap;

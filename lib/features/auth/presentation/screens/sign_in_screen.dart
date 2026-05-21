import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';

/// Sign-in screen.
///
/// Two phases:
///  1. Email entry + Google button.
///  2. OTP code entry (after the code is dispatched).
///
/// The phase is decided by pattern-matching on the current AuthState
/// rather than a local boolean — single source of truth.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side effects: navigation and snackbars.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go('/todos');
        case AuthFailed(failure: final f):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          );
        case _:
          break;
      }
    });

    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        leading: switch (state) {
          AuthOtpSent() || AuthVerifyingOtp() || AuthFailed(email: != null) =>
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).cancelOtpFlow(),
            ),
          _ => null,
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (state) {
          AuthOtpSent() ||
          AuthVerifyingOtp() ||
          AuthFailed(email: != null) =>
            const _CodeForm(),
          _ => const _EmailForm(),
        },
      ),
    );
  }
}

class _EmailForm extends ConsumerStatefulWidget {
  const _EmailForm();
  @override
  ConsumerState<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends ConsumerState<_EmailForm> {
  final _email = TextEditingController();

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

    return Column(
      children: [
        TextField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
          enabled: !isBusy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isBusy
              ? null
              : () => ref
                  .read(authControllerProvider.notifier)
                  .sendOtp(_email.text),
          child: isSendingOtp
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Email me a code'),
        ),
        const SizedBox(height: 24),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or'),
          ),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: isGoogleLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login), // swap for a brand icon asset
          label: const Text('Continue with Google'),
          onPressed: isBusy
              ? null
              : () => ref
                  .read(authControllerProvider.notifier)
                  .signInWithGoogle(),
        ),
      ],
    );
  }
}

class _CodeForm extends ConsumerStatefulWidget {
  const _CodeForm();
  @override
  ConsumerState<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends ConsumerState<_CodeForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (email != null)
          Text(
            'Enter the 6-digit code we sent to ${email.value}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          decoration: const InputDecoration(labelText: 'Code'),
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          enabled: !isVerifying,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isVerifying
              ? null
              : () => ref
                  .read(authControllerProvider.notifier)
                  .verifyOtp(_code.text),
          child: isVerifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isVerifying
              ? null
              : () =>
                  ref.read(authControllerProvider.notifier).resendOtp(),
          child: const Text('Resend code'),
        ),
      ],
    );
  }
}

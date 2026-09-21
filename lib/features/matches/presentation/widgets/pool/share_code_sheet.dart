import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../providers/match_pool_providers.dart';

/// Resolves the 6-digit code from artboard 02's "Have a share code?" row.
///
/// The row is drawn in the design; the sheet behind it is not, so this keeps
/// to the board's own vocabulary — paper ground, mono label, one ink action —
/// and does no more than turn a code into the challenge it names.
Future<void> showShareCodeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ShareCodeSheet(),
  );
}

class _ShareCodeSheet extends ConsumerStatefulWidget {
  const _ShareCodeSheet();

  @override
  ConsumerState<_ShareCodeSheet> createState() => _ShareCodeSheetState();
}

class _ShareCodeSheetState extends ConsumerState<_ShareCodeSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter all six digits.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref
        .read(matchPoolRepositoryProvider)
        .findChallengeByCode(code);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _busy = false;
        _error = failure.message;
      }),
      (request) {
        if (request == null) {
          setState(() {
            _busy = false;
            // A wrong code and an expired one look identical on purpose —
            // the RPC returns zero rows for both so neither leaks.
            _error = 'That code is not valid, or it has expired.';
          });
          return;
        }
        Navigator.of(context).pop();
        context.push('/challenges/${request.id.value}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: CkColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Enter share code',
              style: CkType.display(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Six digits, handed to you by the challenge’s captain.',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => _submit(),
              style: CkType.mono(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.30,
                color: CkColors.ink,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: CkType.mono(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.30,
                  color: CkColors.soft,
                ),
                filled: true,
                fillColor: CkColors.paper2,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CkColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CkColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CkColors.ink),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12.5, color: CkColors.redInk),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _busy ? null : _submit,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _busy ? CkColors.ink2 : CkColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child:
                      _busy
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CkColors.paper,
                            ),
                          )
                          : Text(
                            'Find challenge',
                            style: CkType.display(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CkColors.paper,
                              letterSpacing: -0.01,
                            ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_button.dart';

/// Bottom sheet for entering or clearing a player's jersey number.
class JerseySheet extends StatefulWidget {
  const JerseySheet({super.key, this.initial});
  final int? initial;

  static Future<({int? value})?> show(BuildContext context, {int? initial}) {
    return showModalBottomSheet<({int? value})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => JerseySheet(initial: initial),
    );
  }

  @override
  State<JerseySheet> createState() => _JerseySheetState();
}

class _JerseySheetState extends State<JerseySheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jersey number', style: CkType.display(fontSize: 20)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: CkType.body(fontSize: 16),
            decoration: const InputDecoration(hintText: 'e.g. 7'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CkButton.secondary(
                  label: 'Clear',
                  onPressed: () => Navigator.of(context).pop((value: null)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: CkButton(label: 'Save', onPressed: _submit)),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final n = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop((value: n));
  }
}

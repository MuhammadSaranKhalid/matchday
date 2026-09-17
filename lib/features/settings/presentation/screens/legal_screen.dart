import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'legal_content.dart';

Future<void> openLegalLink(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) { /* Display the URL so the user can copy it. */ }
  if (!context.mounted) return;
  await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Open this address'), content: SelectableText(uri.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]));
}
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});
  final String document;
  @override
  Widget build(BuildContext context) {
    final content = legalContent[document]!;
    return Scaffold(appBar: AppBar(title: Text(content.first)), body: ListView(padding: const EdgeInsets.all(24), children: [
      for (final section in content.skip(1)) ...[
        Text(section.split('\n').first, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8), SelectableText(section.substring(section.indexOf('\n') + 1)), const SizedBox(height: 24),
      ],
      OutlinedButton(onPressed: () => openLegalLink(context, Uri.parse('$legalBaseUrl/$document.html')), child: const Text('Open website')),
      TextButton(onPressed: () => openLegalLink(context, Uri(scheme: 'mailto', path: supportEmail)), child: const Text('Contact support')),
    ]));
  }
}

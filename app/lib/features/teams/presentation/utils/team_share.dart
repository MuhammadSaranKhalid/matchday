import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/ck_toast.dart';

const String _teamShareBase = 'https://joinmatchday.com/t';

String teamShareLink(String teamId) => '$_teamShareBase/$teamId';

Future<void> shareTeam(
  BuildContext originContext, {
  required String teamId,
  required String teamName,
}) {
  final box = originContext.findRenderObject() as RenderBox?;
  final origin = (box != null && box.hasSize)
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  return SharePlus.instance.share(
    ShareParams(
      text: 'Check out $teamName on matchday 🏏${teamShareLink(teamId)}',
      subject: '$teamName on matchday',
      sharePositionOrigin: origin,
    ),
  );
}

Future<void> copyTeamLink(
  BuildContext context, {
  required String teamId,
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: teamShareLink(teamId)));
    if (!context.mounted) return;
    CkToast.show(
      context,
      message: 'Link copied',
      icon: Icons.content_copy,
    );
  } catch (_) {
    if (!context.mounted) return;
    CkToast.show(
      context,
      message: 'Couldn’t copy the link',
      isError: true,
      actionLabel: 'Retry',
      onAction: () => copyTeamLink(context, teamId: teamId),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/ck_toast.dart';

/// One host, one letter per entity type: `/u/` user, `/t/` team, `/c/`
/// competition.
///
/// Profiles already share `joinmatchday.com/u/<username>`; tournaments
/// currently share a second domain (`matchday.cricket/tournaments/<id>`),
/// which isn't the brand and reads as spam in a forwarded WhatsApp message.
/// Teams join the `joinmatchday.com` family here; retiring the other host to
/// a 301 is its own ticket.
const String _teamShareBase = 'https://joinmatchday.com/t';

/// Public link to a team page.
///
/// Uses the team id today. The design's slug form (`/t/lahore-lions`) needs a
/// `slug` column on `teams` to be unique and stable; when that lands, ids stay
/// valid as redirects so links shared now never die.
String teamShareLink(String teamId) => '$_teamShareBase/$teamId';

/// Opens the OS share sheet for a team.
///
/// No in-app pre-share screen and no success toast: the OS sheet *is* the
/// preview, a completed share is confirmed by the OS, and a cancelled share
/// should say nothing at all.
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
      text: 'Check out $teamName on matchday 🏏\n${teamShareLink(teamId)}',
      subject: '$teamName on matchday',
      sharePositionOrigin: origin,
    ),
  );
}

/// Copies the team link and confirms it. This is the one share path that
/// *does* confirm — nothing else tells the user it worked.
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

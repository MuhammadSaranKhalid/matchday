// View model for the Team Page — a faithful port of the JSX `CASES.*`
// shape from design/screens/tp-data.jsx + tp-tabs.jsx.
//
// One [TeamPageView] feeds the Team Page body. It is built from real provider
// data by buildTeamPageViewFromReal(...) in team_page_screen.dart.
//
// Sections are nullable / empty-by-default — the body short-circuits any
// section whose data is absent so each viewer × state lands on a focused
// screen.
//
// NOTE: many fields below (record, form, stats, tournament, actionQueue,
// performers, live details) have no backend yet and stay null/empty in
// production. They mirror the design's full state set; populate them when the
// corresponding backend ships, adjusting the shape to match it.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show IconData;

/// Who's looking at the page — drives the action row, the tab set, and the
/// per-row personal markers in the squad.
enum TeamPageViewer {
  owner,
  captain,
  player,
  following,
  stranger,
  strangerPrivate,
}

/// The four tonally-distinct info-banner styles (port of the JSX `tones` map).
enum TpInfoBannerTone { green, amber, red, gray }

/// Result of a single match in the Last-8 form strip.
enum TpFormResult { w, l, t }

/// Status of a player row in the squad — drives jersey-tile color + status
/// pip + UNCLAIMED pill.
enum TpPlayerStatus { app, sms, unclaimed }

/// JSX role string mapped to a Flutter enum. Mirrors `Captain / Vice-Captain
/// / Wicket-Keeper / Player`.
enum TpPlayerRole { captain, viceCaptain, wicketKeeper, player }

/// Action-queue tone — controls left-border accent on Manage rows.
enum TpQueueTone { red, amber, ink }

/// Tab IDs for the Team Page.
enum TeamPageTab { posts, squad, matches, stats, about, recent }

@immutable
class TpRecord {
  const TpRecord({required this.played, required this.won, required this.lost});
  final int played;
  final int won;
  final int lost;
  int get winPct => played == 0 ? 0 : ((won / played) * 100).round();
}

@immutable
class TpHeroBadge {
  const TpHeroBadge({
    required this.label,
    this.tone = TpHeroBadgeTone.neutral,
    this.pulse = false,
  });
  final String label;
  final TpHeroBadgeTone tone;
  final bool pulse;
}

enum TpHeroBadgeTone { neutral, red }

@immutable
class TpLiveCard {
  const TpLiveCard({
    required this.ctx,
    required this.us,
    required this.them,
    required this.usScore,
    required this.themScore,
    required this.note,
  });
  final String ctx;
  final String us;
  final String them;
  final String usScore;
  final String themScore;
  final String note;
}

@immutable
class TpInfoBanner {
  const TpInfoBanner({
    required this.tone,
    required this.title,
    required this.body,
    this.cta,
    this.icon,
  });
  final TpInfoBannerTone tone;
  final String title;
  final String body;
  final String? cta;

  /// Icon glyph rendered inside the small circular badge.
  final IconData? icon;
}

@immutable
class TpUpcomingMatch {
  const TpUpcomingMatch({
    required this.dateDay,
    required this.dateTime,
    required this.round,
    required this.venue,
    required this.vs,
    this.live = false,
  });

  /// First half of the JSX `date` string — e.g. "Today" / "May 6".
  final String dateDay;

  /// Second half of the JSX `date` string — e.g. "14:00".
  final String dateTime;
  final String round;
  final String venue;
  final String vs;
  final bool live;
}

@immutable
class TpRecentMatch {
  const TpRecentMatch({
    required this.date,
    required this.us,
    required this.them,
    required this.result,
    required this.summary,
  });
  final String date;
  final String us;
  final String them;
  final TpFormResult result;
  final String summary;
}

@immutable
class TpTournament {
  const TpTournament({
    required this.kind,
    required this.name,
    required this.stage,
    required this.played,
    required this.total,
    required this.next,
  });
  final String kind;
  final String name;
  final String stage;
  final int played;
  final int total;
  final String next;
}

@immutable
class TpPerformer {
  const TpPerformer({
    required this.kind,
    required this.label,
    required this.name,
    required this.value,
    required this.detail,
  });

  /// Three-letter tile label: BAT / BOWL / AR.
  final String kind;

  /// Mono section label: "MOST RUNS" / "MOST WICKETS" / "BEST IMPACT".
  final String label;
  final String name;
  final String value;
  final String detail;
}

@immutable
class TpStats {
  const TpStats({
    required this.winPct,
    required this.trend,
    required this.top,
  });
  final int winPct;
  final String trend;
  final List<TpPerformer> top;
}

@immutable
class TpActionQueueItem {
  const TpActionQueueItem({
    required this.kind,
    required this.tone,
    required this.when,
    required this.title,
    required this.body,
    required this.primary,
  });
  final String kind;
  final TpQueueTone tone;
  final String when;
  final String title;
  final String body;
  final String primary;
}

@immutable
class TpDetailRow {
  const TpDetailRow(this.label, this.value);
  final String label;
  final String value;
}

@immutable
class TpManagerRow {
  const TpManagerRow({required this.name, required this.role});
  final String name;
  final String role;
}

@immutable
class TpPlayerRow {
  const TpPlayerRow({
    required this.id,
    required this.name,
    required this.role,
    required this.jersey,
    required this.bat,
    required this.bowl,
    required this.status,
    this.last5 = const [],
  });
  final String id;
  final String name;
  final TpPlayerRole role;
  final int jersey;

  /// Batting hand: "RHB" / "LHB".
  final String bat;

  /// Bowling type: "RM" / "OS" / "SLA" / "—" / etc.
  final String bowl;

  final TpPlayerStatus status;

  /// Up to 5 most recent batting scores for the inline sparkline.
  final List<int> last5;
}

/// The whole Team Page, in one shape. Renderers read this and short-circuit
/// any optional section that's null / empty.
@immutable
class TeamPageView {
  const TeamPageView({
    required this.viewer,
    required this.team,
    required this.tabs,
    required this.initialTab,
    this.viewerPlayerId,
    this.badges = const [],
    this.banner,
  });

  final TeamPageViewer viewer;
  final TpTeam team;
  final List<TeamPageTab> tabs;
  final TeamPageTab initialTab;

  /// JSX `viewerIs` — the player id of the signed-in user. Used by
  /// PlayerRow to add the YOU pill + jersey checkmark.
  final String? viewerPlayerId;

  final List<TpHeroBadge> badges;
  final TpInfoBanner? banner;
}

/// The viewable team — all the fields the page reads. Mirrors the JSX
/// LIONS / KHAAKI / RAWAL_OLD shapes.
@immutable
class TpTeam {
  const TpTeam({
    required this.name,
    required this.mono,
    required this.type,
    required this.city,
    required this.area,
    required this.primary,
    required this.privacy,
    this.tagline,
    this.logoUrl,
    this.verified = false,
    this.archived,
    this.record,
    this.form = const [],
    this.live,
    this.tournament,
    this.upcoming = const [],
    this.recent = const [],
    this.stats,
    this.squad = const [],
    this.maxSize = 25,
    this.actionQueue = const [],
    this.about = '',
    this.details = const [],
    this.managers = const [],
  });

  final String name;
  final String mono;
  final String type;
  final String city;
  final String area;
  final Color primary;
  final String privacy;

  final String? tagline;
  final String? logoUrl;
  final bool verified;

  /// When set, the page renders in archive mode (desaturated, "Read-only
  /// archive" action, DISBANDED block in About). Value is a human date.
  final String? archived;

  final TpRecord? record;
  final List<TpFormResult> form;
  final TpLiveCard? live;
  final TpTournament? tournament;

  final List<TpUpcomingMatch> upcoming;
  final List<TpRecentMatch> recent;
  final TpStats? stats;

  final List<TpPlayerRow> squad;
  final int maxSize;

  final List<TpActionQueueItem> actionQueue;

  final String about;
  final List<TpDetailRow> details;
  final List<TpManagerRow> managers;
}

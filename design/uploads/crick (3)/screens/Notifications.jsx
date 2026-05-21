// Notifications.jsx — the app's notification center
// Surfaces every notification type the app emits across all features:
//   Invites & requests   · Match alerts    · Tournament alerts
//   Stats & milestones   · Social          · System
//
// Three variants in one component:
//   <CkNotifications />                       → sectioned canonical (all categories, grouped by day)
//   <CkNotifications variant="filtered" />    → same data, filter chips visible, default to Invites
//   <CkNotifications variant="empty" />       → empty / inbox-zero state with permission education

(function () {

// ─── tokens ───────────────────────────────────────────
const ink = 'var(--ink)', ink2 = 'var(--ink-2)', muted = 'var(--muted)';
const paper = 'var(--paper)', paper2 = 'var(--paper-2)', surface = 'var(--surface)';
const hair = 'var(--hairline)', line = 'var(--line)';
const red = 'var(--red)', redSoft = 'var(--red-soft)';
const green = 'var(--green)', greenSoft = 'var(--green-soft)';
const amber = 'var(--amber)', cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase', color: muted };
const display = (s = 22) => ({ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: s, lineHeight: 1.05, color: ink });

// ─── notification data ────────────────────────────────
// Real spec coverage: team, tournament, match, scoring, stats, claim, social, system
const NOTIFS = [
  // ── TODAY ──────────────────────────────────────────
  { id: 'nR1', day: 'today', t: '5m', cat: 'roster-alert', unread: true,
    body: <>Faraz dropped out — you're short for <b>Lions vs Eagles</b></>,
    sub: 'Sat 18 May · 3 PM · Need 11 · Have 10',
    pill: { tone: 'amber', text: 'NEEDS 1' },
    actions: ['view'] },

  { id: 'n1', day: 'today', t: '12m', cat: 'invite', unread: true,
    actor: { name: 'Bilal Ahmed', mono: 'BA' },
    body: <>Invited you to <b>Lahore Lions</b></>,
    sub: 'Squad of 14 · Club · Lahore, Model Town',
    role: 'Player · Jersey #7',
    actions: ['accept', 'decline'] },

  { id: 'n2', day: 'today', t: '38m', cat: 'match', unread: true,
    body: <><b>Spring Cup '26 · QF</b> starts in 1h 20m</>,
    sub: 'Lahore Lions vs Karachi Cobras · Gaddafi B Ground · 4:00 PM',
    pill: { tone: 'red', text: 'LIVE SOON' },
    actions: ['view'] },

  { id: 'n3', day: 'today', t: '1h', cat: 'scoring', unread: true,
    actor: { name: 'Imran Saeed', mono: 'IS' },
    body: <>Assigned you as <b>scorer</b> for Spring Cup '26 · Final</>,
    sub: 'Lahore Lions vs Karachi XI · Sat 18 May, 5:00 PM',
    actions: ['accept', 'decline'] },

  { id: 'n4', day: 'today', t: '2h', cat: 'social',
    actor: { name: 'Adeel Sheikh', mono: 'AS' },
    body: <><b>@adeelk</b> started following you</>,
    sub: 'Wicket-keeper · Lahore · 22 matches',
    actions: ['followBack'] },

  // ── YESTERDAY ──────────────────────────────────────
  { id: 'n5', day: 'yesterday', t: '14h', cat: 'milestone', unread: true,
    body: <><b>67* vs Karachi Cobras</b> — your highest score</>,
    sub: "4 fours · 3 sixes · SR 142 · Spring Cup '26 QF",
    bigStat: { v: '67', l: '*' },
    actions: ['view', 'share'] },

  { id: 'n6', day: 'yesterday', t: '16h', cat: 'claim',
    actor: { name: 'Ahmed Khan', mono: 'AK' },
    body: <>Wants to claim <b>"Ahmed K."</b> in your squad</>,
    sub: 'Added by you Mar 2024 · 22 matches · 312 runs · 18 wkts',
    actions: ['approve', 'reject'] },

  { id: 'n7', day: 'yesterday', t: '19h', cat: 'tournament',
    body: <>Your registration to <b>Spring Cup '26</b> was approved</>,
    sub: 'Group A · Round 1 vs Multan Tigers, Tue 14 May',
    pill: { tone: 'green', text: 'APPROVED' },
    actions: ['view'] },

  { id: 'n8', day: 'yesterday', t: '22h', cat: 'match-end',
    body: <>Lahore Lions won by <b>23 runs</b> vs Multan Tigers</>,
    sub: "Group A R1 · 142/6 (20) defended 119/9 (20) · Spring Cup '26",
    score: { a: '142/6', b: '119/9' },
    actions: ['view'] },

  // ── THIS WEEK ──────────────────────────────────────
  { id: 'n9', day: 'week', t: 'Mon', cat: 'match-request',
    actor: { name: 'Model Town XI', mono: 'MX' },
    body: <><b>Model Town XI</b> challenged you to a friendly</>,
    sub: 'Sun 19 May · 8:00 AM · T20 · Tape ball · Race Course',
    actions: ['accept', 'decline'] },

  { id: 'n10', day: 'week', t: 'Mon', cat: 'mention',
    actor: { name: 'Faraz Khan', mono: 'FK' },
    body: <><b>@faraz</b> mentioned you in a post</>,
    sub: '"Best opening partnership ever with @bilal — 88 in 7 overs vs Multan…"' },

  { id: 'n11', day: 'week', t: 'Sun', cat: 'fixture-change',
    body: <>Match vs <b>Karachi Cobras</b> moved to Sat 18 May, 3 PM</>,
    sub: 'Was Fri 17 May, 4 PM · Reason: rain forecast',
    pill: { tone: 'amber', text: 'RESCHEDULED' },
    actions: ['view'] },

  { id: 'n12', day: 'week', t: 'Sun', cat: 'milestone',
    body: <>Career milestone — <b>1,000 runs</b></>,
    sub: 'Across 42 innings · 2.1 years on the app',
    bigStat: { v: '1K', l: 'r' },
    actions: ['share'] },

  { id: 'n13', day: 'week', t: 'Sat', cat: 'tournament',
    body: <><b>Spring Cup '26</b> published its bracket</>,
    sub: '8 teams · Lahore Lions seeded #3 · R1 vs Multan Tigers',
    actions: ['view'] },

  { id: 'n14', day: 'week', t: 'Fri', cat: 'like',
    actor: { name: 'Usman Riaz', mono: 'UR' },
    body: <><b>@usmanr</b> and <b>4 others</b> liked your post</>,
    sub: '"3 in 4 balls — best over of my life"' },

  { id: 'n15', day: 'week', t: 'Fri', cat: 'comment',
    actor: { name: 'Junaid Ali', mono: 'JA' },
    body: <><b>Junaid Ali</b> commented</>,
    sub: '"Brilliant innings bro 🔥 bring the bat to our ground next time"' },

  { id: 'n16', day: 'week', t: 'Thu', cat: 'team',
    actor: { name: 'Bilal Ahmed', mono: 'BA' },
    body: <>Made you <b>vice-captain</b> of Lahore Lions</>,
    sub: 'Effective from next match · Was Player' },

  // ── EARLIER ────────────────────────────────────────
  { id: 'n17', day: 'earlier', t: '15 May', cat: 'milestone',
    body: <>First <b>5-wicket haul</b> — 5/22 vs Multan Tigers</>,
    sub: '4 ov · 5 maidens · 22 runs · Career-best figures',
    bigStat: { v: '5', l: '/22' },
    actions: ['view', 'share'] },

  { id: 'n18', day: 'earlier', t: '13 May', cat: 'ranking',
    body: <>You entered the <b>Top 50 batters · Punjab</b></>,
    sub: 'Up 8 places this week · #47 · 1,012 career runs',
    pill: { tone: 'green', text: '+8' } },

  { id: 'n19', day: 'earlier', t: '11 May', cat: 'claim-approved',
    body: <>Your claim on <b>"Bilal K. · Spring '23"</b> was approved</>,
    sub: '180 runs · 9 wickets · 4 catches migrated to your profile',
    actions: ['view'] },

  { id: 'n20', day: 'earlier', t: '09 May', cat: 'recruitment',
    body: <><b>Karachi Royals</b> is recruiting a wicket-keeper</>,
    sub: 'Club · Karachi · Matches your role & city',
    actions: ['view', 'mute'] },

  { id: 'n21', day: 'earlier', t: '06 May', cat: 'award',
    body: <>You won <b>Player of the Match</b> · R1 vs Multan Tigers</>,
    sub: '67* (43) · 2/19 · 1 catch',
    actions: ['view'] },

  { id: 'n22', day: 'earlier', t: '04 May', cat: 'organizer',
    body: <><b>2 teams</b> registered for Spring Cup '26</>,
    sub: 'Multan Tigers · Karachi Cobras · Awaiting your approval',
    actions: ['review'] },

  { id: 'n23', day: 'earlier', t: '02 May', cat: 'system',
    body: <>Your phone <b>+92 300 ··· 4521</b> was verified</>,
    sub: 'Account secured · 2-step recovery active' },
];

// ─── category metadata ────────────────────────────────
// Drives icon, bg tint, and which top-level filter the row belongs to
const CAT = {
  invite:         { tint: cream,    fg: ink,    bucket: 'invites',     icon: 'envelope' },
  'match-request':{ tint: cream,    fg: ink,    bucket: 'invites',     icon: 'envelope' },
  scoring:        { tint: ink,      fg: paper,  bucket: 'invites',     icon: 'pencil'   },
  claim:          { tint: cream,    fg: ink,    bucket: 'invites',     icon: 'handshake'},
  'claim-approved':{tint: greenSoft,fg: green,  bucket: 'matches',     icon: 'check'    },
  match:          { tint: redSoft,  fg: red,    bucket: 'matches',     icon: 'flame'    },
  'match-end':    { tint: paper2,   fg: ink,    bucket: 'matches',     icon: 'flag'     },
  'fixture-change':{tint: cream,    fg: ink2,   bucket: 'matches',     icon: 'shuffle'  },
  'roster-alert': { tint: cream,    fg: amber,  bucket: 'matches',     icon: 'people'   },
  award:          { tint: greenSoft,fg: green,  bucket: 'matches',     icon: 'trophy'   },
  tournament:     { tint: redSoft,  fg: red,    bucket: 'tournaments', icon: 'bracket'  },
  organizer:      { tint: redSoft,  fg: red,    bucket: 'tournaments', icon: 'flag'     },
  milestone:      { tint: greenSoft,fg: green,  bucket: 'milestones',  icon: 'spark'    },
  ranking:        { tint: greenSoft,fg: green,  bucket: 'milestones',  icon: 'arrow-up' },
  team:           { tint: paper2,   fg: ink,    bucket: 'invites',     icon: 'people'   },
  social:         { tint: paper2,   fg: ink2,   bucket: 'social',      icon: 'user-plus'},
  mention:        { tint: paper2,   fg: ink2,   bucket: 'social',      icon: 'at'       },
  comment:        { tint: paper2,   fg: ink2,   bucket: 'social',      icon: 'speech'   },
  like:           { tint: paper2,   fg: ink2,   bucket: 'social',      icon: 'heart'    },
  recruitment:    { tint: paper2,   fg: ink2,   bucket: 'social',      icon: 'megaphone'},
  system:         { tint: paper2,   fg: muted,  bucket: 'system',      icon: 'shield'   },
};

const FILTERS = [
  { k: 'all',          l: 'All',           bucket: null },
  { k: 'unread',       l: 'Unread',        bucket: 'unread' },
  { k: 'invites',      l: 'Invites',       bucket: 'invites' },
  { k: 'matches',      l: 'Matches',       bucket: 'matches' },
  { k: 'tournaments',  l: 'Tournaments',   bucket: 'tournaments' },
  { k: 'milestones',   l: 'Milestones',    bucket: 'milestones' },
  { k: 'social',       l: 'Social',        bucket: 'social' },
];

// ─── icons ────────────────────────────────────────────
function NotifIcon({ kind, size = 14, color = 'currentColor' }) {
  const s = { fill: 'none', stroke: color, strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const paths = {
    envelope:  <><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 7l10 7L22 7"/></>,
    pencil:    <><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/></>,
    handshake: <><path d="M9 11l3-3 3 3 4 4-3 3-2-2-2 2-3-3"/><path d="M2 12l4-4 3 3"/><path d="M22 12l-4 4"/></>,
    check:     <><polyline points="20 6 9 17 4 12"/></>,
    flame:     <><path d="M12 22c4 0 7-3 7-7 0-3-2-5-4-7-2 2-4 4-4 7 0-2-1-3-2-4-1 2-3 4-3 7 0 4 3 7 6 7z"/></>,
    flag:      <><path d="M4 22V4M4 4h13l-2 4 2 4H4"/></>,
    shuffle:   <><polyline points="16 3 21 3 21 8"/><line x1="4" y1="20" x2="21" y2="3"/><polyline points="21 16 21 21 16 21"/><line x1="15" y1="15" x2="21" y2="21"/><line x1="4" y1="4" x2="9" y2="9"/></>,
    trophy:    <><path d="M8 21h8M12 17v4M6 4h12v5a6 6 0 0 1-12 0z"/><path d="M6 4H3v3a3 3 0 0 0 3 3M18 4h3v3a3 3 0 0 1-3 3"/></>,
    bracket:   <><path d="M3 6h6v4H3zM3 14h6v4H3zM15 10h6v4h-6zM9 8h6M9 16h6M15 12h-3"/></>,
    spark:     <><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/></>,
    'arrow-up':<><path d="M12 19V5M5 12l7-7 7 7"/></>,
    people:    <><circle cx="9" cy="8" r="3.4"/><path d="M2 21c0-3.8 3-7 7-7s7 3.2 7 7"/><circle cx="17" cy="6" r="2.4"/><path d="M22 17c0-2.5-2-4.5-5-4.5"/></>,
    'user-plus':<><circle cx="9" cy="8" r="3.4"/><path d="M2 21c0-3.8 3-7 7-7s5 1 6 2.5"/><path d="M19 8v6M16 11h6"/></>,
    at:        <><circle cx="12" cy="12" r="4"/><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8"/></>,
    speech:    <><path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></>,
    heart:     <><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1A5.5 5.5 0 1 0 3.2 12.4l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z"/></>,
    megaphone: <><path d="M3 11v2a4 4 0 0 0 4 4l9 4V5L7 9a4 4 0 0 0-4 2z"/><path d="M21 7v8"/></>,
    shield:    <><path d="M12 22s8-4 8-12V4l-8-2-8 2v6c0 8 8 12 8 12z"/><polyline points="9 12 11 14 15 10"/></>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" style={s}>{paths[kind]}</svg>;
}

// ─── primitives ───────────────────────────────────────
function CatIcon({ cat }) {
  const c = CAT[cat] || CAT.system;
  return (
    <div style={{
      width: 36, height: 36, borderRadius: 10, flexShrink: 0,
      background: c.tint, color: c.fg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <NotifIcon kind={c.icon} size={16} />
    </div>
  );
}

function Pill({ tone, children }) {
  const map = {
    red:   { bg: red, fg: 'white' },
    green: { bg: greenSoft, fg: 'oklch(0.36 0.10 148)' },
    amber: { bg: cream, fg: 'oklch(0.30 0.02 80)' },
    ink:   { bg: ink, fg: paper },
  };
  const m = map[tone] || map.amber;
  return (
    <span style={{
      ...mono, color: m.fg, background: m.bg, border: 'none',
      padding: '2px 7px', borderRadius: 999, display: 'inline-flex',
    }}>{children}</span>
  );
}

function BigStat({ v, l }) {
  return (
    <div style={{
      width: 44, height: 44, borderRadius: 12, flexShrink: 0,
      background: greenSoft, color: 'oklch(0.36 0.10 148)',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      lineHeight: 1, paddingTop: 2,
    }}>
      <div style={{ fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 18, letterSpacing: '-0.02em' }}>{v}</div>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, letterSpacing: '0.06em', opacity: 0.7, marginTop: 1 }}>{l}</div>
    </div>
  );
}

function ScoreChip({ a, b }) {
  return (
    <div style={{
      width: 'auto', height: 44, borderRadius: 10, flexShrink: 0,
      background: paper2, padding: '0 10px',
      display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 1,
      fontFamily: 'JetBrains Mono', fontVariantNumeric: 'tabular-nums',
    }}>
      <div style={{ fontSize: 12, fontWeight: 700, color: ink }}>{a}</div>
      <div style={{ fontSize: 11, color: muted }}>{b}</div>
    </div>
  );
}

const ACTION_LABELS = {
  accept:      { l: 'Accept',      primary: true },
  decline:     { l: 'Decline',     primary: false },
  approve:     { l: 'Approve',     primary: true },
  reject:      { l: 'Reject',      primary: false },
  view:        { l: 'View',        primary: false },
  share:       { l: 'Share',       primary: false },
  followBack:  { l: 'Follow back', primary: true },
  mute:        { l: 'Mute',        primary: false },
  review:      { l: 'Review',      primary: true },
};

function ActionBtn({ kind, onClick }) {
  const m = ACTION_LABELS[kind] || { l: kind, primary: false };
  return (
    <button onClick={onClick} style={{
      padding: '7px 12px', borderRadius: 999,
      border: m.primary ? 'none' : '1px solid ' + hair,
      background: m.primary ? ink : paper,
      color: m.primary ? paper : ink,
      fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
    }}>{m.l}</button>
  );
}

// ─── notification row ─────────────────────────────────
function Row({ n, onAction }) {
  const c = CAT[n.cat] || CAT.system;

  // Decide leading element: bigStat > scoreChip > catIcon (+ avatar overlay if actor)
  const lead = n.bigStat ? <BigStat {...n.bigStat} />
             : n.score   ? <ScoreChip {...n.score} />
             : <CatIcon cat={n.cat} />;

  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 12,
      padding: '14px 18px',
      background: n.unread ? 'oklch(0.985 0.008 85 / 1)' : 'transparent',
      borderTop: '1px solid ' + hair,
      position: 'relative',
    }}>
      {/* unread dot at left edge */}
      {n.unread && (
        <span style={{
          position: 'absolute', left: 7, top: 24,
          width: 6, height: 6, borderRadius: 999, background: red,
        }} />
      )}

      {/* leading icon / avatar */}
      <div style={{ position: 'relative', flexShrink: 0 }}>
        {lead}
        {n.actor && !n.bigStat && !n.score && (
          <div style={{
            position: 'absolute', right: -4, bottom: -4,
            width: 18, height: 18, borderRadius: 999,
            background: ink, color: paper,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontSize: 8, fontWeight: 700, letterSpacing: '-0.02em',
            border: '2px solid ' + paper,
          }}>{n.actor.mono}</div>
        )}
      </div>

      {/* content */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 2 }}>
          <div style={{ fontFamily: 'Inter', fontSize: 13.5, fontWeight: 500, color: ink, lineHeight: 1.35, flex: 1, minWidth: 0 }}>
            {n.body}
          </div>
          <span style={{ ...mono, fontSize: 9.5, flexShrink: 0 }}>{n.t}</span>
        </div>
        {n.sub && (
          <div style={{ fontSize: 11.5, color: muted, lineHeight: 1.4, marginTop: 2 }}>
            {n.sub}
          </div>
        )}
        {n.role && (
          <div style={{ ...mono, fontSize: 9.5, color: ink2, marginTop: 4, letterSpacing: '0.06em' }}>{n.role}</div>
        )}
        {(n.actions || n.pill) && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            {n.pill && <Pill tone={n.pill.tone}>{n.pill.text}</Pill>}
            {(n.actions || []).map(k => (
              <ActionBtn key={k} kind={k} onClick={() => onAction && onAction(n.id, k)} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ─── main component ───────────────────────────────────
function CkNotifications({ variant = 'all' } = {}) {
  if (variant === 'empty') return <NotifEmpty />;

  const [filter, setFilter] = React.useState(variant === 'filtered' ? 'invites' : 'all');
  const [dismissed, setDismissed] = React.useState(new Set());
  const [reads, setReads] = React.useState(new Set());

  const filtered = NOTIFS
    .filter(n => !dismissed.has(n.id))
    .map(n => reads.has(n.id) ? { ...n, unread: false } : n)
    .filter(n => {
      if (filter === 'all') return true;
      if (filter === 'unread') return n.unread;
      const c = CAT[n.cat] || CAT.system;
      return c.bucket === filter;
    });

  const grouped = {
    today:     filtered.filter(n => n.day === 'today'),
    yesterday: filtered.filter(n => n.day === 'yesterday'),
    week:      filtered.filter(n => n.day === 'week'),
    earlier:   filtered.filter(n => n.day === 'earlier'),
  };
  const unreadCount = NOTIFS.filter(n => n.unread && !reads.has(n.id)).length;

  const onAction = (id, action) => {
    if (action === 'decline' || action === 'reject' || action === 'mute') {
      setDismissed(prev => new Set([...prev, id]));
    } else {
      setReads(prev => new Set([...prev, id]));
    }
  };
  const markAllRead = () => setReads(new Set(NOTIFS.map(n => n.id)));

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* ── Header ─────────────────────────────────── */}
      <div style={{ padding: '12px 18px 10px', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
          <h1 style={display(28)}>Notifications</h1>
          <div style={{ display: 'flex', gap: 6 }}>
            <button onClick={markAllRead} style={{
              background: 'transparent', border: '1px solid ' + hair, borderRadius: 999,
              padding: '6px 10px', cursor: 'pointer',
              ...mono, color: ink2, fontSize: 9.5,
            }}>MARK ALL READ</button>
            <button style={{
              background: 'transparent', border: '1px solid ' + hair, borderRadius: 10,
              width: 32, height: 32, padding: 0, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: ink,
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="2.5"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.36.16.66.42.87.74"/></svg>
            </button>
          </div>
        </div>
        <div style={{ fontSize: 12, color: muted }}>
          {unreadCount > 0
            ? <><span style={{ color: ink, fontWeight: 600 }}>{unreadCount} new</span> · {NOTIFS.length - dismissed.size} total</>
            : <>All caught up · {NOTIFS.length - dismissed.size} total</>}
        </div>
      </div>

      {/* ── Filter chip rail ───────────────────────── */}
      <div style={{
        display: 'flex', gap: 6, padding: '6px 18px 12px',
        overflowX: 'auto', flexShrink: 0,
        scrollbarWidth: 'none',
        borderBottom: '1px solid ' + hair,
      }}>
        {FILTERS.map(f => {
          const active = filter === f.k;
          const count = f.k === 'unread' ? unreadCount
            : f.k === 'all' ? null
            : NOTIFS.filter(n => (CAT[n.cat] || CAT.system).bucket === f.k && !dismissed.has(n.id)).length;
          return (
            <button key={f.k} onClick={() => setFilter(f.k)} style={{
              padding: '7px 12px', borderRadius: 999, flexShrink: 0, cursor: 'pointer',
              border: active ? 'none' : '1px solid ' + hair,
              background: active ? ink : paper,
              color: active ? paper : ink2,
              fontFamily: 'Inter', fontSize: 12, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 6,
            }}>
              <span>{f.l}</span>
              {count != null && count > 0 && (
                <span style={{
                  ...mono, fontSize: 9, fontWeight: 700,
                  color: active ? ink : muted, background: active ? paper : paper2,
                  padding: '0 5px', borderRadius: 4, lineHeight: '14px', minWidth: 14, textAlign: 'center',
                }}>{count}</span>
              )}
            </button>
          );
        })}
      </div>

      {/* ── List ───────────────────────────────────── */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {filtered.length === 0 ? (
          <FilteredEmpty filter={filter} />
        ) : (
          <>
            {grouped.today.length > 0     && <Section label="TODAY"     count={grouped.today.length}>     {grouped.today.map(n => <Row key={n.id} n={n} onAction={onAction} />)}</Section>}
            {grouped.yesterday.length > 0 && <Section label="YESTERDAY" count={grouped.yesterday.length}> {grouped.yesterday.map(n => <Row key={n.id} n={n} onAction={onAction} />)}</Section>}
            {grouped.week.length > 0      && <Section label="THIS WEEK" count={grouped.week.length}>      {grouped.week.map(n => <Row key={n.id} n={n} onAction={onAction} />)}</Section>}
            {grouped.earlier.length > 0   && <Section label="EARLIER"   count={grouped.earlier.length}>   {grouped.earlier.map(n => <Row key={n.id} n={n} onAction={onAction} />)}</Section>}
            <div style={{ padding: '22px 18px 32px', textAlign: 'center', borderTop: '1px solid ' + hair }}>
              <button style={{
                ...mono, fontSize: 10, color: muted, letterSpacing: '0.10em',
                background: 'transparent', border: 'none', cursor: 'pointer',
              }}>NOTIFICATION SETTINGS  ›</button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function Section({ label, count, children }) {
  return (
    <div>
      <div style={{
        padding: '16px 18px 6px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
        background: paper,
      }}>
        <span style={mono}>{label}</span>
        <span style={{ ...mono, color: ink2 }}>{count}</span>
      </div>
      {children}
    </div>
  );
}

function FilteredEmpty({ filter }) {
  const msg = {
    all:         { t: "You're all caught up.",         s: 'New notifications will land here.' },
    unread:      { t: 'Inbox zero.',                   s: 'Nothing unread — enjoy the moment.' },
    invites:     { t: 'No pending invites.',           s: 'Team, scorer, claim and friendly requests will appear here.' },
    matches:     { t: 'No match alerts right now.',    s: 'Reminders, results and rescheduling land here.' },
    tournaments: { t: 'No tournament alerts.',         s: 'Registrations, fixtures and awards will show up here.' },
    milestones:  { t: 'No new milestones yet.',        s: 'Centuries, 5-fers and ranking jumps will be celebrated here.' },
    social:      { t: 'Nothing social just now.',      s: 'Mentions, comments and new followers will surface here.' },
    system:      { t: 'No system messages.',           s: 'Account and security updates will appear here.' },
  }[filter] || { t: 'Nothing here.', s: '' };

  return (
    <div style={{
      padding: '70px 32px', textAlign: 'center',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 16, background: paper2, color: muted,
        display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 6,
      }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>
      </div>
      <div style={display(18)}>{msg.t}</div>
      <div style={{ fontSize: 13, color: muted, lineHeight: 1.45, maxWidth: 280 }}>{msg.s}</div>
    </div>
  );
}

// ─── Empty / first-load state ─────────────────────────
function NotifEmpty() {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      <div style={{ padding: '12px 18px 6px', flexShrink: 0 }}>
        <h1 style={display(28)}>Notifications</h1>
        <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>Nothing yet — but here's what you'll get.</div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>

        {/* Hero empty crest */}
        <div style={{
          margin: '8px auto 18px', width: 96, height: 96, borderRadius: 24,
          background: paper2, color: ink2,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative',
        }}>
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>
          <span style={{
            position: 'absolute', right: -2, top: -2,
            width: 18, height: 18, borderRadius: 999, background: red,
            border: '3px solid ' + paper,
          }} />
        </div>

        <h2 style={{ ...display(22), textAlign: 'center', marginBottom: 6 }}>You'll hear from us when it matters.</h2>
        <p style={{ fontSize: 13.5, color: muted, lineHeight: 1.5, textAlign: 'center', margin: '0 auto 22px', maxWidth: 300 }}>
          A short, opinionated list — not a feed. Tune what you want in settings.
        </p>

        {/* Categories preview */}
        <div style={{ background: surface, border: '1px solid ' + hair, borderRadius: 14, overflow: 'hidden', marginBottom: 16 }}>
          {[
            { cat: 'invite',      t: 'Invites & requests',  d: 'Team invites · scorer · co-manager · claim approvals' },
            { cat: 'match',       t: 'Match alerts',        d: 'Toss reminder · XI deadline · live · result · MOM' },
            { cat: 'tournament',  t: 'Tournament alerts',   d: 'Registration · fixtures · brackets · awards' },
            { cat: 'milestone',   t: 'Milestones',          d: 'Fifty, century, 5-fer, ranking jumps' },
            { cat: 'social',      t: 'Social',              d: 'Mentions · comments · follows · recruitment matches' },
            { cat: 'system',      t: 'System',              d: 'Verification · security · account changes' },
          ].map((c, i) => (
            <div key={c.cat} style={{ display: 'flex', gap: 12, padding: '14px 14px', borderTop: i ? '1px solid ' + hair : 'none', alignItems: 'flex-start' }}>
              <CatIcon cat={c.cat} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>{c.t}</div>
                <div style={{ fontSize: 11.5, color: muted, marginTop: 2, lineHeight: 1.4 }}>{c.d}</div>
              </div>
              <div style={{
                width: 30, height: 18, borderRadius: 999, background: ink, position: 'relative',
                flexShrink: 0, marginTop: 8,
              }}>
                <span style={{
                  position: 'absolute', right: 2, top: 2, width: 14, height: 14, borderRadius: 999, background: paper,
                }} />
              </div>
            </div>
          ))}
        </div>

        {/* Push permission CTA */}
        <div style={{
          padding: 14, borderRadius: 14, background: ink, color: paper,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10, background: 'rgba(255,255,255,0.1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <NotifIcon kind="envelope" size={16} color="white" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 600 }}>Allow push notifications</div>
            <div style={{ fontSize: 11, opacity: 0.7, marginTop: 1 }}>So you don't miss your match starting.</div>
          </div>
          <button style={{
            background: paper, color: ink, border: 'none', borderRadius: 999,
            padding: '7px 12px', fontFamily: 'Inter', fontWeight: 600, fontSize: 12, cursor: 'pointer',
          }}>Turn on</button>
        </div>

      </div>
    </div>
  );
}

window.CkNotifications = CkNotifications;

})();

// Feed.jsx — Circk Home Feed v2 (editorial / matchday-paper direction)
// Spec: 6.1–6.10. All post types: Text, Photo, MatchAnnouncement, Recruitment,
// TournamentUpdate, MilestoneAchievement (auto). Engagement: like, comment, save, share.
// Filters: All / People / Teams / Tournaments / Match. Empty filter → suggested follows.

const FEED_TABS = [
  { id: 'home', label: 'Home' },
  { id: 'matches', label: 'Matches' },
  { id: 'tour', label: 'Tournaments' },
  { id: 'profile', label: 'You' },
];

const FILTERS = [
  { id: 'all', label: 'All' },
  { id: 'people', label: 'People' },
  { id: 'teams', label: 'Teams' },
  { id: 'tour', label: 'Tournaments' },
  { id: 'match', label: 'Match' },
];

// Reverse-chrono. `bucket` groups into day sections.
// Live matches now live in the Matches tab — the home feed shows social posts only,
// with a slim "Live now" rail surfaced at the top of this screen as an entry point.
const LIVE_NOW = [
  {
    id: 'lr1', mine: true, tag: "Spring Cup · QF",
    home: { short: 'LAH', color: 'oklch(0.62 0.19 28)', runs: 132, wickets: 4, ov: '14.3', batting: true },
    away: { short: 'CTY', color: 'oklch(0.42 0.10 260)', runs: 178, wickets: 10, ov: '20.0' },
    need: 47, ballsLeft: 33,
  },
  {
    id: 'lr2', mine: false, tag: "Friday Night League",
    home: { short: 'DHA', color: 'oklch(0.42 0.10 260)', runs: 88, wickets: 2, ov: '12.0', batting: true },
    away: { short: 'MOH', color: 'oklch(0.78 0.14 80)', runs: null, wickets: null, ov: '—' },
    need: null, ballsLeft: null,
  },
  {
    id: 'lr3', mine: false, tag: "Tape Ball Cup",
    home: { short: 'OB',  color: 'oklch(0.36 0.04 80)',  runs: 64, wickets: 6, ov: '9.4' },
    away: { short: 'GAL', color: 'oklch(0.55 0.12 200)', runs: 45, wickets: 3, ov: '7.2', batting: true },
    need: 20, ballsLeft: 76,
  },
];

const POSTS = [
  {
    id: 'p1', kind: 'matchAnnouncement', filter: ['teams', 'match'], bucket: 'today',
    author: { name: 'Lahore Lions', handle: 'lahore-lions', kind: 'team', color: 'oklch(0.62 0.19 28)' },
    postedBy: { name: 'Imran K.', role: 'Manager' },
    time: '12m',
    text: 'Friday 6 PM — playoff vs City Eagles. Model Town pitch. We need a 12th. DM if available.',
    linkedMatch: { home: 'Lahore Lions', homeShort: 'LAH', away: 'City Eagles', awayShort: 'CTY', when: 'Fri 14 Mar · 6:00 PM', venue: 'Model Town', status: 'Upcoming', homeColor: 'oklch(0.62 0.19 28)', awayColor: 'oklch(0.42 0.10 260)' },
    likes: 23, comments: 8, saved: false, liked: false,
  },
  {
    id: 'p3', kind: 'milestone', filter: ['people', 'match'], bucket: 'today',
    time: '38m',
    player: { name: 'Ahmed Khan', handle: 'ahmed', initials: 'AK', color: 'oklch(0.62 0.19 28)', team: 'Lahore Lions' },
    achievement: 'FIFTY',
    bigStat: '52',
    statSub: 'off 41',
    breakdown: ['5 fours', '2 sixes', 'SR 126.8'],
    contextEntity: "Spring Cup '26 · QF · vs City Eagles",
    likes: 142, comments: 14, saved: false, liked: false,
  },
  {
    id: 'p4', kind: 'photo', filter: ['people'], bucket: 'today',
    author: { name: 'Sahil Kapoor', handle: 'sahil', kind: 'user', initials: 'SK', color: 'oklch(0.42 0.10 260)' },
    time: '2h',
    text: 'Maiden hundred today 🥹 thanks to the @lahore-lions boys for backing me up.',
    photo: { color: 'oklch(0.62 0.19 28)', label: 'SIX', score: '107* (62)' },
    photoCount: 3,
    linkedTeam: 'Lahore Lions',
    likes: 87, comments: 22, saved: true, liked: true,
  },
  {
    id: 'p5', kind: 'recruitment', filter: ['teams'], bucket: 'today',
    author: { name: 'DHA United', handle: 'dha-united', kind: 'team', color: 'oklch(0.42 0.10 260)' },
    postedBy: { name: 'Bilal S.', role: 'Captain' },
    time: '4h',
    role: 'Right-arm fast bowler',
    body: 'One quick needed for the Sunday League. Ages 18–28. Tape ball, evening matches at Gulberg.',
    location: 'Lahore · Gulberg',
    deadline: 'Apply by Wed',
    spotsLeft: 1,
    likes: 34, comments: 19, saved: false, liked: false,
  },
  {
    id: 'p6', kind: 'tournamentUpdate', filter: ['tour'], bucket: 'yesterday',
    author: { name: "Spring Cup '26", handle: 'spring-cup-26', kind: 'tournament', color: 'oklch(0.18 0.02 80)' },
    postedBy: { name: 'You', role: 'Organizer' },
    time: '1d',
    headline: 'Round 2 fixtures announced',
    body: '4 quarterfinals across this weekend. Brackets locked.',
    fixtures: [
      { a: 'Lions', b: 'Eagles', when: 'Fri 6 PM', highlight: true },
      { a: 'Kings', b: 'Old Boys', when: 'Sat 5 PM' },
      { a: 'DHA U.', b: 'New School', when: 'Sat 7 PM' },
      { a: 'Galle B.', b: 'Royal M.', when: 'Sun 6 PM' },
    ],
    likes: 56, comments: 11, saved: false, liked: false,
  },
  {
    id: 'p7', kind: 'text', filter: ['people'], bucket: 'thisWeek',
    author: { name: 'Tariq M.', handle: 'tariq', kind: 'user', initials: 'TM', color: 'oklch(0.45 0.05 240)' },
    time: '2d',
    text: "Best match of the season was our final last summer. Down 60 in 5, then Asad walks in and hits 78 off 30. Cricket's a wild game.",
    likes: 41, comments: 9, saved: false, liked: false,
  },
];

const SUGGESTIONS = [
  { name: 'Mohalla Kings', kind: 'team', meta: '12 followers in your area', color: 'oklch(0.78 0.14 80)' },
  { name: 'Friday Night League', kind: 'tournament', meta: 'Starting next week · Lahore', color: 'oklch(0.56 0.13 148)' },
  { name: 'Asad Mahmood', kind: 'user', meta: 'Top batter · Lahore', color: 'oklch(0.42 0.10 260)' },
];

const BUCKET_LABELS = {
  today: { label: 'TODAY', side: 'Fri 14 Mar' },
  yesterday: { label: 'YESTERDAY', side: 'Thu 13 Mar' },
  thisWeek: { label: 'THIS WEEK', side: '' },
};

// =========================================================================
// LIVE NOW RAIL — slim horizontal entry point at top of feed.
// Links to the Matches tab where the actual scoreboards live.
// =========================================================================
function LiveNowRail({ matches, onSeeAll, onOpen }) {
  if (!matches || matches.length === 0) return null;
  return (
    <div style={{ borderBottom: '1px solid var(--hairline)', background: 'var(--paper)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 20px 4px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{ position: 'relative', width: 7, height: 7 }}>
            <span style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'var(--red)' }} />
            <span style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'var(--red)', animation: 'ckPing 1.6s ease-out infinite' }} />
          </span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.14em', color: 'var(--ink)' }}>LIVE NOW</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>· {matches.length}</span>
        </div>
        <button onClick={onSeeAll} style={{ background: 'transparent', border: 'none', color: 'var(--red)', fontFamily: 'inherit', fontSize: 11, fontWeight: 700, letterSpacing: '0.04em', cursor: 'pointer', padding: 0 }}>
          MATCHES TAB →
        </button>
      </div>
      <div style={{ display: 'flex', gap: 8, padding: '8px 20px 12px', overflowX: 'auto', scrollbarWidth: 'none' }}>
        {matches.map(m => {
          const bat = m.home.batting ? m.home : m.away;
          const bowl = m.home.batting ? m.away : m.home;
          return (
            <button key={m.id} onClick={() => onOpen(m)} style={{
              flex: 'none', minWidth: 188, padding: 0,
              background: 'oklch(0.18 0.02 80)', color: 'white',
              border: 'none', borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
              boxShadow: m.mine ? '0 0 0 2px var(--red)' : '0 1px 3px rgba(0,0,0,0.12)',
              overflow: 'hidden',
            }}>
              <div style={{ padding: '6px 10px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <span style={{ width: 5, height: 5, borderRadius: 999, background: 'var(--red)' }} />
                  <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.1em' }}>LIVE</span>
                  {m.mine && <span style={{ fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.08em' }}>· YOU</span>}
                </div>
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: 8, color: 'rgba(255,255,255,0.5)', letterSpacing: '0.06em', textTransform: 'uppercase', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 88 }}>{m.tag}</span>
              </div>
              <div style={{ padding: '8px 10px', display: 'flex', flexDirection: 'column', gap: 5 }}>
                {[m.home, m.away].map((t, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 7, opacity: t.batting || t === m.home ? 1 : 0.55 }}>
                    <div style={{ width: 18, height: 18, borderRadius: 4, background: t.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 9 }}>{t.short}</div>
                    <div style={{ flex: 1, fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.01em' }}>
                      {t.runs != null ? <>{t.runs}<span style={{ color: 'rgba(255,255,255,0.45)', fontWeight: 500 }}>/{t.wickets}</span></> : <span style={{ color: 'rgba(255,255,255,0.4)', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 500, letterSpacing: '0.06em' }}>YET TO BAT</span>}
                    </div>
                    <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'rgba(255,255,255,0.55)' }}>{t.ov}</div>
                    {t.batting && <span style={{ width: 5, height: 5, borderRadius: 999, background: 'var(--red)' }} />}
                  </div>
                ))}
              </div>
              {m.need != null && (
                <div style={{ padding: '5px 10px 7px', borderTop: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.04)', fontFamily: 'JetBrains Mono', fontSize: 9, color: 'rgba(255,255,255,0.85)', letterSpacing: '0.04em' }}>
                  NEED <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11, color: 'white' }}>{m.need}</span> off <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11, color: 'white' }}>{m.ballsLeft}</span>
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

// =========================================================================
// Top chrome — editorial header
// =========================================================================
function FeedHeader({ unread = 3 }) {
  const today = 'Fri · 14 Mar';
  return (
    <div style={{ padding: '14px 20px 12px', borderBottom: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>
            CIRCK · {today.toUpperCase()}
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 28, letterSpacing: '-0.035em', lineHeight: 1.05, marginTop: 2 }}>
            Matchday<span style={{ color: 'var(--red)' }}>.</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', paddingTop: 6 }}>
          <button style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'var(--ink)' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
          </button>
          <button style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'var(--ink)', position: 'relative' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
            {unread > 0 && (
              <div style={{ position: 'absolute', top: -3, right: -5, minWidth: 14, height: 14, borderRadius: 999, background: 'var(--red)', border: '1.5px solid var(--paper)', color: 'white', fontSize: 8, fontFamily: 'JetBrains Mono', fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 3px' }}>{unread}</div>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

function TabBar({ active, setActive }) {
  const icons = {
    home: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/></svg>,
    matches: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9"/><path d="M3.6 9h16.8M3.6 15h16.8M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>,
    tour: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6M18 9h1.5a2.5 2.5 0 0 0 0-5H18M4 22h16M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22M18 2H6v7a6 6 0 0 0 12 0z"/></svg>,
    profile: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>,
  };
  return (
    <div style={{ display: 'flex', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', padding: '8px 8px 22px' }}>
      {FEED_TABS.map(t => (
        <button key={t.id} onClick={() => setActive(t.id)} style={{
          flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, padding: '6px 0',
          background: 'transparent', border: 'none',
          color: active === t.id ? 'var(--ink)' : 'var(--muted)', cursor: 'pointer', fontFamily: 'inherit',
        }}>
          {icons[t.id]}
          <div style={{ fontSize: 10, fontWeight: 600 }}>{t.label}</div>
          <div style={{ width: 14, height: 2, borderRadius: 2, background: active === t.id ? 'var(--red)' : 'transparent' }} />
        </button>
      ))}
    </div>
  );
}

function Fab({ onClick }) {
  const [pressed, setPressed] = React.useState(false);
  return (
    <button onClick={onClick} onMouseDown={() => setPressed(true)} onMouseUp={() => setPressed(false)} onMouseLeave={() => setPressed(false)}
      style={{
        position: 'absolute', right: 18, bottom: 88, width: 56, height: 56, borderRadius: 28,
        background: 'var(--red)', color: 'white', border: 'none',
        boxShadow: '0 8px 22px rgba(190,60,40,0.35), 0 2px 6px rgba(190,60,40,0.2)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        cursor: 'pointer', zIndex: 20, transform: pressed ? 'scale(0.94)' : 'scale(1)', transition: 'transform .12s',
      }}>
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>
    </button>
  );
}

// =========================================================================
// Day divider — editorial section break
// =========================================================================
function DayDivider({ bucket }) {
  const cfg = BUCKET_LABELS[bucket];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0 2px' }}>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: bucket === 'now' ? 'var(--red)' : 'var(--ink)', letterSpacing: '0.14em' }}>
        {cfg.label}
      </div>
      <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
      {cfg.side && <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>{cfg.side}</div>}
    </div>
  );
}

// =========================================================================
// Compact author rail (replaces big avatar header on most cards)
// =========================================================================
function ByLine({ author, postedBy, time, autoGenerated, kindLabel }) {
  const isTeam = author.kind === 'team';
  const isTour = author.kind === 'tournament';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px 4px' }}>
      <div style={{
        width: 22, height: 22, borderRadius: isTeam || isTour ? 5 : 999,
        background: author.color, color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontSize: 9, fontWeight: 700, flex: 'none',
      }}>
        {author.initials || author.name.split(' ').map(w => w[0]).slice(0, 2).join('')}
      </div>
      <span style={{ fontSize: 12, fontWeight: 600 }}>{author.name}</span>
      {kindLabel && <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.06em' }}>· {kindLabel}</span>}
      {postedBy && <span style={{ fontSize: 11, color: 'var(--muted)' }}>· by {postedBy.name}</span>}
      <div style={{ flex: 1 }} />
      <span style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>{time}</span>
      <button style={{ background: 'transparent', border: 'none', color: 'var(--muted)', cursor: 'pointer', padding: 0, marginLeft: 4 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="6" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="12" cy="18" r="1.4"/></svg>
      </button>
    </div>
  );
}

function EngagementBar({ post, onLike, onSave, onComment, onShare, dark }) {
  const c = dark ? 'rgba(255,255,255,0.85)' : 'var(--ink-2)';
  const cMute = dark ? 'rgba(255,255,255,0.6)' : 'var(--muted)';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '10px 14px 12px', borderTop: dark ? '1px solid rgba(255,255,255,0.12)' : '1px solid var(--hairline)' }}>
      <button onClick={onLike} style={{ display: 'flex', alignItems: 'center', gap: 5, background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', fontFamily: 'inherit', color: post.liked ? 'var(--red)' : c }}>
        <svg width="17" height="17" viewBox="0 0 24 24" fill={post.liked ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
        <span style={{ fontSize: 12, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{post.likes + (post.liked ? 1 : 0)}</span>
      </button>
      <button onClick={onComment} style={{ display: 'flex', alignItems: 'center', gap: 5, background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', fontFamily: 'inherit', color: c }}>
        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>
        <span style={{ fontSize: 12, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{post.comments}</span>
      </button>
      <button onClick={onShare} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: c }}>
        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 12v7a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-7M16 6l-4-4-4 4M12 2v13"/></svg>
      </button>
      <div style={{ flex: 1 }} />
      <button onClick={onSave} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: post.saved ? (dark ? 'white' : 'var(--ink)') : cMute }}>
        <svg width="17" height="17" viewBox="0 0 24 24" fill={post.saved ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>
      </button>
    </div>
  );
}

function LinkChip({ icon, label, onClick, dark }) {
  return (
    <button onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '4px 9px', borderRadius: 999,
      border: dark ? '1px solid rgba(255,255,255,0.18)' : '1px solid var(--hairline)',
      background: dark ? 'rgba(255,255,255,0.06)' : 'var(--paper)',
      color: dark ? 'rgba(255,255,255,0.85)' : 'var(--ink-2)',
      fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
    }}>
      {icon}{label}
    </button>
  );
}

// =========================================================================
// LIVE HERO — full-bleed dark scoreboard, anchors the feed
// =========================================================================
function LiveHero({ post, onLink }) {
  const [score, setScore] = React.useState({ runs: post.home.baseRuns, wickets: post.home.baseWickets, balls: post.home.baseBalls });
  const [lastBall, setLastBall] = React.useState('1');
  const [pulse, setPulse] = React.useState(0);
  React.useEffect(() => {
    const id = setInterval(() => {
      const opts = ['0','0','1','1','1','2','4','W','6','·'];
      const ball = opts[Math.floor(Math.random()*opts.length)];
      setLastBall(ball);
      setPulse(p => p + 1);
      setScore(s => {
        let dr = 0, dw = 0;
        if (ball === 'W') dw = 1;
        else if (ball === '·') dr = 0;
        else if (ball === '4') dr = 4;
        else if (ball === '6') dr = 6;
        else dr = parseInt(ball) || 0;
        return { runs: s.runs + dr, wickets: Math.min(10, s.wickets + dw), balls: Math.min(120, s.balls + 1) };
      });
    }, 2800);
    return () => clearInterval(id);
  }, []);
  const need = Math.max(0, post.target - score.runs);
  const ballsLeft = Math.max(0, 120 - score.balls);
  const ov = Math.floor(score.balls / 6);
  const b = score.balls % 6;
  const rr = (score.runs / Math.max(1, score.balls / 6)).toFixed(2);
  const reqRR = ballsLeft > 0 ? (need / Math.max(1, ballsLeft / 6)).toFixed(2) : '—';

  return (
    <button onClick={() => onLink('match')} style={{
      width: '100%', borderRadius: 14, padding: 0, background: 'oklch(0.18 0.02 80)', color: 'white',
      border: 'none', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer', overflow: 'hidden',
      boxShadow: '0 4px 14px rgba(0,0,0,0.18)',
    }}>
      {/* top strip */}
      <div style={{ padding: '10px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ position: 'relative', width: 8, height: 8 }}>
            <span style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'var(--red)' }} />
            <span key={pulse} style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'var(--red)', animation: 'ckPing 1.4s ease-out' }} />
          </span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.14em' }}>LIVE</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.6)', letterSpacing: '0.06em' }}>· {post.tag.toUpperCase()}</span>
        </div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)' }}>{post.venue}</div>
      </div>

      {/* dual-team scoreboard */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
        {/* Away (1st innings, complete) */}
        <div style={{ padding: '14px', borderRight: '1px solid rgba(255,255,255,0.1)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ width: 24, height: 24, borderRadius: 5, background: post.away.color, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 10 }}>{post.away.short}</div>
            <span style={{ fontSize: 12, fontWeight: 600 }}>{post.away.name}</span>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 32, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.03em', lineHeight: 1 }}>
            {post.away.runs}<span style={{ color: 'rgba(255,255,255,0.45)', fontWeight: 600, fontSize: 24 }}>/{post.away.wickets}</span>
          </div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)', marginTop: 4, letterSpacing: '0.04em' }}>
            (20.0) · COMPLETE
          </div>
        </div>
        {/* Home (chasing) */}
        <div style={{ padding: '14px', position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ width: 24, height: 24, borderRadius: 5, background: post.home.color, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 10 }}>{post.home.short}</div>
            <span style={{ fontSize: 12, fontWeight: 600 }}>{post.home.name}</span>
            <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--red)', letterSpacing: '0.08em', fontWeight: 700 }}>BAT</span>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 32, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.03em', lineHeight: 1 }}>
            {score.runs}<span style={{ color: 'rgba(255,255,255,0.45)', fontWeight: 600, fontSize: 24 }}>/{score.wickets}</span>
          </div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.7)', marginTop: 4, letterSpacing: '0.04em' }}>
            ({ov}.{b}) · RR {rr}
          </div>
        </div>
      </div>

      {/* equation strip */}
      <div style={{ padding: '10px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderTop: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.04)' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.08em' }}>NEED</span>
          <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.01em' }}>{need}</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)' }}>off</span>
          <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18, fontVariantNumeric: 'tabular-nums' }}>{ballsLeft}</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)' }}>balls</span>
        </div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.7)', letterSpacing: '0.06em' }}>
          REQ {reqRR}
        </div>
      </div>

      {/* striker / non-striker / bowler */}
      <div style={{ padding: '10px 14px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, borderTop: '1px solid rgba(255,255,255,0.1)' }}>
        <div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>STRIKER*</div>
          <div style={{ fontSize: 12, fontWeight: 600, marginTop: 2 }}>{post.striker.name}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'rgba(255,255,255,0.7)', marginTop: 1 }}>{post.striker.runs} ({post.striker.balls})</div>
        </div>
        <div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>NON-STR</div>
          <div style={{ fontSize: 12, fontWeight: 600, marginTop: 2 }}>{post.nonStriker.name}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'rgba(255,255,255,0.7)', marginTop: 1 }}>{post.nonStriker.runs} ({post.nonStriker.balls})</div>
        </div>
        <div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>BOWLER</div>
          <div style={{ fontSize: 12, fontWeight: 600, marginTop: 2 }}>{post.bowler.name}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'rgba(255,255,255,0.7)', marginTop: 1 }}>{post.bowler.figures}</div>
        </div>
      </div>

      {/* last 6 balls */}
      <div style={{ padding: '10px 14px 14px', display: 'flex', alignItems: 'center', gap: 8, borderTop: '1px solid rgba(255,255,255,0.1)' }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.08em' }}>THIS OVER</span>
        <div style={{ display: 'flex', gap: 4, flex: 1 }}>
          {['1','·','4','0','W',lastBall].map((b, i) => (
            <span key={i} style={{
              width: 22, height: 22, borderRadius: 999,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700,
              background: b === '4' ? 'oklch(0.56 0.13 148)' : b === '6' ? 'var(--red)' : b === 'W' ? 'oklch(0.5 0.15 28)' : 'rgba(255,255,255,0.1)',
              color: 'white',
              opacity: i === 5 ? 1 : 0.85,
              transform: i === 5 ? 'scale(1.05)' : 'scale(1)',
              transition: 'transform .25s',
            }}>{b}</span>
          ))}
        </div>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'rgba(255,255,255,0.85)' }}>→</span>
      </div>
    </button>
  );
}

// =========================================================================
// MILESTONE — paper-style, big typographic moment
// =========================================================================
function MilestoneCard({ post, onAction, onLink }) {
  return (
    <article style={{ borderRadius: 14, overflow: 'hidden', background: 'var(--paper)', border: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderBottom: '1px dashed var(--hairline)' }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'oklch(0.55 0.13 50)', padding: '2px 6px', borderRadius: 4, background: 'oklch(0.96 0.06 80)', letterSpacing: '0.1em' }}>MILESTONE · AUTO</span>
        <div style={{ flex: 1 }} />
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{post.time}</span>
      </div>

      <div style={{ padding: '20px 16px 14px' }}>
        {/* big number */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12 }}>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 88, lineHeight: 0.85, letterSpacing: '-0.05em', fontVariantNumeric: 'tabular-nums' }}>
            {post.bigStat}
          </div>
          <div style={{ paddingBottom: 12 }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em' }}>{post.statSub.toUpperCase()}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.16em', marginTop: 2 }}>{post.achievement}</div>
          </div>
        </div>

        {/* player line */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, paddingTop: 10, borderTop: '1px solid var(--hairline)' }}>
          <div style={{ width: 26, height: 26, borderRadius: 999, background: post.player.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 700, flex: 'none' }}>{post.player.initials}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 700 }}>{post.player.name}</div>
            <div style={{ fontSize: 11, color: 'var(--muted)' }}>{post.player.team}</div>
          </div>
        </div>

        {/* breakdown */}
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 10 }}>
          {post.breakdown.map((b, i) => (
            <span key={i} style={{ fontFamily: 'JetBrains Mono', fontSize: 10, padding: '3px 7px', borderRadius: 4, background: 'var(--paper-2)', color: 'var(--ink-2)', letterSpacing: '0.04em' }}>{b}</span>
          ))}
        </div>

        <div style={{ marginTop: 12, paddingTop: 10, borderTop: '1px dashed var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 11, color: 'var(--muted)' }}>from <strong style={{ color: 'var(--ink-2)', fontWeight: 600 }}>{post.contextEntity}</strong></div>
          <button onClick={() => onLink('match')} style={{ background: 'transparent', border: 'none', padding: 0, color: 'var(--red)', fontFamily: 'inherit', fontSize: 11, fontWeight: 700, cursor: 'pointer' }}>SEE INNINGS →</button>
        </div>
      </div>

      <EngagementBar post={post} onLike={() => onAction('like')} onSave={() => onAction('save')} onComment={() => onAction('comment')} onShare={() => onAction('share')} />
    </article>
  );
}

// =========================================================================
// MATCH ANNOUNCEMENT — versus block + RSVP-style action
// =========================================================================
function MatchAnnouncementCard({ post, onAction, onLink }) {
  const m = post.linkedMatch;
  const [going, setGoing] = React.useState(null);
  return (
    <article style={{ borderRadius: 14, border: '1px solid var(--hairline)', background: 'var(--paper)', overflow: 'hidden' }}>
      <ByLine author={post.author} postedBy={post.postedBy} time={post.time} kindLabel="TEAM" />
      <div style={{ padding: '4px 14px 12px', fontSize: 14, lineHeight: 1.45 }}>{post.text}</div>

      {/* versus block */}
      <button onClick={() => onLink('match')} style={{
        width: 'calc(100% - 28px)', margin: '0 14px 12px',
        background: 'var(--paper-2)', border: '1px solid var(--hairline)', borderRadius: 12,
        padding: 14, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>{m.status.toUpperCase()}</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)' }}>{m.when}</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 12 }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 36, height: 36, borderRadius: 8, background: m.homeColor, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700 }}>{m.homeShort}</div>
            <div style={{ fontSize: 11, fontWeight: 600, textAlign: 'center' }}>{m.home}</div>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18, color: 'var(--muted)', letterSpacing: '-0.02em' }}>vs</div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 36, height: 36, borderRadius: 8, background: m.awayColor, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700 }}>{m.awayShort}</div>
            <div style={{ fontSize: 11, fontWeight: 600, textAlign: 'center' }}>{m.away}</div>
          </div>
        </div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 12, textAlign: 'center', borderTop: '1px dashed var(--hairline)', paddingTop: 8 }}>📍 {m.venue}</div>
      </button>

      {/* RSVP */}
      <div style={{ display: 'flex', gap: 6, padding: '0 14px 12px' }}>
        {['Going', 'Maybe', "Can't"].map(opt => (
          <button key={opt} onClick={(e) => { e.stopPropagation(); setGoing(opt); }} style={{
            flex: 1, padding: '8px 10px', borderRadius: 10,
            border: '1px solid ' + (going === opt ? 'var(--ink)' : 'var(--hairline)'),
            background: going === opt ? 'var(--ink)' : 'transparent',
            color: going === opt ? 'var(--paper)' : 'var(--ink-2)',
            fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer',
          }}>{opt}</button>
        ))}
      </div>

      <EngagementBar post={post} onLike={() => onAction('like')} onSave={() => onAction('save')} onComment={() => onAction('comment')} onShare={() => onAction('share')} />
    </article>
  );
}

// =========================================================================
// PHOTO POST
// =========================================================================
function PhotoPost({ post, onAction }) {
  const [idx, setIdx] = React.useState(0);
  return (
    <article style={{ borderRadius: 14, border: '1px solid var(--hairline)', background: 'var(--paper)', overflow: 'hidden' }}>
      <ByLine author={post.author} time={post.time} />
      <div style={{ padding: '0 14px 10px', fontSize: 14, lineHeight: 1.45 }}>
        {post.text.split(/(@\w[\w-]+)/).map((seg, i) => seg.startsWith('@')
          ? <span key={i} style={{ color: 'var(--red)', fontWeight: 600 }}>{seg}</span>
          : <span key={i}>{seg}</span>
        )}
      </div>
      <div style={{ position: 'relative', height: 240, background: post.photo.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
        <svg width="360" height="360" viewBox="0 0 200 200" style={{ position: 'absolute', opacity: 0.18 }}>
          <ellipse cx="100" cy="100" rx="90" ry="58" stroke="white" fill="none" strokeWidth="0.5"/>
          <ellipse cx="100" cy="100" rx="60" ry="38" stroke="white" fill="none" strokeWidth="0.5"/>
          <line x1="100" y1="42" x2="100" y2="158" stroke="white" strokeWidth="0.4"/>
        </svg>
        <div style={{ position: 'relative', textAlign: 'center' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, opacity: 0.85, letterSpacing: '0.14em' }}>HIGHLIGHT · CH. 3</div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 64, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 4 }}>{post.photo.label}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 12, opacity: 0.85, marginTop: 6 }}>{post.photo.score}</div>
        </div>
        <div style={{ position: 'absolute', bottom: 10, left: '50%', transform: 'translateX(-50%)', display: 'flex', gap: 4 }}>
          {Array.from({ length: post.photoCount }).map((_, i) => (
            <button key={i} onClick={() => setIdx(i)} style={{ width: 6, height: 6, borderRadius: 999, background: i === idx ? 'white' : 'rgba(255,255,255,0.4)', border: 'none', padding: 0, cursor: 'pointer' }} />
          ))}
        </div>
        {post.photoCount > 1 && (
          <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 10, fontFamily: 'JetBrains Mono', background: 'rgba(0,0,0,0.4)', color: 'white', padding: '3px 7px', borderRadius: 999, letterSpacing: '0.05em' }}>{idx+1}/{post.photoCount}</span>
        )}
      </div>
      {post.linkedTeam && (
        <div style={{ padding: '10px 14px 0' }}>
          <LinkChip icon={<span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>TEAM ·</span>} label={post.linkedTeam} />
        </div>
      )}
      <EngagementBar post={post} onLike={() => onAction('like')} onSave={() => onAction('save')} onComment={() => onAction('comment')} onShare={() => onAction('share')} />
    </article>
  );
}

// =========================================================================
// RECRUITMENT — wanted-poster aesthetic
// =========================================================================
function RecruitmentCard({ post, onAction, onApply, applied }) {
  return (
    <article style={{ borderRadius: 14, border: '1px solid var(--hairline)', background: 'var(--paper)', overflow: 'hidden', position: 'relative' }}>
      {/* poster header strip */}
      <div style={{ background: 'oklch(0.94 0.06 148)', padding: '8px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid oklch(0.86 0.07 148)' }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'oklch(0.36 0.10 148)', letterSpacing: '0.16em' }}>★ WANTED</span>
        {post.spotsLeft != null && (
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'oklch(0.36 0.10 148)', letterSpacing: '0.06em' }}>{post.spotsLeft} SPOT{post.spotsLeft === 1 ? '' : 'S'} LEFT</span>
        )}
      </div>
      <ByLine author={post.author} postedBy={post.postedBy} time={post.time} kindLabel="TEAM" />
      <div style={{ padding: '4px 14px 12px' }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1 }}>{post.role}</div>
        <div style={{ fontSize: 13, lineHeight: 1.45, marginTop: 8, color: 'var(--ink-2)' }}>{post.body}</div>
        <div style={{ display: 'flex', gap: 6, marginTop: 12, flexWrap: 'wrap' }}>
          <LinkChip icon={<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 10c0 7-8 12-8 12s-8-5-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></svg>} label={post.location} />
          <LinkChip icon={<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>} label={post.deadline} />
        </div>
        <button onClick={onApply} style={{
          marginTop: 12, width: '100%', padding: '12px 14px', borderRadius: 10,
          border: 'none', background: applied ? 'oklch(0.56 0.13 148)' : 'var(--ink)', color: 'var(--paper)',
          fontWeight: 700, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer',
          letterSpacing: '0.02em',
        }}>{applied ? '✓ Applied — captain will message you' : 'Apply for trial →'}</button>
      </div>
      <EngagementBar post={post} onLike={() => onAction('like')} onSave={() => onAction('save')} onComment={() => onAction('comment')} onShare={() => onAction('share')} />
    </article>
  );
}

// =========================================================================
// TOURNAMENT UPDATE — fixture rail
// =========================================================================
function TournamentUpdateCard({ post, onAction, onLink }) {
  return (
    <article style={{ borderRadius: 14, border: '1px solid var(--hairline)', background: 'var(--paper)', overflow: 'hidden' }}>
      <ByLine author={post.author} postedBy={post.postedBy} time={post.time} kindLabel="TOURNAMENT" />
      <div style={{ padding: '4px 14px 10px' }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.015em' }}>{post.headline}</div>
        <div style={{ fontSize: 13, lineHeight: 1.4, marginTop: 4, color: 'var(--ink-2)' }}>{post.body}</div>
      </div>
      <div style={{ margin: '0 14px 12px', borderRadius: 10, overflow: 'hidden', border: '1px solid var(--hairline)' }}>
        {post.fixtures.map((f, i) => (
          <button key={i} onClick={() => onLink('match')} style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px',
            background: f.highlight ? 'oklch(0.96 0.04 28)' : 'var(--paper)',
            border: 'none', borderTop: i === 0 ? 'none' : '1px solid var(--hairline)',
            cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
          }}>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--muted)', minWidth: 20, letterSpacing: '0.04em' }}>QF{i+1}</span>
            <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, flex: 1, letterSpacing: '-0.01em' }}>{f.a} <span style={{ color: 'var(--muted)', fontWeight: 500 }}>vs</span> {f.b}</span>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)', fontWeight: 600 }}>{f.when}</span>
            {f.highlight && <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--red)', letterSpacing: '0.08em', fontWeight: 700 }}>YOU</span>}
          </button>
        ))}
      </div>
      <EngagementBar post={post} onLike={() => onAction('like')} onSave={() => onAction('save')} onComment={() => onAction('comment')} onShare={() => onAction('share')} />
    </article>
  );
}

// =========================================================================
// TEXT POST — compact
// =========================================================================
function TextPost({ post, onAction }) {
  return (
    <article style={{ borderRadius: 14, border: '1px solid var(--hairline)', background: 'var(--paper)', overflow: 'hidden' }}>
      <ByLine author={post.author} time={post.time} />
      <div style={{ padding: '0 14px 14px', fontSize: 15, lineHeight: 1.5, fontFamily: 'Inter Tight', letterSpacing: '-0.005em' }}>{post.text}</div>
      <EngagementBar post={post} onLike={() => onAction('like')} onSave={() => onAction('save')} onComment={() => onAction('comment')} onShare={() => onAction('share')} />
    </article>
  );
}

// =========================================================================
// FILTER CHIPS — sticky-ish
// =========================================================================
function FilterBar({ active, setActive }) {
  return (
    <div style={{ display: 'flex', gap: 6, padding: '10px 20px', overflowX: 'auto', borderBottom: '1px solid var(--hairline)', background: 'var(--paper)' }}>
      {FILTERS.map(f => (
        <button key={f.id} onClick={() => setActive(f.id)} style={{
          flex: 'none', padding: '6px 12px', borderRadius: 999,
          background: active === f.id ? 'var(--ink)' : 'transparent',
          color: active === f.id ? 'var(--paper)' : 'var(--ink-2)',
          border: '1px solid ' + (active === f.id ? 'var(--ink)' : 'var(--hairline)'),
          fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer',
          whiteSpace: 'nowrap',
        }}>{f.label}</button>
      ))}
    </div>
  );
}

// =========================================================================
// EMPTY STATE
// =========================================================================
function EmptyState({ filter, followed, toggleFollow }) {
  return (
    <div style={{ padding: '20px 0' }}>
      <div style={{ textAlign: 'center', padding: '20px 16px' }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em' }}>Nothing in "{filter}" yet</div>
        <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 4, lineHeight: 1.4 }}>Follow more accounts to fill this feed.</div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--ink)', letterSpacing: '0.14em' }}>SUGGESTED FOR YOU</div>
        <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 6 }}>
        {SUGGESTIONS.map((s, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: 12, borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)' }}>
            <div style={{ width: 38, height: 38, borderRadius: s.kind === 'user' ? 999 : 8, background: s.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 14, flex: 'none' }}>
              {s.name.split(' ').map(w => w[0]).slice(0, 2).join('')}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 600, fontSize: 14 }}>{s.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{s.meta}</div>
            </div>
            <button onClick={() => toggleFollow(i)} style={{
              fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.08em',
              padding: '6px 10px', borderRadius: 999, cursor: 'pointer',
              background: followed[i] ? 'oklch(0.56 0.13 148)' : 'transparent',
              color: followed[i] ? 'white' : 'var(--red)',
              border: '1px solid ' + (followed[i] ? 'oklch(0.56 0.13 148)' : 'oklch(0.85 0.08 28)'),
            }}>{followed[i] ? 'FOLLOWING' : 'FOLLOW'}</button>
          </div>
        ))}
      </div>
    </div>
  );
}

// =========================================================================
// COMMENT SHEET / COMPOSER / SHARE — kept as bottom sheets
// =========================================================================
function CommentSheet({ post, onClose }) {
  const [comments, setComments] = React.useState([
    { id: 1, name: 'Asad M.', text: 'Top knock 👏', time: '1h', likes: 3 },
    { id: 2, name: 'Tariq M.', text: 'How did you handle the short ball today?', time: '45m', likes: 1 },
  ]);
  const [text, setText] = React.useState('');
  const submit = () => {
    if (!text.trim()) return;
    setComments(c => [...c, { id: Date.now(), name: 'You', text: text.trim(), time: 'now', likes: 0 }]);
    setText('');
  };
  return (
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 50, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()} style={{ background: 'var(--paper)', borderRadius: '18px 18px 0 0', maxHeight: '75%', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <div style={{ padding: '12px 20px', borderBottom: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontWeight: 700, fontSize: 14 }}>Comments · {comments.length}</div>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted)', padding: 0 }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
          </button>
        </div>
        <div style={{ flex: 1, overflow: 'auto', padding: '8px 20px' }}>
          {comments.map(c => (
            <div key={c.id} style={{ display: 'flex', gap: 10, padding: '10px 0', borderBottom: '1px solid var(--hairline)' }}>
              <div style={{ width: 32, height: 32, borderRadius: 999, background: 'var(--paper-2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11, flex: 'none' }}>{c.name.split(' ').map(w => w[0]).slice(0, 2).join('')}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12 }}><strong>{c.name}</strong><span style={{ color: 'var(--muted)', marginLeft: 6, fontSize: 11 }}>{c.time}</span></div>
                <div style={{ fontSize: 13, marginTop: 2, lineHeight: 1.4 }}>{c.text}</div>
                <div style={{ display: 'flex', gap: 14, marginTop: 4, fontSize: 11, color: 'var(--muted)' }}>
                  <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'inherit', fontFamily: 'inherit', cursor: 'pointer' }}>Reply</button>
                  <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'inherit', fontFamily: 'inherit', cursor: 'pointer' }}>♡ {c.likes}</button>
                </div>
              </div>
            </div>
          ))}
        </div>
        <div style={{ padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', display: 'flex', gap: 8 }}>
          <input className="ck-input" placeholder="Add a comment…" value={text} onChange={e => setText(e.target.value)} onKeyDown={e => e.key === 'Enter' && submit()} style={{ flex: 1 }} />
          <button onClick={submit} disabled={!text.trim()} style={{ padding: '0 16px', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontWeight: 600, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer', opacity: text.trim() ? 1 : 0.4 }}>Post</button>
        </div>
      </div>
    </div>
  );
}

function Composer({ onClose }) {
  const [type, setType] = React.useState('Text');
  const [text, setText] = React.useState('');
  const types = ['Text', 'Photo', 'Match announcement', 'Recruitment'];
  return (
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 50, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()} style={{ background: 'var(--paper)', borderRadius: '18px 18px 0 0', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '14px 20px', borderBottom: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: 'var(--muted)', padding: 0, cursor: 'pointer', fontFamily: 'inherit', fontSize: 13 }}>Cancel</button>
          <div style={{ fontWeight: 700, fontSize: 14 }}>New post</div>
          <button disabled={!text.trim()} onClick={onClose} style={{ background: 'transparent', border: 'none', color: text.trim() ? 'var(--red)' : 'var(--muted)', padding: 0, cursor: 'pointer', fontFamily: 'inherit', fontSize: 13, fontWeight: 700 }}>Post</button>
        </div>
        <div style={{ display: 'flex', gap: 6, padding: '12px 20px 0', overflowX: 'auto' }}>
          {types.map(t => (
            <button key={t} onClick={() => setType(t)} style={{
              flex: 'none', padding: '6px 12px', borderRadius: 999,
              background: type === t ? 'var(--ink)' : 'transparent',
              color: type === t ? 'var(--paper)' : 'var(--ink-2)',
              border: '1px solid ' + (type === t ? 'var(--ink)' : 'var(--hairline)'),
              fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer',
            }}>{t}</button>
          ))}
        </div>
        <textarea autoFocus value={text} onChange={e => setText(e.target.value)} maxLength={2000}
          placeholder={type === 'Recruitment' ? 'Looking for a fast bowler…' : type === 'Match announcement' ? 'Friday 6 PM at Model Town…' : "What's happening on the pitch?"}
          style={{ margin: '14px 20px', minHeight: 140, border: 'none', outline: 'none', background: 'transparent', resize: 'none', fontFamily: 'inherit', fontSize: 15, lineHeight: 1.45 }} />
        <div style={{ padding: '8px 20px 18px', display: 'flex', alignItems: 'center', gap: 14, color: 'var(--muted)' }}>
          <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'inherit', cursor: 'pointer' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.5-3.5L8 21"/></svg>
          </button>
          <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'inherit', cursor: 'pointer', fontSize: 13, fontFamily: 'inherit' }}>@ Tag</button>
          <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'inherit', cursor: 'pointer', fontSize: 13, fontFamily: 'inherit' }}>🔗 Link match</button>
          <div style={{ flex: 1 }} />
          <span style={{ fontSize: 11, fontFamily: 'JetBrains Mono' }}>{text.length}/2000</span>
        </div>
      </div>
    </div>
  );
}

function ShareSheet({ onClose }) {
  const [copied, setCopied] = React.useState(false);
  return (
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 50, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()} style={{ background: 'var(--paper)', borderRadius: '18px 18px 0 0', padding: '14px 20px 22px' }}>
        <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 12 }}>Share</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 14 }}>
          {['WhatsApp', 'Copy link', 'More', 'DM'].map((s, i) => (
            <button key={i} onClick={() => { if (s === 'Copy link') { setCopied(true); setTimeout(() => setCopied(false), 1200); } }} style={{
              padding: 10, borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper-2)',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              cursor: 'pointer', fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14 }}>{s[0]}</div>
              <span>{s === 'Copy link' && copied ? 'Copied ✓' : s}</span>
            </button>
          ))}
        </div>
        <button onClick={onClose} style={{ width: '100%', padding: 12, borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Cancel</button>
      </div>
    </div>
  );
}

// =========================================================================
// MAIN
// =========================================================================
function Feed() {
  const [tab, setTab] = React.useState('home');
  const [filter, setFilter] = React.useState('all');
  const [posts, setPosts] = React.useState(POSTS);
  const [appliedRecruitment, setAppliedRecruitment] = React.useState({});
  const [followed, setFollowed] = React.useState({});
  const [commentFor, setCommentFor] = React.useState(null);
  const [composing, setComposing] = React.useState(false);
  const [sharing, setSharing] = React.useState(false);
  const [linkedToast, setLinkedToast] = React.useState('');

  const onAction = (postId, action) => {
    if (action === 'like') setPosts(ps => ps.map(p => p.id === postId ? { ...p, liked: !p.liked } : p));
    else if (action === 'save') setPosts(ps => ps.map(p => p.id === postId ? { ...p, saved: !p.saved } : p));
    else if (action === 'comment') setCommentFor(postId);
    else if (action === 'share') setSharing(true);
  };
  const onLink = (kind) => {
    setLinkedToast(kind === 'match' ? 'Opening match…' : kind === 'tournament' ? 'Opening tournament…' : 'Opening team…');
    setTimeout(() => setLinkedToast(''), 1400);
  };

  const visiblePosts = posts.filter(p => filter === 'all' || p.filter?.includes(filter));
  const commentPost = posts.find(p => p.id === commentFor);

  // group by bucket, preserving order
  const grouped = [];
  let lastBucket = null;
  visiblePosts.forEach(p => {
    if (p.bucket !== lastBucket) {
      grouped.push({ kind: 'divider', bucket: p.bucket });
      lastBucket = p.bucket;
    }
    grouped.push({ kind: 'post', post: p });
  });

  const renderPost = (post) => {
    if (post.kind === 'matchAnnouncement') return <MatchAnnouncementCard key={post.id} post={post} onAction={(a) => onAction(post.id, a)} onLink={onLink} />;
    if (post.kind === 'milestone') return <MilestoneCard key={post.id} post={post} onAction={(a) => onAction(post.id, a)} onLink={onLink} />;
    if (post.kind === 'photo') return <PhotoPost key={post.id} post={post} onAction={(a) => onAction(post.id, a)} />;
    if (post.kind === 'recruitment') return <RecruitmentCard key={post.id} post={post} onAction={(a) => onAction(post.id, a)} applied={appliedRecruitment[post.id]} onApply={() => setAppliedRecruitment(s => ({ ...s, [post.id]: !s[post.id] }))} />;
    if (post.kind === 'tournamentUpdate') return <TournamentUpdateCard key={post.id} post={post} onAction={(a) => onAction(post.id, a)} onLink={onLink} />;
    if (post.kind === 'text') return <TextPost key={post.id} post={post} onAction={(a) => onAction(post.id, a)} />;
    return null;
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      <style>{`
        @keyframes ckPing { 0% { transform: scale(1); opacity: 0.8; } 100% { transform: scale(2.6); opacity: 0; } }
      `}</style>

      <FeedHeader />

      {tab !== 'home' ? (
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 6, padding: 32, textAlign: 'center', color: 'var(--muted)' }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--ink)' }}>{FEED_TABS.find(t => t.id === tab).label}</div>
          <div style={{ fontSize: 13, lineHeight: 1.4, maxWidth: 240 }}>This tab opens its dedicated screen.</div>
        </div>
      ) : (
        <>
          <LiveNowRail
            matches={LIVE_NOW}
            onSeeAll={() => setTab('matches')}
            onOpen={() => { setLinkedToast('Opening live match…'); setTimeout(() => setLinkedToast(''), 1400); }}
          />
          <FilterBar active={filter} setActive={setFilter} />

          <div style={{ flex: 1, overflow: 'auto', padding: '6px 16px 16px' }}>
            {visiblePosts.length === 0 ? (
              <EmptyState filter={FILTERS.find(f => f.id === filter).label} followed={followed} toggleFollow={(i) => setFollowed(f => ({ ...f, [i]: !f[i] }))} />
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {grouped.map((g, i) =>
                  g.kind === 'divider'
                    ? <DayDivider key={'d-'+g.bucket+i} bucket={g.bucket} />
                    : renderPost(g.post)
                )}
                <div style={{ padding: '14px 0 8px', textAlign: 'center', fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.14em' }}>
                  END · NO ALGORITHM · REVERSE-CHRONO
                </div>
              </div>
            )}
          </div>
          <Fab onClick={() => setComposing(true)} />
        </>
      )}

      <TabBar active={tab} setActive={setTab} />

      {commentPost && <CommentSheet post={commentPost} onClose={() => setCommentFor(null)} />}
      {composing && <Composer onClose={() => setComposing(false)} />}
      {sharing && <ShareSheet onClose={() => setSharing(false)} />}
      {linkedToast && (
        <div style={{ position: 'absolute', bottom: 96, left: '50%', transform: 'translateX(-50%)', background: 'var(--ink)', color: 'var(--paper)', padding: '10px 16px', borderRadius: 999, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', zIndex: 30, boxShadow: '0 6px 16px rgba(0,0,0,0.2)' }}>{linkedToast}</div>
      )}
    </div>
  );
}

window.CkFeed = Feed;

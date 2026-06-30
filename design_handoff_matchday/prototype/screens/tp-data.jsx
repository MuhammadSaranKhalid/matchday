// tp-data.jsx — case fixtures for TeamPage

(function () {

const SQUAD_LIONS = [
  { id: 'p1', n: 'Bilal Ahmed',   role: 'Captain',       jersey: 7,  bat: 'RHB', bowl: 'RM',  status: 'app', last5: [42, 18, 0, 31, 67] },
  { id: 'p2', n: 'Adeel Sheikh',  role: 'Wicket-Keeper', jersey: 11, bat: 'LHB', bowl: '—',   status: 'app', last5: [12, 38, 22, 8, 41] },
  { id: 'p3', n: 'Faraz Khan',    role: 'Vice-Captain',  jersey: 33, bat: 'RHB', bowl: 'OS',  status: 'app', last5: [55, 27, 14, 9, 0] },
  { id: 'p4', n: 'Hamza Tariq',   role: 'Player',        jersey: 18, bat: 'RHB', bowl: '—',   status: 'app', last5: [3, 21, 0, 19, 4] },
  { id: 'p5', n: 'Usman Riaz',    role: 'Player',        jersey: 4,  bat: 'RHB', bowl: 'RFM', status: 'app', last5: [0, 0, 8, 12, 6] },
  { id: 'p6', n: 'Imran Akhtar',  role: 'Player',        jersey: 22, bat: 'RHB', bowl: 'RFM', status: 'app', last5: [44, 11, 27, 0, 18] },
  { id: 'p7', n: 'Tariq Hussain', role: 'Player',        jersey: 9,  bat: 'LHB', bowl: 'SLA', status: 'sms', last5: [] },
  { id: 'p8', n: 'Ahmed Khan',    role: 'Player',        jersey: 23, bat: 'RHB', bowl: '—',   status: 'unclaimed', last5: [12, 8] },
];

const LIONS = {
  name: 'Lahore Lions', mono: 'LL',
  type: 'Club', city: 'Lahore', area: 'Model Town',
  primary: 'oklch(0.36 0.10 148)',
  tagline: 'Roar with the Lions.',
  verified: true, privacy: 'Public',
  record: { p: 47, w: 31, l: 14 },
  squad: SQUAD_LIONS,
  form: ['W','W','L','W','T','W','L','W'],
  upcoming: [
    { date: 'Today · 14:00', round: 'Spring Cup QF', venue: 'Gaddafi B', vs: 'Multan Tigers' },
    { date: 'May 6 · 16:00', round: 'Friendly',      venue: 'Bagh-e-Jinnah', vs: 'Karachi Eagles' },
  ],
  recent: [
    { date: 'Apr 28', us: 'LL 174/6', them: 'IT 142',  won: true,  summary: 'Won by 32 runs' },
    { date: 'Apr 22', us: 'LL 88',    them: 'GG 92/4', won: false, summary: 'Lost by 6 wkts' },
    { date: 'Apr 15', us: 'LL 156/8', them: 'PR 156',  won: 'tie', summary: 'Tie · super over' },
  ],
  stats: {
    winPct: 66, trend: '+4 vs last season',
    top: [
      { kind: 'BAT',  label: 'MOST RUNS',    name: 'Bilal Ahmed', v: '482', detail: 'avg 40.2 · SR 138' },
      { kind: 'BOWL', label: 'MOST WICKETS', name: 'Usman Riaz',  v: '21',  detail: 'econ 6.4 · 1× 5w' },
      { kind: 'AR',   label: 'BEST IMPACT',  name: 'Faraz Khan',  v: '+58', detail: 'runs + wkts adj.' },
    ],
  },
  about: 'Founded in 2019, Lahore Lions play out of Model Town. We run a year-round practice schedule and field a senior + youth side. New player trials open in March each year.',
  details: [
    ['Type', 'Club'], ['Founded', '2019'], ['City', 'Lahore'],
    ['Home ground', 'Gaddafi B Ground'], ['Privacy', 'Public'], ['Members', '18 active'],
  ],
  managers: [
    { n: 'Bilal Ahmed',  role: 'Owner · Captain' },
    { n: 'Adeel Sheikh', role: 'Manager' },
  ],
  maxSize: 25,
};

const KHAAKI = {
  name: 'Khaaki XI', mono: 'KH',
  type: 'Club', city: 'Lahore', area: 'Cantt',
  primary: 'oklch(0.36 0.04 80)',
  tagline: 'Members only.',
  verified: true, privacy: 'Private',
  record: { p: 22, w: 14, l: 8 },
  squad: SQUAD_LIONS.map(p => ({ ...p })),
  form: ['W','L','W','W','L','W','W','W'],
  recent: [],
  details: [
    ['Type', 'Club'], ['Founded', '2017'], ['City', 'Lahore'],
    ['Home ground', 'Cantt Garrison'], ['Privacy', 'Private · members only'], ['Members', '14'],
  ],
  managers: [{ n: 'Major (R) Hashmi', role: 'Owner · Captain' }],
  maxSize: 20,
};

const RAWAL_OLD = {
  name: 'Rawalpindi Old Boys', mono: 'RO',
  type: 'Club', city: 'Rawalpindi', area: 'Sadar',
  primary: 'oklch(0.36 0.02 80)',
  tagline: 'Once we played here.',
  archived: 'May 2024',
  verified: true, privacy: 'Public',
  squad: SQUAD_LIONS.slice(0, 6).map(p => ({ ...p, status: 'app' })),
  recent: [
    { date: 'May 2024', us: 'RO 102', them: 'PR 156', won: false, summary: 'Final match · lost by 54 runs' },
    { date: 'Apr 2024', us: 'RO 144/7', them: 'OB 140', won: true, summary: 'Won by 3 wkts' },
  ],
  stats: { winPct: 58, trend: 'season closed', top: [{ kind: 'BAT', label: 'CLUB RECORD', name: 'Saeed Anwar Jr.', v: '94*', detail: 'vs Karachi Eagles · 2023' }] },
  details: [
    ['Type', 'Club'], ['Founded', '2009'], ['Disbanded', 'May 2024'],
    ['City', 'Rawalpindi'], ['Home ground', 'Sadar Ground'], ['Privacy', 'Public · archived'],
  ],
  managers: [],
  about: 'A friendly side that ran from 2009 to 2024. The club disbanded when most of the senior players moved cities. Record preserved for the alumni.',
};

const CASES = {
  // 01 — Owner, just created, empty
  'owner-new': {
    viewer: 'owner', viewerIs: 'p1',
    banner: { tone: 'green', title: 'Lahore Lions is live.', body: "You're the owner. Next: add your squad.", cta: 'Add players',
      icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg> },
    team: {
      ...LIONS,
      record: null, form: null, upcoming: null, recent: null, stats: null,
      squad: [{ id: 'p1', n: 'You · Bilal Ahmed', role: 'Captain', jersey: 1, bat: 'RHB', bowl: 'RM', status: 'app', last5: [] }],
      about: '',
      details: [['Type','Club'],['Founded','2026'],['City','Lahore'],['Home ground','Gaddafi B Ground'],['Privacy','Public'],['Members','1 (you)']],
      actionQueue: [],
      managers: [{ n: 'You · Bilal Ahmed', role: 'Owner · Captain' }],
    },
    tabs: ['Squad', 'Manage', 'About'],
    initial: 'Squad',
  },

  // 02 — Owner, active club with action queue
  'owner-active': {
    viewer: 'owner', viewerIs: 'p1',
    team: {
      ...LIONS,
      actionQueue: [
        { kind: 'JOIN',  tone: 'red',   when: '2h',  title: 'Usman Bhatti wants to join', body: 'All-rounder · Lahore · saw your post · 1 mutual', primary: 'Approve' },
        { kind: 'CLAIM', tone: 'amber', when: '5h',  title: 'Saif Khan claims "Ahmed Khan" placeholder', body: '+92 300 4521 ··· · 1 mutual team', primary: 'Approve' },
        { kind: 'XI',    tone: 'amber', when: '4d',  title: 'XI not picked for Spring Cup QF', body: 'Match in 18h · 14 players available · pick 11', primary: 'Pick XI' },
      ],
    },
    tabs: ['Squad', 'Matches', 'Stats', 'Manage', 'About'],
    badges: [{ label: '3 actions need you', tone: 'red' }],
    initial: 'Manage',
  },

  // 03 — Captain with tournament in motion
  captain: {
    viewer: 'captain', viewerIs: 'p1',
    team: {
      ...LIONS,
      tournament: { kind: 'Tournament · QF', name: 'Spring Cup 2026', stage: 'Quarter-final', played: 4, total: 4, next: 'today 18:30 vs Multan Tigers' },
      upcoming: [
        { date: 'Today · 18:30', round: 'Spring Cup QF', venue: 'Gaddafi B', vs: 'Multan Tigers' },
        { date: 'May 6 · 16:00', round: 'Friendly',      venue: 'Bagh-e-Jinnah', vs: 'Karachi Eagles' },
      ],
    },
    banner: { tone: 'amber', title: 'You captain Lahore Lions.', body: 'Match in 18h. Pick the XI and confirm the meeting time.', cta: 'Pick XI',
      icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M3 7h18M3 12h18M3 17h12"/></svg> },
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    initial: 'Matches',
  },

  // 04 — Player on team
  player: {
    viewer: 'player', viewerIs: 'p4',
    team: LIONS,
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    initial: 'Squad',
  },

  // 05 — Following
  following: {
    viewer: 'following',
    team: LIONS,
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    initial: 'Matches',
  },

  // 06 — Stranger, public
  stranger: {
    viewer: 'stranger',
    team: LIONS,
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    initial: 'Squad',
  },

  // 07 — Live now
  'live-now': {
    viewer: 'stranger',
    team: {
      ...LIONS,
      live: { ctx: 'SPRING CUP · QF', us: 'Lahore Lions', them: 'Karachi Cobras',
        usScore: '142/6 (20)', themScore: '119/9 (19.2)', note: 'Cobras need 24 from 6 balls' },
      upcoming: [{ date: 'Now', round: 'Spring Cup QF', venue: 'Gaddafi B', vs: 'Karachi Cobras', live: true }],
    },
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    badges: [{ label: 'Playing now', tone: 'red', pulse: true }],
    initial: 'Matches',
  },

  // 08 — Private team, stranger
  'private-stranger': {
    viewer: 'stranger-private',
    team: KHAAKI,
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    initial: 'Squad',
  },

  // 09 — Archived team
  archived: {
    viewer: 'stranger',
    team: RAWAL_OLD,
    tabs: ['Stats', 'Recent', 'About'],
    initial: 'About',
  },

  // 10 — Player, with a pending claim (UNCLAIMED-on-roster note)
  'player-claim': {
    viewer: 'player', viewerIs: 'p8',
    team: {
      ...LIONS,
      squad: SQUAD_LIONS.map(p => p.id === 'p8' ? { ...p, status: 'app', n: 'You · Ahmed Khan' } : p),
    },
    banner: { tone: 'green', title: 'You\u2019re in the Lions squad.', body: 'Your claim was approved 2 days ago. Jersey #23 is yours.', cta: 'View profile',
      icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg> },
    tabs: ['Squad', 'Matches', 'Stats', 'About'],
    initial: 'Squad',
  },
};

window.tpCases = CASES;

})();

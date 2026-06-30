// challenge-data.jsx — fixtures for the Send Challenge flow.

(function () {

// Format presets — tapping one fills every knob (matches the server catalogue).
// format jsonb: { oversPerInnings, playersPerTeam, ballType, maxOversPerBowler, ballsPerOver, inningsPerSide }
const PRESETS = [
  { id: 't20',     label: 'T20',         f: { oversPerInnings: 20, playersPerTeam: 11, ballType: 'leather', maxOversPerBowler: 4,  ballsPerOver: 6, inningsPerSide: 1 } },
  { id: 't10',     label: 'T10',         f: { oversPerInnings: 10, playersPerTeam: 11, ballType: 'leather', maxOversPerBowler: 2,  ballsPerOver: 6, inningsPerSide: 1 } },
  { id: 'odi',     label: 'ODI',         f: { oversPerInnings: 50, playersPerTeam: 11, ballType: 'leather', maxOversPerBowler: 10, ballsPerOver: 6, inningsPerSide: 1 } },
  { id: 'list_a',  label: 'List A',      f: { oversPerInnings: 50, playersPerTeam: 11, ballType: 'leather', maxOversPerBowler: 10, ballsPerOver: 6, inningsPerSide: 1 } },
  { id: 'hundred', label: 'The Hundred', f: { oversPerInnings: 20, playersPerTeam: 11, ballType: 'leather', maxOversPerBowler: 4,  ballsPerOver: 5, inningsPerSide: 1, endChangeBalls: 10 } },
  { id: 'super8',  label: '8-a-side',    f: { oversPerInnings: 20, playersPerTeam: 8,  ballType: 'leather', maxOversPerBowler: 4,  ballsPerOver: 6, inningsPerSide: 1 } },
  { id: 'tape',    label: 'Tape-ball',   f: { oversPerInnings: 20, playersPerTeam: 11, ballType: 'tape',    maxOversPerBowler: 4,  ballsPerOver: 6, inningsPerSide: 1 } },
  { id: 'box',     label: 'Box cricket', f: { oversPerInnings: 6,  playersPerTeam: 8,  ballType: 'tennis',  maxOversPerBowler: 2,  ballsPerOver: 6, inningsPerSide: 1, scoredPostMatch: true } },
];

const BALL_TYPES = [
  { id: 'leather', label: 'Hardball', sub: 'Leather · league' },
  { id: 'tape',    label: 'Tape',     sub: 'Softball · mohalla' },
  { id: 'tennis',  label: 'Tennis',   sub: 'Tapeball / indoor' },
];

const PLAYERS_OPTS = [5, 6, 7, 8, 9, 10, 11, 12, 15];

// Teams the current user manages (RLS: manager/owner only).
const MY_TEAMS = [
  { id: 't_ll', name: 'Lahore Lions',     mono: 'LL', color: 'oklch(0.62 0.19 28)',  city: 'Lahore',  area: 'Model Town', squad: 18 },
  { id: 't_it', name: 'Iqbal Town XI',    mono: 'IT', color: 'oklch(0.45 0.12 280)', city: 'Lahore',  area: 'Iqbal Town', squad: 9 },
  { id: 't_ms', name: 'Model Town Strikers', mono: 'MS', color: 'oklch(0.50 0.13 200)', city: 'Lahore', area: 'Model Town', squad: 13 },
];

// Nearby opponents — pre-ranked: city match → recency → alphabetic.
const OPPONENTS = [
  { id: 'o_ke', name: 'Karachi Eagles', mono: 'KE', color: 'oklch(0.55 0.15 250)', city: 'Lahore', meta: 'Played 3× · last May 2 · won 2', squad: 18 },
  { id: 'o_gg', name: 'Gulberg Greens', mono: 'GG', color: 'oklch(0.52 0.13 145)', city: 'Lahore', meta: 'Played 1× · last Mar 18',       squad: 16 },
  { id: 'o_ob', name: 'Old Boys XI',    mono: 'OB', color: 'oklch(0.36 0.04 80)',  city: 'Lahore', meta: 'Played 2× · last Aug 9',        squad: 22 },
  { id: 'o_mk', name: 'Mohalla Kings',  mono: 'MK', color: 'oklch(0.55 0.13 80)',  city: 'Lahore', meta: 'Never played · 4 km',           squad: 12 },
  { id: 'o_sc', name: 'Sherwani CC',    mono: 'SC', color: 'oklch(0.36 0.10 28)',  city: 'Lahore', meta: 'Never played · 7 km',           squad: 14 },
  { id: 'o_rs', name: 'Rawalpindi Stars', mono: 'RS', color: 'oklch(0.46 0.12 60)', city: 'Rawalpindi', meta: 'Never played · 280 km',     squad: 15 },
];

const VENUES = [
  { id: 'v1', name: 'Model Town Ground',  sub: '5 km · 2 pitches · last Mar 14' },
  { id: 'v2', name: 'DHA Pitch 3',        sub: '8 km · floodlit · last Aug 9' },
  { id: 'v3', name: 'Gulberg Pitch 2',    sub: '12 km · last Feb 6' },
];

const TIMES = ['08:00', '08:30', '09:00', '09:30', '10:00', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30'];

// Nearby free agents / guests, for the "borrow a player" gap-fill.
const NEARBY = [
  { id: 'g1', name: 'Wajid Ali',     role: 'AR',  sub: 'RHB · OS',  team: 'Model Town XI',   dist: '2 km' },
  { id: 'g2', name: 'Salman Yousuf', role: 'BAT', sub: 'LHB',       team: 'Race Course CC',   dist: '4 km' },
  { id: 'g3', name: 'Naveed Iqbal',  role: 'BOW', sub: 'RHB · RFM', team: 'Cantt Cricketers', dist: '5 km' },
  { id: 'g4', name: 'Tariq Bhatti',  role: 'BAT', sub: 'RHB',       team: 'Iqbal Park XI',    dist: '6 km' },
  { id: 'g5', name: 'Aamir Shah',    role: 'WK',  sub: 'LHB',       team: 'Defence Boys',     dist: '7 km' },
  { id: 'g6', name: 'Ibrahim Khan',  role: 'AR',  sub: 'LHB · SLA', team: 'Mughalpura CC',    dist: '8 km' },
  { id: 'g7', name: 'Rauf Cheema',   role: 'BOW', sub: 'RHB · RM',  team: 'Garrison XI',      dist: '9 km' },
];

// From-team active roster (Lahore Lions). role ∈ BAT|BOW|AR|WK.
const ROSTER = [
  { id: 'r1',  name: 'Bilal Ahmed',   role: 'AR',  sub: 'RHB · RM',  captain: true,  form: 'Hot' },
  { id: 'r2',  name: 'Adeel Sheikh',  role: 'WK',  sub: 'LHB',        form: 'OK' },
  { id: 'r3',  name: 'Faraz Khan',    role: 'AR',  sub: 'RHB · OS',  form: 'Hot' },
  { id: 'r4',  name: 'Hamza Tariq',   role: 'BAT', sub: 'RHB',        form: 'OK' },
  { id: 'r5',  name: 'Usman Riaz',    role: 'BOW', sub: 'RHB · RFM', form: 'Hot' },
  { id: 'r6',  name: 'Imran Akhtar',  role: 'BOW', sub: 'RHB · RFM', form: 'OK' },
  { id: 'r7',  name: 'Tariq Hussain', role: 'BOW', sub: 'LHB · SLA', form: 'Cold' },
  { id: 'r8',  name: 'Shahid Iqbal',  role: 'BAT', sub: 'RHB',        form: 'OK' },
  { id: 'r9',  name: 'Junaid Ali',    role: 'AR',  sub: 'RHB · LFM', form: 'Hot' },
  { id: 'r10', name: 'Saad Anwar',    role: 'BAT', sub: 'LHB',        form: 'OK' },
  { id: 'r11', name: 'Kashif Bhatti', role: 'WK',  sub: 'RHB',        form: 'OK' },
  { id: 'r12', name: 'Naveed Hassan', role: 'BAT', sub: 'RHB',        form: 'Cold' },
  { id: 'r13', name: 'Owais Memon',   role: 'BOW', sub: 'RHB · OS',  form: 'OK' },
  { id: 'r14', name: 'Asad Qureshi',  role: 'AR',  sub: 'LHB · RM',  form: 'Hot' },
  { id: 'r15', name: 'Rizwan Aslam',  role: 'BAT', sub: 'RHB',        form: 'OK' },
  { id: 'r16', name: 'Yasir Shabbir', role: 'BOW', sub: 'RHB · LFM', form: 'OK' },
  { id: 'r17', name: 'Salman Akhtar', role: 'BAT', sub: 'RHB',        form: 'Cold' },
  { id: 'r18', name: 'Bilal Pirzada', role: 'AR',  sub: 'RHB · RM',  form: 'OK' },
];

function ballLabel(id) { return (BALL_TYPES.find(b => b.id === id) || {}).label || id; }
function presetMatches(f) {
  for (const p of PRESETS) {
    if (!p.f) continue;
    const k = p.f;
    if (k.oversPerInnings === f.oversPerInnings && k.playersPerTeam === f.playersPerTeam &&
        k.ballType === f.ballType && k.maxOversPerBowler === f.maxOversPerBowler &&
        k.ballsPerOver === f.ballsPerOver && k.inningsPerSide === f.inningsPerSide) return p.id;
  }
  return 'custom';
}

window.ChData = { PRESETS, BALL_TYPES, PLAYERS_OPTS, MY_TEAMS, OPPONENTS, VENUES, TIMES, NEARBY, ROSTER, ballLabel, presetMatches };

})();

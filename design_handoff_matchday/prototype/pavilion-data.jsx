// pavilion-data.jsx — fixtures for the Pavilion workspace hub.

(function () {

const CRESTS = {
  LL: { short: 'LL', name: 'Lahore Lions',        color: 'oklch(0.62 0.19 28)' },
  IT: { short: 'IT', name: 'Iqbal Town XI',       color: 'oklch(0.45 0.12 280)' },
  MS: { short: 'MS', name: 'Model Town Strikers', color: 'oklch(0.50 0.13 200)' },
  KE: { short: 'KE', name: 'Karachi Eagles',      color: 'oklch(0.55 0.15 250)' },
  MT: { short: 'MT', name: 'Multan Tigers',       color: 'oklch(0.48 0.08 50)' },
  CC: { short: 'CC', name: 'Karachi Cobras',      color: 'oklch(0.44 0.10 200)' },
  MK: { short: 'MK', name: 'Mohalla Kings',       color: 'oklch(0.66 0.13 80)' },
  GG: { short: 'GG', name: 'Gulberg Greens',      color: 'oklch(0.52 0.13 145)' },
};

// phase: live | startsSoon | scheduled | awaitingReply | completed | hidden
function seedMatches() {
  return [
    { id: 'm_live',  phase: 'live',       opp: 'MT', when: 'Now · 14.3 ov', venue: 'Gaddafi B',  sub: 'Spring Cup QF', team: 'LL', role: 'captain', scoreA: '112/4', scoreB: '—' },
    { id: 'm_soon',  phase: 'startsSoon', opp: 'KE', when: 'Today · 4:00 PM', venue: 'Model Town', sub: 'Friendly · starts in 22m', team: 'LL', role: 'captain', lineupSet: false },
    { id: 'm_sched', phase: 'scheduled',  opp: 'CC', when: 'Sat 7 Jun · 3:00 PM', venue: 'Gulberg', sub: '9 of 11 RSVP’d', team: 'LL', role: 'captain', lineupSet: false },
    { id: 'm_sched2',phase: 'scheduled',  opp: 'GG', when: 'Sun 8 Jun · 7:00 AM', venue: 'Iqbal Park', sub: 'League R4', team: 'IT', role: 'owner', lineupSet: true },
    { id: 'm_await', phase: 'awaitingReply', opp: 'MK', when: 'Sat 14 Jun · 4:00 PM', venue: 'TBD', sub: 'Sent 1d ago · expires 23h', team: 'LL', role: 'captain' },
    { id: 'm_done',  phase: 'completed',  opp: 'MT', when: 'Sun 1 Jun', venue: 'Gaddafi B', sub: 'Won by 23 runs', team: 'LL', role: 'captain', result: 'W', scoreA: '142/6', scoreB: '119/9' },
    { id: 'm_done2', phase: 'completed',  opp: 'CC', when: 'Wed 28 May', venue: 'Gulberg', sub: 'Lost by 4 wkts', team: 'IT', role: 'owner', result: 'L', scoreA: '128/9', scoreB: '131/6' },
  ];
}

// role: captain | owner | player ; needs = actionable items count
function seedTeams() {
  return [
    { id: 't_ll', crest: 'LL', role: 'captain', squad: 18, record: 'W12 · L5', sub: 'Club · Model Town, Lahore', next: 'vs MT · today', pending: 2, needs: ['1 squad invite to approve', 'Lineup not set for Sat'] },
    { id: 't_it', crest: 'IT', role: 'owner',   squad: 9,  record: 'W3 · L4',  sub: 'Club · Iqbal Town', next: 'vs GG · Sun', pending: 0, needs: ['2 more players to field 11'] },
    { id: 't_ms', crest: 'MS', role: 'player',  squad: 13, record: 'W7 · L6',  sub: 'Club · Model Town', next: 'No upcoming', pending: 0, needs: [] },
  ];
}

// kind: organizing | playing ; stage progress
function seedTournaments() {
  return [
    { id: 'tr_sc', name: "Spring Cup '26", short: 'SC', color: 'oklch(0.36 0.10 28)', kind: 'organizing', format: 'Knockout · 8 teams', stage: 'Quarter-finals', sub: '3 fixtures to schedule', needs: 3, progress: 0.5, state: 'live', sample: 'knockout' },
    { id: 'tr_dr', name: 'Gully Champions', short: 'GC', color: 'oklch(0.45 0.13 300)', kind: 'organizing', format: 'Knockout · 8 teams', stage: 'Draft', sub: 'No teams yet · share code', needs: 1, progress: 0, state: 'draft', sample: 'knockout' },
    { id: 'tr_rg', name: 'Eid Night Cup',  short: 'EN', color: 'oklch(0.55 0.16 40)',  kind: 'organizing', format: 'Knockout · 8 teams', stage: 'Registration', sub: '5 of 8 in · 2 requests', needs: 2, progress: 0.15, state: 'registration', sample: 'knockout' },
    { id: 'tr_rd', name: 'Mohalla Shield', short: 'MS', color: 'oklch(0.50 0.12 200)', kind: 'organizing', format: 'Knockout · 8 teams', stage: 'Ready to draw', sub: '8 in · all paid · draw the bracket', needs: 1, progress: 0.3, state: 'ready', sample: 'knockout' },
    { id: 'tr_rc', name: 'Ramadan Cup',    short: 'RC', color: 'oklch(0.46 0.10 150)', kind: 'organizing', format: 'Round-robin · 6 teams', stage: 'Group stage', sub: 'Round 2 of 5', needs: 0, progress: 0.4, state: 'live', sample: 'league' },
    { id: 'tr_dn', name: 'Winter Smash',   short: 'WS', color: 'oklch(0.42 0.07 285)', kind: 'organizing', format: 'Knockout · 8 teams', stage: 'Completed', sub: 'Lyari Lions — champions', needs: 0, progress: 1, state: 'completed', sample: 'knockout' },
    { id: 'tr_cl', name: 'City League',    short: 'CL', color: 'oklch(0.50 0.12 250)', kind: 'playing', format: 'League · 10 teams', stage: 'Matchday 4', sub: 'Lions 2nd · 9 pts', needs: 0, progress: 0.4, state: 'live', sample: 'league' },
  ];
}

// Account area — everything pushed OUT of the Pavilion lives here.
const ACCOUNT = [
  { group: 'YOU', items: [
    { id: 'profile', icon: 'users', t: 'Profile', s: 'Bilal Ahmed · @bilal_ar' },
    { id: 'stats', icon: 'star', t: 'Stats', s: 'Career · form · wagon wheel' },
    { id: 'achievements', icon: 'trophy', t: 'Achievements', s: '14 unlocked' },
  ]},
  { group: 'ACTIVITY', items: [
    { id: 'wallet', icon: 'ticket', t: 'Wallet', s: 'Entry fees · payouts' },
    { id: 'saved', icon: 'flag', t: 'Saved', s: 'Posts & matches you kept' },
    { id: 'followed', icon: 'bell', t: 'Following', s: 'Players · teams · tournaments' },
    { id: 'scorer', icon: 'pencil', t: 'Scorer history', s: '38 matches scored' },
  ]},
  { group: 'SETTINGS', items: [
    { id: 'notif', icon: 'bell', t: 'Notifications', s: 'Pushes & alerts' },
    { id: 'disc', icon: 'search', t: 'Discoverability', s: 'Who can find & challenge you' },
    { id: 'privacy', icon: 'info', t: 'Privacy & blocking', s: 'Visibility · blocked accounts' },
  ]},
];

window.PavData = { CRESTS, seedMatches, seedTeams, seedTournaments, ACCOUNT };

})();

// pavilion-parts.jsx — Overview lane + Matches/Teams/Tournaments lanes + Account.

(function () {

const C = window.Ch;
const D = window.PavData;
const { ink, ink2, muted, soft, paper, paper2, hair, line, red, redSoft, green, greenSoft, amber, cream, amberInk, greenInk, display, mono, Icon, Crest, Avatar } = C;
const { CRESTS } = D;

const TONE = {
  red: { bg: redSoft, fg: 'oklch(0.42 0.16 28)', dot: red },
  amber: { bg: cream, fg: amberInk, dot: amber },
  green: { bg: greenSoft, fg: greenInk, dot: green },
  neutral: { bg: paper2, fg: muted, dot: soft },
};
function Pill({ tone = 'neutral', live, children }) {
  const t = TONE[tone];
  return <span style={{ ...mono, fontSize: 9, padding: '3px 7px', borderRadius: 5, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', gap: 5 }}>
    <span style={{ width: 5, height: 5, borderRadius: 999, background: t.dot, animation: live ? 'ck-pulse 1.4s ease-in-out infinite' : 'none' }} />{children}
  </span>;
}
function SecLabel({ children, action, onAction }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '0 18px', marginBottom: 9 }}>
      <span style={{ ...mono, fontSize: 10, color: muted }}>{children}</span>
      {action && <button onClick={onAction} style={{ ...mono, fontSize: 9, color: ink2, background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}>{action}</button>}
    </div>
  );
}

// ── phase → header pill + single primary action ──
const PHASE = {
  live:          { pill: { t: 'LIVE', tone: 'red', live: true }, primary: { a: 'resume', l: 'Resume scoring', icon: 'whistle' } },
  startsSoon:    { pill: { t: 'STARTS SOON', tone: 'amber' }, primary: { a: 'start', l: 'Start match', icon: 'play' }, secondary: { a: 'lineup', l: 'Lineup' } },
  scheduled:     { pill: { t: 'SCHEDULED', tone: 'neutral' }, secondary: { a: 'view', l: 'View' } },
  awaitingReply: { pill: { t: 'AWAITING REPLY', tone: 'amber' }, secondary: { a: 'withdraw', l: 'Withdraw' } },
  completed:     { pill: { t: 'FINAL', tone: 'neutral' }, secondary: { a: 'scorecard', l: 'Scorecard' } },
};

function MatchCard({ m, onAction }) {
  const them = CRESTS[m.opp] || CRESTS.KE;
  const meTeam = CRESTS[m.team] || CRESTS.LL;
  const cfg = PHASE[m.phase]; if (!cfg) return null;
  const showScore = m.phase === 'live' || m.phase === 'completed';
  return (
    <div style={{ margin: '0 16px 10px', borderRadius: 16, border: '1px solid ' + hair, background: paper, overflow: 'hidden' }}>
      <div style={{ padding: '13px 14px 12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
          <Pill tone={cfg.pill.tone} live={cfg.pill.live}>{cfg.pill.t}</Pill>
          {m.lineupSet === false && (m.phase === 'scheduled' || m.phase === 'startsSoon') && <span style={{ ...mono, fontSize: 9, color: amberInk }}>LINEUP NOT SET</span>}
          <span style={{ ...mono, fontSize: 9, color: muted, marginLeft: 'auto' }}>{m.when}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Crest size={40} bg={them.color} label={them.short} radius={11} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15, letterSpacing: '-0.02em', whiteSpace: 'nowrap' }}>{meTeam.short} vs {them.short}</span>
              {m.result && <span style={{ ...mono, fontSize: 9, padding: '1px 5px', borderRadius: 4, background: m.result === 'W' ? greenSoft : paper2, color: m.result === 'W' ? greenInk : muted }}>{m.result === 'W' ? 'WON' : 'LOST'}</span>}
            </div>
            <div style={{ fontSize: 11.5, color: muted, marginTop: 2 }}>{m.sub} · {m.venue}</div>
          </div>
          {showScore && (
            <div style={{ textAlign: 'right', flexShrink: 0 }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, fontSize: 14, color: ink }}>{m.scoreA}</div>
              {m.scoreB && m.scoreB !== '—' && <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: muted, marginTop: 1 }}>{m.scoreB}</div>}
            </div>
          )}
        </div>
      </div>
      {(cfg.primary || cfg.secondary) && (
        <div style={{ display: 'flex', gap: 8, padding: '10px 14px', borderTop: '1px solid ' + hair, background: paper2 }}>
          {cfg.secondary && <button onClick={() => onAction(m.id, cfg.secondary.a)} style={{ flex: cfg.primary ? '0 0 auto' : 1, padding: '10px 16px', borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit', border: '1px solid ' + hair, background: paper, color: ink, fontWeight: 600, fontSize: 13 }}>{cfg.secondary.l}</button>}
          {cfg.primary && <button onClick={() => onAction(m.id, cfg.primary.a)} style={{ flex: 1, padding: '10px 16px', borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit', border: 'none', background: m.phase === 'live' ? red : ink, color: paper, fontWeight: 700, fontSize: 13, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 7 }}><Icon name={cfg.primary.icon} size={15} stroke={paper} sw={2} />{cfg.primary.l}</button>}
        </div>
      )}
    </div>
  );
}

// ── Overview lane: the one always-on "what needs me today" strip ──
function Overview({ matches, teams, tournaments, onAction, onSegment }) {
  const live = matches.find(m => m.phase === 'live');
  const soon = matches.find(m => m.phase === 'startsSoon');
  const hero = live || soon;
  // aggregate actionables
  const lineupGaps = matches.filter(m => m.lineupSet === false).length;
  const awaiting = matches.filter(m => m.phase === 'awaitingReply').length;
  const invites = teams.reduce((s, t) => s + (t.pending || 0), 0);
  const tourGaps = tournaments.reduce((s, t) => s + (t.needs || 0), 0);
  const chips = [];
  if (lineupGaps) chips.push({ icon: 'users', t: `${lineupGaps} lineup${lineupGaps > 1 ? 's' : ''} not set`, seg: 'matches', tone: 'amber' });
  if (awaiting) chips.push({ icon: 'swords', t: `${awaiting} challenge${awaiting > 1 ? 's' : ''} awaiting`, seg: 'matches', tone: 'amber' });
  if (invites) chips.push({ icon: 'users', t: `${invites} squad invite${invites > 1 ? 's' : ''}`, seg: 'teams', tone: 'amber' });
  if (tourGaps) chips.push({ icon: 'trophy', t: `${tourGaps} fixtures to schedule`, seg: 'tournaments', tone: 'amber' });

  const them = hero ? (CRESTS[hero.opp] || CRESTS.KE) : null;
  return (
    <div style={{ padding: '4px 0 6px' }}>
      <SecLabel>TODAY</SecLabel>
      {hero ? (
        <div style={{ margin: '0 16px 10px', borderRadius: 18, background: ink, color: paper, padding: '15px 16px', position: 'relative', overflow: 'hidden' }}>
          <svg width="200" height="200" viewBox="0 0 200 200" style={{ position: 'absolute', right: -80, top: -70, opacity: 0.08 }}><ellipse cx="100" cy="100" rx="90" ry="56" stroke="#fff" strokeWidth="1" fill="none"/><ellipse cx="100" cy="100" rx="50" ry="30" stroke="#fff" strokeWidth="1" fill="none"/></svg>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, position: 'relative' }}>
            <span style={{ width: 6, height: 6, borderRadius: 999, background: red, animation: live ? 'ck-pulse 1.4s ease-in-out infinite' : 'none' }} />
            <span style={{ ...mono, fontSize: 9, color: '#fff', opacity: 0.85 }}>{live ? 'LIVE NOW' : 'STARTS SOON'}</span>
            <span style={{ ...mono, fontSize: 9, color: '#fff', opacity: 0.5, marginLeft: 'auto' }}>{hero.when}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative' }}>
            <Crest size={42} bg={them.color} label={them.short} radius={11} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 17, letterSpacing: '-0.02em', color: '#fff' }}>{(CRESTS[hero.team] || CRESTS.LL).short} vs {them.short}</div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)', marginTop: 3 }}>{hero.sub} · {hero.venue}</div>
            </div>
            {hero.scoreA && <div style={{ textAlign: 'right' }}><div style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, fontSize: 16, color: '#fff' }}>{hero.scoreA}</div></div>}
          </div>
          <button onClick={() => onAction(hero.id, live ? 'resume' : 'start')} style={{ marginTop: 14, width: '100%', padding: '11px 0', borderRadius: 12, border: 'none', background: live ? red : paper, color: live ? paper : ink, fontFamily: 'inherit', fontWeight: 700, fontSize: 13.5, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 7, position: 'relative' }}>
            <Icon name={live ? 'whistle' : 'play'} size={16} stroke={live ? paper : ink} sw={2} />{live ? 'Resume scoring' : 'Start match'}
          </button>
        </div>
      ) : (
        <div style={{ margin: '0 16px 10px', padding: '16px', borderRadius: 16, border: '1px dashed ' + line, background: paper2, fontSize: 12.5, color: ink2, lineHeight: 1.5 }}>
          Nothing live today. Schedule a friendly or check your fixtures below.
        </div>
      )}
      {chips.length > 0 && (
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', padding: '2px 16px 4px' }}>
          {chips.map((c, i) => (
            <button key={i} onClick={() => onSegment(c.seg)} style={{ flexShrink: 0, display: 'inline-flex', alignItems: 'center', gap: 7, padding: '8px 12px', borderRadius: 11, border: '1px solid ' + hair, background: paper, cursor: 'pointer', fontFamily: 'inherit' }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: amber }} />
              <span style={{ fontSize: 12, fontWeight: 600, color: ink, whiteSpace: 'nowrap' }}>{c.t}</span>
              <Icon name="next" size={13} stroke={muted} sw={2} />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Matches lane ──
function MatchesLane({ matches, onAction, hideIds = [] }) {
  const hidden = new Set(hideIds);
  const up = matches.filter(m => ['live', 'startsSoon', 'scheduled', 'awaitingReply'].includes(m.phase) && !hidden.has(m.id));
  const past = matches.filter(m => m.phase === 'completed');
  return (
    <div style={{ paddingTop: 4 }}>
      <SecLabel>{up.length ? `UPCOMING · ${up.length}` : 'UPCOMING'}</SecLabel>
      {up.length === 0 && <div style={{ margin: '0 16px 10px', padding: '14px 16px', borderRadius: 14, background: paper2, fontSize: 12.5, color: ink2 }}>Everything upcoming is up top. Schedule another with ＋.</div>}
      {up.map(m => <MatchCard key={m.id} m={m} onAction={onAction} />)}
      {past.length > 0 && <><div style={{ height: 6 }} /><SecLabel>PLAYED · {past.length}</SecLabel>{past.map(m => <MatchCard key={m.id} m={m} onAction={onAction} />)}</>}
      <div style={{ height: 16 }} />
    </div>
  );
}

// ── Teams lane ──
function TeamsLane({ teams, onOpen, onAction, onCreate }) {
  const ROLE = { captain: { t: 'CAPTAIN', tone: 'amber' }, owner: { t: 'OWNER', tone: 'green' }, player: { t: 'PLAYER', tone: 'neutral' } };
  if (!teams.length) {
    return window.PavV2.EmptyState({ icon: 'users', title: 'No teams yet',
      body: 'Create a side — club, village or one-off — then invite players or add unclaimed names. You can captain or just play.',
      cta: 'Create a team', onCta: onCreate,
      hint: 'Invited to a squad? It’ll show up here to accept.' });
  }
  return (
    <div style={{ paddingTop: 4 }}>
      <SecLabel>YOUR TEAMS · {teams.length}</SecLabel>
      {teams.map(t => {
        const c = CRESTS[t.crest]; const r = ROLE[t.role];
        return (
          <div key={t.id} style={{ margin: '0 16px 10px', borderRadius: 16, border: '1px solid ' + hair, background: paper, overflow: 'hidden' }}>
            <button onClick={() => onOpen(t)} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '13px 14px', background: 'transparent', border: 'none', cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit' }}>
              <Crest size={44} bg={c.color} label={c.short} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15.5, letterSpacing: '-0.02em', whiteSpace: 'nowrap' }}>{c.name}</span>
                  <Pill tone={r.tone}>{r.t}</Pill>
                </div>
                <div style={{ fontSize: 11.5, color: muted, marginTop: 2 }}>{t.squad} squad · {t.record} · {t.next}</div>
              </div>
              <Icon name="next" size={16} stroke={muted} sw={2} />
            </button>
            {t.needs.length > 0 && (
              <div style={{ borderTop: '1px solid ' + hair, background: paper2, padding: '9px 14px', display: 'flex', flexDirection: 'column', gap: 6 }}>
                {t.needs.map((n, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ width: 5, height: 5, borderRadius: 999, background: amber, flexShrink: 0 }} />
                    <span style={{ fontSize: 12, color: ink2, flex: 1 }}>{n}</span>
                    <button onClick={() => onAction(t.id, 'resolve', n)} style={{ ...mono, fontSize: 9, color: ink, background: paper, border: '1px solid ' + hair, borderRadius: 7, padding: '4px 8px', cursor: 'pointer' }}>FIX</button>
                  </div>
                ))}
              </div>
            )}
          </div>
        );
      })}
      <div style={{ height: 16 }} />
    </div>
  );
}

// ── Tournaments lane ──
function ToursLane({ tournaments, onOpen, onAction, onCreate }) {
  const org = tournaments.filter(t => t.kind === 'organizing');
  const play = tournaments.filter(t => t.kind === 'playing');
  if (!tournaments.length) {
    return window.PavV2.EmptyState({ icon: 'trophy', title: 'No tournaments yet',
      body: 'Run a cup or league — knockout, round-robin or points table. Or register your team to play in one.',
      cta: 'Create a tournament', onCta: onCreate,
      secondary: 'Find tournaments to join', onSecondary: () => onAction && onAction(null, 'browse') });
  }
  const Card = (t) => (
    <div key={t.id} style={{ margin: '0 16px 10px', borderRadius: 16, border: '1px solid ' + hair, background: paper, overflow: 'hidden' }}>
      <button onClick={() => onOpen(t)} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '13px 14px', background: 'transparent', border: 'none', cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit' }}>
        <div style={{ width: 44, height: 44, borderRadius: 12, background: t.color, color: paper, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name="trophy" size={20} stroke={paper} sw={1.8} /></div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15.5, letterSpacing: '-0.02em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.name}</div>
          <div style={{ fontSize: 11.5, color: muted, marginTop: 2 }}>{t.format} · {t.stage}</div>
          <div style={{ height: 4, borderRadius: 2, background: paper2, marginTop: 8, overflow: 'hidden' }}><div style={{ width: (t.progress * 100) + '%', height: '100%', background: t.color }} /></div>
        </div>
        <Icon name="next" size={16} stroke={muted} sw={2} />
      </button>
      {t.needs > 0 && (
        <div style={{ borderTop: '1px solid ' + hair, background: paper2, padding: '9px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ width: 5, height: 5, borderRadius: 999, background: amber }} />
          <span style={{ fontSize: 12, color: ink2, flex: 1 }}>{t.sub}</span>
          <button onClick={() => onAction(t.id, 'schedule')} style={{ ...mono, fontSize: 9, color: paper, background: ink, border: 'none', borderRadius: 7, padding: '5px 9px', cursor: 'pointer' }}>SCHEDULE</button>
        </div>
      )}
    </div>
  );
  return (
    <div style={{ paddingTop: 4 }}>
      <SecLabel>ORGANIZING · {org.length}</SecLabel>
      {org.map(Card)}
      {play.length > 0 && <><div style={{ height: 6 }} /><SecLabel>PLAYING · {play.length}</SecLabel>{play.map(Card)}</>}
      <div style={{ height: 16 }} />
    </div>
  );
}

// ── Account sheet (everything pushed out of the Pavilion) ──
function Account({ onClose, onToast, bare }) {
  return (
    <div style={bare
      ? { position: 'absolute', inset: 0, background: paper, display: 'flex', flexDirection: 'column' }
      : { position: 'absolute', inset: 0, zIndex: 70, background: paper, display: 'flex', flexDirection: 'column', animation: 'pv-slide 0.24s cubic-bezier(0.32,0.72,0,1)' }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      <div style={{ padding: '6px 12px 12px', flexShrink: 0, display: 'flex', alignItems: 'center', gap: 8, borderBottom: '1px solid ' + hair }}>
        <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 6, display: 'flex', alignItems: 'center', gap: 4, color: ink, fontFamily: 'inherit', fontSize: 14, fontWeight: 600 }}><Icon name="back" size={18} stroke={ink} sw={2} /> Pavilion</button>
        <span style={{ ...mono, fontSize: 9, color: muted, marginLeft: 'auto' }}>ACCOUNT</span>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ padding: '18px 18px 14px', display: 'flex', alignItems: 'center', gap: 14 }}>
          <Avatar name="Bilal Ahmed" size={56} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ ...display(20) }}>Bilal Ahmed</div>
            <div style={{ fontSize: 12.5, color: muted, marginTop: 2 }}>@bilal_ar · All-rounder · Lahore</div>
          </div>
        </div>
        {D.ACCOUNT.map(grp => (
          <div key={grp.group} style={{ marginTop: 8 }}>
            <div style={{ ...mono, fontSize: 10, color: muted, padding: '4px 18px 8px' }}>{grp.group}</div>
            {grp.items.map((it, i) => (
              <button key={it.id} onClick={() => onToast(it.t)} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 13, padding: '12px 18px', background: paper, border: 'none', borderTop: '1px solid ' + hair, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit' }}>
                <div style={{ width: 34, height: 34, borderRadius: 10, background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name={it.icon} size={16} stroke={ink2} sw={1.8} /></div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{it.t}</div>
                  <div style={{ fontSize: 11.5, color: muted, marginTop: 1 }}>{it.s}</div>
                </div>
                <Icon name="next" size={15} stroke={muted} sw={2} />
              </button>
            ))}
          </div>
        ))}
        <div style={{ padding: '20px 18px 28px' }}>
          <button onClick={() => onToast('Signed out')} style={{ width: '100%', padding: '13px 0', borderRadius: 12, border: '1px solid ' + hair, background: paper, color: red, fontFamily: 'inherit', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Sign out</button>
          <div style={{ ...mono, fontSize: 9, color: muted, textAlign: 'center', marginTop: 16 }}>MATCHDAY · v2.0</div>
        </div>
      </div>
    </div>
  );
}

window.PavParts = { Overview, MatchesLane, TeamsLane, ToursLane, Account, MatchCard };

})();

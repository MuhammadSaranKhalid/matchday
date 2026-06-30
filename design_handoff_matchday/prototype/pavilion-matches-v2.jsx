// pavilion-matches-v2.jsx — v2 Matches: status-only cards + match detail page.
// Cards carry NO action buttons — they're clean, visibly-tappable rows that
// open a full match detail page where every action lives. The Today hero
// (in PavParts.Overview) still carries the one urgent action.

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
function SecLabel({ children }) {
  return <div style={{ ...mono, fontSize: 10, color: muted, padding: '0 18px', marginBottom: 9 }}>{children}</div>;
}

const PHASE = {
  live:          { label: 'LIVE', tone: 'red', live: true },
  startsSoon:    { label: 'STARTS SOON', tone: 'amber' },
  scheduled:     { label: 'SCHEDULED', tone: 'neutral' },
  awaitingReply: { label: 'AWAITING REPLY', tone: 'amber' },
  completed:     { label: 'FINAL', tone: 'neutral' },
};

// ── phase-adaptive card (Option C) ──────────────────────
//   • upcoming (startsSoon / scheduled / awaitingReply) → compact dual-crest row
//   • live / completed                                  → two-row scoreboard
function ScoreRow({ c, score, dim, win, top }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '8px 14px', borderTop: top ? 'none' : '1px solid ' + hair, background: win ? greenSoft : 'transparent' }}>
      <Crest size={28} bg={c.color} label={c.short} radius={8} />
      <span style={{ flex: 1, minWidth: 0, fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13.5, letterSpacing: '-0.01em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: ink }}>{c.name}</span>
      {win && <Icon name="check" size={15} stroke={greenInk} sw={2.6} style={{ flexShrink: 0 }} />}
      <span style={{ fontFamily: 'JetBrains Mono', fontWeight: dim ? 600 : 700, fontSize: dim ? 12 : 15, color: dim ? muted : ink, fontVariantNumeric: 'tabular-nums' }}>{score}</span>
    </div>
  );
}

function MatchCard({ m, onOpen }) {
  const them = CRESTS[m.opp] || CRESTS.KE;
  const meTeam = CRESTS[m.team] || CRESTS.LL;
  const cfg = PHASE[m.phase]; if (!cfg) return null;
  const scored = m.phase === 'live' || m.phase === 'completed';
  const [press, setPress] = React.useState(false);
  const aWin = m.phase === 'completed' && m.result === 'W';
  const bWin = m.phase === 'completed' && m.result && m.result !== 'W';

  return (
    <button
      onClick={() => onOpen(m)}
      onPointerDown={() => setPress(true)}
      onPointerUp={() => setPress(false)}
      onPointerLeave={() => setPress(false)}
      style={{
        width: 'calc(100% - 32px)', margin: '0 16px 10px', textAlign: 'left', fontFamily: 'inherit',
        borderRadius: 16, border: '1px solid ' + hair, background: press ? paper2 : paper,
        cursor: 'pointer', padding: 0, transition: 'background .12s', display: 'block', overflow: 'hidden',
      }}>
      {/* status strip */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '11px 12px 0' }}>
        <Pill tone={cfg.tone} live={cfg.live}>{cfg.label}</Pill>
        {m.lineupSet === false && (m.phase === 'scheduled' || m.phase === 'startsSoon') && <span style={{ ...mono, fontSize: 9, color: amberInk }}>LINEUP NOT SET</span>}
        <span style={{ ...mono, fontSize: 9, color: muted, marginLeft: 'auto' }}>{m.when}</span>
      </div>

      {scored ? (
        /* ── two-row scoreboard ── */
        <>
          <div style={{ height: 8 }} />
          <ScoreRow c={meTeam} score={m.scoreA || '—'} dim={!m.scoreA || m.scoreA === '—'} win={aWin} top />
          <ScoreRow c={them} score={m.scoreB || '—'} dim={!m.scoreB || m.scoreB === '—'} win={bWin} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '9px 12px', borderTop: '1px solid ' + hair }}>
            <span style={{ flex: 1, minWidth: 0, fontSize: 11.5, color: muted, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.sub} · {m.venue}</span>
            <Icon name="next" size={15} stroke={soft} sw={2} style={{ flexShrink: 0 }} />
          </div>
        </>
      ) : (
        /* ── compact dual-crest row ── */
        <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '12px 12px 13px' }}>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Crest size={38} bg={meTeam.color} label={meTeam.short} radius={10} />
            <div style={{ marginLeft: -9, border: '2px solid ' + paper, borderRadius: 12 }}>
              <Crest size={38} bg={them.color} label={them.short} radius={10} />
            </div>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15, letterSpacing: '-0.02em', whiteSpace: 'nowrap' }}>{meTeam.short} vs {them.short}</div>
            <div style={{ fontSize: 11.5, color: muted, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.sub} · {m.venue}</div>
          </div>
          <Icon name="next" size={16} stroke={soft} sw={2} style={{ flexShrink: 0 }} />
        </div>
      )}
    </button>
  );
}

function MatchesLane({ matches, onOpen, onCreate, hideIds = [] }) {
  const hidden = new Set(hideIds);
  const up = matches.filter(m => ['live', 'startsSoon', 'scheduled', 'awaitingReply'].includes(m.phase) && !hidden.has(m.id));
  const past = matches.filter(m => m.phase === 'completed');
  if (matches.length === 0) {
    return <EmptyState icon="swords" title="No matches yet"
      body="Challenge another team to set up your first match — you pick the day, ground and format."
      cta="Schedule a match" onCta={onCreate}
      hint="Got a 6-digit code? Tap ＋ to claim an open challenge." />;
  }
  return (
    <div style={{ paddingTop: 4 }}>
      <SecLabel>{up.length ? `UPCOMING · ${up.length}` : 'UPCOMING'}</SecLabel>
      {up.length === 0 && <div style={{ margin: '0 16px 10px', padding: '14px 16px', borderRadius: 14, background: paper2, fontSize: 12.5, color: ink2 }}>Everything upcoming is up top. Schedule another with ＋.</div>}
      {up.map(m => <MatchCard key={m.id} m={m} onOpen={onOpen} />)}
      {past.length > 0 && <><div style={{ height: 6 }} /><SecLabel>PLAYED · {past.length}</SecLabel>{past.map(m => <MatchCard key={m.id} m={m} onOpen={onOpen} />)}</>}
      <div style={{ height: 16 }} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// MATCH DETAIL PAGE — every action lives here
// ─────────────────────────────────────────────────────────
function KvCard({ rows }) {
  return (
    <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 14, overflow: 'hidden' }}>
      {rows.map(([k, v], i) => (
        <div key={k} style={{ display: 'flex', padding: '11px 14px', borderTop: i ? '1px solid ' + hair : 'none', gap: 12, alignItems: 'center' }}>
          <div style={{ ...mono, fontSize: 9.5, color: muted, width: 78 }}>{k.toUpperCase()}</div>
          <div style={{ flex: 1, fontSize: 13, color: ink, fontWeight: 500, textAlign: 'right' }}>{v}</div>
        </div>
      ))}
    </div>
  );
}
function SectionH({ children, side }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '20px 2px 9px' }}>
      <span style={{ ...mono, fontSize: 10, color: muted }}>{children}</span>
      {side && <span style={{ fontSize: 11, color: muted }}>{side}</span>}
    </div>
  );
}

function MatchDetail({ m, onBack, onAction }) {
  const them = CRESTS[m.opp] || CRESTS.KE;
  const meTeam = CRESTS[m.team] || CRESTS.LL;
  const cfg = PHASE[m.phase];
  const live = m.phase === 'live';
  const done = m.phase === 'completed';
  const captain = m.role === 'captain' || m.role === 'owner';

  // headline under the crests
  let headline, subline;
  if (live) { headline = m.scoreA || 'In play'; subline = m.when + ' · ' + m.venue; }
  else if (done) { headline = m.sub; subline = m.when + ' · ' + m.venue; }
  else { headline = m.when; subline = m.venue; }

  // sticky footer actions per phase
  const footer = [];
  if (live) footer.push({ a: 'resume', l: 'Resume scoring', primary: true, icon: 'whistle', danger: true });
  else if (m.phase === 'startsSoon') {
    if (m.lineupSet === false) footer.push({ a: 'lineup', l: 'Set lineup', icon: 'users' });
    footer.push({ a: 'start', l: 'Start match', primary: true, icon: 'play' });
  } else if (m.phase === 'scheduled') {
    footer.push({ a: 'reschedule', l: 'Reschedule', icon: 'cal' });
    footer.push({ a: m.lineupSet === false ? 'lineup' : 'viewlineup', l: m.lineupSet === false ? 'Set lineup' : 'View lineup', primary: true, icon: 'users' });
  } else if (m.phase === 'awaitingReply') {
    footer.push({ a: 'withdraw', l: 'Withdraw challenge', primary: true, icon: 'close', danger: true });
  } else if (done) {
    footer.push({ a: 'share', l: 'Share', icon: 'share' });
    footer.push({ a: 'scorecard', l: 'View scorecard', primary: true, icon: 'ticket' });
  }

  // secondary "manage" rows in the body
  const manage = [];
  if (!done && m.phase !== 'awaitingReply') {
    manage.push({ a: 'message', l: 'Message opponent', icon: 'msg' });
    if (m.phase !== 'live') manage.push({ a: 'reschedule', l: 'Propose a new time', icon: 'cal' });
    if (m.phase !== 'live' && captain) manage.push({ a: 'cancel', l: 'Cancel match', icon: 'close', danger: true });
  }

  const rsvpYes = m.phase === 'startsSoon' ? 11 : 9;

  return (
    <div className="ck-screen" style={{ height: '100%', display: 'flex', flexDirection: 'column', background: paper }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      <div style={{ padding: '6px 12px', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid ' + hair }}>
        <button onClick={onBack} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 6, display: 'flex', alignItems: 'center', gap: 4, color: ink, fontFamily: 'inherit', fontSize: 14, fontWeight: 600 }}>
          <Icon name="back" size={18} stroke={ink} sw={2} /> Pavilion
        </button>
        <span style={{ ...mono, fontSize: 9, color: muted }}>MATCH</span>
        <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 6, color: ink2 }}><Icon name="dots" size={18} stroke={ink2} sw={2} /></button>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', minHeight: 0, padding: '4px 18px 24px' }}>
        {/* hero */}
        <div style={{ margin: '10px 0 0', padding: '18px 14px', borderRadius: 18, background: live ? ink : paper2, color: live ? paper : ink, position: 'relative', overflow: 'hidden' }}>
          {live && <svg width="200" height="200" viewBox="0 0 200 200" style={{ position: 'absolute', right: -80, top: -70, opacity: 0.08 }}><ellipse cx="100" cy="100" rx="90" ry="56" stroke="#fff" strokeWidth="1" fill="none"/><ellipse cx="100" cy="100" rx="50" ry="30" stroke="#fff" strokeWidth="1" fill="none"/></svg>}
          <div style={{ display: 'flex', justifyContent: 'center', position: 'relative' }}>
            <Pill tone={cfg.tone} live={cfg.live}>{cfg.label}</Pill>
          </div>
          <div style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 14, justifyContent: 'center', position: 'relative' }}>
            <div style={{ textAlign: 'center', flex: 1, minWidth: 0 }}>
              <Crest size={52} bg={meTeam.color} label={meTeam.short} radius={14} />
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13.5, marginTop: 8, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: live ? paper : ink }}>{meTeam.name}</div>
              <div style={{ fontSize: 10.5, color: live ? 'rgba(255,255,255,0.6)' : muted, marginTop: 2 }}>you · {m.role}</div>
            </div>
            <Icon name="swords" size={20} stroke={live ? 'rgba(255,255,255,0.5)' : muted} sw={2} />
            <div style={{ textAlign: 'center', flex: 1, minWidth: 0 }}>
              <Crest size={52} bg={them.color} label={them.short} radius={14} />
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13.5, marginTop: 8, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: live ? paper : ink }}>{them.name}</div>
              <div style={{ fontSize: 10.5, color: live ? 'rgba(255,255,255,0.6)' : muted, marginTop: 2 }}>opponent</div>
            </div>
          </div>
          <div style={{ marginTop: 16, paddingTop: 14, borderTop: '1px solid ' + (live ? 'rgba(255,255,255,0.14)' : hair), textAlign: 'center', position: 'relative' }}>
            <div style={{ fontFamily: live || done ? 'JetBrains Mono' : 'Inter Tight', fontWeight: 700, fontSize: live ? 26 : 18, letterSpacing: '-0.01em', color: live ? paper : ink }}>{headline}</div>
            <div style={{ fontSize: 12, color: live ? 'rgba(255,255,255,0.7)' : muted, marginTop: 3 }}>{subline}</div>
          </div>
        </div>

        {/* completed score line */}
        {done && (
          <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
            {[[meTeam.short, m.scoreA, m.result === 'W'], [them.short, m.scoreB, m.result !== 'W']].map(([s, sc, win], i) => (
              <div key={i} style={{ flex: 1, padding: '12px 14px', borderRadius: 12, border: '1px solid ' + hair, background: win ? greenSoft : paper }}>
                <div style={{ ...mono, fontSize: 9, color: muted }}>{s}{win ? ' · WON' : ''}</div>
                <div style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, fontSize: 18, color: ink, marginTop: 4 }}>{sc}</div>
              </div>
            ))}
          </div>
        )}

        {/* match spec */}
        <SectionH>Match spec</SectionH>
        <KvCard rows={[
          ['Format', 'T20 · 11-a-side'],
          ['Overs', '20 · 6-ball'],
          ['Ball', 'Tape'],
          ['Venue', m.venue],
          ['When', m.when],
        ]} />

        {/* squad & lineup */}
        {!done && m.phase !== 'awaitingReply' && (
          <>
            <SectionH side={m.lineupSet === false ? 'not set' : 'XI locked'}>Squad & lineup</SectionH>
            <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 14, padding: '13px 14px', display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ display: 'flex' }}>
                {[meTeam.color, '#8a8f98', '#b0784a', '#5a7d52'].map((c, i) => (
                  <div key={i} style={{ width: 28, height: 28, borderRadius: 999, background: c, border: '2px solid ' + paper, marginLeft: i ? -10 : 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: paper, fontSize: 9, fontWeight: 700, fontFamily: 'Inter Tight' }}>{['BA','AS','FK','HT'][i]}</div>
                ))}
                <div style={{ width: 28, height: 28, borderRadius: 999, background: paper2, border: '2px solid ' + paper, marginLeft: -10, display: 'flex', alignItems: 'center', justifyContent: 'center', color: ink2, fontSize: 9, fontWeight: 700, fontFamily: 'JetBrains Mono' }}>+{rsvpYes - 4}</div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{rsvpYes} of 11 confirmed</div>
                <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{m.lineupSet === false ? 'Lineup not set yet' : 'Your XI is locked'}</div>
              </div>
            </div>
          </>
        )}

        {/* head to head */}
        {m.phase !== 'awaitingReply' && (
          <>
            <SectionH>Head to head</SectionH>
            <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 14, padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center' }}>
              <div style={{ ...display(22), color: ink }}>3<span style={{ fontSize: 13, color: muted }}> – </span>2</div>
              <div style={{ flex: 1, minWidth: 0, fontSize: 11.5, color: muted, lineHeight: 1.5 }}>5 meetings · last: <b style={{ color: ink2 }}>{meTeam.short} won by 12</b></div>
            </div>
          </>
        )}

        {/* manage rows */}
        {manage.length > 0 && (
          <>
            <SectionH>Manage</SectionH>
            <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 14, overflow: 'hidden' }}>
              {manage.map((r, i) => (
                <button key={r.a} onClick={() => onAction(m.id, r.a)} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: paper, border: 'none', borderTop: i ? '1px solid ' + hair : 'none', cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit' }}>
                  <Icon name={r.icon} size={16} stroke={r.danger ? red : ink2} sw={1.8} />
                  <span style={{ flex: 1, fontSize: 13.5, fontWeight: 500, color: r.danger ? red : ink }}>{r.l}</span>
                  <Icon name="next" size={14} stroke={soft} sw={2} />
                </button>
              ))}
            </div>
          </>
        )}
        <div style={{ height: 8 }} />
      </div>

      {/* sticky action footer */}
      {footer.length > 0 && (
        <div style={{ flexShrink: 0, padding: '12px 18px', paddingBottom: 'calc(16px + env(safe-area-inset-bottom))', background: paper, borderTop: '1px solid ' + hair, display: 'flex', gap: 8 }}>
          {footer.map(f => (
            <button key={f.a} onClick={() => onAction(m.id, f.a)} style={{
              flex: f.primary ? 1.4 : 1, padding: '13px 0', borderRadius: 12, cursor: 'pointer', fontFamily: 'inherit',
              border: f.primary ? 'none' : '1px solid ' + hair,
              background: f.primary ? (f.danger ? red : ink) : paper,
              color: f.primary ? paper : (f.danger ? red : ink),
              fontWeight: f.primary ? 700 : 600, fontSize: 13.5,
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 7,
            }}>
              {f.icon && <Icon name={f.icon} size={15} stroke={f.primary ? paper : (f.danger ? red : ink)} sw={2} />}{f.l}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

window.PavV2 = { MatchCard, MatchesLane, MatchDetail, EmptyState };

// ── reusable empty state ──────────────────────────────
function EmptyState({ icon, title, body, cta, onCta, hint, secondary, onSecondary }) {
  return (
    <div style={{ padding: '40px 30px 28px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <div style={{ width: 68, height: 68, borderRadius: 18, background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 18, position: 'relative' }}>
        <Icon name={icon} size={28} stroke={ink2} sw={1.7} />
        <span style={{ position: 'absolute', right: -5, bottom: -5, width: 24, height: 24, borderRadius: 999, background: paper, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="plus" size={13} stroke={ink} sw={2.4} />
        </span>
      </div>
      <div style={{ ...display(20) }}>{title}</div>
      <div style={{ fontSize: 13, color: ink2, marginTop: 8, lineHeight: 1.55, maxWidth: 280 }}>{body}</div>
      {cta && (
        <button onClick={onCta} style={{ marginTop: 20, padding: '13px 22px', borderRadius: 12, border: 'none', background: ink, color: paper, fontFamily: 'inherit', fontWeight: 700, fontSize: 14, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 8 }}>
          <Icon name="plus" size={17} stroke={paper} sw={2.4} />{cta}
        </button>
      )}
      {secondary && (
        <button onClick={onSecondary} style={{ marginTop: 10, padding: '11px 18px', borderRadius: 11, border: '1px solid ' + hair, background: paper, color: ink, fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>{secondary}</button>
      )}
      {hint && <div style={{ ...mono, fontSize: 9.5, color: muted, marginTop: 18, letterSpacing: '0.06em', lineHeight: 1.6, maxWidth: 260 }}>{hint}</div>}
    </div>
  );
}

})();

// Tournament.jsx — Tournament detail (Standings / Fixtures / Bracket)

const TEAMS = {
  LL: { mono: 'LL', name: 'Lahore Lions',     bg: 'oklch(0.36 0.10 148)' },
  MT: { mono: 'MT', name: 'Model Town XI',    bg: 'oklch(0.42 0.16 28)'  },
  KS: { mono: 'KS', name: 'Karachi Stars',    bg: 'oklch(0.32 0.14 250)' },
  IT: { mono: 'IT', name: 'Islamabad Tigers', bg: 'oklch(0.30 0.06 70)'  },
  GG: { mono: 'GG', name: 'Gujranwala Giants',bg: 'oklch(0.45 0.13 50)'  },
  PR: { mono: 'PR', name: 'Pindi Royals',     bg: 'oklch(0.40 0.14 320)' },
  FX: { mono: 'FX', name: 'Faisalabad XI',    bg: 'oklch(0.50 0.13 180)' },
  ML: { mono: 'ML', name: 'Multan Mavericks', bg: 'oklch(0.40 0.15 20)'  },
};

function CkTBadge({ id, size = 28 }) {
  const t = TEAMS[id] || { mono: '??', bg: 'var(--soft)' };
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.28,
      background: t.bg, color: 'white', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700,
      fontSize: size * 0.4, letterSpacing: '-0.02em',
    }}>{t.mono}</div>
  );
}

function CkTournament() {
  const [tab, setTab] = React.useState('Standings');

  const Tab = ({ id }) => (
    <button onClick={() => setTab(id)} style={{
      background: 'transparent', border: 'none',
      padding: '12px 0', cursor: 'pointer',
      fontFamily: 'Inter', fontWeight: 600, fontSize: 14,
      color: tab === id ? 'var(--ink)' : 'var(--muted)',
      borderBottom: tab === id ? '2px solid var(--ink)' : '2px solid transparent',
      flex: 1,
    }}>{id}</button>
  );

  return (
    <div className="ck-screen" style={{ display: 'block', height: '100%', overflow: 'auto' }}>
      <div style={{ height: 44 }} />

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 18px 8px' }}>
        <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="oklch(0.18 0.02 80)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <span className="ck-chip">SPRING CUP · 2026</span>
        <button onClick={() => window.__ckNav && window.__ckNav.push('manage')} style={{ background: 'var(--paper-2)', border: '1px solid var(--hairline)', padding: '5px 10px', borderRadius: 999, cursor: 'pointer', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', color: 'var(--ink-2)' }}>
          MANAGE
        </button>
      </div>

      {/* Hero */}
      <div style={{ padding: '8px 18px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>
          <span>LAHORE</span><span>·</span><span>T20</span><span>·</span><span>LEATHER</span>
        </div>
        <h1 className="ck-display" style={{ fontSize: 32, fontWeight: 700, margin: 0, letterSpacing: '-0.03em', lineHeight: 1 }}>
          Spring Cup
          <span style={{ color: 'var(--muted)', fontWeight: 500 }}> ’26</span>
        </h1>
        <div style={{ marginTop: 10, display: 'flex', gap: 16, fontSize: 12, color: 'var(--muted)' }}>
          <span><span style={{ color: 'var(--ink)', fontWeight: 600 }}>8</span> teams</span>
          <span><span style={{ color: 'var(--ink)', fontWeight: 600 }}>14/16</span> matches</span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--red)' }}/>
            <span style={{ color: 'var(--red)', fontWeight: 600 }}>QF live</span>
          </span>
        </div>

        {/* Live match strip */}
        <div style={{
          marginTop: 14, padding: '12px 14px',
          background: 'var(--ink)', color: 'var(--paper)', borderRadius: 14,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <span className="ck-chip live" style={{ flexShrink: 0 }}>LIVE</span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
              <CkTBadge id="LL" size={18} />
              <span>177/8</span>
              <span style={{ opacity: 0.5, margin: '0 4px' }}>vs</span>
              <CkTBadge id="MT" size={18} />
              <span style={{ color: 'oklch(0.85 0.13 80)' }}>132/4</span>
            </div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>
              QF1 · MT need 46 from 33 · 14.3 ov
            </div>
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" style={{ flexShrink: 0 }}>
            <path d="M9 6l6 6-6 6" stroke="white" strokeWidth="2" fill="none" strokeLinecap="round"/>
          </svg>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', padding: '0 16px', background: 'var(--paper)', position: 'sticky', top: 44, zIndex: 5 }}>
        <Tab id="Standings" /><Tab id="Fixtures" /><Tab id="Bracket" /><Tab id="Stats" />
      </div>

      {tab === 'Standings' && <StandingsTab />}
      {tab === 'Fixtures' && <FixturesTab />}
      {tab === 'Bracket' && <BracketTab />}
      {tab === 'Stats' && <StatsTab />}

      <div style={{ height: 40 }} />
    </div>
  );
}

function StandingsTab() {
  const rows = [
    { id: 'LL', p: 4, w: 4, l: 0, t: 0, pts: 8, nrr: '+1.84', form: 'WWWW' },
    { id: 'KS', p: 4, w: 3, l: 1, t: 0, pts: 6, nrr: '+0.72', form: 'WLWW' },
    { id: 'MT', p: 4, w: 2, l: 1, t: 1, pts: 5, nrr: '+0.18', form: 'WTLW' },
    { id: 'IT', p: 4, w: 2, l: 2, t: 0, pts: 4, nrr: '-0.05', form: 'LWWL' },
    { id: 'GG', p: 4, w: 2, l: 2, t: 0, pts: 4, nrr: '-0.31', form: 'WLWL' },
    { id: 'PR', p: 4, w: 1, l: 3, t: 0, pts: 2, nrr: '-0.62', form: 'LLWL' },
    { id: 'FX', p: 4, w: 1, l: 3, t: 0, pts: 2, nrr: '-0.94', form: 'LWLL' },
    { id: 'ML', p: 4, w: 0, l: 4, t: 0, pts: 0, nrr: '-1.41', form: 'LLLL' },
  ];

  return (
    <div style={{ padding: '16px 16px 0' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <div className="ck-section-h">League stage · top 4 → QF</div>
        <span style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>by PTS · NRR</span>
      </div>

      {/* Header row */}
      <div style={{
        display: 'grid', gridTemplateColumns: '14px 24px 1fr 22px 22px 22px 28px 38px',
        gap: 6, padding: '6px 10px', fontSize: 9, fontFamily: 'JetBrains Mono',
        color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em',
      }}>
        <span>#</span><span></span><span>Team</span>
        <span style={{ textAlign: 'center' }}>P</span>
        <span style={{ textAlign: 'center' }}>W</span>
        <span style={{ textAlign: 'center' }}>L</span>
        <span style={{ textAlign: 'right' }}>PTS</span>
        <span style={{ textAlign: 'right' }}>NRR</span>
      </div>

      <div style={{ background: 'var(--surface)', borderRadius: 14, border: '1px solid var(--hairline)', overflow: 'hidden' }}>
        {rows.map((r, i) => {
          const qual = i < 4;
          return (
            <React.Fragment key={r.id}>
              <div style={{
                display: 'grid', gridTemplateColumns: '14px 24px 1fr 22px 22px 22px 28px 38px',
                gap: 6, padding: '10px 10px', alignItems: 'center',
                background: qual ? 'transparent' : 'var(--paper-2)',
                position: 'relative',
              }}>
                {qual && <div style={{
                  position: 'absolute', left: 0, top: 0, bottom: 0, width: 3,
                  background: 'var(--green)',
                }}/>}
                <span className="ck-tnum" style={{ fontSize: 12, fontWeight: 600, color: qual ? 'var(--ink)' : 'var(--muted)' }}>{i+1}</span>
                <CkTBadge id={r.id} size={22} />
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {TEAMS[r.id].name}
                  </div>
                  <div style={{ display: 'flex', gap: 2, marginTop: 3 }}>
                    {r.form.split('').map((c, j) => (
                      <span key={j} style={{
                        width: 12, height: 12, borderRadius: 3,
                        background: c === 'W' ? 'var(--green)' : c === 'T' ? 'var(--amber)' : 'var(--red)',
                        color: 'white', fontSize: 8, fontWeight: 700,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontFamily: 'Inter Tight',
                      }}>{c}</span>
                    ))}
                  </div>
                </div>
                <span className="ck-tnum" style={{ fontSize: 13, textAlign: 'center', color: 'var(--ink-2)' }}>{r.p}</span>
                <span className="ck-tnum" style={{ fontSize: 13, textAlign: 'center', fontWeight: 600 }}>{r.w}</span>
                <span className="ck-tnum" style={{ fontSize: 13, textAlign: 'center', color: 'var(--muted)' }}>{r.l}</span>
                <span className="ck-display ck-tnum" style={{ fontSize: 16, fontWeight: 700, textAlign: 'right' }}>{r.pts}</span>
                <span className="ck-tnum" style={{ fontSize: 11, textAlign: 'right', fontFamily: 'JetBrains Mono',
                  color: r.nrr.startsWith('+') ? 'var(--green)' : 'var(--red)' }}>{r.nrr}</span>
              </div>
              {i === 3 && (
                <div style={{
                  padding: '6px 12px', fontSize: 9, fontFamily: 'JetBrains Mono',
                  color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em',
                  background: 'var(--paper-2)', borderTop: '1px dashed var(--line)', borderBottom: '1px dashed var(--line)',
                }}>
                  ─── Qualification cutoff ───
                </div>
              )}
            </React.Fragment>
          );
        })}
      </div>

      <div style={{ marginTop: 10, fontSize: 11, color: 'var(--muted)', lineHeight: 1.5, padding: '0 4px' }}>
        Tie-break: <span style={{ color: 'var(--ink-2)', fontWeight: 600 }}>NRR → H2H → Wins</span>.
        Top 4 advance to knockout.
      </div>
    </div>
  );
}

function FixturesTab() {
  const fixtures = [
    { day: 'Today · Apr 30', items: [
      { time: '14:00', a: 'LL', b: 'MT', score: '177/8 · 132/4', round: 'QF1', status: 'live', loc: 'Gaddafi B' },
      { time: '19:30', a: 'KS', b: 'IT', round: 'QF2', status: 'upcoming', loc: 'Bagh-e-Jinnah' },
    ]},
    { day: 'Tomorrow · May 1', items: [
      { time: '14:00', a: 'GG', b: 'PR', round: 'QF3', status: 'upcoming', loc: 'Model Town' },
      { time: '19:30', a: 'FX', b: 'ML', round: 'QF4', status: 'upcoming', loc: 'Cantt Ground' },
    ]},
    { day: 'Apr 28', items: [
      { time: '15:00', a: 'LL', b: 'GG', score: '184/5 · 142 (19.2)', winner: 'LL', round: 'L8', status: 'done', loc: 'Gaddafi B', margin: 'won by 42 runs' },
      { time: '19:30', a: 'KS', b: 'ML', score: '155 (20) · 121 (18.4)', winner: 'KS', round: 'L8', status: 'done', loc: 'Bagh-e-Jinnah', margin: 'won by 34 runs' },
    ]},
  ];

  return (
    <div style={{ padding: '12px 16px 0' }}>
      {fixtures.map((g, gi) => (
        <div key={gi} style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <span className="ck-section-h">{g.day}</span>
            <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {g.items.map((m, i) => (
              <div key={i} style={{
                background: m.status === 'live' ? 'var(--ink)' : 'var(--surface)',
                color: m.status === 'live' ? 'var(--paper)' : 'var(--ink)',
                borderRadius: 14,
                border: m.status === 'live' ? '1px solid transparent' : '1px solid var(--hairline)',
                padding: '12px 14px',
              }}>
                <div style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  marginBottom: 8, fontSize: 10, fontFamily: 'JetBrains Mono',
                  color: m.status === 'live' ? 'rgba(255,255,255,0.6)' : 'var(--muted)',
                }}>
                  <span>{m.round} · {m.loc}</span>
                  {m.status === 'live'
                    ? <span style={{ color: 'oklch(0.85 0.13 80)', fontWeight: 700, letterSpacing: '0.08em' }}>● LIVE {m.time}</span>
                    : m.status === 'done'
                      ? <span>FT</span>
                      : <span>{m.time}</span>}
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  {[m.a, m.b].map((tid, ti) => {
                    const isWinner = m.winner === tid;
                    const score = m.score?.split(' · ')[ti];
                    return (
                      <div key={ti} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <CkTBadge id={tid} size={26} />
                        <div style={{ flex: 1, fontSize: 14, fontWeight: isWinner ? 700 : 500,
                          opacity: m.status === 'done' && !isWinner ? 0.6 : 1 }}>
                          {TEAMS[tid].name}
                        </div>
                        {score && (
                          <div className="ck-display ck-tnum" style={{
                            fontSize: 15, fontWeight: 700,
                            color: m.status === 'live' && ti === 1 ? 'oklch(0.85 0.13 80)' : 'inherit',
                          }}>{score}</div>
                        )}
                      </div>
                    );
                  })}
                </div>
                {m.margin && (
                  <div style={{ marginTop: 8, fontSize: 11, color: 'var(--muted)', fontStyle: 'italic' }}>
                    {TEAMS[m.winner].name} {m.margin}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function BracketTab() {
  // 8-team knockout bracket — vertical for mobile
  const QF = [
    { a: 'LL', b: 'MT', score: '177 · 132/4', live: true },
    { a: 'KS', b: 'IT', score: null },
    { a: 'GG', b: 'PR', score: null },
    { a: 'FX', b: 'ML', score: null },
  ];

  const Match = ({ a, b, score, live, ghost, label }) => (
    <div style={{
      background: live ? 'var(--ink)' : 'var(--surface)',
      color: live ? 'var(--paper)' : 'var(--ink)',
      border: live ? '1px solid transparent' : '1px solid var(--hairline)',
      borderRadius: 10, padding: '8px 10px',
      opacity: ghost ? 0.45 : 1,
      position: 'relative',
    }}>
      {label && (
        <div style={{
          position: 'absolute', top: -8, left: 8,
          fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700,
          letterSpacing: '0.1em', textTransform: 'uppercase',
          background: 'var(--paper)', color: 'var(--muted)',
          padding: '0 4px',
        }}>{label}</div>
      )}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {[a, b].map((tid, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            {tid ? <CkTBadge id={tid} size={18} /> : <div style={{ width: 18, height: 18, borderRadius: 5, background: 'var(--paper-2)', border: '1px dashed var(--line)' }}/>}
            <span style={{ fontSize: 11, fontWeight: 600, flex: 1, minWidth: 0,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {tid ? TEAMS[tid].name : 'TBD'}
            </span>
            {score && (
              <span className="ck-tnum" style={{ fontSize: 10, fontFamily: 'JetBrains Mono',
                color: live && i === 1 ? 'oklch(0.85 0.13 80)' : 'inherit', opacity: live ? 1 : 0.7 }}>
                {score.split(' · ')[i]}
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <div style={{ padding: '16px 16px 0' }}>
      <div className="ck-section-h" style={{ marginBottom: 12 }}>Knockout · Apr 30 → May 4</div>
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
      }}>
        {/* Column headers */}
        <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 600, letterSpacing: '0.1em', color: 'var(--muted)', textTransform: 'uppercase' }}>QF</div>
        <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 600, letterSpacing: '0.1em', color: 'var(--muted)', textTransform: 'uppercase' }}>SF</div>
        <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 600, letterSpacing: '0.1em', color: 'var(--muted)', textTransform: 'uppercase' }}>Final</div>

        {/* QF column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, position: 'relative' }}>
          {QF.map((m, i) => <Match key={i} {...m} />)}
        </div>

        {/* SF column */}
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-around', gap: 24, position: 'relative' }}>
          <Match a={null} b={null} ghost />
          <Match a={null} b={null} ghost />
          {/* connector lines */}
          <svg style={{ position: 'absolute', top: 0, left: -8, width: 8, height: '100%', pointerEvents: 'none' }} preserveAspectRatio="none">
            <line x1="0" y1="20%" x2="8" y2="20%" stroke="var(--line)" strokeWidth="1" />
            <line x1="0" y1="70%" x2="8" y2="70%" stroke="var(--line)" strokeWidth="1" />
          </svg>
        </div>

        {/* Final column */}
        <div style={{ display: 'flex', alignItems: 'center', position: 'relative' }}>
          <div style={{ width: '100%' }}>
            <Match a={null} b={null} ghost label="Final" />
            <div style={{
              marginTop: 12, padding: '10px 8px', borderRadius: 10,
              background: 'var(--cream)', textAlign: 'center',
            }}>
              <svg width="20" height="20" viewBox="0 0 24 24" style={{ marginBottom: 4 }}>
                <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 16.8l-6.2 4.5 2.4-7.4L2 9.4h7.6L12 2z" fill="oklch(0.78 0.14 80)"/>
              </svg>
              <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-2)' }}>
                Champion
              </div>
              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--muted)', marginTop: 2 }}>May 4</div>
            </div>
          </div>
        </div>
      </div>

      <div style={{
        marginTop: 18, padding: '12px 14px', borderRadius: 12,
        background: 'var(--paper-2)', border: '1px solid var(--hairline)',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: 8,
          background: 'var(--cream)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24"><path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 16.8l-6.2 4.5 2.4-7.4L2 9.4h7.6L12 2z" fill="oklch(0.62 0.16 60)"/></svg>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 600 }}>Prize purse</div>
          <div style={{ fontSize: 11, color: 'var(--muted)' }}>1st: 50,000 PKR · 2nd: 20,000 PKR · MOT: 5,000 PKR</div>
        </div>
      </div>
    </div>
  );
}

function StatsTab() {
  const top = [
    { kind: 'Most runs', name: 'Bilal Ahmed', team: 'LL', stat: '218', meta: '4 inn · avg 54.5 · SR 142.4' },
    { kind: 'Most wickets', name: 'Haroon Malik', team: 'LL', stat: '11', meta: '4 mt · ER 6.8 · 1 ×4w' },
    { kind: 'Highest score', name: 'Faraz Ali', team: 'MT', stat: '94*', meta: 'vs FX · 47 balls' },
    { kind: 'Best bowling', name: 'Salman R.', team: 'KS', stat: '5/19', meta: 'vs ML · 4 ov' },
  ];
  return (
    <div style={{ padding: '16px 16px 0' }}>
      <div className="ck-section-h" style={{ marginBottom: 10 }}>Tournament leaders</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {top.map((r, i) => (
          <div key={i} style={{
            background: 'var(--surface)', border: '1px solid var(--hairline)',
            borderRadius: 14, padding: '12px 14px',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{r.kind}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                <CkTBadge id={r.team} size={20} />
                <span style={{ fontSize: 14, fontWeight: 600 }}>{r.name}</span>
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{r.meta}</div>
            </div>
            <div className="ck-display ck-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em' }}>
              {r.stat}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

window.CkTournament = CkTournament;

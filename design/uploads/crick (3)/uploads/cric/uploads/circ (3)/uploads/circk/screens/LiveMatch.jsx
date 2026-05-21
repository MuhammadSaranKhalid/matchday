// LiveMatch.jsx — Spectator-facing live match view (read-only, what fans see)

const teamColors = {
  LL: { bg: 'oklch(0.36 0.10 148)', mono: 'LL', name: 'Lahore Lions' },
  MT: { bg: 'oklch(0.42 0.16 28)',  mono: 'MT', name: 'Model Town XI' },
};

function TeamBadge({ team, size = 36 }) {
  const t = teamColors[team];
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.28,
      background: t.bg, color: 'white',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700,
      fontSize: size * 0.4, letterSpacing: '-0.02em',
      flexShrink: 0,
    }}>{t.mono}</div>
  );
}

function CkBall({ kind, label }) {
  return <span className={`ck-ball ${kind}`}>{label}</span>;
}

// Mini run-rate sparkline
function RunRateSpark({ values, target }) {
  const w = 180, h = 44;
  const max = Math.max(...values, target) * 1.1;
  const pts = values.map((v, i) => `${(i/(values.length-1))*w},${h - (v/max)*h}`).join(' ');
  const tY = h - (target/max)*h;
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      <line x1={0} y1={tY} x2={w} y2={tY} stroke="oklch(0.62 0.19 28)" strokeWidth="1" strokeDasharray="3,3" />
      <polyline points={pts} fill="none" stroke="oklch(0.18 0.02 80)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      {values.map((v, i) => (
        <circle key={i} cx={(i/(values.length-1))*w} cy={h - (v/max)*h} r="2" fill="oklch(0.18 0.02 80)" />
      ))}
    </svg>
  );
}

function CkLiveMatch() {
  const [tab, setTab] = React.useState('Live');

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
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="oklch(0.18 0.02 80)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className="ck-chip live">LIVE</span>
          <span style={{ fontSize: 12, color: 'var(--muted)', fontWeight: 500 }}>Spring Cup · QF1</span>
        </div>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><circle cx="5" cy="12" r="1.6" fill="oklch(0.18 0.02 80)"/><circle cx="12" cy="12" r="1.6" fill="oklch(0.18 0.02 80)"/><circle cx="19" cy="12" r="1.6" fill="oklch(0.18 0.02 80)"/></svg>
        </button>
      </div>

      {/* Hero scoreboard */}
      <div style={{
        margin: '8px 16px 14px', padding: '20px 18px',
        borderRadius: 22, background: 'var(--ink)', color: 'var(--paper)',
        position: 'relative', overflow: 'hidden',
      }}>
        {/* faint pitch markings */}
        <svg width="100%" height="100%" viewBox="0 0 360 240" preserveAspectRatio="none" style={{
          position: 'absolute', inset: 0, opacity: 0.06,
        }}>
          <ellipse cx="180" cy="120" rx="170" ry="100" stroke="white" strokeWidth="1" fill="none"/>
          <ellipse cx="180" cy="120" rx="100" ry="60" stroke="white" strokeWidth="1" fill="none"/>
          <rect x="170" y="80" width="20" height="80" stroke="white" strokeWidth="1" fill="none"/>
        </svg>

        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 14, position: 'relative' }}>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.55)', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase' }}>T20 · 2nd Innings</div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.55)', fontWeight: 600, letterSpacing: '0.05em' }}>Gaddafi Stadium B-Ground</div>
        </div>

        {/* Team A — done */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12, position: 'relative' }}>
          <TeamBadge team="LL" size={32} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600, opacity: 0.85 }}>Lahore Lions</div>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)' }}>20.0 ov</div>
          </div>
          <div className="ck-display ck-tnum" style={{ fontSize: 24, fontWeight: 700, opacity: 0.85 }}>
            177<span style={{ fontSize: 16, opacity: 0.6 }}>/8</span>
          </div>
        </div>

        {/* Team B — batting */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative' }}>
          <TeamBadge team="MT" size={44} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 700 }}>
              Model Town XI
              <span style={{
                marginLeft: 8, padding: '2px 6px', borderRadius: 4,
                background: 'rgba(255,255,255,0.15)', fontSize: 10, fontWeight: 600,
                letterSpacing: '0.06em', textTransform: 'uppercase',
              }}>Bat</span>
            </div>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.55)' }}>14.3 ov · CRR 9.10</div>
          </div>
          <div className="ck-display ck-tnum" style={{ fontSize: 38, fontWeight: 700, lineHeight: 1 }}>
            132<span style={{ fontSize: 22, opacity: 0.6 }}>/4</span>
          </div>
        </div>

        {/* Required */}
        <div style={{
          marginTop: 16, padding: '12px 14px', borderRadius: 12,
          background: 'rgba(255,255,255,0.07)',
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
          position: 'relative',
        }}>
          <div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Need</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700, marginTop: 2 }}>46</div>
          </div>
          <div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>From</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700, marginTop: 2 }}>33<span style={{ fontSize: 13, opacity: 0.6 }}>b</span></div>
          </div>
          <div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>RRR</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700, marginTop: 2, color: 'oklch(0.85 0.13 80)' }}>8.36</div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', padding: '0 16px' }}>
        <Tab id="Live" /><Tab id="Scorecard" /><Tab id="Stats" /><Tab id="Squads" />
      </div>

      {tab === 'Scorecard' && <LMScorecard />}
      {tab === 'Stats' && <LMStats />}
      {tab === 'Squads' && <LMSquads />}
      {tab !== 'Live' ? null : <>

      {/* At the crease */}
      <div style={{ padding: '18px 16px 8px' }}>
        <div className="ck-section-h" style={{ marginBottom: 10 }}>At the crease</div>
        <div style={{
          background: 'var(--surface)', borderRadius: 16,
          border: '1px solid var(--hairline)',
          overflow: 'hidden',
        }}>
          {/* striker */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px' }}>
            <div className="ck-avatar">UR</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                Usman Riaz
                <span style={{
                  width: 14, height: 14, borderRadius: 999, background: 'var(--red)', color: 'white',
                  fontSize: 9, fontWeight: 700, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                }}>•</span>
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>4 fours · 2 sixes</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700 }}>54<span style={{ fontSize: 12, color: 'var(--muted)' }}>(31)</span></div>
              <div style={{ fontSize: 10, color: 'var(--muted)' }}>SR 174.2</div>
            </div>
          </div>
          <div style={{ height: 1, background: 'var(--hairline)' }} />
          {/* non-striker */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px' }}>
            <div className="ck-avatar">FA</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>Faraz Ali</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>3 fours</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700, color: 'var(--ink-2)' }}>28<span style={{ fontSize: 12, color: 'var(--muted)' }}>(22)</span></div>
              <div style={{ fontSize: 10, color: 'var(--muted)' }}>SR 127.3</div>
            </div>
          </div>
          <div style={{ height: 1, background: 'var(--hairline)' }} />
          {/* bowler */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', background: 'var(--paper-2)' }}>
            <div className="ck-avatar" style={{ background: 'oklch(0.36 0.10 148)', color: 'white', borderColor: 'transparent' }}>HM</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>Haroon Malik <span style={{ fontSize: 11, color: 'var(--muted)', fontWeight: 500 }}>· Bowling</span></div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>RA off-spin</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div className="ck-display ck-tnum" style={{ fontSize: 16, fontWeight: 700 }}>1<span style={{ fontSize: 12, color: 'var(--muted)' }}>/24</span></div>
              <div style={{ fontSize: 10, color: 'var(--muted)' }}>2.3 ov · ER 9.6</div>
            </div>
          </div>
        </div>
      </div>

      {/* This over */}
      <div style={{ padding: '14px 16px 8px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <div className="ck-section-h">Over 15 · Haroon Malik</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>3 balls · 8 runs</div>
        </div>
        <div style={{
          background: 'var(--surface)', borderRadius: 16,
          border: '1px solid var(--hairline)',
          padding: 14,
          display: 'flex', gap: 6, alignItems: 'center',
        }}>
          <CkBall kind="dot" label="•" />
          <CkBall kind="four" label="4" />
          <CkBall kind="" label="2" />
          <CkBall kind="extra" label="wd" />
          {[3,4,5].map(i => (
            <div key={i} style={{
              width: 28, height: 28, borderRadius: 999,
              border: '1.5px dashed var(--line)',
            }} />
          ))}
        </div>
      </div>

      {/* Last 5 overs sparkline */}
      <div style={{ padding: '14px 16px 8px' }}>
        <div className="ck-section-h" style={{ marginBottom: 10 }}>Last 6 overs</div>
        <div style={{
          background: 'var(--surface)', borderRadius: 16,
          border: '1px solid var(--hairline)', padding: '14px 14px 10px',
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{ flex: 1 }}>
            <RunRateSpark values={[6, 9, 14, 7, 11, 12]} target={8.85} />
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4, fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)' }}>
              <span>9</span><span>10</span><span>11</span><span>12</span><span>13</span><span>14</span>
            </div>
          </div>
          <div style={{ width: 1, height: 40, background: 'var(--hairline)' }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <div style={{ fontSize: 10, color: 'var(--muted)', fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>Last 6</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700 }}>59</div>
            <div style={{ fontSize: 10, color: 'var(--green)', fontWeight: 600 }}>9.83 RR</div>
          </div>
        </div>
      </div>

      {/* Wickets fall */}
      <div style={{ padding: '14px 16px 30px' }}>
        <div className="ck-section-h" style={{ marginBottom: 10 }}>Recent wickets</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { w: 4, name: 'Sameer Iqbal', out: 'c Khan b Malik', score: '21 (15)', over: '12.4' },
            { w: 3, name: 'Bilal Ahmed (c)', out: 'b Hussain', score: '34 (22)', over: '9.2' },
            { w: 2, name: 'Zain Tariq', out: 'lbw b Rauf', score: '8 (9)', over: '4.6' },
          ].map(w => (
            <div key={w.w} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '10px 12px', background: 'var(--surface)',
              border: '1px solid var(--hairline)', borderRadius: 12,
            }}>
              <div style={{
                width: 24, height: 24, borderRadius: 6,
                background: 'var(--red-soft)', color: 'var(--red)',
                fontSize: 11, fontWeight: 700, fontFamily: 'Inter Tight',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{w.w}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{w.name}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{w.out}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className="ck-display ck-tnum" style={{ fontSize: 14, fontWeight: 700 }}>{w.score}</div>
                <div style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>{w.over} ov</div>
              </div>
            </div>
          ))}
        </div>
      </div>
      </>}
    </div>
  );
}

// ── Scorecard tab ─────────────────────────────────────────────
function LMScorecard() {
  const [innings, setInnings] = React.useState(2);

  const i1 = {
    team: 'Lahore Lions', total: '177/8', overs: '20.0', rr: '8.85',
    bat: [
      { name: 'Bilal Ahmed (c)', out: 'c Riaz b Hussain', r: 48, b: 31, f: 5, s: 2 },
      { name: 'Zain Tariq',      out: 'b Rauf',           r: 12, b: 14, f: 1, s: 0 },
      { name: 'Sameer Iqbal',    out: 'c Khan b Malik',   r: 21, b: 15, f: 2, s: 1 },
      { name: 'Awais Yousuf',    out: 'run out (Ali)',    r: 34, b: 22, f: 3, s: 1 },
      { name: 'Haroon Malik',    out: 'not out',          r: 41, b: 24, f: 3, s: 2 },
      { name: 'Tariq Aslam',     out: 'lbw b Hussain',    r: 8,  b: 7,  f: 1, s: 0 },
    ],
    bowl: [
      { name: 'M. Hussain',  o: '4.0', m: 0, r: 28, w: 3, er: '7.0' },
      { name: 'A. Rauf',     o: '4.0', m: 0, r: 31, w: 2, er: '7.8' },
      { name: 'F. Ali',      o: '4.0', m: 0, r: 38, w: 1, er: '9.5' },
      { name: 'U. Riaz',     o: '4.0', m: 0, r: 35, w: 1, er: '8.8' },
      { name: 'S. Khan',     o: '4.0', m: 0, r: 42, w: 0, er: '10.5' },
    ],
    extras: 'b 2 · lb 4 · w 7 · nb 2',
    fow: '1-21 (Tariq, 3.4) · 2-58 (Iqbal, 7.6) · 3-92 (Ahmed, 11.2) · 4-138 (Yousuf, 15.5)',
  };

  const i2 = {
    team: 'Model Town XI', total: '132/4', overs: '14.3', rr: '9.10',
    bat: [
      { name: 'Zain Tariq',       out: 'lbw b Rauf',         r: 8,  b: 9,  f: 1, s: 0 },
      { name: 'Bilal Ahmed (c)',  out: 'b Hussain',           r: 34, b: 22, f: 3, s: 1 },
      { name: 'Sameer Iqbal',     out: 'c Khan b Malik',      r: 21, b: 15, f: 2, s: 1 },
      { name: 'Usman Riaz',       out: 'batting',             r: 54, b: 31, f: 4, s: 2 },
      { name: 'Faraz Ali',        out: 'batting',             r: 28, b: 22, f: 3, s: 0 },
    ],
    bowl: [
      { name: 'M. Hussain',   o: '3.0', m: 0, r: 22, w: 1, er: '7.3' },
      { name: 'A. Rauf',      o: '3.0', m: 0, r: 18, w: 1, er: '6.0' },
      { name: 'S. Khan',      o: '3.0', m: 0, r: 28, w: 1, er: '9.3' },
      { name: 'H. Malik',     o: '2.3', m: 0, r: 24, w: 1, er: '9.6' },
      { name: 'T. Aslam',     o: '3.0', m: 0, r: 33, w: 0, er: '11.0' },
    ],
    extras: 'lb 3 · w 4',
    fow: '1-14 (Tariq, 2.5) · 2-66 (Ahmed, 9.2) · 3-99 (Iqbal, 12.4)',
  };

  const data = innings === 1 ? i1 : i2;

  return (
    <div style={{ padding: '12px 16px 30px' }}>
      {/* Innings switch */}
      <div style={{
        display: 'flex', background: 'var(--paper-2)', borderRadius: 10,
        padding: 3, gap: 3, marginBottom: 14,
      }}>
        {[1,2].map(n => (
          <button key={n} onClick={() => setInnings(n)} style={{
            flex: 1, padding: '8px 0', borderRadius: 8, cursor: 'pointer',
            background: innings === n ? 'var(--paper)' : 'transparent',
            color: innings === n ? 'var(--ink)' : 'var(--muted)',
            border: 'none', fontWeight: 600, fontSize: 12,
            boxShadow: innings === n ? '0 1px 2px rgba(0,0,0,0.04)' : 'none',
          }}>
            {n === 1 ? 'Lahore Lions' : 'Model Town XI'} · {n === 1 ? '177/8' : '132/4'}
          </button>
        ))}
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
        <div>
          <div className="ck-section-h">{data.team}</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>
            {data.overs} ov · RR {data.rr}
          </div>
        </div>
        <div className="ck-display ck-tnum" style={{ fontSize: 28, fontWeight: 700 }}>{data.total}</div>
      </div>

      {/* Batting */}
      <div style={{ marginTop: 8, background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 36px 28px 28px 28px',
          gap: 6, padding: '8px 12px', fontSize: 9, fontFamily: 'JetBrains Mono',
          color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em',
          background: 'var(--paper-2)',
        }}>
          <span>Batter</span>
          <span style={{ textAlign: 'right' }}>R</span>
          <span style={{ textAlign: 'right' }}>B</span>
          <span style={{ textAlign: 'right' }}>4s</span>
          <span style={{ textAlign: 'right' }}>6s</span>
        </div>
        {data.bat.map((b, i) => {
          const out = b.out === 'batting' || b.out === 'not out';
          return (
            <div key={i} style={{
              display: 'grid', gridTemplateColumns: '1fr 36px 28px 28px 28px',
              gap: 6, padding: '10px 12px', alignItems: 'center',
              borderTop: i > 0 ? '1px solid var(--hairline)' : 'none',
            }}>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {b.name} {b.out === 'batting' && <span style={{ color: 'var(--red)', fontSize: 9, marginLeft: 4, fontWeight: 700 }}>•BAT</span>}
                </div>
                <div style={{ fontSize: 11, color: out ? 'var(--green)' : 'var(--muted)',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.out}</div>
              </div>
              <span className="ck-display ck-tnum" style={{ fontSize: 16, fontWeight: 700, textAlign: 'right' }}>{b.r}</span>
              <span className="ck-tnum" style={{ fontSize: 12, color: 'var(--muted)', textAlign: 'right' }}>{b.b}</span>
              <span className="ck-tnum" style={{ fontSize: 12, color: 'var(--ink-2)', textAlign: 'right' }}>{b.f}</span>
              <span className="ck-tnum" style={{ fontSize: 12, color: 'var(--ink-2)', textAlign: 'right' }}>{b.s}</span>
            </div>
          );
        })}
      </div>

      <div style={{ fontSize: 11, color: 'var(--muted)', padding: '10px 4px', lineHeight: 1.5 }}>
        <span style={{ fontFamily: 'JetBrains Mono', textTransform: 'uppercase', letterSpacing: '0.08em', fontSize: 9, color: 'var(--soft)' }}>EXTRAS </span>
        {data.extras}
      </div>
      <div style={{ fontSize: 11, color: 'var(--muted)', padding: '0 4px 12px', lineHeight: 1.5 }}>
        <span style={{ fontFamily: 'JetBrains Mono', textTransform: 'uppercase', letterSpacing: '0.08em', fontSize: 9, color: 'var(--soft)' }}>FALL </span>
        {data.fow}
      </div>

      {/* Bowling */}
      <div className="ck-section-h" style={{ marginTop: 10, marginBottom: 8 }}>Bowling</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 30px 26px 30px 26px 36px',
          gap: 6, padding: '8px 12px', fontSize: 9, fontFamily: 'JetBrains Mono',
          color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em',
          background: 'var(--paper-2)',
        }}>
          <span>Bowler</span>
          <span style={{ textAlign: 'right' }}>O</span>
          <span style={{ textAlign: 'right' }}>M</span>
          <span style={{ textAlign: 'right' }}>R</span>
          <span style={{ textAlign: 'right' }}>W</span>
          <span style={{ textAlign: 'right' }}>ER</span>
        </div>
        {data.bowl.map((b, i) => (
          <div key={i} style={{
            display: 'grid', gridTemplateColumns: '1fr 30px 26px 30px 26px 36px',
            gap: 6, padding: '10px 12px', alignItems: 'center',
            borderTop: i > 0 ? '1px solid var(--hairline)' : 'none',
          }}>
            <span style={{ fontSize: 13, fontWeight: 600,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.name}</span>
            <span className="ck-tnum" style={{ fontSize: 12, color: 'var(--ink-2)', textAlign: 'right' }}>{b.o}</span>
            <span className="ck-tnum" style={{ fontSize: 12, color: 'var(--muted)', textAlign: 'right' }}>{b.m}</span>
            <span className="ck-tnum" style={{ fontSize: 12, color: 'var(--ink-2)', textAlign: 'right' }}>{b.r}</span>
            <span className="ck-display ck-tnum" style={{ fontSize: 15, fontWeight: 700, textAlign: 'right',
              color: b.w >= 2 ? 'var(--red)' : 'var(--ink)' }}>{b.w}</span>
            <span className="ck-tnum" style={{ fontSize: 11, color: 'var(--muted)', textAlign: 'right', fontFamily: 'JetBrains Mono' }}>{b.er}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Stats tab ─────────────────────────────────────────────────
function LMStats() {
  // Partnership donut
  const partnership = { runs: 73, balls: 47, striker: 41, nonStriker: 32 }; // sum slightly off — illustrative
  const sPct = (partnership.striker / (partnership.striker + partnership.nonStriker)) * 100;

  // Wagon wheel: simple placeholder with shot dots
  const shots = [
    { angle: 30, dist: 0.9, runs: 6 },
    { angle: 60, dist: 0.8, runs: 4 },
    { angle: 110, dist: 0.7, runs: 4 },
    { angle: 145, dist: 0.5, runs: 2 },
    { angle: 200, dist: 0.85, runs: 6 },
    { angle: 260, dist: 0.6, runs: 4 },
    { angle: 285, dist: 0.4, runs: 1 },
    { angle: 320, dist: 0.5, runs: 1 },
    { angle: 5, dist: 0.4, runs: 2 },
    { angle: 175, dist: 0.45, runs: 1 },
    { angle: 95, dist: 0.6, runs: 4 },
  ];

  return (
    <div style={{ padding: '14px 16px 30px', display: 'flex', flexDirection: 'column', gap: 14 }}>
      {/* Headline stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
        {[
          { l: 'Partnership', v: '73', m: '47 b · 9.32 RR', tone: 'var(--green)' },
          { l: 'Powerplay', v: '54/1', m: '6 ov · RR 9.0', tone: 'var(--ink)' },
          { l: 'Boundaries', v: '14', m: '11 fours · 3 sixes', tone: 'var(--ink)' },
        ].map((s, i) => (
          <div key={i} style={{
            background: 'var(--surface)', border: '1px solid var(--hairline)',
            borderRadius: 12, padding: '10px 12px',
          }}>
            <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.l}</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700, color: s.tone, marginTop: 2 }}>{s.v}</div>
            <div style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>{s.m}</div>
          </div>
        ))}
      </div>

      {/* Partnership split bar */}
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: '14px' }}>
        <div className="ck-section-h" style={{ marginBottom: 10 }}>4th-wicket partnership</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 10 }}>
          <span className="ck-display ck-tnum" style={{ fontSize: 32, fontWeight: 700 }}>73</span>
          <span style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>off 47 balls</span>
          <span style={{ marginLeft: 'auto', fontSize: 11, color: 'var(--green)', fontWeight: 600 }}>+7 since last over</span>
        </div>
        <div style={{ height: 14, borderRadius: 7, overflow: 'hidden', display: 'flex', background: 'var(--paper-2)' }}>
          <div style={{ width: `${sPct}%`, background: 'var(--ink)' }} />
          <div style={{ width: `${100-sPct}%`, background: 'var(--soft)' }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 11 }}>
          <span><span style={{ fontWeight: 600 }}>U. Riaz</span> <span style={{ color: 'var(--muted)' }}>41 (28)</span></span>
          <span style={{ color: 'var(--muted)' }}><span style={{ color: 'var(--ink-2)', fontWeight: 600 }}>F. Ali</span> 32 (19)</span>
        </div>
      </div>

      {/* Wagon wheel */}
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: '14px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
          <div className="ck-section-h">Wagon wheel · U. Riaz</div>
          <span style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>54 (31)</span>
        </div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <svg width="160" height="160" viewBox="-100 -100 200 200" style={{ flexShrink: 0 }}>
            {/* boundary */}
            <circle r="95" fill="oklch(0.965 0.010 85)" stroke="oklch(0.90 0.008 85)" strokeWidth="1" />
            {/* inner */}
            <circle r="50" fill="none" stroke="oklch(0.90 0.008 85)" strokeWidth="1" strokeDasharray="3,3" />
            {/* pitch */}
            <rect x="-7" y="-22" width="14" height="44" fill="oklch(0.94 0.05 90)" stroke="oklch(0.90 0.008 85)" strokeWidth="0.5"/>
            {shots.map((s, i) => {
              const rad = (s.angle * Math.PI) / 180;
              const x = Math.sin(rad) * s.dist * 95;
              const y = -Math.cos(rad) * s.dist * 95;
              const c = s.runs === 6 ? 'oklch(0.18 0.02 80)'
                       : s.runs === 4 ? 'oklch(0.56 0.13 148)'
                       : 'oklch(0.62 0.19 28)';
              return (
                <g key={i}>
                  <line x1="0" y1="0" x2={x} y2={y} stroke={c} strokeWidth={s.runs >= 4 ? 1.5 : 0.8} opacity={s.runs >= 4 ? 0.85 : 0.4} />
                  <circle cx={x} cy={y} r={s.runs === 6 ? 4 : s.runs === 4 ? 3.5 : 2} fill={c} />
                </g>
              );
            })}
          </svg>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div>
              <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>Off side</div>
              <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700 }}>32 <span style={{ fontSize: 11, color: 'var(--muted)' }}>(59%)</span></div>
            </div>
            <div>
              <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>Leg side</div>
              <div className="ck-display ck-tnum" style={{ fontSize: 20, fontWeight: 700 }}>22 <span style={{ fontSize: 11, color: 'var(--muted)' }}>(41%)</span></div>
            </div>
            <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: 'var(--muted)' }}>
                <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--ink)' }} />6
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: 'var(--muted)' }}>
                <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--green)' }} />4
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: 'var(--muted)' }}>
                <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--red)' }} />1-3
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Manhattan-ish over chart */}
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: '14px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
          <div className="ck-section-h">Runs per over</div>
          <span style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>● innings 2</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 80 }}>
          {[8, 6, 11, 4, 7, 18, 9, 6, 14, 7, 11, 12, 11, 9].map((v, i) => {
            const isWkt = i === 4 || i === 11;
            const max = 18;
            return (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
                <div style={{ fontSize: 9, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>{v}</div>
                <div style={{
                  width: '100%', height: `${(v/max)*60}px`, borderRadius: '3px 3px 0 0',
                  background: isWkt ? 'var(--red)' : v >= 12 ? 'var(--ink)' : 'var(--ink-2)',
                  position: 'relative',
                }}>
                  {isWkt && <div style={{ position: 'absolute', top: -8, left: '50%', transform: 'translateX(-50%)', width: 4, height: 4, borderRadius: 999, background: 'var(--red)' }}/>}
                </div>
                <div style={{ fontSize: 8, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>{i+1}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ── Squads tab ────────────────────────────────────────────────
function LMSquads() {
  const [side, setSide] = React.useState('LL');

  const ll = [
    { n: 'Bilal Ahmed',   r: 'Captain · Batter',     j: 7,  c: true,  k: false, claimed: true  },
    { n: 'Zain Tariq',    r: 'Opener · Batter',      j: 4,  c: false, k: false, claimed: true  },
    { n: 'Sameer Iqbal',  r: 'Top order',            j: 11, c: false, k: false, claimed: true  },
    { n: 'Awais Yousuf',  r: 'Wicket-keeper',        j: 17, c: false, k: true,  claimed: true  },
    { n: 'Haroon Malik',  r: 'All-rounder · spin',   j: 9,  c: false, k: false, claimed: true  },
    { n: 'Tariq Aslam',   r: 'Bowler · pace',        j: 22, c: false, k: false, claimed: false },
    { n: 'M. Hussain',    r: 'Bowler · pace',        j: 88, c: false, k: false, claimed: true  },
    { n: 'A. Rauf',       r: 'Bowler · medium',      j: 12, c: false, k: false, claimed: true  },
    { n: 'F. Ali',        r: 'All-rounder',          j: 5,  c: false, k: false, claimed: true  },
    { n: 'U. Riaz',       r: 'Batter',               j: 33, c: false, k: false, claimed: true  },
    { n: 'S. Khan',       r: 'Bowler · spin',        j: 21, c: false, k: false, claimed: false },
  ];
  const mt = [
    { n: 'Faraz Ali',       r: 'Captain · All-rdr', j: 10, c: true,  k: false, claimed: true  },
    { n: 'Usman Riaz',      r: 'Opener · Batter',   j: 25, c: false, k: false, claimed: true  },
    { n: 'Imran Shah',      r: 'Top order',         j: 6,  c: false, k: false, claimed: true  },
    { n: 'Adeel Iqbal',     r: 'Wicket-keeper',     j: 18, c: false, k: true,  claimed: true  },
    { n: 'Junaid Tariq',    r: 'All-rounder',       j: 7,  c: false, k: false, claimed: false },
    { n: 'Salman Rashid',   r: 'Bowler · spin',     j: 13, c: false, k: false, claimed: true  },
    { n: 'Asad Mehmood',    r: 'Bowler · pace',     j: 99, c: false, k: false, claimed: false },
    { n: 'Khalid Saleem',   r: 'Bowler · medium',   j: 4,  c: false, k: false, claimed: true  },
    { n: 'Hamza Yousaf',    r: 'All-rounder',       j: 8,  c: false, k: false, claimed: true  },
    { n: 'Bilal Tahir',     r: 'Batter',            j: 14, c: false, k: false, claimed: true  },
    { n: 'Yasir Mahmood',   r: 'Bowler · pace',     j: 27, c: false, k: false, claimed: true  },
  ];

  const list = side === 'LL' ? ll : mt;
  const teamColor = side === 'LL' ? 'oklch(0.36 0.10 148)' : 'oklch(0.42 0.16 28)';
  const teamName = side === 'LL' ? 'Lahore Lions' : 'Model Town XI';

  return (
    <div style={{ padding: '14px 16px 30px' }}>
      {/* Side switch */}
      <div style={{
        display: 'flex', background: 'var(--paper-2)', borderRadius: 10,
        padding: 3, gap: 3, marginBottom: 14,
      }}>
        {[
          { id: 'LL', label: 'Lahore Lions', sub: 'Bat 1st · 177/8' },
          { id: 'MT', label: 'Model Town XI', sub: 'Chasing · 132/4' },
        ].map(t => (
          <button key={t.id} onClick={() => setSide(t.id)} style={{
            flex: 1, padding: '8px 10px', borderRadius: 8, cursor: 'pointer',
            background: side === t.id ? 'var(--paper)' : 'transparent',
            color: side === t.id ? 'var(--ink)' : 'var(--muted)',
            border: 'none', textAlign: 'left',
            boxShadow: side === t.id ? '0 1px 2px rgba(0,0,0,0.04)' : 'none',
          }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>{t.label}</div>
            <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: side === t.id ? 'var(--muted)' : 'var(--soft)' }}>{t.sub}</div>
          </button>
        ))}
      </div>

      {/* Team header */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12,
        padding: '12px 14px', background: 'var(--surface)',
        border: '1px solid var(--hairline)', borderRadius: 14, marginBottom: 12,
      }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12, background: teamColor,
          color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, letterSpacing: '-0.02em',
        }}>{side}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700 }}>{teamName}</div>
          <div style={{ fontSize: 11, color: 'var(--muted)' }}>Playing XI · {list.length} players</div>
        </div>
        <button style={{
          background: 'transparent', border: '1px solid var(--line)', borderRadius: 8,
          padding: '6px 10px', fontSize: 11, fontWeight: 600, color: 'var(--ink-2)', cursor: 'pointer',
        }}>Follow</button>
      </div>

      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        {list.map((p, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
            borderTop: i > 0 ? '1px solid var(--hairline)' : 'none',
          }}>
            {/* Jersey number */}
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'var(--paper-2)', border: '1px solid var(--hairline)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13,
              color: 'var(--ink-2)', fontVariantNumeric: 'tabular-nums',
            }}>{p.j}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, fontWeight: 600 }}>
                <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.n}</span>
                {p.c && <span style={{ fontSize: 9, fontWeight: 700, padding: '1px 4px', borderRadius: 3, background: 'var(--cream)', color: 'var(--ink-2)', letterSpacing: '0.06em' }}>C</span>}
                {p.k && <span style={{ fontSize: 9, fontWeight: 700, padding: '1px 4px', borderRadius: 3, background: 'var(--green-soft)', color: 'oklch(0.36 0.10 148)', letterSpacing: '0.06em' }}>WK</span>}
                {p.claimed ? (
                  <svg width="11" height="11" viewBox="0 0 14 14" title="claimed"><circle cx="7" cy="7" r="6.5" fill="oklch(0.56 0.13 148)"/><path d="M4 7.2l2 2 4-4.4" stroke="white" strokeWidth="1.6" fill="none" strokeLinecap="round"/></svg>
                ) : (
                  <span style={{ fontSize: 9, fontWeight: 600, padding: '1px 5px', borderRadius: 3, background: 'var(--paper-2)', color: 'var(--muted)', border: '1px dashed var(--line)', letterSpacing: '0.04em' }}>UNCLAIMED</span>
                )}
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{p.r}</div>
            </div>
            <svg width="16" height="16" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6" stroke="oklch(0.72 0.01 80)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
          </div>
        ))}
      </div>

      <div style={{ marginTop: 12, fontSize: 11, color: 'var(--muted)', lineHeight: 1.5, padding: '0 4px' }}>
        <span style={{ color: 'var(--ink-2)', fontWeight: 600 }}>Squad locked.</span> Mid-tournament substitutions are off — see tournament rules.
      </div>
    </div>
  );
}

window.CkLiveMatch = CkLiveMatch;

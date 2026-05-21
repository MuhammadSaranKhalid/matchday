// TournamentAwards.jsx — End-of-tournament: trophy moment + auto-suggested awards
// Two artboards in one component via prop: variant = 'winner' | 'awards'

function CkTournamentWinner() {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--ink)', color: 'var(--paper)' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 18px 4px', flexShrink: 0 }}>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M6 18L18 6M6 6l12 12" stroke="var(--paper)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
        </button>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.5)', letterSpacing: '0.12em' }}>SPRING CUP · 2026</span>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--paper)" strokeWidth="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
        </button>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 28px', textAlign: 'center', position: 'relative' }}>
        {/* faint pitch oval */}
        <svg width="500" height="500" viewBox="0 0 200 200" style={{ position: 'absolute', opacity: 0.08, pointerEvents: 'none' }}>
          <ellipse cx="100" cy="100" rx="95" ry="60" stroke="var(--paper)" strokeWidth="0.5" fill="none"/>
          <ellipse cx="100" cy="100" rx="55" ry="34" stroke="var(--paper)" strokeWidth="0.5" fill="none"/>
        </svg>

        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, letterSpacing: '0.2em', color: 'oklch(0.85 0.13 80)', marginBottom: 18 }}>
          ★  CHAMPIONS  ★
        </div>

        <div style={{
          width: 120, height: 120, borderRadius: 26,
          background: TEAMS.LL.bg, color: 'white',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontSize: 48, fontWeight: 800, letterSpacing: '-0.04em',
          boxShadow: '0 30px 60px -10px oklch(0.30 0.08 148 / 0.5)',
          marginBottom: 22,
        }}>LL</div>

        <h1 className="ck-display" style={{ fontSize: 38, fontWeight: 700, margin: 0, letterSpacing: '-0.035em', lineHeight: 1 }}>
          Lahore Lions
        </h1>
        <div style={{ marginTop: 10, fontSize: 14, color: 'rgba(255,255,255,0.6)' }}>
          beat Karachi Stars by 4 wickets
        </div>

        <div style={{ marginTop: 28, display: 'flex', gap: 22, alignItems: 'baseline' }}>
          {[
            ['7', 'matches'],
            ['6', 'wins'],
            ['+1.84', 'NRR'],
          ].map(([v, l], i) => (
            <div key={i} style={{ textAlign: 'center' }}>
              <div className="ck-display ck-tnum" style={{ fontSize: 26, fontWeight: 700, lineHeight: 1 }}>{v}</div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: '0.1em', color: 'rgba(255,255,255,0.5)', marginTop: 4, textTransform: 'uppercase' }}>{l}</div>
            </div>
          ))}
        </div>

        <button style={{
          marginTop: 40, padding: '12px 22px', borderRadius: 12,
          background: 'var(--paper)', color: 'var(--ink)', border: 'none',
          fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
        }}>See all awards →</button>
      </div>

      <div style={{ flexShrink: 0, padding: '14px 18px 22px', textAlign: 'center', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.35)', letterSpacing: '0.1em' }}>
        APR 30 — MAY 4 · GADDAFI B
      </div>
    </div>
  );
}

function CkTournamentAwards() {
  const [picked, setPicked] = React.useState({
    pot: 'BA', batter: 'BA', bowler: 'KS-2', allround: 'IT-1', fielder: 'MT-1',
  });
  const [confirmed, setConfirmed] = React.useState(false);

  const choices = {
    pot: [
      { id: 'BA', name: 'Babar A.', team: 'LL', stat: '342 runs · 12 wkts · impact 91' },
      { id: 'SR', name: 'Salman R.', team: 'KS', stat: '298 runs · 4 wkts · impact 84' },
      { id: 'FA', name: 'Faraz A.',  team: 'MT', stat: '5 fifties · impact 79' },
    ],
    batter: [
      { id: 'BA', name: 'Babar A.', team: 'LL', stat: '342 R · avg 57.0 · SR 142' },
      { id: 'SR', name: 'Salman R.', team: 'KS', stat: '298 R · avg 49.6 · SR 138' },
    ],
    bowler: [
      { id: 'KS-2', name: 'Wasim Q.', team: 'KS', stat: '14 wkts · econ 6.4' },
      { id: 'LL-2', name: 'Hassan A.', team: 'LL', stat: '12 wkts · econ 6.7' },
    ],
    allround: [
      { id: 'IT-1', name: 'Hamza T.', team: 'IT', stat: '210 R · 9 wkts' },
      { id: 'BA',   name: 'Babar A.', team: 'LL', stat: '342 R · 12 wkts' },
    ],
    fielder: [
      { id: 'MT-1', name: 'Adeel S.', team: 'MT', stat: '8 catches · 2 run-outs' },
      { id: 'KS-1', name: 'Bilal H.',  team: 'KS', stat: '6 catches · 3 run-outs' },
    ],
  };
  const labels = { pot: 'Player of the Tournament', batter: 'Best Batter', bowler: 'Best Bowler', allround: 'Best All-rounder', fielder: 'Best Fielder' };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 18px 4px', flexShrink: 0 }}>
        <button style={iconBtn}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="var(--ink)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
        </button>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>FINALIZE AWARDS</span>
        <span style={{ width: 22 }}/>
      </div>

      <div style={{ padding: '8px 18px 14px', flexShrink: 0 }}>
        <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, margin: 0, letterSpacing: '-0.03em', lineHeight: 1.05 }}>
          Suggested awards
        </h1>
        <div style={{ marginTop: 6, fontSize: 12, color: 'var(--muted)' }}>
          Auto-picked from tournament stats. Tap to override before publishing.
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 18px' }}>
        {Object.keys(labels).map(k => {
          const opts = choices[k];
          const sel = opts.find(o => o.id === picked[k]) || opts[0];
          const isPot = k === 'pot';
          return (
            <div key={k} style={{ marginBottom: 14 }}>
              <div className="ck-section-h" style={{ marginBottom: 6 }}>{labels[k]}</div>
              <div style={{
                background: isPot ? 'var(--ink)' : 'var(--surface)',
                color: isPot ? 'var(--paper)' : 'var(--ink)',
                border: isPot ? '1px solid transparent' : '1px solid var(--hairline)',
                borderRadius: 14, padding: '12px 14px',
                display: 'flex', alignItems: 'center', gap: 12,
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 999,
                  background: isPot ? 'oklch(0.85 0.13 80)' : TEAMS[sel.team]?.bg, color: 'white',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700,
                }}>
                  {isPot ? '★' : TEAMS[sel.team]?.mono}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700 }}>{sel.name}</div>
                  <div style={{ fontSize: 11, color: isPot ? 'rgba(255,255,255,0.6)' : 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>
                    {TEAMS[sel.team]?.name} · {sel.stat}
                  </div>
                </div>
              </div>
              {/* alt picks */}
              {opts.length > 1 && (
                <div style={{ display: 'flex', gap: 6, marginTop: 6, overflowX: 'auto', paddingBottom: 2 }}>
                  {opts.map(o => (
                    <button key={o.id} onClick={() => setPicked(p => ({ ...p, [k]: o.id }))} style={{
                      flexShrink: 0, padding: '6px 10px', borderRadius: 8,
                      border: picked[k] === o.id ? '1px solid var(--ink)' : '1px solid var(--hairline)',
                      background: picked[k] === o.id ? 'var(--ink)' : 'var(--paper)',
                      color: picked[k] === o.id ? 'var(--paper)' : 'var(--ink-2)',
                      fontFamily: 'Inter', fontSize: 11, fontWeight: 500, cursor: 'pointer',
                    }}>{o.name}</button>
                  ))}
                  <button style={{
                    flexShrink: 0, padding: '6px 10px', borderRadius: 8,
                    border: '1px dashed var(--line)', background: 'transparent',
                    color: 'var(--muted)', fontFamily: 'Inter', fontSize: 11, fontWeight: 500, cursor: 'pointer',
                  }}>+ Pick another</button>
                </div>
              )}
            </div>
          );
        })}
        <div style={{ height: 16 }}/>
      </div>

      <div style={{ flexShrink: 0, padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8 }}>
        <button style={{
          padding: '12px 18px', borderRadius: 12, border: '1px solid var(--hairline)',
          background: 'var(--paper)', color: 'var(--ink)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer',
        }}>Save draft</button>
        <button onClick={() => setConfirmed(true)} style={{
          flex: 1, padding: '12px 0', borderRadius: 12, border: 'none',
          background: confirmed ? 'var(--green)' : 'var(--ink)',
          color: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
        }}>{confirmed ? '✓ Published' : 'Publish & complete tournament'}</button>
      </div>
    </div>
  );
}

window.CkTournamentWinner = CkTournamentWinner;
window.CkTournamentAwards = CkTournamentAwards;

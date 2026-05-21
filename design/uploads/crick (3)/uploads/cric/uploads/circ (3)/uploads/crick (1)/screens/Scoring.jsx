// Scoring.jsx — Interactive live ball-by-ball scorer (the cricket-specific UI)
// One-handed, fast taps. State updates: score, balls, over progression, undo last ball.

const initial = {
  innings: 2,
  battingTeam: 'Model Town XI',
  bowlingTeam: 'Lahore Lions',
  target: 178,
  totalRuns: 132,
  totalWickets: 4,
  legalBallsBowled: 87, // 14.3
  striker:    { id: 'UR', name: 'Usman Riaz',  runs: 54, balls: 31, fours: 4, sixes: 2, onStrike: true },
  nonStriker: { id: 'FA', name: 'Faraz Ali',   runs: 28, balls: 22, fours: 3, sixes: 0, onStrike: false },
  bowler:     { id: 'HM', name: 'Haroon Malik', overs: 2, ballsThisOver: 3, runs: 24, wickets: 1, maidens: 0 },
  // log of recent balls — newest first
  log: [
    { id: 5, over: '15.3', kind: 'wd', label: 'wd', desc: 'Wide down leg', runs: 1 },
    { id: 4, over: '15.3', kind: '2',  label: '2',  desc: 'Pushed to deep cover', runs: 2 },
    { id: 3, over: '15.2', kind: 'four', label: '4', desc: 'Punched through covers', runs: 4 },
    { id: 2, over: '15.1', kind: 'dot',  label: '•', desc: 'Defended back', runs: 0 },
    { id: 1, over: '14.6', kind: 'six',  label: '6', desc: 'Slog-swept over midwicket', runs: 6 },
    { id: 0, over: '14.5', kind: 'wkt',  label: 'W', desc: 'c Khan b Malik · S. Iqbal 21(15)', runs: 0 },
  ],
};

function CkScoring() {
  const [s, setS] = React.useState(initial);
  const [extraOpen, setExtraOpen] = React.useState(null); // 'wd' | 'nb' | 'b' | 'lb' | null
  const [wktOpen, setWktOpen] = React.useState(false);
  const [undoFlash, setUndoFlash] = React.useState(false);

  // ── derived ─────────────────────────────────────────────
  const overs = `${Math.floor(s.legalBallsBowled / 6)}.${s.legalBallsBowled % 6}`;
  const remaining = Math.max(0, s.target - s.totalRuns);
  const ballsLeft = (20 * 6) - s.legalBallsBowled;
  const rrr = ballsLeft > 0 ? (remaining / (ballsLeft / 6)).toFixed(2) : '—';
  const crr = s.legalBallsBowled > 0 ? (s.totalRuns / (s.legalBallsBowled / 6)).toFixed(2) : '—';

  // ── helpers ─────────────────────────────────────────────
  const pushBall = (entry) => setS(prev => {
    const n = { ...prev };
    n.log = [{ ...entry, id: (prev.log[0]?.id ?? 0) + 1, over: overs }, ...prev.log].slice(0, 20);
    return n;
  });

  const swapStrike = (state) => {
    state.striker.onStrike = !state.striker.onStrike;
    state.nonStriker.onStrike = !state.nonStriker.onStrike;
    return { ...state, striker: state.nonStriker, nonStriker: state.striker };
  };

  const addLegalBall = (state) => {
    state.legalBallsBowled += 1;
    state.bowler = { ...state.bowler, ballsThisOver: state.bowler.ballsThisOver + 1 };
    if (state.bowler.ballsThisOver >= 6) {
      state.bowler = { ...state.bowler, overs: state.bowler.overs + 1, ballsThisOver: 0 };
      // end of over → swap strike
      Object.assign(state, swapStrike(state));
    }
    return state;
  };

  // Run scored off the bat
  const tapRun = (r) => {
    setS(prev => {
      let n = JSON.parse(JSON.stringify(prev));
      n.totalRuns += r;
      n.striker.runs += r;
      n.striker.balls += 1;
      if (r === 4) n.striker.fours += 1;
      if (r === 6) n.striker.sixes += 1;
      n.bowler.runs += r;
      n = addLegalBall(n);
      if (r % 2 === 1) n = swapStrike(n);
      return n;
    });
    pushBall({
      kind: r === 0 ? 'dot' : r === 4 ? 'four' : r === 6 ? 'six' : '',
      label: r === 0 ? '•' : String(r),
      desc: r === 0 ? 'Dot ball' : r === 4 ? 'Four!' : r === 6 ? 'SIX!' : `${r} run${r>1?'s':''}`,
      runs: r,
    });
  };

  const tapExtra = (type, runs = 1) => {
    setS(prev => {
      let n = JSON.parse(JSON.stringify(prev));
      n.totalRuns += runs;
      n.bowler.runs += runs;
      // wide & no-ball don't count as legal balls
      if (type === 'wd' || type === 'nb') {
        if (type === 'nb' && runs > 1) {
          // off-the-bat runs on a no-ball go to striker (simplified)
          n.striker.runs += (runs - 1);
        }
      } else {
        // bye / leg-bye — striker faces ball but doesn't get runs
        n.striker.balls += 1;
        n = addLegalBall(n);
        if (runs % 2 === 1) n = swapStrike(n);
      }
      return n;
    });
    const labels = { wd: 'wd', nb: 'nb', b: 'b', lb: 'lb' };
    const descs = {
      wd: 'Wide', nb: 'No-ball', b: 'Bye', lb: 'Leg-bye',
    };
    pushBall({
      kind: 'extra',
      label: runs > 1 ? `${runs}${labels[type]}` : labels[type],
      desc: `${descs[type]}${runs > 1 ? ` · ${runs} runs` : ''}`,
      runs,
    });
    setExtraOpen(null);
  };

  const tapWicket = (type) => {
    setS(prev => {
      let n = JSON.parse(JSON.stringify(prev));
      n.totalWickets += 1;
      n.striker.balls += 1;
      n.bowler.wickets += 1;
      n = addLegalBall(n);
      // simplified: striker out — replace with placeholder next batter
      n.striker = { id: '??', name: 'New Batter', runs: 0, balls: 0, fours: 0, sixes: 0, onStrike: true };
      return n;
    });
    pushBall({
      kind: 'wkt',
      label: 'W',
      desc: `WICKET · ${type}`,
      runs: 0,
    });
    setWktOpen(false);
  };

  const undo = () => {
    if (s.log.length === 0) return;
    const [last, ...rest] = s.log;
    setS(prev => {
      const n = JSON.parse(JSON.stringify(prev));
      n.log = rest;
      n.totalRuns = Math.max(0, n.totalRuns - last.runs);
      n.bowler.runs = Math.max(0, n.bowler.runs - last.runs);
      // very simplified rollback: treat all undo as losing one legal ball
      // (a real scorer would store full ball state, but this is a hi-fi demo)
      if (last.kind !== 'extra' || (last.label !== 'wd' && !last.label.includes('nb'))) {
        n.legalBallsBowled = Math.max(0, n.legalBallsBowled - 1);
        n.bowler.ballsThisOver = Math.max(0, n.bowler.ballsThisOver - 1);
        n.striker.balls = Math.max(0, n.striker.balls - 1);
      }
      if (last.kind === 'four' || last.kind === 'six' || /^\d+$/.test(last.label)) {
        n.striker.runs = Math.max(0, n.striker.runs - last.runs);
        if (last.kind === 'four') n.striker.fours = Math.max(0, n.striker.fours - 1);
        if (last.kind === 'six') n.striker.sixes = Math.max(0, n.striker.sixes - 1);
      }
      if (last.kind === 'wkt') {
        n.totalWickets = Math.max(0, n.totalWickets - 1);
        n.bowler.wickets = Math.max(0, n.bowler.wickets - 1);
      }
      return n;
    });
    setUndoFlash(true);
    setTimeout(() => setUndoFlash(false), 600);
  };

  // ── This-over balls (visual) ────────────────────────────
  const overBalls = s.log.filter(b => b.over.startsWith(`${Math.floor(s.legalBallsBowled / 6)}.`)).slice().reverse();

  // ── UI ──────────────────────────────────────────────────
  const RunBtn = ({ r, big }) => (
    <button onClick={() => tapRun(r)} style={{
      flex: 1, height: big ? 56 : 48,
      borderRadius: 14,
      border: 'none', cursor: 'pointer',
      background: r === 4 ? 'var(--green-soft)' : r === 6 ? 'var(--ink)' : 'var(--surface)',
      color: r === 6 ? 'var(--paper)' : r === 4 ? 'oklch(0.36 0.10 148)' : 'var(--ink)',
      boxShadow: r === 6 ? 'var(--shadow-2)' : '0 0 0 1px var(--hairline)',
      fontFamily: 'Inter Tight', fontWeight: 700,
      fontSize: big ? 24 : 22, letterSpacing: '-0.02em',
      fontVariantNumeric: 'tabular-nums',
      transition: 'transform .08s ease',
    }}
    onMouseDown={e => e.currentTarget.style.transform = 'scale(0.96)'}
    onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
    onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
    >
      {r === 0 ? '•' : r}
    </button>
  );

  const ExtraBtn = ({ k, label }) => (
    <button onClick={() => setExtraOpen(extraOpen === k ? null : k)} style={{
      flex: 1, padding: '10px 0',
      borderRadius: 12, cursor: 'pointer',
      background: extraOpen === k ? 'var(--ink)' : 'var(--cream)',
      color: extraOpen === k ? 'var(--paper)' : 'var(--ink-2)',
      border: 'none',
      fontFamily: 'Inter', fontWeight: 700, fontSize: 13,
      letterSpacing: '0.04em', textTransform: 'uppercase',
    }}>{label}</button>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--paper)' }}>
      <div style={{ height: 44 }} />

      {/* Top bar — minimal, scorer mode */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 16px 6px',
      }}>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18" stroke="oklch(0.18 0.02 80)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
        </button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className="ck-chip live">SCORING</span>
          <span style={{ fontSize: 11, color: 'var(--muted)', fontWeight: 600, fontFamily: 'JetBrains Mono' }}>
            QF1 · T20
          </span>
        </div>
        <button style={{
          background: 'var(--paper-2)', border: '1px solid var(--hairline)',
          padding: '6px 10px', cursor: 'pointer', borderRadius: 8,
          fontSize: 12, fontWeight: 600, color: 'var(--ink-2)',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3" fill="oklch(0.55 0.02 80)"/><circle cx="5" cy="12" r="3" fill="oklch(0.55 0.02 80)"/><circle cx="19" cy="12" r="3" fill="oklch(0.55 0.02 80)"/></svg>
          More
        </button>
      </div>

      {/* Compact scoreboard */}
      <div style={{
        margin: '4px 12px 10px', padding: '12px 14px',
        background: 'var(--ink)', color: 'var(--paper)', borderRadius: 16,
      }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10 }}>
          <div className="ck-display ck-tnum" style={{ fontSize: 38, fontWeight: 700, lineHeight: 0.95 }}>
            {s.totalRuns}<span style={{ opacity: 0.55 }}>/{s.totalWickets}</span>
          </div>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 1 }}>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>Overs</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 18, fontWeight: 700 }}>{overs}<span style={{ fontSize: 11, opacity: 0.5 }}> /20</span></div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>Need</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 18, fontWeight: 700 }}>
              {remaining}<span style={{ fontSize: 11, opacity: 0.5 }}> off {ballsLeft}</span>
            </div>
          </div>
        </div>
        <div style={{
          display: 'flex', justifyContent: 'space-between', marginTop: 8, paddingTop: 8,
          borderTop: '1px solid rgba(255,255,255,0.1)',
          fontSize: 11, fontFamily: 'JetBrains Mono',
        }}>
          <span style={{ color: 'rgba(255,255,255,0.55)' }}>CRR <span style={{ color: 'white', fontWeight: 600 }}>{crr}</span></span>
          <span style={{ color: 'rgba(255,255,255,0.55)' }}>RRR <span style={{ color: 'oklch(0.85 0.13 80)', fontWeight: 600 }}>{rrr}</span></span>
          <span style={{ color: 'rgba(255,255,255,0.55)' }}>vs <span style={{ color: 'white', fontWeight: 600 }}>LL 177/8</span></span>
        </div>
      </div>

      {/* Striker / Non-striker / Bowler */}
      <div style={{ padding: '0 12px', display: 'flex', flexDirection: 'column', gap: 6 }}>
        {/* Batters row */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6,
        }}>
          {[s.striker, s.nonStriker].map((b, i) => (
            <div key={i} style={{
              padding: '10px 12px', borderRadius: 12,
              background: b.onStrike ? 'var(--surface)' : 'var(--paper-2)',
              border: b.onStrike ? '1.5px solid var(--ink)' : '1px solid var(--hairline)',
              position: 'relative',
            }}>
              {b.onStrike && (
                <div style={{
                  position: 'absolute', top: 8, right: 8,
                  width: 8, height: 8, borderRadius: 999, background: 'var(--red)',
                }}/>
              )}
              <div style={{ fontSize: 12, fontWeight: 600, color: b.onStrike ? 'var(--ink)' : 'var(--ink-2)', minHeight: 16,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {b.name}{b.onStrike && <span style={{ fontSize: 9, color: 'var(--red)', marginLeft: 4, fontWeight: 700, letterSpacing: '0.05em' }}>•STRIKE</span>}
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                <span className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700 }}>{b.runs}</span>
                <span style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>({b.balls})</span>
                <span style={{ marginLeft: 'auto', fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>
                  {b.fours}×4 {b.sixes}×6
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Bowler */}
        <div style={{
          padding: '10px 12px', borderRadius: 12,
          background: 'var(--paper-2)', border: '1px solid var(--hairline)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: 'oklch(0.36 0.10 148)', color: 'white',
            fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11, letterSpacing: '-0.02em',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{s.bowler.id}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>{s.bowler.name}</div>
            <div style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>
              {s.bowler.overs}.{s.bowler.ballsThisOver} ov · {s.bowler.runs}r · {s.bowler.wickets}w
            </div>
          </div>
          {/* This over balls */}
          <div style={{ display: 'flex', gap: 4 }}>
            {[0,1,2,3,4,5].map(i => {
              const ball = overBalls[i];
              if (!ball) return (
                <div key={i} style={{
                  width: 22, height: 22, borderRadius: 999,
                  border: '1.5px dashed var(--line)',
                }}/>
              );
              return (
                <div key={i} className={`ck-ball ${ball.kind}`} style={{
                  width: 22, height: 22, fontSize: 11,
                }}>{ball.label}</div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Last action banner / undo */}
      <div style={{
        margin: '10px 12px 6px', padding: '10px 12px',
        background: undoFlash ? 'var(--cream)' : 'var(--paper-2)',
        borderRadius: 12, border: '1px solid var(--hairline)',
        display: 'flex', alignItems: 'center', gap: 10,
        transition: 'background .3s',
      }}>
        {s.log[0] ? (
          <div className={`ck-ball ${s.log[0].kind}`} style={{ width: 28, height: 28 }}>{s.log[0].label}</div>
        ) : (
          <div style={{ width: 28, height: 28 }}/>
        )}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 10, color: 'var(--muted)', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
            Last ball · {s.log[0]?.over || '—'}
          </div>
          <div style={{ fontSize: 12, fontWeight: 500, color: 'var(--ink-2)',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {s.log[0]?.desc || 'No balls yet'}
          </div>
        </div>
        <button onClick={undo} disabled={s.log.length === 0} style={{
          background: 'transparent', border: '1px solid var(--line)',
          padding: '6px 10px', borderRadius: 8, cursor: 'pointer',
          fontSize: 12, fontWeight: 600, color: 'var(--ink-2)',
          display: 'flex', alignItems: 'center', gap: 5,
          opacity: s.log.length === 0 ? 0.4 : 1,
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24"><path d="M9 14l-4-4 4-4M5 10h9a5 5 0 010 10h-3" stroke="oklch(0.30 0.02 80)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          Undo
        </button>
      </div>

      {/* Extras drawer */}
      {extraOpen && (
        <div style={{
          margin: '0 12px 8px', padding: '10px 12px',
          background: 'var(--ink)', borderRadius: 12,
          display: 'flex', alignItems: 'center', gap: 8, color: 'white',
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', marginRight: 4 }}>
            {extraOpen === 'wd' ? 'Wide' : extraOpen === 'nb' ? 'No-ball' : extraOpen === 'b' ? 'Bye' : 'Leg-bye'} +
          </div>
          {[1,2,3,4,5].map(r => (
            <button key={r} onClick={() => tapExtra(extraOpen, r)} style={{
              flex: 1, height: 36, borderRadius: 8,
              background: 'rgba(255,255,255,0.1)', color: 'white',
              border: 'none', cursor: 'pointer',
              fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16,
            }}>{r}</button>
          ))}
        </div>
      )}

      {/* Wicket drawer */}
      {wktOpen && (
        <div style={{
          margin: '0 12px 8px', padding: '12px',
          background: 'var(--red)', borderRadius: 12,
          color: 'white',
        }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 8 }}>
            Wicket — how out?
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6 }}>
            {['Bowled','Caught','LBW','Run out','Stumped','Hit wkt'].map(t => (
              <button key={t} onClick={() => tapWicket(t)} style={{
                padding: '10px 0', borderRadius: 8,
                background: 'rgba(255,255,255,0.15)', color: 'white',
                border: 'none', cursor: 'pointer',
                fontFamily: 'Inter', fontWeight: 600, fontSize: 12,
              }}>{t}</button>
            ))}
          </div>
        </div>
      )}

      {/* Run pad — main scoring area */}
      <div style={{ padding: '0 12px 6px' }}>
        <div style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
          <RunBtn r={0} />
          <RunBtn r={1} />
          <RunBtn r={2} />
          <RunBtn r={3} />
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <RunBtn r={4} big />
          <RunBtn r={6} big />
          <button onClick={() => { setWktOpen(w => !w); setExtraOpen(null); }} style={{
            flex: 1, height: 56,
            borderRadius: 14, border: 'none', cursor: 'pointer',
            background: wktOpen ? 'var(--red)' : 'var(--red-soft)',
            color: wktOpen ? 'white' : 'var(--red)',
            fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 22,
          }}>W</button>
        </div>
      </div>

      {/* Extras row */}
      <div style={{ padding: '0 12px 10px', display: 'flex', gap: 6 }}>
        <ExtraBtn k="wd" label="Wide" />
        <ExtraBtn k="nb" label="No-ball" />
        <ExtraBtn k="b"  label="Bye" />
        <ExtraBtn k="lb" label="Leg-bye" />
      </div>

      {/* Bottom: ball log */}
      <div style={{
        flex: 1, overflow: 'auto', padding: '0 12px 24px',
        borderTop: '1px solid var(--hairline)', marginTop: 4,
      }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '10px 0 8px' }}>
          <div className="ck-section-h">Ball log</div>
          <span style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono' }}>{s.log.length} balls</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {s.log.slice(0, 8).map((b, i) => (
            <div key={b.id} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 10px', borderRadius: 10,
              background: i === 0 ? 'var(--cream)' : 'transparent',
              border: i === 0 ? '1px solid transparent' : '1px solid transparent',
              transition: 'background .3s',
            }}>
              <span style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', width: 36 }}>{b.over}</span>
              <div className={`ck-ball ${b.kind}`} style={{ width: 22, height: 22, fontSize: 11 }}>{b.label}</div>
              <span style={{ fontSize: 12, color: 'var(--ink-2)', flex: 1, minWidth: 0,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.desc}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

window.CkScoring = CkScoring;

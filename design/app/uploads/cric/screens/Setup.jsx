// Setup.jsx — Match setup, 3 INTERACTIVE variants

function SetupHeader({ title, sub }) {
  return (
    <div style={{ padding: '14px 20px 14px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>Match setup · QF1</div>
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 12, color: 'var(--muted)' }}>Help</div>
      </div>
      <div style={{ marginTop: 16 }}>
        <h1 className="ck-display" style={{ fontSize: 28, fontWeight: 700, margin: 0, lineHeight: 1.1, letterSpacing: '-0.025em' }}>{title}</h1>
        {sub && <p style={{ margin: '6px 0 0', fontSize: 14, color: 'var(--muted)', lineHeight: 1.4 }}>{sub}</p>}
      </div>
    </div>
  );
}

// =========================================================================
// Variant A — Animated toss + decision
// =========================================================================

function SetupA() {
  // 0=initial, 1=flipping, 2=result
  const [phase, setPhase] = React.useState(0);
  const [winner, setWinner] = React.useState(null); // 'Lions' | 'Eagles'
  const [face, setFace] = React.useState('?');
  const [decision, setDecision] = React.useState(null); // 'bat' | 'bowl'
  const [strikerLeft, setStrikerLeft] = React.useState(true);

  const flip = () => {
    setPhase(1); setDecision(null);
    let i = 0;
    const tick = setInterval(() => {
      setFace(i % 2 === 0 ? 'H' : 'T');
      i++;
    }, 90);
    setTimeout(() => {
      clearInterval(tick);
      const w = Math.random() > 0.5 ? 'Lions' : 'Eagles';
      const f = Math.random() > 0.5 ? 'HEADS' : 'TAILS';
      setWinner(w);
      setFace(f === 'HEADS' ? 'H' : 'T');
      setPhase(2);
    }, 1400);
  };

  React.useEffect(() => { flip(); }, []);

  const batters = [
    { id: 'BK', name: 'Bilal Khan', role: 'cpt · RHB' },
    { id: 'SK', name: 'Sahil Kapoor', role: 'LHB · opener' },
  ];

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <SetupHeader title="Toss" sub="Lahore Lions vs City Eagles · 7:00 PM, Model Town" />

      <div style={{ flex: 1, overflow: 'auto', padding: '4px 20px 16px' }}>
        <div onClick={() => phase !== 1 && flip()} style={{
          margin: '20px auto 12px', width: 220, height: 220,
          borderRadius: 999, background: 'var(--ink)',
          color: 'var(--paper)', position: 'relative',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 18px 40px rgba(40,30,15,0.18), inset 0 -4px 0 oklch(0.10 0.02 80)',
          cursor: 'pointer',
          transform: phase === 1 ? 'rotateY(720deg)' : 'rotateY(0)',
          transition: 'transform 1.4s cubic-bezier(.2,.8,.2,1)',
        }}>
          <div style={{ position: 'absolute', inset: 12, borderRadius: 999, border: '1.5px dashed oklch(0.30 0.02 80)' }} />
          <div style={{ textAlign: 'center' }}>
            {phase === 2 ? (
              <>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.12em' }}>WINNER</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 38, fontWeight: 700, lineHeight: 1, marginTop: 4, letterSpacing: '-0.025em' }}>{winner}</div>
                <div style={{ fontSize: 11, color: 'oklch(0.72 0.01 80)', marginTop: 6 }}>{decision ? `chose to ${decision}` : 'choose below'}</div>
              </>
            ) : (
              <>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 56, fontWeight: 700 }}>{face}</div>
                <div style={{ fontSize: 11, color: 'oklch(0.72 0.01 80)', marginTop: 6 }}>{phase === 1 ? 'flipping…' : 'tap to flip'}</div>
              </>
            )}
          </div>
        </div>

        {phase === 2 && !decision && (
          <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
            <button onClick={() => setDecision('bat')} style={{ flex: 1, padding: '12px 0', borderRadius: 12, border: '1.5px solid var(--ink)', background: 'var(--paper)', fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>{winner} bat first</button>
            <button onClick={() => setDecision('bowl')} style={{ flex: 1, padding: '12px 0', borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>{winner} bowl first</button>
          </div>
        )}

        {decision && (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 10, alignItems: 'center', marginTop: 18 }}>
              <div style={{ padding: 12, borderRadius: 12, border: decision === 'bat' && winner === 'Lions' || decision === 'bowl' && winner === 'Eagles' ? '1.5px solid var(--ink)' : '1px solid var(--hairline)', background: 'var(--paper-2)' }}>
                <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--ink-2)', letterSpacing: '0.06em' }}>BATTING</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, marginTop: 4 }}>{decision === 'bat' ? winner : (winner === 'Lions' ? 'Eagles' : 'Lions')}</div>
              </div>
              <div style={{ fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>vs</div>
              <div style={{ padding: 12, borderRadius: 12, border: '1px solid var(--hairline)' }}>
                <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.06em' }}>BOWLING</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, marginTop: 4 }}>{decision === 'bowl' ? winner : (winner === 'Lions' ? 'Eagles' : 'Lions')}</div>
              </div>
            </div>

            <div style={{ marginTop: 22 }}>
              <div className="ck-section-h" style={{ marginBottom: 10 }}>Opening pair · tap to set strike</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {batters.map((p, i) => {
                  const onStrike = strikerLeft ? i === 0 : i === 1;
                  return (
                    <button key={i} onClick={() => setStrikerLeft(i === 0)} style={{
                      padding: 12, borderRadius: 12, border: '1.5px solid ' + (onStrike ? 'var(--ink)' : 'var(--hairline)'),
                      display: 'flex', alignItems: 'center', gap: 12,
                      background: onStrike ? 'var(--paper-2)' : 'var(--paper)',
                      cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                    }}>
                      <div className="ck-avatar" style={{ width: 38, height: 38 }}>{p.id}</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontWeight: 600, fontSize: 15 }}>{p.name}</div>
                        <div style={{ fontSize: 11, color: 'var(--muted)' }}>{p.role}</div>
                      </div>
                      {onStrike && <span style={{ fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.08em', color: 'var(--red)', border: '1px solid var(--red-soft)', padding: '4px 7px', borderRadius: 999 }}>ON STRIKE</span>}
                    </button>
                  );
                })}
              </div>
            </div>
          </>
        )}
      </div>
      <div style={{ padding: '12px 20px 22px', borderTop: '1px solid var(--hairline)' }}>
        <button className="ck-btn" disabled={!decision} style={{ width: '100%', opacity: decision ? 1 : 0.4 }}>Start match · 1st ball</button>
      </div>
    </div>
  );
}

// =========================================================================
// Variant B — XI selection with swap
// =========================================================================

function SetupB() {
  const initialXI = [
    { n: 'Bilal Khan', r: 'cpt · RHB', t: 'BAT' },
    { n: 'Sahil Kapoor', r: 'LHB · opener', t: 'BAT' },
    { n: 'Rashid Ali', r: 'RHB · finisher', t: 'BAT' },
    { n: 'Anand Verma', r: 'wk · RHB', t: 'WK' },
    { n: 'Yusuf Iqbal', r: 'all-rounder', t: 'AR' },
    { n: 'Tariq Hashmi', r: 'all-rounder', t: 'AR' },
    { n: 'Hassan Iqbal', r: 'RAM · death', t: 'BWL' },
    { n: 'Faisal Munir', r: 'RAS · spin', t: 'BWL' },
    { n: 'Karan Mehta', r: 'LAM · pace', t: 'BWL' },
    { n: 'Vivek Sharma', r: 'RAL · spin', t: 'BWL' },
    { n: 'Naveen Patel', r: 'RAM · new ball', t: 'BWL' },
  ];
  const initialBench = [
    { n: 'Saad Mir', r: 'RHB · sub', t: 'BAT' },
    { n: 'Junaid Khan', r: 'wk · sub', t: 'WK' },
    { n: 'Aman Singh', r: 'LAM · sub', t: 'BWL' },
    { n: 'Rohit Bansal', r: 'AR · sub', t: 'AR' },
  ];

  const [xi, setXi] = React.useState(initialXI);
  const [bench, setBench] = React.useState(initialBench);
  const [pickXi, setPickXi] = React.useState(null);

  const swap = (benchIdx) => {
    if (pickXi == null) return;
    setXi(prev => prev.map((p, i) => i === pickXi ? bench[benchIdx] : p));
    setBench(prev => prev.map((p, i) => i === benchIdx ? xi[pickXi] : p));
    setPickXi(null);
  };

  const tagBg = (t) => t === 'BAT' ? 'var(--paper-2)' : t === 'WK' ? 'oklch(0.94 0.05 90)' : t === 'BWL' ? 'var(--red-soft)' : 'var(--green-soft)';
  const tagFg = (t) => t === 'BAT' ? 'var(--ink)' : t === 'WK' ? 'var(--ink-2)' : t === 'BWL' ? 'var(--red)' : 'oklch(0.36 0.10 148)';

  const counts = xi.reduce((a, p) => ({ ...a, [p.t]: (a[p.t] || 0) + 1 }), {});

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <SetupHeader title="Pick your 11" sub={pickXi == null ? 'Tap a player to swap with bench.' : `Now tap a bench player to swap in for ${xi[pickXi].n}.`} />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 20px 16px' }}>
        <div style={{ padding: 12, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)', marginBottom: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div className="ck-section-h">Balance</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--ink-2)' }}>{counts.BAT||0} BAT · {counts.WK||0} WK · {counts.AR||0} AR · {counts.BWL||0} BWL</div>
          </div>
          <div style={{ display: 'flex', height: 8, borderRadius: 4, marginTop: 8, overflow: 'hidden' }}>
            <div style={{ width: `${(counts.BAT||0)/11*100}%`, background: 'var(--ink)' }} />
            <div style={{ width: `${(counts.WK||0)/11*100}%`, background: 'oklch(0.78 0.14 80)' }} />
            <div style={{ width: `${(counts.AR||0)/11*100}%`, background: 'var(--green)' }} />
            <div style={{ width: `${(counts.BWL||0)/11*100}%`, background: 'var(--red)' }} />
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
          <div className="ck-section-h">Playing 11</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>11 / 11</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {xi.map((p, i) => (
            <button key={i} onClick={() => setPickXi(pickXi === i ? null : i)} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: '8px 10px', borderRadius: 8,
              background: pickXi === i ? 'var(--ink)' : 'var(--paper)', color: pickXi === i ? 'var(--paper)' : 'var(--ink)',
              border: '1px solid ' + (pickXi === i ? 'var(--ink)' : 'var(--hairline)'),
              cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: pickXi === i ? 'oklch(0.72 0.01 80)' : 'var(--muted)', width: 16 }}>{i + 1}</div>
              <div style={{ padding: '2px 6px', borderRadius: 4, fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.05em', background: tagBg(p.t), color: tagFg(p.t) }}>{p.t}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{p.n}</div>
                <div style={{ fontSize: 10, color: pickXi === i ? 'oklch(0.72 0.01 80)' : 'var(--muted)' }}>{p.r}</div>
              </div>
            </button>
          ))}
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 16, marginBottom: 8 }}>
          <div className="ck-section-h">Bench</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{pickXi != null ? 'tap to swap in' : 'pick from XI first'}</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {bench.map((p, i) => (
            <button key={i} onClick={() => swap(i)} disabled={pickXi == null} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: '8px 10px', borderRadius: 8,
              border: '1px solid var(--hairline)', background: 'var(--paper)',
              opacity: pickXi == null ? 0.5 : 1,
              cursor: pickXi == null ? 'default' : 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ padding: '2px 6px', borderRadius: 4, fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.05em', background: tagBg(p.t), color: tagFg(p.t) }}>{p.t}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{p.n}</div>
                <div style={{ fontSize: 10, color: 'var(--muted)' }}>{p.r}</div>
              </div>
              <span style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: pickXi != null ? 'var(--ink)' : 'var(--muted)', fontWeight: 700, padding: '4px 8px', borderRadius: 999, border: '1px solid var(--hairline)' }}>SWAP</span>
            </button>
          ))}
        </div>
      </div>
      <div style={{ padding: '12px 20px 22px', borderTop: '1px solid var(--hairline)' }}>
        <button className="ck-btn" style={{ width: '100%' }}>Confirm 11 → Toss</button>
      </div>
    </div>
  );
}

// =========================================================================
// Variant C — Match conditions, editable
// =========================================================================

function SetupC() {
  const [overs, setOvers] = React.useState(20);
  const [pp, setPp] = React.useState(6);
  const [bowlerMax, setBowlerMax] = React.useState(4);
  const [pitch, setPitch] = React.useState('Dry');

  const Stepper = ({ value, set, min, max, label, suffix }) => (
    <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)' }}>
      <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 2 }}>
        <button onClick={() => set(Math.max(min, value - 1))} style={{ width: 22, height: 22, borderRadius: 999, background: 'var(--paper-2)', border: 'none', fontSize: 13, cursor: 'pointer', color: 'var(--ink-2)' }}>−</button>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em' }}>{value}{suffix && <span style={{ fontSize: 13, color: 'var(--muted)', marginLeft: 4 }}>{suffix}</span>}</div>
        <button onClick={() => set(Math.min(max, value + 1))} style={{ width: 22, height: 22, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontSize: 13, cursor: 'pointer', marginLeft: 'auto' }}>+</button>
      </div>
    </div>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <SetupHeader title="Conditions" sub="Set the stage before first ball" />
      <div style={{ flex: 1, overflow: 'auto', padding: '8px 20px 16px' }}>
        <div style={{ padding: 16, borderRadius: 16, background: 'oklch(0.96 0.02 148)', border: '1px solid oklch(0.86 0.04 148)', position: 'relative', overflow: 'hidden' }}>
          <svg width="160" height="160" viewBox="0 0 100 100" style={{ position: 'absolute', right: -20, bottom: -20, opacity: 0.18 }}>
            <ellipse cx="50" cy="50" rx="46" ry="30" stroke="oklch(0.36 0.10 148)" fill="none" strokeWidth="0.6"/>
            <ellipse cx="50" cy="50" rx="26" ry="16" stroke="oklch(0.36 0.10 148)" fill="none" strokeWidth="0.6"/>
          </svg>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.36 0.10 148)', letterSpacing: '0.1em' }}>VENUE</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, marginTop: 4, letterSpacing: '-0.02em' }}>Model Town pitch · Ground 2</div>
          <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 4 }}>boundary 60m · grass · floodlit</div>

          <div style={{ display: 'flex', gap: 6, marginTop: 12, flexWrap: 'wrap' }}>
            {['Dry', 'Damp', 'Worn', 'Green'].map(p => (
              <button key={p} onClick={() => setPitch(p)} style={{
                padding: '6px 10px', borderRadius: 999, fontFamily: 'inherit',
                background: pitch === p ? 'oklch(0.36 0.10 148)' : 'var(--paper)',
                color: pitch === p ? 'var(--paper)' : 'var(--ink-2)',
                border: '1px solid oklch(0.86 0.04 148)',
                fontSize: 11, fontWeight: 600, cursor: 'pointer',
              }}>{p}</button>
            ))}
          </div>
        </div>

        <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 10 }}>Match · tap +/− to edit</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <Stepper label="OVERS" value={overs} set={setOvers} min={5} max={50} />
          <Stepper label="POWERPLAY" value={pp} set={setPp} min={1} max={overs} suffix="ov" />
          <Stepper label="BOWLER MAX" value={bowlerMax} set={setBowlerMax} min={1} max={overs} suffix="ov" />
          <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)' }}>
            <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>BALL</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.025em', marginTop: 2 }}>White Kook.</div>
          </div>
        </div>
      </div>
      <div style={{ padding: '12px 20px 22px', borderTop: '1px solid var(--hairline)' }}>
        <button className="ck-btn" style={{ width: '100%' }}>Confirm conditions → Toss</button>
      </div>
    </div>
  );
}

window.CkSetupA = SetupA;
window.CkSetupB = SetupB;
window.CkSetupC = SetupC;

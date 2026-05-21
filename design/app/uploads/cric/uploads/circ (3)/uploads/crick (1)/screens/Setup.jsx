// Setup.jsx — Match setup
// SetupA = FULL multi-step interactive flow (canonical, shown in canvas)
// SetupB = XI selection alt view
// SetupC = Conditions alt view

function SetupHeader({ title, sub, step, totalSteps, onBack }) {
  return (
    <div style={{ padding: '14px 20px 14px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={onBack} disabled={!onBack} style={{
          background: 'transparent', border: 'none', padding: 0,
          cursor: onBack ? 'pointer' : 'default', opacity: onBack ? 1 : 0.25,
        }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
          Match setup{typeof step === 'number' ? ` · step ${step}/${totalSteps}` : ' · QF1'}
        </div>
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 12, color: 'var(--muted)' }}>Help</div>
      </div>
      <div style={{ marginTop: 16 }}>
        <h1 className="ck-display" style={{ fontSize: 28, fontWeight: 700, margin: 0, lineHeight: 1.1, letterSpacing: '-0.025em' }}>{title}</h1>
        {sub && <p style={{ margin: '6px 0 0', fontSize: 14, color: 'var(--muted)', lineHeight: 1.4 }}>{sub}</p>}
      </div>
      {typeof step === 'number' && (
        <div style={{ display: 'flex', gap: 4, marginTop: 14 }}>
          {Array.from({ length: totalSteps }).map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: i < step ? 'var(--ink)' : 'var(--hairline)',
              transition: 'background .2s',
            }} />
          ))}
        </div>
      )}
    </div>
  );
}

// =========================================================================
// FULL multi-step Match Setup flow
// =========================================================================

function SetupA() {
  const TOTAL = 6;
  const [step, setStep] = React.useState(1);
  const [started, setStarted] = React.useState(false);

  // ─ Step 1 · Toss
  const [tossPhase, setTossPhase] = React.useState(0); // 0 ready, 1 flipping, 2 result
  const [tossCall, setTossCall] = React.useState(null); // 'H' | 'T' (Lions called)
  const [face, setFace] = React.useState('?');
  const [tossWinner, setTossWinner] = React.useState(null);
  const [decision, setDecision] = React.useState(null); // 'bat' | 'bowl'

  const flip = (call) => {
    setTossCall(call); setTossPhase(1);
    let i = 0;
    const tick = setInterval(() => { setFace(i % 2 === 0 ? 'H' : 'T'); i++; }, 90);
    setTimeout(() => {
      clearInterval(tick);
      const result = Math.random() > 0.5 ? 'H' : 'T';
      setFace(result);
      setTossWinner(result === call ? 'Lions' : 'Eagles');
      setTossPhase(2);
    }, 1400);
  };

  // ─ Step 2 · Squads / XI
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

  // ─ Step 3 · Opening pair + bowler
  const [striker, setStriker] = React.useState(0);
  const [nonStriker, setNonStriker] = React.useState(1);
  const [openingBowler, setOpeningBowler] = React.useState(null);
  const [pairPicker, setPairPicker] = React.useState(null); // 'striker' | 'non' | null

  // who is batting depends on toss outcome — both flows ok in mock
  const battingTeam = decision === 'bat' ? tossWinner : (tossWinner === 'Lions' ? 'Eagles' : 'Lions');
  const bowlingTeam = battingTeam === 'Lions' ? 'Eagles' : 'Lions';

  // for the mock, we always show Lions XI as candidates regardless
  const eaglesBowlers = [
    { n: 'Mohit Yadav', r: 'RAM · new ball' },
    { n: 'Imran Tariq', r: 'LAM · pace' },
    { n: 'Sanjay R.', r: 'RAS · spin' },
    { n: 'Wasim A.', r: 'RAM · death' },
  ];

  // ─ Step 4 · Conditions
  const [overs, setOvers] = React.useState(20);
  const [pp, setPp] = React.useState(6);
  const [bowlerMax, setBowlerMax] = React.useState(4);
  const [pitch, setPitch] = React.useState('Dry');
  const [ball, setBall] = React.useState('White Kook.');
  const [weather, setWeather] = React.useState('Clear');

  // ─ Step 5 · Playing rules
  const [drs, setDrs] = React.useState(false);
  const [superOver, setSuperOver] = React.useState(true);
  const [wideRule, setWideRule] = React.useState('Strict');
  const [noBall, setNoBall] = React.useState('Free hit');
  const [boundary, setBoundary] = React.useState(60);
  const [allowSubs, setAllowSubs] = React.useState(true);

  // ─ Step 6 · Officials + start
  const [scorer, setScorer] = React.useState('You');
  const [umpire1, setUmpire1] = React.useState('Imtiaz S.');
  const [umpire2, setUmpire2] = React.useState('—');
  const [streamFeed, setStreamFeed] = React.useState(true);

  // ── Step gates
  const canAdvance = {
    1: tossPhase === 2 && decision != null,
    2: xi.length === 11 && (counts.WK || 0) >= 1,
    3: striker !== nonStriker && openingBowler != null,
    4: overs >= 1 && pp >= 1 && bowlerMax >= 1,
    5: true,
    6: scorer && umpire1,
  };

  const Stepper = ({ value, set, min, max, label, suffix }) => (
    <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)' }}>
      <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
        <button onClick={() => set(Math.max(min, value - 1))} style={{ width: 24, height: 24, borderRadius: 999, background: 'var(--paper-2)', border: 'none', fontSize: 14, cursor: 'pointer', color: 'var(--ink-2)' }}>−</button>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em', flex: 1, textAlign: 'center' }}>
          {value}{suffix && <span style={{ fontSize: 12, color: 'var(--muted)', marginLeft: 4, fontWeight: 500 }}>{suffix}</span>}
        </div>
        <button onClick={() => set(Math.min(max, value + 1))} style={{ width: 24, height: 24, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontSize: 14, cursor: 'pointer' }}>+</button>
      </div>
    </div>
  );

  const Toggle = ({ on, onClick }) => (
    <button onClick={onClick} style={{
      width: 42, height: 26, borderRadius: 999,
      background: on ? 'var(--ink)' : 'oklch(0.86 0.01 80)',
      border: 'none', position: 'relative', cursor: 'pointer', flexShrink: 0,
      transition: 'background .15s',
    }}>
      <div style={{
        position: 'absolute', top: 3, left: on ? 19 : 3,
        width: 20, height: 20, borderRadius: 999, background: 'white',
        transition: 'left .15s', boxShadow: '0 1px 2px rgba(0,0,0,0.15)',
      }} />
    </button>
  );

  const ChipRow = ({ value, set, options }) => (
    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
      {options.map(o => (
        <button key={o} onClick={() => set(o)} style={{
          padding: '6px 12px', borderRadius: 999, fontFamily: 'inherit',
          background: value === o ? 'var(--ink)' : 'var(--paper)',
          color: value === o ? 'var(--paper)' : 'var(--ink-2)',
          border: '1px solid ' + (value === o ? 'var(--ink)' : 'var(--hairline)'),
          fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>{o}</button>
      ))}
    </div>
  );

  // ── Started screen
  if (started) {
    return (
      <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--ink)', color: 'var(--paper)' }}>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px', textAlign: 'center' }}>
          <div style={{ position: 'relative', width: 120, height: 120, marginBottom: 28 }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'var(--red)', animation: 'ck-pulse 1.4s infinite' }} />
            <div style={{ position: 'absolute', inset: 12, borderRadius: 999, border: '1.5px dashed oklch(0.85 0.02 80)' }} />
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: 700, color: 'white', letterSpacing: '0.1em' }}>LIVE</div>
          </div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.14em' }}>BALL 0.0 · OVER 1</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 30, fontWeight: 700, letterSpacing: '-0.025em', marginTop: 10, lineHeight: 1.1 }}>{battingTeam} batting</div>
          <div style={{ fontSize: 14, color: 'oklch(0.72 0.01 80)', marginTop: 10, maxWidth: 280, lineHeight: 1.5 }}>
            Match created. Scorer: <strong style={{ color: 'var(--paper)' }}>{scorer}</strong>. Handing off to live scoring.
          </div>
          <div style={{ marginTop: 24, padding: '10px 14px', borderRadius: 10, border: '1px solid oklch(0.30 0.02 80)', fontFamily: 'JetBrains Mono', fontSize: 11, color: 'oklch(0.72 0.01 80)', letterSpacing: '0.05em' }}>
            {overs} ov · {pp} ov PP · max {bowlerMax}/bowler · {pitch.toLowerCase()} pitch
          </div>
        </div>
        <div style={{ padding: '0 24px 28px' }}>
          <button onClick={() => { setStarted(false); setStep(1); setTossPhase(0); setDecision(null); setOpeningBowler(null); }} style={{
            width: '100%', padding: '15px 0', borderRadius: 14, background: 'oklch(0.78 0.14 80)', color: 'var(--ink)',
            border: 'none', fontFamily: 'inherit', fontSize: 16, fontWeight: 700, cursor: 'pointer',
          }}>Open scorer →</button>
          <button onClick={() => { setStarted(false); setStep(1); setTossPhase(0); setDecision(null); setOpeningBowler(null); }} style={{ width: '100%', marginTop: 8, padding: '12px 0', background: 'transparent', color: 'oklch(0.72 0.01 80)', border: 'none', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Restart setup</button>
        </div>
      </div>
    );
  }

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <SetupHeader
        title={
          step === 1 ? 'Toss' :
          step === 2 ? 'Pick your 11' :
          step === 3 ? 'Opening pair' :
          step === 4 ? 'Conditions' :
          step === 5 ? 'Playing rules' :
          'Officials & start'
        }
        sub={
          step === 1 ? 'Lahore Lions vs City Eagles · 7:00 PM, Model Town' :
          step === 2 ? (pickXi == null ? 'Tap a player to swap with bench. Need ≥1 wicketkeeper.' : `Now tap a bench player to swap in for ${xi[pickXi].n}.`) :
          step === 3 ? `${battingTeam} open the innings. ${bowlingTeam} bowl first.` :
          step === 4 ? 'Set the stage before first ball.' :
          step === 5 ? 'How will the game be played?' :
          'Confirm officials and start the match.'
        }
        step={step}
        totalSteps={TOTAL}
        onBack={step > 1 ? () => setStep(step - 1) : null}
      />

      <div style={{ flex: 1, overflow: 'auto', padding: '4px 20px 16px' }}>

        {/* ──────── STEP 1 · TOSS ──────── */}
        {step === 1 && (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 8, alignItems: 'center', marginTop: 8, marginBottom: 16 }}>
              <div style={{ padding: 12, borderRadius: 12, background: 'var(--paper-2)', textAlign: 'center' }}>
                <div className="ck-avatar" style={{ width: 36, height: 36, margin: '0 auto', background: 'oklch(0.62 0.19 28)', color: 'white', borderColor: 'transparent' }}>LL</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, marginTop: 6 }}>Lahore Lions</div>
                <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', marginTop: 2 }}>HOST · 14W · 2L</div>
              </div>
              <div style={{ fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>vs</div>
              <div style={{ padding: 12, borderRadius: 12, background: 'var(--paper-2)', textAlign: 'center' }}>
                <div className="ck-avatar" style={{ width: 36, height: 36, margin: '0 auto', background: 'oklch(0.55 0.08 240)', color: 'white', borderColor: 'transparent' }}>CE</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, marginTop: 6 }}>City Eagles</div>
                <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', marginTop: 2 }}>VISITOR · 11W · 5L</div>
              </div>
            </div>

            <div style={{
              margin: '8px auto 12px', width: 200, height: 200,
              borderRadius: 999, background: 'var(--ink)',
              color: 'var(--paper)', position: 'relative',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 18px 40px rgba(40,30,15,0.18), inset 0 -4px 0 oklch(0.10 0.02 80)',
              transform: tossPhase === 1 ? 'rotateY(720deg)' : 'rotateY(0)',
              transition: 'transform 1.4s cubic-bezier(.2,.8,.2,1)',
            }}>
              <div style={{ position: 'absolute', inset: 12, borderRadius: 999, border: '1.5px dashed oklch(0.30 0.02 80)' }} />
              <div style={{ textAlign: 'center' }}>
                {tossPhase === 2 ? (
                  <>
                    <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.12em' }}>WINNER</div>
                    <div style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 700, lineHeight: 1, marginTop: 4, letterSpacing: '-0.025em' }}>{tossWinner}</div>
                    <div style={{ fontSize: 11, color: 'oklch(0.72 0.01 80)', marginTop: 6 }}>landed on {face === 'H' ? 'Heads' : 'Tails'}</div>
                  </>
                ) : (
                  <>
                    <div style={{ fontFamily: 'Inter Tight', fontSize: 56, fontWeight: 700 }}>{face}</div>
                    <div style={{ fontSize: 11, color: 'oklch(0.72 0.01 80)', marginTop: 6 }}>{tossPhase === 1 ? 'flipping…' : 'Lions to call'}</div>
                  </>
                )}
              </div>
            </div>

            {tossPhase === 0 && (
              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={() => flip('H')} style={{ flex: 1, padding: '14px 0', borderRadius: 12, border: '1.5px solid var(--ink)', background: 'var(--paper)', fontFamily: 'inherit', fontSize: 15, fontWeight: 700, cursor: 'pointer' }}>Heads</button>
                <button onClick={() => flip('T')} style={{ flex: 1, padding: '14px 0', borderRadius: 12, border: '1.5px solid var(--ink)', background: 'var(--paper)', fontFamily: 'inherit', fontSize: 15, fontWeight: 700, cursor: 'pointer' }}>Tails</button>
              </div>
            )}

            {tossPhase === 2 && (
              <>
                <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>{tossWinner} chooses to</div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button onClick={() => setDecision('bat')} style={{
                    flex: 1, padding: '14px 0', borderRadius: 12,
                    border: decision === 'bat' ? '2px solid var(--ink)' : '1px solid var(--hairline)',
                    background: decision === 'bat' ? 'var(--paper-2)' : 'var(--paper)',
                    fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer',
                  }}>Bat first</button>
                  <button onClick={() => setDecision('bowl')} style={{
                    flex: 1, padding: '14px 0', borderRadius: 12,
                    border: decision === 'bowl' ? '2px solid var(--ink)' : '1px solid var(--hairline)',
                    background: decision === 'bowl' ? 'var(--paper-2)' : 'var(--paper)',
                    fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer',
                  }}>Bowl first</button>
                </div>
                {decision && (
                  <div style={{ marginTop: 14, padding: 12, borderRadius: 10, background: 'var(--paper-2)', display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>1ST INNINGS</div>
                    <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, flex: 1, textAlign: 'right' }}>{battingTeam} bat</div>
                  </div>
                )}
              </>
            )}
          </>
        )}

        {/* ──────── STEP 2 · XI ──────── */}
        {step === 2 && (
          <>
            <div style={{ padding: 12, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)', marginBottom: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <div className="ck-section-h">Balance · Lahore Lions</div>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--ink-2)' }}>{counts.BAT||0} BAT · {counts.WK||0} WK · {counts.AR||0} AR · {counts.BWL||0} BWL</div>
              </div>
              <div style={{ display: 'flex', height: 8, borderRadius: 4, marginTop: 8, overflow: 'hidden' }}>
                <div style={{ width: `${(counts.BAT||0)/11*100}%`, background: 'var(--ink)' }} />
                <div style={{ width: `${(counts.WK||0)/11*100}%`, background: 'oklch(0.78 0.14 80)' }} />
                <div style={{ width: `${(counts.AR||0)/11*100}%`, background: 'var(--green)' }} />
                <div style={{ width: `${(counts.BWL||0)/11*100}%`, background: 'var(--red)' }} />
              </div>
              {(counts.WK || 0) < 1 && <div style={{ fontSize: 11, color: 'var(--red)', marginTop: 6, fontWeight: 600 }}>Need at least 1 wicketkeeper.</div>}
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
          </>
        )}

        {/* ──────── STEP 3 · OPENING PAIR + BOWLER ──────── */}
        {step === 3 && (
          <>
            <div className="ck-section-h" style={{ marginBottom: 8 }}>Strike</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 18 }}>
              {[
                { role: 'striker', label: 'On strike', val: striker, set: setStriker, badge: 'ON STRIKE' },
                { role: 'non', label: 'Non-striker', val: nonStriker, set: setNonStriker, badge: 'NON-STRIKER' },
              ].map(slot => {
                const p = xi[slot.val];
                return (
                  <button key={slot.role} onClick={() => setPairPicker(slot.role)} style={{
                    padding: 12, borderRadius: 12, border: '1px solid var(--hairline)',
                    background: 'var(--paper)', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                  }}>
                    <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.08em', color: slot.role === 'striker' ? 'var(--red)' : 'var(--muted)' }}>{slot.badge}</div>
                    <div className="ck-avatar" style={{ width: 38, height: 38, marginTop: 8 }}>{p.n.split(' ').map(w => w[0]).join('')}</div>
                    <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, marginTop: 6 }}>{p.n}</div>
                    <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{p.r}</div>
                    <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--ink)', fontWeight: 600, marginTop: 8 }}>tap to change ↻</div>
                  </button>
                );
              })}
            </div>

            <button onClick={() => { const a = striker, b = nonStriker; setStriker(b); setNonStriker(a); }} style={{
              width: '100%', padding: '10px 0', borderRadius: 10,
              background: 'var(--paper-2)', border: '1px solid var(--hairline)',
              fontFamily: 'inherit', fontSize: 12, fontWeight: 600, color: 'var(--ink)',
              cursor: 'pointer', marginBottom: 18,
            }}>↔ Swap strike</button>

            <div className="ck-section-h" style={{ marginBottom: 8 }}>Opening bowler · {bowlingTeam}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {eaglesBowlers.map((b, i) => (
                <button key={i} onClick={() => setOpeningBowler(i)} style={{
                  display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 10,
                  background: openingBowler === i ? 'var(--ink)' : 'var(--paper)',
                  color: openingBowler === i ? 'var(--paper)' : 'var(--ink)',
                  border: '1px solid ' + (openingBowler === i ? 'var(--ink)' : 'var(--hairline)'),
                  cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                }}>
                  <div className="ck-avatar" style={{ width: 30, height: 30, fontSize: 11, background: openingBowler === i ? 'oklch(0.30 0.02 80)' : 'var(--paper-2)', color: openingBowler === i ? 'var(--paper)' : 'var(--ink-2)', borderColor: 'transparent' }}>{b.n.split(' ').map(w => w[0]).join('')}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{b.n}</div>
                    <div style={{ fontSize: 10, color: openingBowler === i ? 'oklch(0.72 0.01 80)' : 'var(--muted)' }}>{b.r}</div>
                  </div>
                  {openingBowler === i && <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>}
                </button>
              ))}
            </div>
          </>
        )}

        {/* Picker overlay for opening pair */}
        {step === 3 && pairPicker && (
          <div onClick={() => setPairPicker(null)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.45)', zIndex: 30, display: 'flex', alignItems: 'flex-end' }}>
            <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--paper)', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: '18px 20px 24px', maxHeight: '76%', overflow: 'auto' }}>
              <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 14px' }} />
              <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginBottom: 14 }}>Select {pairPicker === 'striker' ? 'striker' : 'non-striker'}</div>
              {xi.filter(p => p.t === 'BAT' || p.t === 'WK' || p.t === 'AR').map((p) => {
                const idx = xi.indexOf(p);
                const taken = (pairPicker === 'striker' ? nonStriker : striker) === idx;
                return (
                  <button key={idx} disabled={taken} onClick={() => { pairPicker === 'striker' ? setStriker(idx) : setNonStriker(idx); setPairPicker(null); }} style={{
                    display: 'flex', alignItems: 'center', gap: 10, width: '100%', padding: '10px 0',
                    borderBottom: '1px solid var(--hairline)', border: 'none', borderBottom: '1px solid var(--hairline)',
                    background: 'transparent', fontFamily: 'inherit', textAlign: 'left',
                    opacity: taken ? 0.4 : 1, cursor: taken ? 'default' : 'pointer',
                  }}>
                    <div className="ck-avatar" style={{ width: 32, height: 32, fontSize: 11 }}>{p.n.split(' ').map(w => w[0]).join('')}</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 14, fontWeight: 600 }}>{p.n}</div>
                      <div style={{ fontSize: 10, color: 'var(--muted)' }}>{p.r}</div>
                    </div>
                    {taken && <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>OTHER END</span>}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* ──────── STEP 4 · CONDITIONS ──────── */}
        {step === 4 && (
          <>
            <div style={{ padding: 16, borderRadius: 16, background: 'oklch(0.96 0.02 148)', border: '1px solid oklch(0.86 0.04 148)', position: 'relative', overflow: 'hidden' }}>
              <svg width="160" height="160" viewBox="0 0 100 100" style={{ position: 'absolute', right: -20, bottom: -20, opacity: 0.18 }}>
                <ellipse cx="50" cy="50" rx="46" ry="30" stroke="oklch(0.36 0.10 148)" fill="none" strokeWidth="0.6"/>
                <ellipse cx="50" cy="50" rx="26" ry="16" stroke="oklch(0.36 0.10 148)" fill="none" strokeWidth="0.6"/>
              </svg>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.36 0.10 148)', letterSpacing: '0.1em' }}>VENUE</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 700, marginTop: 4, letterSpacing: '-0.02em' }}>Model Town · Ground 2</div>
              <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 4 }}>floodlit · grass · capacity 800</div>
            </div>

            <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>Pitch</div>
            <ChipRow value={pitch} set={setPitch} options={['Dry', 'Damp', 'Worn', 'Green']} />

            <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>Weather</div>
            <ChipRow value={weather} set={setWeather} options={['Clear', 'Cloudy', 'Humid', 'Dew expected']} />

            <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>Match · tap +/− to edit</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <Stepper label="OVERS" value={overs} set={setOvers} min={5} max={50} />
              <Stepper label="POWERPLAY" value={pp} set={(v) => setPp(Math.min(v, overs))} min={1} max={overs} suffix="ov" />
              <Stepper label="BOWLER MAX" value={bowlerMax} set={setBowlerMax} min={1} max={overs} suffix="ov" />
              <Stepper label="BOUNDARY" value={boundary} set={setBoundary} min={45} max={75} suffix="m" />
            </div>

            <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>Ball</div>
            <ChipRow value={ball} set={setBall} options={['White Kook.', 'Red Kook.', 'Tape ball', 'Tennis']} />
          </>
        )}

        {/* ──────── STEP 5 · PLAYING RULES ──────── */}
        {step === 5 && (
          <>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '13px 0', borderTop: '1px solid var(--hairline)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>DRS / video reviews</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>Allow players to call for review (no replay in mock)</div>
                </div>
                <Toggle on={drs} onClick={() => setDrs(!drs)} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '13px 0', borderTop: '1px solid var(--hairline)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>Super over on tie</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>Otherwise the match is shared</div>
                </div>
                <Toggle on={superOver} onClick={() => setSuperOver(!superOver)} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '13px 0', borderTop: '1px solid var(--hairline)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>Allow substitutes</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>Bench can replace injured XI</div>
                </div>
                <Toggle on={allowSubs} onClick={() => setAllowSubs(!allowSubs)} />
              </div>
            </div>

            <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 8 }}>Wide rule</div>
            <ChipRow value={wideRule} set={setWideRule} options={['Strict', 'Standard', 'Lenient']} />

            <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>No-ball penalty</div>
            <ChipRow value={noBall} set={setNoBall} options={['Free hit', 'No free hit', '+1 only']} />

            <div style={{ marginTop: 18, padding: 12, borderRadius: 10, background: 'var(--paper-2)', fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.5 }}>
              <strong style={{ fontFamily: 'Inter Tight' }}>Heads up:</strong> tape-ball matches typically use lenient wides and no DRS. You can always change this from the scorer's settings during the match.
            </div>
          </>
        )}

        {/* ──────── STEP 6 · OFFICIALS / REVIEW ──────── */}
        {step === 6 && (
          <>
            <div className="ck-section-h" style={{ marginBottom: 8 }}>Scorer</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              {['You', 'Adeel S. (cpt)', 'Tariq H. (mgr)', 'Co-scorer (invite)'].map(s => (
                <button key={s} onClick={() => setScorer(s)} style={{
                  display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 10,
                  background: scorer === s ? 'var(--ink)' : 'var(--paper)',
                  color: scorer === s ? 'var(--paper)' : 'var(--ink)',
                  border: '1px solid ' + (scorer === s ? 'var(--ink)' : 'var(--hairline)'),
                  cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                }}>
                  <div className="ck-avatar" style={{ width: 28, height: 28, fontSize: 11, background: scorer === s ? 'oklch(0.30 0.02 80)' : 'var(--paper-2)', color: scorer === s ? 'var(--paper)' : 'var(--ink-2)', borderColor: 'transparent' }}>
                    {s === 'You' ? 'BK' : s.split(' ').map(w => w[0]).slice(0,2).join('')}
                  </div>
                  <div style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>{s}</div>
                  {scorer === s && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>}
                </button>
              ))}
            </div>

            <div className="ck-section-h" style={{ marginTop: 16, marginBottom: 8 }}>Umpires</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)' }}>
                <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>STANDING #1</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, marginTop: 4 }}>{umpire1}</div>
                <button onClick={() => setUmpire1(umpire1 === 'Imtiaz S.' ? 'Wasim H.' : 'Imtiaz S.')} style={{ marginTop: 8, padding: '5px 10px', borderRadius: 8, background: 'var(--paper-2)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>Change</button>
              </div>
              <div style={{ padding: 12, borderRadius: 10, border: '1px dashed var(--hairline)' }}>
                <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>STANDING #2</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, marginTop: 4, color: umpire2 === '—' ? 'var(--muted)' : 'var(--ink)' }}>{umpire2}</div>
                <button onClick={() => setUmpire2(umpire2 === '—' ? 'Junaid R.' : '—')} style={{ marginTop: 8, padding: '5px 10px', borderRadius: 8, background: 'transparent', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer', color: 'var(--ink-2)' }}>{umpire2 === '—' ? '+ Add' : 'Remove'}</button>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 18, padding: '13px 0', borderTop: '1px solid var(--hairline)' }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>Auto-post to feed</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>Match-live notification to followers</div>
              </div>
              <Toggle on={streamFeed} onClick={() => setStreamFeed(!streamFeed)} />
            </div>

            <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 8 }}>Review</div>
            <div style={{ padding: 14, borderRadius: 12, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Toss</span><span style={{ fontWeight: 600 }}>{tossWinner} · {decision} first</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>1st innings</span><span style={{ fontWeight: 600 }}>{battingTeam}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Striker / non-striker</span><span style={{ fontWeight: 600 }}>{xi[striker].n.split(' ')[0]} / {xi[nonStriker].n.split(' ')[0]}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Opening bowler</span><span style={{ fontWeight: 600 }}>{openingBowler != null ? eaglesBowlers[openingBowler].n : '—'}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Format</span><span style={{ fontWeight: 600, fontFamily: 'JetBrains Mono' }}>{overs} ov · PP {pp} · max {bowlerMax}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Pitch / weather</span><span style={{ fontWeight: 600 }}>{pitch} · {weather}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Rules</span><span style={{ fontWeight: 600 }}>{drs ? 'DRS' : 'no DRS'} · {wideRule.toLowerCase()} wides · {noBall.toLowerCase()}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, padding: '4px 0' }}><span style={{ color: 'var(--muted)' }}>Officials</span><span style={{ fontWeight: 600 }}>{umpire1}{umpire2 !== '—' ? ` & ${umpire2}` : ''}</span></div>
            </div>
          </>
        )}

        <div style={{ height: 12 }} />
      </div>

      <div style={{ padding: '12px 20px 22px', borderTop: '1px solid var(--hairline)', display: 'flex', gap: 8 }}>
        {step > 1 && (
          <button onClick={() => setStep(step - 1)} style={{
            padding: '14px 18px', borderRadius: 14, background: 'var(--paper-2)', color: 'var(--ink)',
            border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer',
          }}>Back</button>
        )}
        <button
          disabled={!canAdvance[step]}
          onClick={() => step < TOTAL ? setStep(step + 1) : setStarted(true)}
          className="ck-btn"
          style={{ flex: 1, opacity: canAdvance[step] ? 1 : 0.4 }}
        >
          {step < TOTAL
            ? (step === 1 ? 'Confirm toss → Squads' : step === 2 ? 'Confirm 11 → Opening' : step === 3 ? 'Confirm pair → Conditions' : step === 4 ? 'Confirm conditions → Rules' : 'Confirm rules → Officials')
            : 'Start match · 1st ball'}
        </button>
      </div>
    </div>
  );
}

// =========================================================================
// Variant B — XI selection (alt entry point)
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
// Variant C — Match conditions
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

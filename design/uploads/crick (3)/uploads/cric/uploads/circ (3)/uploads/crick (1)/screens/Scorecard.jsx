// Scorecard.jsx — Retrospective scorecard entry mode (§4.9.2)
// Used when a match was played but no live scoring happened.
// Captain/manager fills in batting card + bowling card after the match.

function Scorecard() {
  const [tab, setTab] = React.useState('Batting'); // Batting | Bowling | Extras
  const [innings, setInnings] = React.useState(1); // 1 or 2
  const [showAddBat, setShowAddBat] = React.useState(false);
  const [showAddBowl, setShowAddBowl] = React.useState(false);
  const [editingBat, setEditingBat] = React.useState(null);
  const [activeField, setActiveField] = React.useState('r');
  const [editVals, setEditVals] = React.useState({ r: '', b: '', f: '', s: '' });

  // Batting card per innings
  const [batting, setBatting] = React.useState({
    1: [
      { name: 'Adeel Sheikh', r: 28, b: 12, f: 3, s: 1, out: 'c Khan b Iqbal' },
      { name: 'Bilal Khan', r: 64, b: 38, f: 8, s: 2, out: 'b Iqbal' },
      { name: 'Hassan Raza', r: 16, b: 14, f: 1, s: 0, out: 'run out (Sheikh)' },
      { name: 'Imran Aslam', r: 22, b: 17, f: 2, s: 0, out: 'lbw b Khan' },
      { name: 'Saad Iqbal', r: 8, b: 9, f: 1, s: 0, out: 'not out' },
      { name: 'Tariq M.', r: 12, b: 6, f: 0, s: 1, out: 'not out' },
    ],
    2: [
      { name: 'A. Mohsin', r: 12, b: 14, f: 1, s: 0, out: 'b Mahmood' },
      { name: 'R. Iqbal', r: 38, b: 28, f: 4, s: 1, out: 'c Sheikh b Mahmood' },
      { name: 'K. Anwar', r: 24, b: 22, f: 2, s: 0, out: 'lbw b Aslam' },
    ],
  });

  // Bowling
  const [bowling, setBowling] = React.useState({
    1: [
      { name: 'Iqbal A.', o: 4, m: 0, r: 28, w: 2, eco: 7.0 },
      { name: 'Khan T.', o: 4, m: 0, r: 32, w: 1, eco: 8.0 },
      { name: 'V. Krishna', o: 4, m: 1, r: 26, w: 0, eco: 6.5 },
      { name: 'Hussain F.', o: 4, m: 0, r: 38, w: 0, eco: 9.5 },
    ],
    2: [
      { name: 'Tariq Mahmood', o: 4, m: 1, r: 22, w: 4, eco: 5.5 },
      { name: 'Imran Aslam', o: 4, m: 0, r: 28, w: 2, eco: 7.0 },
    ],
  });

  // Extras
  const [extras, setExtras] = React.useState({
    1: { wd: 4, nb: 1, b: 2, lb: 3, p: 0 },
    2: { wd: 6, nb: 2, b: 0, lb: 1, p: 0 },
  });

  const teams = { 1: 'Lahore Lions', 2: 'City Eagles' };
  const totalRuns = i => batting[i].reduce((a, p) => a + p.r, 0) + Object.values(extras[i]).reduce((a, v) => a + v, 0);
  const totalWkts = i => batting[i].filter(p => p.out !== 'not out').length;
  const extrasTotal = i => Object.values(extras[i]).reduce((a, v) => a + v, 0);

  const startEdit = (idx) => {
    const p = batting[innings][idx];
    setEditingBat(idx);
    setEditVals({ r: String(p.r), b: String(p.b), f: String(p.f), s: String(p.s) });
    setActiveField('r');
  };

  const saveEdit = () => {
    if (editingBat === null) return;
    setBatting(b => ({
      ...b,
      [innings]: b[innings].map((p, i) => i === editingBat ? {
        ...p,
        r: parseInt(editVals.r) || 0,
        b: parseInt(editVals.b) || 0,
        f: parseInt(editVals.f) || 0,
        s: parseInt(editVals.s) || 0,
      } : p),
    }));
    setEditingBat(null);
  };

  const tapPad = (key) => {
    setEditVals(v => {
      const cur = v[activeField];
      if (key === '⌫') return { ...v, [activeField]: cur.slice(0, -1) };
      if (key === '·') return v;
      return { ...v, [activeField]: cur === '0' ? key : (cur + key).slice(0, 3) };
    });
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      {/* Header */}
      <div style={{ padding: '14px 20px 0', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.1em' }}>RETROSPECTIVE ENTRY</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700, letterSpacing: '-0.015em' }}>Lions vs Eagles</div>
          </div>
          <button style={{ padding: '6px 11px', borderRadius: 8, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Save</button>
        </div>

        {/* Innings switcher */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
          {[1, 2].map(i => (
            <button key={i} onClick={() => setInnings(i)} style={{
              flex: 1, padding: '10px 12px', borderRadius: 10,
              background: innings === i ? 'var(--paper-2)' : 'transparent',
              border: '1px solid ' + (innings === i ? 'var(--ink)' : 'var(--hairline)'),
              fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left',
            }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>INNINGS {i}</div>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 2 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600 }}>{teams[i]}</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{totalRuns(i)}<span style={{ color: 'var(--muted)', fontSize: 12 }}>/{totalWkts(i)}</span></div>
              </div>
            </button>
          ))}
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex' }}>
          {['Batting', 'Bowling', 'Extras'].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: '11px 14px', fontSize: 13, fontWeight: 600,
              background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              color: tab === t ? 'var(--ink)' : 'var(--muted)',
              borderBottom: tab === t ? '2px solid var(--ink)' : '2px solid transparent',
              marginBottom: -1,
            }}>{t}</button>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        {tab === 'Batting' && (
          <div>
            {/* Column headers */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 32px 32px 24px 24px', gap: 6, padding: '10px 20px 6px', fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>
              <div>BATTER</div><div style={{ textAlign: 'right' }}>R</div><div style={{ textAlign: 'right' }}>B</div><div style={{ textAlign: 'right' }}>4s</div><div style={{ textAlign: 'right' }}>6s</div>
            </div>
            {batting[innings].map((p, i) => {
              const editing = editingBat === i;
              const sr = p.b > 0 ? ((p.r / p.b) * 100).toFixed(1) : '–';
              return (
                <div key={i}>
                  <button onClick={() => startEdit(i)} style={{
                    display: 'grid', gridTemplateColumns: '1fr 32px 32px 24px 24px',
                    gap: 6, padding: '10px 20px', width: '100%',
                    border: 'none', background: editing ? 'oklch(0.99 0.012 85)' : 'transparent',
                    borderTop: '1px solid var(--hairline)', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                  }}>
                    <div>
                      <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{p.name}</div>
                      <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{p.out} · SR {sr}</div>
                    </div>
                    <div style={{ textAlign: 'right', fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{p.r}</div>
                    <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--ink-2)' }}>{p.b}</div>
                    <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--ink-2)' }}>{p.f}</div>
                    <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--ink-2)' }}>{p.s}</div>
                  </button>
                </div>
              );
            })}

            <button onClick={() => setShowAddBat(true)} style={{
              display: 'flex', alignItems: 'center', gap: 8,
              padding: '12px 20px', width: '100%',
              border: 'none', borderTop: '1px dashed var(--line)',
              background: 'transparent', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left',
              color: 'var(--ink-2)', fontSize: 13, fontWeight: 600,
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
              Add batter
            </button>

            {/* Totals strip */}
            <div style={{ padding: '14px 20px', background: 'var(--paper-2)', borderTop: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em' }}>TOTAL</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 28, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em' }}>
                  {totalRuns(innings)}<span style={{ color: 'var(--muted)', fontSize: 18 }}>/{totalWkts(innings)}</span>
                </div>
              </div>
              <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 4 }}>
                Bat {batting[innings].reduce((a, p) => a + p.r, 0)} · Extras {extrasTotal(innings)} ({Object.entries(extras[innings]).filter(([k,v]) => v > 0).map(([k,v]) => `${v}${k}`).join(' ')})
              </div>
            </div>

            <div style={{ padding: 16 }}>
              <div style={{ padding: 12, borderRadius: 10, background: 'oklch(0.94 0.05 90 / 0.4)', border: '1px solid oklch(0.86 0.05 90)' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="oklch(0.30 0.02 80)" strokeWidth="2" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/></svg>
                  <div style={{ fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.4 }}>
                    <strong style={{ fontFamily: 'Inter Tight' }}>Retrospective mode.</strong> Stats won't include ball-by-ball detail. Wagon wheels, partnership graphs, and over-by-over breakdowns are unavailable. <a href="#" style={{ color: 'var(--ink)' }}>Learn more</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {tab === 'Bowling' && (
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 28px 28px 28px 28px 36px', gap: 4, padding: '10px 20px 6px', fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>
              <div>BOWLER</div><div style={{ textAlign: 'right' }}>O</div><div style={{ textAlign: 'right' }}>M</div><div style={{ textAlign: 'right' }}>R</div><div style={{ textAlign: 'right' }}>W</div><div style={{ textAlign: 'right' }}>ECO</div>
            </div>
            {bowling[innings].map((b, i) => (
              <div key={i} style={{
                display: 'grid', gridTemplateColumns: '1fr 28px 28px 28px 28px 36px',
                gap: 4, padding: '12px 20px', alignItems: 'center',
                borderTop: '1px solid var(--hairline)',
              }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{b.name}</div>
                <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 12 }}>{b.o}</div>
                <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 12 }}>{b.m}</div>
                <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 12 }}>{b.r}</div>
                <div style={{ textAlign: 'right', fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{b.w}</div>
                <div style={{ textAlign: 'right', fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{b.eco.toFixed(1)}</div>
              </div>
            ))}
            <button onClick={() => setShowAddBowl(true)} style={{
              display: 'flex', alignItems: 'center', gap: 8,
              padding: '12px 20px', width: '100%',
              border: 'none', borderTop: '1px dashed var(--line)',
              background: 'transparent', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left',
              color: 'var(--ink-2)', fontSize: 13, fontWeight: 600,
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
              Add bowler
            </button>
          </div>
        )}

        {tab === 'Extras' && (
          <div style={{ padding: '14px 20px' }}>
            <div className="ck-section-h" style={{ marginBottom: 12 }}>Extras · Innings {innings}</div>
            {[
              { k: 'wd', l: 'Wides' },
              { k: 'nb', l: 'No-balls' },
              { k: 'b', l: 'Byes' },
              { k: 'lb', l: 'Leg-byes' },
              { k: 'p', l: 'Penalty' },
            ].map(e => (
              <div key={e.k} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0', borderBottom: '1px solid var(--hairline)' }}>
                <div style={{ flex: 1, fontSize: 14, fontWeight: 500 }}>{e.l}</div>
                <button onClick={() => setExtras(x => ({ ...x, [innings]: { ...x[innings], [e.k]: Math.max(0, x[innings][e.k] - 1) } }))} style={{ width: 32, height: 32, borderRadius: 8, border: '1px solid var(--hairline)', background: 'var(--paper)', fontSize: 16, fontFamily: 'inherit', cursor: 'pointer' }}>−</button>
                <div style={{ width: 36, textAlign: 'center', fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{extras[innings][e.k]}</div>
                <button onClick={() => setExtras(x => ({ ...x, [innings]: { ...x[innings], [e.k]: x[innings][e.k] + 1 } }))} style={{ width: 32, height: 32, borderRadius: 8, border: '1px solid var(--hairline)', background: 'var(--paper)', fontSize: 16, fontFamily: 'inherit', cursor: 'pointer' }}>+</button>
              </div>
            ))}
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 16, padding: 14, background: 'var(--paper-2)', borderRadius: 12 }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em' }}>TOTAL EXTRAS</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em' }}>{extrasTotal(innings)}</div>
            </div>
          </div>
        )}
      </div>

      {/* Edit numpad sheet */}
      {editingBat !== null && tab === 'Batting' && (
        <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, background: 'var(--paper)', borderTop: '1px solid var(--line)', padding: '14px 16px 18px', boxShadow: '0 -8px 28px rgba(40,30,15,0.07)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{batting[innings][editingBat].name}</div>
            <button onClick={() => setEditingBat(null)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
            </button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6, marginBottom: 12 }}>
            {[
              { k: 'r', l: 'Runs' },
              { k: 'b', l: 'Balls' },
              { k: 'f', l: '4s' },
              { k: 's', l: '6s' },
            ].map(f => (
              <button key={f.k} onClick={() => setActiveField(f.k)} style={{
                padding: '8px 4px', borderRadius: 8,
                background: activeField === f.k ? 'var(--ink)' : 'var(--paper-2)',
                color: activeField === f.k ? 'var(--paper)' : 'var(--ink)',
                border: 'none', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'center',
              }}>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 8.5, opacity: 0.75, letterSpacing: '0.08em' }}>{f.l.toUpperCase()}</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{editVals[f.k] || '0'}</div>
              </button>
            ))}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6 }}>
            {['1', '2', '3', '4', '5', '6', '7', '8', '9', '·', '0', '⌫'].map(k => (
              <button key={k} onClick={() => tapPad(k)} style={{
                padding: '14px 0', borderRadius: 10, fontFamily: 'Inter Tight',
                background: 'var(--paper-2)', border: '1px solid var(--hairline)',
                fontSize: 18, fontWeight: 600, cursor: 'pointer',
              }}>{k}</button>
            ))}
          </div>
          <button onClick={saveEdit} style={{ width: '100%', marginTop: 10, padding: '12px 0', borderRadius: 10, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Save</button>
        </div>
      )}
    </div>
  );
}

window.CkScorecard = Scorecard;

// ScoringCases.jsx — every special scoring scenario as an overlay on the live scoring UI.
// The base Scoring.jsx is untouched; each case renders CkScoring underneath
// and layers a modal / sheet / banner on top.
//
// Public API:
//   <CkScoringCases kase="wkt-type" />
//
// Cases (15):
//   wkt-type        wicket — type picker
//   wkt-caught      wicket — caught, pick fielder
//   wkt-runout      wicket — run out, who's out + fielder
//   extras-wide     wide + runs picker
//   extras-noball   no-ball + bat runs + auto-free-hit
//   extras-bye      bye / leg-bye + runs
//   freehit         next ball is a free hit (top banner)
//   boundary        boundary confirm — 4 or 6?
//   over-end        end of over → pick next bowler
//   new-batter      wicket fell → pick incoming batter
//   innings-break   innings 1 done → start innings 2
//   match-won       match complete — won by runs / wickets
//   match-tied      tied → super over prompt
//   rain-pause      rain interruption — resume / reduce / abandon
//   edit-ball       long-press ball log → edit or undo

(function () {

const ink = 'var(--ink)';
const ink2 = 'var(--ink-2)';
const muted = 'var(--muted)';
const paper = 'var(--paper)';
const paper2 = 'var(--paper-2)';
const surface = 'var(--surface)';
const hair = 'var(--hairline)';
const red = 'var(--red)';
const redSoft = 'var(--red-soft)';
const green = 'var(--green)';
const greenSoft = 'var(--green-soft)';
const amber = 'var(--amber)';
const cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase' };
const display = (s) => ({ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: s, lineHeight: 1.05, color: ink });

// ═══════════════════════════════════════════════════════════════════════════
// Shared: render the live scoring UI underneath, optionally dimmed
// ═══════════════════════════════════════════════════════════════════════════

function ScoringBase({ dim }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      opacity: dim ? 0.55 : 1,
      pointerEvents: 'none', // overlays handle input
    }}>
      {typeof window !== 'undefined' && window.CkScoring && React.createElement(window.CkScoring)}
    </div>
  );
}

function Backdrop({ children, onClose }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(40,30,15,0.45)',
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
    }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()}>{children}</div>
    </div>
  );
}

function Sheet({ children, maxH }) {
  return (
    <div style={{
      background: paper, borderRadius: '24px 24px 0 0', padding: '18px 18px 24px',
      maxHeight: maxH || '85%', overflowY: 'auto',
      boxShadow: '0 -8px 32px rgba(40,30,15,0.18)',
    }}>
      <div style={{ width: 36, height: 4, borderRadius: 2, background: hair, margin: '0 auto 16px' }} />
      {children}
    </div>
  );
}

function SheetHeader({ kicker, title, sub, kickerColor }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ ...mono, fontSize: 9, color: kickerColor || muted, marginBottom: 4 }}>{kicker}</div>
      <div style={display(22)}>{title}</div>
      {sub && <div style={{ fontSize: 12.5, color: ink2, lineHeight: 1.5, marginTop: 6 }}>{sub}</div>}
    </div>
  );
}

function Pill({ children, active, danger, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '10px 14px', borderRadius: 999,
      border: '1.5px solid ' + (active ? (danger ? red : ink) : hair),
      background: active ? (danger ? red : ink) : paper,
      color: active ? paper : ink,
      fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: 'inherit', whiteSpace: 'nowrap',
    }}>{children}</button>
  );
}

function Primary({ children, danger, onClick, disabled }) {
  return (
    <button onClick={!disabled ? onClick : undefined} disabled={disabled} style={{
      flex: 1, padding: '13px 16px', borderRadius: 10, border: 'none',
      background: disabled ? paper2 : (danger ? red : ink),
      color: disabled ? muted : paper,
      fontWeight: 700, fontSize: 14, cursor: disabled ? 'default' : 'pointer',
      fontFamily: 'inherit', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    }}>{children}</button>
  );
}

function Ghost({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '13px 16px', borderRadius: 10,
      border: '1px solid ' + hair, background: paper, color: ink,
      fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
    }}>{children}</button>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · wkt-type
// ═══════════════════════════════════════════════════════════════════════════

function WktTypeView() {
  const [pick, setPick] = React.useState(null);
  const types = [
    { id: 'b',   l: 'Bowled',      ic: 'pole' },
    { id: 'ct',  l: 'Caught',      ic: 'hand' },
    { id: 'lbw', l: 'LBW',         ic: 'leg' },
    { id: 'ro',  l: 'Run out',     ic: 'run' },
    { id: 'st',  l: 'Stumped',     ic: 'glove' },
    { id: 'hw',  l: 'Hit wicket',  ic: 'pole' },
    { id: 'ret', l: 'Retired',     ic: 'walk' },
    { id: 'obs', l: 'Obstructing', ic: 'block' },
  ];
  return (
    <Sheet>
      <SheetHeader kicker="WICKET · BALL 15.4" kickerColor={red} title="How was the batter out?" sub="Pick a wicket type. We'll ask for fielders next if needed." />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8, marginBottom: 18 }}>
        {types.map(t => (
          <button key={t.id} onClick={() => setPick(t.id)} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '14px 12px',
            background: pick === t.id ? paper2 : paper,
            border: '2px solid ' + (pick === t.id ? red : hair),
            borderRadius: 12, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
          }}>
            <div style={{
              width: 32, height: 32, borderRadius: 9, flexShrink: 0,
              background: pick === t.id ? red : paper2,
              color: pick === t.id ? paper : ink2,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 14,
            }}>{t.id.toUpperCase().slice(0, 2)}</div>
            <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{t.l}</span>
          </button>
        ))}
      </div>

      <div style={{ padding: 12, background: cream, borderRadius: 10, fontSize: 11.5, color: ink2, lineHeight: 1.5, marginBottom: 14 }}>
        Striker: <b style={{ color: ink }}>S. Iqbal · 21 (15)</b> · Bowler: <b style={{ color: ink }}>Haroon Malik</b>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary danger disabled={!pick}>
          {pick === 'ct' || pick === 'ro' || pick === 'st' ? 'Next → fielder' : 'Confirm wicket'}
          {pick && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · wkt-caught — pick fielder
// ═══════════════════════════════════════════════════════════════════════════

function WktCaughtView() {
  const fielders = [
    { id: 'AS', n: 'Asad Sheikh',   role: 'WK',  hot: false },
    { id: 'BK', n: 'Bilal Khan',    role: 'CPT', hot: true },
    { id: 'FK', n: 'Faraz Khan',    role: 'AR' },
    { id: 'HM', n: 'Haroon Malik',  role: 'B', sub: 'Bowler — caught & bowled' },
    { id: 'IA', n: 'Imran Akhtar',  role: 'BAT' },
    { id: 'JA', n: 'Junaid Ali',    role: 'WK' },
    { id: 'SA', n: 'Saad Anwar',    role: 'BWL' },
    { id: 'TM', n: 'Tariq M.',      role: 'AR' },
    { id: 'UR', n: 'Usman Riaz',    role: 'AR' },
    { id: 'ZM', n: 'Zain Mansoor',  role: 'BAT' },
    { id: 'KR', n: 'Kashif Raza',   role: 'AR' },
  ];
  const [pick, setPick] = React.useState('BK');
  return (
    <Sheet>
      <SheetHeader kicker="CAUGHT · WICKET" kickerColor={red} title="Who took the catch?" sub="S. Iqbal c ??? b Malik — pick the fielder." />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6, marginBottom: 16 }}>
        {fielders.map(f => {
          const on = pick === f.id;
          return (
            <button key={f.id} onClick={() => setPick(f.id)} style={{
              padding: '10px 6px', borderRadius: 10,
              background: on ? paper2 : paper,
              border: '1.5px solid ' + (on ? red : hair),
              cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, position: 'relative',
            }}>
              {f.hot && <span style={{ position: 'absolute', top: 4, right: 4, ...mono, fontSize: 7, padding: '1px 4px', borderRadius: 3, background: greenSoft, color: 'oklch(0.36 0.10 148)' }}>HOT</span>}
              <div style={{
                width: 32, height: 32, borderRadius: 999,
                background: on ? red : paper2, color: on ? paper : ink,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
              }}>{f.id}</div>
              <div style={{ fontSize: 10, fontWeight: 600, textAlign: 'center', color: ink, lineHeight: 1.2 }}>{f.n.split(' ')[0]}</div>
              <div style={{ ...mono, fontSize: 7, color: muted }}>{f.role}</div>
            </button>
          );
        })}
      </div>

      <div style={{ padding: 12, background: redSoft, borderRadius: 10, fontSize: 12, color: red, fontWeight: 600, lineHeight: 1.5, marginBottom: 14 }}>
        S. Iqbal c <span style={{ background: red, color: paper, padding: '1px 6px', borderRadius: 3 }}>{fielders.find(f => f.id === pick)?.n}</span> b Malik · 21 (15)
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Back</Ghost>
        <Primary danger>
          Confirm catch
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><polyline points="20 6 9 17 4 12"/></svg>
        </Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · wkt-runout
// ═══════════════════════════════════════════════════════════════════════════

function WktRunoutView() {
  const [who, setWho] = React.useState('striker');
  const [fielder, setFielder] = React.useState('BK');
  const [runsBefore, setRunsBefore] = React.useState(1);
  return (
    <Sheet>
      <SheetHeader kicker="RUN OUT · WICKET" kickerColor={red} title="Run out details." sub="Who was out and who got them?" />

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>WHICH BATTER</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
        {[
          { id: 'striker',    n: 'S. Iqbal',   meta: '21 (15) · ON STRIKE' },
          { id: 'nonstriker', n: 'Faraz Ali',  meta: '28 (22) · NON-STRIKER' },
        ].map(b => {
          const on = who === b.id;
          return (
            <button key={b.id} onClick={() => setWho(b.id)} style={{
              padding: '12px', borderRadius: 12,
              background: on ? paper2 : paper,
              border: '2px solid ' + (on ? red : hair),
              cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>{b.n}</div>
              <div style={{ ...mono, fontSize: 8, color: muted, marginTop: 3 }}>{b.meta}</div>
            </button>
          );
        })}
      </div>

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>RUNS COMPLETED BEFORE OUT</div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {[0, 1, 2, 3].map(r => (
          <Pill key={r} active={runsBefore === r} onClick={() => setRunsBefore(r)}>{r}</Pill>
        ))}
      </div>

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>FIELDER (THREW)</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
        {[
          { id: 'BK', n: 'Bilal Khan' },
          { id: 'FK', n: 'Faraz Khan' },
          { id: 'AS', n: 'Asad Sheikh · WK' },
          { id: 'UR', n: 'Usman Riaz' },
          { id: 'HM', n: 'Haroon Malik' },
        ].map(f => (
          <Pill key={f.id} active={fielder === f.id} onClick={() => setFielder(f.id)}>{f.n}</Pill>
        ))}
      </div>

      <div style={{ padding: 12, background: redSoft, borderRadius: 10, fontSize: 12, color: red, fontWeight: 600, lineHeight: 1.5, marginBottom: 14 }}>
        {who === 'striker' ? 'S. Iqbal' : 'Faraz Ali'} run out by <b>{fielder}</b> · {runsBefore} run{runsBefore === 1 ? '' : 's'} completed
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Back</Ghost>
        <Primary danger>Confirm run out</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · extras-wide
// ═══════════════════════════════════════════════════════════════════════════

function ExtrasWideView() {
  const [extraRuns, setExtraRuns] = React.useState(1);
  const [boundary, setBoundary] = React.useState(false);
  return (
    <Sheet>
      <SheetHeader kicker="WIDE · EXTRA" kickerColor={amber} title="Wide — how many runs?" sub="Wide adds 1 penalty + any runs scored. Doesn't count as a legal ball." />

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>RUNS (INCLUDING WIDE)</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 6, marginBottom: 18 }}>
        {[1, 2, 3, 4, 5].map(r => {
          const on = extraRuns === r && !boundary;
          return (
            <button key={r} onClick={() => { setExtraRuns(r); setBoundary(false); }} style={{
              padding: '14px 0', borderRadius: 10,
              background: on ? cream : paper,
              border: '1.5px solid ' + (on ? amber : hair),
              cursor: 'pointer', fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 800, color: ink,
            }}>{r}</button>
          );
        })}
      </div>

      <button onClick={() => { setBoundary(true); setExtraRuns(5); }} style={{
        width: '100%', padding: 12, borderRadius: 10, marginBottom: 18,
        background: boundary ? greenSoft : paper,
        border: '1.5px solid ' + (boundary ? green : hair),
        cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: 7, flexShrink: 0,
          background: boundary ? green : greenSoft, color: boundary ? paper : 'oklch(0.36 0.10 148)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 14,
        }}>4</div>
        <div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 700 }}>Boundary 4 wide</div>
          <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>1 wide + 4 runs = 5 total</div>
        </div>
      </button>

      <div style={{ padding: 12, background: cream, borderRadius: 10, fontSize: 11.5, color: ink2, lineHeight: 1.5, marginBottom: 14 }}>
        Bowler concedes {boundary ? 5 : extraRuns} run{extraRuns === 1 && !boundary ? '' : 's'} · ball must be re-bowled · striker doesn't face
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary>Confirm wide</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · extras-noball
// ═══════════════════════════════════════════════════════════════════════════

function ExtrasNoballView() {
  const [batRuns, setBatRuns] = React.useState(0);
  return (
    <Sheet>
      <SheetHeader kicker="NO-BALL · EXTRA" kickerColor={red} title="No-ball — bat scored?" sub="No-ball is 1 penalty + bat's runs. Next ball is automatically a free hit." />

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>BAT SCORED (OFF THE BAT)</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6, marginBottom: 14 }}>
        {[0, 1, 2, 3, 4, 6].map(r => {
          const on = batRuns === r;
          return (
            <button key={r} onClick={() => setBatRuns(r)} style={{
              padding: '14px 0', borderRadius: 10,
              background: on ? (r === 4 ? greenSoft : r === 6 ? ink : paper2) : paper,
              border: '1.5px solid ' + (on ? (r === 6 ? ink : r === 4 ? green : ink) : hair),
              color: on && r === 6 ? paper : on && r === 4 ? 'oklch(0.36 0.10 148)' : ink,
              cursor: 'pointer', fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 800,
            }}>{r}</button>
          );
        })}
      </div>

      <label style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', background: paper, border: '1px solid ' + hair, borderRadius: 10, cursor: 'pointer', marginBottom: 18 }}>
        <input type="checkbox" defaultChecked style={{ accentColor: ink, width: 16, height: 16 }} />
        <div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600 }}>Next ball is a free hit</div>
          <div style={{ fontSize: 10.5, color: muted, marginTop: 2 }}>Auto-enabled for front-foot no-balls. Only run-outs can dismiss.</div>
        </div>
      </label>

      <div style={{ padding: 12, background: redSoft, borderRadius: 10, fontSize: 12, color: red, lineHeight: 1.5, marginBottom: 14 }}>
        <b>No-ball + {batRuns} off bat = {1 + batRuns} runs</b> · doesn't count as legal ball · re-bowl as free hit
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary danger>Confirm no-ball</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · extras-bye / leg-bye
// ═══════════════════════════════════════════════════════════════════════════

function ExtrasByeView() {
  const [kind, setKind] = React.useState('b');
  const [runs, setRuns] = React.useState(1);
  return (
    <Sheet>
      <SheetHeader kicker="BYES · EXTRAS" kickerColor={amber} title="Bye or leg-bye?" sub="Runs not credited to the batter. Ball still counts as legal." />

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>TYPE</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 18 }}>
        {[
          { id: 'b',  l: 'Bye',     s: 'Past the bat, no contact with body' },
          { id: 'lb', l: 'Leg-bye', s: 'Off the body, not the bat' },
        ].map(o => {
          const on = kind === o.id;
          return (
            <button key={o.id} onClick={() => setKind(o.id)} style={{
              padding: '14px 12px', borderRadius: 12,
              background: on ? paper2 : paper,
              border: '2px solid ' + (on ? ink : hair),
              cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700 }}>{o.l}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 3 }}>{o.s}</div>
            </button>
          );
        })}
      </div>

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>RUNS RUN</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 6, marginBottom: 14 }}>
        {[1, 2, 3, 4].map(r => {
          const on = runs === r;
          return (
            <button key={r} onClick={() => setRuns(r)} style={{
              padding: '14px 0', borderRadius: 10,
              background: on ? cream : paper,
              border: '1.5px solid ' + (on ? amber : hair),
              cursor: 'pointer', fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 800, color: ink,
            }}>{r}</button>
          );
        })}
        <button onClick={() => setRuns(4)} style={{
          padding: '14px 0', borderRadius: 10,
          background: runs === 4 ? greenSoft : paper,
          border: '1.5px solid ' + hair,
          cursor: 'pointer', fontFamily: 'Inter', fontSize: 11, fontWeight: 600,
        }}>BNDRY</button>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary>Confirm {kind === 'b' ? 'bye' : 'leg-bye'}</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · free hit (top banner — no modal)
// ═══════════════════════════════════════════════════════════════════════════

function FreeHitView() {
  return (
    <div style={{ position: 'absolute', top: 44, left: 0, right: 0, zIndex: 60 }}>
      <div style={{
        margin: '8px 12px 0', padding: '10px 14px', borderRadius: 12,
        background: amber, color: ink,
        display: 'flex', alignItems: 'center', gap: 10,
        boxShadow: '0 8px 24px rgba(40,30,15,0.18)',
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 999,
          background: ink, color: paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 11, letterSpacing: '-0.02em',
        }}>FH</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>Free hit · next ball</div>
          <div style={{ fontSize: 11, opacity: 0.75, marginTop: 1 }}>Only run-out can dismiss · batter can swing freely</div>
        </div>
        <span style={{ ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 5, background: 'rgba(255,255,255,0.5)' }}>BALL 15.5</span>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · boundary confirm
// ═══════════════════════════════════════════════════════════════════════════

function BoundaryView() {
  const [pick, setPick] = React.useState(null);
  return (
    <Sheet>
      <SheetHeader kicker="BOUNDARY · BALL 15.4" title="Was it a 4 or a 6?" sub="Fielder appears to have crossed the rope. Confirm." />

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18 }}>
        {[
          { id: 4, l: 'FOUR', bg: greenSoft, fg: 'oklch(0.36 0.10 148)' },
          { id: 6, l: 'SIX',  bg: ink,       fg: paper },
        ].map(b => {
          const on = pick === b.id;
          return (
            <button key={b.id} onClick={() => setPick(b.id)} style={{
              padding: '30px 0', borderRadius: 14,
              background: b.bg, color: b.fg,
              border: '3px solid ' + (on ? red : 'transparent'),
              cursor: 'pointer', fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 36, letterSpacing: '-0.04em',
            }}>{b.l}</button>
          );
        })}
      </div>

      <div style={{ padding: 12, background: paper2, borderRadius: 10, fontSize: 11.5, color: ink2, lineHeight: 1.5, marginBottom: 14, display: 'flex', gap: 10, alignItems: 'flex-start' }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink2} strokeWidth="1.8" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
        <span>Was the ball over the rope on the bounce? Tap <b style={{ color: ink }}>4</b>. Cleared the rope? <b style={{ color: ink }}>6</b>.</span>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary disabled={!pick}>Confirm {pick ? pick : ''}</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · over-end
// ═══════════════════════════════════════════════════════════════════════════

function OverEndView() {
  const [pick, setPick] = React.useState(null);
  const bowlers = [
    { id: 'SA', n: 'Saad Anwar',    role: 'BWL · LFM',  done: 2, max: 4, form: 'Hot' },
    { id: 'KR', n: 'Kashif Raza',   role: 'AR · RM',    done: 1, max: 4, form: 'Cold' },
    { id: 'TM', n: 'Tariq Mehmood', role: 'AR · SLA',   done: 3, max: 4, form: 'OK' },
    { id: 'FK', n: 'Faraz Khan',    role: 'AR · OS',    done: 4, max: 4, form: 'OK', maxedOut: true },
  ];
  return (
    <Sheet>
      <SheetHeader kicker="OVER 15 COMPLETE · 12 RUNS" title="Pick next bowler." sub="Haroon Malik can't bowl two in a row. 4 overs left." />

      {/* over recap */}
      <div style={{
        padding: 12, background: paper2, borderRadius: 12, marginBottom: 16,
      }}>
        <div style={{ display: 'flex', gap: 6, marginBottom: 8 }}>
          {['1', '0', '4', 'W', '6', '1'].map((b, i) => {
            const isFour = b === '4', isSix = b === '6', isWkt = b === 'W';
            return (
              <span key={i} style={{
                width: 30, height: 30, borderRadius: 7,
                background: isFour ? greenSoft : isWkt ? red : isSix ? ink : paper,
                color: isFour ? 'oklch(0.36 0.10 148)' : isWkt || isSix ? paper : ink,
                border: !isFour && !isWkt && !isSix ? '1px solid ' + hair : 'none',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13,
              }}>{b}</span>
            );
          })}
        </div>
        <div style={{ fontSize: 11.5, color: ink2 }}><b style={{ color: ink }}>Haroon Malik</b> · 4-0-32-2 · final over: 12 runs, 1 wkt</div>
      </div>

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>AVAILABLE BOWLERS</div>
      <div style={{ display: 'grid', gap: 6, marginBottom: 16 }}>
        {bowlers.map(b => {
          const on = pick === b.id;
          return (
            <button key={b.id} disabled={b.maxedOut} onClick={() => setPick(b.id)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
              background: on ? paper2 : paper,
              border: '1.5px solid ' + (on ? ink : hair),
              borderRadius: 10, cursor: b.maxedOut ? 'not-allowed' : 'pointer', fontFamily: 'inherit', textAlign: 'left',
              opacity: b.maxedOut ? 0.5 : 1,
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                background: on ? ink : paper2, color: on ? paper : ink2,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
              }}>{b.id}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{b.n}</span>
                  {b.maxedOut && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 3, background: redSoft, color: red }}>MAXED</span>}
                  {b.form === 'Hot' && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 3, background: greenSoft, color: 'oklch(0.36 0.10 148)' }}>HOT</span>}
                </div>
                <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{b.role}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>{b.done}<span style={{ color: muted, fontSize: 11 }}>/{b.max}</span></div>
                <div style={{ ...mono, fontSize: 8, color: muted, marginTop: 1 }}>OV BOWLED</div>
              </div>
            </button>
          );
        })}
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Skip</Ghost>
        <Primary disabled={!pick}>Confirm bowler</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · new batter
// ═══════════════════════════════════════════════════════════════════════════

function NewBatterView() {
  const [pick, setPick] = React.useState(null);
  const remaining = [
    { id: 'HM', n: 'Hamza Tariq',  role: 'BAT · RHB',     last: '47 (35) vs Eagles' },
    { id: 'UR', n: 'Usman Riaz',   role: 'AR · RHB · RFM', last: '24 (18) avg 28' },
    { id: 'KR', n: 'Kashif Raza',  role: 'AR · RHB',      last: '8 (12) form: cold' },
    { id: 'AL', n: 'Adnan Latif',  role: 'BWL · OS',      last: 'Not out twice' },
  ];
  return (
    <Sheet>
      <SheetHeader kicker="WICKET FELL · 15.4" kickerColor={red} title="Next batter in?" sub="S. Iqbal out c Khan b Malik · 21 (15). Lions 132/5." />

      <div style={{ display: 'grid', gap: 6, marginBottom: 16 }}>
        {remaining.map((p, i) => {
          const on = pick === p.id;
          return (
            <button key={p.id} onClick={() => setPick(p.id)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px',
              background: on ? paper2 : paper,
              border: '2px solid ' + (on ? ink : hair),
              borderRadius: 12, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ ...mono, fontSize: 9, color: muted, width: 18 }}>{i + 6}</div>
              <div style={{
                width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                background: paper2, color: ink2,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
              }}>{p.id}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{p.n}</div>
                <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{p.role} · {p.last}</div>
              </div>
            </button>
          );
        })}
      </div>

      <div style={{ padding: 12, background: paper2, borderRadius: 10, fontSize: 11.5, color: ink2, lineHeight: 1.5, marginBottom: 14 }}>
        Incoming batter joins <b style={{ color: ink }}>Faraz Ali (28*)</b> at the non-striker's end. They'll face ball 15.5.
      </div>

      <Primary disabled={!pick}>Send {pick ? remaining.find(p => p.id === pick).n.split(' ')[0] : ''} in →</Primary>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · innings-break
// ═══════════════════════════════════════════════════════════════════════════

function InningsBreakView() {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: paper,
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ height: 44 }} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 18px' }}>
        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 6 }}>INNINGS 1 COMPLETE · DRINKS</div>
        <h1 style={display(28)}>Lions <span style={{ color: muted }}>178/8</span></h1>
        <div style={{ fontSize: 13, color: ink2, marginTop: 4 }}>20 overs · RR 8.90 · best: Iqbal 67 (43)</div>

        {/* Target card */}
        <div style={{ marginTop: 18, padding: 16, borderRadius: 14, background: ink, color: paper }}>
          <div style={{ ...mono, fontSize: 9, opacity: 0.7, marginBottom: 6 }}>EAGLES TARGET</div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 56, letterSpacing: '-0.04em', lineHeight: 1 }}>179</div>
          <div style={{ fontSize: 12, opacity: 0.85, marginTop: 6 }}>from 20 overs · 8.95 rpo required</div>
        </div>

        {/* Top performers */}
        <div style={{ marginTop: 18 }}>
          <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>HIGHLIGHTS</div>
          <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12, overflow: 'hidden' }}>
            <HiRow icon="bat"  who="Iqbal"  what="67 (43) · 6 fours · 2 sixes" />
            <HiRow icon="ball" who="Malik"  what="3/22 (4) · economy 5.5" />
            <HiRow icon="six"  who="Riaz"   what="24 off 8 · including a 6-6-4" />
          </div>
        </div>

        {/* Innings 2 setup */}
        <div style={{ marginTop: 18, padding: 14, borderRadius: 12, background: paper2 }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 8 }}>UP NEXT</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700 }}>Eagles to bat</div>
          <div style={{ fontSize: 12, color: ink2, marginTop: 4, lineHeight: 1.5 }}>Pick openers (striker + non-striker) and Lions' opening bowler. Drinks for 10 minutes.</div>
        </div>
      </div>
      <div style={{ borderTop: '1px solid ' + hair, padding: '12px 18px', background: paper, display: 'flex', gap: 10 }}>
        <Ghost>Pause</Ghost>
        <Primary>Start innings 2 →</Primary>
      </div>
    </div>
  );
}

function HiRow({ icon, who, what }) {
  const icons = {
    bat:  <><path d="M4 20l16-16"/><rect x="2" y="18" width="6" height="4" rx="1"/></>,
    ball: <><circle cx="12" cy="12" r="9"/><path d="M3 12s3-7 9-7 9 7 9 7"/></>,
    six:  <><path d="M9 12a3 3 0 0 1 6 0v3a3 3 0 0 1-6 0V9a3 3 0 0 1 3-3"/></>,
  };
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 14px', borderTop: '1px solid ' + hair }}>
      <div style={{
        width: 28, height: 28, borderRadius: 8,
        background: cream, color: ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">{icons[icon]}</svg>
      </div>
      <span style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, color: ink, width: 60 }}>{who}</span>
      <span style={{ fontSize: 12, color: ink2 }}>{what}</span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · match-won (by runs)
// ═══════════════════════════════════════════════════════════════════════════

function MatchWonView({ byWkts }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: paper,
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ height: 44 }} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 18px' }}>
        <div style={{ ...mono, fontSize: 10, color: green, marginBottom: 6 }}>MATCH OVER · {byWkts ? 'EAGLES WON' : 'LIONS WON'}</div>
        <h1 style={display(34)}>{byWkts ? <>Eagles won<br/>by <span style={{ color: green }}>7 wickets</span>.</> : <>Lions won<br/>by <span style={{ color: green }}>23 runs</span>.</>}</h1>

        {/* Both innings */}
        <div style={{ marginTop: 24, display: 'grid', gap: 8 }}>
          <InningsCard team="Lions"  score="178/8 (20)" rr="8.90" winner={!byWkts} />
          <InningsCard team="Eagles" score={byWkts ? "182/3 (19.2)" : "155/9 (20)"} rr={byWkts ? "9.41" : "7.75"} winner={byWkts} />
        </div>

        {/* MOM */}
        <div style={{ marginTop: 24 }}>
          <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>PLAYER OF THE MATCH</div>
          <div style={{ padding: 14, background: ink, color: paper, borderRadius: 14, display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 56, height: 56, borderRadius: 14, background: amber, color: ink,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 22,
            }}>{byWkts ? 'AQ' : 'HM'}</div>
            <div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700 }}>{byWkts ? 'Asad Qureshi' : 'Haroon Malik'}</div>
              <div style={{ fontSize: 12, opacity: 0.75, marginTop: 2 }}>{byWkts ? '78 (51) · 6 fours · 3 sixes' : '3/22 (4) + 24 (12) · economy 5.5'}</div>
            </div>
          </div>
        </div>
      </div>
      <div style={{ borderTop: '1px solid ' + hair, padding: '12px 18px', background: paper, display: 'flex', gap: 10 }}>
        <Ghost>Share</Ghost>
        <Primary>View full scorecard</Primary>
      </div>
    </div>
  );
}

function InningsCard({ team, score, rr, winner }) {
  return (
    <div style={{
      padding: 14, borderRadius: 12,
      background: winner ? greenSoft : paper,
      border: '1.5px solid ' + (winner ? green : hair),
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>{team}</div>
        <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>RR {rr}</div>
      </div>
      <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 800, color: ink, letterSpacing: '-0.02em' }}>{score}</div>
      {winner && <span style={{ ...mono, fontSize: 9, padding: '3px 7px', borderRadius: 4, background: green, color: paper }}>WON</span>}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · match-tied · super over
// ═══════════════════════════════════════════════════════════════════════════

function MatchTiedView() {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: paper,
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ height: 44 }} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 18px' }}>
        <div style={{ ...mono, fontSize: 10, color: red, marginBottom: 6 }}>MATCH TIED · 178 = 178</div>
        <h1 style={display(32)}>Super over.</h1>
        <div style={{ fontSize: 13.5, color: ink2, marginTop: 8, lineHeight: 1.5 }}>
          Both sides scored 178. One over each, three batters per side, one bowler per side. Higher score wins.
        </div>

        <div style={{ marginTop: 22, padding: 14, borderRadius: 12, background: redSoft }}>
          <div style={{ ...mono, fontSize: 9, color: red, marginBottom: 8 }}>WHO BATS FIRST</div>
          <div style={{ fontSize: 13, color: ink, lineHeight: 1.5 }}>
            Side that bowled second bats first in the super over — <b>Lions</b>.
          </div>
        </div>

        <div style={{ ...mono, fontSize: 10, color: muted, marginTop: 24, marginBottom: 8 }}>NEXT 3 STEPS</div>
        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12, overflow: 'hidden' }}>
          <StepRow n="1" t="Lions pick 3 batters" />
          <StepRow n="2" t="Eagles pick 1 bowler" />
          <StepRow n="3" t="Toss for super-over choice (already in spec: bat first)" />
        </div>
      </div>
      <div style={{ borderTop: '1px solid ' + hair, padding: '12px 18px', background: paper, display: 'flex', gap: 10 }}>
        <Ghost>Tie · no result</Ghost>
        <Primary>Start super over →</Primary>
      </div>
    </div>
  );
}

function StepRow({ n, t }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: '1px solid ' + hair }}>
      <div style={{
        width: 24, height: 24, borderRadius: 999, background: ink, color: paper,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 11,
      }}>{n}</div>
      <span style={{ fontSize: 13, color: ink2 }}>{t}</span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · rain-pause
// ═══════════════════════════════════════════════════════════════════════════

function RainPauseView() {
  const [opt, setOpt] = React.useState('resume');
  return (
    <Sheet>
      <SheetHeader kicker="MATCH PAUSED · 15.4 OV" kickerColor={amber} title="Rain stoppage." sub="Eagles 132/4 chasing 179. 4.2 overs remaining. Both captains agree on next step." />

      <div style={{ display: 'grid', gap: 8, marginBottom: 16 }}>
        {[
          { id: 'resume',  l: 'Resume when ready',     s: 'Pause clock now, restart when umpire calls play',  primary: true },
          { id: 'reduce',  l: 'Reduce overs (DLS)',    s: 'Recalculate target. Need both captains to agree' },
          { id: 'abandon', l: 'Abandon — no result',   s: 'Match called off. Stats up to last completed over count' },
          { id: 'reschedule', l: 'Reschedule',         s: 'Move to a new date with same score, if possible' },
        ].map(o => {
          const on = opt === o.id;
          return (
            <button key={o.id} onClick={() => setOpt(o.id)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: 12,
              background: on ? paper2 : paper,
              border: '2px solid ' + (on ? ink : hair),
              borderRadius: 12, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{o.l}</span>
                  {o.primary && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 4, background: ink, color: paper }}>DEFAULT</span>}
                </div>
                <div style={{ fontSize: 11, color: muted, marginTop: 2, lineHeight: 1.4 }}>{o.s}</div>
              </div>
              <div style={{
                width: 18, height: 18, borderRadius: 999, flexShrink: 0,
                border: '2px solid ' + (on ? ink : hair),
                background: on ? ink : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {on && <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3"><path d="M20 6L9 17l-5-5"/></svg>}
              </div>
            </button>
          );
        })}
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary>Confirm choice</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CASE · edit-ball
// ═══════════════════════════════════════════════════════════════════════════

function EditBallView() {
  return (
    <Sheet>
      <SheetHeader kicker="EDIT BALL · 15.3" title="Change the call?" sub="Original entry: 2 runs · pushed to deep cover. You can edit or undo." />

      <div style={{
        padding: 14, background: paper2, borderRadius: 12, marginBottom: 14,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 10, background: paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 18, color: ink, border: '1px solid ' + hair,
        }}>2</div>
        <div style={{ flex: 1 }}>
          <div style={{ ...mono, fontSize: 9, color: muted }}>CURRENT</div>
          <div style={{ fontSize: 13, fontWeight: 600, color: ink, marginTop: 2 }}>2 runs · Iqbal · 21 (15)</div>
        </div>
        <span style={{ ...mono, fontSize: 9, color: muted }}>2m ago</span>
      </div>

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>CHANGE TO</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6, marginBottom: 14 }}>
        {['0', '1', '3', '4', '6', 'W', 'WD', 'NB'].map(r => (
          <button key={r} style={{
            padding: '12px 0', borderRadius: 8,
            background: paper, border: '1px solid ' + hair,
            cursor: 'pointer', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 14, color: ink,
          }}>{r}</button>
        ))}
      </div>

      <button style={{
        width: '100%', padding: 12, marginBottom: 14, borderRadius: 10,
        background: redSoft, color: red, border: 'none', cursor: 'pointer',
        fontFamily: 'inherit', fontWeight: 600, fontSize: 13,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>
        Undo this ball entirely
      </button>

      <div style={{ padding: 12, background: cream, borderRadius: 10, fontSize: 11, color: ink2, lineHeight: 1.5, marginBottom: 14, display: 'flex', gap: 10, alignItems: 'flex-start' }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink2} strokeWidth="1.8" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
        <span>Only the scorer can edit within 5 minutes. After that, the tournament creator must approve.</span>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Ghost>Cancel</Ghost>
        <Primary>Save change</Primary>
      </div>
    </Sheet>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT
// ═══════════════════════════════════════════════════════════════════════════

const CASES = {
  'wkt-type':       WktTypeView,
  'wkt-caught':     WktCaughtView,
  'wkt-runout':     WktRunoutView,
  'extras-wide':    ExtrasWideView,
  'extras-noball':  ExtrasNoballView,
  'extras-bye':     ExtrasByeView,
  'freehit':        FreeHitView,
  'boundary':       BoundaryView,
  'over-end':       OverEndView,
  'new-batter':     NewBatterView,
  'innings-break':  InningsBreakView,
  'match-won':      MatchWonView,
  'match-won-wkts': () => <MatchWonView byWkts />,
  'match-tied':     MatchTiedView,
  'rain-pause':     RainPauseView,
  'edit-ball':      EditBallView,
};

const TAKEOVER = new Set(['innings-break', 'match-won', 'match-won-wkts', 'match-tied']);
const NO_BACKDROP = new Set(['freehit']);

function CkScoringCases({ kase = 'wkt-type' } = {}) {
  const View = CASES[kase];

  // Full-screen takeovers replace scoring entirely
  if (TAKEOVER.has(kase)) {
    return (
      <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative', background: paper }}>
        <View />
      </div>
    );
  }

  // Banner-only overlays don't need a backdrop
  if (NO_BACKDROP.has(kase)) {
    return (
      <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative', background: paper, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0 }}>
          {typeof window !== 'undefined' && window.CkScoring && React.createElement(window.CkScoring)}
        </div>
        <View />
      </div>
    );
  }

  // Modal sheets — scoring dimmed underneath
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative', background: paper, overflow: 'hidden' }}>
      <ScoringBase dim />
      <Backdrop>
        <View />
      </Backdrop>
    </div>
  );
}

window.CkScoringCases = CkScoringCases;

})();

// CoScoring.jsx — UI additions for two-captain scoring.
// Three demos in one component, each shown standalone in the canvas:
//   <CkCoScoring view="active"   />  — your over, you're scoring
//   <CkCoScoring view="passive"  />  — their over, you're watching with flag rights
//   <CkCoScoring view="handoff"  />  — over complete, handing off
//   <CkCoScoring view="dispute"  />  — you long-pressed a ball; reconcile sheet
//
// Each demo is a full screen — keeps the existing Scoring.jsx untouched while
// showing the additions needed for co-scoring mode.

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

const MATCH = {
  ours:  { name: 'Lahore Lions',   mono: 'LL', color: red, captain: 'Bilal Ahmed' },
  them:  { name: 'Karachi Eagles', mono: 'KE', color: 'oklch(0.55 0.15 250)', captain: 'Imran Saeed' },
};

function Crest({ size = 32, bg, label, fg = paper }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.25, flexShrink: 0,
      background: bg, color: fg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: size * 0.4, letterSpacing: '-0.02em',
    }}>{label}</div>
  );
}

// ─── Handoff banner — pinned at top of scoring during co-scoring ────
function HandoffBanner({ mode, onFlag }) {
  // mode: 'active' (your turn) | 'passive' (their turn)
  if (mode === 'active') {
    return (
      <div style={{
        background: red, color: paper, padding: '10px 16px', height: 56, boxSizing: 'border-box',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{ width: 8, height: 8, borderRadius: 999, background: paper, animation: 'cs-pulse 1.4s infinite' }} />
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700 }}>Your over · Lions bowling</div>
          <div style={{ ...mono, fontSize: 9, opacity: 0.85, marginTop: 1 }}>4 balls scored · 2 to go</div>
        </div>
        <span style={{ ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 5, background: 'rgba(255,255,255,0.18)' }}>OVER 7</span>
      </div>
    );
  }
  return (
    <div style={{
      background: paper2, color: ink2, padding: '10px 16px', height: 56, boxSizing: 'border-box',
      borderBottom: '1px solid ' + hair,
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <Crest size={22} bg={MATCH.them.color} label={MATCH.them.mono} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600, color: ink }}>Eagles scoring · over 6.3</div>
        <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 1 }}>Imran scoring · Saad Anwar to bowl ball 4</div>
      </div>
      <span style={{ ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 5, background: paper, color: muted, border: '1px solid ' + hair }}>READ-ONLY</span>
    </div>
  );
}

// ─── Mock score header (slim version of what's in Scoring.jsx) ────────
function ScoreHeader({ dim }) {
  return (
    <div style={{ padding: '14px 18px 10px', background: paper, borderBottom: '1px solid ' + hair, opacity: dim ? 0.6 : 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <Crest size={36} bg={MATCH.ours.color} label={MATCH.ours.mono} />
        <div style={{ flex: 1 }}>
          <div style={{ ...mono, fontSize: 9, color: muted }}>LIONS · 1ST INNINGS</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 2 }}>
            58<span style={{ color: muted, fontSize: 22 }}>/2</span>
          </div>
          <div style={{ ...mono, fontSize: 10, color: ink2, marginTop: 4 }}>6.3 ov · CRR 9.05 · NEED 92 FROM 13.3</div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <BatterChip name="Hamza T." runs="32 (21)" striker />
        <BatterChip name="Faraz K." runs="18 (12)" />
      </div>
    </div>
  );
}

function BatterChip({ name, runs, striker }) {
  return (
    <div style={{
      flex: 1, padding: '8px 10px', borderRadius: 8,
      background: striker ? redSoft : paper2,
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      {striker && <div style={{ width: 6, height: 6, borderRadius: 999, background: red }} />}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter', fontSize: 12, fontWeight: 600, color: ink }}>{name}</div>
        <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 1 }}>{runs}</div>
      </div>
    </div>
  );
}

// ─── This-over ball log ───────────────────────────────────
function OverLog({ disputable, onDispute }) {
  const balls = [
    { runs: '1', kind: 'run' },
    { runs: '0', kind: 'dot' },
    { runs: '4', kind: 'four' },
    { runs: 'W', kind: 'wkt' },
    { runs: '2', kind: 'run' },
    { runs: '·', kind: 'pending' },
  ];
  return (
    <div style={{ padding: '12px 18px', background: paper, borderBottom: '1px solid ' + hair }}>
      <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 8 }}>THIS OVER · {disputable ? 'TAP TO FLAG' : 'IMRAN SCORING'}</div>
      <div style={{ display: 'flex', gap: 6 }}>
        {balls.map((b, i) => {
          const styles = {
            dot:     { bg: paper2,   fg: muted, border: '1px solid ' + hair },
            run:     { bg: paper2,   fg: ink },
            four:    { bg: greenSoft, fg: 'oklch(0.36 0.10 148)' },
            wkt:     { bg: red, fg: paper },
            pending: { bg: paper, fg: muted, border: '1.5px dashed ' + hair },
          }[b.kind];
          return (
            <button
              key={i}
              onClick={disputable ? () => onDispute(i) : undefined}
              style={{
                width: 36, height: 36, borderRadius: 8,
                background: styles.bg, color: styles.fg,
                border: styles.border || 'none',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15,
                cursor: disputable ? 'pointer' : 'default',
                position: 'relative',
              }}
            >
              {b.runs}
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─── Active scorer view ───────────────────────────────────
function ActiveView() {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper }}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10 }}>
        <div style={{ height: 44, background: red }} />
        <HandoffBanner mode="active" />
      </div>
      <div style={{ marginTop: 44 + 56, flex: 1, minHeight: 0, overflow: 'hidden' }}>
        <ScoringEmbed />
      </div>
    </div>
  );
}

// Render the real CkScoring component, stripped of its own top inset (we add our own).
function ScoringEmbed({ passive }) {
  return (
    <div style={{
      position: 'relative', height: '100%',
      pointerEvents: passive ? 'none' : 'auto',
      opacity: passive ? 0.55 : 1,
      transition: 'opacity 0.2s',
      marginTop: -44, // pull CkScoring up so its own 44px notch spacer hides under our banner
    }}>
      {typeof window !== 'undefined' && window.CkScoring && React.createElement(window.CkScoring)}
    </div>
  );
}

// ─── Passive scorer view (their over) ─────────────────────
function PassiveView({ onDispute }) {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, position: 'relative' }}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10 }}>
        <div style={{ height: 44, background: paper2 }} />
        <HandoffBanner mode="passive" />
      </div>
      <div style={{ marginTop: 44 + 56, flex: 1, minHeight: 0, overflow: 'hidden', position: 'relative' }}>
        <ScoringEmbed passive />
        {/* Floating flag CTA */}
        <button onClick={onDispute} style={{
          position: 'absolute', left: 16, right: 16, bottom: 24, zIndex: 5,
          padding: '14px 16px', borderRadius: 14, border: 'none',
          background: ink, color: paper, cursor: 'pointer', fontFamily: 'inherit',
          fontWeight: 700, fontSize: 14,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          boxShadow: '0 8px 28px rgba(40,30,15,0.20)',
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M4 22V4M4 4h13l-2 4 2 4H4"/></svg>
          Flag the last ball
        </button>
      </div>
    </div>
  );
}

function RoleRow({ icon, title, sub }) {
  const icons = {
    eye:  <><circle cx="12" cy="12" r="3"/><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/></>,
    flag: <><path d="M4 22V4M4 4h13l-2 4 2 4H4"/></>,
    bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></>,
  };
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 14px', borderTop: '1px solid ' + hair }}>
      <div style={{
        width: 28, height: 28, borderRadius: 8, flexShrink: 0,
        background: paper2, color: ink2,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">{icons[icon]}</svg>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: ink }}>{title}</div>
        <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{sub}</div>
      </div>
    </div>
  );
}

// ─── Over-end handoff sheet ───────────────────────────────
function HandoffView() {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'rgba(40,30,15,0.45)' }}>
      <div style={{ flex: 1 }} />
      <div style={{
        background: paper, borderRadius: '24px 24px 0 0', padding: '20px 18px 24px',
        boxShadow: '0 -8px 32px rgba(40,30,15,0.18)',
      }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: hair, margin: '0 auto 18px' }} />

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 18 }}>
          <div style={{
            width: 48, height: 48, borderRadius: 12, background: greenSoft, color: 'oklch(0.36 0.10 148)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={display(20)}>Over complete.</div>
            <div style={{ fontSize: 12, color: muted, marginTop: 2 }}>Imran Akhtar · 1-0-7-0 · 1 four · 0 dots</div>
          </div>
        </div>

        {/* Over recap */}
        <div style={{
          padding: 14, background: paper2, borderRadius: 12, marginBottom: 18,
        }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 8 }}>OVER 7 · 7 RUNS</div>
          <div style={{ display: 'flex', gap: 6 }}>
            {['1', '0', '4', 'W', '2', '·'].map((b, i) => {
              const isFour = b === '4';
              const isWkt = b === 'W';
              return (
                <span key={i} style={{
                  width: 32, height: 32, borderRadius: 7,
                  background: isFour ? greenSoft : isWkt ? red : paper,
                  color: isFour ? 'oklch(0.36 0.10 148)' : isWkt ? paper : ink,
                  border: !isFour && !isWkt ? '1px solid ' + hair : 'none',
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13,
                }}>{b}</span>
              );
            })}
          </div>
          <div style={{ fontSize: 11.5, color: ink2, marginTop: 10, lineHeight: 1.5 }}>
            Lions <b style={{ color: ink }}>58/3</b> after 7 · RR 8.29 · need 92 from 13 overs
          </div>
        </div>

        {/* Handoff card */}
        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>HANDING OFF</div>
        <div style={{ background: paper, border: '1.5px solid ' + ink, borderRadius: 12, padding: 14, marginBottom: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
            <Crest size={36} bg={MATCH.ours.color} label={MATCH.ours.mono} />
            <div style={{ ...mono, fontSize: 10, color: muted, alignSelf: 'center' }}>→</div>
            <Crest size={36} bg={MATCH.them.color} label={MATCH.them.mono} />
            <div style={{ flex: 1 }} />
            <span style={{ ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 5, background: ink, color: paper }}>OVER 8</span>
          </div>
          <div style={{ fontSize: 13, color: ink, fontWeight: 600, lineHeight: 1.4 }}>
            Eagles, you're up. Imran takes scoring.
          </div>
          <div style={{ fontSize: 11, color: muted, marginTop: 4, lineHeight: 1.5 }}>
            Pick your next bowler. Saad Anwar has 3 overs left, Faisal has 4.
          </div>
        </div>

        {/* Both-tap acknowledgement */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
          <AckCard team={MATCH.ours} captain="Bilal" ack />
          <AckCard team={MATCH.them} captain="Imran" />
        </div>

        <button style={{
          width: '100%', padding: '14px 0', borderRadius: 12, border: 'none',
          background: ink, color: paper,
          fontFamily: 'Inter', fontWeight: 700, fontSize: 14, cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          I'm ready · hand off to Eagles
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
        </button>

        <div style={{ ...mono, fontSize: 9, color: muted, textAlign: 'center', marginTop: 10 }}>
          Auto-advances in 30 s if both stale
        </div>
      </div>
    </div>
  );
}

function AckCard({ team, captain, ack }) {
  return (
    <div style={{
      flex: 1, padding: 10, borderRadius: 10,
      background: ack ? greenSoft : paper2,
      border: '1px solid ' + (ack ? green : hair),
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      <Crest size={24} bg={team.color} label={team.mono} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 600, color: ink }}>{captain}</div>
        <div style={{ ...mono, fontSize: 8, color: ack ? 'oklch(0.36 0.10 148)' : muted, marginTop: 1 }}>
          {ack ? '✓ READY' : 'WAITING'}
        </div>
      </div>
    </div>
  );
}

// ─── Dispute / reconcile sheet ────────────────────────────
function DisputeView({ onClose }) {
  const [proposed, setProposed] = React.useState(null);
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'rgba(40,30,15,0.45)' }}>
      <div style={{ flex: 1 }} />
      <div style={{
        background: paper, borderRadius: '24px 24px 0 0', padding: '20px 18px 24px',
        boxShadow: '0 -8px 32px rgba(40,30,15,0.18)',
      }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: hair, margin: '0 auto 18px' }} />

        <div style={{ marginBottom: 16 }}>
          <div style={{ ...mono, fontSize: 9, color: red, marginBottom: 4 }}>FLAG · BALL 7.4</div>
          <div style={{ ...display(20), marginBottom: 6 }}>Disagree with Imran's call?</div>
          <div style={{ fontSize: 12.5, color: muted, lineHeight: 1.5 }}>
            Imran entered <b style={{ color: ink }}>1 wicket — caught by Asad</b>. Imran will see your flag and can accept or counter.
          </div>
        </div>

        {/* What Imran entered */}
        <div style={{
          padding: 12, background: paper2, borderRadius: 10, marginBottom: 12,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8, background: red, color: paper,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 16,
          }}>W</div>
          <div style={{ flex: 1 }}>
            <div style={{ ...mono, fontSize: 9, color: muted }}>IMRAN ENTERED</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: ink, marginTop: 2 }}>Hamza Tariq c Asad b Saad · 32 (21)</div>
          </div>
        </div>

        {/* What's the correct call */}
        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>WHAT REALLY HAPPENED</div>
        <div style={{ display: 'grid', gap: 6, marginBottom: 16 }}>
          {[
            { id: 'four', l: 'It was a 4', s: 'Caught on the rope, umpire signalled six… wait, four' },
            { id: 'six',  l: 'It was a 6',  s: 'Cleared the rope' },
            { id: 'noWkt',l: 'Not out',     s: 'Fielder grounded the ball / no-ball' },
            { id: 'other',l: 'Something else', s: "I'll explain" },
          ].map(o => {
            const on = proposed === o.id;
            return (
              <button key={o.id} onClick={() => setProposed(o.id)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: 12,
                background: on ? paper2 : paper,
                border: '1.5px solid ' + (on ? ink : hair),
                borderRadius: 10, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
              }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{o.l}</div>
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

        <div style={{ padding: 12, borderRadius: 10, background: cream, fontSize: 11, color: ink2, lineHeight: 1.5, marginBottom: 16 }}>
          If Imran disagrees with your flag, the on-field umpire makes the final call. Both versions stay in the match log.
        </div>

        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={onClose} style={{
            padding: '13px 16px', borderRadius: 10,
            border: '1px solid ' + hair, background: paper, color: ink,
            fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
          }}>Cancel</button>
          <button disabled={!proposed} style={{
            flex: 1, padding: '13px 16px', borderRadius: 10, border: 'none',
            background: proposed ? red : paper2, color: proposed ? paper : muted,
            fontWeight: 700, fontSize: 14, cursor: proposed ? 'pointer' : 'default', fontFamily: 'inherit',
          }}>Send flag to Imran</button>
        </div>
      </div>
    </div>
  );
}

// ─── Root ─────────────────────────────────────────────────
function CkCoScoring({ view = 'active' } = {}) {
  const [v, setV] = React.useState(view);
  if (v === 'active')   return <ActiveView />;
  if (v === 'passive')  return <PassiveView onDispute={() => setV('dispute')} />;
  if (v === 'handoff')  return <HandoffView />;
  if (v === 'dispute')  return <DisputeView onClose={() => setV('passive')} />;
  return null;
}

// Animation
const styleEl = document.createElement('style');
styleEl.textContent = `@keyframes cs-pulse { 0%,100% { opacity:1 } 50% { opacity:0.4 } }`;
document.head.appendChild(styleEl);

window.CkCoScoring = CkCoScoring;

})();

// TournamentSeed.jsx — Organizer flow to seed teams, generate bracket, lock fixtures
// Steps: 1) Seed teams (drag/up-down) → 2) Preview bracket → 3) Lock & publish

function CkTournamentSeed() {
  const initial = ['LL', 'KS', 'MT', 'IT', 'GG', 'PR', 'FX', 'ML'];
  const [step, setStep] = React.useState(1);
  const [order, setOrder] = React.useState(initial);
  const [locked, setLocked] = React.useState(false);

  const move = (i, dir) => {
    const j = i + dir;
    if (j < 0 || j >= order.length) return;
    const next = [...order];
    [next[i], next[j]] = [next[j], next[i]];
    setOrder(next);
  };
  const shuffle = () => setOrder([...order].sort(() => Math.random() - 0.5));

  // Standard knockout pairing for 8 (1v8, 4v5, 2v7, 3v6) → SF order
  const pair = (s) => [[s[0], s[7]], [s[3], s[4]], [s[1], s[6]], [s[2], s[5]]];
  const qfs = pair(order);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 18px 4px', flexShrink: 0 }}>
        <button style={iconBtn}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="var(--ink)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
        </button>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>SEED & GENERATE</span>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{step}/3</span>
      </div>

      {/* Step indicator */}
      <div style={{ padding: '10px 18px 8px', display: 'flex', gap: 4, flexShrink: 0 }}>
        {[1, 2, 3].map(n => (
          <div key={n} style={{
            flex: 1, height: 3, borderRadius: 999,
            background: n <= step ? 'var(--ink)' : 'var(--paper-2)',
          }}/>
        ))}
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto', padding: '0 18px' }}>
        {step === 1 && (
          <div>
            <h2 className="ck-display" style={{ fontSize: 24, margin: '6px 0 4px', letterSpacing: '-0.025em' }}>Seed the teams</h2>
            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 14 }}>
              Higher seed plays lower seed. Reorder, or shuffle for a random draw.
            </div>
            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
              {order.map((id, i) => (
                <div key={id} style={{
                  display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px',
                  borderTop: i ? '1px solid var(--hairline)' : 'none',
                }}>
                  <span className="ck-mono" style={{
                    width: 22, fontSize: 11, fontWeight: 700, color: 'var(--muted)',
                  }}>#{i + 1}</span>
                  <CkTBadge id={id} size={28} />
                  <span style={{ flex: 1, fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{TEAMS[id]?.name}</span>
                  <button onClick={() => move(i, -1)} disabled={i === 0} style={{...arrowBtn, opacity: i === 0 ? 0.25 : 1}}>↑</button>
                  <button onClick={() => move(i, +1)} disabled={i === order.length - 1} style={{...arrowBtn, opacity: i === order.length - 1 ? 0.25 : 1}}>↓</button>
                </div>
              ))}
            </div>
            <button onClick={shuffle} style={{
              marginTop: 12, width: '100%', padding: 12, borderRadius: 12,
              border: '1px dashed var(--line)', background: 'transparent',
              color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer',
            }}>↻ Random seeding</button>
          </div>
        )}

        {step === 2 && (
          <div>
            <h2 className="ck-display" style={{ fontSize: 24, margin: '6px 0 4px', letterSpacing: '-0.025em' }}>Preview bracket</h2>
            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 14 }}>
              8 teams · 7 matches · single elimination. Final on May 4.
            </div>

            {/* Round columns rendered vertically as cards (small phone) */}
            <RoundBlock title="Quarter-finals · Apr 30 → May 1" items={qfs.map((p, i) => ({
              round: `QF${i+1}`, a: p[0], b: p[1],
              when: i < 2 ? `Apr 30 · ${i === 0 ? '14:00' : '19:30'}` : `May 1 · ${i === 2 ? '14:00' : '19:30'}`,
            }))} />
            <RoundBlock title="Semi-finals · May 3" items={[
              { round: 'SF1', a: null, b: null, label: 'W QF1 vs W QF2', when: 'May 3 · 14:00' },
              { round: 'SF2', a: null, b: null, label: 'W QF3 vs W QF4', when: 'May 3 · 19:30' },
            ]} />
            <RoundBlock title="Final · May 4" items={[
              { round: 'F', a: null, b: null, label: 'W SF1 vs W SF2', when: 'May 4 · 19:30 · Gaddafi B' },
            ]} />

            <div style={{
              padding: '10px 12px', borderRadius: 12, marginTop: 14,
              background: 'oklch(0.97 0.04 90)', border: '1px solid oklch(0.88 0.05 90)',
              fontSize: 11, color: 'oklch(0.40 0.10 80)', lineHeight: 1.5,
            }}>
              <strong style={{ color: 'oklch(0.30 0.10 80)' }}>Heads up · </strong>
              You can still reschedule individual matches after locking, but seeds are frozen.
            </div>
          </div>
        )}

        {step === 3 && (
          <div style={{ textAlign: 'center', paddingTop: 20 }}>
            {!locked ? (
              <>
                <div style={{
                  width: 80, height: 80, margin: '0 auto 18px',
                  borderRadius: 999, background: 'var(--paper-2)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="1.5"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>
                </div>
                <h2 className="ck-display" style={{ fontSize: 24, margin: '0 0 8px', letterSpacing: '-0.025em' }}>Lock fixtures?</h2>
                <div style={{ fontSize: 13, color: 'var(--muted)', maxWidth: 280, margin: '0 auto 20px', lineHeight: 1.5 }}>
                  Bracket goes live to all teams and the public. Late entrants will be put on a waitlist.
                </div>
                <div style={{
                  textAlign: 'left', background: 'var(--surface)', border: '1px solid var(--hairline)',
                  borderRadius: 14, padding: 14, maxWidth: 320, margin: '0 auto',
                }}>
                  {[
                    ['Format', 'Knockout · 8 teams'],
                    ['Matches', '7 (with 3rd-place off)'],
                    ['First match', `${TEAMS[qfs[0][0]]?.name} vs ${TEAMS[qfs[0][1]]?.name}`],
                    ['Final', 'May 4 · Gaddafi B'],
                  ].map(([k, v], i) => (
                    <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
                      <span style={{ fontSize: 12, color: 'var(--muted)' }}>{k}</span>
                      <span style={{ fontSize: 12, fontWeight: 600 }}>{v}</span>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <>
                <div style={{
                  width: 80, height: 80, margin: '40px auto 18px',
                  borderRadius: 999, background: 'var(--green-soft)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <svg width="38" height="38" viewBox="0 0 24 24" fill="none" stroke="oklch(0.36 0.10 148)" strokeWidth="2.4" strokeLinecap="round"><path d="m5 12 5 5L20 7"/></svg>
                </div>
                <h2 className="ck-display" style={{ fontSize: 26, margin: '0 0 8px', letterSpacing: '-0.025em' }}>Bracket is live</h2>
                <div style={{ fontSize: 13, color: 'var(--muted)', maxWidth: 280, margin: '0 auto', lineHeight: 1.5 }}>
                  Captains have been notified. First toss in 19h.
                </div>
              </>
            )}
          </div>
        )}
      </div>

      {/* CTA bar */}
      <div style={{ flexShrink: 0, padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8 }}>
        {step > 1 && !locked && (
          <button onClick={() => setStep(s => s - 1)} style={{
            padding: '12px 18px', borderRadius: 12, border: '1px solid var(--hairline)',
            background: 'var(--paper)', color: 'var(--ink)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>Back</button>
        )}
        <button onClick={() => {
          if (step < 3) setStep(s => s + 1);
          else if (!locked) setLocked(true);
        }} style={{
          flex: 1, padding: '12px 0', borderRadius: 12, border: 'none',
          background: locked ? 'var(--green)' : 'var(--ink)',
          color: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
        }}>
          {step === 1 ? 'Continue · Preview bracket' : step === 2 ? 'Continue · Lock' : locked ? 'Done' : 'Lock & publish'}
        </button>
      </div>
    </div>
  );
}

function RoundBlock({ title, items }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <div className="ck-section-h" style={{ marginBottom: 6 }}>{title}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {items.map((m, i) => (
          <div key={i} style={{
            border: '1px solid var(--hairline)', borderRadius: 12, padding: '10px 12px',
            background: 'var(--surface)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
              <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)' }}>{m.round}</span>
              <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)' }}>{m.when}</span>
            </div>
            {m.a ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <CkTBadge id={m.a} size={20} />
                <span style={{ fontSize: 12, fontWeight: 600, flex: 1 }}>{TEAMS[m.a].name}</span>
                <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)' }}>vs</span>
                <span style={{ fontSize: 12, fontWeight: 600, flex: 1, textAlign: 'right' }}>{TEAMS[m.b].name}</span>
                <CkTBadge id={m.b} size={20} />
              </div>
            ) : (
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--muted)', fontSize: 12, fontStyle: 'italic' }}>
                <div style={{ width: 20, height: 20, borderRadius: 5, background: 'var(--paper-2)', border: '1px dashed var(--line)' }}/>
                <span style={{ flex: 1 }}>{m.label}</span>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

const iconBtn = { background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' };
const arrowBtn = {
  width: 28, height: 28, borderRadius: 8, border: '1px solid var(--hairline)',
  background: 'var(--paper)', color: 'var(--ink)', cursor: 'pointer',
  fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700,
};

window.CkTournamentSeed = CkTournamentSeed;

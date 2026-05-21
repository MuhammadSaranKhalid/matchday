// TournamentRegister.jsx — Team manager registers their team for a tournament
// Steps: 1) Tournament summary + accept rules → 2) Pick squad → 3) Pay & submit

function CkTournamentRegister() {
  const [step, setStep] = React.useState(1);
  const [submitted, setSubmitted] = React.useState(false);
  const roster = [
    { id: 'p1', name: 'Babar Ahmed',     role: 'BAT', claimed: true,  jersey: 56 },
    { id: 'p2', name: 'Hassan Ali',      role: 'BWL', claimed: true,  jersey: 32 },
    { id: 'p3', name: 'Imad Wasim',      role: 'AR',  claimed: true,  jersey: 14 },
    { id: 'p4', name: 'Sarfaraz K.',     role: 'WK',  claimed: true,  jersey: 54 },
    { id: 'p5', name: 'Rizwan Sheikh',   role: 'BAT', claimed: false, jersey: 18 },
    { id: 'p6', name: 'Naseem Shah',     role: 'BWL', claimed: true,  jersey: 71 },
    { id: 'p7', name: 'Faheem Ashraf',   role: 'AR',  claimed: true,  jersey: 9  },
    { id: 'p8', name: 'Asif Ali',        role: 'BAT', claimed: false, jersey: 26 },
    { id: 'p9', name: 'Shadab Khan',     role: 'AR',  claimed: true,  jersey: 29 },
    { id: 'p10', name: 'Haris Rauf',     role: 'BWL', claimed: true,  jersey: 11 },
    { id: 'p11', name: 'Mohammad Nawaz', role: 'AR',  claimed: false, jersey: 37 },
    { id: 'p12', name: 'Iftikhar Ahmed', role: 'BAT', claimed: true,  jersey: 51 },
    { id: 'p13', name: 'Saud Shakeel',   role: 'BAT', claimed: false, jersey: 47 },
    { id: 'p14', name: 'Abrar Ahmed',    role: 'BWL', claimed: true,  jersey: 23 },
  ];
  const [picked, setPicked] = React.useState(new Set(roster.slice(0, 11).map(p => p.id)));
  const [accepted, setAccepted] = React.useState(false);

  const toggle = (id) => {
    const next = new Set(picked);
    if (next.has(id)) next.delete(id);
    else if (next.size < 15) next.add(id);
    setPicked(next);
  };
  const valid2 = picked.size >= 11 && picked.size <= 15;

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 18px 4px', flexShrink: 0 }}>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="var(--ink)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
        </button>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>REGISTER TEAM</span>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{step}/3</span>
      </div>

      <div style={{ padding: '8px 18px 4px', display: 'flex', gap: 4, flexShrink: 0 }}>
        {[1,2,3].map(n => <div key={n} style={{ flex: 1, height: 3, borderRadius: 999, background: n <= step ? 'var(--ink)' : 'var(--paper-2)' }}/>)}
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '10px 18px 0' }}>
        {submitted ? (
          <div style={{ paddingTop: 40, textAlign: 'center' }}>
            <div style={{ width: 80, height: 80, margin: '0 auto 18px', borderRadius: 999, background: 'oklch(0.97 0.04 90)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="oklch(0.45 0.12 80)" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            </div>
            <h2 className="ck-display" style={{ fontSize: 24, margin: '0 0 8px', letterSpacing: '-0.025em' }}>Registration submitted</h2>
            <div style={{ fontSize: 13, color: 'var(--muted)', maxWidth: 280, margin: '0 auto', lineHeight: 1.5 }}>
              The organizer reviews squad and fee. You'll get a notification on approval — usually within a day.
            </div>
            <div style={{ marginTop: 28, display: 'inline-flex', gap: 6, padding: '8px 12px', borderRadius: 999, background: 'oklch(0.97 0.04 90)', border: '1px solid oklch(0.88 0.05 90)' }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: 'oklch(0.45 0.12 80)', alignSelf: 'center' }}/>
              <span className="ck-mono" style={{ fontSize: 10, fontWeight: 700, color: 'oklch(0.40 0.10 80)', letterSpacing: '0.08em' }}>PENDING APPROVAL</span>
            </div>
          </div>
        ) : (
        <>
        {step === 1 && (
          <div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', letterSpacing: '0.1em', marginBottom: 4 }}>
              YOU'RE REGISTERING
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
              <CkTBadge id="LL" size={36} />
              <div>
                <div className="ck-display" style={{ fontSize: 20, fontWeight: 700 }}>Lahore Lions</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>You · captain</div>
              </div>
            </div>

            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: 14, marginBottom: 16 }}>
              <div className="ck-section-h" style={{ marginBottom: 6 }}>The tournament</div>
              <div className="ck-display" style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em' }}>
                Spring Cup '26
              </div>
              <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>
                Knockout · 8 teams · T20 · Apr 30 → May 4
              </div>
              <div style={{ marginTop: 12, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                {[
                  ['Entry fee', 'Rs. 12,000'],
                  ['Reg. closes', 'Apr 29'],
                  ['Squad size', '11 – 15'],
                  ['Multi-team', 'Not allowed'],
                ].map(([k, v]) => (
                  <div key={k}>
                    <div style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{k}</div>
                    <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{v}</div>
                  </div>
                ))}
              </div>
            </div>

            <div className="ck-section-h" style={{ marginBottom: 6 }}>Rules to acknowledge</div>
            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 14 }}>
              {[
                'Squad locks once tournament starts',
                'Players must be claimed profiles to count for season stats',
                'Walkover if team is 15 min late to toss',
                'Ball type: leather · powerplay 6 · max 4 ov/bowler',
              ].map((r, i) => (
                <div key={i} style={{ padding: '11px 14px', fontSize: 12, color: 'var(--ink-2)', borderTop: i ? '1px solid var(--hairline)' : 'none', display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                  <span style={{ width: 4, height: 4, borderRadius: 999, background: 'var(--muted)', marginTop: 7, flexShrink: 0 }}/>
                  {r}
                </div>
              ))}
            </div>

            <button onClick={() => setAccepted(a => !a)} style={{
              width: '100%', padding: 12, borderRadius: 12,
              border: `1px solid ${accepted ? 'var(--ink)' : 'var(--hairline)'}`,
              background: accepted ? 'var(--ink)' : 'var(--paper)',
              color: accepted ? 'var(--paper)' : 'var(--ink-2)',
              fontFamily: 'Inter', fontSize: 13, fontWeight: 500, cursor: 'pointer',
              display: 'flex', alignItems: 'center', gap: 10, textAlign: 'left',
            }}>
              <span style={{
                width: 18, height: 18, borderRadius: 5,
                border: `1.5px solid ${accepted ? 'var(--paper)' : 'var(--line)'}`,
                background: accepted ? 'var(--paper)' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                {accepted && <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="3" strokeLinecap="round"><path d="m5 12 5 5L20 7"/></svg>}
              </span>
              I agree to the rules above
            </button>
          </div>
        )}

        {step === 2 && (
          <div>
            <h2 className="ck-display" style={{ fontSize: 22, margin: '0 0 4px', letterSpacing: '-0.025em' }}>Pick your squad</h2>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
              <span style={{ fontSize: 12, color: 'var(--muted)' }}>{picked.size} of 11–15 selected</span>
              <span style={{ flex: 1, height: 4, borderRadius: 999, background: 'var(--paper-2)', overflow: 'hidden' }}>
                <span style={{ display: 'block', width: `${Math.min(100, (picked.size/15)*100)}%`, height: '100%', background: valid2 ? 'var(--green)' : 'var(--amber)' }}/>
              </span>
            </div>

            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
              {roster.map((p, i) => {
                const sel = picked.has(p.id);
                return (
                  <button key={p.id} onClick={() => toggle(p.id)} style={{
                    width: '100%', display: 'flex', alignItems: 'center', gap: 10,
                    padding: '11px 12px', borderTop: i ? '1px solid var(--hairline)' : 'none',
                    background: sel ? 'oklch(0.97 0.02 148)' : 'transparent',
                    border: 'none', borderTopColor: 'var(--hairline)',
                    cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
                  }}>
                    <span style={{
                      width: 22, height: 22, borderRadius: 6,
                      border: `1.5px solid ${sel ? 'var(--green)' : 'var(--line)'}`,
                      background: sel ? 'var(--green)' : 'transparent',
                      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                    }}>
                      {sel && <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round"><path d="m5 12 5 5L20 7"/></svg>}
                    </span>
                    <div style={{ width: 30, fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 700, color: 'var(--muted)' }}>#{p.jersey}</div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                        {p.name}
                        {p.claimed ? (
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="oklch(0.32 0.14 250)"><path d="M12 2 4 5v6c0 5 3.4 9.4 8 11 4.6-1.6 8-6 8-11V5l-8-3Z"/></svg>
                        ) : null}
                      </div>
                      <div style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 1 }}>
                        {p.role} {!p.claimed && '· UNCLAIMED'}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>

            {!picked.size && (
              <div style={{ marginTop: 10, fontSize: 11, color: 'var(--red)' }}>Select at least 11 players.</div>
            )}
          </div>
        )}

        {step === 3 && (
          <div>
            <h2 className="ck-display" style={{ fontSize: 22, margin: '0 0 14px', letterSpacing: '-0.025em' }}>Review & pay</h2>

            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: 14, marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
                <CkTBadge id="LL" size={32} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700 }}>Lahore Lions</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)' }}>{picked.size} players · captained by you</div>
                </div>
                <button onClick={() => setStep(2)} style={{ background: 'transparent', border: 'none', color: 'var(--ink-2)', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', cursor: 'pointer' }}>EDIT</button>
              </div>
              <div style={{ borderTop: '1px solid var(--hairline)', paddingTop: 10 }}>
                {[
                  ['Entry fee', 'Rs. 12,000'],
                  ['Platform fee', 'Rs. 0'],
                ].map(([k, v]) => (
                  <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', fontSize: 12 }}>
                    <span style={{ color: 'var(--muted)' }}>{k}</span>
                    <span className="ck-mono">{v}</span>
                  </div>
                ))}
                <div style={{ borderTop: '1px solid var(--hairline)', marginTop: 8, paddingTop: 8, display: 'flex', justifyContent: 'space-between', fontSize: 14, fontWeight: 700 }}>
                  <span>Total</span>
                  <span className="ck-mono">Rs. 12,000</span>
                </div>
              </div>
            </div>

            <div className="ck-section-h" style={{ marginBottom: 6 }}>Pay with</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 8 }}>
              {[
                { id: 'jc', label: 'JazzCash · ****2351', sub: 'Default' },
                { id: 'ez', label: 'Easypaisa', sub: null },
                { id: 'cash', label: 'Pay organizer in cash', sub: 'Mark as fee due' },
              ].map((m, i) => (
                <button key={m.id} style={{
                  display: 'flex', alignItems: 'center', gap: 10, padding: '11px 14px',
                  borderRadius: 12, border: `1px solid ${i === 0 ? 'var(--ink)' : 'var(--hairline)'}`,
                  background: i === 0 ? 'var(--paper-2)' : 'var(--paper)',
                  cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
                }}>
                  <span style={{
                    width: 16, height: 16, borderRadius: 999,
                    border: `1.5px solid ${i === 0 ? 'var(--ink)' : 'var(--line)'}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {i === 0 && <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--ink)' }}/>}
                  </span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{m.label}</div>
                    {m.sub && <div style={{ fontSize: 10, color: 'var(--muted)' }}>{m.sub}</div>}
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}
        </>
        )}
        <div style={{ height: 16 }}/>
      </div>

      {!submitted && (
        <div style={{ flexShrink: 0, padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8 }}>
          {step > 1 && (
            <button onClick={() => setStep(s => s - 1)} style={{ padding: '12px 18px', borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>
              Back
            </button>
          )}
          <button
            disabled={(step === 1 && !accepted) || (step === 2 && !valid2)}
            onClick={() => {
              if (step < 3) setStep(s => s + 1);
              else setSubmitted(true);
            }}
            style={{
              flex: 1, padding: '12px 0', borderRadius: 12, border: 'none',
              background: ((step === 1 && !accepted) || (step === 2 && !valid2)) ? 'var(--paper-2)' : 'var(--ink)',
              color: ((step === 1 && !accepted) || (step === 2 && !valid2)) ? 'var(--muted)' : 'var(--paper)',
              fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
              cursor: ((step === 1 && !accepted) || (step === 2 && !valid2)) ? 'not-allowed' : 'pointer',
            }}>
            {step === 1 ? 'Continue · Pick squad' : step === 2 ? 'Continue · Review' : 'Pay & submit'}
          </button>
        </div>
      )}
    </div>
  );
}

window.CkTournamentRegister = CkTournamentRegister;

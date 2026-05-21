// Result.jsx — Match result screen with MOM picker (§4.10)

function Result() {
  const [mom, setMom] = React.useState(null);
  const [confirmed, setConfirmed] = React.useState(false);
  const [showShare, setShowShare] = React.useState(false);

  // Top-3 MOM auto-suggestion based on match impact
  const candidates = [
    {
      id: 'bk', name: 'Bilal Khan', team: 'Lions', avatar: 'BK',
      score: 92, headline: '64 (38)',
      lines: ['Top-scored', '8×4 · 2×6', 'SR 168.4'],
      role: 'Top order',
    },
    {
      id: 'tm', name: 'Tariq Mahmood', team: 'Lions', avatar: 'TM',
      score: 88, headline: '4/22',
      lines: ['Best figures', '4 ov · 1 maiden', 'Econ 5.5'],
      role: 'Pacer',
    },
    {
      id: 'as', name: 'Adeel Sheikh', team: 'Lions', avatar: 'AS',
      score: 71, headline: '3 ct, 28 (12)',
      lines: ['Captain · WK', 'Held the key catches', 'Cameo at the death'],
      role: 'Captain · WK',
    },
  ];

  const Bar = ({ pct, color = 'var(--ink)' }) => (
    <div style={{ width: '100%', height: 4, background: 'var(--hairline)', borderRadius: 999, overflow: 'hidden', marginTop: 6 }}>
      <div style={{ width: pct + '%', height: '100%', background: color, transition: 'width .3s' }} />
    </div>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>

      {/* Result hero */}
      <div style={{ padding: '14px 20px 22px', background: 'var(--ink)', color: 'var(--paper)', position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'inherit' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: '0.1em', color: 'oklch(0.72 0.01 80)' }}>SPRING CUP · QF · APR 26</div>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 14, marginBottom: 18 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.1em', marginBottom: 4 }}>WINNER</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 28, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1 }}>Lahore Lions</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 36, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.03em', marginTop: 4 }}>156<span style={{ color: 'oklch(0.72 0.01 80)', fontSize: 22 }}>/4 (20)</span></div>
          </div>
          <div style={{ width: 36, height: 36, borderRadius: 999, background: 'oklch(0.30 0.02 80)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'JetBrains Mono', fontSize: 11, color: 'oklch(0.78 0.14 80)' }}>vs</div>
          <div style={{ flex: 1, textAlign: 'right' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.72 0.01 80)', letterSpacing: '0.1em', marginBottom: 4 }}>—</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 600, letterSpacing: '-0.02em', lineHeight: 1, color: 'oklch(0.72 0.01 80)' }}>City Eagles</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 30, fontWeight: 600, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.03em', marginTop: 4, color: 'oklch(0.72 0.01 80)' }}>142<span style={{ fontSize: 20 }}>/9 (20)</span></div>
          </div>
        </div>

        <div style={{
          textAlign: 'center', padding: '10px 14px', borderRadius: 12,
          background: 'oklch(0.30 0.02 80)',
          fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 600, letterSpacing: '-0.015em',
        }}>
          Lions won by <span style={{ color: 'oklch(0.78 0.14 80)' }}>14 runs</span>
        </div>

        <div style={{ position: 'absolute', bottom: -22, left: 20, right: 20, height: 24, background: 'var(--paper)', borderRadius: '24px 24px 0 0' }} />
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '20px 20px 24px' }}>

        {/* Top performers strip */}
        <div className="ck-section-h" style={{ marginBottom: 10 }}>Top performers</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: 22 }}>
          {[
            { l: 'Most runs', name: 'Bilal Khan', v: '64 (38)' },
            { l: 'Best bowling', name: 'Tariq M.', v: '4/22' },
            { l: 'Most catches', name: 'Adeel S.', v: '3' },
          ].map((p, i) => (
            <div key={i} style={{ padding: 10, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 8.5, color: 'var(--muted)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{p.l}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', marginTop: 4 }}>{p.v}</div>
              <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{p.name}</div>
            </div>
          ))}
        </div>

        {/* MOM picker */}
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <div className="ck-section-h" style={{ color: 'var(--ink)' }}>Player of the Match</div>
          <div style={{ fontSize: 11, color: 'var(--muted)' }}>{confirmed ? 'Confirmed' : 'Auto-suggested · pick one'}</div>
        </div>

        {!confirmed && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {candidates.map(c => {
              const sel = mom === c.id;
              return (
                <button key={c.id} onClick={() => setMom(c.id)} disabled={confirmed} style={{
                  padding: 14, borderRadius: 14,
                  border: '2px solid ' + (sel ? 'var(--ink)' : 'var(--hairline)'),
                  background: sel ? 'var(--paper)' : 'var(--paper)',
                  cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                  position: 'relative',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div className="ck-avatar" style={{ width: 44, height: 44, fontSize: 14 }}>{c.avatar}</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                        <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, letterSpacing: '-0.015em' }}>{c.name}</div>
                        <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{c.headline}</div>
                      </div>
                      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>{c.role}</div>
                    </div>
                    <div style={{
                      width: 22, height: 22, borderRadius: 999,
                      border: '2px solid ' + (sel ? 'var(--ink)' : 'var(--hairline)'),
                      background: sel ? 'var(--ink)' : 'transparent',
                      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                    }}>
                      {sel && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--paper)" strokeWidth="3"><path d="M20 6 9 17l-5-5"/></svg>}
                    </div>
                  </div>
                  <div style={{ marginTop: 10, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                    {c.lines.map((ln, i) => (
                      <span key={i} style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.04em' }}>
                        {i > 0 && <span style={{ marginRight: 12, color: 'var(--hairline)' }}>·</span>}
                        {ln}
                      </span>
                    ))}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12 }}>
                    <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>IMPACT</span>
                    <div style={{ flex: 1 }}>
                      <Bar pct={c.score} color={sel ? 'var(--ink)' : 'var(--soft)'} />
                    </div>
                    <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, fontVariantNumeric: 'tabular-nums', minWidth: 22, textAlign: 'right' }}>{c.score}</span>
                  </div>
                </button>
              );
            })}
          </div>
        )}

        {confirmed && mom && (
          <div style={{ padding: 18, borderRadius: 16, background: 'var(--ink)', color: 'var(--paper)', position: 'relative', overflow: 'hidden' }}>
            <svg width="180" height="180" viewBox="0 0 180 180" style={{ position: 'absolute', right: -40, top: -40, opacity: 0.08 }}>
              <path d="m90 10 24 56 56 4-44 38 14 56-50-28-50 28 14-56-44-38 56-4Z" fill="oklch(0.78 0.14 80)" />
            </svg>
            <div style={{ position: 'relative' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.12em' }}>PLAYER OF THE MATCH</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 12 }}>
                <div className="ck-avatar" style={{ width: 56, height: 56, fontSize: 16, background: 'oklch(0.78 0.14 80)', color: 'var(--ink)', borderColor: 'transparent' }}>
                  {candidates.find(c => c.id === mom).avatar}
                </div>
                <div>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1 }}>{candidates.find(c => c.id === mom).name}</div>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 28, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em', marginTop: 4, color: 'oklch(0.78 0.14 80)' }}>{candidates.find(c => c.id === mom).headline}</div>
                </div>
              </div>
            </div>
          </div>
        )}

        <div style={{ display: 'flex', gap: 8, marginTop: 18 }}>
          {!confirmed ? (
            <>
              <button style={{ flex: 1, padding: '12px 0', borderRadius: 10, background: 'var(--paper-2)', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>View scorecard</button>
              <button onClick={() => mom && setConfirmed(true)} disabled={!mom} style={{
                flex: 2, padding: '12px 0', borderRadius: 10,
                background: mom ? 'var(--ink)' : 'var(--paper-2)',
                color: mom ? 'var(--paper)' : 'var(--muted)',
                border: 'none', fontFamily: 'inherit', fontWeight: 600, fontSize: 13,
                cursor: mom ? 'pointer' : 'not-allowed',
              }}>Confirm POM</button>
            </>
          ) : (
            <>
              <button onClick={() => { setConfirmed(false); }} style={{ flex: 1, padding: '12px 0', borderRadius: 10, background: 'var(--paper-2)', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Edit</button>
              <button onClick={() => setShowShare(true)} style={{ flex: 2, padding: '12px 0', borderRadius: 10, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Share to feed</button>
            </>
          )}
        </div>
      </div>

      {/* Share sheet */}
      {showShare && (
        <div onClick={() => setShowShare(false)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.5)', zIndex: 30, display: 'flex', alignItems: 'flex-end' }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--paper)', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: '18px 20px 24px' }}>
            <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 14px' }} />
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginBottom: 4 }}>Share result</div>
            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 14 }}>Posts as a Match Result card with stats and POM.</div>
            {[
              { l: 'Post to your feed', sub: '24 followers' },
              { l: 'Post on Lahore Lions page', sub: '142 followers' },
              { l: 'Tag in Spring Cup tournament', sub: 'organisers + bracket viewers' },
            ].map((o, i) => (
              <button key={i} onClick={() => setShowShare(false)} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                width: '100%', padding: '14px 0', border: 'none', borderBottom: i < 2 ? '1px solid var(--hairline)' : 'none',
                background: 'transparent', fontFamily: 'inherit', textAlign: 'left', cursor: 'pointer',
              }}>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{o.l}</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{o.sub}</div>
                </div>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

window.CkResult = Result;

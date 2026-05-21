// Team.jsx — Team profile (3 variants: roster, claim flow, manage)

function TeamHeader({ name = 'Lahore Lions', sub, established = 'Est. 2019', city = 'Lahore', wl = '14W · 2L', following, setFollowing, accent = 'oklch(0.62 0.19 28)' }) {
  return (
    <div style={{ position: 'relative' }}>
      {/* Banner */}
      <div style={{
        height: 110, background: accent, position: 'relative', overflow: 'hidden',
      }}>
        <svg width="100%" height="100%" viewBox="0 0 400 110" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0, opacity: 0.18 }}>
          <ellipse cx="200" cy="180" rx="180" ry="100" fill="none" stroke="white" strokeWidth="0.8"/>
          <ellipse cx="200" cy="180" rx="120" ry="65" fill="none" stroke="white" strokeWidth="0.8"/>
        </svg>
        <div style={{ position: 'absolute', top: 14, left: 16, right: 16, display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: 'white' }}>
          <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'inherit' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
        </div>
      </div>

      <div style={{ padding: '0 20px', marginTop: -36 }}>
        <div style={{
          width: 72, height: 72, borderRadius: 16,
          background: 'var(--paper)', border: '4px solid var(--paper)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 24, color: 'white',
          boxShadow: 'var(--shadow-1)',
        }}>
          <div style={{ width: '100%', height: '100%', borderRadius: 12, background: accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {name.split(' ').map(w => w[0]).slice(0,2).join('')}
          </div>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', marginTop: 10 }}>{name}</div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', marginTop: 4, letterSpacing: '0.04em' }}>
          {city} · {established} · {wl}
        </div>
        {sub && <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 8, lineHeight: 1.4 }}>{sub}</div>}

        <div style={{ display: 'flex', gap: 8, marginTop: 14, marginBottom: 14 }}>
          <button onClick={() => setFollowing && setFollowing(!following)} style={{
            flex: 1, padding: '10px 0', borderRadius: 10, border: 'none',
            background: following ? 'var(--paper-2)' : 'var(--ink)',
            color: following ? 'var(--ink)' : 'var(--paper)',
            fontWeight: 600, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer',
            border: following ? '1px solid var(--hairline)' : 'none',
          }}>{following ? 'Following ✓' : 'Follow'}</button>
          <button style={{ flex: 1, padding: '10px 0', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink)', fontWeight: 600, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer' }}>Share</button>
        </div>
      </div>
    </div>
  );
}

// =========================================================================
// Variant A — Roster, recent results, fixtures
// =========================================================================

function TeamA() {
  const [following, setFollowing] = React.useState(true);
  const [tab, setTab] = React.useState('Squad');

  const squad = [
    { name: 'Adeel Sheikh', role: 'Captain · WK', cap: true, pl: 142 },
    { name: 'Bilal Khan', role: 'Top-order bat', cap: false, pl: 138 },
    { name: 'Hassan Raza', role: 'All-rounder', cap: false, pl: 96 },
    { name: 'Tariq Mahmood', role: 'Pacer', cap: false, pl: 84 },
    { name: 'Imran Aslam', role: 'Spinner', cap: false, pl: 71 },
    { name: 'Zubair Khan', role: 'Middle-order', cap: false, pl: 62, claim: true },
    { name: 'Faraz Ali', role: 'Pacer', cap: false, pl: 58, claim: true },
    { name: 'Saad Iqbal', role: 'All-rounder', cap: false, pl: 41 },
  ];

  const results = [
    { vs: 'City Eagles', score: '156/4 (20)', oppScore: '142/9 (20)', won: true, m: '14R', date: '2d' },
    { vs: 'Defenders XI', score: '94 (18.2)', oppScore: '95/3 (16.1)', won: false, m: '7w', date: '5d' },
    { vs: 'Mohalla Kings', score: '178/6 (20)', oppScore: '134/8 (20)', won: true, m: '44R', date: '8d' },
    { vs: 'Royal XI', score: '127/5 (20)', oppScore: '129/2 (17.4)', won: false, m: '8w', date: '12d' },
  ];

  const fixtures = [
    { vs: 'Galle Boys', when: 'Sat Apr 26 · 4pm', at: 'Iqbal Ground' },
    { vs: 'Defenders XI', when: 'Wed Apr 30 · 6pm', at: 'Bagh-e-Jinnah' },
  ];

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TeamHeader sub="Punjab's grit. Built around 7 senior mohalla cricketers from Cantt." following={following} setFollowing={setFollowing} />

      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* Stats strip */}
        <div style={{ padding: '0 20px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 0, borderTop: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
          {[
            { l: 'Win rate', v: '87%', s: 'season' },
            { l: 'Avg score', v: '148', s: '20-over' },
            { l: 'Tournaments', v: '3', s: 'active' },
          ].map((s, i) => (
            <div key={i} style={{ padding: '12px 0', borderRight: i < 2 ? '1px solid var(--hairline)' : 'none', textAlign: i === 0 ? 'left' : 'center' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>{s.l}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', marginTop: 2 }}>{s.v}</div>
              <div style={{ fontSize: 10, color: 'var(--muted)' }}>{s.s}</div>
            </div>
          ))}
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', padding: '0 20px' }}>
          {['Squad', 'Results', 'Fixtures'].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: '12px 14px', fontSize: 13, fontWeight: 600,
              background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              color: tab === t ? 'var(--ink)' : 'var(--muted)',
              borderBottom: tab === t ? '2px solid var(--ink)' : '2px solid transparent',
              marginBottom: -1,
            }}>{t}</button>
          ))}
        </div>

        {tab === 'Squad' && (
          <div>
            <div style={{ padding: '12px 20px 6px', fontSize: 11, color: 'var(--muted)' }}>{squad.length} players · {squad.filter(p => p.claim).length} unclaimed</div>
            {squad.map((p, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 20px', borderTop: '1px solid var(--hairline)' }}>
                <div className={p.claim ? 'ck-avatar ck-placeholder' : 'ck-avatar'} style={{ width: 36, height: 36 }}>
                  {!p.claim && p.name.split(' ').map(w => w[0]).join('')}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                    {p.name}
                    {p.cap && <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, padding: '2px 5px', borderRadius: 4, background: 'var(--ink)', color: 'var(--paper)', letterSpacing: '0.08em' }}>C</span>}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--muted)' }}>{p.role}</div>
                </div>
                {p.claim ? (
                  <button style={{ padding: '6px 10px', borderRadius: 8, background: 'var(--cream)', color: 'oklch(0.30 0.02 80)', border: 'none', fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>Is this you?</button>
                ) : (
                  <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{p.pl} pld</div>
                )}
              </div>
            ))}
          </div>
        )}

        {tab === 'Results' && (
          <div>
            {results.map((r, i) => (
              <div key={i} style={{ padding: '14px 20px', borderTop: '1px solid var(--hairline)' }}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
                  <div style={{ fontSize: 13, color: 'var(--ink-2)' }}>vs {r.vs}</div>
                  <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{r.date}</div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 14 }}>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: r.won ? 'var(--ink)' : 'var(--muted)' }}>{r.score}</div>
                    <div style={{ fontSize: 10, color: 'var(--muted)' }}>Lions</div>
                  </div>
                  <div style={{ fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>vs</div>
                  <div>
                    <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: !r.won ? 'var(--ink)' : 'var(--muted)' }}>{r.oppScore}</div>
                    <div style={{ fontSize: 10, color: 'var(--muted)' }}>{r.vs}</div>
                  </div>
                </div>
                <div style={{ marginTop: 8, fontSize: 11, color: r.won ? 'var(--green)' : 'var(--red)', fontWeight: 600 }}>
                  {r.won ? `Won by ${r.m}` : `Lost by ${r.m}`}
                </div>
              </div>
            ))}
          </div>
        )}

        {tab === 'Fixtures' && (
          <div>
            {fixtures.map((f, i) => (
              <div key={i} style={{ padding: '14px 20px', borderTop: '1px solid var(--hairline)' }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 600 }}>vs {f.vs}</div>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', marginTop: 3 }}>{f.when} · {f.at}</div>
              </div>
            ))}
            <div style={{ padding: '14px 20px', borderTop: '1px solid var(--hairline)', display: 'flex', justifyContent: 'center' }}>
              <button style={{ padding: '8px 14px', background: 'transparent', color: 'var(--ink-2)', border: '1px solid var(--hairline)', borderRadius: 999, fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>+ Schedule a friendly</button>
            </div>
          </div>
        )}

        <div style={{ height: 20 }} />
      </div>
    </div>
  );
}

// =========================================================================
// Variant B — Claim flow (search-and-claim, Path B from §2.6)
// =========================================================================

function TeamB() {
  // Step: 0 = list w/ unclaimed, 1 = claim sheet open, 2 = submitted
  const [step, setStep] = React.useState(0);
  const [selectedClaim, setSelectedClaim] = React.useState(null);
  const [reason, setReason] = React.useState('I played for Lions in 2023, my old captain Adeel can verify.');

  const unclaimed = [
    { id: 'u1', name: 'Zubair Khan', role: 'Middle-order', matches: 62, since: '2022', last: 'Last seen Apr 14' },
    { id: 'u2', name: 'Faraz Ali', role: 'Pacer', matches: 58, since: '2023', last: 'Last seen Apr 21' },
    { id: 'u3', name: 'Saqib Mehmood', role: 'Spinner', matches: 34, since: '2024', last: 'Last seen Mar 03' },
  ];

  const sel = unclaimed.find(u => u.id === selectedClaim);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      <TeamHeader name="Lahore Lions" sub="Search the squad to find yourself, then send a claim. Your captain or manager will verify." accent="oklch(0.62 0.19 28)" />

      <div style={{ padding: '4px 20px 0' }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Unclaimed players · {unclaimed.length}</div>
        <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 14, lineHeight: 1.45 }}>
          These records were created by scorers but not yet linked to an account. If one of them is you, claim it to take ownership of your stats.
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 20px 20px' }}>
        {unclaimed.map(p => (
          <button key={p.id} onClick={() => { setSelectedClaim(p.id); setStep(1); }} style={{
            display: 'flex', alignItems: 'center', gap: 12, width: '100%', padding: 14,
            marginBottom: 8, borderRadius: 12, border: '1px dashed var(--line)',
            background: 'var(--paper)', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
          }}>
            <div className="ck-avatar ck-placeholder" style={{ width: 40, height: 40 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600 }}>{p.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{p.role} · {p.matches} matches · since {p.since}</div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', marginTop: 4, letterSpacing: '0.05em' }}>{p.last.toUpperCase()}</div>
            </div>
            <div style={{ padding: '5px 9px', borderRadius: 6, background: 'var(--cream)', fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: 700, color: 'var(--ink-2)', letterSpacing: '0.08em' }}>CLAIM</div>
          </button>
        ))}

        <div style={{ padding: 14, borderRadius: 12, background: 'var(--paper-2)', marginTop: 4 }}>
          <div style={{ fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5 }}>
            <strong style={{ fontFamily: 'Inter Tight' }}>Don't see yourself?</strong> Ask your manager to add you, or create a new player profile linked to this team.
          </div>
          <button style={{ marginTop: 10, padding: '8px 12px', borderRadius: 8, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>+ Create profile</button>
        </div>
      </div>

      {/* Claim sheet */}
      {step === 1 && sel && (
        <div onClick={() => setStep(0)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.45)', zIndex: 30, display: 'flex', alignItems: 'flex-end' }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--paper)', borderTopLeftRadius: 22, borderTopRightRadius: 22, padding: '18px 20px 24px' }}>
            <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 14px' }} />
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em' }}>CLAIM PLAYER · LAHORE LIONS</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 24, fontWeight: 700, letterSpacing: '-0.025em', marginTop: 6 }}>Are you {sel.name}?</div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 6, lineHeight: 1.45 }}>We'll send a request to the team manager to verify. You'll get notified within 24h.</div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 0, marginTop: 18, padding: 14, borderRadius: 12, background: 'var(--paper-2)' }}>
              {[
                { l: 'Matches', v: sel.matches },
                { l: 'Since', v: sel.since },
                { l: 'Role', v: sel.role.split(' ')[0] },
              ].map((s, i) => (
                <div key={i} style={{ borderRight: i < 2 ? '1px solid var(--hairline)' : 'none', paddingLeft: i > 0 ? 12 : 0 }}>
                  <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>{s.l.toUpperCase()}</div>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums', marginTop: 2 }}>{s.v}</div>
                </div>
              ))}
            </div>

            <label style={{ display: 'block', marginTop: 16 }}>
              <div className="ck-label">Why this is you</div>
              <textarea value={reason} onChange={e => setReason(e.target.value)} className="ck-input" style={{ minHeight: 70, resize: 'none', fontSize: 13 }} />
            </label>

            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              <button onClick={() => setStep(0)} style={{ flex: 1, padding: '12px 0', borderRadius: 10, background: 'var(--paper-2)', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Cancel</button>
              <button onClick={() => setStep(2)} style={{ flex: 2, padding: '12px 0', borderRadius: 10, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Send claim request</button>
            </div>
          </div>
        </div>
      )}

      {/* Submitted state */}
      {step === 2 && sel && (
        <div onClick={() => { setStep(0); setSelectedClaim(null); }} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.55)', zIndex: 30, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', maxWidth: 320, background: 'var(--paper)', borderRadius: 18, padding: 24, textAlign: 'center' }}>
            <div style={{ width: 56, height: 56, borderRadius: 999, background: 'var(--green-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 14px' }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="oklch(0.36 0.10 148)" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>
            </div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em' }}>Claim sent</div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 8, lineHeight: 1.45 }}>
              Adeel Sheikh (captain) will get a notification to verify you as <strong>{sel.name}</strong>. We'll let you know.
            </div>
            <button onClick={() => { setStep(0); setSelectedClaim(null); }} style={{ marginTop: 18, padding: '12px 22px', background: 'var(--ink)', color: 'var(--paper)', border: 'none', borderRadius: 10, fontFamily: 'inherit', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Done</button>
          </div>
        </div>
      )}
    </div>
  );
}

// =========================================================================
// Variant C — Manage team (manager's view: join requests, claim approvals)
// =========================================================================

function TeamC() {
  const [requests, setRequests] = React.useState([
    { id: 'r1', kind: 'claim', name: 'Hassan A.', sub: 'wants to claim Zubair Khan · cited 2023 season', avatar: 'HA', date: '4h' },
    { id: 'r2', kind: 'join', name: 'Rashid Iqbal', sub: 'wants to join · pacer · @rashid_i', avatar: 'RI', date: '1d' },
    { id: 'r3', kind: 'claim', name: 'Anonymous', sub: 'wants to claim Faraz Ali · phone +92 *** **34', avatar: 'A', date: '2d' },
    { id: 'r4', kind: 'join', name: 'Mansoor S.', sub: 'wants to join · all-rounder', avatar: 'MS', date: '3d' },
  ]);
  const [decision, setDecision] = React.useState({}); // id -> 'approve'|'deny'

  const decide = (id, action) => setDecision(d => ({ ...d, [id]: action }));

  const pending = requests.filter(r => !decision[r.id]);
  const decided = requests.filter(r => decision[r.id]);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TeamHeader name="Lahore Lions" sub="Manager view · Adeel Sheikh" />

      <div style={{ padding: '0 20px 12px', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {[
            { l: 'Pending', v: pending.length, hl: pending.length > 0 },
            { l: 'Squad', v: 24 },
            { l: 'Active', v: 18 },
          ].map((s, i) => (
            <div key={i} style={{
              flex: 1, padding: 12, borderRadius: 10,
              background: s.hl ? 'oklch(0.94 0.05 28 / 0.5)' : 'var(--paper-2)',
              border: '1px solid ' + (s.hl ? 'var(--red-soft)' : 'var(--hairline)'),
            }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: s.hl ? 'var(--red)' : 'var(--muted)', letterSpacing: '0.08em' }}>{s.l.toUpperCase()}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', marginTop: 2 }}>{s.v}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '14px 20px 20px' }}>
        <div className="ck-section-h" style={{ marginBottom: 10 }}>Pending requests · {pending.length}</div>

        {pending.length === 0 ? (
          <div style={{ padding: '28px 16px', textAlign: 'center', color: 'var(--muted)', fontSize: 13, background: 'var(--paper-2)', borderRadius: 12 }}>
            All caught up. ✓
          </div>
        ) : pending.map(r => (
          <div key={r.id} style={{ padding: 14, borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)', marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <div className="ck-avatar" style={{ width: 38, height: 38 }}>{r.avatar}</div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{r.name}</span>
                  <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, padding: '2px 5px', borderRadius: 4, background: r.kind === 'claim' ? 'var(--cream)' : 'var(--green-soft)', color: r.kind === 'claim' ? 'var(--ink-2)' : 'oklch(0.36 0.10 148)', letterSpacing: '0.08em' }}>
                    {r.kind === 'claim' ? 'CLAIM' : 'JOIN'}
                  </span>
                </div>
                <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.4 }}>{r.sub}</div>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', marginTop: 4 }}>{r.date} ago</div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
              <button onClick={() => decide(r.id, 'deny')} style={{ flex: 1, padding: '8px 0', borderRadius: 8, background: 'var(--paper-2)', color: 'var(--ink-2)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontWeight: 600, fontSize: 12, cursor: 'pointer' }}>Deny</button>
              <button onClick={() => decide(r.id, 'view')} style={{ flex: 1, padding: '8px 0', borderRadius: 8, background: 'var(--paper)', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontWeight: 600, fontSize: 12, cursor: 'pointer' }}>View profile</button>
              <button onClick={() => decide(r.id, 'approve')} style={{ flex: 1.4, padding: '8px 0', borderRadius: 8, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontWeight: 600, fontSize: 12, cursor: 'pointer' }}>Approve</button>
            </div>
          </div>
        ))}

        {decided.length > 0 && (
          <>
            <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 10 }}>Just decided</div>
            {decided.map(r => (
              <div key={r.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 0', fontSize: 12, color: 'var(--muted)', borderTop: '1px solid var(--hairline)' }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={decision[r.id] === 'approve' ? 'var(--green)' : 'var(--muted)'} strokeWidth="2.2">
                  {decision[r.id] === 'approve' ? <path d="M20 6 9 17l-5-5"/> : <><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/></>}
                </svg>
                <span style={{ flex: 1 }}>{decision[r.id] === 'approve' ? 'Approved' : decision[r.id] === 'deny' ? 'Denied' : 'Viewing'} · {r.name}</span>
                <button onClick={() => setDecision(d => { const n = { ...d }; delete n[r.id]; return n; })} style={{ background: 'transparent', border: 'none', fontSize: 11, color: 'var(--ink)', cursor: 'pointer', fontFamily: 'inherit', fontWeight: 600 }}>Undo</button>
              </div>
            ))}
          </>
        )}
      </div>
    </div>
  );
}

window.CkTeamA = TeamA;
window.CkTeamB = TeamB;
window.CkTeamC = TeamC;

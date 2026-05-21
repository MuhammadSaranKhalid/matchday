// TeamCreate.jsx — Create a new team
// 6 steps: Basics → Identity → Home → Crest → Squad → Review → Done
// Squad has working sub-flows (search · SMS invite · unclaimed).
// Reuses design tokens from styles.css. No external deps.

function CkTeamCreate({ initialStep = 1 } = {}) {
  const [step, setStep] = React.useState(initialStep);
  const [done, setDone] = React.useState(initialStep === 'done');
  const [team, setTeam] = React.useState({
    name: 'Lahore Lions',
    type: 'Club',
    primary: 'oklch(0.36 0.10 148)',
    secondary: 'oklch(0.985 0.008 85)',
    monogram: 'LL',
    crestStyle: 'Monogram',
    city: 'Lahore',
    area: 'Model Town',
    homeGround: 'Gaddafi B Ground',
    founded: '2019',
    privacy: 'Public',
    maxSize: 25,
    invites: [
      { id: 'p1', name: 'Bilal Ahmed',   role: 'Captain',       status: 'app',       detail: '@bilal · joined 2024' },
      { id: 'p2', name: 'Adeel Sheikh',  role: 'Wicket-Keeper', status: 'app',       detail: '@adeelk · joined 2024' },
      { id: 'p3', name: 'Faraz Khan',    role: 'Player',        status: 'sms',       detail: '+92 300 4521 ··· · invite SMS' },
      { id: 'p4', name: 'Hamza Tariq',   role: 'Player',        status: 'unclaimed', detail: 'Placeholder · unclaimed' },
    ],
  });

  const setT = (patch) => setTeam(prev => ({ ...prev, ...patch }));

  const STEPS = ['Basics', 'Identity', 'Home', 'Crest', 'Squad', 'Review'];
  const isLast = step === STEPS.length;

  // ── Done / success terminal state ────────────────
  if (done) return <TCDone team={team} onAgain={() => { setDone(false); setStep(1); }} />;

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 18px 4px', flexShrink: 0 }}>
        <button onClick={() => step > 1 ? setStep(step - 1) : null}
          style={{ background: 'transparent', border: 'none', padding: 6, cursor: step > 1 ? 'pointer' : 'default', opacity: step > 1 ? 1 : 0.3 }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="var(--ink)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>
          NEW TEAM · {step}/{STEPS.length}
        </span>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em' }}>
          SAVE & EXIT
        </button>
      </div>

      {/* Progress bar (segmented) */}
      <div style={{ padding: '6px 18px 14px', flexShrink: 0 }}>
        <div style={{ display: 'flex', gap: 4 }}>
          {STEPS.map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 999,
              background: i < step ? 'var(--ink)' : 'var(--paper-2)',
            }} />
          ))}
        </div>
        <div style={{ marginTop: 8, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em' }}>
          STEP {step} · {STEPS[step-1].toUpperCase()}
        </div>
      </div>

      {/* Body — scrolling step pane */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {step === 1 && <TCStepBasics team={team} setT={setT} />}
        {step === 2 && <TCStepIdentity team={team} setT={setT} />}
        {step === 3 && <TCStepHome team={team} setT={setT} />}
        {step === 4 && <TCStepCrest team={team} setT={setT} />}
        {step === 5 && <TCStepSquad team={team} setT={setT} />}
        {step === 6 && <TCStepReview team={team} jumpTo={setStep} />}
        <div style={{ height: 30 }} />
      </div>

      {/* Sticky footer */}
      <div style={{ flexShrink: 0, padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8 }}>
        {step > 1 && (
          <button onClick={() => setStep(step - 1)} style={{
            padding: '14px 18px', borderRadius: 12, border: '1px solid var(--hairline)',
            background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 14, cursor: 'pointer', color: 'var(--ink)',
          }}>Back</button>
        )}
        <button onClick={() => isLast ? setDone(true) : setStep(step + 1)} style={{
          flex: 1, padding: '14px 0', borderRadius: 12, border: 'none',
          background: 'var(--ink)', color: 'var(--paper)',
          fontFamily: 'Inter', fontWeight: 600, fontSize: 15, cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          {isLast ? 'Create team' : (step === 5 ? 'Review' : 'Continue')}
          {!isLast && (
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
          )}
          {isLast && (
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          )}
        </button>
      </div>
    </div>
  );
}

// ─── Step 1 — Basics ────────────────────────────────
function TCStepBasics({ team, setT }) {
  return (
    <div style={{ padding: '4px 18px 0' }}>
      <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 18px', lineHeight: 1.1 }}>
        Name your team.
      </h1>

      <div style={{ marginBottom: 16 }}>
        <label className="ck-label">Team name</label>
        <input className="ck-input" value={team.name} onChange={e => setT({ name: e.target.value, monogram: monogramOf(e.target.value) })} />
        <div style={{ marginTop: 6, fontSize: 11, color: 'var(--muted)', display: 'flex', justifyContent: 'space-between' }}>
          <span>3–50 characters · we'll use first letters as a crest</span>
          <span className="ck-mono">{team.name.length}/50</span>
        </div>
      </div>

      <div style={{ marginBottom: 16 }}>
        <label className="ck-label">Team type</label>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {[
            { v: 'Club',     d: 'Persistent club with branding' },
            { v: 'Village',  d: 'Mohalla / community team' },
            { v: 'Casual',   d: 'One-off for a tournament' },
            { v: 'Corporate',d: 'Office / department' },
            { v: 'School',   d: 'School team' },
            { v: 'University', d: 'Uni team' },
          ].map(opt => (
            <button key={opt.v} onClick={() => setT({ type: opt.v })} style={{
              padding: '12px 10px', borderRadius: 12, cursor: 'pointer', textAlign: 'left',
              border: team.type === opt.v ? '1.5px solid var(--ink)' : '1px solid var(--hairline)',
              background: team.type === opt.v ? 'var(--paper)' : 'var(--surface)',
              fontFamily: 'inherit',
            }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, color: 'var(--ink)' }}>{opt.v}</div>
              <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 3, lineHeight: 1.3 }}>{opt.d}</div>
            </button>
          ))}
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <div>
          <label className="ck-label">Founded</label>
          <input className="ck-input" value={team.founded} onChange={e => setT({ founded: e.target.value })} placeholder="2019" />
        </div>
        <div>
          <label className="ck-label">Privacy</label>
          <div style={{ display: 'flex', gap: 6 }}>
            {['Public', 'Private'].map(p => (
              <button key={p} onClick={() => setT({ privacy: p })} style={{
                flex: 1, padding: '14px 0', borderRadius: 12,
                border: team.privacy === p ? '1.5px solid var(--ink)' : '1px solid var(--hairline)',
                background: team.privacy === p ? 'var(--paper)' : 'var(--surface)',
                fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: 'var(--ink)', cursor: 'pointer',
              }}>{p}</button>
            ))}
          </div>
        </div>
      </div>

      <div style={{ marginTop: 18, padding: 12, background: 'var(--paper-2)', borderRadius: 12, fontSize: 11, color: 'var(--ink-2)', display: 'flex', gap: 10, alignItems: 'flex-start', lineHeight: 1.4 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.6" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
        <span><strong style={{ color: 'var(--ink)' }}>Private</strong> teams hide their roster from non-members and are invite-only. You can change this later.</span>
      </div>
    </div>
  );
}

// ─── Step 2 — Identity (colors) ────────────────────
function TCStepIdentity({ team, setT }) {
  const palette = [
    'oklch(0.36 0.10 148)', 'oklch(0.42 0.16 28)', 'oklch(0.32 0.14 250)',
    'oklch(0.30 0.06 70)',  'oklch(0.45 0.13 50)', 'oklch(0.40 0.14 320)',
    'oklch(0.50 0.13 180)', 'oklch(0.40 0.15 20)', 'oklch(0.18 0.02 80)',
    'oklch(0.62 0.19 28)',  'oklch(0.78 0.14 80)', 'oklch(0.94 0.05 90)',
  ];
  return (
    <div style={{ padding: '4px 18px 0' }}>
      <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 18px', lineHeight: 1.1 }}>
        Your colors.
      </h1>

      {/* Live preview */}
      <div style={{
        height: 168, borderRadius: 18, padding: 22, position: 'relative', overflow: 'hidden',
        background: team.primary, color: textOn(team.primary), marginBottom: 22,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: team.secondary, color: textOn(team.secondary),
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 17, letterSpacing: '-0.02em',
          }}>{team.monogram}</div>
          <div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em' }}>{team.name}</div>
            <div style={{ fontSize: 11, opacity: 0.7, fontFamily: 'JetBrains Mono', letterSpacing: '0.06em' }}>{team.type.toUpperCase()} · {team.city.toUpperCase()}</div>
          </div>
        </div>
        <div style={{ position: 'absolute', right: -40, bottom: -44, opacity: 0.18 }}>
          <svg width="200" height="200" viewBox="0 0 200 200">
            <ellipse cx="100" cy="100" rx="95" ry="60" stroke="currentColor" strokeWidth="1" fill="none"/>
            <ellipse cx="100" cy="100" rx="55" ry="34" stroke="currentColor" strokeWidth="1" fill="none"/>
            <rect x="92" y="70" width="16" height="60" stroke="currentColor" strokeWidth="1" fill="none"/>
          </svg>
        </div>
        <div style={{ position: 'absolute', left: 22, bottom: 18, fontSize: 11, fontFamily: 'JetBrains Mono', opacity: 0.7, letterSpacing: '0.06em' }}>
          PREVIEW · KIT
        </div>
      </div>

      <div style={{ marginBottom: 18 }}>
        <label className="ck-label">Primary</label>
        <ColorGrid palette={palette} value={team.primary} onChange={v => setT({ primary: v })} />
      </div>

      <div style={{ marginBottom: 12 }}>
        <label className="ck-label">Secondary / accent</label>
        <ColorGrid palette={palette} value={team.secondary} onChange={v => setT({ secondary: v })} />
      </div>

      <div>
        <label className="ck-label">Monogram</label>
        <input className="ck-input" value={team.monogram} maxLength={3}
          onChange={e => setT({ monogram: e.target.value.toUpperCase() })}
          style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', textAlign: 'center', maxWidth: 120 }} />
      </div>
    </div>
  );
}

function ColorGrid({ palette, value, onChange }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 8 }}>
      {palette.map(c => (
        <button key={c} onClick={() => onChange(c)} style={{
          aspectRatio: '1', borderRadius: 12, background: c, cursor: 'pointer',
          border: value === c ? '2.5px solid var(--ink)' : '1px solid var(--hairline)',
          padding: 0, position: 'relative',
        }}>
          {value === c && (
            <span style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={textOn(c)} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </span>
          )}
        </button>
      ))}
    </div>
  );
}

// ─── Step 3 — Home / Location ───────────────────────
function TCStepHome({ team, setT }) {
  return (
    <div style={{ padding: '4px 18px 0' }}>
      <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 6px', lineHeight: 1.1 }}>
        Where do you play?
      </h1>
      <p style={{ fontSize: 13, color: 'var(--muted)', margin: '0 0 22px', lineHeight: 1.4 }}>
        Helps players nearby find you and disambiguates teams with similar names.
      </p>

      <div style={{ marginBottom: 14 }}>
        <label className="ck-label">City</label>
        <input className="ck-input" value={team.city} onChange={e => setT({ city: e.target.value })} />
      </div>

      <div style={{ marginBottom: 14 }}>
        <label className="ck-label">Area / mohalla / locality</label>
        <input className="ck-input" value={team.area} onChange={e => setT({ area: e.target.value })} placeholder="Model Town" />
      </div>

      <div style={{ marginBottom: 22 }}>
        <label className="ck-label">Home ground (optional)</label>
        <input className="ck-input" value={team.homeGround} onChange={e => setT({ homeGround: e.target.value })} placeholder="Gaddafi B Ground" />
        <div style={{ marginTop: 6, fontSize: 11, color: 'var(--muted)' }}>
          Free text — no need to be a registered venue.
        </div>
      </div>

      {/* Map placeholder */}
      <div style={{
        height: 132, borderRadius: 14, position: 'relative', overflow: 'hidden',
        background:
          'repeating-linear-gradient(135deg, var(--paper-2) 0 8px, var(--paper) 8px 16px)',
        border: '1px solid var(--hairline)',
      }}>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--red)" strokeWidth="2"><path d="M12 22s8-7.5 8-13a8 8 0 1 0-16 0c0 5.5 8 13 8 13z"/><circle cx="12" cy="9" r="3" fill="var(--red)"/></svg>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600 }}>{team.area}, {team.city}</div>
          <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.06em' }}>MAP PREVIEW</div>
        </div>
      </div>
    </div>
  );
}

// ─── Step 4 — Crest ─────────────────────────────────
function TCStepCrest({ team, setT }) {
  const styles = ['Monogram', 'Initials', 'Shield', 'Custom upload'];
  return (
    <div style={{ padding: '4px 18px 0' }}>
      <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 18px', lineHeight: 1.1 }}>
        Pick a crest.
      </h1>

      {/* Big crest preview */}
      <div style={{
        margin: '0 auto 18px', width: 132, height: 132, borderRadius: 28,
        background: team.primary, color: textOn(team.primary),
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 56, letterSpacing: '-0.04em',
        position: 'relative', overflow: 'hidden',
      }}>
        {team.crestStyle === 'Shield' && (
          <svg width="100%" height="100%" viewBox="0 0 100 100" style={{ position: 'absolute', inset: 0 }}>
            <path d="M50 5 L92 18 L88 60 Q88 80 50 95 Q12 80 12 60 L8 18 Z" fill="none" stroke={textOn(team.primary)} strokeWidth="2"/>
          </svg>
        )}
        <span style={{ position: 'relative', zIndex: 1 }}>{team.crestStyle === 'Initials' ? team.monogram[0] : team.monogram}</span>
      </div>

      {/* Style picker */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8, marginBottom: 16 }}>
        {styles.map(s => (
          <button key={s} onClick={() => setT({ crestStyle: s })} style={{
            padding: '14px 10px', borderRadius: 12, cursor: 'pointer', textAlign: 'left',
            border: team.crestStyle === s ? '1.5px solid var(--ink)' : '1px solid var(--hairline)',
            background: team.crestStyle === s ? 'var(--paper)' : 'var(--surface)',
            fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: 'var(--ink)',
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <CrestIcon kind={s} primary={team.primary} mono={team.monogram} />
            <span>{s}</span>
          </button>
        ))}
      </div>

      <div style={{ padding: 12, background: 'var(--paper-2)', borderRadius: 12, fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.4 }}>
        Crest auto-syncs with your team colors. You can replace it with a custom upload anytime.
      </div>
    </div>
  );
}

function CrestIcon({ kind, primary, mono = 'LL' }) {
  const fg = textOn(primary);
  const wrap = (children) => (
    <div style={{ width: 26, height: 26, borderRadius: 7, background: primary, color: fg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>{children}</div>
  );
  if (kind === 'Monogram') return wrap(mono.slice(0, 2));
  if (kind === 'Initials') return wrap(mono[0] || 'L');
  if (kind === 'Shield') return wrap(
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={fg} strokeWidth="2"><path d="M12 2 L21 5 L20 13 Q20 18 12 22 Q4 18 4 13 L3 5 Z"/></svg>
  );
  return wrap(
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={fg} strokeWidth="2"><path d="M12 5v14M5 12h14"/></svg>
  );
}

// ─── Step 5 — Squad / Invites ──────────────────────
function TCStepSquad({ team, setT }) {
  const [mode, setMode] = React.useState('list'); // list | picker | search | sms | unclaimed
  const removeInvite = (id) => setT({ invites: team.invites.filter(p => p.id !== id) });
  const cycleRole = (id) => {
    const ROLES = ['Player', 'Captain', 'Vice-Captain', 'Wicket-Keeper'];
    setT({ invites: team.invites.map(p => p.id === id ? { ...p, role: ROLES[(ROLES.indexOf(p.role) + 1) % ROLES.length] } : p) });
  };
  const addPlayer = (newP) => {
    setT({ invites: [...team.invites, { ...newP, id: 'p' + (team.invites.length + 1) + Date.now() }] });
    setMode('list');
  };

  if (mode === 'search')    return <AddBySearch onCancel={() => setMode('list')} onAdd={addPlayer} />;
  if (mode === 'sms')       return <AddByInvite  onCancel={() => setMode('list')} onAdd={addPlayer} />;
  if (mode === 'unclaimed') return <AddUnclaimed onCancel={() => setMode('list')} onAdd={addPlayer} />;

  return (
    <div style={{ padding: '4px 18px 0' }}>
      <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 4px', lineHeight: 1.1 }}>
        Add your players.
      </h1>
      <p style={{ fontSize: 13, color: 'var(--muted)', margin: '0 0 18px', lineHeight: 1.4 }}>
        Skip if you want — you can build the squad later. Up to {team.maxSize} active members.
      </p>

      {/* Roster summary chip */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 12, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em' }}>
        <span>SQUAD · {team.invites.length}/{team.maxSize}</span>
        <span style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
        <span style={{ color: 'var(--ink)' }}>{team.invites.filter(p => p.status === 'app').length} ON APP</span>
        <span>·</span>
        <span style={{ color: 'var(--amber)' }}>{team.invites.filter(p => p.status === 'sms').length} SMS</span>
        <span>·</span>
        <span style={{ color: 'var(--muted)' }}>{team.invites.filter(p => p.status === 'unclaimed').length} UNCLAIMED</span>
      </div>

      {/* Invite list */}
      {team.invites.length > 0 && (
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 12 }}>
          {team.invites.map((p, i) => (
            <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
              <PlayerStatusDot status={p.status} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: 'var(--ink)' }}>{p.name}</span>
                  {p.role !== 'Player' && (
                    <span className="ck-chip" style={{ padding: '1px 6px', fontSize: 9, background: 'var(--cream)', color: 'var(--ink-2)', borderColor: 'transparent', letterSpacing: '0.06em' }}>
                      {p.role === 'Wicket-Keeper' ? 'WK' : p.role.toUpperCase()}
                    </span>
                  )}
                </div>
                <div style={{ fontSize: 10.5, color: 'var(--muted)', marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>{p.detail}</div>
              </div>
              <button onClick={() => cycleRole(p.id)} style={{ background: 'transparent', border: '1px solid var(--hairline)', borderRadius: 8, padding: '5px 8px', cursor: 'pointer', fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--ink-2)', letterSpacing: '0.06em' }}>
                ROLE
              </button>
              <button onClick={() => removeInvite(p.id)} style={{ background: 'transparent', border: 'none', padding: 4, cursor: 'pointer', color: 'var(--muted)' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 6l12 12M18 6L6 18"/></svg>
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Add row */}
      {mode !== 'picker' ? (
        <button onClick={() => setMode('picker')} style={{
          width: '100%', padding: 14, borderRadius: 12, cursor: 'pointer',
          border: '1px dashed var(--line)', background: 'transparent',
          color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M5 12h14"/></svg>
          Add a player
        </button>
      ) : (
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: 14 }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 4 }}>HOW TO ADD</div>
          {[
            { k: 'search',    t: 'Search registered users',    d: 'They get an invite — must accept', dot: 'app' },
            { k: 'sms',       t: 'Invite by phone or email',   d: 'We SMS a link to download Circk',  dot: 'sms' },
            { k: 'unclaimed', t: 'Add as unclaimed',           d: 'Just a name — for stats now, claim later', dot: 'unclaimed' },
          ].map((opt, i) => (
            <button key={opt.k} onClick={() => setMode(opt.k)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '14px 0',
              background: 'transparent', border: 'none', borderTop: i ? '1px solid var(--hairline)' : 'none', cursor: 'pointer',
              width: '100%', textAlign: 'left',
            }}>
              <PlayerStatusDot status={opt.dot} />
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{opt.t}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{opt.d}</div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="M9 18l6-6-6-6"/></svg>
            </button>
          ))}
          <button onClick={() => setMode('list')} style={{ marginTop: 6, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', background: 'transparent', border: 'none', cursor: 'pointer', letterSpacing: '0.08em' }}>CANCEL</button>
        </div>
      )}
    </div>
  );
}

// ── Add sub-flow: search registered users ────────────
function AddBySearch({ onCancel, onAdd }) {
  const [q, setQ] = React.useState('');
  const allUsers = [
    { name: 'Usman Riaz',     handle: '@usmanr',   meta: 'All-rounder · Lahore · 32 matches' },
    { name: 'Imran Akhtar',   handle: '@imrana',   meta: 'Bowler · Lahore · 18 matches' },
    { name: 'Shahid Iqbal',   handle: '@shahid_i', meta: 'Batter · Karachi · 41 matches' },
    { name: 'Junaid Ali',     handle: '@junaid',   meta: 'Wicket-keeper · Lahore · 22 matches' },
    { name: 'Tariq Mehmood',  handle: '@tariqm',   meta: 'All-rounder · Multan · 15 matches' },
    { name: 'Saad Anwar',     handle: '@saad',     meta: 'Bowler · Lahore · 9 matches' },
  ];
  const matches = q.trim() === '' ? allUsers.slice(0, 4)
    : allUsers.filter(u => (u.name + u.handle).toLowerCase().includes(q.toLowerCase()));

  return (
    <SubFlow title="Search players" subtitle="Find anyone already on Circk. They'll get an invite to accept." onCancel={onCancel}>
      {/* Search bar */}
      <div style={{ position: 'relative', marginBottom: 14 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" style={{ position: 'absolute', left: 14, top: 16 }}><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
        <input className="ck-input" autoFocus placeholder="Name or @username" value={q} onChange={e => setQ(e.target.value)} style={{ paddingLeft: 38 }} />
      </div>

      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 8 }}>
        {q ? 'RESULTS' : 'SUGGESTED · NEAR YOU'}
      </div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        {matches.length === 0 && (
          <div style={{ padding: '22px 14px', textAlign: 'center', color: 'var(--muted)', fontSize: 13 }}>
            No one matched “{q}”. Try inviting them by phone instead.
          </div>
        )}
        {matches.map((u, i) => (
          <div key={u.handle} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
            <div className="ck-avatar">{u.name.split(' ').map(w => w[0]).slice(0, 2).join('')}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{u.name}</div>
              <div style={{ fontSize: 10.5, color: 'var(--muted)', fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>{u.handle} · {u.meta}</div>
            </div>
            <button onClick={() => onAdd({ name: u.name, role: 'Player', status: 'app', detail: u.handle + ' · invite sent' })} style={{
              padding: '7px 12px', borderRadius: 999, border: 'none', background: 'var(--ink)', color: 'var(--paper)',
              fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
            }}>Invite</button>
          </div>
        ))}
      </div>
    </SubFlow>
  );
}

// ── Add sub-flow: invite by phone / email ────────────
function AddByInvite({ onCancel, onAdd }) {
  const [name, setName] = React.useState('');
  const [contact, setContact] = React.useState('');
  const [via, setVia] = React.useState('phone');
  const valid = name.trim().length >= 2 && contact.trim().length >= 5;

  return (
    <SubFlow title="Invite by phone or email" subtitle="We'll text or email a download link. They claim their profile when they sign up." onCancel={onCancel}>
      <div style={{ display: 'flex', gap: 6, padding: 4, background: 'var(--paper-2)', borderRadius: 12, marginBottom: 14 }}>
        {[{ k: 'phone', l: 'Phone' }, { k: 'email', l: 'Email' }].map(t => (
          <button key={t.k} onClick={() => setVia(t.k)} style={{
            flex: 1, padding: '10px 0', borderRadius: 10, border: 'none',
            background: via === t.k ? 'var(--paper)' : 'transparent',
            boxShadow: via === t.k ? 'var(--shadow-1)' : 'none',
            fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: via === t.k ? 'var(--ink)' : 'var(--muted)', cursor: 'pointer',
          }}>{t.l}</button>
        ))}
      </div>

      <div style={{ marginBottom: 14 }}>
        <label className="ck-label">Their name</label>
        <input className="ck-input" placeholder="e.g. Faraz Khan" value={name} onChange={e => setName(e.target.value)} autoFocus />
      </div>

      <div style={{ marginBottom: 18 }}>
        <label className="ck-label">{via === 'phone' ? 'Phone number' : 'Email address'}</label>
        <input className="ck-input"
          inputMode={via === 'phone' ? 'tel' : 'email'}
          placeholder={via === 'phone' ? '+92 300 1234 567' : 'name@example.com'}
          value={contact} onChange={e => setContact(e.target.value)} />
      </div>

      <div style={{ padding: 12, background: 'var(--paper-2)', borderRadius: 12, fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.5, marginBottom: 18 }}>
        We'll send <strong style={{ color: 'var(--ink)' }}>one</strong> {via === 'phone' ? 'SMS' : 'email'} with a download link. Their name will appear in your squad as <em>“invite pending”</em> until they accept. Stats added in matches before they accept will transfer over automatically.
      </div>

      <SubmitRow disabled={!valid} label={via === 'phone' ? 'Send SMS invite' : 'Send email invite'} onCancel={onCancel}
        onSubmit={() => onAdd({
          name: name || 'New player',
          role: 'Player',
          status: 'sms',
          detail: contact + ' · invite ' + (via === 'phone' ? 'SMS' : 'email'),
        })}
      />
    </SubFlow>
  );
}

// ── Add sub-flow: unclaimed placeholder ──────────────
function AddUnclaimed({ onCancel, onAdd }) {
  const [name, setName] = React.useState('');
  const [role, setRole] = React.useState('Player');
  const [batting, setBatting] = React.useState('Right');
  const [bowling, setBowling] = React.useState('Right-arm fast');
  const valid = name.trim().length >= 2;

  return (
    <SubFlow title="Add as unclaimed" subtitle="A placeholder you can credit stats to. They can claim it later when they join Circk." onCancel={onCancel}>
      <div style={{ marginBottom: 14 }}>
        <label className="ck-label">Player name</label>
        <input className="ck-input" placeholder="e.g. Hamza Tariq" value={name} onChange={e => setName(e.target.value)} autoFocus />
      </div>

      <div style={{ marginBottom: 14 }}>
        <label className="ck-label">Role</label>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {['Player', 'Captain', 'Vice-Captain', 'Wicket-Keeper'].map(r => (
            <button key={r} onClick={() => setRole(r)} style={{
              padding: '9px 12px', borderRadius: 999,
              border: role === r ? '1.5px solid var(--ink)' : '1px solid var(--hairline)',
              background: role === r ? 'var(--paper)' : 'var(--surface)',
              fontFamily: 'Inter', fontSize: 12, fontWeight: 600, color: 'var(--ink)', cursor: 'pointer',
            }}>{r}</button>
          ))}
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18 }}>
        <div>
          <label className="ck-label">Batting</label>
          <Select value={batting} onChange={setBatting} options={['Right', 'Left']} />
        </div>
        <div>
          <label className="ck-label">Bowling</label>
          <Select value={bowling} onChange={setBowling} options={['Right-arm fast', 'Right-arm spin', 'Left-arm fast', 'Left-arm spin', 'Doesn\'t bowl']} />
        </div>
      </div>

      <div style={{ padding: 12, background: 'var(--paper-2)', borderRadius: 12, fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.5, marginBottom: 18 }}>
        Unclaimed players appear in matches and rankings with an <strong style={{ color: 'var(--ink)' }}>Unclaimed</strong> badge. When they join Circk, they can search for their name and claim the profile — you approve the claim, and all their stats migrate over.
      </div>

      <SubmitRow disabled={!valid} label="Add to squad" onCancel={onCancel}
        onSubmit={() => onAdd({
          name: name || 'New player',
          role,
          status: 'unclaimed',
          detail: 'Unclaimed · ' + batting + '-hand · ' + bowling.toLowerCase(),
        })}
      />
    </SubFlow>
  );
}

// ── shared sub-flow chrome ───────────────────────────
function SubFlow({ title, subtitle, onCancel, children }) {
  return (
    <div style={{ padding: '4px 18px 0' }}>
      <button onClick={onCancel} style={{
        background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', gap: 6,
        fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 14,
      }}>
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M15 18l-6-6 6-6"/></svg>
        BACK TO SQUAD
      </button>
      <h1 className="ck-display" style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.025em', margin: '0 0 6px', lineHeight: 1.1 }}>{title}</h1>
      <p style={{ fontSize: 13, color: 'var(--muted)', margin: '0 0 20px', lineHeight: 1.4 }}>{subtitle}</p>
      {children}
    </div>
  );
}

function Select({ value, onChange, options }) {
  return (
    <div style={{ position: 'relative' }}>
      <select value={value} onChange={e => onChange(e.target.value)} className="ck-input" style={{
        appearance: 'none', WebkitAppearance: 'none', paddingRight: 36, fontSize: 14, cursor: 'pointer',
      }}>
        {options.map(o => <option key={o} value={o}>{o}</option>)}
      </select>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" style={{ position: 'absolute', right: 14, top: 18, pointerEvents: 'none' }}><path d="M6 9l6 6 6-6"/></svg>
    </div>
  );
}

function SubmitRow({ disabled, label, onCancel, onSubmit }) {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <button onClick={onCancel} style={{
        padding: '13px 18px', borderRadius: 12, border: '1px solid var(--hairline)',
        background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 14, cursor: 'pointer', color: 'var(--ink)',
      }}>Cancel</button>
      <button disabled={disabled} onClick={onSubmit} style={{
        flex: 1, padding: '13px 0', borderRadius: 12, border: 'none',
        background: 'var(--ink)', color: 'var(--paper)',
        fontFamily: 'Inter', fontWeight: 600, fontSize: 14, cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.35 : 1,
      }}>{label}</button>
    </div>
  );
}

// ─── Step 6 — Review ────────────────────────────────
function TCStepReview({ team, jumpTo }) {
  const SummaryRow = ({ label, value, step, multi }) => (
    <button onClick={() => jumpTo(step)} style={{
      width: '100%', display: 'flex', alignItems: multi ? 'flex-start' : 'center', gap: 12,
      padding: '14px 14px', background: 'transparent', border: 'none', borderTop: '1px solid var(--hairline)', cursor: 'pointer', textAlign: 'left',
    }}>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', width: 78, flexShrink: 0, paddingTop: 2 }}>{label}</div>
      <div style={{ flex: 1, fontFamily: 'Inter', fontSize: 13.5, color: 'var(--ink)', lineHeight: 1.4, fontWeight: 500 }}>{value}</div>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" style={{ marginTop: multi ? 4 : 0, flexShrink: 0 }}><path d="M11 4l8 8-8 8M3 12h16"/></svg>
    </button>
  );

  return (
    <div style={{ padding: '4px 18px 0' }}>
      <h1 className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 4px', lineHeight: 1.1 }}>
        Looks good?
      </h1>
      <p style={{ fontSize: 13, color: 'var(--muted)', margin: '0 0 22px', lineHeight: 1.4 }}>
        Tap any row to jump back and edit.
      </p>

      {/* Hero card */}
      <div style={{
        borderRadius: 18, padding: 20, position: 'relative', overflow: 'hidden',
        background: team.primary, color: textOn(team.primary), marginBottom: 14,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 56, height: 56, borderRadius: 14,
            background: team.secondary, color: textOn(team.secondary),
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 22, letterSpacing: '-0.03em',
          }}>{team.monogram}</div>
          <div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1.05 }}>{team.name}</div>
            <div style={{ fontSize: 11, opacity: 0.8, fontFamily: 'JetBrains Mono', letterSpacing: '0.06em', marginTop: 4 }}>
              {team.type.toUpperCase()} · {team.area.toUpperCase()}, {team.city.toUpperCase()} · EST. {team.founded}
            </div>
          </div>
        </div>
        <div style={{ position: 'absolute', right: -40, bottom: -44, opacity: 0.18 }}>
          <svg width="200" height="200" viewBox="0 0 200 200">
            <ellipse cx="100" cy="100" rx="95" ry="60" stroke="currentColor" strokeWidth="1" fill="none"/>
            <ellipse cx="100" cy="100" rx="55" ry="34" stroke="currentColor" strokeWidth="1" fill="none"/>
            <rect x="92" y="70" width="16" height="60" stroke="currentColor" strokeWidth="1" fill="none"/>
          </svg>
        </div>
      </div>

      {/* Editable summary list */}
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 16 }}>
        <SummaryRow label="BASICS"   step={1} value={`${team.name} · ${team.type} · ${team.privacy} · est. ${team.founded}`} />
        <SummaryRow label="IDENTITY" step={2} value={
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 16, height: 16, borderRadius: 4, background: team.primary, border: '1px solid var(--hairline)' }} />
            <span style={{ width: 16, height: 16, borderRadius: 4, background: team.secondary, border: '1px solid var(--hairline)' }} />
            <span>Monogram “{team.monogram}”</span>
          </span>
        } />
        <SummaryRow label="HOME"     step={3} value={`${team.area}, ${team.city}${team.homeGround ? ' · ' + team.homeGround : ''}`} />
        <SummaryRow label="CREST"    step={4} value={`${team.crestStyle} style · auto-synced colors`} />
        <SummaryRow label="SQUAD"    step={5} multi value={
          <div>
            <div>{team.invites.length} player{team.invites.length === 1 ? '' : 's'} added</div>
            <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>
              {team.invites.filter(p => p.status === 'app').length} on app ·
              {' '}{team.invites.filter(p => p.status === 'sms').length} SMS ·
              {' '}{team.invites.filter(p => p.status === 'unclaimed').length} unclaimed
            </div>
          </div>
        } />
      </div>

      {/* Owner block */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: 12, background: 'var(--paper-2)', borderRadius: 12, marginBottom: 16 }}>
        <div className="ck-avatar" style={{ background: 'var(--ink)', color: 'var(--paper)' }}>BA</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)' }}>You'll be the team owner</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>You can add co-managers and transfer ownership later.</div>
        </div>
      </div>

      <div style={{ fontSize: 11, color: 'var(--muted)', lineHeight: 1.5, padding: '0 4px 4px' }}>
        By creating this team you agree to Circk's community guidelines. {team.invites.filter(p => p.status === 'sms').length > 0 && <>We'll send {team.invites.filter(p => p.status === 'sms').length} invite{team.invites.filter(p => p.status === 'sms').length === 1 ? '' : 's'} as soon as the team is created.</>}
      </div>
    </div>
  );
}

// ─── Done — terminal success state ──────────────────
function TCDone({ team, onAgain }) {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--paper)' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar — minimal close */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', padding: '10px 18px 4px', flexShrink: 0 }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>TEAM CREATED</span>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '22px 18px 18px', display: 'flex', flexDirection: 'column' }}>

        {/* Hero crest with confetti dots */}
        <div style={{ position: 'relative', display: 'flex', justifyContent: 'center', marginBottom: 22, marginTop: 10 }}>
          <Confetti />
          <div style={{
            width: 132, height: 132, borderRadius: 28,
            background: team.primary, color: textOn(team.primary),
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 56, letterSpacing: '-0.04em',
            boxShadow: '0 12px 36px rgba(40,30,15,0.18)',
            zIndex: 1,
          }}>{team.monogram}</div>
        </div>

        <h1 className="ck-display" style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.03em', margin: '0 0 6px', lineHeight: 1.1, textAlign: 'center' }}>
          {team.name} is live.
        </h1>
        <p style={{ fontSize: 14, color: 'var(--muted)', margin: '0 0 24px', lineHeight: 1.4, textAlign: 'center' }}>
          You're the owner. {team.invites.filter(p => p.status === 'sms').length > 0
            ? `${team.invites.filter(p => p.status === 'sms').length} invite${team.invites.filter(p => p.status === 'sms').length === 1 ? '' : 's'} sent.`
            : `Squad of ${team.invites.length} ready to go.`}
        </p>

        {/* Receipt — what was set up */}
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: '4px 14px', marginBottom: 22 }}>
          <ReceiptRow icon="check" label="Team profile created" detail={`${team.type} · ${team.privacy}`} />
          <ReceiptRow icon="check" label="Located in" detail={`${team.area}, ${team.city}`} />
          <ReceiptRow icon="check" label="Crest set" detail={`${team.crestStyle} style`} />
          {team.invites.filter(p => p.status === 'app').length > 0 && (
            <ReceiptRow icon="check" label={`${team.invites.filter(p => p.status === 'app').length} player${team.invites.filter(p => p.status === 'app').length === 1 ? '' : 's'} notified`} detail="They'll see an in-app invite" />
          )}
          {team.invites.filter(p => p.status === 'sms').length > 0 && (
            <ReceiptRow icon="send" label={`${team.invites.filter(p => p.status === 'sms').length} SMS invite${team.invites.filter(p => p.status === 'sms').length === 1 ? '' : 's'} queued`} detail="Sending now" />
          )}
          {team.invites.filter(p => p.status === 'unclaimed').length > 0 && (
            <ReceiptRow icon="dot" label={`${team.invites.filter(p => p.status === 'unclaimed').length} unclaimed placeholder${team.invites.filter(p => p.status === 'unclaimed').length === 1 ? '' : 's'}`} detail="They can claim later" />
          )}
        </div>

        {/* Next steps */}
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 8, paddingLeft: 4 }}>WHAT NEXT</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 18 }}>
          <NextRow primary label="Open team page" sub="See your public profile" icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
          } />
          <NextRow label="Schedule a friendly" sub="Challenge another team" icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
          } />
          <NextRow label="Register for a tournament" sub="Find one near Lahore" icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M6 9V4h12v5a6 6 0 0 1-12 0z"/><path d="M4 4h2M18 4h2M9 18h6M12 14v4"/></svg>
          } />
          <NextRow label="Invite more players" sub={`${team.maxSize - team.invites.length} slots left`} icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="9" cy="9" r="4"/><path d="M2 21c0-4 3-6 7-6s7 2 7 6M19 8v6M16 11h6"/></svg>
          } />
        </div>

        <div style={{ flex: 1 }} />

        <button onClick={onAgain} style={{
          background: 'transparent', border: 'none', padding: '8px 0', cursor: 'pointer',
          fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', textAlign: 'center',
        }}>
          ← CREATE ANOTHER TEAM
        </button>
      </div>
    </div>
  );
}

function ReceiptRow({ icon, label, detail }) {
  const ICONS = {
    check: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--green)" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>,
    send:  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--amber)" strokeWidth="2"><path d="M22 2L11 13M22 2l-7 20-4-9-9-4z"/></svg>,
    dot:   <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><circle cx="12" cy="12" r="3"/></svg>,
  };
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0', borderTop: '1px solid var(--hairline)' }}>
      <div style={{ width: 22, display: 'flex', justifyContent: 'center', flexShrink: 0 }}>{ICONS[icon]}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: 'var(--ink)', fontWeight: 500 }}>{label}</div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>{detail}</div>
      </div>
    </div>
  );
}

function NextRow({ primary, label, sub, icon }) {
  return (
    <button style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '14px 14px', borderRadius: 14, cursor: 'pointer',
      border: primary ? 'none' : '1px solid var(--hairline)',
      background: primary ? 'var(--ink)' : 'var(--surface)',
      color: primary ? 'var(--paper)' : 'var(--ink)',
      fontFamily: 'inherit', textAlign: 'left', width: '100%',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 10, flexShrink: 0,
        background: primary ? 'rgba(255,255,255,0.12)' : 'var(--paper-2)',
        color: primary ? 'var(--paper)' : 'var(--ink)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 600 }}>{label}</div>
        <div style={{ fontSize: 11, opacity: primary ? 0.7 : 1, color: primary ? 'var(--paper)' : 'var(--muted)', marginTop: 1 }}>{sub}</div>
      </div>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ opacity: primary ? 0.7 : 0.5 }}><path d="M9 18l6-6-6-6"/></svg>
    </button>
  );
}

function Confetti() {
  // small decorative dots scattered behind the crest
  const items = [
    { x: 30,  y: 20, c: 'var(--red)',    s: 8 },
    { x: 318, y: 36, c: 'var(--amber)',  s: 7 },
    { x: 70,  y: 110, c: 'var(--green)', s: 6 },
    { x: 290, y: 116, c: 'var(--ink)',   s: 5 },
    { x: 50,  y: 70, c: 'var(--cream)',  s: 9 },
    { x: 320, y: 84, c: 'var(--red)',    s: 5 },
    { x: 18,  y: 132, c: 'var(--amber)', s: 4 },
    { x: 340, y: 148, c: 'var(--green)', s: 7 },
  ];
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
      {items.map((d, i) => (
        <span key={i} style={{
          position: 'absolute', left: d.x, top: d.y,
          width: d.s, height: d.s, borderRadius: 999, background: d.c,
        }} />
      ))}
    </div>
  );
}

function PlayerStatusDot({ status }) {
  const map = {
    app:       { bg: 'var(--green)',     glyph: '✓' },
    sms:       { bg: 'var(--amber)',     glyph: '!' },
    unclaimed: { bg: 'var(--paper-2)',   glyph: '?', fg: 'var(--muted)', border: '1px dashed var(--line)' },
  };
  const m = map[status] || map.unclaimed;
  return (
    <div style={{
      width: 28, height: 28, borderRadius: 9, flexShrink: 0,
      background: m.bg, color: m.fg || 'white', border: m.border || 'none',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13,
    }}>{m.glyph}</div>
  );
}

// ─── helpers ─────────────────────────────────────────
function monogramOf(name) {
  return (name || '')
    .split(/\s+/).filter(Boolean).slice(0, 2)
    .map(w => w[0]).join('').toUpperCase() || '??';
}

function textOn(bg) {
  // simple heuristic — paper/cream get dark text, everything else white
  if (bg.includes('0.985') || bg.includes('0.94') || bg.includes('0.78')) return 'oklch(0.18 0.02 80)';
  return 'white';
}

window.CkTeamCreate = CkTeamCreate;

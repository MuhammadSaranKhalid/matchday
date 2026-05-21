// TeamCreate.jsx — Create a new team
// 5 steps: Basics → Type & colors → Location → Crest → Invite players → Done
// Reuses design tokens from styles.css. No external deps.

function CkTeamCreate() {
  const [step, setStep] = React.useState(1);
  const [team, setTeam] = React.useState({
    name: 'Lahore Lions',
    type: 'Club',
    primary: 'oklch(0.36 0.10 148)',
    secondary: 'oklch(0.985 0.008 85)',
    monogram: 'LL',
    city: 'Lahore',
    area: 'Model Town',
    homeGround: 'Gaddafi B Ground',
    founded: '2019',
    privacy: 'Public',
    maxSize: 25,
    invites: [
      { id: 'p1', name: 'Bilal Ahmed',   role: 'Captain',     status: 'app',   detail: '@bilal · joined 2024' },
      { id: 'p2', name: 'Adeel Sheikh',  role: 'Wicket-Keeper', status: 'app',   detail: '@adeelk · joined 2024' },
      { id: 'p3', name: 'Faraz Khan',    role: 'Player',      status: 'sms',   detail: '+92 300 4521 ··· · invite SMS' },
      { id: 'p4', name: 'Hamza Tariq',   role: 'Player',      status: 'unclaimed', detail: 'Placeholder · unclaimed' },
    ],
  });

  const setT = (patch) => setTeam(prev => ({ ...prev, ...patch }));

  const STEPS = ['Basics', 'Identity', 'Home', 'Crest', 'Squad'];
  const isLast = step === STEPS.length;

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
        <button onClick={() => isLast ? null : setStep(step + 1)} style={{
          flex: 1, padding: '14px 0', borderRadius: 12, border: 'none',
          background: 'var(--ink)', color: 'var(--paper)',
          fontFamily: 'Inter', fontWeight: 600, fontSize: 15, cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          {isLast ? 'Create team' : 'Continue'}
          {!isLast && (
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
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
  const [pick, setPick] = React.useState('Monogram');
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
        {pick === 'Shield' && (
          <svg width="100%" height="100%" viewBox="0 0 100 100" style={{ position: 'absolute', inset: 0 }}>
            <path d="M50 5 L92 18 L88 60 Q88 80 50 95 Q12 80 12 60 L8 18 Z" fill="none" stroke={textOn(team.primary)} strokeWidth="2"/>
          </svg>
        )}
        <span style={{ position: 'relative', zIndex: 1 }}>{team.monogram}</span>
      </div>

      {/* Style picker */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8, marginBottom: 16 }}>
        {styles.map(s => (
          <button key={s} onClick={() => setPick(s)} style={{
            padding: '14px 10px', borderRadius: 12, cursor: 'pointer', textAlign: 'left',
            border: pick === s ? '1.5px solid var(--ink)' : '1px solid var(--hairline)',
            background: pick === s ? 'var(--paper)' : 'var(--surface)',
            fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: 'var(--ink)',
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <CrestIcon kind={s} primary={team.primary} />
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

function CrestIcon({ kind, primary }) {
  const fg = textOn(primary);
  const wrap = (children) => (
    <div style={{ width: 26, height: 26, borderRadius: 7, background: primary, color: fg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>{children}</div>
  );
  if (kind === 'Monogram') return wrap('LL');
  if (kind === 'Initials') return wrap('L');
  if (kind === 'Shield') return wrap(
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={fg} strokeWidth="2"><path d="M12 2 L21 5 L20 13 Q20 18 12 22 Q4 18 4 13 L3 5 Z"/></svg>
  );
  return wrap(
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={fg} strokeWidth="2"><path d="M12 5v14M5 12h14"/></svg>
  );
}

// ─── Step 5 — Squad / Invites ──────────────────────
function TCStepSquad({ team, setT }) {
  const [adding, setAdding] = React.useState(false);
  const removeInvite = (id) => setT({ invites: team.invites.filter(p => p.id !== id) });
  const cycleRole = (id) => {
    const ROLES = ['Player', 'Captain', 'Vice-Captain', 'Wicket-Keeper'];
    setT({ invites: team.invites.map(p => p.id === id ? { ...p, role: ROLES[(ROLES.indexOf(p.role) + 1) % ROLES.length] } : p) });
  };

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

      {/* Add row */}
      {!adding ? (
        <button onClick={() => setAdding(true)} style={{
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
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 10 }}>HOW TO ADD</div>
          {[
            { k: 'app', t: 'Search registered users', d: 'They get an invite — must accept' },
            { k: 'sms', t: 'Invite by phone or email', d: 'We SMS a link to download Circk' },
            { k: 'un',  t: 'Add as unclaimed', d: 'Just a name — for stats now, claim later' },
          ].map(opt => (
            <button key={opt.k} onClick={() => setAdding(false)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0',
              background: 'transparent', border: 'none', borderTop: '1px solid var(--hairline)', cursor: 'pointer',
              width: '100%', textAlign: 'left',
            }}>
              <PlayerStatusDot status={opt.k === 'un' ? 'unclaimed' : opt.k} />
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{opt.t}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{opt.d}</div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="M9 18l6-6-6-6"/></svg>
            </button>
          ))}
          <button onClick={() => setAdding(false)} style={{ marginTop: 6, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', background: 'transparent', border: 'none', cursor: 'pointer', letterSpacing: '0.08em' }}>CANCEL</button>
        </div>
      )}
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

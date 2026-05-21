// Create.jsx — Tournament creation, spec-complete
// Spec sections covered: 3.3 entity, 3.4 match format defaults, 3.5 tournament rules,
// 3.6 status (Draft → Registration), 3.7 team registration, 3.10 awards, 3.11 permissions, 3.12 flow.

const FORMAT_OPTIONS = [
  { id: 'Knockout', t: 'Knockout', s: 'Single elim · bracket', icon: '◇', mvp: true },
  { id: 'RoundRobin', t: 'Round-robin', s: 'Each plays each once', icon: '⊞', mvp: true },
  { id: 'League', t: 'League', s: 'Home + away (double RR)', icon: '⇄', mvp: true },
  { id: 'GroupKnockout', t: 'Group + KO', s: 'v1.1 · groups → playoffs', icon: '◈', mvp: false },
  { id: 'DoubleElimination', t: 'Double elim', s: 'v1.2 · winners + losers', icon: '◊', mvp: false },
];
const BALL_TYPES = ['Leather', 'Tape', 'Tennis'];
const OVER_OPTIONS = [5, 10, 15, 20, 50];
const PLAYER_OPTIONS = [6, 7, 8, 9, 10, 11];
const TEAM_BUCKETS = [4, 6, 8, 10, 12, 16];
const VENUE_OPTIONS = [
  { id: 'mt', t: 'Model Town', s: 'Lahore · 2 pitches' },
  { id: 'gulb', t: 'Gulberg pitch', s: 'Lahore · 1 pitch' },
  { id: 'dha', t: 'DHA grounds', s: 'Lahore · 5 pitches' },
];
const DAYS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const TIE_BREAKERS = [
  { id: 'NRR', t: 'Net run rate' },
  { id: 'H2H', t: 'Head-to-head' },
  { id: 'Wins', t: 'Most wins' },
];
const SEED_TEAMS = [
  { name: 'Lahore Lions', captain: 'Imran K.', color: 'oklch(0.62 0.19 28)' },
  { name: 'City Eagles', captain: 'Hassan R.', color: 'oklch(0.56 0.13 148)' },
  { name: 'Mohalla Kings', captain: 'Ali T.', color: 'oklch(0.78 0.14 80)' },
  { name: 'DHA United', captain: 'Bilal S.', color: 'oklch(0.42 0.10 260)' },
  { name: 'Galle Boys', captain: 'Ravi P.', color: 'oklch(0.55 0.15 30)' },
  { name: 'Royal Madras', captain: 'Karthik V.', color: 'oklch(0.42 0.13 300)' },
  { name: 'Old Boys', captain: 'Tariq M.', color: 'oklch(0.45 0.05 240)' },
  { name: 'New School', captain: 'Faisal A.', color: 'oklch(0.62 0.16 50)' },
];

const STEPS = [
  { id: 'basics', label: 'Basics' },
  { id: 'format', label: 'Format' },
  { id: 'match', label: 'Match' },
  { id: 'rules', label: 'Rules' },
  { id: 'teams', label: 'Teams' },
  { id: 'schedule', label: 'Schedule' },
  { id: 'people', label: 'Organizers' },
  { id: 'prize', label: 'Prize' },
  { id: 'review', label: 'Review' },
];

function Create() {
  const [step, setStep] = React.useState(0);
  const [done, setDone] = React.useState(false);

  const [form, setForm] = React.useState({
    // 3.3 — Basics
    tournamentName: "Spring Cup '26",
    tagline: 'The mohalla showdown',
    description: '8-team T20 cup running through March. Fri / Sat / Sun nights at Model Town.',
    coverColor: 'oklch(0.62 0.19 28)',
    bannerImage: null,
    logoImage: null,
    privacy: 'Public',

    // 3.3 — Format
    tournamentType: 'GroupKnockout',
    groups: 2,
    qualifiers: 2,

    // 3.4 — Match format defaults
    oversPerInnings: 20,
    inningsPerTeam: 1,
    playersPerTeam: 11,
    ballType: 'Leather',
    powerplayEnabled: true,
    powerplayOvers: 6,
    maxOversPerBowler: 4,
    wideRunPenalty: 1,
    noBallRunPenalty: 1,
    freeHitOnNoBall: true,
    superOverOnTie: true,

    // 3.5 — Tournament rules
    allowMultiTeamPlayers: false,
    allowMidTournamentSquadChanges: false,
    genderRule: 'Open',
    minAge: '',
    maxAge: '',
    requireClaimedProfiles: false,
    pointsForWin: 2,
    pointsForLoss: 0,
    pointsForTie: 1,
    pointsForNoResult: 1,
    tieBreakers: ['NRR', 'H2H', 'Wins'],
    playoffsEnabled: false,
    playoffTeams: 4,

    // teams + cap
    minTeams: 6,
    maxTeams: 8,
    teams: 8,
    teamList: SEED_TEAMS.slice(0, 8).map(t => ({ ...t })),
    pendingTeam: '',

    // 3.3 — schedule
    venues: ['mt', 'gulb'],
    startDate: 'Fri 14 Mar',
    endDate: 'Sun 30 Mar',
    registrationDeadline: 'Wed 12 Mar',
    startTime: '7:00 PM',
    days: [4, 5, 6],
    matchesPerDay: 2,

    // people (3.3)
    organizers: [{ name: 'You', role: 'Creator' }, { name: 'Sahil K.', role: 'Co-organizer' }],
    pendingOrganizer: '',
    assignedScorers: [{ name: 'Asad M.' }],
    pendingScorer: '',

    // prize
    entryFee: 2000,
    prizeWinner: 25000,
    prizeRunner: 10000,
    prizeMOM: 'Trophy + Rs.500',
    prizeDetails: '',
    inviteLink: 'circk.app/spring-cup-26',
    autoApprove: true,
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));
  const update = (patch) => setForm(f => ({ ...f, ...patch }));

  const validateStep = (s) => {
    if (s === 0) return form.tournamentName.trim().length >= 3;
    if (s === 1) return !!form.tournamentType;
    if (s === 4) return form.teamList.filter(t => t.name).length >= form.minTeams;
    if (s === 5) return form.venues.length > 0 && form.days.length > 0;
    return true;
  };
  const canNext = validateStep(step);

  const next = () => {
    if (!canNext) return;
    if (step < STEPS.length - 1) setStep(step + 1);
    else setDone(true);
  };
  const back = () => step > 0 && setStep(step - 1);
  const reset = () => { setDone(false); setStep(0); };

  if (done) return <SuccessScreen form={form} reset={reset} />;

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Header step={step} total={STEPS.length} steps={STEPS} setStep={setStep} back={back} />

      <div style={{ flex: 1, overflow: 'auto', padding: '20px 20px 16px' }}>
        {step === 0 && <Basics form={form} set={set} />}
        {step === 1 && <Format form={form} update={update} />}
        {step === 2 && <MatchFormat form={form} set={set} />}
        {step === 3 && <Rules form={form} set={set} />}
        {step === 4 && <Teams form={form} set={set} update={update} />}
        {step === 5 && <Schedule form={form} set={set} />}
        {step === 6 && <People form={form} set={set} />}
        {step === 7 && <PrizeInvites form={form} set={set} />}
        {step === 8 && <Review form={form} jumpTo={setStep} />}
      </div>

      <div style={{ padding: '12px 20px 22px', borderTop: '1px solid var(--hairline)', display: 'flex', gap: 8 }}>
        {step > 0 && <button onClick={back} className="ck-btn tonal" style={{ padding: '14px 18px' }}>Back</button>}
        <button onClick={next} disabled={!canNext} className="ck-btn" style={{ flex: 1, opacity: canNext ? 1 : 0.4 }}>
          {step === STEPS.length - 1 ? 'Publish · open registration' : 'Continue'}
        </button>
      </div>
    </div>
  );
}

function Header({ step, total, steps, setStep, back }) {
  return (
    <div style={{ padding: '14px 20px 12px', borderBottom: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={back} disabled={step === 0} style={{ background: 'transparent', border: 'none', padding: 0, cursor: step === 0 ? 'default' : 'pointer', color: step === 0 ? 'var(--muted)' : 'var(--ink)', opacity: step === 0 ? 0.4 : 1 }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
          New tournament · {step + 1}/{total}
        </div>
        <div style={{ flex: 1 }} />
        <span style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.08em', padding: '3px 7px', borderRadius: 999, border: '1px solid var(--hairline)' }}>DRAFT</span>
      </div>
      <div style={{ display: 'flex', gap: 4, marginTop: 12, overflowX: 'auto' }}>
        {steps.map((s, i) => (
          <button key={s.id} onClick={() => i < step && setStep(i)} style={{
            flex: '1 0 auto', padding: '4px 8px', borderRadius: 999,
            fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 600, letterSpacing: '0.05em',
            background: i === step ? 'var(--ink)' : i < step ? 'var(--paper-2)' : 'transparent',
            color: i === step ? 'var(--paper)' : i < step ? 'var(--ink)' : 'var(--muted)',
            border: '1px solid ' + (i === step ? 'var(--ink)' : i < step ? 'var(--hairline)' : 'transparent'),
            cursor: i < step ? 'pointer' : 'default', textTransform: 'uppercase', whiteSpace: 'nowrap',
          }}>{i < step && '✓ '}{s.label}</button>
        ))}
      </div>
    </div>
  );
}

function StepTitle({ title, sub }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <h1 style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 700, margin: 0, lineHeight: 1.1, letterSpacing: '-0.025em' }}>{title}</h1>
      {sub && <p style={{ margin: '6px 0 0', fontSize: 13, color: 'var(--muted)', lineHeight: 1.4 }}>{sub}</p>}
    </div>
  );
}

// ---------- Reusable controls ----------
function Toggle({ on, onChange }) {
  return (
    <button onClick={() => onChange(!on)} style={{
      width: 44, height: 26, borderRadius: 13, position: 'relative', border: 'none', cursor: 'pointer',
      background: on ? 'var(--ink)' : 'var(--hairline)', transition: 'background .2s', flex: 'none',
    }}>
      <div style={{ position: 'absolute', top: 3, left: on ? 21 : 3, width: 20, height: 20, borderRadius: 999, background: 'var(--paper)', transition: 'left .2s' }} />
    </button>
  );
}
function ToggleRow({ k, t, s, form, set }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--hairline)' }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontWeight: 600, fontSize: 14 }}>{t}</div>
        <div style={{ fontSize: 11, color: 'var(--muted)', lineHeight: 1.3, marginTop: 2 }}>{s}</div>
      </div>
      <Toggle on={form[k]} onChange={v => set(k, v)} />
    </div>
  );
}
function Stepper({ k, label, suf, min, max, form, set }) {
  return (
    <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)' }}>
      <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.06em' }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
        <button onClick={() => set(k, Math.max(min, form[k] - 1))} style={{ width: 26, height: 26, borderRadius: 999, background: 'var(--paper-2)', border: 'none', fontSize: 14, cursor: 'pointer', color: 'var(--ink-2)' }}>−</button>
        <div style={{ flex: 1, textAlign: 'center', fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em' }}>
          {form[k]}{suf && <span style={{ fontSize: 12, color: 'var(--muted)', marginLeft: 4 }}>{suf}</span>}
        </div>
        <button onClick={() => set(k, Math.min(max, form[k] + 1))} style={{ width: 26, height: 26, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontSize: 14, cursor: 'pointer' }}>+</button>
      </div>
    </div>
  );
}
function Pill({ active, children, ...rest }) {
  return (
    <button {...rest} style={{
      flex: 1, padding: '10px 0', fontFamily: 'Inter Tight', fontWeight: 600, fontSize: 13,
      borderRadius: 10, border: '1px solid ' + (active ? 'var(--ink)' : 'var(--hairline)'),
      background: active ? 'var(--ink)' : 'var(--paper)',
      color: active ? 'var(--paper)' : 'var(--ink)', cursor: 'pointer',
      ...rest.style,
    }}>{children}</button>
  );
}

// =========================================================================
// STEP 0 — Basics
// =========================================================================
function Basics({ form, set }) {
  const COLORS = [
    'oklch(0.62 0.19 28)', 'oklch(0.56 0.13 148)', 'oklch(0.78 0.14 80)',
    'oklch(0.42 0.10 260)', 'oklch(0.18 0.02 80)', 'oklch(0.62 0.16 320)',
  ];
  return (
    <>
      <StepTitle title="Name & basics." sub="What we'll call it, who can find it, how it looks." />

      <div style={{
        height: 130, borderRadius: 14, padding: 16, marginBottom: 18,
        background: form.coverColor, color: 'var(--paper)',
        position: 'relative', overflow: 'hidden',
        display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
      }}>
        <svg width="220" height="220" viewBox="0 0 200 200" style={{ position: 'absolute', right: -50, top: -60, opacity: 0.18 }}>
          <ellipse cx="100" cy="100" rx="90" ry="60" stroke="white" fill="none" strokeWidth="0.6"/>
          <ellipse cx="100" cy="100" rx="50" ry="32" stroke="white" fill="none" strokeWidth="0.6"/>
        </svg>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, opacity: 0.8, letterSpacing: '0.08em' }}>PREVIEW</div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1.1, marginTop: 4 }}>{form.tournamentName || 'Untitled'}</div>
        {form.tagline && <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>{form.tagline}</div>}
      </div>

      <label className="ck-label">Name</label>
      <input className="ck-input" value={form.tournamentName} onChange={e => set('tournamentName', e.target.value)} maxLength={100} placeholder="3–100 characters" />
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 6 }}>{form.tournamentName.length}/100</div>

      <label className="ck-label" style={{ marginTop: 16 }}>Tagline (optional)</label>
      <input className="ck-input" value={form.tagline} onChange={e => set('tagline', e.target.value)} maxLength={60} placeholder="One line about the cup" />

      <label className="ck-label" style={{ marginTop: 16 }}>Description</label>
      <textarea className="ck-input" value={form.description} onChange={e => set('description', e.target.value)} maxLength={1000} rows={3} style={{ resize: 'vertical', minHeight: 76, fontFamily: 'inherit', lineHeight: 1.4 }} placeholder="Tell teams what to expect…" />
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>{form.description.length}/1000</div>

      <label className="ck-label" style={{ marginTop: 16 }}>Banner & logo</label>
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 8 }}>
        <button style={{ height: 72, borderRadius: 10, border: '1.5px dashed var(--hairline)', background: 'var(--paper-2)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4, cursor: 'pointer', fontFamily: 'inherit' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.5-3.5L8 21"/></svg>
          <span style={{ fontSize: 11, color: 'var(--muted)', fontWeight: 600 }}>Add banner</span>
        </button>
        <button style={{ height: 72, borderRadius: 10, border: '1.5px dashed var(--hairline)', background: 'var(--paper-2)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4, cursor: 'pointer', fontFamily: 'inherit' }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><circle cx="12" cy="12" r="9"/><path d="M12 7v10M7 12h10"/></svg>
          <span style={{ fontSize: 10, color: 'var(--muted)', fontWeight: 600 }}>Logo</span>
        </button>
      </div>

      <label className="ck-label" style={{ marginTop: 18 }}>Cover color</label>
      <div style={{ display: 'flex', gap: 8 }}>
        {COLORS.map(c => (
          <button key={c} onClick={() => set('coverColor', c)} style={{
            width: 36, height: 36, borderRadius: 999, background: c, cursor: 'pointer',
            border: form.coverColor === c ? '2.5px solid var(--ink)' : '1.5px solid var(--hairline)',
            boxShadow: form.coverColor === c ? '0 0 0 2px var(--paper) inset' : 'none',
          }} />
        ))}
      </div>

      <div style={{ marginTop: 22 }}>
        <label className="ck-label">Privacy</label>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { id: 'Public', s: 'Anyone can browse and request to register a team' },
            { id: 'Private', s: 'Invite-only — teams only join via link or invitation' },
          ].map(o => (
            <button key={o.id} onClick={() => set('privacy', o.id)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: 12, borderRadius: 10,
              border: '1.5px solid ' + (form.privacy === o.id ? 'var(--ink)' : 'var(--hairline)'),
              background: form.privacy === o.id ? 'var(--paper-2)' : 'var(--paper)',
              cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{
                width: 20, height: 20, borderRadius: 999, border: '2px solid ' + (form.privacy === o.id ? 'var(--ink)' : 'var(--hairline)'),
                display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 'none',
              }}>{form.privacy === o.id && <div style={{ width: 10, height: 10, borderRadius: 999, background: 'var(--ink)' }} />}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{o.id}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{o.s}</div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </>
  );
}

// =========================================================================
// STEP 1 — Format (tournament structure)
// =========================================================================
function Format({ form, update }) {
  const showGroups = form.tournamentType === 'GroupKnockout';
  const showPlayoffs = form.tournamentType === 'RoundRobin' || form.tournamentType === 'League';
  return (
    <>
      <StepTitle title="Tournament format." sub="Choose how matches are structured. MVP supports the first three." />

      <label className="ck-label">Type</label>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {FORMAT_OPTIONS.map(f => (
          <button key={f.id} onClick={() => f.mvp && update({ tournamentType: f.id })} disabled={!f.mvp} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: 12, borderRadius: 10,
            border: '1.5px solid ' + (form.tournamentType === f.id ? 'var(--ink)' : 'var(--hairline)'),
            background: form.tournamentType === f.id ? 'var(--paper-2)' : 'var(--paper)',
            opacity: f.mvp ? 1 : 0.45,
            cursor: f.mvp ? 'pointer' : 'not-allowed', fontFamily: 'inherit', textAlign: 'left',
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 8, background: form.tournamentType === f.id ? 'var(--ink)' : 'var(--paper-2)',
              color: form.tournamentType === f.id ? 'var(--paper)' : 'var(--ink-2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontSize: 18,
            }}>{f.icon}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>{f.t}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{f.s}</div>
            </div>
            {!f.mvp && <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)', padding: '3px 6px', borderRadius: 999, background: 'var(--paper-2)', letterSpacing: '0.06em' }}>SOON</span>}
          </button>
        ))}
      </div>

      {showGroups && (
        <div style={{ marginTop: 18, padding: 14, borderRadius: 12, background: 'oklch(0.94 0.05 90)', border: '1px solid oklch(0.86 0.05 90)' }}>
          <div className="ck-section-h" style={{ marginBottom: 10 }}>Group config</div>
          <div style={{ display: 'flex', gap: 10 }}>
            <Stepper k="groups" label="GROUPS" min={1} max={4} form={form} set={(k, v) => update({ [k]: v })} />
            <Stepper k="qualifiers" label="QUALIFY/GROUP" min={1} max={4} form={form} set={(k, v) => update({ [k]: v })} />
          </div>
        </div>
      )}

      {showPlayoffs && (
        <div style={{ marginTop: 18, padding: 14, borderRadius: 12, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: showPlayoffs && form.playoffsEnabled ? 10 : 0 }}>
            <div>
              <div style={{ fontWeight: 600, fontSize: 14 }}>Playoffs</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>Top N teams from {form.tournamentType === 'League' ? 'league' : 'round-robin'} → knockout</div>
            </div>
            <Toggle on={form.playoffsEnabled} onChange={v => update({ playoffsEnabled: v })} />
          </div>
          {form.playoffsEnabled && (
            <Stepper k="playoffTeams" label="PLAYOFF TEAMS" min={2} max={8} form={form} set={(k, v) => update({ [k]: v })} />
          )}
        </div>
      )}

      <label className="ck-label" style={{ marginTop: 22 }}>Team capacity</label>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <Stepper k="minTeams" label="MIN TEAMS" min={2} max={form.maxTeams} form={form} set={(k, v) => update({ [k]: v })} />
        <Stepper k="maxTeams" label="MAX TEAMS" min={form.minTeams} max={32} form={form} set={(k, v) => update({ [k]: v })} />
      </div>
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 6 }}>
        Tournament can't start until {form.minTeams} teams approved · cap at {form.maxTeams}.
      </div>
    </>
  );
}

// =========================================================================
// STEP 2 — Match Format Defaults
// =========================================================================
function MatchFormat({ form, set }) {
  return (
    <>
      <StepTitle title="Match format defaults." sub="Applies to every match unless overridden per-match." />

      <label className="ck-label">Overs per innings</label>
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {OVER_OPTIONS.map(o => (
          <Pill key={o} active={form.oversPerInnings === o} onClick={() => set('oversPerInnings', o)}>{o === 50 ? '50 ov' : `T${o}`}</Pill>
        ))}
      </div>

      <label className="ck-label">Innings per team</label>
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {[1, 2].map(n => (
          <Pill key={n} active={form.inningsPerTeam === n} onClick={() => set('inningsPerTeam', n)}>{n} innings</Pill>
        ))}
      </div>

      <label className="ck-label">Players per team</label>
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {PLAYER_OPTIONS.map(n => (
          <Pill key={n} active={form.playersPerTeam === n} onClick={() => set('playersPerTeam', n)}>{n}</Pill>
        ))}
      </div>

      <label className="ck-label">Ball type</label>
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {BALL_TYPES.map(b => (
          <Pill key={b} active={form.ballType === b} onClick={() => set('ballType', b)}>{b}</Pill>
        ))}
      </div>

      <div className="ck-section-h" style={{ marginTop: 8, marginBottom: 8 }}>Powerplay</div>
      <ToggleRow k="powerplayEnabled" t="Powerplay enabled" s="Field restrictions for opening overs" form={form} set={set} />
      {form.powerplayEnabled && (
        <div style={{ marginTop: 10 }}>
          <Stepper k="powerplayOvers" label="POWERPLAY OVERS" suf="ov" min={1} max={Math.floor(form.oversPerInnings / 2)} form={form} set={set} />
        </div>
      )}

      <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 8 }}>Bowling limits</div>
      <Stepper k="maxOversPerBowler" label="MAX OVERS / BOWLER" suf="ov" min={1} max={form.oversPerInnings} form={form} set={set} />
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 6 }}>
        Default suggestion: <strong style={{ color: 'var(--ink-2)' }}>{Math.ceil(form.oversPerInnings / 5)}</strong> ({form.oversPerInnings} / 5)
      </div>

      <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 8 }}>Extras</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 8 }}>
        <Stepper k="wideRunPenalty" label="WIDE PENALTY" suf=" run" min={0} max={5} form={form} set={set} />
        <Stepper k="noBallRunPenalty" label="NO-BALL PENALTY" suf=" run" min={0} max={5} form={form} set={set} />
      </div>
      <ToggleRow k="freeHitOnNoBall" t="Free hit on no-ball" s="Next ball cannot dismiss the batter except run-out" form={form} set={set} />
      <ToggleRow k="superOverOnTie" t="Super over on tie" s="One-over eliminator decides knockout matches" form={form} set={set} />
    </>
  );
}

// =========================================================================
// STEP 3 — Tournament Rules
// =========================================================================
function Rules({ form, set }) {
  const moveTieBreaker = (idx, dir) => {
    const list = [...form.tieBreakers];
    const j = idx + dir;
    if (j < 0 || j >= list.length) return;
    [list[idx], list[j]] = [list[j], list[idx]];
    set('tieBreakers', list);
  };

  return (
    <>
      <StepTitle title="Tournament rules." sub="Eligibility, points, tie-breaks. Distinct from match-level rules." />

      <div className="ck-section-h" style={{ marginBottom: 4 }}>Squad rules</div>
      <ToggleRow k="allowMultiTeamPlayers" t="Allow multi-team players" s="A player can be registered for >1 team in this tournament" form={form} set={set} />
      <ToggleRow k="allowMidTournamentSquadChanges" t="Mid-tournament squad changes" s="Off → squads lock once tournament starts" form={form} set={set} />
      <ToggleRow k="requireClaimedProfiles" t="Require claimed profiles" s="All registered players must have claimed Circk profiles" form={form} set={set} />

      <div className="ck-section-h" style={{ marginTop: 18, marginBottom: 8 }}>Eligibility</div>
      <label className="ck-label">Gender rule</label>
      <div style={{ display: 'flex', gap: 6, marginBottom: 14, flexWrap: 'wrap' }}>
        {['Open', 'MaleOnly', 'FemaleOnly', 'MixedRequired'].map(g => (
          <Pill key={g} active={form.genderRule === g} onClick={() => set('genderRule', g)} style={{ flex: '1 1 calc(50% - 3px)', minWidth: 0, padding: '8px 10px', fontSize: 12 }}>
            {g === 'MaleOnly' ? 'Male only' : g === 'FemaleOnly' ? 'Female only' : g === 'MixedRequired' ? 'Mixed required' : 'Open'}
          </Pill>
        ))}
      </div>

      <label className="ck-label">Age restriction (optional)</label>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input className="ck-input" placeholder="Min age" value={form.minAge} onChange={e => set('minAge', e.target.value.replace(/\D/g, ''))} />
        <input className="ck-input" placeholder="Max age" value={form.maxAge} onChange={e => set('maxAge', e.target.value.replace(/\D/g, ''))} />
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Points system</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <Stepper k="pointsForWin" label="WIN" suf=" pt" min={0} max={6} form={form} set={set} />
        <Stepper k="pointsForLoss" label="LOSS" suf=" pt" min={0} max={3} form={form} set={set} />
        <Stepper k="pointsForTie" label="TIE" suf=" pt" min={0} max={3} form={form} set={set} />
        <Stepper k="pointsForNoResult" label="NO RESULT" suf=" pt" min={0} max={3} form={form} set={set} />
      </div>
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 8 }}>Rain-abandoned matches use "No result"</div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Tie-breakers (in order)</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {form.tieBreakers.map((tb, idx) => {
          const meta = TIE_BREAKERS.find(x => x.id === tb);
          return (
            <div key={tb} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: 10,
              borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)',
            }}>
              <div style={{ width: 22, height: 22, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 700, flex: 'none' }}>{idx + 1}</div>
              <div style={{ flex: 1, fontWeight: 600, fontSize: 13 }}>{meta?.t}</div>
              <button onClick={() => moveTieBreaker(idx, -1)} disabled={idx === 0} style={{ width: 28, height: 28, padding: 0, background: 'var(--paper-2)', border: 'none', borderRadius: 999, cursor: idx === 0 ? 'default' : 'pointer', opacity: idx === 0 ? 0.3 : 1 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m18 15-6-6-6 6"/></svg>
              </button>
              <button onClick={() => moveTieBreaker(idx, 1)} disabled={idx === form.tieBreakers.length - 1} style={{ width: 28, height: 28, padding: 0, background: 'var(--paper-2)', border: 'none', borderRadius: 999, cursor: idx === form.tieBreakers.length - 1 ? 'default' : 'pointer', opacity: idx === form.tieBreakers.length - 1 ? 0.3 : 1 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m6 9 6 6 6-6"/></svg>
              </button>
            </div>
          );
        })}
      </div>
    </>
  );
}

// =========================================================================
// STEP 4 — Teams
// =========================================================================
function Teams({ form, set, update }) {
  const [editIdx, setEditIdx] = React.useState(null);
  const [editField, setEditField] = React.useState('name');

  const filled = form.teamList.filter(t => t.name).length;

  // ensure list length matches maxTeams
  React.useEffect(() => {
    if (form.teamList.length !== form.maxTeams) {
      const next = form.teamList.slice(0, form.maxTeams);
      while (next.length < form.maxTeams) next.push({ name: '', captain: '', color: 'oklch(0.50 0.05 80)' });
      update({ teamList: next, teams: form.maxTeams });
    }
  }, [form.maxTeams]);

  const addTeam = () => {
    const v = form.pendingTeam.trim();
    if (!v) return;
    const next = [...form.teamList];
    const emptyIdx = next.findIndex(t => !t.name);
    const newTeam = { name: v, captain: '', color: 'oklch(0.50 0.05 80)' };
    if (emptyIdx >= 0) next[emptyIdx] = newTeam;
    update({ teamList: next, pendingTeam: '' });
  };
  const remove = (i) => {
    const next = [...form.teamList];
    next[i] = { name: '', captain: '', color: 'oklch(0.50 0.05 80)' };
    set('teamList', next);
  };
  const updateField = (i, field, value) => {
    const next = [...form.teamList];
    next[i] = { ...next[i], [field]: value };
    set('teamList', next);
  };

  return (
    <>
      <StepTitle title={`Invite teams.`} sub={`Need at least ${form.minTeams} approved to start. Cap is ${form.maxTeams}.`} />

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <div className="ck-section-h">{filled} / {form.maxTeams} added · min {form.minTeams}</div>
        <button onClick={() => set('teamList', SEED_TEAMS.slice(0, form.maxTeams).concat(Array(Math.max(0, form.maxTeams - SEED_TEAMS.length)).fill(null).map(() => ({ name: '', captain: '', color: 'oklch(0.50 0.05 80)' }))))} style={{ background: 'transparent', border: 'none', fontSize: 11, color: 'var(--red)', fontFamily: 'inherit', cursor: 'pointer', fontWeight: 600 }}>Use suggestions</button>
      </div>

      <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
        <input
          className="ck-input" placeholder="Team name"
          value={form.pendingTeam}
          onChange={e => set('pendingTeam', e.target.value)}
          onKeyDown={e => e.key === 'Enter' && addTeam()}
          disabled={filled >= form.maxTeams}
        />
        <button onClick={addTeam} disabled={!form.pendingTeam.trim() || filled >= form.maxTeams} style={{
          padding: '0 18px', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)',
          fontFamily: 'inherit', fontWeight: 600, fontSize: 18, cursor: 'pointer',
          opacity: form.pendingTeam.trim() && filled < form.maxTeams ? 1 : 0.4,
        }}>+</button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {form.teamList.map((t, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px',
            borderRadius: 10, border: '1px solid var(--hairline)',
            background: t.name ? 'var(--paper)' : 'var(--paper-2)',
          }}>
            <div style={{ width: 18, fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{String(i + 1).padStart(2, '0')}</div>
            <button onClick={() => {
              const colors = ['oklch(0.62 0.19 28)', 'oklch(0.56 0.13 148)', 'oklch(0.78 0.14 80)', 'oklch(0.42 0.10 260)', 'oklch(0.62 0.16 320)', 'oklch(0.18 0.02 80)'];
              const idx = colors.indexOf(t.color);
              updateField(i, 'color', colors[(idx + 1) % colors.length]);
            }} style={{
              width: 32, height: 32, borderRadius: 999, border: 'none', cursor: t.name ? 'pointer' : 'default',
              background: t.name ? t.color : 'var(--hairline)',
              color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700, flex: 'none',
            }}>{t.name ? t.name.split(' ').map(w => w[0]).slice(0, 2).join('') : '–'}</button>
            <div style={{ flex: 1, minWidth: 0 }}>
              {editIdx === i && editField === 'name' ? (
                <input autoFocus value={t.name} onChange={e => updateField(i, 'name', e.target.value)}
                  onBlur={() => setEditIdx(null)} onKeyDown={e => e.key === 'Enter' && setEditIdx(null)}
                  style={{ width: '100%', border: 'none', outline: 'none', background: 'transparent', fontFamily: 'inherit', fontSize: 14, fontWeight: 600 }} />
              ) : (
                <div onClick={() => t.name && (setEditIdx(i), setEditField('name'))}
                  style={{ fontSize: 14, fontWeight: t.name ? 600 : 400, color: t.name ? 'var(--ink)' : 'var(--muted)', cursor: t.name ? 'pointer' : 'default', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {t.name || 'Pending invite'}
                </div>
              )}
              {editIdx === i && editField === 'captain' ? (
                <input autoFocus value={t.captain} onChange={e => updateField(i, 'captain', e.target.value)}
                  onBlur={() => setEditIdx(null)} onKeyDown={e => e.key === 'Enter' && setEditIdx(null)} placeholder="Captain"
                  style={{ width: '100%', border: 'none', outline: 'none', background: 'transparent', fontFamily: 'inherit', fontSize: 11, color: 'var(--muted)', marginTop: 2 }} />
              ) : (
                t.name && (
                  <div onClick={() => (setEditIdx(i), setEditField('captain'))}
                    style={{ fontSize: 11, color: 'var(--muted)', cursor: 'pointer', marginTop: 1 }}>
                    {t.captain ? `cap. ${t.captain}` : '+ add captain'}
                  </div>
                )
              )}
            </div>
            {t.name && (
              <button onClick={() => remove(i)} style={{ background: 'transparent', border: 'none', color: 'var(--muted)', cursor: 'pointer', padding: 4 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
              </button>
            )}
          </div>
        ))}
      </div>

      <div style={{ marginTop: 14, padding: 12, borderRadius: 10, background: 'var(--paper-2)', fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.4 }}>
        Once you publish, captains receive a notification and registration opens. Squads lock {form.allowMidTournamentSquadChanges ? 'after first match' : 'when tournament starts'}.
      </div>
    </>
  );
}

// =========================================================================
// STEP 5 — Schedule
// =========================================================================
function Schedule({ form, set }) {
  const toggleDay = (i) => {
    const next = form.days.includes(i) ? form.days.filter(d => d !== i) : [...form.days, i].sort();
    set('days', next);
  };
  const toggleVenue = (id) => {
    const next = form.venues.includes(id) ? form.venues.filter(v => v !== id) : [...form.venues, id];
    set('venues', next);
  };

  return (
    <>
      <StepTitle title="When and where." sub="Dates, venues, weekly cadence." />

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Dates</div>
      <label className="ck-label">Registration deadline</label>
      <input className="ck-input" value={form.registrationDeadline} onChange={e => set('registrationDeadline', e.target.value)} />
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4, marginBottom: 14 }}>Auto-closes team registration after this date</div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 8 }}>
        <div>
          <label className="ck-label">Start date</label>
          <input className="ck-input" value={form.startDate} onChange={e => set('startDate', e.target.value)} />
        </div>
        <div>
          <label className="ck-label">End date (est.)</label>
          <input className="ck-input" value={form.endDate} onChange={e => set('endDate', e.target.value)} />
        </div>
      </div>
      <label className="ck-label" style={{ marginTop: 10 }}>Default start time</label>
      <input className="ck-input" value={form.startTime} onChange={e => set('startTime', e.target.value)} />

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Venues</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {VENUE_OPTIONS.map(v => {
          const on = form.venues.includes(v.id);
          return (
            <button key={v.id} onClick={() => toggleVenue(v.id)} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: 12, borderRadius: 10,
              border: '1.5px solid ' + (on ? 'var(--ink)' : 'var(--hairline)'),
              background: on ? 'var(--paper-2)' : 'var(--paper)',
              cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{
                width: 20, height: 20, borderRadius: 5, border: '2px solid ' + (on ? 'var(--ink)' : 'var(--hairline)'),
                background: on ? 'var(--ink)' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 'none',
              }}>{on && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3"><path d="M20 6 9 17l-5-5"/></svg>}</div>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: 'oklch(0.96 0.02 148)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'oklch(0.36 0.10 148)' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 10c0 7-8 12-8 12s-8-5-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></svg>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{v.t}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{v.s}</div>
              </div>
            </button>
          );
        })}
        <button style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: 12, borderRadius: 10,
          border: '1.5px dashed var(--hairline)', background: 'transparent', cursor: 'pointer',
          fontFamily: 'inherit', fontSize: 13, color: 'var(--muted)', fontWeight: 600,
        }}>+ Add custom venue</button>
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Match days</div>
      <div style={{ display: 'flex', gap: 6 }}>
        {DAYS.map((d, i) => (
          <button key={i} onClick={() => toggleDay(i)} style={{
            flex: 1, padding: '12px 0', borderRadius: 10,
            border: '1px solid ' + (form.days.includes(i) ? 'var(--ink)' : 'var(--hairline)'),
            background: form.days.includes(i) ? 'var(--ink)' : 'var(--paper)',
            color: form.days.includes(i) ? 'var(--paper)' : 'var(--ink-2)',
            fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, cursor: 'pointer',
          }}>{d}</button>
        ))}
      </div>
      <div style={{ marginTop: 14 }}>
        <Stepper k="matchesPerDay" label="MATCHES PER DAY" min={1} max={8} form={form} set={set} />
      </div>
    </>
  );
}

// =========================================================================
// STEP 6 — Organizers & Scorers
// =========================================================================
function People({ form, set }) {
  const addOrg = () => {
    const v = form.pendingOrganizer.trim();
    if (!v) return;
    set('organizers', [...form.organizers, { name: v, role: 'Co-organizer' }]);
    set('pendingOrganizer', '');
  };
  const removeOrg = (i) => {
    if (form.organizers[i].role === 'Creator') return;
    set('organizers', form.organizers.filter((_, idx) => idx !== i));
  };
  const addScorer = () => {
    const v = form.pendingScorer.trim();
    if (!v) return;
    set('assignedScorers', [...form.assignedScorers, { name: v }]);
    set('pendingScorer', '');
  };
  const removeScorer = (i) => set('assignedScorers', form.assignedScorers.filter((_, idx) => idx !== i));

  return (
    <>
      <StepTitle title="Who runs it." sub="Co-organizers can edit settings · scorers can score any match." />

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Organizers</div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 8 }}>
        <input className="ck-input" placeholder="Add by name or @handle" value={form.pendingOrganizer} onChange={e => set('pendingOrganizer', e.target.value)} onKeyDown={e => e.key === 'Enter' && addOrg()} />
        <button onClick={addOrg} disabled={!form.pendingOrganizer.trim()} style={{ padding: '0 18px', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'inherit', fontWeight: 600, fontSize: 18, cursor: 'pointer', opacity: form.pendingOrganizer.trim() ? 1 : 0.4 }}>+</button>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 22 }}>
        {form.organizers.map((o, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 10, border: '1px solid var(--hairline)' }}>
            <div className="ck-avatar" style={{ width: 32, height: 32, fontSize: 12, fontFamily: 'Inter Tight', fontWeight: 700, background: o.role === 'Creator' ? 'var(--ink)' : 'var(--paper-2)', color: o.role === 'Creator' ? 'var(--paper)' : 'var(--ink)', flex: 'none' }}>{o.name.split(' ').map(w => w[0]).slice(0, 2).join('')}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 600, fontSize: 14 }}>{o.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{o.role}</div>
            </div>
            {o.role !== 'Creator' && (
              <button onClick={() => removeOrg(i)} style={{ background: 'transparent', border: 'none', color: 'var(--muted)', cursor: 'pointer', padding: 4 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
              </button>
            )}
          </div>
        ))}
      </div>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Tournament scorers</div>
      <div style={{ fontSize: 11, color: 'var(--muted)', marginBottom: 8, lineHeight: 1.4 }}>Can score any match in this tournament. Per-match scorers can also be assigned later.</div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 8 }}>
        <input className="ck-input" placeholder="Add scorer" value={form.pendingScorer} onChange={e => set('pendingScorer', e.target.value)} onKeyDown={e => e.key === 'Enter' && addScorer()} />
        <button onClick={addScorer} disabled={!form.pendingScorer.trim()} style={{ padding: '0 18px', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'inherit', fontWeight: 600, fontSize: 18, cursor: 'pointer', opacity: form.pendingScorer.trim() ? 1 : 0.4 }}>+</button>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {form.assignedScorers.length === 0 ? (
          <div style={{ padding: 12, borderRadius: 10, background: 'var(--paper-2)', fontSize: 12, color: 'var(--muted)', textAlign: 'center' }}>No tournament scorers yet</div>
        ) : form.assignedScorers.map((s, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 10, border: '1px solid var(--hairline)' }}>
            <div className="ck-avatar" style={{ width: 32, height: 32, fontSize: 12, fontFamily: 'Inter Tight', fontWeight: 700, flex: 'none' }}>{s.name.split(' ').map(w => w[0]).slice(0, 2).join('')}</div>
            <div style={{ flex: 1, fontWeight: 600, fontSize: 14 }}>{s.name}</div>
            <button onClick={() => removeScorer(i)} style={{ background: 'transparent', border: 'none', color: 'var(--muted)', cursor: 'pointer', padding: 4 }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
            </button>
          </div>
        ))}
      </div>
    </>
  );
}

// =========================================================================
// STEP 7 — Prize & Invites
// =========================================================================
function PrizeInvites({ form, set }) {
  const [copied, setCopied] = React.useState(false);
  return (
    <>
      <StepTitle title="Prize & invites." sub="Money on the line and how teams get in." />

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Entry & prizes</div>
      <label className="ck-label">Entry fee per team</label>
      <div style={{ position: 'relative', marginBottom: 14 }}>
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--muted)', fontSize: 14, fontFamily: 'JetBrains Mono' }}>Rs.</span>
        <input className="ck-input" type="number" value={form.entryFee} onChange={e => set('entryFee', +e.target.value)} style={{ paddingLeft: 44 }} />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 14 }}>
        <div>
          <label className="ck-label">Winner</label>
          <input className="ck-input" type="number" value={form.prizeWinner} onChange={e => set('prizeWinner', +e.target.value)} />
        </div>
        <div>
          <label className="ck-label">Runner-up</label>
          <input className="ck-input" type="number" value={form.prizeRunner} onChange={e => set('prizeRunner', +e.target.value)} />
        </div>
      </div>

      <label className="ck-label">Player of the match</label>
      <input className="ck-input" value={form.prizeMOM} onChange={e => set('prizeMOM', e.target.value)} placeholder="e.g. Trophy + Rs.500" />

      <label className="ck-label" style={{ marginTop: 14 }}>Other prize details (optional)</label>
      <textarea className="ck-input" value={form.prizeDetails} onChange={e => set('prizeDetails', e.target.value)} rows={2} style={{ resize: 'vertical', minHeight: 56, fontFamily: 'inherit' }} placeholder="Best batter / bowler / fielder..." />

      <div style={{ marginTop: 14, padding: 12, borderRadius: 10, background: 'oklch(0.94 0.05 90)', border: '1px solid oklch(0.86 0.05 90)', fontSize: 12, color: 'var(--ink-2)' }}>
        Pool collected: <strong style={{ color: 'var(--ink)', fontFamily: 'JetBrains Mono' }}>Rs. {(form.entryFee * form.maxTeams).toLocaleString()}</strong> (max) · payout <strong style={{ color: 'var(--ink)', fontFamily: 'JetBrains Mono' }}>Rs. {(form.prizeWinner + form.prizeRunner).toLocaleString()}</strong>
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Share link</div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 14 }}>
        <input className="ck-input" value={form.inviteLink} onChange={e => set('inviteLink', e.target.value)} />
        <button onClick={() => { setCopied(true); setTimeout(() => setCopied(false), 1200); }} style={{
          padding: '0 14px', borderRadius: 10, border: '1px solid var(--hairline)',
          background: copied ? 'var(--green)' : 'var(--paper-2)', color: copied ? 'white' : 'var(--ink)',
          fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>{copied ? '✓ Copied' : 'Copy'}</button>
      </div>

      <ToggleRow k="autoApprove" t="Auto-approve via link" s="Anyone with the link can register a team without manual approval" form={form} set={set} />
    </>
  );
}

// =========================================================================
// STEP 8 — Review
// =========================================================================
function Review({ form, jumpTo }) {
  const fmt = FORMAT_OPTIONS.find(f => f.id === form.tournamentType)?.t;
  const venueNames = form.venues.map(id => VENUE_OPTIONS.find(v => v.id === id)?.t).join(' · ');
  const dayLabels = form.days.map(i => DAYS[i]).join(' · ');
  const tieBreakLabel = form.tieBreakers.map(id => TIE_BREAKERS.find(x => x.id === id)?.t).join(' → ');
  const ageLabel = form.minAge || form.maxAge ? `${form.minAge || '–'}–${form.maxAge || '–'}` : 'No restriction';
  const ruleSummary = [
    form.allowMultiTeamPlayers && 'multi-team',
    form.allowMidTournamentSquadChanges && 'flex squad',
    form.requireClaimedProfiles && 'claimed only',
  ].filter(Boolean).join(' · ') || 'standard';

  const Row = ({ label, value, step }) => (
    <button onClick={() => jumpTo(step)} style={{
      display: 'flex', alignItems: 'center', gap: 10, padding: '12px 0',
      width: '100%', background: 'transparent', border: 'none', borderBottom: '1px solid var(--hairline)',
      cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
    }}>
      <div style={{ width: 100, fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.06em', textTransform: 'uppercase', flex: 'none' }}>{label}</div>
      <div style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>{value}</div>
      <div style={{ fontSize: 11, color: 'var(--muted)' }}>edit</div>
    </button>
  );

  return (
    <>
      <StepTitle title="Review & publish." sub="Publishing moves status to Registration. Tap any row to edit." />

      <div style={{ padding: 16, borderRadius: 14, background: form.coverColor, color: 'var(--paper)', marginBottom: 18, position: 'relative', overflow: 'hidden' }}>
        <svg width="200" height="200" viewBox="0 0 200 200" style={{ position: 'absolute', right: -50, top: -50, opacity: 0.15 }}>
          <ellipse cx="100" cy="100" rx="90" ry="60" stroke="white" fill="none" strokeWidth="0.6"/>
          <ellipse cx="100" cy="100" rx="50" ry="32" stroke="white" fill="none" strokeWidth="0.6"/>
        </svg>
        <div style={{ position: 'relative' }}>
          <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', opacity: 0.85, letterSpacing: '0.1em' }}>STATUS · DRAFT → REGISTRATION</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 700, lineHeight: 1.1, letterSpacing: '-0.025em', marginTop: 4 }}>{form.tournamentName}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, opacity: 0.85, marginTop: 6 }}>{form.maxTeams} teams · {fmt} · T{form.oversPerInnings} · {form.ballType}</div>
        </div>
      </div>

      <Row label="Privacy" value={form.privacy} step={0} />
      <Row label="Format" value={fmt + (form.tournamentType === 'GroupKnockout' ? ` · ${form.groups}×${Math.ceil(form.maxTeams / form.groups)}` : form.playoffsEnabled ? ` · top ${form.playoffTeams} playoffs` : '')} step={1} />
      <Row label="Capacity" value={`${form.minTeams}–${form.maxTeams} teams`} step={1} />
      <Row label="Match" value={`T${form.oversPerInnings} · ${form.playersPerTeam}-a-side · ${form.ballType}`} step={2} />
      <Row label="Powerplay" value={form.powerplayEnabled ? `${form.powerplayOvers} ov · bowler max ${form.maxOversPerBowler}` : 'Off'} step={2} />
      <Row label="Eligibility" value={`${form.genderRule === 'Open' ? 'Open' : form.genderRule.replace(/([A-Z])/g, ' $1').trim()} · age ${ageLabel}`} step={3} />
      <Row label="Squad rules" value={ruleSummary} step={3} />
      <Row label="Points" value={`W ${form.pointsForWin} · L ${form.pointsForLoss} · T ${form.pointsForTie} · NR ${form.pointsForNoResult}`} step={3} />
      <Row label="Tie-break" value={tieBreakLabel} step={3} />
      <Row label="Teams" value={`${form.teamList.filter(t => t.name).length} added`} step={4} />
      <Row label="Reg. closes" value={form.registrationDeadline} step={5} />
      <Row label="Dates" value={`${form.startDate} → ${form.endDate}`} step={5} />
      <Row label="Cadence" value={`${dayLabels} · ${form.matchesPerDay}/day`} step={5} />
      <Row label="Venues" value={venueNames || '—'} step={5} />
      <Row label="Organizers" value={`${form.organizers.length} · ${form.assignedScorers.length} scorer${form.assignedScorers.length !== 1 ? 's' : ''}`} step={6} />
      <Row label="Entry fee" value={`Rs. ${form.entryFee.toLocaleString()} / team`} step={7} />
      <Row label="Prize pool" value={`Rs. ${(form.prizeWinner + form.prizeRunner).toLocaleString()}`} step={7} />

      <div style={{ marginTop: 18, padding: 12, borderRadius: 10, background: 'oklch(0.94 0.05 90)', border: '1px solid oklch(0.86 0.05 90)', fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5 }}>
        <strong>What happens on publish:</strong> Status becomes <strong>Registration</strong>. Captains get notified, teams can join until {form.registrationDeadline}. You can keep editing rules until the first ball.
      </div>
    </>
  );
}

// =========================================================================
// SUCCESS — Status: Registration open
// =========================================================================
function SuccessScreen({ form, reset }) {
  const fmt = FORMAT_OPTIONS.find(f => f.id === form.tournamentType)?.t;
  const matches = form.tournamentType === 'GroupKnockout' ? form.maxTeams + 6
    : form.tournamentType === 'Knockout' ? form.maxTeams - 1
    : form.tournamentType === 'League' ? form.maxTeams * (form.maxTeams - 1)
    : form.maxTeams * (form.maxTeams - 1) / 2;
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--ink)', color: 'var(--paper)' }}>
      <div style={{ padding: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.1em', display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 6, height: 6, borderRadius: 999, background: 'oklch(0.78 0.14 80)' }} />REGISTRATION OPEN
        </div>
        <button onClick={reset} style={{ background: 'transparent', border: 'none', color: 'oklch(0.72 0.01 80)', fontSize: 12, fontFamily: 'inherit', cursor: 'pointer' }}>Start over</button>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 28px' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.12em' }}>YOUR TOURNAMENT IS LIVE</div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 38, fontWeight: 700, lineHeight: 1.05, letterSpacing: '-0.03em', marginTop: 8 }}>{form.tournamentName}</div>
        <div style={{ fontSize: 13, color: 'oklch(0.78 0.01 80)', marginTop: 6 }}>{fmt} · T{form.oversPerInnings} · {form.ballType}</div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', marginTop: 24, borderTop: '1px solid oklch(0.30 0.02 80)', borderBottom: '1px solid oklch(0.30 0.02 80)' }}>
          {[
            { l: 'TEAMS', v: `${form.teamList.filter(t => t.name).length}/${form.maxTeams}` },
            { l: 'MATCHES', v: matches },
            { l: 'PRIZE', v: `Rs.${((form.prizeWinner + form.prizeRunner) / 1000).toFixed(0)}k` },
          ].map((s, i) => (
            <div key={i} style={{ padding: '14px 12px', borderLeft: i ? '1px solid oklch(0.30 0.02 80)' : 'none' }}>
              <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'oklch(0.62 0.02 80)', letterSpacing: '0.08em' }}>{s.l}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', marginTop: 2 }}>{s.v}</div>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 18, fontSize: 13, color: 'oklch(0.78 0.01 80)', lineHeight: 1.5 }}>
          Registration closes <strong style={{ color: 'var(--paper)' }}>{form.registrationDeadline}</strong>. Tournament starts <strong style={{ color: 'var(--paper)' }}>{form.startDate} · {form.startTime}</strong>. Status will move to <strong style={{ color: 'var(--paper)' }}>Upcoming</strong> once {form.minTeams} teams are approved.
        </div>
      </div>
      <div style={{ padding: '12px 20px 22px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button onClick={() => {
          if (typeof window !== 'undefined') window.__ckLastTournament = { ...form, status: 'registration' };
          if (window.__ckNav) {
            window.__ckNav.popToRoot();
            window.__ckNav.push('manage');
          } else {
            reset();
          }
        }} style={{ width: '100%', padding: 14, borderRadius: 12, border: 'none', background: 'var(--paper)', color: 'var(--ink)', fontWeight: 600, fontSize: 14, fontFamily: 'inherit', cursor: 'pointer' }}>Open tournament dashboard</button>
        <button onClick={reset} style={{ width: '100%', padding: 12, borderRadius: 12, border: '1px solid oklch(0.30 0.02 80)', background: 'transparent', color: 'var(--paper)', fontWeight: 500, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer' }}>Share invite link</button>
      </div>
    </div>
  );
}

window.CkCreate = Create;

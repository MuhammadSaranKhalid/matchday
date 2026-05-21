// MatchSetup.jsx — One-to-one (friendly) match setup wizard, Phase A.
// 6 steps: Type → Opponent → Format → Venue & Time → Scorer → Review.
// Match-day phase (toss · XI · openers) lives in Setup.jsx (SetupA/B/C).
//
// Public API:
//   <CkMatchSetup initialStep={1} />  // 1..6, or "result" for the post-send confirmation

(function () {

const ink     = 'var(--ink)';
const ink2    = 'var(--ink-2)';
const muted   = 'var(--muted)';
const paper   = 'var(--paper)';
const paper2  = 'var(--paper-2)';
const hair    = 'var(--hairline)';
const red     = 'var(--red)';
const green   = 'var(--green)';
const amber   = 'oklch(0.74 0.14 75)';
const cream   = 'var(--cream)';

const display = (size) => ({
  fontFamily: 'Inter Tight, system-ui',
  fontSize: size, fontWeight: 700, letterSpacing: '-0.025em', color: ink, lineHeight: 1.1,
});
const mono = { fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.08em', fontWeight: 700, textTransform: 'uppercase' };

// ─────────────────────────────────────────────────────────
// Header — step indicator + back + title
// ─────────────────────────────────────────────────────────
function MsHeader({ step, total, title, sub, onBack }) {
  return (
    <div style={{ padding: '14px 18px 16px', borderBottom: '1px solid ' + hair, background: paper }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
        <button onClick={onBack} aria-label="Back" style={{
          width: 32, height: 32, borderRadius: 8, border: '1px solid ' + hair,
          background: paper, cursor: 'pointer', display: 'flex',
          alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
        </button>
        <div style={{ ...mono, fontSize: 10, color: muted }}>
          Match setup · Step {step} of {total}
        </div>
        <div style={{ flex: 1 }} />
        <div style={{ ...mono, fontSize: 10, color: muted }}>Friendly</div>
      </div>
      {/* progress bar */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 14 }}>
        {Array.from({ length: total }, (_, i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: i < step ? ink : (i === step - 1 ? ink : 'rgba(20,18,14,0.10)'),
          }}/>
        ))}
      </div>
      <div style={{ ...display(24) }}>{title}</div>
      {sub && <div style={{ fontSize: 13, color: ink2, marginTop: 4, lineHeight: 1.4 }}>{sub}</div>}
    </div>
  );
}

// Sticky bottom CTA bar
function MsCta({ onBack, onNext, nextLabel = 'Continue', nextDisabled, secondary, onSecondary }) {
  return (
    <div style={{
      borderTop: '1px solid ' + hair, padding: '12px 18px',
      background: paper, display: 'flex', gap: 10, alignItems: 'center',
      paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
    }}>
      {secondary && (
        <button onClick={onSecondary} style={{
          padding: '12px 16px', borderRadius: 10,
          border: '1px solid ' + hair, background: paper, color: ink,
          fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
        }}>{secondary}</button>
      )}
      <button onClick={onNext} disabled={nextDisabled} style={{
        flex: 1, padding: '12px 16px', borderRadius: 10,
        border: 'none', background: nextDisabled ? paper2 : ink,
        color: nextDisabled ? muted : paper,
        fontWeight: 700, fontSize: 14, cursor: nextDisabled ? 'default' : 'pointer',
        fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        {nextLabel}
        {!nextDisabled && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><path d="M9 18l6-6-6-6"/></svg>}
      </button>
    </div>
  );
}

// Pill / chip
function Chip({ active, onClick, children, color }) {
  return (
    <button onClick={onClick} style={{
      padding: '10px 14px', borderRadius: 999,
      border: '1px solid ' + (active ? (color || ink) : hair),
      background: active ? (color || ink) : paper,
      color: active ? paper : ink,
      fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: 'inherit',
      whiteSpace: 'nowrap',
    }}>{children}</button>
  );
}

function SectionLabel({ children, hint }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 8 }}>
      <div style={{ ...mono, fontSize: 10, color: muted }}>{children}</div>
      {hint && <div style={{ fontSize: 11, color: muted }}>{hint}</div>}
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// STEP 1 — Match type
// ─────────────────────────────────────────────────────────
function Step1Type({ onBack, onNext, value, setValue }) {
  const types = [
    { id: 'friendly', t: 'Friendly',  s: 'One-off match between two teams. No tournament wrapper. Stats count.', icon: '◉', accent: red,  rec: true },
    { id: 'league',   t: 'League fixture', s: 'Part of an ongoing league. Adds to the league table.',                icon: '⚑', accent: ink },
    { id: 'cup',      t: 'Cup tie',   s: 'Knockout fixture inside a tournament you organize.',                       icon: '♛', accent: amber },
  ];
  return (
    <>
      <MsHeader step={1} total={6} title="What kind of match?" sub="Pick the wrapper. Friendly is the most common — two teams, one match, stats count." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 18px', display: 'grid', gap: 10 }}>
        {types.map(ty => (
          <button key={ty.id} onClick={() => setValue(ty.id)} style={{
            display: 'flex', gap: 14, padding: '14px 14px',
            background: value === ty.id ? paper2 : paper,
            border: '2px solid ' + (value === ty.id ? ink : hair),
            borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10, background: ty.accent, color: paper,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 18, fontWeight: 700, flexShrink: 0,
            }}>{ty.icon}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontWeight: 700, fontSize: 15, color: ink }}>{ty.t}</span>
                {ty.rec && <span style={{ ...mono, fontSize: 9, padding: '2px 6px', borderRadius: 4, background: ink, color: paper }}>Most common</span>}
              </div>
              <div style={{ fontSize: 12, color: muted, marginTop: 3, lineHeight: 1.4 }}>{ty.s}</div>
            </div>
            <div style={{
              width: 20, height: 20, borderRadius: 999,
              border: '2px solid ' + (value === ty.id ? ink : hair),
              background: value === ty.id ? ink : 'transparent',
              flexShrink: 0, alignSelf: 'center',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {value === ty.id && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
            </div>
          </button>
        ))}
      </div>
      <MsCta onBack={onBack} onNext={onNext} nextDisabled={!value} />
    </>
  );
}

// ─────────────────────────────────────────────────────────
// STEP 2 — Opponent
// ─────────────────────────────────────────────────────────
function Step2Opponent({ onBack, onNext, opp, setOpp, query, setQuery, neededPlayers }) {
  const myTeam = { name: 'Lahore Lions', sub: 'Your team · Captained · 14 squad', color: red };
  const recent = [
    { name: 'Karachi Eagles',  sub: 'Played 3× · last May 2 · won 2', squad: 18, color: 'oklch(0.55 0.15 250)' },
    { name: 'DHA United',      sub: 'Played 1× · last Mar 18',         squad: 16, color: green },
    { name: 'Mohalla Kings',   sub: 'Never played',                    squad: 12, color: amber },
    { name: 'Old Boys CC',     sub: 'Played 2× · last Aug 9',          squad: 22, color: ink },
  ];
  const need = neededPlayers || 11;
  const filtered = query
    ? recent.filter(t => t.name.toLowerCase().includes(query.toLowerCase()))
    : recent;

  return (
    <>
      <MsHeader step={2} total={6} title="Pick your opponent" sub="Lahore Lions vs …" onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto' }}>

        {/* My team — fixed */}
        <div style={{ padding: '16px 18px 6px' }}>
          <SectionLabel>Your team</SectionLabel>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: 12,
            background: paper, border: '1px solid ' + hair, borderRadius: 10,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 9, background: myTeam.color, color: paper,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15,
            }}>LL</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: 14 }}>{myTeam.name}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{myTeam.sub}</div>
            </div>
            <button style={{
              ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 5,
              border: '1px solid ' + hair, background: paper, color: muted, cursor: 'pointer', fontFamily: 'JetBrains Mono',
            }}>Change</button>
          </div>
        </div>

        {/* VS divider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 18px' }}>
          <div style={{ flex: 1, height: 1, background: hair }}/>
          <div style={{ ...mono, fontSize: 10, color: muted }}>VS</div>
          <div style={{ flex: 1, height: 1, background: hair }}/>
        </div>

        {/* Search */}
        <div style={{ padding: '0 18px 12px' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', background: paper2, border: '1px solid ' + hair, borderRadius: 10,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
            <input
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search teams by name or city"
              style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontSize: 14, fontFamily: 'inherit', color: ink }}
            />
          </div>
        </div>

        {/* Recent / results */}
        <div style={{ padding: '0 18px 8px' }}>
          <SectionLabel>{query ? `${filtered.length} results` : 'Recent opponents'}</SectionLabel>
          <div style={{ display: 'grid', gap: 6 }}>
            {filtered.map((t, i) => (
              <button key={i} onClick={() => setOpp(t.name)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: 10,
                background: opp === t.name ? paper2 : paper,
                border: '2px solid ' + (opp === t.name ? ink : hair),
                borderRadius: 10, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 8, background: t.color, color: paper,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, flexShrink: 0,
                }}>{t.name.split(' ').map(s => s[0]).join('').slice(0, 2)}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 600, fontSize: 13 }}>{t.name}</span>
                    {t.squad < need && (
                      <span style={{
                        ...mono, fontSize: 8, padding: '2px 6px', borderRadius: 4,
                        background: amber, color: paper, letterSpacing: '0.06em',
                      }}>Tight · needs {need}</span>
                    )}
                  </div>
                  <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{t.sub}</div>
                </div>
                <span style={{
                  ...mono, fontSize: 9,
                  color: t.squad < need ? amber : muted,
                }}>{t.squad} sq</span>
              </button>
            ))}
          </div>
        </div>

        {/* Invite escape hatch */}
        <div style={{ padding: '12px 18px 24px' }}>
          <SectionLabel>Can't find them?</SectionLabel>
          <button style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '12px',
            background: paper, border: '1px dashed ' + hair, borderRadius: 10,
            cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 8, background: paper2,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="1.8" strokeLinecap="round"><path d="M16 12h6M19 9v6"/><path d="M14 16v-2a4 4 0 0 0-4-4H4"/><circle cx="9" cy="7" r="4"/></svg>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>Invite a captain to join circk</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>They build their team, then accept your fixture.</div>
            </div>
          </button>
        </div>

      </div>
      <MsCta onBack={onBack} onNext={onNext} nextDisabled={!opp} />
    </>
  );
}

// ─────────────────────────────────────────────────────────
// STEP 3 — Format
// ─────────────────────────────────────────────────────────
function Step3Format({ onBack, onNext, format, setFormat }) {
  const overOptions = [10, 15, 20, 25, 30, 40, 50];
  const ballOptions = [
    { id: 'white', t: 'White ball', s: 'limited overs · day-night' },
    { id: 'red',   t: 'Red ball',   s: 'multi-day · daylight' },
    { id: 'tape',  t: 'Tape ball',  s: 'softball / mohalla cricket' },
  ];
  const playerOptions = [
    { n: 11, l: 'Full' },
    { n: 9,  l: 'School' },
    { n: 8,  l: 'Corporate' },
    { n: 7,  l: 'Mohalla' },
    { n: 6,  l: 'Six-a-side' },
  ];
  return (
    <>
      <MsHeader step={3} total={6} title="Match format" sub="How long, what ball, how many a side." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 18px' }}>

        <SectionLabel hint="Per innings">Overs</SectionLabel>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 22 }}>
          {overOptions.map(o => (
            <Chip key={o} active={format.overs === o} onClick={() => setFormat({ ...format, overs: o })}>
              {o} overs
            </Chip>
          ))}
          <Chip active={false}>Custom…</Chip>
        </div>

        <SectionLabel hint="Each team fields this many">Players per side</SectionLabel>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 6, marginBottom: 8 }}>
          {playerOptions.map(p => {
            const active = format.players === p.n;
            return (
              <button key={p.n} onClick={() => setFormat({ ...format, players: p.n })} style={{
                padding: '10px 0', borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit',
                background: active ? ink : paper,
                color: active ? paper : ink,
                border: '1px solid ' + (active ? ink : hair),
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              }}>
                <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 20, letterSpacing: '-0.02em' }}>{p.n}</div>
                <div style={{ ...mono, fontSize: 8, opacity: 0.75, letterSpacing: '0.08em' }}>{p.l}</div>
              </button>
            );
          })}
        </div>
        <button onClick={() => {
          const v = parseInt(window.prompt('Custom players per side (5–15):', String(format.players || 11)), 10);
          if (v >= 5 && v <= 15) setFormat({ ...format, players: v });
        }} style={{
          width: '100%', padding: '8px 0', background: paper2, border: '1px dashed ' + hair,
          borderRadius: 8, fontSize: 12, color: muted, cursor: 'pointer', fontFamily: 'inherit', marginBottom: 22,
        }}>Custom (5–15)… {![11,9,8,7,6].includes(format.players) ? `· ${format.players}· selected` : ''}</button>

        <SectionLabel>Ball type</SectionLabel>
        <div style={{ display: 'grid', gap: 8, marginBottom: 22 }}>
          {ballOptions.map(b => (
            <button key={b.id} onClick={() => setFormat({ ...format, ball: b.id })} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: 12,
              background: format.ball === b.id ? paper2 : paper,
              border: '2px solid ' + (format.ball === b.id ? ink : hair),
              borderRadius: 10, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{
                width: 24, height: 24, borderRadius: 999,
                background: b.id === 'red' ? '#a83a3a' : b.id === 'tape' ? '#d8a85e' : '#fafafa',
                border: '1px solid ' + (b.id === 'white' ? hair : 'transparent'),
                flexShrink: 0,
              }}/>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 13 }}>{b.t}</div>
                <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{b.s}</div>
              </div>
              <div style={{
                width: 18, height: 18, borderRadius: 999,
                border: '2px solid ' + (format.ball === b.id ? ink : hair),
                background: format.ball === b.id ? ink : 'transparent',
                flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {format.ball === b.id && <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
              </div>
            </button>
          ))}
        </div>

        <SectionLabel>Powerplay</SectionLabel>
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {[4, 5, 6].map(pp => (
            <Chip key={pp} active={format.pp === pp} onClick={() => setFormat({ ...format, pp })}>{pp} overs</Chip>
          ))}
          <Chip active={format.pp === 0} onClick={() => setFormat({ ...format, pp: 0 })}>None</Chip>
        </div>

        <SectionLabel>Other</SectionLabel>
        <div style={{ display: 'grid', gap: 8 }}>
          {[
            { id: 'dls',    t: 'DLS / VJD on rain interruption' },
            { id: 'super',  t: 'Super over on tie' },
            { id: 'free',   t: 'Free hit on no-ball (front-foot)' },
          ].map(opt => {
            const on = !!format[opt.id];
            return (
              <button key={opt.id} onClick={() => setFormat({ ...format, [opt.id]: !on })} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
                background: paper, border: '1px solid ' + hair, borderRadius: 10,
                cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
              }}>
                <div style={{
                  width: 36, height: 22, borderRadius: 999, padding: 2,
                  background: on ? ink : 'rgba(20,18,14,0.10)',
                  display: 'flex', justifyContent: on ? 'flex-end' : 'flex-start',
                  transition: 'background 0.15s',
                }}>
                  <div style={{ width: 18, height: 18, borderRadius: 999, background: paper }}/>
                </div>
                <span style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>{opt.t}</span>
              </button>
            );
          })}
        </div>

      </div>
      <MsCta onBack={onBack} onNext={onNext} nextDisabled={!format.overs || !format.ball} />
    </>
  );
}

// ─────────────────────────────────────────────────────────
// STEP 4 — Venue & time
// ─────────────────────────────────────────────────────────
function Step4Venue({ onBack, onNext, venue, setVenue, when, setWhen }) {
  const recentVenues = [
    { name: 'Model Town Ground', sub: '5 km · last Mar 14 · 2 pitches' },
    { name: 'DHA Sports Complex', sub: '8 km · last Aug 9 · floodlit' },
    { name: 'Gulberg Pitch 2',     sub: '12 km · last Feb 6' },
  ];
  return (
    <>
      <MsHeader step={4} total={6} title="When & where" onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 18px' }}>

        {/* Date / time */}
        <SectionLabel>Date</SectionLabel>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6, marginBottom: 12 }}>
          {[
            { d: 'SAT', n: 18, m: 'Mar' },
            { d: 'SUN', n: 19, m: 'Mar' },
            { d: 'SAT', n: 25, m: 'Mar' },
            { d: 'SUN', n: 26, m: 'Mar' },
          ].map((d, i) => (
            <button key={i} onClick={() => setWhen({ ...when, date: `${d.m} ${d.n}` })} style={{
              padding: '10px 0', background: when.date === `${d.m} ${d.n}` ? ink : paper,
              color: when.date === `${d.m} ${d.n}` ? paper : ink,
              border: '1px solid ' + (when.date === `${d.m} ${d.n}` ? ink : hair),
              borderRadius: 8, cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            }}>
              <div style={{ ...mono, fontSize: 9, opacity: 0.7 }}>{d.d}</div>
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18 }}>{d.n}</div>
              <div style={{ fontSize: 9, opacity: 0.7 }}>{d.m}</div>
            </button>
          ))}
        </div>
        <button style={{
          width: '100%', padding: '8px 0', background: paper2, border: '1px dashed ' + hair,
          borderRadius: 8, fontSize: 12, color: muted, cursor: 'pointer', fontFamily: 'inherit', marginBottom: 22,
        }}>Pick another date…</button>

        <SectionLabel>Start time</SectionLabel>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 22 }}>
          {['07:00', '15:00', '16:00', '17:00', '18:00', '18:30', '19:00'].map(t => (
            <Chip key={t} active={when.time === t} onClick={() => setWhen({ ...when, time: t })}>{t}</Chip>
          ))}
        </div>

        <SectionLabel hint="Recent">Venue</SectionLabel>
        <div style={{ display: 'grid', gap: 6, marginBottom: 12 }}>
          {recentVenues.map((v, i) => (
            <button key={i} onClick={() => setVenue(v.name)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: 10,
              background: venue === v.name ? paper2 : paper,
              border: '2px solid ' + (venue === v.name ? ink : hair),
              borderRadius: 10, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8, background: paper2,
                border: '1px solid ' + hair,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 13 }}>{v.name}</div>
                <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{v.sub}</div>
              </div>
            </button>
          ))}
        </div>
        <button style={{
          width: '100%', padding: '10px 0', background: paper, border: '1px solid ' + hair,
          borderRadius: 8, fontSize: 13, color: ink, cursor: 'pointer', fontFamily: 'inherit', fontWeight: 600,
        }}>+ New venue</button>

      </div>
      <MsCta onBack={onBack} onNext={onNext} nextDisabled={!venue || !when.date || !when.time} />
    </>
  );
}

// ─────────────────────────────────────────────────────────
// STEP 5 — Scorer
// ─────────────────────────────────────────────────────────
function Step5Scorer({ onBack, onNext, scorer, setScorer }) {
  const opts = [
    { id: 'me',      t: 'I will score',                s: 'You score the match live or enter post-match.', icon: '◉', accent: ink, rec: true },
    { id: 'them',    t: 'Opponent captain scores',     s: 'They run the scoring app. Stats sync to both teams.', icon: '⚑', accent: red },
    { id: 'neutral', t: 'Pick a neutral scorer',       s: 'Someone trusted by both sides. Reduces disputes.', icon: '✦', accent: amber },
    { id: 'co',      t: 'Both captains co-score',      s: 'Each marks balls for their bowler. Auto-merges.',   icon: '⇋', accent: green },
  ];
  return (
    <>
      <MsHeader step={5} total={6} title="Who scores?" sub="A scorer enters every ball. You can change later." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 18px', display: 'grid', gap: 10 }}>
        {opts.map(o => (
          <button key={o.id} onClick={() => setScorer(o.id)} style={{
            display: 'flex', gap: 14, padding: '14px',
            background: scorer === o.id ? paper2 : paper,
            border: '2px solid ' + (scorer === o.id ? ink : hair),
            borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10, background: o.accent, color: paper,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 16, fontWeight: 700, flexShrink: 0,
            }}>{o.icon}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontWeight: 700, fontSize: 14 }}>{o.t}</span>
                {o.rec && <span style={{ ...mono, fontSize: 9, padding: '2px 6px', borderRadius: 4, background: ink, color: paper }}>Default</span>}
              </div>
              <div style={{ fontSize: 12, color: muted, marginTop: 3, lineHeight: 1.4 }}>{o.s}</div>
            </div>
            <div style={{
              width: 20, height: 20, borderRadius: 999,
              border: '2px solid ' + (scorer === o.id ? ink : hair),
              background: scorer === o.id ? ink : 'transparent',
              flexShrink: 0, alignSelf: 'center',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {scorer === o.id && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
            </div>
          </button>
        ))}
      </div>
      <MsCta onBack={onBack} onNext={onNext} nextDisabled={!scorer} nextLabel="Continue"/>
    </>
  );
}

// ─────────────────────────────────────────────────────────
// STEP 6 — Review & send
// ─────────────────────────────────────────────────────────
// ───────────────────────────────────────────────────────────
// STEP 6 — Pick playing XI (sender)
// ───────────────────────────────────────────────────────────
// ───────────────────────────────────────────────────────────
// STEP 6 · GATE — fires when squad < playersPerSide (inline RosterThin)
// 5 sub-views in one component: picker → borrow / unclaimed / reduce / forfeit → resolves
// ───────────────────────────────────────────────────────────
function Step6Gate({ onBack, onResolve, need, have, initialView = 'picker' }) {
  const [view, setView] = React.useState(initialView);

  if (view === 'borrow')    return <GateBorrow    short={need - have} onBack={() => setView('picker')} onDone={(added) => onResolve('borrow', { added })} />;
  if (view === 'unclaimed') return <GateUnclaimed short={need - have} onBack={() => setView('picker')} onDone={(added) => onResolve('unclaimed', { added })} />;

  return <GatePicker need={need} have={have} onBack={onBack} onPick={setView} />;
}

// ── picker
function GatePicker({ need, have, onBack, onPick }) {
  const short = need - have;
  const options = [
    { id: 'borrow',    title: 'Borrow a player',  sub: `Find ${short} guest${short === 1 ? '' : 's'} from another team — allowed in friendlies. Both captains agree.`, tint: ink, rec: true },
    { id: 'unclaimed', title: 'Add as unclaimed', sub: 'Just a name. They can claim the profile later — stats migrate over.', tint: amber },
  ];
  return (
    <>
      <MsHeader step={6} total={7} title="Roster too thin." sub={`Need ${need} a side. Your squad has ${have}. Add more players before picking your XI — or back out and rethink the format.`} onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 24px' }}>
        <div style={{
          padding: 14, borderRadius: 12, background: cream, color: ink,
          display: 'flex', alignItems: 'center', gap: 14, marginBottom: 16,
        }}>
          <div style={{
            width: 52, height: 52, borderRadius: 12, background: amber, color: paper,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 24, letterSpacing: '-0.04em',
          }}>−{short}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 700 }}>Short {short} player{short === 1 ? '' : 's'}</div>
            <div style={{ fontSize: 11, color: ink2, marginTop: 2 }}>Have {have} · need {need} for this format</div>
            <div style={{ display: 'flex', gap: 3, marginTop: 6 }}>
              {Array.from({ length: need }, (_, i) => (
                <span key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i < have ? green : 'rgba(20,18,14,0.10)' }} />
              ))}
            </div>
          </div>
        </div>

        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>FILL THE GAP</div>
        {options.map(o => (
          <button key={o.id} onClick={() => onPick(o.id)} style={{
            width: '100%', display: 'flex', gap: 12, padding: 14, marginBottom: 8,
            background: paper, border: '1.5px solid ' + hair,
            borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10, flexShrink: 0,
              background: o.tint, color: paper,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16,
            }}>{o.id === 'borrow' ? '⊟' : '?'}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <span style={{ fontWeight: 700, fontSize: 13.5, color: ink }}>{o.title}</span>
                {o.rec && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 4, background: ink, color: paper }}>MOST COMMON</span>}
              </div>
              <div style={{ fontSize: 11.5, color: muted, marginTop: 3, lineHeight: 1.45 }}>{o.sub}</div>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2" style={{ alignSelf: 'center', flexShrink: 0 }}><path d="M9 18l6-6-6-6"/></svg>
          </button>
        ))}

        <div style={{ marginTop: 14, padding: 14, background: paper2, borderRadius: 12, fontSize: 12, color: ink2, lineHeight: 1.5 }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 6 }}>OR BACK OUT</div>
          To play a <b style={{ color: ink }}>smaller format</b> (e.g. {have}-a-side), go back to Step 3 and change “Players per side.” The request hasn't been sent yet — no consequence for changing your mind.
        </div>
      </div>
    </>
  );
}

// ── BORROW — search local players, multi-add ──────────────
function GateBorrow({ short, onBack, onDone }) {
  const NEARBY = [
    { id: 'g1', name: 'Wajid Ali',    team: 'Model Town XI',   meta: 'AR · RHB · OS · 24 m',  dist: '2 km'  },
    { id: 'g2', name: 'Salman Yousuf', team: 'Race Course CC',  meta: 'BAT · LHB · 18 m',      dist: '4 km'  },
    { id: 'g3', name: 'Naveed Iqbal', team: 'Cantt Cricketers', meta: 'BWL · RFM · 31 m',      dist: '5 km'  },
    { id: 'g4', name: 'Tariq Bhatti', team: 'Iqbal Park XI',    meta: 'BAT · RHB · 14 m',      dist: '6 km'  },
    { id: 'g5', name: 'Aamir Shah',   team: 'Defence Boys',     meta: 'WK · LHB · 22 m',       dist: '7 km'  },
    { id: 'g6', name: 'Ibrahim Khan', team: 'Mughalpura CC',    meta: 'AR · LHB · SLA · 28 m', dist: '8 km'  },
  ];
  const [q, setQ] = React.useState('');
  const [picked, setPicked] = React.useState(new Set());
  const matches = q ? NEARBY.filter(p => (p.name + p.team).toLowerCase().includes(q.toLowerCase())) : NEARBY;
  const toggle = (id) => setPicked(p => {
    const n = new Set(p); n.has(id) ? n.delete(id) : n.add(id); return n;
  });
  const enough = picked.size >= short;

  return (
    <>
      <MsHeader step={6} total={7} title="Borrow players." sub={`Find ${short} guest${short === 1 ? '' : 's'} from nearby teams. They'll appear with a "guest" pill in match stats.`} onBack={onBack}/>

      <div style={{
        padding: '10px 18px', borderBottom: '1px solid ' + hair, background: paper,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{ ...mono, fontSize: 10, color: enough ? green : ink2 }}>
          GUESTS · {picked.size}/{short}
        </div>
        <div style={{ flex: 1, height: 4, background: paper2, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ width: `${Math.min(100, (picked.size / short) * 100)}%`, height: '100%', background: enough ? green : ink, transition: 'width 0.15s' }}/>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        <div style={{ padding: '12px 18px' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', background: paper2, border: '1px solid ' + hair, borderRadius: 10,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search by name or club"
              style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontSize: 14, fontFamily: 'inherit', color: ink }}/>
          </div>
        </div>

        <div style={{ padding: '0 18px 6px' }}>
          <SectionLabel hint={`${matches.length} nearby`}>{q ? 'Results' : 'Available this Saturday'}</SectionLabel>
        </div>

        <div>
          {matches.map(p => {
            const on = picked.has(p.id);
            return (
              <button key={p.id} onClick={() => toggle(p.id)} style={{
                width: '100%', display: 'flex', alignItems: 'center', gap: 12,
                padding: '11px 18px', borderTop: '1px solid ' + hair,
                background: on ? paper2 : paper, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
              }}>
                <div style={{
                  width: 22, height: 22, borderRadius: 6, flexShrink: 0,
                  background: on ? ink : paper, border: on ? 'none' : '1.5px solid var(--soft)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {on && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3"><path d="M20 6L9 17l-5-5"/></svg>}
                </div>
                <div style={{
                  width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                  background: paper2, color: ink2,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
                }}>{p.name.split(' ').map(w => w[0]).join('').slice(0, 2)}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                    <span style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{p.name}</span>
                    <span style={{ ...mono, fontSize: 8, padding: '1px 5px', borderRadius: 3, background: cream, color: ink2 }}>GUEST</span>
                  </div>
                  <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{p.team} · {p.meta}</div>
                </div>
                <div style={{ ...mono, fontSize: 9, color: muted }}>{p.dist}</div>
              </button>
            );
          })}
        </div>

        <div style={{ padding: '16px 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 10, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
            Guests receive a request — they appear on your XI only after accepting. Their stats credit their home team unless they're free agents.
          </div>
        </div>
      </div>
      <MsCta onBack={onBack} onNext={() => enough && onDone(Array.from(picked))} nextDisabled={!enough}
        nextLabel={enough ? `Add ${picked.size} guest${picked.size === 1 ? '' : 's'} → XI` : `Need ${short - picked.size} more`} />
    </>
  );
}

// ── UNCLAIMED — form per missing player ───────────────────
function GateUnclaimed({ short, onBack, onDone }) {
  const blank = () => ({ name: '', role: 'Player', bat: 'Right', bowl: 'Right-arm fast' });
  const [rows, setRows] = React.useState(Array.from({ length: short }, blank));
  const set = (i, patch) => setRows(rs => rs.map((r, idx) => idx === i ? { ...r, ...patch } : r));
  const allValid = rows.every(r => r.name.trim().length >= 2);

  return (
    <>
      <MsHeader step={6} total={7} title="Add unclaimed players." sub={`Type ${short} name${short === 1 ? '' : 's'}. They'll go onto your squad as placeholders — claimable later.`} onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '12px 18px 24px' }}>
        {rows.map((r, i) => (
          <div key={i} style={{
            padding: 14, background: paper, border: '1px solid ' + hair, borderRadius: 12, marginBottom: 10,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <span style={{ ...mono, fontSize: 10, color: muted }}>PLAYER {i + 1} OF {short}</span>
              <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 3, background: cream, color: ink2 }}>UNCLAIMED</span>
            </div>

            <input className="ck-input" placeholder="Full name (e.g. Hamza Tariq)" value={r.name}
              onChange={e => set(i, { name: e.target.value })} style={{ marginBottom: 10 }}/>

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 10 }}>
              {['Player', 'Captain', 'Vice-Captain', 'Wicket-Keeper'].map(role => (
                <button key={role} onClick={() => set(i, { role })} style={{
                  padding: '7px 11px', borderRadius: 999,
                  border: '1px solid ' + (r.role === role ? ink : hair),
                  background: r.role === role ? ink : paper,
                  color: r.role === role ? paper : ink,
                  fontFamily: 'inherit', fontSize: 11.5, fontWeight: 600, cursor: 'pointer',
                }}>{role === 'Wicket-Keeper' ? 'WK' : role}</button>
              ))}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <select value={r.bat} onChange={e => set(i, { bat: e.target.value })} className="ck-input"
                style={{ appearance: 'none', WebkitAppearance: 'none', fontSize: 12, paddingRight: 28, cursor: 'pointer' }}>
                {['Right', 'Left'].map(o => <option key={o}>{o}-hand bat</option>)}
              </select>
              <select value={r.bowl} onChange={e => set(i, { bowl: e.target.value })} className="ck-input"
                style={{ appearance: 'none', WebkitAppearance: 'none', fontSize: 12, paddingRight: 28, cursor: 'pointer' }}>
                {['Right-arm fast', 'Right-arm spin', 'Left-arm fast', 'Left-arm spin', "Doesn't bowl"].map(o => <option key={o}>{o}</option>)}
              </select>
            </div>
          </div>
        ))}

        <div style={{ padding: 12, borderRadius: 10, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
          Stats from this match accumulate against the unclaimed profile. When the player joins matchday, they search their name and claim it — you approve, stats migrate.
        </div>
      </div>
      <MsCta onBack={onBack} onNext={() => allValid && onDone(rows)} nextDisabled={!allValid}
        nextLabel={`Add ${short} to squad → XI`} />
    </>
  );
}

// ── REDUCE — confirm format change ────────────────────────
function GateReduce({ have, need, onBack, onDone }) {
  return (
    <>
      <MsHeader step={6} total={7} title={`Drop to ${have}-a-side?`} sub="Eagles will get a counter-proposal. The match stays Pending until they confirm the smaller format." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 24px' }}>

        {/* Before / after */}
        <div style={{ display: 'flex', alignItems: 'stretch', gap: 10, marginBottom: 18 }}>
          <FormatCard label="ORIGINAL" players={need} accent={muted} muted/>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="2"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
          </div>
          <FormatCard label="NEW" players={have} accent={green}/>
        </div>

        <SectionLabel>What changes</SectionLabel>
        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, overflow: 'hidden', marginBottom: 16 }}>
          {[
            { k: 'Players', orig: `${need} a side`, next: `${have} a side` },
            { k: 'Max bowler overs', orig: 'unchanged', next: 'unchanged' },
            { k: 'Total overs',      orig: 'unchanged', next: 'unchanged' },
            { k: 'Format wrapper',   orig: 'Friendly',  next: 'Friendly' },
          ].map((r, i) => (
            <div key={r.k} style={{
              display: 'flex', alignItems: 'center', padding: '11px 14px',
              borderTop: i ? '1px solid ' + hair : 'none',
            }}>
              <span style={{ fontSize: 12, color: muted, flex: 1 }}>{r.k}</span>
              <span style={{ fontSize: 12, color: muted, textDecoration: r.orig !== r.next ? 'line-through' : 'none' }}>{r.orig}</span>
              {r.orig !== r.next && (
                <>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2" style={{ margin: '0 8px' }}><path d="M5 12h14M13 6l6 6-6 6"/></svg>
                  <span style={{ fontSize: 13, fontWeight: 700, color: ink }}>{r.next}</span>
                </>
              )}
            </div>
          ))}
        </div>

        <SectionLabel>What happens next</SectionLabel>
        <div style={{ padding: 12, background: paper2, border: '1px solid ' + hair, borderRadius: 10, marginBottom: 16 }}>
          {[
            'Eagles\' captain gets a "Drop to ' + have + '-a-side?" counter-proposal',
            'They accept (or counter again)',
            'Match becomes Confirmed at the new format',
            'You go on to pick your XI from your full squad',
          ].map((t, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '4px 0' }}>
              <div style={{
                width: 18, height: 18, borderRadius: 999, background: ink, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 700, flexShrink: 0,
              }}>{i + 1}</div>
              <span style={{ fontSize: 12, color: ink2, lineHeight: 1.45 }}>{t}</span>
            </div>
          ))}
        </div>

        <div style={{ ...mono, fontSize: 9, color: muted, textAlign: 'center', marginTop: 8 }}>
          Auto-cancels at T-12h if Eagles don't reply
        </div>
      </div>
      <MsCta onBack={onBack} onNext={onDone} nextLabel={`Send counter-proposal · ${have}-a-side`} />
    </>
  );
}

function FormatCard({ label, players, accent, muted: isMuted }) {
  return (
    <div style={{
      flex: 1, padding: '14px 12px', borderRadius: 12, textAlign: 'center',
      background: isMuted ? paper2 : paper,
      border: '1.5px solid ' + (isMuted ? hair : accent),
    }}>
      <div style={{ ...mono, fontSize: 9, color: accent }}>{label}</div>
      <div style={{ fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 36, letterSpacing: '-0.04em', color: ink, lineHeight: 1, margin: '6px 0 4px' }}>{players}</div>
      <div style={{ fontSize: 11, color: muted, fontFamily: 'inherit' }}>a side</div>
    </div>
  );
}

// ── FORFEIT — destructive confirm ─────────────────────────
function GateForfeit({ onBack, onDone }) {
  const [confirmed, setConfirmed] = React.useState(false);
  return (
    <>
      <MsHeader step={6} total={7} title="Forfeit this match?" sub="Eagles get a walkover win. There's no come-back." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 24px' }}>
        <div style={{
          padding: 18, borderRadius: 14, background: 'oklch(0.96 0.04 28)', color: ink, marginBottom: 18,
          display: 'flex', alignItems: 'center', gap: 16,
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: 14, background: red, color: paper, flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><circle cx="12" cy="12" r="9"/><path d="M9 9l6 6M15 9l-6 6"/></svg>
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 700, color: red }}>This can't be undone</div>
            <div style={{ fontSize: 12, color: ink2, marginTop: 3, lineHeight: 1.4 }}>You can challenge Eagles again later, but this match goes in the books as a walkover.</div>
          </div>
        </div>

        <SectionLabel>What you'll lose</SectionLabel>
        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, overflow: 'hidden', marginBottom: 16 }}>
          {[
            { k: 'Match result', v: 'Walkover · Eagles win', danger: true },
            { k: 'Eagles head-to-head', v: 'Goes to 3 wins of 4' },
            { k: 'Your no-show rate', v: 'Adjusts upward · visible on team page', danger: true },
            { k: 'Player stats', v: 'No stats accumulate · no XI to lock' },
            { k: 'Tournament eligibility', v: 'Not affected (friendly only)' },
          ].map((r, i) => (
            <div key={r.k} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
              padding: '11px 14px', borderTop: i ? '1px solid ' + hair : 'none',
            }}>
              <span style={{ fontSize: 12, color: muted }}>{r.k}</span>
              <span style={{ fontSize: 12, fontWeight: 600, color: r.danger ? red : ink, textAlign: 'right', maxWidth: '60%' }}>{r.v}</span>
            </div>
          ))}
        </div>

        <button onClick={() => setConfirmed(c => !c)} style={{
          width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: 12,
          background: confirmed ? paper2 : paper, border: '1.5px solid ' + (confirmed ? ink : hair),
          borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6, flexShrink: 0,
            background: confirmed ? ink : paper,
            border: confirmed ? 'none' : '1.5px solid var(--soft)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {confirmed && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3"><path d="M20 6L9 17l-5-5"/></svg>}
          </div>
          <span style={{ fontSize: 12.5, color: ink, lineHeight: 1.45 }}>
            I understand this records a walkover and affects my team's record.
          </span>
        </button>
      </div>
      <div style={{
        borderTop: '1px solid ' + hair, padding: '12px 18px',
        background: paper, display: 'flex', gap: 10, alignItems: 'center',
        paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
      }}>
        <button onClick={onBack} style={{
          padding: '12px 16px', borderRadius: 10,
          border: '1px solid ' + hair, background: paper, color: ink,
          fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
        }}>Back</button>
        <button onClick={confirmed ? onDone : undefined} disabled={!confirmed} style={{
          flex: 1, padding: '12px 16px', borderRadius: 10, border: 'none',
          background: confirmed ? red : paper2,
          color: confirmed ? paper : muted,
          fontWeight: 700, fontSize: 14, cursor: confirmed ? 'pointer' : 'default', fontFamily: 'inherit',
        }}>Confirm forfeit</button>
      </div>
    </>
  );
}

function Step6XI({ onBack, onNext, format, picked, setPicked, keeper, setKeeper }) {
  const need = format.players || 11;
  const squad = window.MS_SQUAD || (window.MS_SQUAD = [
    { id: 's1',  name: 'Bilal Ahmed',   role: 'CPT · RHB · RM',  form: 'Hot' },
    { id: 's2',  name: 'Adeel Sheikh',  role: 'WK · LHB',         form: 'OK'  },
    { id: 's3',  name: 'Faraz Khan',    role: 'AR · RHB · OS',   form: 'Hot' },
    { id: 's4',  name: 'Hamza Tariq',   role: 'BAT · RHB',        form: 'OK'  },
    { id: 's5',  name: 'Usman Riaz',    role: 'AR · RHB · RFM',  form: 'Hot' },
    { id: 's6',  name: 'Imran Akhtar',  role: 'BWL · RHB · RFM', form: 'OK'  },
    { id: 's7',  name: 'Shahid Iqbal',  role: 'BAT · LHB',        form: 'Cold'},
    { id: 's8',  name: 'Junaid Ali',    role: 'WK · RHB',         form: 'OK'  },
    { id: 's9',  name: 'Tariq Mehmood', role: 'AR · LHB · SLA',  form: 'OK'  },
    { id: 's10', name: 'Saad Anwar',    role: 'BWL · RHB · LFM', form: 'Hot' },
    { id: 's11', name: 'Bilal Khan',    role: 'BAT · RHB',        form: 'OK'  },
    { id: 's12', name: 'Adnan Latif',   role: 'BWL · RHB · OS',  form: 'OK'  },
    { id: 's13', name: 'Kashif Raza',   role: 'AR · RHB · RM',   form: 'Cold'},
    { id: 's14', name: 'Zain Mansoor',  role: 'BAT · LHB',        form: 'Hot' },
  ]);

  const toggle = (id) => {
    setPicked(prev => {
      const next = new Set(prev);
      if (next.has(id)) { if (id === keeper) return prev; next.delete(id); }
      else if (next.size < need) next.add(id);
      return next;
    });
  };

  const playing  = squad.filter(p => picked.has(p.id));
  const reserves = squad.filter(p => !picked.has(p.id));
  const ready = picked.size === need && picked.has(keeper);
  const FORM_BG = { Hot: 'var(--green-soft)', OK: paper2, Cold: 'var(--cream)' };
  const FORM_FG = { Hot: 'oklch(0.36 0.10 148)', OK: ink2, Cold: muted };

  return (
    <>
      <MsHeader step={6} total={7} title="Pick your XI" sub={`${need} from a squad of ${squad.length}. Penciled-in players get a heads-up notification — they can flag conflicts before match day.`} onBack={onBack}/>

      <div style={{
        padding: '10px 18px', borderBottom: '1px solid ' + hair, background: paper,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{ ...mono, fontSize: 10, color: picked.size === need ? green : ink2 }}>
          XI · {picked.size}/{need}
        </div>
        <div style={{ flex: 1, height: 4, background: paper2, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ width: `${(picked.size / need) * 100}%`, height: '100%', background: picked.size === need ? green : ink, transition: 'width 0.15s' }}/>
        </div>
        <div style={{ ...mono, fontSize: 10, color: muted }}>
          {squad.length - picked.size} RES
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto' }}>

        <div style={{ padding: '12px 18px 6px', display: 'flex', gap: 6 }}>
          <button onClick={() => setPicked(new Set(squad.slice(0, need).map(p => p.id)))} style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>AUTO · BEST FORM</button>
          <button onClick={() => setPicked(new Set())} style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>CLEAR</button>
        </div>

        <div style={{ padding: '8px 18px 4px', ...mono, fontSize: 10, color: ink }}>PLAYING XI · {picked.size}/{need}</div>
        {playing.map((p, i) => (
          <XIRow key={p.id} p={p} picked onToggle={() => toggle(p.id)} isKeeper={keeper === p.id} onMakeKeeper={() => setKeeper(p.id)} formBg={FORM_BG[p.form]} formFg={FORM_FG[p.form]} hasBorder={i > 0} />
        ))}

        {reserves.length > 0 && (
          <>
            <div style={{ padding: '14px 18px 6px', borderTop: '1px solid ' + hair, marginTop: 6, ...mono, fontSize: 10, color: muted }}>
              RESERVES · {reserves.length}
            </div>
            {reserves.map((p, i) => (
              <XIRow key={p.id} p={p} onToggle={() => toggle(p.id)} disabled={picked.size >= need} formBg={FORM_BG[p.form]} formFg={FORM_FG[p.form]} hasBorder={i > 0} />
            ))}
          </>
        )}

        <div style={{ padding: '16px 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 10, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
            You can swap players until the toss. Eagles will see <b style={{ color: ink }}>{picked.size}</b> penciled-in name{picked.size === 1 ? '' : 's'} when they review your request.
          </div>
        </div>
      </div>
      <MsCta onBack={onBack} onNext={onNext} nextDisabled={!ready} nextLabel="Review" />
    </>
  );
}

function XIRow({ p, picked, isKeeper, onToggle, onMakeKeeper, disabled, formBg, formFg, hasBorder }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '10px 18px',
      borderTop: hasBorder ? '1px solid ' + hair : 'none',
      background: picked ? paper : 'transparent', opacity: disabled ? 0.5 : 1,
    }}>
      <button onClick={!disabled ? onToggle : undefined} style={{
        width: 22, height: 22, borderRadius: 6, flexShrink: 0,
        border: picked ? 'none' : '1.5px solid var(--soft)',
        background: picked ? ink : paper,
        cursor: disabled ? 'default' : 'pointer', padding: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {picked && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
      </button>
      <div style={{
        width: 32, height: 32, borderRadius: 9, flexShrink: 0,
        background: paper2, color: ink2,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
      }}>{p.name.split(' ').map(w => w[0]).join('').slice(0, 2)}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{p.name}</span>
          {isKeeper && <span style={{ fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, letterSpacing: '0.10em', padding: '1px 5px', borderRadius: 3, background: red, color: paper }}>WK</span>}
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, letterSpacing: '0.10em', padding: '2px 5px', borderRadius: 4, background: formBg, color: formFg }}>{p.form.toUpperCase()}</span>
        </div>
        <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{p.role}</div>
      </div>
      {picked && !isKeeper && (
        <button onClick={onMakeKeeper} style={{
          fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em',
          fontSize: 8, padding: '4px 7px', borderRadius: 5,
          border: '1px solid ' + hair, background: paper, color: muted, cursor: 'pointer',
        }}>WK</button>
      )}
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// STEP 7 — Review & send (renumbered from 6)
// ───────────────────────────────────────────────────────────
function Step6Review({ onBack, onNext, draft }) {
  const Row = ({ k, v }) => (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', padding: '10px 0', borderBottom: '1px solid ' + hair }}>
      <span style={{ fontSize: 12, color: muted }}>{k}</span>
      <span style={{ fontSize: 13, fontWeight: 600, color: ink, textAlign: 'right', maxWidth: '60%' }}>{v}</span>
    </div>
  );
  return (
    <>
      <MsHeader step={7} total={7} title="Review & send" sub="A request goes to the opponent captain. Match is Pending until they accept." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 18px' }}>

        {/* Hero card */}
        <div style={{
          padding: '18px 16px', background: ink, color: paper,
          borderRadius: 14, marginBottom: 18,
        }}>
          <div style={{ ...mono, fontSize: 9, opacity: 0.7, marginBottom: 8 }}>Friendly · {draft.format.overs} overs · {draft.format.players}-a-side</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{
                width: 44, height: 44, borderRadius: 10, background: red, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, margin: '0 auto 6px',
              }}>LL</div>
              <div style={{ fontWeight: 700, fontSize: 13 }}>Lahore Lions</div>
            </div>
            <div style={{ ...mono, fontSize: 12, opacity: 0.7 }}>VS</div>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{
                width: 44, height: 44, borderRadius: 10,
                background: 'rgba(255,255,255,0.12)', color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, margin: '0 auto 6px',
              }}>{draft.opp.split(' ').map(s=>s[0]).join('').slice(0,2)}</div>
              <div style={{ fontWeight: 700, fontSize: 13 }}>{draft.opp}</div>
            </div>
          </div>
          <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid rgba(255,255,255,0.12)', textAlign: 'center' }}>
            <div style={{ fontSize: 13, opacity: 0.85 }}>{draft.when.date} · {draft.when.time} · {draft.venue}</div>
          </div>
        </div>

        <SectionLabel>Details</SectionLabel>
        <Row k="Format" v={`${draft.format.overs} overs · ${draft.format.ball === 'red' ? 'Red ball' : draft.format.ball === 'tape' ? 'Tape ball' : 'White ball'}`} />
        <Row k="Players per side" v={`${draft.format.players} a side`} />
        <Row k="Powerplay" v={draft.format.pp ? `${draft.format.pp} overs` : 'None'} />
        <Row k="Super over" v={draft.format.super ? 'Yes' : 'No'} />
        <Row k="Free hit" v={draft.format.free ? 'Front-foot no-ball' : 'Off'} />
        <Row k="Scorer" v={
          draft.scorer === 'me' ? 'You' :
          draft.scorer === 'them' ? 'Opponent captain' :
          draft.scorer === 'co' ? 'Both captains' : 'Neutral'
        } />
        <Row k="Your XI" v={`${draft.xiCount} pencilled in`} />

        <div style={{ height: 18 }}/>

        {/* What happens next */}
        <div style={{ padding: 14, background: paper2, border: '1px solid ' + hair, borderRadius: 12 }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 8 }}>What happens next</div>
          {[
            { n: 1, t: `${draft.opp.split(' ')[0]}'s captain gets a request` },
            { n: 2, t: 'They accept (or propose changes)' },
            { n: 3, t: 'Match is Confirmed — appears on both calendars' },
            { n: 4, t: 'On match day: toss → playing XI → live' },
          ].map(s => (
            <div key={s.n} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
              <div style={{
                width: 18, height: 18, borderRadius: 999, background: ink, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 700, flexShrink: 0,
              }}>{s.n}</div>
              <span style={{ fontSize: 12, color: ink2 }}>{s.t}</span>
            </div>
          ))}
        </div>

        <div style={{ ...mono, fontSize: 9, color: muted, textAlign: 'center', marginTop: 14 }}>
          Auto-cancels at T-24h if {draft.opp.split(' ')[0]}'s captain hasn't responded
        </div>

      </div>
      <MsCta onBack={onBack} onNext={onNext} nextLabel="Send request →" />
    </>
  );
}

// ─────────────────────────────────────────────────────────
// RESULT — confirmation
// ─────────────────────────────────────────────────────────
function StepResult({ onClose, draft }) {
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '60px 24px 40px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start' }}>
        <div style={{
          width: 88, height: 88, borderRadius: 22, background: green, color: paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 24,
        }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
        </div>
        <div style={{ ...display(26), marginBottom: 8 }}>Request sent</div>
        <div style={{ fontSize: 13, color: ink2, lineHeight: 1.5, maxWidth: 280, marginBottom: 28 }}>
          We notified {draft.opp.split(' ')[0]}'s captain. The match shows as <b style={{ color: ink }}>Pending</b> on your calendar until they accept.
        </div>

        <div style={{
          width: '100%', padding: 14, background: paper2, border: '1px solid ' + hair, borderRadius: 12, textAlign: 'left',
        }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 8 }}>While you wait</div>
          {[
            'Share the heads-up with your XI — they\'ll see they\'re penciled in',
            'Add match-day notes (parking, kit, snacks) for your team',
            'Invite a scorer if you picked "neutral"',
          ].map((t, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '6px 0' }}>
              <span style={{ color: muted, fontSize: 13 }}>·</span>
              <span style={{ fontSize: 12, color: ink2, lineHeight: 1.5 }}>{t}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{
        borderTop: '1px solid ' + hair, padding: '12px 18px',
        background: paper, display: 'flex', gap: 10,
        paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
      }}>
        <button onClick={onClose} style={{
          flex: 1, padding: '12px 16px', borderRadius: 10,
          border: '1px solid ' + hair, background: paper, color: ink,
          fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
        }}>Done</button>
        <button style={{
          flex: 1, padding: '12px 16px', borderRadius: 10,
          border: 'none', background: ink, color: paper,
          fontWeight: 700, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          Share with XI
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
        </button>
      </div>
    </>
  );
}

// ─────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────
function CkMatchSetup({ initialStep = 1, initialPlayers, initialGateView }) {
  const [step, setStep] = React.useState(initialStep);
  const [type, setType] = React.useState('friendly');
  const [opp, setOpp] = React.useState('Karachi Eagles');
  const [query, setQuery] = React.useState('');
  const [format, setFormat] = React.useState({ overs: 20, ball: 'white', players: initialPlayers || 11, pp: 6, dls: false, super: true, free: true });
  const [venue, setVenue] = React.useState('Model Town Ground');
  const [when, setWhen] = React.useState({ date: 'Mar 18', time: '15:00' });
  const [scorer, setScorer] = React.useState('me');
  const [picked, setPicked] = React.useState(new Set(['s1','s2','s3','s4','s5','s6','s7','s8','s9','s10','s11']));
  const [keeper, setKeeper] = React.useState('s2');
  const [gatePassed, setGatePassed] = React.useState(false);

  const SQUAD_SIZE = 14;
  const isShort = (format.players || 11) > SQUAD_SIZE;

  const draft = { type, opp, format, venue, when, scorer, xiCount: picked.size };

  const back = () => {
    if (step === 1) return;
    if (step === 'result') return setStep(7);
    if (step === 'gate') return setStep(5);
    if (step === 6 && isShort && gatePassed) return setStep('gate');
    setStep(s => Math.max(1, s - 1));
  };
  const next = () => {
    if (step === 5 && isShort && !gatePassed) return setStep('gate');
    if (step === 'gate') return setStep(6);
    if (step === 7) return setStep('result');
    setStep(s => Math.min(7, s + 1));
  };
  const resolveGate = (choice, payload) => {
    setGatePassed(true);
    // Both remaining options (borrow / unclaimed) grow the squad — continue to XI
    setStep(6);
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      {step === 1 && <Step1Type onBack={back} onNext={next} value={type} setValue={setType} />}
      {step === 2 && <Step2Opponent onBack={back} onNext={next} opp={opp} setOpp={setOpp} query={query} setQuery={setQuery} neededPlayers={format.players} />}
      {step === 3 && <Step3Format onBack={back} onNext={next} format={format} setFormat={setFormat} />}
      {step === 4 && <Step4Venue onBack={back} onNext={next} venue={venue} setVenue={setVenue} when={when} setWhen={setWhen} />}
      {step === 5 && <Step5Scorer onBack={back} onNext={next} scorer={scorer} setScorer={setScorer} />}
      {step === 'gate' && <Step6Gate onBack={back} onResolve={resolveGate} need={format.players || 11} have={SQUAD_SIZE} initialView={initialGateView} />}
      {step === 6 && <Step6XI onBack={back} onNext={next} format={format} picked={picked} setPicked={setPicked} keeper={keeper} setKeeper={setKeeper} />}
      {step === 7 && <Step6Review onBack={back} onNext={next} draft={draft} />}
      {step === 'result' && <StepResult onClose={() => setStep(1)} draft={draft} />}
    </div>
  );
}

window.CkMatchSetup = CkMatchSetup;
})();

// Tournaments.jsx — bottom-nav Tournaments tab.
// Three variants on one screen, switchable via the `variant` prop:
//   'sectioned' (a) — stacked sections: Following · Playing · Organizing · Near you
//   'tabbed'    (b) — featured hero + segmented sub-tabs + format chips
//   'editorial' (c) — editorial bracket-first hero, dense list below
//
// Uses CkTBadge / TEAMS from Tournament.jsx (loaded earlier),
// and CkAppShell from AppShell.jsx.

// ─── Mock tournament data ──────────────────────────────────────
const TOURS = {
  spring: {
    id: 'spring', mono: 'SC', name: "Spring Cup '26",
    org: 'Lahore Cricket Council', city: 'Lahore',
    format: 'T20', shape: 'Knockout', teams: 8, played: 6, total: 7,
    state: 'live', live: 1,
    accent: 'oklch(0.62 0.19 28)',  // pitch red
    bg: 'oklch(0.18 0.02 80)',
    next: 'QF1 · LL vs MT · Gaddafi B',
    score: 'LL 132/4 · 14.3 ov · need 46 from 33',
    stage: 'Quarter-finals',
    qf: [['LL','MT'], ['KS','IT'], ['GG','PR'], ['FX','ML']],
    starts: 'Apr 28', ends: 'May 4',
    you: 'playing', // playing / organizing / following
  },
  monsoon: {
    id: 'monsoon', mono: 'ML', name: "Monsoon League '26",
    org: 'You', city: 'Lahore',
    format: 'T20', shape: 'League', teams: 6, played: 4, total: 15,
    state: 'live', live: 0,
    accent: 'oklch(0.56 0.13 148)',
    bg: 'oklch(0.36 0.10 148)',
    next: 'Sat · GG vs FX · Model Town',
    stage: 'Round 5 of 15',
    starts: 'Apr 6', ends: 'Jun 22',
    you: 'organizing',
  },
  ramzan: {
    id: 'ramzan', mono: 'RT', name: "Ramzan Tape-ball Trophy",
    org: 'Mohalla Sports Club', city: 'Lahore',
    format: 'T10', shape: 'League', teams: 12, played: 22, total: 33,
    state: 'live', live: 2,
    accent: 'oklch(0.78 0.14 80)',
    bg: 'oklch(0.45 0.13 50)',
    next: 'Tonight 9pm · Bahria Phase 4',
    stage: 'Round 8 of 11',
    starts: 'Mar 11', ends: 'Apr 9',
    you: 'following',
  },
  bahria: {
    id: 'bahria', mono: 'BP', name: "Bahria Premier '26",
    org: 'Bahria Town SC', city: 'Lahore',
    format: 'T20', shape: 'League + Playoffs', teams: 10, played: 0, total: 47,
    state: 'upcoming', live: 0,
    accent: 'oklch(0.32 0.14 250)',
    bg: 'oklch(0.32 0.14 250)',
    next: 'Opens May 9 · 47 matches',
    stage: 'Registrations open · 8/10 teams',
    starts: 'May 9', ends: 'Jul 14',
    you: null,
  },
  faisal: {
    id: 'faisal', mono: 'FC', name: "Faisalabad Corporate Cup",
    org: 'Lyallpur Sports Forum', city: 'Faisalabad',
    format: 'T15', shape: 'Knockout', teams: 16, played: 0, total: 15,
    state: 'upcoming', live: 0,
    accent: 'oklch(0.40 0.15 20)',
    bg: 'oklch(0.40 0.15 20)',
    next: 'Opens Jun 1',
    stage: 'Captains\u2019 meet May 28',
    starts: 'Jun 1', ends: 'Jun 16',
    you: null,
  },
  pindi: {
    id: 'pindi', mono: 'PN', name: "Pindi Night Sixes",
    org: 'Rawalpindi CA', city: 'Rawalpindi',
    format: 'T10', shape: 'League', teams: 8, played: 14, total: 14,
    state: 'recent', live: 0,
    accent: 'oklch(0.40 0.14 320)',
    bg: 'oklch(0.40 0.14 320)',
    next: 'PR won \u2014 def. KS by 24',
    stage: 'Concluded · Apr 18',
    starts: 'Apr 4', ends: 'Apr 18',
    you: 'following',
  },
};

// ─── Top-level screen ──────────────────────────────────────────
function CkTournaments({ variant = 'sectioned', onTab, onAvatar, onBell }) {
  const variants = { sectioned: TVarSectioned, tabbed: TVarTabbed, editorial: TVarEditorial };
  const Comp = variants[variant] || TVarSectioned;
  return (
    <CkAppShell tab="Tournaments" onTab={onTab} onAvatar={onAvatar} onBell={onBell} hideTopBar>
      <Comp/>
    </CkAppShell>
  );
}

// ════════════════════════════════════════════════════════════════
// VARIANT A — sectioned feed
// ════════════════════════════════════════════════════════════════
function TVarSectioned() {
  return (
    <div>
      <THeader title="Tournaments" subtitle="Live · upcoming · your circles" />

      <TSection label="Playing in" count={1}>
        <TCardLarge t={TOURS.spring} role="player" />
      </TSection>

      <TSection label="Organizing" count={1}>
        <TCardLarge t={TOURS.monsoon} role="organizer" />
      </TSection>

      <TSection label="Following" count={2}>
        <TRowCompact t={TOURS.ramzan} />
        <TRowCompact t={TOURS.pindi} />
      </TSection>

      <TSection label="Near you · Lahore" count={3} action="See all">
        <THorizontal items={[TOURS.bahria, TOURS.faisal, TOURS.spring]} />
      </TSection>

      <TBrowseFooter />
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// VARIANT B — featured hero + segmented sub-tabs + format chips
// ════════════════════════════════════════════════════════════════
function TVarTabbed() {
  const [sub, setSub] = React.useState('Following');
  const [fmt, setFmt] = React.useState('All');
  const SUBS = ['Following', 'Live', 'Near me', 'Browse'];
  const FMTS = ['All', 'T20', 'T10', 'Knockout', 'League'];

  return (
    <div>
      <THeader title="Tournaments" subtitle="What's on your circuit" />
      <THeroFeatured t={TOURS.spring} />

      {/* Sub tabs */}
      <div style={{ padding: '4px 16px 0', borderBottom: '1px solid var(--hairline)', display: 'flex', gap: 18, overflowX: 'auto' }}>
        {SUBS.map(s => (
          <button key={s} onClick={() => setSub(s)} style={{
            background: 'transparent', border: 'none', cursor: 'pointer', padding: '12px 0',
            fontFamily: 'Inter', fontSize: 13, fontWeight: 600,
            color: sub === s ? 'var(--ink)' : 'var(--muted)',
            borderBottom: sub === s ? '2px solid var(--ink)' : '2px solid transparent',
            whiteSpace: 'nowrap',
          }}>
            {s === 'Live' && <span style={{ display: 'inline-block', width: 5, height: 5, borderRadius: 999, background: 'var(--red)', marginRight: 5, transform: 'translateY(-1px)' }}/>}
            {s}
            {s === 'Following' && <span style={{ marginLeft: 5, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>3</span>}
          </button>
        ))}
      </div>

      {/* Format chips */}
      <div style={{ padding: '12px 16px 8px', display: 'flex', gap: 6, overflowX: 'auto' }}>
        {FMTS.map(f => (
          <button key={f} onClick={() => setFmt(f)} style={{
            flex: 'none', padding: '6px 11px', borderRadius: 999,
            border: fmt === f ? '1px solid var(--ink)' : '1px solid var(--hairline)',
            background: fmt === f ? 'var(--ink)' : 'var(--surface)',
            color: fmt === f ? 'var(--paper)' : 'var(--ink-2)',
            fontFamily: 'Inter', fontSize: 11, fontWeight: 600, cursor: 'pointer',
          }}>{f}</button>
        ))}
      </div>

      {/* Body */}
      <div style={{ padding: '4px 16px 16px' }}>
        <TRowDetailed t={TOURS.monsoon} />
        <TRowDetailed t={TOURS.ramzan} />
        <TRowDetailed t={TOURS.pindi} />
        <TRowDetailed t={TOURS.bahria} />
        <TRowDetailed t={TOURS.faisal} />
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// VARIANT C — editorial bracket-first
// ════════════════════════════════════════════════════════════════
function TVarEditorial() {
  return (
    <div style={{ background: 'var(--paper)' }}>
      {/* Editorial header */}
      <div style={{ padding: '10px 20px 16px' }}>
        <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.14em' }}>
          THE CIRCUIT · APR 28
        </div>
        <h1 className="ck-display" style={{
          fontSize: 44, fontWeight: 800, letterSpacing: '-0.045em',
          lineHeight: 0.92, margin: '6px 0 0', color: 'var(--ink)',
        }}>
          Tournaments<span style={{ color: 'var(--red)' }}>.</span>
        </h1>
        <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 8, lineHeight: 1.4, fontWeight: 500 }}>
          3 live across Lahore · 28 teams playing tonight
        </div>
      </div>

      {/* Editorial bracket hero */}
      <TEditorialHero t={TOURS.spring} />

      {/* Quick chips */}
      <div style={{ padding: '14px 20px 8px', display: 'flex', gap: 6, overflowX: 'auto' }}>
        {['All', 'Live now', 'Following', 'Lahore', 'T20', 'Tape-ball'].map((c, i) => (
          <span key={c} style={{
            flex: 'none', padding: '6px 12px', borderRadius: 999,
            background: i === 0 ? 'var(--ink)' : 'var(--paper-2)',
            color: i === 0 ? 'var(--paper)' : 'var(--ink-2)',
            border: i === 0 ? 'none' : '1px solid var(--hairline)',
            fontFamily: 'Inter', fontSize: 11, fontWeight: 600,
          }}>{c}</span>
        ))}
      </div>

      {/* Section: Live across the circuit */}
      <div style={{ padding: '14px 20px 4px', display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--red)' }}/>
        <h3 className="ck-display" style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em', margin: 0 }}>Live now</h3>
        <span className="ck-mono" style={{ marginLeft: 'auto', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em' }}>3</span>
      </div>
      <div style={{ padding: '8px 20px 0' }}>
        <TEditorialRow t={TOURS.spring} index={1} />
        <TEditorialRow t={TOURS.monsoon} index={2} />
        <TEditorialRow t={TOURS.ramzan} index={3} />
      </div>

      {/* Section: On the horizon */}
      <div style={{ padding: '20px 20px 4px' }}>
        <h3 className="ck-display" style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em', margin: 0 }}>On the horizon</h3>
      </div>
      <div style={{ padding: '8px 20px 0' }}>
        <TEditorialRow t={TOURS.bahria} index={4} />
        <TEditorialRow t={TOURS.faisal} index={5} />
      </div>

      <div style={{ padding: '24px 20px 28px' }}>
        <button style={{
          width: '100%', padding: '14px', borderRadius: 12,
          background: 'transparent', border: '1.5px solid var(--ink)',
          color: 'var(--ink)', fontFamily: 'Inter', fontWeight: 700, fontSize: 13, cursor: 'pointer',
        }}>Browse all 47 tournaments →</button>
      </div>
    </div>
  );
}

// ─── Shared building blocks ────────────────────────────────────

function THeader({ title, subtitle }) {
  return (
    <div style={{ padding: '6px 16px 14px', display: 'flex', alignItems: 'flex-end', gap: 10 }}>
      <div style={{ flex: 1 }}>
        <h1 className="ck-display" style={{ fontSize: 30, fontWeight: 700, letterSpacing: '-0.035em', margin: 0, lineHeight: 1 }}>
          {title}
        </h1>
        <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 4 }}>{subtitle}</div>
      </div>
      <button aria-label="Search" style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', color: 'var(--ink)' }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/></svg>
      </button>
    </div>
  );
}

function TSection({ label, count, action, children }) {
  return (
    <div style={{ borderTop: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, padding: '14px 16px 10px' }}>
        <span className="ck-section-h" style={{ fontSize: 10 }}>{label}</span>
        {count != null && <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)' }}>{count}</span>}
        {action && <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em', cursor: 'pointer' }}>{action.toUpperCase()} ›</span>}
      </div>
      {children}
    </div>
  );
}

// Large card — used for "Playing in" and "Organizing"
function TCardLarge({ t, role }) {
  const isPlayer = role === 'player';
  return (
    <div style={{ padding: '0 16px 16px' }}>
      <div style={{
        background: t.bg, color: 'white',
        borderRadius: 16, padding: 16, position: 'relative', overflow: 'hidden',
      }}>
        {/* tiny pitch */}
        <svg width="200" height="200" viewBox="0 0 200 200" style={{ position: 'absolute', right: -50, top: -50, opacity: 0.10 }}>
          <ellipse cx="100" cy="100" rx="95" ry="60" stroke="white" strokeWidth="0.6" fill="none"/>
          <ellipse cx="100" cy="100" rx="55" ry="34" stroke="white" strokeWidth="0.6" fill="none"/>
          <rect x="92" y="70" width="16" height="60" stroke="white" strokeWidth="0.6" fill="none"/>
        </svg>

        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
          {role === 'organizer' && (
            <span style={{ padding: '3px 7px', borderRadius: 4, background: 'rgba(255,255,255,0.18)', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.10em' }}>YOU ORGANIZE</span>
          )}
          {isPlayer && (
            <span style={{ padding: '3px 7px', borderRadius: 4, background: 'rgba(255,255,255,0.18)', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.10em' }}>YOU PLAY · LAHORE LIONS</span>
          )}
          {t.live > 0 && (
            <span style={{ padding: '3px 7px', borderRadius: 4, background: 'var(--red)', color: 'white', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.10em', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 5, height: 5, borderRadius: 999, background: 'white', animation: 'ck-pulse 1.4s infinite' }}/> LIVE
            </span>
          )}
          <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 10, opacity: 0.7, letterSpacing: '0.06em' }}>{t.format} · {t.shape.toUpperCase()}</span>
        </div>

        <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: 26, lineHeight: 1.05 }}>
          {t.name}
        </div>
        <div style={{ fontSize: 12, opacity: 0.78, marginTop: 4 }}>
          {t.stage} · {t.played}/{t.total} matches
        </div>

        {/* progress */}
        <div style={{ marginTop: 14, height: 4, borderRadius: 999, background: 'rgba(255,255,255,0.15)', overflow: 'hidden' }}>
          <div style={{ width: `${(t.played / t.total) * 100}%`, height: '100%', background: 'rgba(255,255,255,0.8)' }}/>
        </div>

        {/* next match panel */}
        <div style={{
          marginTop: 14, padding: '10px 12px', borderRadius: 10,
          background: 'rgba(0,0,0,0.18)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="ck-mono" style={{ fontSize: 9, opacity: 0.7, letterSpacing: '0.08em' }}>
              {t.live > 0 ? 'LIVE NOW' : 'NEXT UP'}
            </div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, marginTop: 2, lineHeight: 1.2 }}>
              {t.live > 0 ? t.score : t.next}
            </div>
          </div>
          <button style={{
            padding: '8px 12px', borderRadius: 8,
            background: 'white', color: t.bg, border: 'none',
            fontFamily: 'Inter', fontSize: 11, fontWeight: 700, cursor: 'pointer', whiteSpace: 'nowrap',
          }}>{role === 'organizer' ? 'MANAGE' : t.live > 0 ? 'WATCH' : 'OPEN'}</button>
        </div>
      </div>
    </div>
  );
}

// Compact row — used for "Following"
function TRowCompact({ t }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)', cursor: 'pointer' }}>
      <div style={{
        width: 40, height: 40, borderRadius: 10, background: t.bg, color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 800, letterSpacing: '-0.02em', flexShrink: 0,
      }}>{t.mono}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.01em' }}>{t.name}</span>
          {t.live > 0 && <span style={{ width: 5, height: 5, borderRadius: 999, background: 'var(--red)', flexShrink: 0 }}/>}
        </div>
        <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.04em', marginTop: 2 }}>
          {t.format} · {t.shape.toUpperCase()} · {t.stage.toUpperCase()}
        </div>
      </div>
      <span style={{ fontFamily: 'JetBrains Mono', fontSize: 14, color: 'var(--muted)' }}>›</span>
    </div>
  );
}

// Horizontal scroll card (Near you)
function THorizontal({ items }) {
  return (
    <div style={{ display: 'flex', gap: 10, padding: '0 16px 18px', overflowX: 'auto' }}>
      {items.map(t => (
        <div key={t.id} style={{
          flex: 'none', width: 220, padding: 14,
          border: '1px solid var(--hairline)', borderRadius: 14, background: 'var(--surface)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8, background: t.bg, color: 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 800,
            }}>{t.mono}</div>
            {t.live > 0 ? (
              <span className="ck-chip live" style={{ padding: '3px 7px', fontSize: 9 }}>LIVE</span>
            ) : (
              <span className="ck-mono" style={{ fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>{t.starts.toUpperCase()}</span>
            )}
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.01em', lineHeight: 1.15, minHeight: 32 }}>
            {t.name}
          </div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>
            {t.city} · {t.teams} teams · {t.format}
          </div>
          <button style={{
            marginTop: 12, width: '100%', padding: '7px 0', borderRadius: 8,
            background: 'var(--ink)', color: 'var(--paper)', border: 'none',
            fontFamily: 'Inter', fontSize: 11, fontWeight: 600, cursor: 'pointer',
          }}>Follow</button>
        </div>
      ))}
    </div>
  );
}

function TBrowseFooter() {
  return (
    <div style={{ borderTop: '1px solid var(--hairline)', padding: '20px 16px 28px', display: 'flex', gap: 10 }}>
      <button style={{
        flex: 1, padding: '12px', borderRadius: 12,
        background: 'var(--paper-2)', border: '1px solid var(--hairline)',
        fontFamily: 'Inter', fontSize: 13, fontWeight: 600, cursor: 'pointer', color: 'var(--ink)',
      }}>Browse all</button>
      <button style={{
        flex: 1, padding: '12px', borderRadius: 12,
        background: 'var(--ink)', color: 'var(--paper)', border: 'none',
        fontFamily: 'Inter', fontSize: 13, fontWeight: 700, cursor: 'pointer',
      }}>+ Create tournament</button>
    </div>
  );
}

// ─── Variant B specifics ───────────────────────────────────────

function THeroFeatured({ t }) {
  return (
    <div style={{ padding: '4px 16px 14px' }}>
      <div style={{
        background: t.bg, color: 'white', borderRadius: 16, padding: 18,
        position: 'relative', overflow: 'hidden',
      }}>
        <svg width="240" height="240" viewBox="0 0 200 200" style={{ position: 'absolute', right: -60, bottom: -80, opacity: 0.10 }}>
          <ellipse cx="100" cy="100" rx="95" ry="60" stroke="white" strokeWidth="0.6" fill="none"/>
          <ellipse cx="100" cy="100" rx="55" ry="34" stroke="white" strokeWidth="0.6" fill="none"/>
        </svg>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 12 }}>
          <span style={{ padding: '3px 7px', borderRadius: 4, background: 'rgba(255,255,255,0.18)', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.10em' }}>FEATURED</span>
          <span style={{ padding: '3px 7px', borderRadius: 4, background: 'var(--red)', color: 'white', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.10em', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 5, height: 5, borderRadius: 999, background: 'white', animation: 'ck-pulse 1.4s infinite' }}/> QF1 LIVE
          </span>
          <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 10, opacity: 0.75, letterSpacing: '0.06em' }}>{t.format} · {t.shape.toUpperCase()}</span>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontWeight: 800, letterSpacing: '-0.035em', fontSize: 32, lineHeight: 0.95 }}>
          {t.name}
        </div>
        <div style={{ fontSize: 12, opacity: 0.78, marginTop: 6 }}>
          {t.org} · {t.city} · {t.teams} teams
        </div>

        {/* Mini bracket strip */}
        <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
          {t.qf.map(([a, b], i) => (
            <div key={i} style={{
              padding: '6px 8px', borderRadius: 8,
              background: i === 0 ? 'var(--red)' : 'rgba(255,255,255,0.10)',
              border: i === 0 ? 'none' : '1px solid rgba(255,255,255,0.15)',
            }}>
              <div className="ck-mono" style={{ fontSize: 8, opacity: 0.7, letterSpacing: '0.06em' }}>QF{i + 1}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700, marginTop: 2, letterSpacing: '-0.01em' }}>
                {a} <span style={{ opacity: 0.5 }}>v</span> {b}
              </div>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ flex: 1 }}>
            <div className="ck-mono" style={{ fontSize: 9, opacity: 0.7, letterSpacing: '0.08em' }}>QF1 · GADDAFI B</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, marginTop: 2 }}>
              LL 132/4 · need 46 from 33
            </div>
          </div>
          <button style={{
            padding: '9px 14px', borderRadius: 10,
            background: 'white', color: t.bg, border: 'none',
            fontFamily: 'Inter', fontSize: 12, fontWeight: 700, cursor: 'pointer',
          }}>WATCH ›</button>
        </div>
      </div>
    </div>
  );
}

function TRowDetailed({ t }) {
  const status = t.live > 0 ? 'live' : t.state;
  return (
    <div style={{
      display: 'flex', alignItems: 'stretch', gap: 12,
      padding: '14px 0', borderTop: '1px solid var(--hairline)', cursor: 'pointer',
    }}>
      {/* Left rail */}
      <div style={{
        width: 52, height: 52, borderRadius: 12, background: t.bg, color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 800, letterSpacing: '-0.02em', flexShrink: 0,
      }}>{t.mono}</div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700, letterSpacing: '-0.015em' }}>{t.name}</span>
          {status === 'live' && (
            <span style={{ padding: '2px 5px', borderRadius: 3, background: 'var(--red)', color: 'white', fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, letterSpacing: '0.08em' }}>LIVE</span>
          )}
          {t.you === 'organizing' && (
            <span style={{ padding: '2px 5px', borderRadius: 3, background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, letterSpacing: '0.08em' }}>YOURS</span>
          )}
        </div>
        <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.04em', marginTop: 3 }}>
          {t.format} · {t.shape.toUpperCase()} · {t.teams} TEAMS · {t.city.toUpperCase()}
        </div>
        <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.35 }}>
          {t.next}
        </div>
      </div>

      {/* Right meta */}
      <div style={{ textAlign: 'right', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <div className="ck-mono ck-tnum" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.04em' }}>
          {t.played}/{t.total}
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 600, color: 'var(--muted)' }}>
          {t.starts}–{t.ends.split(' ')[1] ? t.ends : t.ends}
        </div>
      </div>
    </div>
  );
}

// ─── Variant C specifics ───────────────────────────────────────

function TEditorialHero({ t }) {
  return (
    <div style={{
      margin: '0 20px 4px', padding: 22, borderRadius: 18,
      background: 'var(--ink)', color: 'var(--paper)',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span className="ck-chip live" style={{ padding: '3px 7px', fontSize: 9, background: 'var(--red)', color: 'white' }}>QF1 LIVE</span>
        <span className="ck-mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.10em' }}>FEATURED · SPRING CUP '26</span>
      </div>

      <div className="ck-display" style={{
        fontSize: 32, fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.0,
      }}>
        Lahore Lions chase<br/>
        <span style={{ color: 'var(--red)' }}>178</span> in QF1.
      </div>

      <div style={{ marginTop: 10, fontSize: 12, opacity: 0.7, lineHeight: 1.4 }}>
        Need 46 from 33 with Bilal Ahmed at 67(42). Three more QFs tonight.
      </div>

      {/* Bracket spine */}
      <div style={{
        marginTop: 18, padding: '12px 14px', borderRadius: 12,
        background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)',
      }}>
        <div className="ck-mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.10em', marginBottom: 8 }}>QUARTER-FINALS</div>
        <div style={{ display: 'grid', gap: 6 }}>
          {t.qf.map(([a, b], i) => {
            const live = i === 0;
            return (
              <div key={i} style={{
                display: 'grid', gridTemplateColumns: 'auto 1fr auto 1fr auto',
                alignItems: 'center', gap: 8, padding: '6px 0',
                borderTop: i ? '1px solid rgba(255,255,255,0.06)' : 'none',
              }}>
                <span className="ck-mono" style={{ fontSize: 9, opacity: 0.55, width: 18 }}>QF{i + 1}</span>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, letterSpacing: '-0.01em', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <CkTBadge id={a} size={18} />
                  <span style={{ opacity: live ? 1 : 0.85 }}>{TEAMS[a]?.name}</span>
                </div>
                <span style={{ opacity: 0.4, fontFamily: 'JetBrains Mono', fontSize: 10 }}>v</span>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, letterSpacing: '-0.01em', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <CkTBadge id={b} size={18} />
                  <span style={{ opacity: live ? 1 : 0.85 }}>{TEAMS[b]?.name}</span>
                </div>
                <span className="ck-mono" style={{ fontSize: 10, color: live ? 'oklch(0.85 0.13 30)' : 'rgba(255,255,255,0.4)', letterSpacing: '0.04em', textAlign: 'right' }}>
                  {live ? 'LIVE' : i === 1 ? '7:30' : i === 2 ? 'TUE' : 'WED'}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function TEditorialRow({ t, index }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '20px 1fr auto', gap: 12,
      padding: '14px 0', borderTop: '1px solid var(--hairline)', alignItems: 'center', cursor: 'pointer',
    }}>
      <span className="ck-mono" style={{ fontSize: 11, color: 'var(--muted)', letterSpacing: '0.04em' }}>
        {String(index).padStart(2, '0')}
      </span>
      <div style={{ minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span className="ck-display" style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em' }}>{t.name}</span>
          {t.live > 0 && <span style={{ width: 5, height: 5, borderRadius: 999, background: 'var(--red)' }}/>}
        </div>
        <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em', marginTop: 3 }}>
          {t.format} · {t.shape.toUpperCase()} · {t.city.toUpperCase()} · {t.teams} TEAMS
        </div>
        <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 5, lineHeight: 1.35 }}>
          {t.next}
        </div>
      </div>
      <div style={{
        width: 36, height: 36, borderRadius: 10, background: t.bg, color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 800, letterSpacing: '-0.02em',
      }}>{t.mono}</div>
    </div>
  );
}

window.CkTournaments = CkTournaments;

// Matches.jsx — Circk dedicated Matches tab.
// Three sub-tabs: Live · Upcoming · Recent (per spec §7.10, §7.11).
// Lives as the second tab in the bottom nav, replacing live content in the home feed.

const MATCH_SUBTABS = [
  { id: 'live', label: 'Live' },
  { id: 'upcoming', label: 'Upcoming' },
  { id: 'recent', label: 'Recent' },
];

// ── Mock data ──────────────────────────────────────────────────────────────
const LIVE_MATCHES = [
  {
    id: 'l1', mine: true, tag: "Spring Cup '26 · QF",
    venue: 'Model Town · Lahore',
    home: { name: 'Lahore Lions', short: 'LAH', color: 'oklch(0.62 0.19 28)', runs: 132, wickets: 4, ov: '14.3', batting: true },
    away: { name: 'City Eagles',  short: 'CTY', color: 'oklch(0.42 0.10 260)', runs: 178, wickets: 10, ov: '20.0', batting: false },
    target: 179,
    striker: { name: 'A. Khan', runs: 52, balls: 41 },
    bowler:  { name: 'R. Patel', figures: '2/24' },
    over: ['1','·','4','0','W','1'],
  },
  {
    id: 'l2', mine: false, tag: "Friday Night League",
    venue: 'Gulberg Sports · Lahore',
    home: { name: 'DHA United', short: 'DHA', color: 'oklch(0.42 0.10 260)', runs: 88, wickets: 2, ov: '12.0', batting: true },
    away: { name: 'Mohalla Kings', short: 'MOH', color: 'oklch(0.78 0.14 80)', runs: null, wickets: null, ov: '—', batting: false },
    target: null,
    striker: { name: 'B. Sami', runs: 41, balls: 28 },
    bowler:  { name: 'H. Aziz', figures: '1/22' },
    over: ['2','1','·','1','4','·'],
  },
  {
    id: 'l3', mine: false, tag: "Tape Ball Cup",
    venue: 'Iqbal Park · Lahore',
    home: { name: 'Old Boys', short: 'OB', color: 'oklch(0.36 0.04 80)', runs: 64, wickets: 6, ov: '9.4', batting: false },
    away: { name: 'Galle B.', short: 'GAL', color: 'oklch(0.55 0.12 200)', runs: 45, wickets: 3, ov: '7.2', batting: true },
    target: 65,
    striker: { name: 'F. Hassan', runs: 18, balls: 16 },
    bowler:  { name: 'S. Iqbal', figures: '3/19' },
    over: ['·','·','1','W','·','2'],
  },
];

const UPCOMING_MATCHES = [
  {
    id: 'u1', mine: true, tag: "Spring Cup '26 · SF",
    when: 'Sun 16 Mar', time: '6:00 PM', dayLabel: 'In 2 days',
    venue: 'Model Town · Lahore',
    home: { name: 'Lahore Lions', short: 'LAH', color: 'oklch(0.62 0.19 28)' },
    away: { name: 'TBD',           short: '?',   color: 'oklch(0.85 0.005 80)' },
    note: 'Awaiting QF result',
    rsvpd: false,
  },
  {
    id: 'u2', mine: false, tag: "Friday Night League · R5",
    when: 'Sat 15 Mar', time: '5:00 PM', dayLabel: 'Tomorrow',
    venue: 'Gulberg Sports · Lahore',
    home: { name: 'Kings XI',  short: 'KXI', color: 'oklch(0.78 0.14 80)' },
    away: { name: 'Old Boys',  short: 'OB',  color: 'oklch(0.36 0.04 80)' },
    rsvpd: true, going: 12,
  },
  {
    id: 'u3', mine: false, tag: "Inter-School T10",
    when: 'Sat 15 Mar', time: '7:00 PM', dayLabel: 'Tomorrow',
    venue: 'Aitchison Ground',
    home: { name: 'Aitchison',  short: 'AIT', color: 'oklch(0.42 0.10 260)' },
    away: { name: 'New School', short: 'NS',  color: 'oklch(0.56 0.13 148)' },
  },
  {
    id: 'u4', mine: false, tag: "Spring Cup '26 · SF",
    when: 'Sun 16 Mar', time: '4:00 PM', dayLabel: 'In 2 days',
    venue: 'Model Town · Lahore',
    home: { name: 'DHA United', short: 'DHA', color: 'oklch(0.42 0.10 260)' },
    away: { name: 'Royal M.',   short: 'RM',  color: 'oklch(0.55 0.12 200)' },
  },
];

const RECENT_MATCHES = [
  {
    id: 'r1', mine: true, tag: "Spring Cup '26 · QF · today",
    venue: 'Model Town · Lahore',
    home: { name: 'Lahore Lions', short: 'LAH', color: 'oklch(0.62 0.19 28)', runs: 181, wickets: 6, ov: '20.0' },
    away: { name: 'City Eagles',  short: 'CTY', color: 'oklch(0.42 0.10 260)', runs: 178, wickets: 10, ov: '20.0' },
    result: 'Lions won by 3 runs', winner: 'home',
    mom: { name: 'A. Khan', figures: '78 (52)' },
  },
  {
    id: 'r2', mine: false, tag: "Friday Night League · R4",
    venue: 'Gulberg · Lahore',
    home: { name: 'Kings XI', short: 'KXI', color: 'oklch(0.78 0.14 80)', runs: 142, wickets: 8, ov: '20.0' },
    away: { name: 'DHA United', short: 'DHA', color: 'oklch(0.42 0.10 260)', runs: 144, wickets: 4, ov: '18.2' },
    result: 'DHA won by 6 wickets', winner: 'away',
    mom: { name: 'B. Sami', figures: '64* (38)' },
  },
  {
    id: 'r3', mine: false, tag: "Tape Ball Cup · Group A",
    venue: 'Iqbal Park · Lahore',
    home: { name: 'Mohalla Kings', short: 'MOH', color: 'oklch(0.78 0.14 80)', runs: 96, wickets: 10, ov: '14.5' },
    away: { name: 'Galle B.',      short: 'GAL', color: 'oklch(0.55 0.12 200)', runs: 97, wickets: 5, ov: '13.1' },
    result: 'Galle B. won by 5 wickets', winner: 'away',
    mom: { name: 'F. Hassan', figures: '3/14' },
  },
  {
    id: 'r4', mine: false, tag: "Inter-Uni T20 · SF",
    venue: 'LUMS Ground',
    home: { name: 'LUMS',  short: 'LMS', color: 'oklch(0.36 0.04 80)', runs: 167, wickets: 7, ov: '20.0' },
    away: { name: 'NUST',  short: 'NST', color: 'oklch(0.55 0.12 200)', runs: 167, wickets: 8, ov: '20.0' },
    result: 'Tied · Super Over: NUST won', winner: 'away', tied: true,
    mom: { name: 'A. Rauf', figures: '88 (54)' },
  },
];

// ── Header ────────────────────────────────────────────────────────────────
function MatchesHeader({ liveCount, totalToday }) {
  return (
    <div style={{ padding: '14px 20px 12px', borderBottom: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>
            CIRCK · MATCHES · FRI 14 MAR
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 28, letterSpacing: '-0.035em', lineHeight: 1.05, marginTop: 2 }}>
            On the field<span style={{ color: 'var(--red)' }}>.</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', paddingTop: 6 }}>
          <button style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'var(--ink)' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
          </button>
          <button style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'var(--ink)' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M7 12h10M11 18h2"/></svg>
          </button>
        </div>
      </div>
      {/* counter strip */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 12, fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: '0.06em' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 7, height: 7, borderRadius: 999, background: 'var(--red)' }} />
          <span style={{ color: 'var(--ink)', fontWeight: 700 }}>{liveCount} LIVE NOW</span>
        </div>
        <div style={{ width: 1, height: 10, background: 'var(--hairline)' }} />
        <span style={{ color: 'var(--muted)' }}>{totalToday} TODAY · 50KM RADIUS</span>
      </div>
    </div>
  );
}

function SubTabs({ active, setActive, counts }) {
  return (
    <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', background: 'var(--paper)' }}>
      {MATCH_SUBTABS.map(t => (
        <button key={t.id} onClick={() => setActive(t.id)} style={{
          flex: 1, padding: '12px 0 10px', background: 'transparent', border: 'none',
          cursor: 'pointer', fontFamily: 'inherit', position: 'relative',
          color: active === t.id ? 'var(--ink)' : 'var(--muted)',
        }}>
          <span style={{ fontSize: 13, fontWeight: 700, letterSpacing: '-0.005em' }}>{t.label}</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, marginLeft: 6, color: active === t.id ? (t.id === 'live' ? 'var(--red)' : 'var(--ink-2)') : 'var(--muted)', fontWeight: 600 }}>
            {counts[t.id]}
          </span>
          {active === t.id && (
            <span style={{ position: 'absolute', bottom: -1, left: '50%', transform: 'translateX(-50%)', width: 28, height: 2, background: 'var(--red)', borderRadius: 2 }} />
          )}
        </button>
      ))}
    </div>
  );
}

// ── Filter chips (location + tournament) ──────────────────────────────────
function MatchFilterBar({ filters, active, setActive }) {
  return (
    <div style={{ display: 'flex', gap: 6, padding: '10px 20px', overflowX: 'auto' }}>
      {filters.map(f => (
        <button key={f.id} onClick={() => setActive(f.id)} style={{
          flex: 'none', padding: '5px 11px', borderRadius: 999,
          background: active === f.id ? 'var(--ink)' : 'transparent',
          color: active === f.id ? 'var(--paper)' : 'var(--ink-2)',
          border: '1px solid ' + (active === f.id ? 'var(--ink)' : 'var(--hairline)'),
          fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer',
          whiteSpace: 'nowrap', display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>
          {f.icon}{f.label}
        </button>
      ))}
    </div>
  );
}

// ── Live match card (mid-density, calmer than home feed hero) ─────────────
function LiveCard({ m, onOpen }) {
  // Choose batting team to lead the card
  const bat = m.home.batting ? m.home : m.away;
  const bowl = m.home.batting ? m.away : m.home;
  const need = m.target != null && bat.runs != null ? Math.max(0, m.target - bat.runs) : null;

  return (
    <button onClick={() => onOpen(m)} style={{
      width: '100%', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer',
      background: 'oklch(0.18 0.02 80)', color: 'white', borderRadius: 14, padding: 0,
      border: 'none', overflow: 'hidden',
      boxShadow: m.mine ? '0 0 0 2px var(--red), 0 4px 14px rgba(190,60,40,0.18)' : '0 4px 14px rgba(0,0,0,0.18)',
    }}>
      {/* top strip */}
      <div style={{ padding: '9px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 7, height: 7, borderRadius: 999, background: 'var(--red)' }} />
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.14em' }}>LIVE</span>
          {m.mine && <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.1em', padding: '2px 5px', border: '1px solid var(--red)', borderRadius: 4 }}>YOU</span>}
        </div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{m.tag}</div>
      </div>

      {/* dual scoreline */}
      <div style={{ padding: '12px 14px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {[m.home, m.away].map((t, i) => (
          <div key={i} style={{ opacity: t.batting ? 1 : 0.55 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 6 }}>
              <div style={{ width: 20, height: 20, borderRadius: 4, background: t.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 9 }}>{t.short}</div>
              <span style={{ fontSize: 11, fontWeight: 600 }}>{t.name}</span>
              {t.batting && <span style={{ fontSize: 8, fontFamily: 'JetBrains Mono', color: 'var(--red)', fontWeight: 700, letterSpacing: '0.08em' }}>BAT</span>}
            </div>
            {t.runs != null ? (
              <>
                <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 26, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.03em', lineHeight: 1 }}>
                  {t.runs}<span style={{ color: 'rgba(255,255,255,0.45)', fontWeight: 600, fontSize: 19 }}>/{t.wickets}</span>
                </div>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'rgba(255,255,255,0.55)', marginTop: 3, letterSpacing: '0.04em' }}>
                  ({t.ov})
                </div>
              </>
            ) : (
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.55)' }}>YET TO BAT</div>
            )}
          </div>
        ))}
      </div>

      {/* equation strip */}
      {need != null && (
        <div style={{ padding: '8px 14px', borderTop: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.04)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontFamily: 'JetBrains Mono', fontSize: 11 }}>
          <span style={{ color: 'rgba(255,255,255,0.85)' }}>
            <span style={{ color: 'rgba(255,255,255,0.55)', letterSpacing: '0.06em' }}>NEED </span>
            <span style={{ fontWeight: 700, fontFamily: 'Inter Tight', fontSize: 14 }}>{need}</span>
          </span>
          <span style={{ color: 'rgba(255,255,255,0.55)', letterSpacing: '0.04em' }}>
            {bat.name.split(' ')[0]} chasing {m.target}
          </span>
        </div>
      )}

      {/* mini context: striker/bowler + last balls */}
      <div style={{ padding: '10px 14px 12px', borderTop: '1px solid rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 11, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {m.striker.name} <span style={{ color: 'rgba(255,255,255,0.55)', fontFamily: 'JetBrains Mono', fontSize: 10 }}>{m.striker.runs}({m.striker.balls})</span>
          </div>
          <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>
            v {m.bowler.name} {m.bowler.figures}
          </div>
        </div>
        <div style={{ display: 'flex', gap: 3 }}>
          {m.over.map((b, i) => (
            <span key={i} style={{
              width: 18, height: 18, borderRadius: 999,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700,
              background: b === '4' ? 'oklch(0.56 0.13 148)' : b === '6' ? 'var(--red)' : b === 'W' ? 'oklch(0.5 0.15 28)' : 'rgba(255,255,255,0.1)',
              color: 'white',
            }}>{b}</span>
          ))}
        </div>
      </div>
    </button>
  );
}

// ── Upcoming match card ───────────────────────────────────────────────────
function UpcomingCard({ m, onOpen, onRsvp }) {
  return (
    <button onClick={() => onOpen(m)} style={{
      width: '100%', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer',
      background: 'var(--paper)', borderRadius: 14, padding: 0,
      border: '1px solid ' + (m.mine ? 'var(--red)' : 'var(--hairline)'),
      overflow: 'hidden',
    }}>
      {/* header strip */}
      <div style={{ padding: '8px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'var(--paper-2)', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--ink-2)', letterSpacing: '0.14em' }}>{m.dayLabel.toUpperCase()}</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)' }}>· {m.time}</span>
          {m.mine && <span style={{ fontFamily: 'JetBrains Mono', fontSize: 8, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.1em', padding: '2px 5px', border: '1px solid var(--red)', borderRadius: 4 }}>YOUR TEAM</span>}
        </div>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{m.tag}</span>
      </div>

      {/* versus block */}
      <div style={{ padding: '14px', display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 10 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
          <div style={{ width: 36, height: 36, borderRadius: 8, background: m.home.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700 }}>{m.home.short}</div>
          <div style={{ fontSize: 11, fontWeight: 600, textAlign: 'center', maxWidth: 100 }}>{m.home.name}</div>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, color: 'var(--muted)', letterSpacing: '-0.02em' }}>vs</div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8,
            background: m.away.short === '?' ? 'transparent' : m.away.color,
            border: m.away.short === '?' ? '1.5px dashed var(--soft)' : 'none',
            color: m.away.short === '?' ? 'var(--muted)' : 'white',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700,
          }}>{m.away.short}</div>
          <div style={{ fontSize: 11, fontWeight: 600, textAlign: 'center', maxWidth: 100, color: m.away.short === '?' ? 'var(--muted)' : 'var(--ink)' }}>{m.away.name}</div>
        </div>
      </div>

      {/* footer */}
      <div style={{ padding: '8px 14px 12px', borderTop: '1px dashed var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 11, color: 'var(--muted)', minWidth: 0 }}>
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ flex: 'none' }}><path d="M20 10c0 7-8 12-8 12s-8-5-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></svg>
          <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.venue}</span>
        </div>
        {m.note ? (
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.04em', fontStyle: 'italic' }}>{m.note}</span>
        ) : (
          <span onClick={e => { e.stopPropagation(); onRsvp(m); }} role="button" style={{
            fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em',
            padding: '4px 9px', borderRadius: 999, cursor: 'pointer',
            background: m.rsvpd ? 'oklch(0.56 0.13 148)' : 'transparent',
            color: m.rsvpd ? 'white' : 'var(--ink)',
            border: '1px solid ' + (m.rsvpd ? 'oklch(0.56 0.13 148)' : 'var(--hairline)'),
          }}>{m.rsvpd ? `✓ GOING · ${m.going}` : 'REMIND ME'}</span>
        )}
      </div>
    </button>
  );
}

// ── Recent match card ─────────────────────────────────────────────────────
function RecentCard({ m, onOpen }) {
  return (
    <button onClick={() => onOpen(m)} style={{
      width: '100%', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer',
      background: 'var(--paper)', borderRadius: 14, padding: 0,
      border: '1px solid ' + (m.mine ? 'var(--red)' : 'var(--hairline)'),
      overflow: 'hidden',
    }}>
      <div style={{ padding: '8px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'var(--paper-2)', borderBottom: '1px solid var(--hairline)' }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.14em' }}>FINAL{m.tied ? ' · TIED' : ''}</span>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{m.tag}</span>
      </div>

      {/* two stacked lines, winner emphasised */}
      <div style={{ padding: '10px 14px' }}>
        {[
          { side: 'home', t: m.home, won: m.winner === 'home' },
          { side: 'away', t: m.away, won: m.winner === 'away' },
        ].map((row, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0',
            opacity: row.won ? 1 : 0.55,
          }}>
            <div style={{ width: 24, height: 24, borderRadius: 5, background: row.t.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 10, flex: 'none' }}>{row.t.short}</div>
            <div style={{ flex: 1, fontSize: 13, fontWeight: row.won ? 700 : 500 }}>{row.t.name}</div>
            <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>
              {row.t.runs}<span style={{ color: 'var(--muted)', fontWeight: 500, fontSize: 13 }}>/{row.t.wickets}</span>
            </div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', minWidth: 32, textAlign: 'right' }}>({row.t.ov})</div>
            {row.won && <div style={{ width: 4, height: 22, borderRadius: 2, background: 'var(--red)' }} />}
          </div>
        ))}
      </div>

      <div style={{ padding: '8px 14px 12px', borderTop: '1px dashed var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ fontSize: 12, fontWeight: 600 }}>{m.result}</div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>
          MOM <span style={{ color: 'var(--ink-2)', fontWeight: 700 }}>{m.mom.name}</span> <span>{m.mom.figures}</span>
        </div>
      </div>
    </button>
  );
}

// ── Section header ────────────────────────────────────────────────────────
function SectionH({ label, side, accent }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0 2px' }}>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: accent || 'var(--ink)', letterSpacing: '0.14em' }}>
        {label}
      </div>
      <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
      {side && <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>{side}</div>}
    </div>
  );
}

// ── Empty state per tab ───────────────────────────────────────────────────
function EmptyTab({ title, body, cta }) {
  return (
    <div style={{ padding: '40px 16px', textAlign: 'center' }}>
      <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em' }}>{title}</div>
      <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 6, lineHeight: 1.4, maxWidth: 260, marginInline: 'auto' }}>{body}</div>
      {cta && (
        <button style={{
          marginTop: 14, padding: '10px 16px', borderRadius: 10,
          border: 'none', background: 'var(--ink)', color: 'var(--paper)',
          fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer',
        }}>{cta}</button>
      )}
    </div>
  );
}

// ── Bottom nav (mirrors Feed) ─────────────────────────────────────────────
function MatchesTabBar({ active, setActive }) {
  const tabs = [
    { id: 'home', label: 'Home' },
    { id: 'matches', label: 'Matches' },
    { id: 'tour', label: 'Tournaments' },
    { id: 'profile', label: 'You' },
  ];
  const icons = {
    home: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/></svg>,
    matches: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9"/><path d="M3.6 9h16.8M3.6 15h16.8M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>,
    tour: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6M18 9h1.5a2.5 2.5 0 0 0 0-5H18M4 22h16M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22M18 2H6v7a6 6 0 0 0 12 0z"/></svg>,
    profile: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>,
  };
  return (
    <div style={{ display: 'flex', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', padding: '8px 8px 22px' }}>
      {tabs.map(t => (
        <button key={t.id} onClick={() => setActive(t.id)} style={{
          flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, padding: '6px 0',
          background: 'transparent', border: 'none',
          color: active === t.id ? 'var(--ink)' : 'var(--muted)', cursor: 'pointer', fontFamily: 'inherit',
        }}>
          {icons[t.id]}
          <div style={{ fontSize: 10, fontWeight: 600 }}>{t.label}</div>
          <div style={{ width: 14, height: 2, borderRadius: 2, background: active === t.id ? 'var(--red)' : 'transparent' }} />
        </button>
      ))}
    </div>
  );
}

// ── Match detail sheet (lightweight peek) ─────────────────────────────────
function MatchDetailSheet({ m, onClose, kind }) {
  if (!m) return null;
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 50, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      <div onClick={e => e.stopPropagation()} style={{ background: 'var(--paper)', borderRadius: '18px 18px 0 0', padding: '14px 20px 22px', maxHeight: '70%', overflow: 'auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.12em', color: 'var(--muted)' }}>
            {kind === 'live' ? 'LIVE · TAP TO OPEN' : kind === 'upcoming' ? 'UPCOMING' : 'COMPLETED'}
          </div>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted)', padding: 0 }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
          </button>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 22, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          {m.home.name} <span style={{ color: 'var(--muted)', fontWeight: 500 }}>vs</span> {m.away.name}
        </div>
        <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 4 }}>{m.tag} · {m.venue}</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 14 }}>
          {[
            { k: kind === 'upcoming' ? 'Open match page' : 'Watch live scorecard', primary: true },
            { k: 'Follow this match' },
            { k: 'Share' },
            { k: 'Add to calendar' },
          ].map((b, i) => (
            <button key={i} onClick={onClose} style={{
              padding: '11px 12px', borderRadius: 10,
              border: b.primary ? 'none' : '1px solid var(--hairline)',
              background: b.primary ? 'var(--ink)' : 'transparent',
              color: b.primary ? 'var(--paper)' : 'var(--ink)',
              fontFamily: 'inherit', fontWeight: 600, fontSize: 12, cursor: 'pointer',
            }}>{b.k}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── Main ──────────────────────────────────────────────────────────────────
function Matches({ initialSub = 'live' }) {
  const [tab, setTab] = React.useState('matches');
  const [sub, setSub] = React.useState(initialSub);
  const [filter, setFilter] = React.useState('all');
  const [open, setOpen] = React.useState(null);
  const [upcoming, setUpcoming] = React.useState(UPCOMING_MATCHES);

  const counts = {
    live: LIVE_MATCHES.length,
    upcoming: upcoming.length,
    recent: RECENT_MATCHES.length,
  };

  const filters = [
    { id: 'all',    label: 'All' },
    { id: 'mine',   label: 'My teams', icon: <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--red)', display: 'inline-block' }} /> },
    { id: 'lahore', label: 'Lahore' },
    { id: 'spring', label: "Spring Cup '26" },
    { id: 'fnl',    label: 'Friday Night League' },
  ];

  const toggleRsvp = (m) => {
    setUpcoming(list => list.map(x => x.id === m.id ? { ...x, rsvpd: !x.rsvpd, going: x.going ? x.going + (x.rsvpd ? -1 : 1) : 1 } : x));
  };

  const renderLive = () => {
    const mine = LIVE_MATCHES.filter(m => m.mine);
    const others = LIVE_MATCHES.filter(m => !m.mine);
    const filterFn = (m) => filter === 'all' || (filter === 'mine' && m.mine) || (filter === 'lahore' && m.venue.includes('Lahore')) || (filter === 'spring' && m.tag.includes('Spring Cup')) || (filter === 'fnl' && m.tag.includes('Friday Night'));
    const myFiltered = mine.filter(filterFn);
    const otherFiltered = others.filter(filterFn);
    if (myFiltered.length === 0 && otherFiltered.length === 0) {
      return <EmptyTab title="No live matches" body="Nothing on the field right now in your area. Check Upcoming for what's next." cta="See upcoming" />;
    }
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {myFiltered.length > 0 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <SectionH label="YOUR TEAM IS PLAYING" side={`${myFiltered.length} live`} accent="var(--red)" />
            {myFiltered.map(m => <LiveCard key={m.id} m={m} onOpen={(mm) => setOpen({ m: mm, kind: 'live' })} />)}
          </div>
        )}
        {otherFiltered.length > 0 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <SectionH label="ALSO LIVE NEAR YOU" side={`${otherFiltered.length} matches · 50KM`} />
            {otherFiltered.map(m => <LiveCard key={m.id} m={m} onOpen={(mm) => setOpen({ m: mm, kind: 'live' })} />)}
          </div>
        )}
      </div>
    );
  };

  const renderUpcoming = () => {
    const filterFn = (m) => filter === 'all' || (filter === 'mine' && m.mine) || (filter === 'lahore' && m.venue.includes('Lahore')) || (filter === 'spring' && m.tag.includes('Spring Cup')) || (filter === 'fnl' && m.tag.includes('Friday Night'));
    const filtered = upcoming.filter(filterFn);
    if (filtered.length === 0) return <EmptyTab title="No upcoming matches" body="Nothing scheduled in this view. Try widening your filters or follow more tournaments." />;
    // group by day label
    const byDay = filtered.reduce((acc, m) => { (acc[m.dayLabel] = acc[m.dayLabel] || []).push(m); return acc; }, {});
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {Object.entries(byDay).map(([day, list]) => (
          <div key={day} style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <SectionH label={day.toUpperCase()} side={list[0]?.when || ''} />
            {list.map(m => <UpcomingCard key={m.id} m={m} onOpen={(mm) => setOpen({ m: mm, kind: 'upcoming' })} onRsvp={toggleRsvp} />)}
          </div>
        ))}
      </div>
    );
  };

  const renderRecent = () => {
    const filterFn = (m) => filter === 'all' || (filter === 'mine' && m.mine) || (filter === 'lahore' && m.venue.includes('Lahore')) || (filter === 'spring' && m.tag.includes('Spring Cup')) || (filter === 'fnl' && m.tag.includes('Friday Night'));
    const filtered = RECENT_MATCHES.filter(filterFn);
    if (filtered.length === 0) return <EmptyTab title="No recent matches" body="Completed matches from the last 7 days will appear here." />;
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <SectionH label="LAST 7 DAYS" side={`${filtered.length} matches`} />
        {filtered.map(m => <RecentCard key={m.id} m={m} onOpen={(mm) => setOpen({ m: mm, kind: 'recent' })} />)}
      </div>
    );
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      <MatchesHeader liveCount={LIVE_MATCHES.length} totalToday={LIVE_MATCHES.length + 4} />

      {tab === 'matches' ? (
        <>
          <SubTabs active={sub} setActive={setSub} counts={counts} />
          <MatchFilterBar filters={filters} active={filter} setActive={setFilter} />
          <div style={{ flex: 1, overflow: 'auto', padding: '6px 16px 16px' }}>
            {sub === 'live'     && renderLive()}
            {sub === 'upcoming' && renderUpcoming()}
            {sub === 'recent'   && renderRecent()}
            <div style={{ padding: '16px 0 4px', textAlign: 'center', fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.14em' }}>
              {sub === 'live' ? 'AUTO-REFRESH · 30S' : sub === 'upcoming' ? 'NEXT 7 DAYS' : 'LAST 7 DAYS'}
            </div>
          </div>
        </>
      ) : (
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 6, padding: 32, textAlign: 'center', color: 'var(--muted)' }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--ink)' }}>{tab[0].toUpperCase() + tab.slice(1)}</div>
          <div style={{ fontSize: 13 }}>This tab opens its dedicated screen.</div>
        </div>
      )}

      <MatchesTabBar active={tab} setActive={setTab} />
      {open && <MatchDetailSheet m={open.m} kind={open.kind} onClose={() => setOpen(null)} />}
    </div>
  );
}

window.CkMatches = Matches;

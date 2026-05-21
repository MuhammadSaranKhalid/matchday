// TeamHub.jsx — Team detail page (public / member view)
// Tabs: Squad · Matches · Stats · About
// Hero pulls primary color from team identity. Reuses CkTBadge/TEAMS from Tournament.jsx.

function CkTeamHub() {
  const [tab, setTab] = React.useState('Squad');

  // The team being viewed — uses Lahore Lions from the global TEAMS map for badge consistency.
  const team = {
    id: 'LL',
    name: 'Lahore Lions',
    type: 'Club',
    primary: TEAMS.LL.bg,
    monogram: TEAMS.LL.mono,
    city: 'Lahore',
    area: 'Model Town',
    homeGround: 'Gaddafi B Ground',
    founded: 2019,
    privacy: 'Public',
    isVerified: true,
    members: 18,
    record: { p: 47, w: 31, l: 14, t: 2 },
  };

  const Tab = ({ id }) => (
    <button onClick={() => setTab(id)} style={{
      flex: 1, padding: '12px 0', background: 'transparent', border: 'none', cursor: 'pointer',
      fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
      color: tab === id ? 'var(--ink)' : 'var(--muted)',
      borderBottom: tab === id ? '2px solid var(--ink)' : '2px solid transparent',
    }}>{id}</button>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar — overlays hero */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px 0', flexShrink: 0, position: 'relative', zIndex: 2 }}>
        <button style={{ background: 'rgba(255,255,255,0.18)', backdropFilter: 'blur(8px)', border: 'none', padding: 8, cursor: 'pointer', borderRadius: 999 }}>
          <svg width="18" height="18" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="white" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ display: 'flex', gap: 6 }}>
          <button style={{ background: 'rgba(255,255,255,0.18)', backdropFilter: 'blur(8px)', border: 'none', padding: 8, cursor: 'pointer', borderRadius: 999 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13"/></svg>
          </button>
          <button style={{ background: 'rgba(255,255,255,0.18)', backdropFilter: 'blur(8px)', border: 'none', padding: 8, cursor: 'pointer', borderRadius: 999 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>
          </button>
        </div>
      </div>

      {/* Hero — team color block */}
      <div style={{
        margin: '-44px 0 0', padding: '60px 18px 24px', background: team.primary, color: 'white',
        position: 'relative', overflow: 'hidden', flexShrink: 0,
      }}>
        {/* decorative pitch lines */}
        <svg width="320" height="200" viewBox="0 0 200 130" style={{ position: 'absolute', right: -30, top: -10, opacity: 0.08 }}>
          <ellipse cx="100" cy="65" rx="95" ry="55" stroke="white" strokeWidth="0.4" fill="none"/>
          <ellipse cx="100" cy="65" rx="55" ry="32" stroke="white" strokeWidth="0.4" fill="none"/>
          <rect x="92" y="35" width="16" height="60" stroke="white" strokeWidth="0.4" fill="none"/>
        </svg>

        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14, position: 'relative', zIndex: 1 }}>
          <div style={{
            width: 72, height: 72, borderRadius: 18,
            background: 'rgba(255,255,255,0.95)', color: team.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 30, letterSpacing: '-0.04em',
            boxShadow: '0 4px 16px rgba(0,0,0,0.18)',
          }}>{team.monogram}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 11, opacity: 0.8, fontFamily: 'JetBrains Mono', letterSpacing: '0.10em', display: 'flex', alignItems: 'center', gap: 6 }}>
              <span>{team.type.toUpperCase()}</span>
              <span>·</span>
              <span>{team.area.toUpperCase()}, {team.city.toUpperCase()}</span>
              {team.isVerified && (
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, padding: '1px 5px', borderRadius: 999, background: 'rgba(255,255,255,0.18)' }}>
                  <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                </span>
              )}
            </div>
            <h1 className="ck-display" style={{ fontSize: 30, fontWeight: 700, letterSpacing: '-0.025em', margin: '4px 0 0', lineHeight: 1, color: 'white' }}>
              {team.name}
            </h1>
          </div>
        </div>

        {/* W / L / T strip */}
        <div style={{ marginTop: 20, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 0, background: 'rgba(0,0,0,0.18)', borderRadius: 12, padding: 0, position: 'relative', zIndex: 1 }}>
          {[
            { l: 'PLAYED', v: team.record.p },
            { l: 'WON',    v: team.record.w },
            { l: 'LOST',   v: team.record.l },
            { l: 'WIN %',  v: Math.round((team.record.w / team.record.p) * 100) },
          ].map((s, i) => (
            <div key={i} style={{ padding: '10px 12px', borderLeft: i ? '1px solid rgba(255,255,255,0.12)' : 'none' }}>
              <div className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700, lineHeight: 1 }}>{s.v}</div>
              <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', opacity: 0.7, letterSpacing: '0.10em', marginTop: 3 }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* Action row */}
        <div style={{ marginTop: 14, display: 'flex', gap: 8, position: 'relative', zIndex: 1 }}>
          <button style={{
            flex: 1, padding: '11px 0', borderRadius: 11, border: 'none',
            background: 'white', color: team.primary,
            fontFamily: 'Inter', fontWeight: 700, fontSize: 13, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
            Follow
          </button>
          <button style={{
            padding: '11px 14px', borderRadius: 11,
            border: '1px solid rgba(255,255,255,0.35)', background: 'transparent', color: 'white',
            fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>Request to join</button>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', background: 'var(--paper)', position: 'sticky', top: 0, zIndex: 5, flexShrink: 0 }}>
        <Tab id="Squad" />
        <Tab id="Matches" />
        <Tab id="Stats" />
        <Tab id="About" />
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {tab === 'Squad' && <HubSquad team={team} />}
        {tab === 'Matches' && <HubMatches team={team} />}
        {tab === 'Stats' && <HubStats team={team} />}
        {tab === 'About' && <HubAbout team={team} />}
        <div style={{ height: 90 }} />
      </div>
    </div>
  );
}

// ─── Squad tab ──────────────────────────────────────
function HubSquad({ team }) {
  const SQUAD = [
    { n: 'Bilal Ahmed',    role: 'Captain',       jersey: 7,  bat: 'RHB', bowl: '—',     status: 'app',   last5: [42, 18, 0, 31, 67] },
    { n: 'Adeel Sheikh',   role: 'Wicket-Keeper', jersey: 11, bat: 'RHB', bowl: '—',     status: 'app',   last5: [12, 38, 22, 8, 41] },
    { n: 'Faraz Khan',     role: 'Vice-Captain',  jersey: 33, bat: 'LHB', bowl: 'RM',    status: 'app',   last5: [55, 27, 14, 9, 0] },
    { n: 'Hamza Tariq',    role: 'Player',        jersey: 18, bat: 'RHB', bowl: 'OB',    status: 'app',   last5: [3, 21, 0, 19, 4] },
    { n: 'Salman Raza',    role: 'Player',        jersey: 4,  bat: 'RHB', bowl: 'RFM',   status: 'app',   last5: [0, 0, 8, 12, 6] },
    { n: 'Tariq Hussain',  role: 'Player',        jersey: 9,  bat: 'LHB', bowl: 'SLA',   status: 'sms',   last5: [] },
    { n: 'Ahmed Khan',     role: 'Player',        jersey: 23, bat: 'RHB', bowl: '—',     status: 'unclaimed', last5: [12, 8] },
    { n: 'Imran Iqbal',    role: 'Player',        jersey: 14, bat: 'RHB', bowl: 'LB',    status: 'app',   last5: [44, 11, 27, 0, 18] },
  ];

  const groups = {
    'Captaincy & keeper': SQUAD.filter(p => ['Captain', 'Vice-Captain', 'Wicket-Keeper'].includes(p.role)),
    'Players': SQUAD.filter(p => p.role === 'Player'),
  };

  return (
    <div style={{ padding: '14px 0' }}>
      {/* Quick filters */}
      <div style={{ padding: '0 16px', display: 'flex', gap: 6, overflowX: 'auto', marginBottom: 8 }}>
        {['All', 'Batters', 'Bowlers', 'All-rounders', 'Keeper'].map((f, i) => (
          <button key={f} style={{
            flex: 'none', padding: '7px 12px', borderRadius: 999,
            border: '1px solid var(--hairline)',
            background: i === 0 ? 'var(--ink)' : 'var(--surface)',
            color: i === 0 ? 'var(--paper)' : 'var(--ink-2)',
            fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
          }}>{f}</button>
        ))}
      </div>

      {Object.entries(groups).map(([gname, players]) => (
        <div key={gname} style={{ marginTop: 12 }}>
          <div style={{ padding: '0 16px 6px', display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span className="ck-section-h">{gname}</span>
            <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)' }}>· {players.length}</span>
          </div>
          <div>
            {players.map((p, i) => <PlayerRow key={p.n} p={p} primary={team.primary} top={i === 0} />)}
          </div>
        </div>
      ))}
    </div>
  );
}

function PlayerRow({ p, primary, top }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: top ? 'none' : '1px solid var(--hairline)' }}>
      {/* Jersey number badge */}
      <div style={{
        width: 36, height: 36, borderRadius: 10, position: 'relative',
        background: p.status === 'unclaimed' ? 'transparent' : primary,
        color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 14, letterSpacing: '-0.02em',
        flexShrink: 0,
        border: p.status === 'unclaimed' ? '1px dashed var(--line)' : 'none',
        ...(p.status === 'unclaimed' && { color: 'var(--muted)' }),
      }}>
        #{p.jersey}
        {p.status === 'sms' && (
          <div style={{ position: 'absolute', top: -3, right: -3, width: 10, height: 10, borderRadius: 999, background: 'var(--amber)', border: '2px solid var(--paper)' }}/>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600, color: 'var(--ink)' }}>{p.n}</span>
          {p.role !== 'Player' && (
            <span className="ck-chip" style={{ padding: '1px 6px', fontSize: 9, background: 'var(--cream)', color: 'var(--ink-2)', borderColor: 'transparent', letterSpacing: '0.06em' }}>
              {p.role === 'Wicket-Keeper' ? 'WK' : p.role === 'Vice-Captain' ? 'VC' : 'C'}
            </span>
          )}
          {p.status === 'unclaimed' && (
            <span className="ck-chip" style={{ padding: '1px 6px', fontSize: 9, background: 'var(--paper-2)', color: 'var(--muted)', borderColor: 'var(--hairline)', letterSpacing: '0.06em' }}>UNCLAIMED</span>
          )}
        </div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>
          {p.bat}{p.bowl !== '—' ? ` · ${p.bowl}` : ''}
        </div>
      </div>
      {/* Sparkline last 5 */}
      <Sparkline values={p.last5.filter(v => typeof v === 'number')} />
    </div>
  );
}

function Sparkline({ values }) {
  if (!values || values.length === 0) {
    return <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.06em' }}>—</span>;
  }
  const max = Math.max(...values, 1);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 2, height: 22 }}>
      {values.map((v, i) => (
        <div key={i} style={{
          width: 4, height: Math.max(2, (v / max) * 22),
          borderRadius: 1, background: v === 0 ? 'var(--hairline)' : 'var(--ink)',
        }} />
      ))}
    </div>
  );
}

// ─── Matches tab ────────────────────────────────────
function HubMatches({ team }) {
  return (
    <div style={{ padding: '14px 0' }}>
      {/* Form chip strip */}
      <div style={{ padding: '0 16px 16px' }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Last 8</div>
        <div style={{ display: 'flex', gap: 6 }}>
          {['W','W','L','W','T','W','L','W'].map((r, i) => (
            <div key={i} style={{
              width: 28, height: 28, borderRadius: 8,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700, color: 'white',
              background: r === 'W' ? 'var(--green)' : r === 'L' ? 'var(--red)' : 'var(--cream)',
              ...(r === 'T' && { color: 'var(--ink-2)' }),
            }}>{r}</div>
          ))}
        </div>
      </div>

      {/* Upcoming */}
      <div style={{ padding: '0 16px 6px' }}>
        <span className="ck-section-h">Upcoming · 2</span>
      </div>
      <div>
        {[
          { date: 'Today · 14:00', round: 'Spring Cup QF1', venue: 'Gaddafi B', vs: 'MT', live: true },
          { date: 'May 6 · 16:00', round: 'Friendly', venue: 'Bagh-e-Jinnah', vs: 'KS', live: false },
        ].map((m, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)' }}>
            <div style={{ width: 44, textAlign: 'center', flexShrink: 0 }}>
              <div className="ck-mono" style={{ fontSize: 9, color: 'var(--muted)', letterSpacing: '0.06em' }}>{m.date.split(' · ')[0].toUpperCase()}</div>
              <div className="ck-display" style={{ fontSize: 13, fontWeight: 700, marginTop: 2 }}>{m.date.split(' · ')[1]}</div>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>vs</span>
                <CkTBadge id={m.vs} size={20} />
                <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{TEAMS[m.vs].name}</span>
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{m.round} · {m.venue}</div>
            </div>
            {m.live && <span className="ck-chip live" style={{ flexShrink: 0 }}>LIVE</span>}
          </div>
        ))}
      </div>

      {/* Recent results */}
      <div style={{ padding: '18px 16px 6px' }}>
        <span className="ck-section-h">Recent · 4</span>
      </div>
      <div>
        {[
          { date: 'Apr 28', vs: 'IT', us: '174/6', them: '142', won: true,  by: '32 runs' },
          { date: 'Apr 22', vs: 'GG', us: '88',    them: '92/4', won: false, by: '6 wkts' },
          { date: 'Apr 15', vs: 'PR', us: '156/8', them: '156',  won: 'tie', by: 'tie · super over' },
          { date: 'Apr 10', vs: 'FX', us: '198/4', them: '187/9',won: true,  by: '11 runs' },
        ].map((m, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)' }}>
            <div style={{
              width: 28, height: 28, borderRadius: 7, flexShrink: 0,
              background: m.won === true ? 'var(--green)' : m.won === 'tie' ? 'var(--cream)' : 'var(--red)',
              color: m.won === 'tie' ? 'var(--ink-2)' : 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 12,
            }}>{m.won === true ? 'W' : m.won === 'tie' ? 'T' : 'L'}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <CkTBadge id="LL" size={16} />
                <span className="ck-mono ck-tnum" style={{ fontSize: 12, fontWeight: 600 }}>{m.us}</span>
                <span style={{ color: 'var(--muted)', fontSize: 11 }}>vs</span>
                <CkTBadge id={m.vs} size={16} />
                <span className="ck-mono ck-tnum" style={{ fontSize: 12, fontWeight: 600, color: 'var(--ink-2)' }}>{m.them}</span>
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{m.date} · {m.won === true ? `Won by ${m.by}` : m.won === 'tie' ? m.by : `Lost by ${m.by}`}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Stats tab ──────────────────────────────────────
function HubStats({ team }) {
  return (
    <div style={{ padding: '18px 16px 0' }}>
      {/* Headline stat */}
      <div style={{
        padding: 18, borderRadius: 16, marginBottom: 16,
        background: 'var(--paper-2)', border: '1px solid var(--hairline)',
      }}>
        <div className="ck-section-h">All-time</div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, marginTop: 6 }}>
          <div className="ck-display ck-tnum" style={{ fontSize: 56, fontWeight: 800, lineHeight: 0.9, letterSpacing: '-0.04em' }}>66</div>
          <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--muted)', paddingBottom: 6 }}>%</div>
          <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
            <div className="ck-mono" style={{ fontSize: 11, color: 'var(--muted)' }}>WIN RATE</div>
            <div style={{ fontSize: 11, color: 'var(--green)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>+4 vs last season</div>
          </div>
        </div>
      </div>

      {/* Top performers */}
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Top performers · this season</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 16 }}>
        {[
          { kind: 'BAT', label: 'Most runs',    name: 'Bilal Ahmed',  v: '482', d: 'avg 40.2 · SR 138' },
          { kind: 'BOWL', label: 'Most wickets', name: 'Salman Raza', v: '21',  d: 'econ 6.4 · 1× 5w' },
          { kind: 'AR',   label: 'Best impact',  name: 'Faraz Khan',  v: '+58', d: 'runs + wkts adj.' },
        ].map((s, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10,
              background: 'var(--cream)', color: 'var(--ink-2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.06em',
            }}>{s.kind}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>{s.label.toUpperCase()}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600, marginTop: 2 }}>{s.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>{s.d}</div>
            </div>
            <div className="ck-display ck-tnum" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em' }}>{s.v}</div>
          </div>
        ))}
      </div>

      {/* By format */}
      <div className="ck-section-h" style={{ marginBottom: 8 }}>By format</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: 18 }}>
        {[
          { f: 'T20',  p: 28, w: 19 },
          { f: 'T10',  p: 14, w: 9  },
          { f: '50ov', p: 5,  w: 3  },
        ].map(s => (
          <div key={s.f} style={{ padding: 12, background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 12 }}>
            <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>{s.f}</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700, marginTop: 4 }}>{s.w}<span style={{ color: 'var(--muted)', fontWeight: 500 }}>/{s.p}</span></div>
            <div style={{ marginTop: 6, height: 4, borderRadius: 999, background: 'var(--paper-2)', overflow: 'hidden' }}>
              <div style={{ width: `${(s.w/s.p)*100}%`, height: '100%', background: 'var(--green)' }}/>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── About tab ──────────────────────────────────────
function HubAbout({ team }) {
  return (
    <div style={{ padding: '18px 16px 0' }}>
      <div style={{ marginBottom: 18 }}>
        <div className="ck-section-h" style={{ marginBottom: 6 }}>About</div>
        <p style={{ fontSize: 14, color: 'var(--ink-2)', lineHeight: 1.5, margin: 0 }}>
          Founded in {team.founded}, Lahore Lions play out of {team.area}. We run a year-round practice schedule and field a senior + youth side. New player trials open in March each year.
        </p>
      </div>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Details</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 18 }}>
        {[
          ['Type',        team.type],
          ['Founded',     team.founded],
          ['City',        team.city],
          ['Home ground', team.homeGround],
          ['Privacy',     team.privacy],
          ['Members',     `${team.members} active`],
        ].map(([k, v], i) => (
          <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
            <span className="ck-mono" style={{ fontSize: 11, color: 'var(--muted)', letterSpacing: '0.04em' }}>{k.toUpperCase()}</span>
            <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 500, color: 'var(--ink)' }}>{v}</span>
          </div>
        ))}
      </div>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Managers · 2</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        {[
          { n: 'Bilal Ahmed', role: 'Owner · Captain' },
          { n: 'Adeel Sheikh', role: 'Manager' },
        ].map((m, i) => (
          <div key={m.n} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
            <div className="ck-avatar">{m.n.split(' ').map(s => s[0]).join('')}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{m.n}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{m.role}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

window.CkTeamHub = CkTeamHub;

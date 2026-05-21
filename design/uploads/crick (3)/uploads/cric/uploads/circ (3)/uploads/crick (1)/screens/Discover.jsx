// Discover.jsx — Search + Discover tab. Two variants.

// =========================================================================
// Shared header
// =========================================================================
function DiscoverHeader({ city, onCityClick, onSearchFocus, query, setQuery, focused }) {
  return (
    <div style={{ padding: '14px 16px 12px', borderBottom: '1px solid var(--hairline)', background: 'var(--paper)', position: 'sticky', top: 0, zIndex: 5 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 700, letterSpacing: '-0.03em' }}>Discover</div>
        <button onClick={onCityClick} style={{
          padding: '7px 11px', borderRadius: 999, background: 'var(--paper-2)',
          border: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 6,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 600, color: 'var(--ink)', cursor: 'pointer',
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
          {city}
        </button>
      </div>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        background: focused ? 'var(--paper)' : 'var(--paper-2)',
        border: '1.5px solid ' + (focused ? 'var(--ink)' : 'var(--hairline)'),
        borderRadius: 12, padding: '10px 14px', transition: 'border-color .15s, background .15s',
      }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
        <input
          value={query}
          onChange={e => setQuery(e.target.value)}
          onFocus={onSearchFocus}
          placeholder="Players, teams, tournaments, matches"
          style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontFamily: 'inherit', fontSize: 14, color: 'var(--ink)' }}
        />
        {query && (
          <button onClick={() => setQuery('')} style={{ border: 'none', background: 'transparent', cursor: 'pointer', padding: 0, display: 'flex', alignItems: 'center' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/></svg>
          </button>
        )}
      </div>
    </div>
  );
}

// =========================================================================
// Variant A — Discover tab (5 sections, geo-aware)
// =========================================================================

function DiscoverA() {
  const [city, setCity] = React.useState('Lahore');
  const [query, setQuery] = React.useState('');
  const [showCity, setShowCity] = React.useState(false);
  const [savedItems, setSavedItems] = React.useState(new Set(['galle-night']));

  const toggleSave = id => {
    setSavedItems(s => {
      const n = new Set(s);
      n.has(id) ? n.delete(id) : n.add(id);
      return n;
    });
  };

  const cities = ['Lahore', 'Karachi', 'Faisalabad', 'Multan', 'Islamabad', 'Peshawar'];

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <DiscoverHeader city={city} query={query} setQuery={setQuery}
        onCityClick={() => setShowCity(true)} onSearchFocus={() => {}} />

      <div style={{ flex: 1, overflow: 'auto' }}>

        {/* ── LIVE NOW ───────────────────────────────────────── */}
        <div style={{ padding: '18px 16px 4px' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span className="ck-chip live">LIVE</span>
              <div className="ck-section-h" style={{ color: 'var(--ink)' }}>Right now in {city}</div>
            </div>
            <button style={{ background: 'transparent', border: 'none', fontSize: 12, fontFamily: 'inherit', color: 'var(--muted)', cursor: 'pointer' }}>See all 7</button>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 10, padding: '0 16px 4px', overflowX: 'auto', scrollSnapType: 'x mandatory' }}>
          {[
            { home: 'Lions', away: 'Eagles', hs: '127/4', as: '63/2', ov: '8.3', m: 'Spring Cup · QF', live: true },
            { home: 'Mohalla Kings', away: 'DHA Utd', hs: '89/8', as: '—', ov: '14.1', m: 'Friday League', live: true },
            { home: 'Royal XI', away: 'Defenders', hs: '156/6', as: '—', ov: '20.0', m: 'Tape-ball Cup', live: true },
          ].map((m, i) => (
            <div key={i} style={{
              flex: 'none', width: 240, padding: 12, borderRadius: 14,
              border: '1px solid var(--hairline)', background: 'var(--paper)', scrollSnapAlign: 'start',
            }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: '0.08em', color: 'var(--muted)', textTransform: 'uppercase', marginBottom: 8, display: 'flex', justifyContent: 'space-between' }}>
                <span>{m.m}</span><span style={{ color: 'var(--red)' }}>● {m.ov} ov</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', alignItems: 'center', gap: 6, marginBottom: 6 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600 }}>{m.home}</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{m.hs}</div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', alignItems: 'center', gap: 6 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600, color: 'var(--muted)' }}>{m.away}</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', color: 'var(--muted)' }}>{m.as}</div>
              </div>
            </div>
          ))}
        </div>

        {/* ── TOURNAMENTS NEAR YOU ───────────────────────────── */}
        <div style={{ padding: '24px 16px 8px' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
            <div className="ck-section-h" style={{ color: 'var(--ink)' }}>Tournaments near you</div>
            <button style={{ background: 'transparent', border: 'none', fontSize: 12, fontFamily: 'inherit', color: 'var(--muted)', cursor: 'pointer' }}>See all</button>
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10, marginBottom: 12, overflowX: 'auto' }}>
            {['Open registration', 'This weekend', 'Tape-ball', 'Hard-ball', '< 5km'].map((f, i) => (
              <button key={i} style={{
                flex: 'none', padding: '6px 11px', borderRadius: 999,
                background: i === 0 ? 'var(--ink)' : 'var(--paper-2)',
                color: i === 0 ? 'var(--paper)' : 'var(--ink-2)',
                border: '1px solid ' + (i === 0 ? 'var(--ink)' : 'var(--hairline)'),
                fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
              }}>{f}</button>
            ))}
          </div>
        </div>
        {[
          { id: 'galle-night', name: 'Galle Night League', t: 'Tape-ball T10', date: 'Apr 18 – May 6', teams: '12/16', dist: '2.4 km', open: true },
          { id: 'mohalla22', name: 'Mohalla Champions \'26', t: 'Hard-ball T20', date: 'May 2 – May 24', teams: '18/24', dist: '4.1 km', open: true },
          { id: 'rotary', name: 'Rotary Friendship Cup', t: 'Hard-ball T20', date: 'May 9 – Jun 1', teams: '7/16', dist: '6.8 km', open: true },
        ].map(t => (
          <div key={t.id} onClick={() => window.__ckNav && window.__ckNav.push('tournament')} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)', cursor: 'pointer' }}>
            <div style={{ width: 44, height: 44, borderRadius: 10, background: 'var(--cream)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="1.8"><path d="M6 9V7a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M6 9h12l-1 11H7Z"/></svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>{t.name}</div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', marginTop: 2, letterSpacing: '0.04em' }}>{t.t} · {t.date} · {t.dist}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, color: t.open ? 'var(--green)' : 'var(--muted)' }}>{t.teams}</div>
              <button onClick={(e) => { e.stopPropagation(); toggleSave(t.id); }} style={{ marginTop: 4, background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill={savedItems.has(t.id) ? 'var(--ink)' : 'none'} stroke="var(--ink)" strokeWidth="1.8"><path d="m19 21-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2Z"/></svg>
              </button>
            </div>
          </div>
        ))}

        {/* ── TOP TEAMS IN CITY ──────────────────────────────── */}
        <div style={{ padding: '24px 16px 8px' }}>
          <div className="ck-section-h" style={{ color: 'var(--ink)' }}>Top teams in {city}</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>By win-rate this season</div>
        </div>
        {[
          { rank: 1, name: 'Lahore Lions', w: '14W·2L', wr: 87, c: 'oklch(0.62 0.19 28)' },
          { rank: 2, name: 'Defenders XI', w: '13W·3L', wr: 81, c: 'oklch(0.36 0.10 148)' },
          { rank: 3, name: 'Mohalla Kings', w: '11W·5L', wr: 69, c: 'oklch(0.78 0.14 80)' },
        ].map(t => (
          <div key={t.rank} onClick={() => window.__ckNav && window.__ckNav.push('team')} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 16px', borderTop: '1px solid var(--hairline)', cursor: 'pointer' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', width: 18 }}>0{t.rank}</div>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: t.c, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700 }}>{t.name.split(' ').map(w => w[0]).slice(0,2).join('')}</div>
            <div style={{ flex: 1, fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{t.name}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{t.w}</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', minWidth: 36, textAlign: 'right' }}>{t.wr}<span style={{ fontSize: 10, color: 'var(--muted)' }}>%</span></div>
          </div>
        ))}

        {/* ── TOP PLAYERS ────────────────────────────────────── */}
        <div style={{ padding: '24px 16px 8px' }}>
          <div className="ck-section-h" style={{ color: 'var(--ink)' }}>Players to watch · Punjab</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>Top batting average · last 30 days</div>
        </div>
        <div style={{ padding: '0 16px 8px' }}>
          {[
            { rank: 1, name: 'Ahmed Sheikh', team: 'Defenders XI', stat: '52.4', sub: 'avg · 4 inn' },
            { rank: 2, name: 'Bilal Khan', team: 'Lahore Lions', stat: '47.2', sub: 'avg · 5 inn' },
            { rank: 3, name: 'Faraz Ali', team: 'DHA United', stat: '44.0', sub: 'avg · 3 inn' },
          ].map(p => (
            <div key={p.rank} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderTop: '1px solid var(--hairline)' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', width: 18 }}>0{p.rank}</div>
              <div className="ck-avatar" style={{ width: 32, height: 32, fontSize: 12 }}>{p.name.split(' ').map(w => w[0]).join('')}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{p.name}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{p.team}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{p.stat}</div>
                <div style={{ fontSize: 10, color: 'var(--muted)' }}>{p.sub}</div>
              </div>
            </div>
          ))}
        </div>

        {/* ── RECENTLY ACTIVE ───────────────────────────────── */}
        <div style={{ padding: '24px 16px 12px' }}>
          <div className="ck-section-h" style={{ color: 'var(--ink)' }}>Recently active</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 12 }}>
            {[
              { name: 'Galle Boys', sub: 'posted 2h', kind: 'team' },
              { name: 'Hassan R.', sub: 'scored 88* · 2h', kind: 'player' },
              { name: 'Friday League', sub: 'live now', kind: 'tour' },
              { name: 'City Eagles', sub: 'recruiting', kind: 'team' },
            ].map((it, i) => (
              <div key={i} style={{ padding: 12, borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)' }}>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{it.kind}</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, marginTop: 4 }}>{it.name}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{it.sub}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ height: 24 }} />
      </div>

      {/* City picker sheet */}
      {showCity && (
        <div onClick={() => setShowCity(false)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.4)', zIndex: 30, display: 'flex', alignItems: 'flex-end' }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--paper)', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: '18px 20px 28px' }}>
            <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 14px' }} />
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginBottom: 14 }}>Change location</div>
            {cities.map(c => (
              <button key={c} onClick={() => { setCity(c); setShowCity(false); }} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                width: '100%', padding: '14px 0', border: 'none', borderBottom: '1px solid var(--hairline)',
                background: 'transparent', fontFamily: 'inherit', fontSize: 15, fontWeight: 500, color: 'var(--ink)', cursor: 'pointer',
              }}>
                <span>{c}</span>
                {city === c && <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// =========================================================================
// Variant B — Active search with debounced categorized results
// =========================================================================

function DiscoverB() {
  const [query, setQuery] = React.useState('lah');
  const [debounced, setDebounced] = React.useState('lah');

  React.useEffect(() => {
    const id = setTimeout(() => setDebounced(query), 200);
    return () => clearTimeout(id);
  }, [query]);

  const recent = ['Bilal Khan', 'Spring Cup', 'Lahore Lions'];

  // Simple substring filter on categorized data
  const all = {
    Players: [
      { id: 'p1', name: 'Bilal Khan', sub: '@bilalk · Lahore Lions · top-order bat' },
      { id: 'p2', name: 'Lahmed Iqbal', sub: '@laqbal · DHA United · all-rounder' },
      { id: 'p3', name: 'Hassan Raza', sub: '@hassan_r · Mohalla Kings · spinner' },
    ],
    Teams: [
      { id: 't1', name: 'Lahore Lions', sub: 'Lahore · 14W–2L · captained by Adeel S.' },
      { id: 't2', name: 'Lahore Defenders', sub: 'Lahore · est. 2021 · 24 players' },
    ],
    Tournaments: [
      { id: 'tr1', name: 'Spring Cup \'26', sub: 'Lahore · T20 · live now' },
      { id: 'tr2', name: 'Lahore City Premier', sub: 'Lahore · T20 · registration closes May 6' },
    ],
    Matches: [
      { id: 'm1', name: 'Lahore Lions vs City Eagles', sub: 'Spring Cup · QF · live · 127/4 (8.3)' },
    ],
  };

  const matches = (s, q) => s.toLowerCase().includes(q.toLowerCase());
  const filtered = Object.fromEntries(
    Object.entries(all).map(([k, v]) => [k, v.filter(it => matches(it.name + ' ' + it.sub, debounced))])
  );
  const totalCount = Object.values(filtered).reduce((a, v) => a + v.length, 0);

  const Icon = ({ kind }) => {
    if (kind === 'Players') return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="8" r="4"/><path d="M4 21v-1a8 8 0 0 1 16 0v1"/></svg>;
    if (kind === 'Teams') return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 21v-2a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v2"/><circle cx="12" cy="7" r="4"/></svg>;
    if (kind === 'Tournaments') return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9V7a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M6 9h12l-1 11H7Z"/></svg>;
    return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>;
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <DiscoverHeader city="Lahore" query={query} setQuery={setQuery} onCityClick={() => {}} onSearchFocus={() => {}} />

      <div style={{ flex: 1, overflow: 'auto' }}>

        {/* Status bar */}
        <div style={{ padding: '10px 16px', borderBottom: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>
            {debounced === '' ? 'TYPE TO SEARCH' : `${totalCount} RESULT${totalCount === 1 ? '' : 'S'} FOR "${debounced.toUpperCase()}"`}
          </div>
          {debounced !== query && (
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>typing…</div>
          )}
        </div>

        {/* Empty state shows recents + suggestions */}
        {debounced === '' && (
          <div>
            <div style={{ padding: '16px 16px 6px' }}>
              <div className="ck-section-h">Recent</div>
            </div>
            {recent.map((r, i) => (
              <button key={i} onClick={() => setQuery(r)} style={{
                display: 'flex', alignItems: 'center', gap: 12, width: '100%', padding: '12px 16px',
                background: 'transparent', border: 'none', borderTop: '1px solid var(--hairline)',
                cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
              }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/></svg>
                <div style={{ flex: 1, fontSize: 14 }}>{r}</div>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
              </button>
            ))}
            <div style={{ padding: '20px 16px 8px' }}>
              <div className="ck-section-h">Try searching</div>
            </div>
            <div style={{ padding: '0 16px 16px', display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {['#tape-ball', '#weekend tournaments', '#wicket-keepers', 'Karachi teams', 'Friday league'].map((t, i) => (
                <button key={i} onClick={() => setQuery(t)} style={{
                  padding: '6px 11px', borderRadius: 999, background: 'var(--paper-2)',
                  border: '1px solid var(--hairline)', fontSize: 11, fontWeight: 500, fontFamily: 'inherit', color: 'var(--ink-2)', cursor: 'pointer',
                }}>{t}</button>
              ))}
            </div>
          </div>
        )}

        {/* Results */}
        {debounced !== '' && totalCount === 0 && (
          <div style={{ padding: '60px 24px', textAlign: 'center', color: 'var(--muted)' }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 600, color: 'var(--ink)', marginBottom: 6 }}>No results</div>
            <div style={{ fontSize: 13 }}>Nothing matches "{debounced}".</div>
            <button style={{ marginTop: 16, padding: '10px 18px', background: 'var(--ink)', color: 'var(--paper)', border: 'none', borderRadius: 10, fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Invite to Circk</button>
          </div>
        )}

        {Object.entries(filtered).map(([kind, items]) => items.length > 0 && (
          <div key={kind}>
            <div style={{ padding: '16px 16px 6px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--muted)' }}>
                <Icon kind={kind} />
                <div className="ck-section-h">{kind}</div>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10 }}>· {items.length}</div>
              </div>
              {items.length >= 2 && <button style={{ background: 'transparent', border: 'none', fontSize: 11, fontFamily: 'inherit', color: 'var(--muted)', cursor: 'pointer' }}>See all</button>}
            </div>
            {items.map(it => (
              <div key={it.id} onClick={() => {
                if (!window.__ckNav) return;
                if (kind === 'Tournaments') window.__ckNav.push('tournament');
                else if (kind === 'Matches') window.__ckNav.push('match');
                else if (kind === 'Teams') window.__ckNav.push('team');
                else if (kind === 'Players') window.__ckNav.push('profile');
              }} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 16px', borderTop: '1px solid var(--hairline)', cursor: 'pointer' }}>
                <div className="ck-avatar" style={{ width: 36, height: 36 }}>{it.name.split(' ').map(w => w[0]).slice(0,2).join('')}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, letterSpacing: '-0.01em' }}>
                    <Highlight text={it.name} q={debounced} />
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {it.sub}
                  </div>
                </div>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
              </div>
            ))}
          </div>
        ))}

        <div style={{ height: 24 }} />
      </div>
    </div>
  );
}

function Highlight({ text, q }) {
  if (!q) return text;
  const idx = text.toLowerCase().indexOf(q.toLowerCase());
  if (idx === -1) return text;
  return (
    <span>
      {text.slice(0, idx)}
      <span style={{ background: 'oklch(0.94 0.05 90)', padding: '0 2px', borderRadius: 3 }}>{text.slice(idx, idx + q.length)}</span>
      {text.slice(idx + q.length)}
    </span>
  );
}

window.CkDiscoverA = DiscoverA;
window.CkDiscoverB = DiscoverB;

// Rankings.jsx — Leaderboards across 12 dimensions (§5.8.1)

function Rankings() {
  const [dim, setDim] = React.useState('Most runs');
  const [scope, setScope] = React.useState('Lahore');
  const [format, setFormat] = React.useState('All');
  const [period, setPeriod] = React.useState('30d');
  const [showScope, setShowScope] = React.useState(false);

  // The 12 ranking dimensions
  const dimensions = [
    { id: 'Most runs', cat: 'Batting', unit: '', short: 'runs' },
    { id: 'Best average', cat: 'Batting', unit: '', short: 'avg' },
    { id: 'Best strike rate', cat: 'Batting', unit: '', short: 'sr' },
    { id: 'Most 50s/100s', cat: 'Batting', unit: '', short: 'fifties' },
    { id: 'Most sixes', cat: 'Batting', unit: '', short: 'sixes' },
    { id: 'Most wickets', cat: 'Bowling', unit: '', short: 'wkts' },
    { id: 'Best economy', cat: 'Bowling', unit: '', short: 'econ' },
    { id: 'Best bowling avg', cat: 'Bowling', unit: '', short: 'avg' },
    { id: 'Most 5-fers', cat: 'Bowling', unit: '', short: '5w' },
    { id: 'Most catches', cat: 'Fielding', unit: '', short: 'ct' },
    { id: 'Most run-outs', cat: 'Fielding', unit: '', short: 'ro' },
    { id: 'Best team win-rate', cat: 'Team', unit: '%', short: 'wr' },
  ];

  // Mock leaderboards keyed by dimension
  const data = {
    'Most runs': [
      { name: 'Bilal Khan', team: 'Lahore Lions', stat: 487, sub: '11 inn · avg 44.3' },
      { name: 'Ahmed Sheikh', team: 'Defenders XI', stat: 412, sub: '9 inn · avg 51.5' },
      { name: 'Hassan Raza', team: 'Mohalla Kings', stat: 394, sub: '12 inn · avg 32.8' },
      { name: 'Faraz Ali', team: 'DHA United', stat: 358, sub: '10 inn · avg 39.8' },
      { name: 'Adeel Sheikh', team: 'Lahore Lions', stat: 312, sub: '11 inn · avg 28.4' },
      { name: 'Imran Aslam', team: 'Galle Boys', stat: 298, sub: '8 inn · avg 49.7' },
      { name: 'Saqib M.', team: 'Royal XI', stat: 274, sub: '10 inn · avg 30.4' },
      { name: 'Tariq M.', team: 'City Eagles', stat: 251, sub: '9 inn · avg 35.9' },
    ],
    'Best average': [
      { name: 'Ahmed Sheikh', team: 'Defenders XI', stat: 51.5, sub: '412 r · 9 inn' },
      { name: 'Imran Aslam', team: 'Galle Boys', stat: 49.7, sub: '298 r · 8 inn' },
      { name: 'Bilal Khan', team: 'Lahore Lions', stat: 44.3, sub: '487 r · 11 inn' },
      { name: 'Faraz Ali', team: 'DHA United', stat: 39.8, sub: '358 r · 10 inn' },
      { name: 'Tariq M.', team: 'City Eagles', stat: 35.9, sub: '251 r · 9 inn' },
    ],
    'Best strike rate': [
      { name: 'Hassan Raza', team: 'Mohalla Kings', stat: 168.4, sub: '394 r · 234 b' },
      { name: 'Bilal Khan', team: 'Lahore Lions', stat: 152.8, sub: '487 r · 319 b' },
      { name: 'Junaid Q.', team: 'Royal XI', stat: 148.2, sub: '187 r · 126 b' },
      { name: 'Adeel Sheikh', team: 'Lahore Lions', stat: 141.6, sub: '312 r · 220 b' },
    ],
    'Most 50s/100s': [
      { name: 'Bilal Khan', team: 'Lahore Lions', stat: '5/1', sub: '5×50 · 1×100' },
      { name: 'Ahmed Sheikh', team: 'Defenders XI', stat: '4/1', sub: '4×50 · 1×100' },
      { name: 'Imran Aslam', team: 'Galle Boys', stat: '3/0', sub: '3×50' },
    ],
    'Most sixes': [
      { name: 'Hassan Raza', team: 'Mohalla Kings', stat: 31, sub: '12 inn' },
      { name: 'Bilal Khan', team: 'Lahore Lions', stat: 24, sub: '11 inn' },
      { name: 'Junaid Q.', team: 'Royal XI', stat: 19, sub: '7 inn' },
    ],
    'Most wickets': [
      { name: 'Tariq Mahmood', team: 'Lahore Lions', stat: 28, sub: '11 m · econ 6.4' },
      { name: 'Lasith Silva', team: 'Galle Boys', stat: 24, sub: '9 m · econ 5.8' },
      { name: 'V. Krishna', team: 'Royal Madras', stat: 22, sub: '10 m · econ 7.2' },
      { name: 'Ali Raza', team: 'Defenders XI', stat: 20, sub: '11 m · econ 6.9' },
      { name: 'Hassan Raza', team: 'Mohalla Kings', stat: 18, sub: '12 m · econ 7.4' },
    ],
    'Best economy': [
      { name: 'Lasith Silva', team: 'Galle Boys', stat: 5.8, sub: '24 wkts · 9 m' },
      { name: 'Tariq Mahmood', team: 'Lahore Lions', stat: 6.4, sub: '28 wkts · 11 m' },
      { name: 'Ali Raza', team: 'Defenders XI', stat: 6.9, sub: '20 wkts · 11 m' },
    ],
    'Best bowling avg': [
      { name: 'Lasith Silva', team: 'Galle Boys', stat: 11.2, sub: '24 wkts' },
      { name: 'Tariq Mahmood', team: 'Lahore Lions', stat: 14.8, sub: '28 wkts' },
      { name: 'V. Krishna', team: 'Royal Madras', stat: 16.4, sub: '22 wkts' },
    ],
    'Most 5-fers': [
      { name: 'Lasith Silva', team: 'Galle Boys', stat: 2, sub: '5/14, 5/22' },
      { name: 'Tariq Mahmood', team: 'Lahore Lions', stat: 1, sub: '5/18 vs Eagles' },
    ],
    'Most catches': [
      { name: 'Adeel Sheikh', team: 'Lahore Lions', stat: 19, sub: 'WK · 11 m' },
      { name: 'Saad Iqbal', team: 'Defenders XI', stat: 14, sub: 'slip · 11 m' },
      { name: 'Junaid Q.', team: 'Royal XI', stat: 11, sub: '7 m' },
    ],
    'Most run-outs': [
      { name: 'Hassan Raza', team: 'Mohalla Kings', stat: 6, sub: '12 m' },
      { name: 'Faraz Ali', team: 'DHA United', stat: 4, sub: '10 m' },
      { name: 'Adeel Sheikh', team: 'Lahore Lions', stat: 3, sub: '11 m' },
    ],
    'Best team win-rate': [
      { name: 'Lahore Lions', team: 'Lahore', stat: 87, sub: '14W · 2L · 16 m', isTeam: true, c: 'oklch(0.62 0.19 28)' },
      { name: 'Defenders XI', team: 'Lahore', stat: 81, sub: '13W · 3L · 16 m', isTeam: true, c: 'oklch(0.36 0.10 148)' },
      { name: 'Galle Boys', team: 'Lahore', stat: 75, sub: '9W · 3L · 12 m', isTeam: true, c: 'oklch(0.30 0.02 80)' },
      { name: 'Mohalla Kings', team: 'Lahore', stat: 69, sub: '11W · 5L · 16 m', isTeam: true, c: 'oklch(0.78 0.14 80)' },
    ],
  };

  const rows = data[dim] || [];
  const max = rows.length ? (typeof rows[0].stat === 'number' ? rows[0].stat : 100) : 100;
  const cats = ['Batting', 'Bowling', 'Fielding', 'Team'];
  const dimsByCat = Object.fromEntries(cats.map(c => [c, dimensions.filter(d => d.cat === c)]));

  const dimMeta = dimensions.find(d => d.id === dim);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      {/* Header */}
      <div style={{ padding: '14px 20px 0', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em' }}>Rankings</div>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"/></svg>
        </div>

        {/* Filter row 1: scope + format + period */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 10, overflowX: 'auto' }}>
          <button onClick={() => setShowScope(true)} style={{
            flex: 'none', padding: '7px 11px', borderRadius: 999, background: 'var(--ink)',
            border: 'none', display: 'flex', alignItems: 'center', gap: 6,
            color: 'var(--paper)', fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
          }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
            {scope}
          </button>
          {['All', 'T20', 'T10', 'Tape-ball'].map(f => (
            <button key={f} onClick={() => setFormat(f)} style={{
              flex: 'none', padding: '7px 11px', borderRadius: 999,
              background: format === f ? 'var(--paper-2)' : 'var(--paper)',
              border: '1px solid ' + (format === f ? 'var(--ink)' : 'var(--hairline)'),
              color: 'var(--ink-2)', fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
            }}>{f}</button>
          ))}
          <div style={{ width: 1, alignSelf: 'stretch', background: 'var(--hairline)', margin: '0 2px' }} />
          {['7d', '30d', 'Season', 'All-time'].map(p => (
            <button key={p} onClick={() => setPeriod(p)} style={{
              flex: 'none', padding: '7px 11px', borderRadius: 999,
              background: period === p ? 'var(--paper-2)' : 'var(--paper)',
              border: '1px solid ' + (period === p ? 'var(--ink)' : 'var(--hairline)'),
              color: 'var(--ink-2)', fontSize: 11, fontFamily: 'JetBrains Mono', fontWeight: 600, cursor: 'pointer',
            }}>{p}</button>
          ))}
        </div>

        {/* Dimension switcher: scrollable categorized */}
        <div style={{ display: 'flex', gap: 16, overflowX: 'auto', paddingBottom: 0 }}>
          {cats.map(cat => (
            <div key={cat} style={{ display: 'flex', flexDirection: 'column', flex: 'none' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 6, paddingLeft: 2 }}>{cat}</div>
              <div style={{ display: 'flex', gap: 4, paddingBottom: 10 }}>
                {dimsByCat[cat].map(d => (
                  <button key={d.id} onClick={() => setDim(d.id)} style={{
                    flex: 'none', padding: '6px 10px', borderRadius: 8,
                    background: dim === d.id ? 'var(--ink)' : 'transparent',
                    color: dim === d.id ? 'var(--paper)' : 'var(--ink-2)',
                    border: '1px solid ' + (dim === d.id ? 'var(--ink)' : 'var(--hairline)'),
                    fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', whiteSpace: 'nowrap',
                  }}>{d.id}</button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* Hero block: top 3 podium */}
        <div style={{ padding: '14px 20px 0' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em' }}>{dim}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>{scope.toUpperCase()} · {format.toUpperCase()} · {period.toUpperCase()}</div>
          </div>
          <div style={{ fontSize: 11, color: 'var(--muted)' }}>
            {dimMeta?.cat} · {rows.length} qualifying {dimMeta?.cat === 'Team' ? 'teams' : 'players'}
          </div>
        </div>

        {/* Top 3 podium row */}
        {rows.length >= 3 && (
          <div style={{ padding: '14px 20px', display: 'grid', gridTemplateColumns: '1fr 1.2fr 1fr', alignItems: 'end', gap: 8 }}>
            {[1, 0, 2].map(i => {
              const r = rows[i];
              const isFirst = i === 0;
              const podHeights = { 0: 80, 1: 60, 2: 50 };
              return (
                <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <div style={{ width: 44, height: 44, borderRadius: 999, background: r.isTeam ? r.c : 'var(--paper-2)', border: '1.5px solid ' + (isFirst ? 'oklch(0.78 0.14 80)' : 'var(--hairline)'), display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, color: r.isTeam ? 'white' : 'var(--ink)' }}>
                    {r.name.split(' ').map(w => w[0]).slice(0,2).join('')}
                  </div>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 600, marginTop: 6, textAlign: 'center', letterSpacing: '-0.005em', maxWidth: '100%', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: isFirst ? 28 : 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em', color: 'var(--ink)' }}>
                    {r.stat}{dimMeta?.unit}
                  </div>
                  <div style={{
                    width: '100%', height: podHeights[i], marginTop: 6,
                    background: isFirst ? 'var(--ink)' : 'var(--paper-2)',
                    borderRadius: '6px 6px 0 0',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    color: isFirst ? 'oklch(0.78 0.14 80)' : 'var(--muted)',
                    fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 22, letterSpacing: '-0.02em',
                  }}>{i + 1}</div>
                </div>
              );
            })}
          </div>
        )}

        {/* Long list */}
        <div style={{ padding: '6px 0 8px' }}>
          {rows.map((r, i) => {
            const pct = typeof r.stat === 'number' ? Math.max(8, (r.stat / max) * 100) : 100;
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 20px',
                borderTop: i === 0 ? '1px solid var(--hairline)' : 'none',
                borderBottom: '1px solid var(--hairline)',
                background: i < 3 ? 'oklch(0.99 0.012 85)' : 'var(--paper)',
              }}>
                <div style={{ width: 22, fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', textAlign: 'right' }}>0{i + 1}</div>
                <div style={{
                  width: 32, height: 32, borderRadius: r.isTeam ? 7 : 999,
                  background: r.isTeam ? r.c : 'var(--paper-2)',
                  border: '1px solid ' + (r.isTeam ? 'transparent' : 'var(--hairline)'),
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11,
                  color: r.isTeam ? 'white' : 'var(--ink-2)', flexShrink: 0,
                }}>{r.name.split(' ').map(w => w[0]).slice(0,2).join('')}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, letterSpacing: '-0.005em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                  <div style={{ fontSize: 10.5, color: 'var(--muted)', marginTop: 1 }}>{r.team} · {r.sub}</div>
                </div>
                <div style={{ width: 64, height: 4, background: 'var(--hairline)', borderRadius: 999, overflow: 'hidden', flexShrink: 0 }}>
                  <div style={{ width: pct + '%', height: '100%', background: i === 0 ? 'var(--ink)' : 'var(--soft)' }} />
                </div>
                <div style={{ minWidth: 60, textAlign: 'right' }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 17, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{r.stat}{dimMeta?.unit && <span style={{ fontSize: 11, color: 'var(--muted)' }}>{dimMeta.unit}</span>}</div>
                </div>
              </div>
            );
          })}
        </div>

        <div style={{ padding: '12px 20px 22px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 11, color: 'var(--muted)' }}>Min. 5 innings to qualify</div>
          <button style={{ background: 'transparent', border: 'none', fontSize: 12, fontFamily: 'inherit', color: 'var(--ink)', cursor: 'pointer', fontWeight: 600 }}>Methodology →</button>
        </div>
      </div>

      {/* Scope picker sheet */}
      {showScope && (
        <div onClick={() => setShowScope(false)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.45)', zIndex: 30, display: 'flex', alignItems: 'flex-end' }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--paper)', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: '18px 20px 24px' }}>
            <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 14px' }} />
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginBottom: 4 }}>Geographic scope</div>
            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 14 }}>Show rankings for</div>
            {[
              { l: 'Your area', sub: '< 5km · Cantt, Lahore', v: '< 5km' },
              { l: 'Lahore', sub: '4 zones · 142 teams', v: 'Lahore' },
              { l: 'Punjab', sub: '12 cities · 1.4k teams', v: 'Punjab' },
              { l: 'Pakistan', sub: 'all-country', v: 'Pakistan' },
              { l: 'Worldwide', sub: 'all locations', v: 'World' },
            ].map((s, i) => (
              <button key={i} onClick={() => { setScope(s.v); setShowScope(false); }} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                width: '100%', padding: '12px 0', border: 'none', borderBottom: i < 4 ? '1px solid var(--hairline)' : 'none',
                background: 'transparent', fontFamily: 'inherit', textAlign: 'left', cursor: 'pointer',
              }}>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{s.l}</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{s.sub}</div>
                </div>
                {scope === s.v && <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

window.CkRankings = Rankings;

// Profile.jsx — Player profile, 3 INTERACTIVE variants

function ProfileHeader({ following, setFollowing, dark = false }) {
  return (
    <div style={{
      padding: '14px 20px 18px',
      background: dark ? 'var(--ink)' : 'var(--paper)',
      color: dark ? 'var(--paper)' : 'var(--ink)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'inherit' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <div style={{ flex: 1 }} />
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 16 }}>
        <div style={{
          width: 64, height: 64, borderRadius: 999,
          background: dark ? 'oklch(0.30 0.02 80)' : 'var(--paper-2)',
          border: '1px solid ' + (dark ? 'oklch(0.30 0.02 80)' : 'var(--hairline)'),
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 24,
        }}>BK</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 24, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1 }}>Bilal Khan</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: dark ? 'oklch(0.72 0.01 80)' : 'var(--muted)', marginTop: 4 }}>@bilalk · Lahore Lions</div>
          <div style={{ fontSize: 12, color: dark ? 'oklch(0.72 0.01 80)' : 'var(--ink-2)', marginTop: 4 }}>Top-order bat · Right arm med</div>
        </div>
      </div>
    </div>
  );
}

function FollowRow({ following, setFollowing }) {
  return (
    <div style={{ display: 'flex', gap: 8, padding: '0 20px 14px' }}>
      <button onClick={() => setFollowing(!following)} style={{
        flex: 1, padding: '10px 0', borderRadius: 10, border: 'none',
        background: following ? 'var(--paper-2)' : 'var(--ink)',
        color: following ? 'var(--ink)' : 'var(--paper)',
        fontWeight: 600, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer',
        border: following ? '1px solid var(--hairline)' : 'none',
      }}>{following ? 'Following ✓' : 'Follow'}</button>
      <button style={{ flex: 1, padding: '10px 0', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink)', fontWeight: 600, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer' }}>Message</button>
    </div>
  );
}

// =========================================================================
// Variant A — Career stats + tabs
// =========================================================================

function ProfileA() {
  const [tab, setTab] = React.useState('Batting');
  const [following, setFollowing] = React.useState(false);

  const stats = {
    Batting: [
      { l: 'Matches', v: '142', s: '2019–present' },
      { l: 'Innings', v: '138', s: '6 not out' },
      { l: 'Runs', v: '4,217', s: 'career' },
      { l: 'Average', v: '36.4', s: 'hwm 41.0 · \'23' },
      { l: 'Strike rate', v: '138.6', s: 'last 12 months' },
      { l: 'Best', v: '112*', s: 'vs City Eagles' },
      { l: '50s / 100s', v: '22 / 4' },
      { l: 'Boundaries', v: '412', s: '328·4 / 84·6' },
    ],
    Bowling: [
      { l: 'Overs', v: '64.2' },
      { l: 'Wickets', v: '21' },
      { l: 'Economy', v: '8.4' },
      { l: 'Best', v: '3/14', s: 'vs Eagles' },
    ],
    Fielding: [
      { l: 'Catches', v: '38' },
      { l: 'Run-outs', v: '7' },
      { l: 'Stumpings', v: '0' },
      { l: 'Drops', v: '4', s: 'self-reported' },
    ],
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <ProfileHeader />
      <FollowRow following={following} setFollowing={setFollowing} />
      <div style={{ flex: 1, overflow: 'auto', padding: '0 20px 16px' }}>
        <div style={{ display: 'flex', gap: 10, marginBottom: 18, overflowX: 'auto' }}>
          {[
            { y: '24', t: 'Spring Cup', kind: 'POT' },
            { y: '23', t: 'Night League', kind: 'WIN' },
            { y: '23', t: '50+ Club', kind: '×7' },
            { y: '22', t: 'Mohalla T10', kind: 'WIN' },
          ].map((tr, i) => (
            <div key={i} style={{ flex: 'none', padding: '10px 12px', borderRadius: 10, background: i === 0 ? 'oklch(0.94 0.05 90)' : 'var(--paper-2)', border: '1px solid ' + (i === 0 ? 'oklch(0.86 0.05 90)' : 'var(--hairline)'), minWidth: 90 }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.06em' }}>'{tr.y} · {tr.kind}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600, marginTop: 4 }}>{tr.t}</div>
            </div>
          ))}
        </div>

        <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', marginBottom: 8 }}>
          {['Batting', 'Bowling', 'Fielding'].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: '10px 14px', fontSize: 13, fontWeight: 600,
              background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              color: tab === t ? 'var(--ink)' : 'var(--muted)',
              borderBottom: tab === t ? '2px solid var(--ink)' : '2px solid transparent',
              marginBottom: -1,
            }}>{t}</button>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', columnGap: 18 }}>
          {stats[tab].map((st, i) => (
            <div key={i} style={{ padding: '12px 0', borderTop: '1px solid var(--hairline)' }}>
              <div style={{ fontSize: 10, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>{st.l}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', marginTop: 2 }}>{st.v}</div>
              {st.s && <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>{st.s}</div>}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// =========================================================================
// Variant B — Recent form, expandable innings
// =========================================================================

function ProfileB() {
  const [following, setFollowing] = React.useState(false);
  const [expanded, setExpanded] = React.useState(0);

  const innings = [
    { score: '64 (38)', vs: 'Defenders XI', date: '2d', tag: 'POM', tone: 'green', balls: ['•','1','4','2','•','4','6','1','W'], bowler: 'Tariq Khan', dismissal: 'c Iqbal b Khan' },
    { score: '12 (14)', vs: 'Galle Boys', date: '5d', tag: '', tone: 'flat', balls: ['•','1','•','•','2','W'], bowler: 'Lasith S.', dismissal: 'lbw' },
    { score: '88 (52)', vs: 'Mohalla Kings', date: '8d', tag: '50', tone: 'green', balls: ['4','1','•','6','2','4','1'], bowler: 'Ali Raza', dismissal: 'not out' },
    { score: '0 (3)', vs: 'Royal Madras', date: '11d', tag: 'duck', tone: 'red', balls: ['•','•','W'], bowler: 'V. Krishna', dismissal: 'b Krishna' },
    { score: '47 (29)', vs: 'DHA United', date: '15d', tag: '', tone: 'flat', balls: ['1','4','2','6','•','1','4'], bowler: 'Faraz Ali', dismissal: 'run out' },
  ];

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <ProfileHeader />
      <FollowRow following={following} setFollowing={setFollowing} />
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr', gap: 14, alignItems: 'center', padding: 14, borderRadius: 14, background: 'var(--ink)', color: 'var(--paper)' }}>
          <div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'oklch(0.78 0.14 80)', letterSpacing: '0.1em' }}>FORM · LAST 5</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 38, fontWeight: 700, lineHeight: 1, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.03em', marginTop: 4 }}>42.2</div>
            <div style={{ fontSize: 11, color: 'oklch(0.72 0.01 80)', marginTop: 2 }}>average · sr 145</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 64 }}>
            {[64, 12, 88, 0, 47].map((r, i) => (
              <div key={i} onClick={() => setExpanded(i)} style={{
                flex: 1, height: Math.max(4, r * 0.7),
                background: r === 0 ? 'var(--red)' : (r >= 50 ? 'oklch(0.78 0.14 80)' : 'oklch(0.72 0.01 80)'),
                borderRadius: 3, cursor: 'pointer',
                outline: expanded === i ? '2px solid var(--paper)' : 'none', outlineOffset: 2,
              }} />
            ))}
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 20px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div className="ck-section-h" style={{ marginBottom: 4 }}>Last 5 innings · tap to expand</div>
        {innings.map((inn, i) => (
          <button key={i} onClick={() => setExpanded(expanded === i ? -1 : i)} style={{
            padding: 14, borderRadius: 12, border: '1px solid ' + (expanded === i ? 'var(--ink)' : 'var(--hairline)'),
            background: 'var(--paper)', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
          }}>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em', color: inn.tone === 'red' ? 'var(--red)' : 'var(--ink)' }}>{inn.score}</div>
                {inn.tag && <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.08em', padding: '3px 6px', borderRadius: 999, background: inn.tone === 'green' ? 'var(--green-soft)' : (inn.tone === 'red' ? 'var(--red-soft)' : 'var(--paper-2)'), color: inn.tone === 'green' ? 'oklch(0.36 0.10 148)' : (inn.tone === 'red' ? 'var(--red)' : 'var(--ink-2)') }}>{inn.tag.toUpperCase()}</span>}
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{inn.date} · vs {inn.vs}</div>
            </div>
            <div style={{ display: 'flex', gap: 4, marginTop: 10, flexWrap: 'wrap' }}>
              {inn.balls.map((b, j) => {
                const cls = b === '•' ? 'dot' : b === '4' ? 'four' : b === '6' ? 'six' : b === 'W' ? 'wkt' : '';
                return <span key={j} className={'ck-ball ' + cls} style={{ width: 24, height: 24, fontSize: 11 }}>{b}</span>;
              })}
            </div>
            {expanded === i && (
              <div style={{ marginTop: 10, paddingTop: 10, borderTop: '1px dashed var(--hairline)', fontSize: 12, color: 'var(--ink-2)', display: 'flex', justifyContent: 'space-between' }}>
                <div><span style={{ color: 'var(--muted)' }}>Out:</span> {inn.dismissal}</div>
                <div><span style={{ color: 'var(--muted)' }}>By:</span> {inn.bowler}</div>
              </div>
            )}
          </button>
        ))}
      </div>
    </div>
  );
}

// =========================================================================
// Variant C — Wagon wheel with filters
// =========================================================================

function ProfileC() {
  const [following, setFollowing] = React.useState(false);
  const [filter, setFilter] = React.useState('Wagon');
  const [shotIdx, setShotIdx] = React.useState(null);

  const allShots = [
    { a: 25, d: 0.85, r: 6 }, { a: 50, d: 0.72, r: 4 }, { a: 70, d: 0.6, r: 2 },
    { a: 95, d: 0.95, r: 6 }, { a: 110, d: 0.5, r: 1 }, { a: 130, d: 0.65, r: 4 },
    { a: 150, d: 0.4, r: 1 }, { a: 175, d: 0.78, r: 4 }, { a: 195, d: 0.55, r: 2 },
    { a: 220, d: 0.3, r: 1 }, { a: 240, d: 0.7, r: 4 }, { a: 265, d: 0.92, r: 6 },
    { a: 285, d: 0.55, r: 2 }, { a: 310, d: 0.68, r: 4 }, { a: 335, d: 0.45, r: 1 },
  ];
  const shots = filter === 'Wagon' ? allShots :
                filter === 'Pace' ? allShots.filter((_,i) => i % 2 === 0) :
                filter === 'Spin' ? allShots.filter((_,i) => i % 2 === 1) :
                allShots.filter(s => s.r >= 4);

  const cx = 130, cy = 130, R = 110;
  const colorFor = r => r === 6 ? 'var(--ink)' : r === 4 ? 'var(--green)' : r >= 2 ? 'oklch(0.55 0.08 80)' : 'var(--soft)';
  const totalRuns = shots.reduce((a, s) => a + s.r, 0);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <ProfileHeader />
      <FollowRow following={following} setFollowing={setFollowing} />
      <div style={{ flex: 1, overflow: 'auto', padding: '0 20px 16px' }}>
        <div style={{ display: 'flex', gap: 6, marginBottom: 14 }}>
          {['Wagon', 'Pace', 'Spin', 'Boundaries'].map(t => (
            <button key={t} onClick={() => setFilter(t)} style={{
              padding: '7px 12px', borderRadius: 999,
              background: filter === t ? 'var(--ink)' : 'var(--paper-2)',
              color: filter === t ? 'var(--paper)' : 'var(--ink-2)',
              fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
              border: '1px solid ' + (filter === t ? 'var(--ink)' : 'var(--hairline)'),
            }}>{t}</button>
          ))}
        </div>

        <div style={{ padding: 14, borderRadius: 16, background: 'oklch(0.985 0.008 85)', border: '1px solid var(--hairline)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div className="ck-section-h">Shot chart · {filter}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{totalRuns} runs · {shots.length} sc.</div>
          </div>
          <svg viewBox="0 0 260 260" style={{ width: '100%', height: 260, display: 'block', marginTop: 6 }}>
            <ellipse cx={cx} cy={cy} rx={R + 8} ry={R + 8} fill="oklch(0.965 0.012 85)" />
            <ellipse cx={cx} cy={cy} rx={R} ry={R} fill="none" stroke="var(--hairline)" strokeWidth="1" />
            <ellipse cx={cx} cy={cy} rx={R * 0.55} ry={R * 0.55} fill="none" stroke="var(--hairline)" strokeWidth="1" strokeDasharray="2 3" />
            <rect x={cx - 6} y={cy - 28} width="12" height="56" fill="oklch(0.94 0.03 85)" stroke="var(--hairline)" strokeWidth="0.5" />
            {shots.map((s, i) => {
              const rad = (s.a - 90) * Math.PI / 180;
              const x = cx + Math.cos(rad) * R * s.d;
              const y = cy + Math.sin(rad) * R * s.d;
              const active = shotIdx === i;
              return (
                <g key={i} onClick={() => setShotIdx(active ? null : i)} style={{ cursor: 'pointer' }}>
                  <line x1={cx} y1={cy} x2={x} y2={y} stroke={colorFor(s.r)} strokeWidth={active ? 2.4 : (s.r === 6 ? 1.6 : 1.2)} opacity={shotIdx == null || active ? 0.85 : 0.25} strokeLinecap="round"/>
                  <circle cx={x} cy={y} r={active ? 5 : (s.r === 6 ? 3 : 2.5)} fill={colorFor(s.r)} opacity={shotIdx == null || active ? 1 : 0.3}/>
                </g>
              );
            })}
            <circle cx={cx} cy={cy + 20} r="2.5" fill="var(--red)" />
          </svg>
          {shotIdx != null && (
            <div style={{ marginTop: 8, padding: 10, background: 'var(--paper)', borderRadius: 8, fontSize: 12, display: 'flex', justifyContent: 'space-between' }}>
              <span><strong>{shots[shotIdx].r} run{shots[shotIdx].r !== 1 ? 's' : ''}</strong> · {Math.round(shots[shotIdx].d * 65)}m</span>
              <span style={{ color: 'var(--muted)' }}>angle {shots[shotIdx].a}°</span>
            </div>
          )}
          <div style={{ display: 'flex', gap: 14, marginTop: 6, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 999, background: 'var(--ink)', marginRight: 4 }} /> 6</span>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 999, background: 'var(--green)', marginRight: 4 }} /> 4</span>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 999, background: 'oklch(0.55 0.08 80)', marginRight: 4 }} /> 2/3</span>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 999, background: 'var(--soft)', marginRight: 4 }} /> 1</span>
          </div>
        </div>
      </div>
    </div>
  );
}

window.CkProfileA = ProfileA;
window.CkProfileB = ProfileB;
window.CkProfileC = ProfileC;

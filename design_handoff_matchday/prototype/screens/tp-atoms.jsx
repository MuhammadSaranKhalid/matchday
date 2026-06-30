// tp-atoms.jsx — atoms for TeamPage

(function () {

const ink = 'var(--ink)', ink2 = 'var(--ink-2)', muted = 'var(--muted)';
const paper = 'var(--paper)', paper2 = 'var(--paper-2)', surf = 'var(--surface)';
const hair = 'var(--hairline)', line = 'var(--line)';
const red = 'var(--red)', redS = 'var(--red-soft)';
const green = 'var(--green)', greenS = 'var(--green-soft)';
const amber = 'var(--amber)', cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontWeight: 600, letterSpacing: '0.10em', textTransform: 'uppercase', fontSize: 10, color: muted };

function StatusBar() {
  return (
    <div style={{
      height: 44, padding: '0 24px', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      fontFamily: '-apple-system, system-ui',
      position: 'absolute', top: 0, left: 0, right: 0, zIndex: 4,
      color: '#fff',
    }}>
      <span style={{ fontWeight: 600, fontSize: 15 }}>9:41</span>
      <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
        <svg width="17" height="11" viewBox="0 0 17 11">
          <rect x="0"  y="6.5" width="2.8" height="4.5" rx="0.6" fill="currentColor"/>
          <rect x="4.5" y="4.5" width="2.8" height="6.5" rx="0.6" fill="currentColor"/>
          <rect x="9"   y="2.5" width="2.8" height="8.5" rx="0.6" fill="currentColor"/>
          <rect x="13.5" y="0"  width="2.8" height="11"  rx="0.6" fill="currentColor"/>
        </svg>
        <svg width="24" height="11" viewBox="0 0 24 11">
          <rect x="0.5" y="0.5" width="20" height="10" rx="3" stroke="currentColor" strokeOpacity="0.55" fill="none"/>
          <rect x="2" y="2" width="17" height="7" rx="1.5" fill="currentColor"/>
        </svg>
      </div>
    </div>
  );
}

function IconBtn({ children, onWhite, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: 36, height: 36, borderRadius: 999, flexShrink: 0,
      background: onWhite ? paper : 'rgba(255,255,255,0.16)',
      backdropFilter: onWhite ? 'none' : 'blur(10px)',
      border: onWhite ? '1px solid ' + hair : 'none',
      color: onWhite ? ink : '#fff', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</button>
  );
}

function VerifiedTick({ size = 10, color = '#fff' }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      width: size + 4, height: size + 4, borderRadius: 999, background: 'rgba(255,255,255,0.22)',
    }}>
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="20 6 9 17 4 12"/>
      </svg>
    </span>
  );
}

function LivePulse({ size = 5 }) {
  return <span style={{ width: size, height: size, borderRadius: 999, background: 'currentColor', animation: 'ck-pulse 1.4s infinite', flexShrink: 0 }} />;
}

function Sparkline({ values }) {
  if (!values || !values.length) return <span style={{ ...mono, fontSize: 9, color: muted }}>—</span>;
  const max = Math.max(...values, 1);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 2, height: 22 }}>
      {values.map((v, i) => (
        <div key={i} style={{
          width: 4, height: Math.max(2, (v / max) * 22),
          borderRadius: 1, background: v === 0 ? hair : ink,
        }} />
      ))}
    </div>
  );
}

function FollowerActions({ team, heroColor }) {
  const [following, setFollowing] = React.useState(true);
  const [notify, setNotify] = React.useState(false);
  const [joinState, setJoinState] = React.useState('idle'); // idle | requested
  const requested = joinState === 'requested';

  const toggle = {
    flex: 1, padding: '11px 0', borderRadius: 11, border: 'none',
    background: following ? '#fff' : 'rgba(255,255,255,0.16)', color: following ? heroColor : '#fff',
    fontFamily: 'Inter', fontWeight: 700, fontSize: 13, cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
  };
  const bell = {
    width: 42, flexShrink: 0, padding: '11px 0', borderRadius: 11,
    border: '1px solid rgba(255,255,255,0.42)',
    background: notify ? 'rgba(255,255,255,0.92)' : 'transparent', color: notify ? heroColor : '#fff',
    cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  };
  const join = {
    flex: 1, padding: '11px 0', borderRadius: 11,
    border: '1px solid rgba(255,255,255,0.42)',
    background: 'transparent', color: requested ? 'rgba(255,255,255,0.6)' : '#fff',
    fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: requested ? 'default' : 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
  };
  return (
    <div style={{ marginTop: 14, display: 'flex', gap: 8, position: 'relative', zIndex: 1 }}>
      <button style={toggle} onClick={() => setFollowing(v => !v)}>
        {following
          ? <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
          : <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>}
        {following ? 'Following' : 'Follow'}
      </button>
      <button style={bell} onClick={() => setNotify(v => !v)} aria-label="Notify">
        {notify
          ? <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0" stroke="currentColor" strokeWidth="2" fill="none"/></svg>
          : <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>}
      </button>
      <button style={join} onClick={() => { if (!requested) { setFollowing(true); setJoinState('requested'); } }}>
        {requested
          ? <><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9"/><polyline points="12 7 12 12 15 14"/></svg>Requested</>
          : <><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M12 5v14M5 12h14"/></svg>Request to join</>}
      </button>
    </div>
  );
}

function ActionRow({ viewer, team, heroColor, onAction }) {
  const fire = (act) => { if (onAction) onAction(act); };
  const wPrimary = {
    padding: '11px 0', borderRadius: 11, border: 'none',
    background: '#fff', color: heroColor,
    fontFamily: 'Inter', fontWeight: 700, fontSize: 13, cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
  };
  const wGhost = {
    padding: '11px 14px', borderRadius: 11,
    border: '1px solid rgba(255,255,255,0.42)', background: 'transparent', color: '#fff',
    fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
  };
  if (team.archived) {
    return (
      <div style={{ marginTop: 14, display: 'flex', gap: 8, position: 'relative', zIndex: 1 }}>
        <button style={{ ...wGhost, flex: 1 }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9"/><polyline points="12 7 12 12 15 14"/></svg>
          Read-only archive
        </button>
        <button style={wGhost}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13"/></svg>
        </button>
      </div>
    );
  }
  if (viewer === 'following') return <FollowerActions team={team} heroColor={heroColor} />;
  let actions;
  if (viewer === 'owner') actions = [
    { label: 'Post as team', primary: true, act: 'post', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M12 5v14M5 12h14"/></svg> },
    { label: 'Invite players', act: 'invite', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/></svg> },
  ];
  else if (viewer === 'captain') actions = [
    { label: 'Captain inbox', primary: true, act: 'inbox', badge: 3, icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M4 5h16v11H8l-4 4z"/></svg> },
    { label: 'Lineup', act: 'lineup', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16M4 12h16M4 18h10"/></svg> },
  ];
  else if (viewer === 'player') actions = [
    { label: 'Team chat', primary: true, act: 'chat', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M4 5h16v11H8l-4 4z"/></svg> },
    { label: 'My stats', act: 'stats', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 19V8M10 19V4M16 19V11M22 19H2"/></svg> },
  ];
  else if (viewer === 'stranger-private') actions = [
    { label: 'Request to join', primary: true, act: 'join', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M12 5v14M5 12h14"/></svg> },
  ];
  else actions = [
    { label: 'Follow', primary: true, act: 'follow', icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg> },
    { label: 'Request to join', act: 'join' },
  ];
  return (
    <div style={{ marginTop: 14, display: 'flex', gap: 8, position: 'relative', zIndex: 1 }}>
      {actions.map((a, i) => (
        <button key={i} onClick={() => fire(a.act)} style={a.primary ? { ...wPrimary, flex: 1 } : wGhost}>
          {a.icon}{a.label}
          {a.badge != null && a.badge > 0 && (
            <span style={{ minWidth: 18, height: 18, padding: '0 5px', borderRadius: 999, background: red, color: '#fff', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 10, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginLeft: 2 }}>{a.badge}</span>
          )}
        </button>
      ))}
    </div>
  );
}

function Hero({ team, viewer, badges, onBack, onAction }) {
  const dim = team.archived;
  const heroColor = dim ? 'oklch(0.36 0.02 80)' : team.primary;
  return (
    <div style={{
      padding: '60px 18px 22px', background: heroColor, color: '#fff',
      position: 'relative', overflow: 'hidden', flexShrink: 0,
      filter: dim ? 'saturate(0.4)' : 'none',
    }}>
      <StatusBar />
      <svg width="320" height="200" viewBox="0 0 200 130" style={{ position: 'absolute', right: -30, top: -10, opacity: 0.10 }}>
        <ellipse cx="100" cy="65" rx="95" ry="55" stroke="#fff" strokeWidth="0.4" fill="none"/>
        <ellipse cx="100" cy="65" rx="55" ry="32" stroke="#fff" strokeWidth="0.4" fill="none"/>
        <rect x="92" y="35" width="16" height="60" stroke="#fff" strokeWidth="0.4" fill="none"/>
      </svg>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative', zIndex: 2, marginBottom: 20 }}>
        <IconBtn onClick={onBack}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
        </IconBtn>
        <div style={{ display: 'flex', gap: 6 }}>
          <IconBtn><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13"/></svg></IconBtn>
          <IconBtn><svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg></IconBtn>
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14, position: 'relative', zIndex: 1 }}>
        <div style={{
          width: 72, height: 72, borderRadius: 18, flexShrink: 0,
          background: 'rgba(255,255,255,0.95)', color: heroColor,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 30, letterSpacing: '-0.04em',
          boxShadow: '0 4px 16px rgba(0,0,0,0.18)',
        }}>{team.mono}</div>
        <div style={{ flex: 1, minWidth: 0, paddingBottom: 4 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontFamily: 'JetBrains Mono', fontSize: 10, opacity: 0.82, letterSpacing: '0.10em' }}>
            <span>{team.type.toUpperCase()}</span><span>·</span>
            <span>{team.area.toUpperCase()}, {team.city.toUpperCase()}</span>
            {team.verified && !dim && <VerifiedTick size={10} />}
          </div>
          <h1 style={{ fontFamily: 'Inter Tight', fontSize: 28, fontWeight: 700, letterSpacing: '-0.025em', margin: '6px 0 0', lineHeight: 1, color: '#fff' }}>{team.name}</h1>
          {team.tagline && !dim && (
            <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontStyle: 'italic', opacity: 0.85, marginTop: 6, letterSpacing: '-0.01em' }}>
              “{team.tagline}”
            </div>
          )}
        </div>
      </div>
      {badges && badges.length > 0 && (
        <div style={{ marginTop: 14, display: 'flex', gap: 6, flexWrap: 'wrap', position: 'relative', zIndex: 1 }}>
          {badges.map((b, i) => (
            <span key={i} style={{
              ...mono, fontSize: 9, fontWeight: 700, color: '#fff',
              background: b.tone === 'red' ? red : 'rgba(255,255,255,0.18)',
              padding: '4px 8px', borderRadius: 6,
              display: 'inline-flex', alignItems: 'center', gap: 5,
            }}>
              {b.pulse && <LivePulse size={5} />}{b.label}
            </span>
          ))}
        </div>
      )}
      {team.record && (
        <div style={{ marginTop: 18, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', background: 'rgba(0,0,0,0.22)', borderRadius: 12, position: 'relative', zIndex: 1 }}>
          {[
            { l: 'PLAYED', v: team.record.p },
            { l: 'WON',    v: team.record.w },
            { l: 'LOST',   v: team.record.l },
            { l: 'WIN %',  v: Math.round((team.record.w / team.record.p) * 100) },
          ].map((s, i) => (
            <div key={i} style={{ padding: '10px 12px', borderLeft: i ? '1px solid rgba(255,255,255,0.14)' : 'none' }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>{s.v}</div>
              <div style={{ ...mono, fontSize: 9, color: 'rgba(255,255,255,0.72)', marginTop: 3 }}>{s.l}</div>
            </div>
          ))}
        </div>
      )}
      <ActionRow viewer={viewer} team={team} heroColor={heroColor} onAction={onAction} />
    </div>
  );
}

function Tabs({ active, setActive, items }) {
  return (
    <div style={{
      display: 'flex', borderBottom: '1px solid ' + hair, background: paper,
      position: 'sticky', top: 0, zIndex: 5, flexShrink: 0, overflowX: 'auto',
    }}>
      {items.map(t => {
        const isActive = active === t.id;
        return (
          <button key={t.id} onClick={() => setActive(t.id)} style={{
            flex: 1, minWidth: 80, padding: '12px 4px',
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
            color: isActive ? ink : muted,
            borderBottom: isActive ? '2px solid ' + ink : '2px solid transparent',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 5,
          }}>
            {t.label}
            {t.badge != null && t.badge > 0 && (
              <span style={{ ...mono, fontSize: 9, fontWeight: 700, padding: '1px 5px', borderRadius: 999, background: isActive ? ink : cream, color: isActive ? paper : ink2 }}>{t.badge}</span>
            )}
          </button>
        );
      })}
    </div>
  );
}

function LiveBanner({ data }) {
  return (
    <div style={{
      margin: '0 14px', marginTop: -12, padding: '12px 14px', borderRadius: 14,
      background: ink, color: paper, position: 'relative', zIndex: 3, overflow: 'hidden',
      boxShadow: '0 6px 18px rgba(20,18,14,0.18)',
    }}>
      <svg width="180" height="120" viewBox="0 0 200 130" style={{ position: 'absolute', right: -30, top: -15, opacity: 0.10 }}>
        <ellipse cx="100" cy="65" rx="92" ry="55" stroke="#fff" strokeWidth="0.4" fill="none"/>
      </svg>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <span style={{ ...mono, fontSize: 9, color: '#fff', background: red, padding: '2px 6px', borderRadius: 4, display: 'inline-flex', alignItems: 'center', gap: 5, fontWeight: 700 }}>
          <LivePulse size={5} />LIVE NOW
        </span>
        <span style={{ ...mono, fontSize: 9, color: 'rgba(255,255,255,0.65)' }}>{data.ctx}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.02em' }}>{data.us}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 15, fontWeight: 700, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>{data.usScore}</div>
        </div>
        <span style={{ ...mono, fontSize: 9, color: 'rgba(255,255,255,0.55)' }}>VS</span>
        <div style={{ flex: 1, textAlign: 'right' }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.02em' }}>{data.them}</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 15, fontWeight: 700, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>{data.themScore || '—'}</div>
        </div>
      </div>
      <div style={{ marginTop: 10, paddingTop: 10, borderTop: '1px solid rgba(255,255,255,0.12)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.78)' }}>{data.note}</span>
        <button style={{ ...mono, fontSize: 9, padding: '5px 9px', borderRadius: 999, border: '1px solid rgba(255,255,255,0.35)', background: 'transparent', color: '#fff', cursor: 'pointer', fontWeight: 700 }}>WATCH LIVE</button>
      </div>
    </div>
  );
}

function InfoBanner({ tone = 'green', icon, title, body, cta }) {
  const tones = {
    green: { bg: greenS, border: 'oklch(0.82 0.08 148)', accent: 'oklch(0.30 0.13 148)', cta: green },
    amber: { bg: cream, border: 'oklch(0.85 0.10 80)', accent: 'oklch(0.32 0.10 80)', cta: amber },
    red:   { bg: redS, border: 'oklch(0.82 0.10 28)', accent: 'oklch(0.36 0.16 28)', cta: red },
    gray:  { bg: paper2, border: hair, accent: ink, cta: ink },
  };
  const t = tones[tone];
  return (
    <div style={{
      margin: '12px 14px 0', padding: '12px 14px', borderRadius: 12,
      background: t.bg, border: '1px solid ' + t.border,
      display: 'flex', alignItems: 'flex-start', gap: 10,
    }}>
      <div style={{
        width: 26, height: 26, borderRadius: 999, flexShrink: 0,
        background: t.cta, color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: 1,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 700, color: t.accent, letterSpacing: '-0.01em' }}>{title}</div>
        <div style={{ fontSize: 12, color: t.accent, marginTop: 2, lineHeight: 1.4, opacity: 0.85 }}>{body}</div>
      </div>
      {cta && (
        <button style={{ padding: '6px 10px', borderRadius: 7, border: 'none', background: t.cta, color: '#fff', fontFamily: 'Inter', fontSize: 11, fontWeight: 700, cursor: 'pointer', flexShrink: 0 }}>{cta}</button>
      )}
    </div>
  );
}

function PlayerRow({ p, primary, top, viewerIs }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: top ? 'none' : '1px solid ' + hair }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, position: 'relative', flexShrink: 0,
        background: p.status === 'unclaimed' ? 'transparent' : primary,
        color: p.status === 'unclaimed' ? muted : '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 14, letterSpacing: '-0.02em',
        border: p.status === 'unclaimed' ? '1px dashed ' + line : 'none',
      }}>
        #{p.jersey}
        {p.status === 'sms' && <div style={{ position: 'absolute', top: -3, right: -3, width: 10, height: 10, borderRadius: 999, background: amber, border: '2px solid ' + paper }}/>}
        {viewerIs === p.id && (
          <div style={{ position: 'absolute', top: -5, right: -5, width: 14, height: 14, borderRadius: 999, background: ink, color: paper, display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid ' + paper }}>
            <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.4"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600, color: ink }}>{p.n}</span>
          {p.role !== 'Player' && (
            <span style={{ ...mono, fontSize: 8.5, padding: '1px 5px', borderRadius: 3, background: cream, color: ink2, fontWeight: 700, letterSpacing: '0.06em' }}>
              {p.role === 'Wicket-Keeper' ? 'WK' : p.role === 'Vice-Captain' ? 'VC' : 'C'}
            </span>
          )}
          {viewerIs === p.id && (
            <span style={{ ...mono, fontSize: 8.5, padding: '1px 5px', borderRadius: 3, background: ink, color: paper, fontWeight: 700, letterSpacing: '0.06em' }}>YOU</span>
          )}
          {p.status === 'unclaimed' && (
            <span style={{ ...mono, fontSize: 8.5, padding: '1px 5px', borderRadius: 3, background: paper2, color: muted, fontWeight: 700, letterSpacing: '0.06em', border: '1px solid ' + hair }}>UNCLAIMED</span>
          )}
        </div>
        <div style={{ fontSize: 11, color: muted, marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>
          {p.bat}{p.bowl !== '—' ? ' · ' + p.bowl : ''}
        </div>
      </div>
      <Sparkline values={p.last5} />
    </div>
  );
}

Object.assign(window, { tpMono: mono, tpHero: Hero, tpTabs: Tabs, tpLiveBanner: LiveBanner, tpInfoBanner: InfoBanner, tpPlayerRow: PlayerRow, tpSparkline: Sparkline });

})();

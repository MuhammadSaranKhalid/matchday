// AppShell.jsx — Unified router + tab bar that ties all 17 screens together.
// Exposes window.CkAppShell.
//
// Architecture:
//   - Root holds: { tab, stack: [{screen, props}, ...], launch: bool }
//   - 5 tabs: feed, discover, create, notif, profile
//   - Push/pop stack overlays current tab
//   - Provides `nav` context to every screen via window.__ckNav (read-only API)
//
// Existing screens don't need rewriting; they call window.__ckNav.push('match')
// where they want navigation. Screens that don't call nav still work as terminals.

const SCREENS = {
  // tabs
  feed:        { Comp: () => window.CkFeed && <window.CkFeed />,         tab: true,  title: 'Feed' },
  discover:    { Comp: () => window.CkDiscoverA && <window.CkDiscoverA />, tab: true, title: 'Discover' },
  search:      { Comp: () => window.CkDiscoverB && <window.CkDiscoverB /> },
  createTab:   { Comp: () => null, tab: true, title: 'Create' }, // sheet, handled inline
  notif:       { Comp: () => window.CkNotifications && <window.CkNotifications />, tab: true, title: 'Inbox' },
  profile:     { Comp: () => window.CkProfileA && <window.CkProfileA />, tab: true, title: 'You' },
  profileForm: { Comp: () => window.CkProfileB && <window.CkProfileB /> },
  profileShot: { Comp: () => window.CkProfileC && <window.CkProfileC /> },

  // pushable
  match:       { Comp: () => window.CkLiveMatch && <window.CkLiveMatch /> },
  tournament:  { Comp: () => window.CkTournament && <window.CkTournament /> },
  setup:       { Comp: () => window.CkSetupA && <window.CkSetupA /> },
  setupXI:     { Comp: () => window.CkSetupB && <window.CkSetupB /> },
  setupCond:   { Comp: () => window.CkSetupC && <window.CkSetupC /> },
  scoring:     { Comp: () => window.CkScoring && <window.CkScoring /> },
  scorecard:   { Comp: () => window.CkScorecard && <window.CkScorecard /> },
  result:      { Comp: () => window.CkResult && <window.CkResult /> },
  team:        { Comp: () => window.CkTeamA && <window.CkTeamA /> },
  teamClaim:   { Comp: () => window.CkTeamB && <window.CkTeamB /> },
  teamMgr:     { Comp: () => window.CkTeamC && <window.CkTeamC /> },
  manage:      { Comp: () => window.CkTournamentManage && <window.CkTournamentManage /> },
  rankings:    { Comp: () => window.CkRankings && <window.CkRankings /> },
  settings:    { Comp: () => window.CkSettings && <window.CkSettings /> },
  create:      { Comp: () => window.CkCreate && <window.CkCreate /> },
  onboarding:  { Comp: () => window.CkOnboarding && <window.CkOnboarding /> },
  suggest:     { Comp: () => window.CkSuggestFollows && <window.CkSuggestFollows /> },
};

function CkAppShell() {
  const [tab, setTab] = React.useState('feed');
  const [stack, setStack] = React.useState([]); // array of screen keys
  const [launch, setLaunch] = React.useState(null); // 'onboarding' | 'suggest' | null
  const [createSheet, setCreateSheet] = React.useState(false);
  const [transitionDir, setTransitionDir] = React.useState('push'); // 'push' | 'pop' | 'none'

  // Expose nav API
  React.useEffect(() => {
    window.__ckNav = {
      push: (screen) => {
        setTransitionDir('push');
        setStack(s => [...s, screen]);
      },
      pop: () => {
        setTransitionDir('pop');
        setStack(s => s.slice(0, -1));
      },
      popToRoot: () => {
        setTransitionDir('pop');
        setStack([]);
      },
      switchTab: (t) => {
        setTransitionDir('none');
        setStack([]);
        setTab(t);
      },
      restartLaunch: () => setLaunch('onboarding'),
    };
  }, []);

  // Launch flow
  if (launch === 'onboarding') {
    return (
      <LaunchHost onDone={() => setLaunch('suggest')}>
        <window.CkOnboarding />
      </LaunchHost>
    );
  }
  if (launch === 'suggest') {
    return (
      <LaunchHost onDone={() => setLaunch(null)}>
        <window.CkSuggestFollows />
      </LaunchHost>
    );
  }

  const top = stack.length > 0 ? stack[stack.length - 1] : null;
  const TabComp = SCREENS[tab].Comp;
  const TopComp = top ? SCREENS[top].Comp : null;

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden', background: 'var(--paper)' }}>
      {/* Tab content (always rendered as base) */}
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column' }}>
        <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
          <div key={tab} style={{ position: 'absolute', inset: 0, animation: stack.length === 0 ? 'ck-fade .18s ease' : 'none' }}>
            {TabComp && <TabComp />}
          </div>
        </div>
        {!top && <TabBar tab={tab} setTab={(t) => {
          if (t === 'createTab') { setCreateSheet(true); return; }
          setTransitionDir('none');
          setTab(t);
        }} />}
      </div>

      {/* Stack overlay */}
      {top && (
        <div
          key={stack.length + ':' + top}
          style={{
            position: 'absolute', inset: 0, background: 'var(--paper)',
            animation: transitionDir === 'push' ? 'ck-slide-in .26s cubic-bezier(.2,.8,.2,1)' :
                       transitionDir === 'pop' ? 'ck-slide-out .22s cubic-bezier(.2,.8,.2,1) reverse' : 'none',
            boxShadow: '-2px 0 20px rgba(20,15,10,0.06)',
          }}
        >
          {TopComp && <TopComp />}
        </div>
      )}

      {/* Create sheet */}
      {createSheet && (
        <CreateSheet
          onClose={() => setCreateSheet(false)}
          onPick={(key) => {
            setCreateSheet(false);
            setTransitionDir('push');
            setStack(s => [...s, key]);
          }}
        />
      )}

      <style>{`
        @keyframes ck-slide-in {
          from { transform: translateX(100%); }
          to { transform: translateX(0); }
        }
        @keyframes ck-slide-out {
          from { transform: translateX(0); }
          to { transform: translateX(100%); }
        }
        @keyframes ck-fade {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      `}</style>
    </div>
  );
}

// ─────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────
function TabBar({ tab, setTab }) {
  const items = [
    { id: 'feed',     label: 'Feed',     icon: 'home' },
    { id: 'discover', label: 'Discover', icon: 'search' },
    { id: 'createTab', label: 'Create',  icon: 'plus', primary: true },
    { id: 'notif',    label: 'Inbox',    icon: 'bell' },
    { id: 'profile',  label: 'You',      icon: 'user' },
  ];
  return (
    <div style={{
      borderTop: '1px solid var(--hairline)',
      background: 'var(--paper)',
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      padding: '8px 8px 18px',
      flexShrink: 0,
    }}>
      {items.map(it => {
        const active = tab === it.id;
        if (it.primary) {
          return (
            <button key={it.id} onClick={() => setTab(it.id)} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              background: 'transparent', border: 'none', cursor: 'pointer', padding: 4,
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 12,
                background: 'var(--ink)', color: 'var(--paper)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 2px 6px rgba(40,30,15,0.18)',
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
              </div>
            </button>
          );
        }
        return (
          <button key={it.id} onClick={() => setTab(it.id)} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            background: 'transparent', border: 'none', cursor: 'pointer',
            padding: '6px 10px', minWidth: 56,
          }}>
            <TabIcon icon={it.icon} active={active} />
            <span style={{
              fontSize: 10, fontWeight: 600,
              color: active ? 'var(--ink)' : 'var(--muted)',
              fontFamily: 'inherit',
              fontFeatureSettings: '"ss01"',
            }}>{it.label}</span>
          </button>
        );
      })}
    </div>
  );
}

function TabIcon({ icon, active }) {
  const c = active ? 'var(--ink)' : 'var(--muted)';
  const w = active ? 2.2 : 1.8;
  switch (icon) {
    case 'home':
      return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth={w}><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2h-4v-7H9v7H5a2 2 0 0 1-2-2Z"/></svg>;
    case 'search':
      return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth={w}><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>;
    case 'bell':
      return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth={w}><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>;
    case 'user':
      return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth={w}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>;
    default: return null;
  }
}

// ─────────────────────────────────────────────
// Create sheet — picker for what to create
// ─────────────────────────────────────────────
function CreateSheet({ onClose, onPick }) {
  const items = [
    { key: 'setup',     label: 'New match',           sub: 'Toss → squads → start scoring', icon: 'play' },
    { key: 'create',    label: 'New tournament',      sub: 'Schedule, brackets, invites',   icon: 'trophy' },
    { key: 'scorecard', label: 'Add past scorecard',  sub: 'Match played but not scored',   icon: 'edit' },
  ];
  return (
    <div onClick={onClose} style={{
      position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.5)', zIndex: 50,
      display: 'flex', alignItems: 'flex-end',
      animation: 'ck-fade .15s ease',
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: '100%', background: 'var(--paper)',
        borderTopLeftRadius: 22, borderTopRightRadius: 22,
        padding: '14px 16px 28px',
        animation: 'ck-sheet-up .25s cubic-bezier(.2,.8,.2,1)',
      }}>
        <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 16px' }} />
        <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', padding: '0 4px 12px' }}>
          What are you starting?
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {items.map(it => (
            <button key={it.key} onClick={() => onPick(it.key)} style={{
              display: 'flex', alignItems: 'center', gap: 14, padding: 14,
              borderRadius: 14, border: '1px solid var(--hairline)',
              background: 'var(--paper)', cursor: 'pointer',
              fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 12,
                background: 'var(--paper-2)', display: 'flex',
                alignItems: 'center', justifyContent: 'center',
              }}>
                <CreateIcon icon={it.icon} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700 }}>{it.label}</div>
                <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{it.sub}</div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2.2"><path d="m9 18 6-6-6-6"/></svg>
            </button>
          ))}
        </div>
        <button onClick={onClose} style={{
          width: '100%', marginTop: 14, padding: '12px 0',
          background: 'transparent', border: 'none', color: 'var(--muted)',
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600, cursor: 'pointer',
        }}>Cancel</button>
      </div>
      <style>{`
        @keyframes ck-sheet-up { from { transform: translateY(100%); } to { transform: translateY(0); } }
      `}</style>
    </div>
  );
}

function CreateIcon({ icon }) {
  const c = 'var(--ink)';
  switch (icon) {
    case 'play':   return <svg width="20" height="20" viewBox="0 0 24 24" fill={c}><path d="M8 5v14l11-7z"/></svg>;
    case 'trophy': return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2"><path d="M6 9V5h12v4a6 6 0 0 1-12 0Z"/><path d="M6 5H3v2a3 3 0 0 0 3 3M18 5h3v2a3 3 0 0 1-3 3"/><path d="M9 19h6M12 15v4"/></svg>;
    case 'edit':   return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2"><path d="M4 20h4l11-11-4-4L4 16Z"/><path d="m13.5 6.5 4 4"/></svg>;
    default: return null;
  }
}

// ─────────────────────────────────────────────
// Launch host — wraps onboarding/suggest with a "skip to app" affordance
// ─────────────────────────────────────────────
function LaunchHost({ children, onDone }) {
  return (
    <div style={{ width: '100%', height: '100%', position: 'relative' }}>
      {children}
      <button onClick={onDone} style={{
        position: 'absolute', top: 14, right: 16, zIndex: 100,
        padding: '6px 12px', borderRadius: 999,
        background: 'rgba(255,255,255,0.85)', border: '1px solid var(--hairline)',
        backdropFilter: 'blur(8px)',
        fontFamily: 'inherit', fontSize: 11, fontWeight: 600, color: 'var(--ink-2)',
        cursor: 'pointer', letterSpacing: '0.04em',
      }}>SKIP TO APP →</button>
    </div>
  );
}

window.CkAppShell = CkAppShell;

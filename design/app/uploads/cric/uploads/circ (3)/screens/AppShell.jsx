// AppShell.jsx — shared chrome for the four bottom-nav screens.
// Provides:
//   <CkAppShell tab onTab title livePulse>{children}</CkAppShell>
//   <CkBottomNav tab onTab>           — bottom tab bar
//   <CkTopBar title livePulse onAvatar onBell unread> — top status / title row + bell + avatar
// Style: paper background, hairline top border, square solid icon for active, simple line icons for inactive.
// Center "+" Create tab is treated as a square accent button.
//
// Used by Home, Discover, Create, Live (and any other screen that wants the chrome).

const NAV_TABS = ['Home', 'Discover', 'Create', 'Live'];

function CkAppShell({ tab, onTab, title, livePulse, unread = 3, children, onAvatar, onBell, hideTopBar }) {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* iOS status bar spacer */}
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar */}
      {!hideTopBar && (
        <CkTopBar title={title} livePulse={livePulse} unread={unread} onAvatar={onAvatar} onBell={onBell} />
      )}

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto', position: 'relative' }}>
        {children}
      </div>

      {/* Bottom nav */}
      <CkBottomNav tab={tab} onTab={onTab} />
    </div>
  );
}

function CkTopBar({ title, livePulse, unread = 0, onAvatar, onBell, dense }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: dense ? '6px 16px 4px' : '10px 16px 8px',
      flexShrink: 0,
    }}>
      {/* Left: brand or title */}
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, minWidth: 0 }}>
        {title === 'circk' || !title ? (
          <span className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.045em', lineHeight: 1 }}>
            circk<span style={{ color: 'var(--red)' }}>.</span>
          </span>
        ) : (
          <span className="ck-display" style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1 }}>{title}</span>
        )}
        {livePulse && (
          <span className="ck-chip live" style={{ padding: '3px 7px', fontSize: 9 }}>LIVE</span>
        )}
      </div>

      {/* Right cluster: bell + avatar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <button onClick={onBell} aria-label="Notifications" style={{
          background: 'transparent', border: 'none', padding: 8, cursor: 'pointer', position: 'relative',
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/>
            <path d="M10.3 21a2 2 0 0 0 3.4 0"/>
          </svg>
          {unread > 0 && (
            <span style={{
              position: 'absolute', top: 5, right: 5,
              width: 8, height: 8, borderRadius: 999,
              background: 'var(--red)', border: '1.5px solid var(--paper)',
            }}/>
          )}
        </button>
        <button onClick={onAvatar} aria-label="My profile" style={{
          background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
          marginLeft: 2,
        }}>
          <div className="ck-avatar" style={{
            width: 30, height: 30, fontSize: 11,
            background: 'var(--ink)', color: 'var(--paper)', borderColor: 'transparent',
          }}>BA</div>
        </button>
      </div>
    </div>
  );
}

function CkBottomNav({ tab, onTab }) {
  return (
    <div style={{
      flexShrink: 0,
      borderTop: '1px solid var(--hairline)',
      background: 'var(--paper)',
      paddingBottom: 'env(safe-area-inset-bottom)',
    }}>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
        height: 56, alignItems: 'center',
      }}>
        {NAV_TABS.map(t => (
          <NavItem key={t} label={t} active={tab === t} onClick={() => onTab && onTab(t)} />
        ))}
      </div>
      {/* iOS home indicator */}
      <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0 6px' }}>
        <div style={{ width: 134, height: 4, borderRadius: 999, background: 'var(--ink)', opacity: 0.5 }}/>
      </div>
    </div>
  );
}

function NavItem({ label, active, onClick }) {
  const isCreate = label === 'Create';

  // Create gets a different treatment — accent square always
  if (isCreate) {
    return (
      <button onClick={onClick} aria-label={label} style={{
        background: 'transparent', border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%',
      }}>
        <div style={{
          width: 38, height: 38, borderRadius: 12,
          background: active ? 'var(--ink)' : 'var(--ink)',
          color: 'var(--paper)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: active ? '0 4px 14px rgba(40,30,15,0.20)' : '0 2px 6px rgba(40,30,15,0.12)',
          transition: 'transform .12s ease',
          transform: active ? 'scale(1.06)' : 'scale(1)',
        }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
            <path d="M12 5v14M5 12h14"/>
          </svg>
        </div>
      </button>
    );
  }

  return (
    <button onClick={onClick} aria-label={label} style={{
      background: 'transparent', border: 'none', cursor: 'pointer',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 3, padding: 0, height: '100%',
    }}>
      {active ? (
        <div style={{
          width: 28, height: 28, borderRadius: 8,
          background: 'var(--ink)', color: 'var(--paper)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <NavIcon name={label} filled />
        </div>
      ) : (
        <div style={{ width: 28, height: 28, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted)' }}>
          <NavIcon name={label} />
        </div>
      )}
      {active && (
        <span style={{
          fontFamily: 'JetBrains Mono', fontSize: 8.5, fontWeight: 700,
          color: 'var(--ink)', letterSpacing: '0.10em',
        }}>{label.toUpperCase()}</span>
      )}
    </button>
  );
}

function NavIcon({ name, filled }) {
  const stroke = filled ? 'currentColor' : 'currentColor';
  const sw = filled ? 2 : 1.8;
  if (name === 'Home') {
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 11l9-7 9 7v9a2 2 0 0 1-2 2h-4v-7h-6v7H5a2 2 0 0 1-2-2z"/>
      </svg>
    );
  }
  if (name === 'Discover') {
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
        <circle cx="11" cy="11" r="7"/>
        <path d="M20 20l-4-4"/>
      </svg>
    );
  }
  if (name === 'Live') {
    // pitch ball (red dot if active)
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="9"/>
        <path d="M3 12h18M12 3v18"/>
      </svg>
    );
  }
  return null;
}

window.CkAppShell = CkAppShell;
window.CkBottomNav = CkBottomNav;
window.CkTopBar = CkTopBar;
window.NAV_TABS = NAV_TABS;

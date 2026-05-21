// TeamManage.jsx — Team manager view
// Tabs: Roster · Requests · Members · Settings
// Lifts the visual language from TournamentManage.jsx — same hero pattern, sticky tabs, action queue.

function CkTeamManage({ justCreated = false, team: teamOverride, initialTab = 'Roster' } = {}) {
  const [tab, setTab] = React.useState(initialTab);
  const [bannerOpen, setBannerOpen] = React.useState(justCreated);

  const team = teamOverride || {
    id: 'LL',
    name: 'Lahore Lions',
    primary: TEAMS.LL.bg,
    monogram: TEAMS.LL.mono,
    type: 'Club',
    city: 'Lahore',
    area: 'Model Town',
  };

  // When the team was just created, start with an empty squad and no inbound requests.
  const [squad, setSquad] = React.useState(justCreated ? [
    { id: 'p1', n: 'You · owner', role: 'Captain', jersey: 1, status: 'active', kind: 'app', since: 'just now' },
  ] : [
    { id: 'p1', n: 'Bilal Ahmed',   role: 'Captain',       jersey: 7,  status: 'active', kind: 'app',       since: 'Jan 2024' },
    { id: 'p2', n: 'Adeel Sheikh',  role: 'Wicket-Keeper', jersey: 11, status: 'active', kind: 'app',       since: 'Jan 2024' },
    { id: 'p3', n: 'Faraz Khan',    role: 'Vice-Captain',  jersey: 33, status: 'active', kind: 'app',       since: 'Mar 2024' },
    { id: 'p4', n: 'Hamza Tariq',   role: 'Player',        jersey: 18, status: 'active', kind: 'app',       since: 'Mar 2024' },
    { id: 'p5', n: 'Salman Raza',   role: 'Player',        jersey: 4,  status: 'active', kind: 'app',       since: 'Apr 2024' },
    { id: 'p6', n: 'Tariq Hussain', role: 'Player',        jersey: 9,  status: 'pending-sms', kind: 'sms',  since: 'invited 3d' },
    { id: 'p7', n: 'Ahmed Khan',    role: 'Player',        jersey: 23, status: 'unclaimed', kind: 'unclaimed', since: 'placeholder · 18 stats' },
    { id: 'p8', n: 'Imran Iqbal',   role: 'Player',        jersey: 14, status: 'active', kind: 'app',       since: 'May 2024' },
    { id: 'p9', n: 'Asad Mehmood',  role: 'Player',        jersey: 21, status: 'active', kind: 'app',       since: 'Jul 2024' },
    { id: 'p10', n: 'Saad Mahmood', role: 'Player',        jersey: 8,  status: 'inactive', kind: 'app',     since: 'left Feb 2025' },
  ]);

  // Pending claim/join requests ─ used by Requests tab
  const [requests, setRequests] = React.useState(justCreated ? [] : [
    { id: 'r1', kind: 'claim', who: 'Saif Khan',     about: 'Wants to claim "Ahmed Khan" placeholder', proof: '+92 300 ··· · 1 mutual team', when: '2h' },
    { id: 'r2', kind: 'join',  who: 'Usman Bhatti',  about: 'Requested to join · all-rounder',         proof: 'Saw your post · @usman.b', when: '5h' },
    { id: 'r3', kind: 'invite-pending', who: 'Tariq Hussain', about: 'SMS invite · awaiting accept',  proof: '+92 311 ··· · sent 3d ago', when: '3d' },
  ]);

  const setReq = (id, action) => setRequests(prev => prev.filter(r => r.id !== id));

  const counts = {
    pending: requests.filter(r => r.kind !== 'invite-pending').length,
    invitesOut: requests.filter(r => r.kind === 'invite-pending').length,
    active: squad.filter(p => p.status === 'active').length,
    unclaimed: squad.filter(p => p.status === 'unclaimed').length,
  };

  const Tab = ({ id, badge }) => (
    <button onClick={() => setTab(id)} style={{
      flex: 'none', padding: '12px 14px', position: 'relative',
      background: 'transparent', border: 'none', cursor: 'pointer',
      fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
      color: tab === id ? 'var(--ink)' : 'var(--muted)',
      borderBottom: tab === id ? '2px solid var(--ink)' : '2px solid transparent',
      display: 'inline-flex', alignItems: 'center', gap: 6,
    }}>
      {id}
      {badge > 0 && (
        <span style={{
          fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700,
          padding: '1px 6px', borderRadius: 999,
          background: tab === id ? 'var(--ink)' : 'var(--cream)',
          color: tab === id ? 'var(--paper)' : 'var(--ink-2)',
        }}>{badge}</span>
      )}
    </button>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 18px 6px', flexShrink: 0 }}>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="var(--ink)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>MANAGER</span>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>
        </button>
      </div>

      {/* Just-created banner ─ dismissible */}
      {bannerOpen && (
        <div style={{
          margin: '4px 14px 0', padding: '10px 12px',
          background: 'var(--green-soft)',
          border: '1px solid oklch(0.82 0.08 148)',
          borderRadius: 10,
          display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0,
        }}>
          <div style={{
            width: 26, height: 26, borderRadius: 999,
            background: 'var(--green)', color: 'white',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <div style={{ flex: 1, minWidth: 0, fontSize: 12, color: 'oklch(0.32 0.13 148)', lineHeight: 1.4 }}>
            <b>{team.name} is live.</b> Add your squad to get started.
          </div>
          <button
            onClick={() => { setTab('Roster'); setBannerOpen(false); }}
            style={{
              padding: '6px 10px', borderRadius: 7,
              border: 'none', background: 'var(--green)', color: 'white',
              fontFamily: 'Inter', fontSize: 11, fontWeight: 700, cursor: 'pointer',
              flexShrink: 0,
            }}
          >Add players</button>
          <button
            onClick={() => setBannerOpen(false)}
            aria-label="Dismiss"
            style={{
              padding: 4, borderRadius: 6,
              border: 'none', background: 'transparent',
              color: 'oklch(0.32 0.13 148)', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              opacity: 0.6, flexShrink: 0,
            }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
          </button>
        </div>
      )}

      {/* Compact hero — team identity + at-a-glance counts */}
      <div style={{ padding: '4px 18px 14px', flexShrink: 0, display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 56, height: 56, borderRadius: 14, background: team.primary,
          color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 22, letterSpacing: '-0.03em',
          flexShrink: 0,
        }}>{team.monogram}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 2 }}>
            <span>{team.type.toUpperCase()}</span>
            <span>·</span>
            <span>{team.area.toUpperCase()}</span>
          </div>
          <h1 className="ck-display" style={{ fontSize: 22, fontWeight: 700, margin: 0, letterSpacing: '-0.025em', lineHeight: 1 }}>
            {team.name}
          </h1>
          <div style={{ marginTop: 6, fontSize: 11, color: 'var(--muted)' }}>
            <span style={{ color: 'var(--ink)', fontWeight: 600 }}>{counts.active}</span> active
            <span style={{ margin: '0 6px' }}>·</span>
            <span>{counts.unclaimed} unclaimed</span>
            <span style={{ margin: '0 6px' }}>·</span>
            <span>{counts.invitesOut} pending invite</span>
          </div>
        </div>
      </div>

      {/* Sticky tabs */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', padding: '0 8px',
        background: 'var(--paper)', position: 'sticky', top: 0, zIndex: 5,
        overflowX: 'auto', flexShrink: 0 }}>
        <Tab id="Roster" />
        <Tab id="Requests" badge={counts.pending} />
        <Tab id="Members" />
        <Tab id="Settings" />
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {tab === 'Roster' && <ManageRoster squad={squad} setSquad={setSquad} primary={team.primary} firstTime={justCreated} teamName={team.name} />}
        {tab === 'Requests' && <ManageRequests requests={requests} setReq={setReq} />}
        {tab === 'Members' && <ManageMembers firstTime={justCreated} />}
        {tab === 'Settings' && <ManageSettings team={team} />}
        <div style={{ height: 90 }} />
      </div>

      {/* Footer CTAs — hidden during the just-created empty state.
          The empty Roster/Members panes carry their own primary actions. */}
      {!justCreated && (
        <div style={{ flexShrink: 0, padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8 }}>
          <button
            onClick={() => window.openCkComposer && window.openCkComposer({
              author: { kind: 'team', name: team.name, initials: team.monogram, color: team.primary },
            })}
            style={{ flex: 1, padding: '12px 0', borderRadius: 12, border: 'none', background: 'var(--red)', color: 'white', fontFamily: 'Inter', fontWeight: 700, fontSize: 13, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6, boxShadow: '0 4px 10px rgba(190,60,40,0.25)' }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
            Post as team
          </button>
          <button style={{ padding: '12px 16px', borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            Add player
          </button>
        </div>
      )}
      {window.CkComposerHost && <window.CkComposerHost />}
    </div>
  );
}

// ─── Roster tab ─────────────────────────────────────
function ManageRoster({ squad, setSquad, primary, firstTime, teamName }) {
  const setStatus = (id, status) => setSquad(prev => prev.map(p => p.id === id ? { ...p, status } : p));

  const active = squad.filter(p => p.status === 'active');
  const pendingSms = squad.filter(p => p.status === 'pending-sms');
  const unclaimed = squad.filter(p => p.status === 'unclaimed');
  const inactive = squad.filter(p => p.status === 'inactive');

  // First-time / just-created empty state — only the owner is on the squad.
  if (firstTime && active.length <= 1 && pendingSms.length === 0 && unclaimed.length === 0) {
    return (
      <div style={{ padding: '14px 16px 0' }}>
        {/* Hero empty */}
        <div style={{
          padding: '28px 18px 22px', textAlign: 'center',
          background: 'var(--paper-2)', border: '1px dashed var(--line)',
          borderRadius: 14, marginBottom: 18,
        }}>
          <div style={{
            width: 72, height: 72, margin: '0 auto 14px',
            borderRadius: 18, background: 'var(--paper)',
            border: '1px solid var(--hairline)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative',
          }}>
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="9" cy="9" r="4"/>
              <path d="M2 21c0-4 3-6 7-6s7 2 7 6"/>
              <path d="M19 8v6M16 11h6"/>
            </svg>
            <div style={{
              position: 'absolute', top: -6, right: -6,
              width: 24, height: 24, borderRadius: 999,
              background: 'var(--red)', color: 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 12, fontWeight: 700,
              border: '2px solid var(--paper)',
              fontFamily: 'Inter Tight',
            }}>1</div>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 19, letterSpacing: '-0.02em', lineHeight: 1.1, marginBottom: 6 }}>
            It's just you so far.
          </div>
          <div style={{ fontSize: 12.5, color: 'var(--ink-2)', lineHeight: 1.5, maxWidth: 260, margin: '0 auto' }}>
            Build {teamName || 'your team'}'s squad — search registered players, send SMS invites, or add unclaimed placeholders for names that aren't on the app yet.
          </div>
        </div>

        {/* Three paths */}
        <div style={{ display: 'grid', gap: 8, marginBottom: 18 }}>
          {[
            {
              icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>,
              t: 'Search registered players',
              s: 'Pick from people already on matchday',
              accent: 'var(--ink)',
              primary: true,
            },
            {
              icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M3 5h18v14H3z"/><path d="M3 7l9 6 9-6"/></svg>,
              t: 'Send an SMS invite',
              s: 'Phone number → download link',
              accent: 'var(--amber)',
            },
            {
              icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/><path d="M8 7l8 2M8 9l8-2" strokeDasharray="2 2"/></svg>,
              t: 'Add as unclaimed',
              s: 'Just a name — they can claim later',
              accent: 'var(--muted)',
            },
          ].map((p, i) => (
            <button key={i} style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: 12,
              padding: '12px 14px',
              background: p.primary ? 'var(--ink)' : 'var(--paper)',
              border: '1px solid ' + (p.primary ? 'var(--ink)' : 'var(--hairline)'),
              borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8,
                background: p.primary ? 'rgba(255,255,255,0.14)' : 'var(--paper-2)',
                color: p.primary ? 'var(--paper)' : p.accent,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>{p.icon}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 13.5, color: p.primary ? 'var(--paper)' : 'var(--ink)', fontFamily: 'Inter Tight', letterSpacing: '-0.01em' }}>{p.t}</div>
                <div style={{ fontSize: 11, color: p.primary ? 'rgba(255,255,255,0.7)' : 'var(--muted)', marginTop: 2 }}>{p.s}</div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={p.primary ? 'rgba(255,255,255,0.7)' : 'var(--muted)'} strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
            </button>
          ))}
        </div>

        {/* You · owner row, kept visible so they see themselves */}
        <div className="ck-section-h" style={{ padding: '0 4px 8px' }}>You</div>
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 12, overflow: 'hidden' }}>
          {squad.map(p => (
            <ManagedPlayer key={p.id} p={p} primary={primary} />
          ))}
        </div>

        {/* FYI */}
        <div style={{
          marginTop: 16, padding: '10px 12px',
          background: 'var(--paper-2)', border: '1px solid var(--hairline)',
          borderRadius: 10, fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.5,
          display: 'flex', gap: 10, alignItems: 'flex-start',
        }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', fontWeight: 700, letterSpacing: '0.1em', flexShrink: 0, marginTop: 1 }}>FYI</span>
          <span>You can have up to <b style={{ color: 'var(--ink)' }}>25 active members</b>. A team with no other players is fine — you'll just appear as <i>Inactive</i> on the leaderboard until you add someone.</span>
        </div>
      </div>
    );
  }

  // Jersey collision detect (illustrative — pretend 11 + 11 collide)
  const jerseyCounts = {};
  squad.filter(p => p.status !== 'inactive').forEach(p => { jerseyCounts[p.jersey] = (jerseyCounts[p.jersey] || 0) + 1; });

  return (
    <div style={{ padding: '14px 0' }}>
      {/* Capacity */}
      <div style={{ padding: '0 16px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
          <div className="ck-section-h">Squad capacity</div>
          <div className="ck-mono" style={{ fontSize: 12, fontWeight: 600 }}>
            {active.length + pendingSms.length + unclaimed.length}<span style={{ color: 'var(--muted)' }}>/25</span>
          </div>
        </div>
        <div style={{ height: 6, borderRadius: 999, background: 'var(--paper-2)', overflow: 'hidden', display: 'flex' }}>
          <div style={{ width: `${(active.length/25)*100}%`, height: '100%', background: 'var(--green)' }}/>
          <div style={{ width: `${(pendingSms.length/25)*100}%`, height: '100%', background: 'var(--amber)' }}/>
          <div style={{ width: `${(unclaimed.length/25)*100}%`, height: '100%', background: 'var(--cream)' }}/>
        </div>
        <div style={{ marginTop: 6, fontSize: 11, color: 'var(--muted)', display: 'flex', gap: 12 }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--green)' }}/>Active</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--amber)' }}/>Invited</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--cream)' }}/>Unclaimed</span>
        </div>
      </div>

      {/* Active roster */}
      <RosterSection title={`Active · ${active.length}`}>
        {active.map(p => (
          <ManagedPlayer key={p.id} p={p} primary={primary} jerseyClash={jerseyCounts[p.jersey] > 1}
            onAction={action => action === 'remove' ? setStatus(p.id, 'inactive') : null} />
        ))}
      </RosterSection>

      {pendingSms.length > 0 && (
        <RosterSection title={`Invited · ${pendingSms.length}`} accent="amber">
          {pendingSms.map(p => (
            <ManagedPlayer key={p.id} p={p} primary={primary}
              extra={
                <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
                  <button style={{ padding: '7px 12px', borderRadius: 9, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Resend SMS</button>
                  <button onClick={() => setStatus(p.id, 'inactive')} style={{ padding: '7px 12px', borderRadius: 9, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontSize: 12, fontWeight: 500, cursor: 'pointer', color: 'var(--ink-2)' }}>Cancel</button>
                </div>
              }
            />
          ))}
        </RosterSection>
      )}

      {unclaimed.length > 0 && (
        <RosterSection title={`Unclaimed · ${unclaimed.length}`}>
          {unclaimed.map(p => (
            <ManagedPlayer key={p.id} p={p} primary={primary} />
          ))}
        </RosterSection>
      )}

      {inactive.length > 0 && (
        <RosterSection title={`Past members · ${inactive.length}`}>
          {inactive.map(p => (
            <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)', opacity: 0.55 }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--paper-2)', color: 'var(--muted)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12, flexShrink: 0 }}>#{p.jersey}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 500, textDecoration: 'line-through' }}>{p.n}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{p.since}</div>
              </div>
              <button onClick={() => setStatus(p.id, 'active')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted)', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em' }}>RE-ADD</button>
            </div>
          ))}
        </RosterSection>
      )}

      <div style={{ padding: '16px 16px 0' }}>
        <button style={{
          width: '100%', padding: 12, borderRadius: 12,
          border: '1px dashed var(--line)', background: 'transparent',
          color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer',
        }}>+ Add player (search · invite · placeholder)</button>
      </div>
    </div>
  );
}

function RosterSection({ title, children, accent }) {
  return (
    <div style={{ marginTop: 18 }}>
      <div style={{ padding: '0 16px 6px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <span className="ck-section-h">{title.split(' · ')[0]}</span>
        <span className="ck-mono" style={{ fontSize: 10, color: accent === 'amber' ? 'var(--amber)' : 'var(--muted)' }}>· {title.split(' · ')[1]}</span>
      </div>
      {children}
    </div>
  );
}

function ManagedPlayer({ p, primary, extra, jerseyClash, onAction }) {
  const ROLE_BADGE = { 'Captain': 'C', 'Vice-Captain': 'VC', 'Wicket-Keeper': 'WK' };
  return (
    <div style={{ padding: '12px 16px', borderTop: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10, position: 'relative',
          background: p.kind === 'unclaimed' ? 'transparent' : primary,
          color: p.kind === 'unclaimed' ? 'var(--muted)' : 'white',
          border: p.kind === 'unclaimed' ? '1px dashed var(--line)' : 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 13, letterSpacing: '-0.02em',
          flexShrink: 0,
        }}>
          #{p.jersey}
          {jerseyClash && (
            <div style={{ position: 'absolute', top: -4, right: -4, width: 14, height: 14, borderRadius: 999, background: 'var(--red)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 800, border: '2px solid var(--paper)', fontFamily: 'Inter Tight' }}>!</div>
          )}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            <span style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600, color: 'var(--ink)' }}>{p.n}</span>
            {ROLE_BADGE[p.role] && (
              <span className="ck-chip" style={{ padding: '1px 6px', fontSize: 9, background: 'var(--cream)', color: 'var(--ink-2)', borderColor: 'transparent', letterSpacing: '0.06em' }}>{ROLE_BADGE[p.role]}</span>
            )}
            {p.kind === 'unclaimed' && (
              <span className="ck-chip" style={{ padding: '1px 6px', fontSize: 9, background: 'var(--paper-2)', color: 'var(--muted)', borderColor: 'var(--hairline)', letterSpacing: '0.06em' }}>UNCLAIMED</span>
            )}
            {p.kind === 'sms' && (
              <span className="ck-chip" style={{ padding: '1px 6px', fontSize: 9, background: 'oklch(0.97 0.04 90)', color: 'oklch(0.45 0.12 80)', borderColor: 'transparent', letterSpacing: '0.06em' }}>SMS SENT</span>
            )}
          </div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>{p.since}</div>
          {jerseyClash && (
            <div style={{ marginTop: 4, fontSize: 10.5, color: 'var(--red)', fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>
              JERSEY #{p.jersey} USED BY 2 PLAYERS
            </div>
          )}
        </div>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', color: 'var(--muted)' }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
        </button>
      </div>
      {extra}
    </div>
  );
}

// ─── Requests tab ───────────────────────────────────
function ManageRequests({ requests, setReq }) {
  const claims = requests.filter(r => r.kind === 'claim');
  const joins  = requests.filter(r => r.kind === 'join');
  const invites = requests.filter(r => r.kind === 'invite-pending');

  return (
    <div style={{ padding: '14px 0' }}>
      {claims.length === 0 && joins.length === 0 && invites.length === 0 && (
        <EmptyState icon="✓" title="All caught up" sub="No pending requests or invites." />
      )}

      {claims.length > 0 && (
        <RequestSection title={`Claim requests · ${claims.length}`} explainer="Someone says they're an unclaimed player you added. Approving links their account to all past stats.">
          {claims.map(r => (
            <RequestCard key={r.id} r={r} actions={
              <>
                <button onClick={() => setReq(r.id, 'approve')} style={{ flex: 1, padding: '10px 0', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Approve claim</button>
                <button onClick={() => setReq(r.id, 'reject')} style={{ padding: '10px 14px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, color: 'var(--ink-2)', cursor: 'pointer' }}>Reject</button>
              </>
            }/>
          ))}
        </RequestSection>
      )}

      {joins.length > 0 && (
        <RequestSection title={`Join requests · ${joins.length}`} explainer="Players asking to be added to your roster.">
          {joins.map(r => (
            <RequestCard key={r.id} r={r} actions={
              <>
                <button onClick={() => setReq(r.id, 'approve')} style={{ flex: 1, padding: '10px 0', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Add to roster</button>
                <button onClick={() => setReq(r.id, 'reject')} style={{ padding: '10px 14px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, color: 'var(--ink-2)', cursor: 'pointer' }}>Decline</button>
              </>
            }/>
          ))}
        </RequestSection>
      )}

      {invites.length > 0 && (
        <RequestSection title={`Outgoing invites · ${invites.length}`} explainer="People you've invited but haven't accepted yet.">
          {invites.map(r => (
            <RequestCard key={r.id} r={r} muted actions={
              <>
                <button style={{ flex: 1, padding: '10px 0', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>Resend</button>
                <button onClick={() => setReq(r.id, 'cancel')} style={{ padding: '10px 14px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, color: 'var(--ink-2)', cursor: 'pointer' }}>Cancel</button>
              </>
            }/>
          ))}
        </RequestSection>
      )}
    </div>
  );
}

function RequestSection({ title, explainer, children }) {
  return (
    <div style={{ marginBottom: 6 }}>
      <div style={{ padding: '6px 16px 4px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <span className="ck-section-h">{title.split(' · ')[0]}</span>
        <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)' }}>· {title.split(' · ')[1]}</span>
      </div>
      {explainer && (
        <div style={{ padding: '0 16px 8px', fontSize: 11, color: 'var(--muted)', lineHeight: 1.4 }}>{explainer}</div>
      )}
      {children}
    </div>
  );
}

function RequestCard({ r, actions, muted }) {
  return (
    <div style={{ margin: '0 16px 10px', padding: 14, borderRadius: 14, background: muted ? 'var(--paper-2)' : 'var(--surface)', border: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        <div style={{
          width: 38, height: 38, borderRadius: 999, flexShrink: 0,
          background: r.kind === 'claim' ? 'oklch(0.92 0.05 28)' : r.kind === 'join' ? 'oklch(0.92 0.05 148)' : 'var(--paper-2)',
          color: r.kind === 'claim' ? 'var(--red)' : r.kind === 'join' ? 'var(--green)' : 'var(--muted)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 14,
        }}>
          {r.who.split(' ').map(s => s[0]).join('')}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600 }}>{r.who}</span>
            <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{r.when}</span>
          </div>
          <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 3, lineHeight: 1.35 }}>{r.about}</div>
          <div style={{ fontSize: 10.5, color: 'var(--muted)', marginTop: 4, fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>{r.proof.toUpperCase()}</div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>{actions}</div>
    </div>
  );
}

function EmptyState({ icon, title, sub }) {
  return (
    <div style={{ padding: '48px 24px', textAlign: 'center' }}>
      <div style={{
        width: 56, height: 56, borderRadius: 999, margin: '0 auto 14px',
        background: 'var(--green-soft)', color: 'var(--green)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 24,
      }}>{icon}</div>
      <div style={{ fontFamily: 'Inter Tight', fontSize: 17, fontWeight: 700 }}>{title}</div>
      <div style={{ marginTop: 4, fontSize: 12, color: 'var(--muted)' }}>{sub}</div>
    </div>
  );
}

// ─── Members tab (managers / owner) ────────────────
function ManageMembers({ firstTime }) {
  // Empty / first-time state: only the owner, no co-managers yet.
  if (firstTime) {
    return (
      <div style={{ padding: '14px 16px 0' }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Owner</div>
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: 14, marginBottom: 22, display: 'flex', alignItems: 'center', gap: 12 }}>
          <div className="ck-avatar" style={{ width: 42, height: 42, fontSize: 16, background: 'var(--ink)', color: 'var(--paper)', borderColor: 'transparent' }}>BA</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700 }}>Bilal Ahmed</div>
            <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>You · created just now · can transfer ownership</div>
          </div>
        </div>

        {/* Empty co-managers */}
        <div style={{
          padding: '24px 18px', textAlign: 'center',
          background: 'var(--paper-2)', border: '1px dashed var(--line)',
          borderRadius: 14, marginBottom: 14,
        }}>
          <div style={{
            width: 56, height: 56, margin: '0 auto 12px',
            borderRadius: 14, background: 'var(--paper)',
            border: '1px solid var(--hairline)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
              <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, letterSpacing: '-0.02em', marginBottom: 4 }}>
            No co-managers yet.
          </div>
          <div style={{ fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5, maxWidth: 260, margin: '0 auto 14px' }}>
            Share the load. Co-managers can edit the roster, schedule fixtures and post as the team.
          </div>
          <button style={{
            padding: '9px 16px', borderRadius: 9, border: 'none',
            background: 'var(--ink)', color: 'var(--paper)',
            fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 6,
          }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
            Add a co-manager
          </button>
        </div>

        <div style={{ padding: 12, background: 'var(--paper-2)', borderRadius: 12, fontSize: 11, color: 'var(--ink-2)', display: 'flex', gap: 10, alignItems: 'flex-start', lineHeight: 1.4 }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.6" style={{ flexShrink: 0, marginTop: 2 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
          <span>Co-managers can do anything you can <em>except</em> disband the team or transfer ownership — that stays with the <strong style={{ color: 'var(--ink)' }}>Owner</strong>.</span>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: '14px 16px 0' }}>
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Owner</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: 14, marginBottom: 18, display: 'flex', alignItems: 'center', gap: 12 }}>
        <div className="ck-avatar" style={{ width: 42, height: 42, fontSize: 16, background: 'var(--ink)', color: 'var(--paper)', borderColor: 'transparent' }}>BA</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700 }}>Bilal Ahmed</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>You · created Jan 2024 · can transfer ownership</div>
        </div>
        <button style={{ padding: '7px 12px', borderRadius: 9, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', color: 'var(--ink-2)', cursor: 'pointer' }}>TRANSFER</button>
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
        <span className="ck-section-h">Co-managers · 2</span>
        <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', color: 'var(--ink)' }}>+ ADD</button>
      </div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        {[
          { n: 'Adeel Sheikh', since: 'Mar 2024', last: '2h ago', role: 'Manager' },
          { n: 'Faraz Khan',   since: 'Aug 2024', last: 'yesterday', role: 'Manager' },
        ].map((m, i) => (
          <div key={m.n} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
            <div className="ck-avatar">{m.n.split(' ').map(s => s[0]).join('')}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{m.n}</div>
              <div style={{ fontSize: 10.5, color: 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 2, letterSpacing: '0.04em' }}>{m.role.toUpperCase()} · ADDED {m.since.toUpperCase()} · ACTIVE {m.last.toUpperCase()}</div>
            </div>
            <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', color: 'var(--muted)' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
            </button>
          </div>
        ))}
      </div>

      <div style={{ marginTop: 18, padding: 12, background: 'var(--paper-2)', borderRadius: 12, fontSize: 11, color: 'var(--ink-2)', display: 'flex', gap: 10, alignItems: 'flex-start', lineHeight: 1.4 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.6" style={{ flexShrink: 0, marginTop: 2 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
        <span>Co-managers can edit roster, fixtures and broadcast. Only the <strong style={{ color: 'var(--ink)' }}>Owner</strong> can disband the team or transfer ownership.</span>
      </div>
    </div>
  );
}

// ─── Settings tab ───────────────────────────────────
function ManageSettings({ team }) {
  return (
    <div style={{ padding: '14px 16px 0' }}>
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Identity</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 18 }}>
        <SettingRow label="Team name"  value={team.name}  />
        <SettingRow label="Team type"  value={team.type}  />
        <SettingRow label="Colors"     custom={
          <div style={{ display: 'flex', gap: 6 }}>
            <span style={{ width: 22, height: 22, borderRadius: 6, background: team.primary, border: '1px solid var(--hairline)' }}/>
            <span style={{ width: 22, height: 22, borderRadius: 6, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}/>
          </div>
        } />
        <SettingRow label="Crest"      custom={
          <div style={{ width: 26, height: 26, borderRadius: 7, background: team.primary, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 11 }}>{team.monogram}</div>
        } />
      </div>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Home</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 18 }}>
        <SettingRow label="City"     value={team.city} />
        <SettingRow label="Area"     value={team.area} />
        <SettingRow label="Ground"   value="Gaddafi B Ground" />
      </div>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Rules</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 18 }}>
        <SettingRow label="Privacy" custom={
          <div style={{ display: 'flex', gap: 4 }}>
            {['Public', 'Private'].map((p, i) => (
              <span key={p} style={{
                padding: '5px 10px', borderRadius: 8,
                background: i === 0 ? 'var(--ink)' : 'transparent',
                color: i === 0 ? 'var(--paper)' : 'var(--muted)',
                fontFamily: 'Inter', fontSize: 11, fontWeight: 600,
                border: i === 0 ? '1px solid var(--ink)' : '1px solid var(--hairline)',
              }}>{p}</span>
            ))}
          </div>
        } />
        <SettingRow label="Max squad size" value="25" />
        <SettingRow label="Join requests"  custom={<Toggle on />} />
      </div>

      {/* Danger zone */}
      <div className="ck-section-h" style={{ marginBottom: 8, color: 'var(--red)' }}>Danger zone</div>
      <div style={{ background: 'oklch(0.98 0.015 28)', border: '1px solid oklch(0.92 0.04 28)', borderRadius: 14, overflow: 'hidden' }}>
        <DangerRow title="Archive team" sub="Hides the team but keeps stats. Reversible." cta="ARCHIVE" />
        <DangerRow title="Disband team" sub="Permanent. Stats stay on player profiles." cta="DISBAND" critical />
      </div>
    </div>
  );
}

function SettingRow({ label, value, custom }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '13px 14px', borderTop: '1px solid var(--hairline)', cursor: 'pointer' }}>
      <span style={{ flex: 1, fontFamily: 'Inter', fontSize: 13, fontWeight: 500, color: 'var(--ink)' }}>{label}</span>
      {custom ? custom : <span style={{ fontFamily: 'Inter', fontSize: 13, color: 'var(--ink-2)' }}>{value}</span>}
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="M9 18l6-6-6-6"/></svg>
    </div>
  );
}

function Toggle({ on }) {
  return (
    <span style={{ width: 36, height: 20, borderRadius: 999, background: on ? 'var(--ink)' : 'var(--paper-2)', position: 'relative', flexShrink: 0, border: on ? 'none' : '1px solid var(--hairline)' }}>
      <span style={{ position: 'absolute', top: 2, left: on ? 18 : 2, width: 16, height: 16, borderRadius: 999, background: 'white', boxShadow: '0 1px 3px rgba(0,0,0,0.2)' }}/>
    </span>
  );
}

function DangerRow({ title, sub, cta, critical }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px', borderTop: '1px solid oklch(0.92 0.04 28)' }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: 'var(--red)' }}>{title}</div>
        <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 2, lineHeight: 1.35 }}>{sub}</div>
      </div>
      <button style={{
        padding: '8px 12px', borderRadius: 9,
        background: critical ? 'var(--red)' : 'var(--paper)',
        color: critical ? 'var(--paper)' : 'var(--red)',
        border: critical ? 'none' : '1px solid var(--red)',
        fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', cursor: 'pointer',
      }}>{cta}</button>
    </div>
  );
}

window.CkTeamManage = CkTeamManage;

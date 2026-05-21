// Pavilion.jsx — the new center tab (replaces Profile + Create + Settings).
// Implements section 08 of IA Map.html:
//   6 zones · 5 home faces · 16 drill-down screens · role-aware blocks.
//
// Public API:
//   <CkPavilion face="captain" initialView="home" />
//     face: 'new' | 'player' | 'captain' | 'organizer' | 'power'
//     initialView: 'home' | one of the drill-down ids below
//
// Drill-downs (16):
//   status-invites · status-claims · status-drafts · status-today
//   captain-duties · organizer-duties
//   calendar · my-teams · my-tournaments · my-stats · achievements · wallet
//   library-saved · library-followed · library-scorer
//   settings-notifications · settings-discoverability · settings-privacy

(function () {

// ─────────────────────────────────────────────────────────
// Tokens & shared atoms
// ─────────────────────────────────────────────────────────
const ink     = 'var(--ink)';
const ink2    = 'var(--ink-2)';
const muted   = 'var(--muted)';
const paper   = 'var(--paper)';
const paper2  = 'var(--paper-2)';
const hair    = 'var(--hairline)';
const red     = 'var(--red)';
const redSoft = 'var(--red-soft)';
const green   = 'var(--green)';
const amber   = 'var(--amber)';
const cream   = 'var(--cream)';

const monoLabel = {
  fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700,
  letterSpacing: '0.10em', textTransform: 'uppercase', color: muted,
};
const display = (size = 22) => ({
  fontFamily: 'Inter Tight', fontWeight: 700,
  letterSpacing: '-0.025em', fontSize: size, lineHeight: 1.05, color: ink,
});

function PvHeader({ title, sub, onBack, right }) {
  return (
    <div style={{
      padding: '12px 18px 12px',
      display: 'flex', alignItems: 'flex-start', gap: 12,
      borderBottom: '1px solid ' + hair,
    }}>
      {onBack && (
        <button onClick={onBack} aria-label="Back" style={{
          background: 'transparent', border: 'none', padding: 4, marginLeft: -4,
          cursor: 'pointer', color: ink, marginTop: 2,
        }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="m15 18-6-6 6-6"/>
          </svg>
        </button>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={display(22)}>{title}</div>
        {sub && <div style={{ fontSize: 12, color: ink2, marginTop: 2, lineHeight: 1.35 }}>{sub}</div>}
      </div>
      {right}
    </div>
  );
}

function PvSectionH({ children, count, action, accent }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      padding: '18px 18px 10px',
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={{ ...monoLabel, color: accent || muted }}>{children}</span>
        {count != null && (
          <span style={{
            fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700,
            color: paper, background: ink, padding: '1px 6px', borderRadius: 4,
          }}>{count}</span>
        )}
      </div>
      {action && (
        <button style={{
          background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
          fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700,
          letterSpacing: '0.08em', color: ink, textTransform: 'uppercase',
        }}>{action} →</button>
      )}
    </div>
  );
}

function PvCard({ onClick, accent, children, style, padding = '14px 16px' }) {
  return (
    <div onClick={onClick} style={{
      background: paper, border: '1px solid ' + hair,
      borderLeft: accent ? ('3px solid ' + accent) : ('1px solid ' + hair),
      borderRadius: 12, padding, cursor: onClick ? 'pointer' : 'default',
      transition: 'transform .08s ease',
      ...style,
    }}>{children}</div>
  );
}

function PvRow({ icon, title, sub, meta, onClick, accent }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 16px', background: 'transparent',
      border: 'none', borderBottom: '1px solid ' + hair,
      cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
    }}>
      {icon && (
        <div style={{
          width: 36, height: 36, borderRadius: 10,
          background: accent || paper2, color: accent ? paper : ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>{icon}</div>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 600, fontSize: 14, color: ink, lineHeight: 1.25 }}>{title}</div>
        {sub && <div style={{ fontSize: 12, color: muted, marginTop: 2 }}>{sub}</div>}
      </div>
      {meta && <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: muted }}>{meta}</div>}
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
    </button>
  );
}

function PvPill({ children, kind = 'default' }) {
  const styles = {
    default: { background: paper2, color: ink2, border: '1px solid ' + hair },
    red:     { background: red, color: 'white', border: 'none' },
    amber:   { background: amber, color: 'oklch(0.30 0.02 80)', border: 'none' },
    green:   { background: green, color: 'white', border: 'none' },
    soft:    { background: cream, color: 'oklch(0.30 0.02 80)', border: 'none' },
    ink:     { background: ink, color: paper, border: 'none' },
  }[kind] || {};
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700,
      letterSpacing: '0.08em', textTransform: 'uppercase',
      padding: '3px 6px', borderRadius: 4, ...styles,
    }}>{children}</span>
  );
}

// Toggle switch
function PvSwitch({ on, onChange }) {
  return (
    <button onClick={() => onChange && onChange(!on)} aria-pressed={on} style={{
      width: 38, height: 22, borderRadius: 999,
      background: on ? ink : 'oklch(0.85 0.005 85)',
      border: 'none', padding: 2, cursor: 'pointer',
      display: 'flex', alignItems: 'center',
      transition: 'background .15s',
    }}>
      <span style={{
        width: 18, height: 18, borderRadius: 999, background: paper,
        transform: on ? 'translateX(16px)' : 'translateX(0)',
        transition: 'transform .15s', boxShadow: '0 1px 3px rgba(0,0,0,0.15)',
      }}/>
    </button>
  );
}

// ─────────────────────────────────────────────────────────
// HOME (zone scroll) — face-aware
// ─────────────────────────────────────────────────────────
function PvHome({ face, go }) {
  const showCaptain   = face === 'captain' || face === 'power';
  const showOrganizer = face === 'organizer' || face === 'power';
  const isNew         = face === 'new';

  return (
    <div style={{ paddingBottom: 28 }}>
      {/* ZONE 1 · STATUS — what needs you (hidden for new users — nothing needs them yet) */}
      {!isNew && (
        <PvSectionH count={showOrganizer ? 5 : 3} accent={red}>Status · what needs you</PvSectionH>
      )}

      {isNew ? null : (
        <div style={{ padding: '0 18px', display: 'grid', gap: 8 }}>
          {/* Today's fixture */}
          <PvCard accent={red} onClick={() => go('status-today')} style={{ background: paper }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
              <PvPill kind="red">Today · 18:30</PvPill>
              <span style={monoLabel}>QF · Spring Cup</span>
            </div>
            <div style={{ ...display(18) }}>Lions <span style={{ color: muted, fontWeight: 500 }}>vs</span> Eagles</div>
            <div style={{ fontSize: 12, color: ink2, marginTop: 4 }}>Model Town · Pitch 2 · You're on the XI</div>
          </PvCard>

          {/* Pending invite */}
          <PvCard onClick={() => go('status-invites')}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
              <PvPill kind="amber">Invite</PvPill>
              <span style={monoLabel}>From DHA United</span>
            </div>
            <div style={{ fontWeight: 600, fontSize: 14, lineHeight: 1.3 }}>Asad Q. invited you to join the squad.</div>
            <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
              <button onClick={(e) => e.stopPropagation()} style={{
                flex: 1, padding: '8px 0', borderRadius: 8, border: 'none',
                background: ink, color: paper, fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
              }}>Accept</button>
              <button onClick={(e) => e.stopPropagation()} style={{
                flex: 1, padding: '8px 0', borderRadius: 8, border: '1px solid ' + hair,
                background: paper, color: ink, fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
              }}>Decline</button>
            </div>
          </PvCard>

          {/* Claim request — yours */}
          <PvCard onClick={() => go('status-claims')}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <PvPill>Claim · pending</PvPill>
              <span style={monoLabel}>Awaiting manager</span>
            </div>
            <div style={{ fontSize: 13, color: ink2, marginTop: 6, lineHeight: 1.4 }}>
              Your claim on <b style={{ color: ink }}>"B. Khan · Mohalla Kings '21"</b> is in review.
            </div>
          </PvCard>

          {showCaptain && (
            <PvCard accent={amber} onClick={() => go('captain-duties')}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <PvPill kind="amber">Captain</PvPill>
                <span style={monoLabel}>Lahore Lions · 3 actions</span>
              </div>
              <div style={{ fontSize: 13, color: ink2, marginTop: 6, lineHeight: 1.4 }}>
                Pick XI for tonight · 1 join request · 2 claim approvals
              </div>
            </PvCard>
          )}

          {showOrganizer && (
            <PvCard accent={green} onClick={() => go('organizer-duties')}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <PvPill kind="green">Organizer</PvPill>
                <span style={monoLabel}>Spring Cup '26 · 4 actions</span>
              </div>
              <div style={{ fontSize: 13, color: ink2, marginTop: 6, lineHeight: 1.4 }}>
                2 team registrations · scorer pool low · awards open · payment overdue (1)
              </div>
            </PvCard>
          )}
        </div>
      )}

      {/* Drafts strip — Create zone is now a FAB (see CkPavilion root) */}
      {!isNew && (
        <PvCard onClick={() => go('status-drafts')} style={{
          margin: '12px 18px 0', background: paper2, borderStyle: 'dashed',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <PvPill>Drafts · 2</PvPill>
            <span style={{ fontSize: 12, color: ink2 }}>Spring Cup (87% done) · Lions roster (50%)</span>
          </div>
        </PvCard>
      )}

      {/* ZONE 3 · CALENDAR — peek (or empty state for new users) */}
      <PvSectionH action={isNew ? null : "See all"}>Calendar · upcoming</PvSectionH>
      {isNew ? (
        <div style={{ padding: '0 18px' }}>
          <button onClick={() => go('calendar')} style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 14,
            padding: '16px 14px', background: paper2,
            border: '1px dashed ' + hair, borderRadius: 12,
            cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
          }}>
            <div style={{
              width: 44, height: 44, borderRadius: 10, background: paper,
              border: '1px solid ' + hair,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <rect x="3" y="5" width="18" height="16" rx="2"/>
                <path d="M3 9h18M8 3v4M16 3v4"/>
              </svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 600, fontSize: 13, color: ink }}>No fixtures yet</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2, lineHeight: 1.4 }}>
                Join a team, register for a tournament, or schedule a friendly— your matches will appear here.
              </div>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2" strokeLinecap="round"><path d="M9 18l6-6-6-6"/></svg>
          </button>
        </div>
      ) : (
        <div style={{ padding: '0 18px', display: 'grid', gap: 6 }}>
          {[
            { d: 'TUE', n: 14, t: 'Lions vs Eagles',    s: '18:30 · QF · Model Town',   live: true },
            { d: 'SAT', n: 18, t: 'Lions vs DHA',       s: '15:00 · Group · Gulberg' },
            { d: 'SUN', n: 19, t: 'Practice match',     s: '07:00 · Home ground' },
          ].map((e, i) => (
            <button key={i} onClick={() => go('calendar')} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
              background: paper, border: '1px solid ' + hair, borderRadius: 10,
              cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{ textAlign: 'center', minWidth: 36 }}>
                <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: muted, fontWeight: 700 }}>{e.d}</div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, lineHeight: 1, color: ink }}>{e.n}</div>
              </div>
              <div style={{ width: 1, height: 28, background: hair }}/>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 13, color: ink }}>{e.t}</div>
                <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{e.s}</div>
              </div>
              {e.live && <PvPill kind="red">Today</PvPill>}
            </button>
          ))}
        </div>
      )}

      {/* ZONE 4 · YOURS */}
      <PvSectionH>Yours</PvSectionH>
      <div style={{ padding: '0 18px', display: 'grid', gap: 6 }}>
        <PvRow icon="⚑" title="My teams" sub={isNew ? 'No teams yet' : '3 teams · 1 captained'} meta={isNew ? '0' : '3'} onClick={() => go('my-teams')} />
        <PvRow icon="♛" title="My tournaments" sub={showOrganizer ? '2 organizing · 1 playing' : '1 playing'} meta={showOrganizer ? '3' : '1'} onClick={() => go('my-tournaments')} />
        <PvRow icon="📊" title="My stats" sub="Career · Form · Wagon" onClick={() => go('my-stats')} />
        <PvRow icon="✦" title="Achievements" sub={isNew ? 'Locked · play 1 match' : '12 unlocked · 4 in progress'} onClick={() => go('achievements')} />
        <PvRow icon="₨" title="Wallet" sub="Entry fees · payouts" onClick={() => go('wallet')} />
      </div>

      {/* ZONE 5 · LIBRARY */}
      <PvSectionH>Library</PvSectionH>
      <div style={{ padding: '0 18px', display: 'grid', gap: 6 }}>
        <PvRow icon="◷" title="Saved" sub="14 posts · 3 matches" onClick={() => go('library-saved')} />
        <PvRow icon="◎" title="Followed" sub={isNew ? '0 follows · suggestions' : '6 players · 4 teams · 2 tournaments'} onClick={() => go('library-followed')} />
        <PvRow icon="✎" title="Scorer history" sub={face === 'power' ? '38 matches scored' : '0 matches scored'} onClick={() => go('library-scorer')} />
      </div>

      {/* ZONE 6 · SETTINGS */}
      <PvSectionH>Settings</PvSectionH>
      <div style={{ padding: '0 18px', display: 'grid', gap: 6 }}>
        <PvRow icon="🔔" title="Notifications & alerts" sub="Push · in-app · quiet hours" onClick={() => go('settings-notifications')} />
        <PvRow icon="◉" title="Discoverability" sub="4 toggles · who can find you" onClick={() => go('settings-discoverability')} />
        <PvRow icon="◐" title="Privacy & blocking" sub="Mute list · blocked · reports" onClick={() => go('settings-privacy')} />
      </div>

      {/* Footer */}
      <div style={{ padding: '20px 18px 0', textAlign: 'center' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: muted, letterSpacing: '0.10em' }}>
          CIRCK v0.1 · ENGLISH · KARACHI
        </div>
        <div style={{ marginTop: 10, display: 'flex', justifyContent: 'center', gap: 14, fontSize: 11, color: muted }}>
          <span>Help</span><span>·</span><span>Terms</span><span>·</span><span>Sign out</span>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// DRILL-DOWN SCREENS — 16 leaves
// ─────────────────────────────────────────────────────────

function PvStatusInvites({ back }) {
  const [tab, setTab] = React.useState('all');
  const items = [
    { kind: 'team',     title: 'DHA United · squad invite',           by: 'Asad Q. · captain', age: '2h' },
    { kind: 'tour',     title: 'Spring Cup ‘26 · tournament invite',  by: 'Sara A. · organizer', age: '5h' },
    { kind: 'role',     title: 'Become scorer · QF Lions vs Eagles',  by: 'Tournament', age: '1d' },
    { kind: 'role',     title: 'Co-manager · Lahore Lions',           by: 'Imran Q.', age: '2d' },
    { kind: 'team',     title: 'Mohalla Kings · join request reply',  by: 'Approved', age: '3d', done: true },
  ];
  return (
    <div>
      <PvHeader title="Pending invites" sub="5 invites · 4 awaiting your response" onBack={back} />
      <div style={{ display: 'flex', gap: 6, padding: '12px 18px 4px', overflowX: 'auto' }}>
        {['all', 'team', 'tour', 'role'].map(t => (
          <button key={t} onClick={() => setTab(t)} style={{
            padding: '6px 12px', borderRadius: 999,
            border: '1px solid ' + (tab === t ? ink : hair),
            background: tab === t ? ink : 'transparent',
            color: tab === t ? paper : ink, fontSize: 12, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer',
          }}>{({ all: 'All', team: 'Teams', tour: 'Tournaments', role: 'Roles' })[t]}</button>
        ))}
      </div>
      <div style={{ padding: '8px 18px', display: 'grid', gap: 8 }}>
        {items.filter(i => tab === 'all' || i.kind === tab).map((it, i) => (
          <PvCard key={i} accent={it.done ? null : amber}>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 4 }}>
              <PvPill kind={it.done ? 'default' : 'amber'}>{({ team: 'Team', tour: 'Tournament', role: 'Role' })[it.kind]}</PvPill>
              <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: muted }}>{it.age}</span>
            </div>
            <div style={{ fontWeight: 600, fontSize: 14, color: ink, lineHeight: 1.3 }}>{it.title}</div>
            <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>{it.by}</div>
            {!it.done && (
              <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                <button style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: 'none', background: ink, color: paper, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Accept</button>
                <button style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Decline</button>
              </div>
            )}
          </PvCard>
        ))}
      </div>
    </div>
  );
}

function PvStatusClaims({ back }) {
  return (
    <div>
      <PvHeader title="Claim requests · yours" sub="Profiles you've claimed · status & history" onBack={back} />
      <div style={{ padding: '14px 18px', display: 'grid', gap: 10 }}>
        <PvCard accent={amber}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <PvPill kind="amber">Pending</PvPill>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: muted }}>3 days ago</span>
          </div>
          <div style={{ fontWeight: 600, fontSize: 14 }}>"B. Khan" · Mohalla Kings '21</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>Manager: Faisal A. · 38 matches · 14 innings</div>
          <div style={{ fontSize: 11, color: ink2, marginTop: 8, padding: 8, background: paper2, borderRadius: 6 }}>
            On approval, all balls / innings / career stats migrate to your profile atomically.
          </div>
        </PvCard>
        <PvCard accent={green}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <PvPill kind="green">Approved</PvPill>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: muted }}>last week</span>
          </div>
          <div style={{ fontWeight: 600, fontSize: 14 }}>"Bilal K." · City Eagles '22</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>Stats migrated · 24 mat · 612 runs</div>
        </PvCard>
        <PvCard>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <PvPill>Rejected</PvPill>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: muted }}>2 weeks ago</span>
          </div>
          <div style={{ fontWeight: 600, fontSize: 14 }}>"B Khan" · Old Boys 2019</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>Manager confirmed different player.</div>
        </PvCard>
        <button style={{
          marginTop: 4, padding: '12px 14px', background: paper2, border: '1px dashed ' + hair,
          borderRadius: 10, color: ink, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>+ Find another profile to claim</button>
      </div>
    </div>
  );
}

function PvStatusDrafts({ back }) {
  const drafts = [
    { kind: 'tour',  title: "Spring Cup '26",         pct: 87, step: 'Review',     last: 'today' },
    { kind: 'team',  title: 'Lions roster — invite',  pct: 50, step: 'Add players', last: 'yesterday' },
  ];
  return (
    <div>
      <PvHeader title="Drafts" sub="Resume where you left off" onBack={back} />
      <div style={{ padding: '14px 18px', display: 'grid', gap: 10 }}>
        {drafts.map((d, i) => (
          <PvCard key={i}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <PvPill>{d.kind === 'tour' ? 'Tournament' : 'Team'}</PvPill>
              <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: muted }}>edited {d.last}</span>
            </div>
            <div style={{ fontWeight: 700, fontSize: 16, fontFamily: 'Inter Tight' }}>{d.title}</div>
            <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>Stuck at <b style={{ color: ink2 }}>{d.step}</b></div>
            {/* progress */}
            <div style={{ marginTop: 10, height: 4, background: paper2, borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ width: d.pct + '%', height: '100%', background: ink }}/>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
              <span style={{ fontSize: 11, color: muted, fontFamily: 'JetBrains Mono' }}>{d.pct}%</span>
              <div style={{ display: 'flex', gap: 6 }}>
                <button style={{ padding: '6px 10px', borderRadius: 6, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Discard</button>
                <button style={{ padding: '6px 10px', borderRadius: 6, border: 'none', background: ink, color: paper, fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Resume →</button>
              </div>
            </div>
          </PvCard>
        ))}
      </div>
    </div>
  );
}

function PvStatusToday({ back }) {
  return (
    <div>
      <PvHeader title="Today's fixture" sub="QF · Spring Cup '26 · 18:30" onBack={back} />
      <div style={{ padding: '16px 18px' }}>
        <PvCard accent={red} style={{ padding: 18 }}>
          <PvPill kind="red">In 4h 12m</PvPill>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 12 }}>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ width: 48, height: 48, borderRadius: 999, background: red, color: paper, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18 }}>L</div>
              <div style={{ ...display(15), marginTop: 6 }}>Lions</div>
            </div>
            <div style={{ ...display(20), color: muted }}>vs</div>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ width: 48, height: 48, borderRadius: 999, background: green, color: paper, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 18 }}>E</div>
              <div style={{ ...display(15), marginTop: 6 }}>Eagles</div>
            </div>
          </div>
          <div style={{ marginTop: 14, padding: 12, background: paper2, borderRadius: 8 }}>
            <div style={monoLabel}>Venue</div>
            <div style={{ fontWeight: 600, fontSize: 13, marginTop: 2 }}>Model Town · Pitch 2</div>
            <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>1.4 km · 8 min drive</div>
          </div>
          <div style={{ marginTop: 10, padding: 12, background: paper2, borderRadius: 8 }}>
            <div style={monoLabel}>Your role</div>
            <div style={{ fontWeight: 600, fontSize: 13, marginTop: 2 }}>On the XI · Batting #3</div>
          </div>
        </PvCard>
        <div style={{ display: 'grid', gap: 8, marginTop: 12 }}>
          <button style={{ padding: '14px 0', borderRadius: 12, border: 'none', background: ink, color: paper, fontSize: 14, fontWeight: 700, fontFamily: 'inherit', cursor: 'pointer' }}>Open match sheet →</button>
          <button style={{ padding: '12px 0', borderRadius: 12, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Get directions</button>
          <button style={{ padding: '12px 0', borderRadius: 12, border: '1px solid ' + hair, background: paper, color: red, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Mark unavailable</button>
        </div>
      </div>
    </div>
  );
}

function PvCaptainDuties({ back }) {
  return (
    <div>
      <PvHeader title="Captain duties" sub="Lahore Lions · 3 actions" onBack={back} right={<PvPill kind="amber">cap</PvPill>} />
      <div style={{ padding: '14px 18px', display: 'grid', gap: 10 }}>
        <PvCard accent={red}>
          <PvPill kind="red">Pick XI · today</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>QF · Lions vs Eagles · 18:30</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>14 squad available · 11 needed · auto-pick from last match</div>
          <button style={{ marginTop: 10, width: '100%', padding: '10px 0', borderRadius: 8, border: 'none', background: ink, color: paper, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Pick XI →</button>
        </PvCard>
        <PvCard accent={amber}>
          <PvPill kind="amber">Join request</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>Hassan Ali wants to join Lions</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>Off-spinner · 23 yrs · 18 matches · @hassana</div>
          <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
            <button style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: 'none', background: ink, color: paper, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Approve</button>
            <button style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Reject</button>
          </div>
        </PvCard>
        <PvCard accent={amber}>
          <PvPill kind="amber">Claim approvals · 2</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>Two players claim profiles in your roster</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3, lineHeight: 1.5 }}>
            "Bilal K. · Spring '23"  →  Bilal Khan @bilalk<br/>
            "A. Asad · Winter '22"  →  Asad A. @asad
          </div>
          <button style={{ marginTop: 10, width: '100%', padding: '10px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Review claims →</button>
        </PvCard>
      </div>
    </div>
  );
}

function PvOrganizerDuties({ back }) {
  return (
    <div>
      <PvHeader title="Organizer duties" sub="Spring Cup '26 · 4 actions" onBack={back} right={<PvPill kind="green">org</PvPill>} />
      <div style={{ padding: '14px 18px', display: 'grid', gap: 10 }}>
        <PvCard accent={green}>
          <PvPill kind="green">Team registrations · 2</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>DHA United · Old Boys</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>Both squads locked · paid · awaiting your approval</div>
          <button style={{ marginTop: 10, width: '100%', padding: '10px 0', borderRadius: 8, border: 'none', background: ink, color: paper, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Approve both →</button>
        </PvCard>
        <PvCard accent={amber}>
          <PvPill kind="amber">Scorer pool low</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>3 scorers · 8 matches this weekend</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>Recommend 5+ · invite from search</div>
          <button style={{ marginTop: 10, width: '100%', padding: '10px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Invite scorers →</button>
        </PvCard>
        <PvCard accent={red}>
          <PvPill kind="red">Payment overdue</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>Mohalla Kings · ₨ 5,000 entry fee</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>Due 4 days ago · waiver available</div>
          <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
            <button style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: 'none', background: ink, color: paper, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Send reminder</button>
            <button style={{ flex: 1, padding: '8px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Waive fee</button>
          </div>
        </PvCard>
        <PvCard>
          <PvPill>Awards open</PvPill>
          <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6 }}>Tournament ends Sunday — finalize awards</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>5 auto-suggested · pick winners or override</div>
          <button style={{ marginTop: 10, width: '100%', padding: '10px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 13, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Open awards →</button>
        </PvCard>
      </div>
    </div>
  );
}

function PvCalendar({ back, empty }) {
  // Empty state — first-time user, no fixtures yet
  if (empty) {
    return (
      <div>
        <PvHeader title="Calendar" sub="Your fixtures — nothing scheduled yet" onBack={back} />
        <div style={{ padding: '32px 18px 24px', textAlign: 'center' }}>
          <div style={{
            width: 88, height: 88, margin: '0 auto 18px',
            borderRadius: 22, background: paper2,
            border: '1px solid ' + hair,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative',
          }}>
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
              <rect x="3" y="5" width="18" height="16" rx="2"/>
              <path d="M3 9h18M8 3v4M16 3v4"/>
            </svg>
            <div style={{
              position: 'absolute', bottom: -6, right: -6,
              width: 28, height: 28, borderRadius: 999,
              background: amber, color: paper,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 16, fontWeight: 700, border: '2px solid ' + paper,
              fontFamily: 'Inter Tight',
            }}>0</div>
          </div>
          <div style={{ ...display(20), marginBottom: 6 }}>No fixtures yet</div>
          <div style={{ fontSize: 13, color: ink2, lineHeight: 1.5, maxWidth: 280, margin: '0 auto' }}>
            Your calendar fills up the moment you join a team, register for a tournament, or schedule a friendly match.
          </div>
        </div>

        {/* Three paths to a first fixture */}
        <PvSectionH>Three ways to get on the field</PvSectionH>
        <div style={{ padding: '0 18px 20px', display: 'grid', gap: 10 }}>
          {[
            {
              icon: (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>
                </svg>
              ),
              accent: red,
              t: 'Discover tournaments near you',
              s: 'Browse open registrations within 50 km — Spring leagues, weekend cups, mohalla championships.',
              cta: 'Open Discover',
            },
            {
              icon: <span style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700 }}>⚑</span>,
              accent: ink,
              t: 'Join a team',
              s: 'Search teams by city or area, or accept a roster invite from a captain you know.',
              cta: 'Find teams',
            },
            {
              icon: <span style={{ fontSize: 18, fontWeight: 700 }}>◉</span>,
              accent: amber,
              t: 'Schedule a friendly',
              s: 'Pick a date, two sides, a venue — score it live or enter the result later.',
              cta: 'Create match',
            },
          ].map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'flex-start', gap: 12,
              padding: 14, background: paper,
              border: '1px solid ' + hair, borderRadius: 12,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 9,
                background: p.accent, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>{p.icon}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: ink, marginBottom: 2 }}>{p.t}</div>
                <div style={{ fontSize: 12, color: muted, lineHeight: 1.5, marginBottom: 8 }}>{p.s}</div>
                <button style={{
                  fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700,
                  letterSpacing: '0.08em', color: ink,
                  background: 'transparent', border: '1px solid ' + ink,
                  padding: '5px 10px', borderRadius: 6, cursor: 'pointer',
                }}>{p.cta} →</button>
              </div>
            </div>
          ))}
        </div>

        {/* Sync hint */}
        <div style={{ padding: '0 18px 24px' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', background: paper2,
            border: '1px solid ' + hair, borderRadius: 10,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
              <path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/>
              <path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M3 21v-5h5"/>
            </svg>
            <div style={{ flex: 1, fontSize: 11, color: ink2, lineHeight: 1.4 }}>
              Once you have fixtures, you'll be able to <b style={{ color: ink }}>sync to your phone calendar</b>.
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Default — populated calendar
  // Month view + agenda
  const days = Array.from({ length: 30 }, (_, i) => i + 1);
  const eventDays = { 14: 'red', 18: 'green', 19: 'amber', 22: 'green', 28: 'red' };
  return (
    <div>
      <PvHeader title="Calendar" sub="March 2026 · 5 fixtures · 2 practice" onBack={back} />
      {/* Month grid */}
      <div style={{ padding: '12px 18px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <span style={{ ...display(18) }}>March 2026</span>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={{ padding: 6, borderRadius: 6, border: '1px solid ' + hair, background: paper, cursor: 'pointer' }}>‹</button>
            <button style={{ padding: 6, borderRadius: 6, border: '1px solid ' + hair, background: paper, cursor: 'pointer' }}>›</button>
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4 }}>
          {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) => (
            <div key={i} style={{ ...monoLabel, textAlign: 'center', fontSize: 9 }}>{d}</div>
          ))}
          {days.map(d => (
            <div key={d} style={{
              aspectRatio: '1', display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
              background: d === 14 ? ink : paper,
              color: d === 14 ? paper : ink,
              borderRadius: 6, fontSize: 12, fontWeight: 600, position: 'relative',
              border: '1px solid ' + (d === 14 ? ink : hair),
            }}>
              {d}
              {eventDays[d] && d !== 14 && (
                <div style={{ width: 4, height: 4, borderRadius: 999, background: ({ red, green, amber })[eventDays[d]], marginTop: 1 }}/>
              )}
            </div>
          ))}
        </div>
      </div>
      {/* Agenda */}
      <PvSectionH>Agenda · upcoming</PvSectionH>
      <div style={{ padding: '0 18px 20px', display: 'grid', gap: 6 }}>
        {[
          { d: 'TUE 14', t: 'Lions vs Eagles', s: '18:30 · QF · Model Town', k: 'red' },
          { d: 'SAT 18', t: 'Lions vs DHA United', s: '15:00 · Group · Gulberg', k: 'green' },
          { d: 'SUN 19', t: 'Practice match', s: '07:00 · Home ground', k: 'amber' },
          { d: 'SUN 22', t: 'Lions vs Mohalla Kings', s: '16:00 · Group · DHA', k: 'green' },
          { d: 'SAT 28', t: 'Spring Cup · FINAL', s: '18:00 · Model Town · Pitch 1', k: 'red' },
        ].map((e, i) => (
          <div key={i} style={{
            display: 'flex', gap: 10, padding: '12px',
            background: paper, border: '1px solid ' + hair, borderRadius: 10,
            borderLeft: '3px solid ' + ({ red, green, amber })[e.k],
          }}>
            <div style={{ minWidth: 56, ...monoLabel, color: ink, alignSelf: 'center' }}>{e.d}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>{e.t}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{e.s}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function PvMyTeams({ back }) {
  const teams = [
    { name: 'Lahore Lions',   role: 'Captain',  count: '14 squad', color: red,   active: true },
    { name: 'Old Boys',       role: 'Player',   count: '22 squad', color: ink,   active: true },
    { name: 'Office Tigers',  role: 'Manager',  count: '11 squad', color: green, active: false },
  ];
  return (
    <div>
      <PvHeader title="My teams" sub="3 teams · 1 captained · 1 managed" onBack={back} right={
        <button style={{ padding: '6px 10px', borderRadius: 8, border: '1px solid ' + hair, background: paper, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>+ New</button>
      } />
      <div style={{ padding: '14px 18px', display: 'grid', gap: 10 }}>
        {teams.map((t, i) => (
          <PvCard key={i}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 44, height: 44, borderRadius: 10, background: t.color, color: paper, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16 }}>
                {t.name.split(' ').map(s => s[0]).join('').slice(0, 2)}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 15, fontFamily: 'Inter Tight' }}>{t.name}</div>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginTop: 4 }}>
                  <PvPill kind={t.role === 'Captain' ? 'amber' : (t.role === 'Manager' ? 'ink' : 'default')}>{t.role}</PvPill>
                  <span style={{ fontSize: 11, color: muted }}>{t.count}</span>
                  {!t.active && <PvPill>Inactive</PvPill>}
                </div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
            </div>
          </PvCard>
        ))}
      </div>
    </div>
  );
}

function PvMyTournaments({ back }) {
  return (
    <div>
      <PvHeader title="My tournaments" sub="2 organizing · 1 playing" onBack={back} />
      <PvSectionH accent={green}>Organizing · 2</PvSectionH>
      <div style={{ padding: '0 18px', display: 'grid', gap: 8 }}>
        {[
          { name: "Spring Cup '26", s: '8 teams · 18 fixtures · QF stage', live: true },
          { name: "Friday League",  s: '6 teams · weekly · Friday nights' },
        ].map((t, i) => (
          <PvCard key={i} accent={green}>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
              <div style={{ fontWeight: 700, fontSize: 15, fontFamily: 'Inter Tight' }}>{t.name}</div>
              {t.live && <PvPill kind="red">Live</PvPill>}
            </div>
            <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>{t.s}</div>
          </PvCard>
        ))}
      </div>
      <PvSectionH>Playing · 1</PvSectionH>
      <div style={{ padding: '0 18px 20px', display: 'grid', gap: 8 }}>
        <PvCard>
          <div style={{ fontWeight: 700, fontSize: 15, fontFamily: 'Inter Tight' }}>Mohalla T10 Winter</div>
          <div style={{ fontSize: 12, color: muted, marginTop: 4 }}>With Old Boys · group stage · 2W 1L</div>
        </PvCard>
      </div>
    </div>
  );
}

function PvMyStats({ back }) {
  const [tab, setTab] = React.useState('Career');
  return (
    <div>
      <PvHeader title="My stats" sub="142 matches · since 2019" onBack={back} />
      <div style={{ display: 'flex', gap: 4, padding: '12px 18px 4px' }}>
        {['Career', 'Form', 'Wagon'].map(t => (
          <button key={t} onClick={() => setTab(t)} style={{
            flex: 1, padding: '8px 0', borderRadius: 8,
            border: '1px solid ' + (tab === t ? ink : hair),
            background: tab === t ? ink : 'transparent',
            color: tab === t ? paper : ink, fontSize: 12, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer',
          }}>{t}</button>
        ))}
      </div>
      {tab === 'Career' && (
        <div style={{ padding: '10px 18px', display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8 }}>
          {[
            ['Runs', '4,217'], ['Average', '36.4'],
            ['Strike rate', '138.6'], ['Best', '112*'],
            ['Wickets', '21'], ['Economy', '8.4'],
            ['Catches', '38'], ['MOM', '14'],
          ].map(([l, v]) => (
            <div key={l} style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, padding: '12px 14px' }}>
              <div style={monoLabel}>{l}</div>
              <div style={{ ...display(24), marginTop: 4 }}>{v}</div>
            </div>
          ))}
        </div>
      )}
      {tab === 'Form' && (
        <div style={{ padding: '10px 18px' }}>
          <div style={monoLabel}>Last 5 innings</div>
          <div style={{ display: 'grid', gap: 6, marginTop: 10 }}>
            {[
              { vs: 'Eagles',   r: 67, b: 41, s: 'NOT OUT', col: green },
              { vs: 'Kings',    r: 12, b: 18 },
              { vs: 'DHA',      r: 88, b: 52, s: '50+', col: amber },
              { vs: 'Old Boys', r: 4,  b: 9 },
              { vs: 'Eagles',   r: 33, b: 24 },
            ].map((m, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, color: muted }}>vs {m.vs}</div>
                  <div style={{ ...display(18), marginTop: 2 }}>{m.r} <span style={{ color: muted, fontSize: 11, fontWeight: 500 }}>({m.b})</span></div>
                </div>
                {m.s && <PvPill kind={m.col === green ? 'green' : 'amber'}>{m.s}</PvPill>}
              </div>
            ))}
          </div>
        </div>
      )}
      {tab === 'Wagon' && (
        <div style={{ padding: '10px 18px', textAlign: 'center' }}>
          <svg viewBox="-110 -110 220 220" width="280" height="280" style={{ background: paper, border: '1px solid ' + hair, borderRadius: 999 }}>
            <circle r="100" stroke={hair} strokeWidth="1" fill="none"/>
            <circle r="55" stroke={hair} strokeWidth="1" fill="none"/>
            <line x1="0" y1="-100" x2="0" y2="100" stroke={hair}/>
            <line x1="-100" y1="0" x2="100" y2="0" stroke={hair}/>
            {[
              [80, -40, 6], [60, -75, 4], [-65, -55, 4], [-90, 30, 6],
              [50, 60, 4], [85, 45, 6], [-30, 85, 1], [-70, -20, 4],
              [40, -90, 6], [25, -60, 2], [-55, 70, 1], [70, 10, 4],
            ].map(([x, y, r], i) => (
              <line key={i} x1="0" y1="0" x2={x} y2={y} stroke={r === 6 ? ink : (r === 4 ? green : muted)} strokeWidth={r === 1 ? 0.8 : 1.4}/>
            ))}
            <circle r="3" fill={red}/>
          </svg>
          <div style={{ fontSize: 11, color: muted, marginTop: 8 }}>Career wagon · 412 boundaries · leg-side dominant</div>
        </div>
      )}
    </div>
  );
}

function PvAchievements({ back }) {
  const items = [
    { t: 'First fifty',          k: 'unlocked', d: 'May 2019 · vs Eagles' },
    { t: 'Hat-trick hero',       k: 'unlocked', d: 'Dec 2022 · vs DHA' },
    { t: 'Century maker',        k: 'unlocked', d: '4× · best 112*' },
    { t: '1000 career runs',     k: 'unlocked', d: 'Jan 2021' },
    { t: '5-fer',                k: 'progress', d: '4 wkts · 1 to go' },
    { t: 'MOM ×25',              k: 'progress', d: '14 / 25' },
    { t: 'Captain a tournament', k: 'progress', d: 'in progress · Spring Cup' },
    { t: 'Score 100 matches',    k: 'locked' },
    { t: 'Tournament winner',    k: 'locked' },
  ];
  return (
    <div>
      <PvHeader title="Achievements" sub="12 unlocked · 4 in progress · 8 locked" onBack={back} />
      <div style={{ padding: '14px 18px', display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8 }}>
        {items.map((a, i) => (
          <div key={i} style={{
            padding: 14, borderRadius: 10,
            background: a.k === 'unlocked' ? cream : paper,
            border: '1px solid ' + (a.k === 'unlocked' ? 'oklch(0.86 0.05 90)' : hair),
            opacity: a.k === 'locked' ? 0.5 : 1,
          }}>
            <div style={{ width: 36, height: 36, borderRadius: 999, background: a.k === 'unlocked' ? amber : paper2, display: 'flex', alignItems: 'center', justifyContent: 'center', color: a.k === 'unlocked' ? paper : muted, fontSize: 18 }}>
              {a.k === 'unlocked' ? '✦' : (a.k === 'progress' ? '◴' : '🔒')}
            </div>
            <div style={{ fontWeight: 700, fontSize: 13, marginTop: 8, fontFamily: 'Inter Tight' }}>{a.t}</div>
            {a.d && <div style={{ fontSize: 10, color: muted, marginTop: 3, fontFamily: 'JetBrains Mono' }}>{a.d}</div>}
          </div>
        ))}
      </div>
    </div>
  );
}

function PvWallet({ back }) {
  return (
    <div>
      <PvHeader title="Wallet" sub="Entry fees · payouts · receipts" onBack={back} />
      <div style={{ padding: '14px 18px' }}>
        <PvCard accent={green} style={{ padding: 18 }}>
          <div style={monoLabel}>Available balance</div>
          <div style={{ ...display(38), marginTop: 6 }}>₨ 12,500</div>
          <div style={{ fontSize: 11, color: muted, marginTop: 6 }}>From Spring Cup '25 · Best Bowler payout</div>
          <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
            <button style={{ flex: 1, padding: '10px 0', borderRadius: 8, border: 'none', background: ink, color: paper, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Withdraw</button>
            <button style={{ flex: 1, padding: '10px 0', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Add method</button>
          </div>
        </PvCard>
      </div>
      <PvSectionH>Recent activity</PvSectionH>
      <div style={{ padding: '0 18px 20px', display: 'grid', gap: 4 }}>
        {[
          { t: 'Spring Cup ‘26 · entry fee', a: '−₨ 5,000', d: 'Mar 4', k: 'out' },
          { t: 'Best Bowler · Spring ‘25',   a: '+₨ 12,500', d: 'Feb 14', k: 'in' },
          { t: 'Friday League · entry fee',  a: '−₨ 2,000', d: 'Jan 22', k: 'out' },
          { t: 'MOM bonus · vs DHA',         a: '+₨ 500',   d: 'Jan 14', k: 'in' },
        ].map((r, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>{r.t}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2, fontFamily: 'JetBrains Mono' }}>{r.d}</div>
            </div>
            <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 14, color: r.k === 'in' ? green : ink }}>{r.a}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function PvLibrarySaved({ back }) {
  return (
    <div>
      <PvHeader title="Saved" sub="14 posts · 3 matches · 2 tournaments" onBack={back} />
      <div style={{ display: 'flex', gap: 6, padding: '12px 18px 4px' }}>
        {['All', 'Posts', 'Matches', 'Tours'].map((t, i) => (
          <button key={t} style={{
            padding: '6px 12px', borderRadius: 999,
            border: '1px solid ' + (i === 0 ? ink : hair),
            background: i === 0 ? ink : 'transparent',
            color: i === 0 ? paper : ink, fontSize: 12, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer',
          }}>{t}</button>
        ))}
      </div>
      <div style={{ padding: '8px 18px', display: 'grid', gap: 8 }}>
        {[
          { t: '"That cover drive was clean."', s: 'Bilal Khan · 3d ago', k: 'post' },
          { t: 'Lions vs Eagles · QF',          s: 'Match · Mar 14',     k: 'match' },
          { t: 'Spring Cup ‘26',                s: 'Tournament',         k: 'tour' },
          { t: '"Looking for a fast bowler"',   s: 'Old Boys · 5d ago',  k: 'post' },
          { t: '"Hat-trick — never gets old"',  s: 'Imran Q. · 1w ago',  k: 'post' },
        ].map((s, i) => (
          <PvCard key={i}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
              <PvPill kind={s.k === 'match' ? 'red' : (s.k === 'tour' ? 'amber' : 'default')}>{s.k}</PvPill>
              <span style={{ fontSize: 11, color: muted, fontFamily: 'JetBrains Mono' }}>{s.s}</span>
            </div>
            <div style={{ fontWeight: 600, fontSize: 14, marginTop: 6, lineHeight: 1.35 }}>{s.t}</div>
          </PvCard>
        ))}
      </div>
    </div>
  );
}

function PvLibraryFollowed({ back }) {
  const [tab, setTab] = React.useState('Players');
  const groups = {
    Players:     [{ n: 'Babar Azam', s: 'PAK · top order', notif: true }, { n: 'Imran Q.', s: '@imranq · captain · friend' }, { n: 'Hassan Ali', s: 'PAK · pace' }],
    Teams:       [{ n: 'Lahore Lions', s: '14 squad · home', notif: true }, { n: 'City Eagles', s: 'rivals · 8 squad' }, { n: 'DHA United', s: '11 squad' }],
    Tournaments: [{ n: "Spring Cup '26", s: '8 teams · live', notif: true }, { n: 'Friday League', s: '6 teams · weekly' }],
  };
  return (
    <div>
      <PvHeader title="Followed" sub="6 players · 3 teams · 2 tournaments" onBack={back} />
      <div style={{ display: 'flex', gap: 4, padding: '12px 18px 4px' }}>
        {Object.keys(groups).map(t => (
          <button key={t} onClick={() => setTab(t)} style={{
            flex: 1, padding: '8px 0', borderRadius: 8,
            border: '1px solid ' + (tab === t ? ink : hair),
            background: tab === t ? ink : 'transparent',
            color: tab === t ? paper : ink, fontSize: 12, fontWeight: 600,
            fontFamily: 'inherit', cursor: 'pointer',
          }}>{t}</button>
        ))}
      </div>
      <div style={{ padding: '8px 18px', display: 'grid', gap: 6 }}>
        {groups[tab].map((it, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
            <div className="ck-avatar" style={{ width: 36, height: 36, fontSize: 12, background: ink, color: paper, borderColor: 'transparent' }}>
              {it.n.split(' ').map(s => s[0]).join('').slice(0, 2)}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>{it.n}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{it.s}</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span title="Per-follow notifications" style={{ fontSize: 14, color: it.notif ? red : muted }}>
                {it.notif ? '🔔' : '🔕'}
              </span>
              <button style={{ padding: '5px 10px', borderRadius: 6, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Following ✓</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function PvLibraryScorer({ back }) {
  const matches = [
    { d: 'Mar 09', t: 'Lions vs Eagles',     v: 'Model Town', r: 'Lions won by 4 wkts', live: true },
    { d: 'Mar 02', t: 'Lions vs Mohalla K.', v: 'Gulberg',    r: 'M. Kings won by 12' },
    { d: 'Feb 22', t: 'DHA vs Old Boys',     v: 'DHA grounds',r: 'DHA won by 3 wkts' },
    { d: 'Feb 14', t: 'Eagles vs DHA',       v: 'Model Town', r: 'Eagles won by 22' },
  ];
  return (
    <div>
      <PvHeader title="Scorer history" sub="38 matches scored · since 2022" onBack={back} />
      <div style={{ padding: '14px 18px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
        {[['Total', '38'], ['This month', '4'], ['Avg accy', '99.2%']].map(([l, v]) => (
          <div key={l} style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, padding: '10px 12px', textAlign: 'center' }}>
            <div style={{ ...monoLabel, fontSize: 9 }}>{l}</div>
            <div style={{ ...display(20), marginTop: 4 }}>{v}</div>
          </div>
        ))}
      </div>
      <PvSectionH>Recent matches</PvSectionH>
      <div style={{ padding: '0 18px 20px', display: 'grid', gap: 6 }}>
        {matches.map((m, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
            <div style={{ minWidth: 50, ...monoLabel, color: ink }}>{m.d}</div>
            <div style={{ width: 1, height: 28, background: hair }}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>{m.t}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{m.v} · {m.r}</div>
            </div>
            {m.live && <PvPill kind="red">Today</PvPill>}
          </div>
        ))}
      </div>
    </div>
  );
}

function PvSettingsNotifications({ back }) {
  const [vals, setVals] = React.useState({
    matchStart: true, matchResult: true, milestoneMine: false,
    milestoneFollowed: true, mention: true, follow: false, reply: true,
    invites: true, claimUpdates: true, captain: true, organizer: true,
    quietHours: true, matchNearMe: false,
  });
  const set = (k) => (v) => setVals(p => ({ ...p, [k]: v }));
  const Group = ({ title, items }) => (
    <>
      <PvSectionH>{title}</PvSectionH>
      <div style={{ padding: '0 18px', background: paper, margin: '0 18px', border: '1px solid ' + hair, borderRadius: 10 }}>
        {items.map(([k, l, s], i) => (
          <div key={k} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '12px 4px',
            borderBottom: i === items.length - 1 ? 'none' : '1px solid ' + hair,
          }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>{l}</div>
              {s && <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{s}</div>}
            </div>
            <PvSwitch on={vals[k]} onChange={set(k)} />
          </div>
        ))}
      </div>
    </>
  );
  return (
    <div>
      <PvHeader title="Notifications & alerts" sub="Push · in-app · per-channel" onBack={back} />
      <Group title="Match" items={[
        ['matchStart', 'Match starting', 'Followed teams · 30 min before'],
        ['matchResult', 'Match results', 'Followed teams + tournaments'],
        ['matchNearMe', 'Match near you (v1.1)', '50 km · live now'],
      ]} />
      <Group title="Milestones" items={[
        ['milestoneMine', 'Milestones about me', 'Auto-post 50/100/5-fer to your feed'],
        ['milestoneFollowed', 'Milestones · followed', '50 · 100 · hat-tricks · championship'],
      ]} />
      <Group title="Social" items={[
        ['mention', 'Mentions in posts', null],
        ['follow', 'New followers', null],
        ['reply', 'Replies to your posts', null],
      ]} />
      <Group title="Roles & duties" items={[
        ['invites', 'Invites & requests', 'Team · tournament · scorer · co-manager'],
        ['claimUpdates', 'Claim updates', 'Approval · rejection · stat migration'],
        ['captain', 'Captain alerts', 'XI deadlines · join requests · claims'],
        ['organizer', 'Organizer alerts', 'Registrations · payments · scorer pool'],
      ]} />
      <PvSectionH>Quiet hours</PvSectionH>
      <div style={{ margin: '0 18px 24px', padding: '14px 16px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: vals.quietHours ? 10 : 0 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 600, fontSize: 13 }}>Mute push during sleep</div>
          </div>
          <PvSwitch on={vals.quietHours} onChange={set('quietHours')} />
        </div>
        {vals.quietHours && (
          <div style={{ display: 'flex', gap: 8 }}>
            {[['From', '22:00'], ['To', '07:00']].map(([l, v]) => (
              <div key={l} style={{ flex: 1, padding: 10, background: paper2, borderRadius: 8 }}>
                <div style={monoLabel}>{l}</div>
                <div style={{ ...display(18), marginTop: 4 }}>{v}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function PvSettingsDiscoverability({ back }) {
  const [vals, setVals] = React.useState({
    appearInSearch: true, suggestToOthers: true, showLocation: true, contactByCaptains: true,
  });
  const set = (k) => (v) => setVals(p => ({ ...p, [k]: v }));
  const flags = [
    ['appearInSearch',     'Appear in search results',        'Anyone can find you by name / handle'],
    ['suggestToOthers',    'Suggest me to others',            'Surface in "you may know" + onboarding'],
    ['showLocation',       'Show my city on profile',         'Karachi · used for nearby tournaments'],
    ['contactByCaptains',  'Captains can invite me to teams', 'Off = teams must be requested by you'],
  ];
  return (
    <div>
      <PvHeader title="Discoverability" sub="4 toggles · who can find you and how" onBack={back} />
      <div style={{ padding: '14px 18px' }}>
        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12, overflow: 'hidden' }}>
          {flags.map(([k, l, s], i) => (
            <div key={k} style={{
              display: 'flex', alignItems: 'flex-start', gap: 12, padding: '14px 16px',
              borderBottom: i === flags.length - 1 ? 'none' : '1px solid ' + hair,
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{l}</div>
                <div style={{ fontSize: 12, color: muted, marginTop: 3 }}>{s}</div>
              </div>
              <PvSwitch on={vals[k]} onChange={set(k)} />
            </div>
          ))}
        </div>
        <div style={{ marginTop: 14, padding: 12, background: paper2, borderRadius: 10, fontSize: 12, color: ink2, lineHeight: 1.5 }}>
          <PvPill>Note</PvPill><br/>
          Discoverability is independent of <b>following</b>. Turning everything off doesn't hide your stats from people who already follow you — they just can't find you again.
        </div>
      </div>
    </div>
  );
}

function PvSettingsPrivacy({ back }) {
  return (
    <div>
      <PvHeader title="Privacy & blocking" sub="Mute · block · report receipts" onBack={back} />

      <PvSectionH count={2}>Muted</PvSectionH>
      <div style={{ padding: '0 18px', display: 'grid', gap: 6 }}>
        {[{ n: 'Random Spammer', s: 'muted 2 weeks ago' }, { n: 'Old Rivalry', s: 'muted 1 month' }].map((u, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
            <div className="ck-avatar" style={{ width: 32, height: 32, fontSize: 11 }}>{u.n.split(' ').map(s => s[0]).join('')}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 13 }}>{u.n}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{u.s}</div>
            </div>
            <button style={{ padding: '6px 10px', borderRadius: 6, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Unmute</button>
          </div>
        ))}
      </div>

      <PvSectionH count={1}>Blocked</PvSectionH>
      <div style={{ padding: '0 18px', display: 'grid', gap: 6 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', background: paper, border: '1px solid ' + hair, borderRadius: 10 }}>
          <div className="ck-avatar" style={{ width: 32, height: 32, fontSize: 11, background: red, color: paper, borderColor: 'transparent' }}>BX</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 600, fontSize: 13 }}>Blocked X.</div>
            <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>blocked 3 months ago · cannot see you, message you, or tag you</div>
          </div>
          <button style={{ padding: '6px 10px', borderRadius: 6, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Unblock</button>
        </div>
      </div>

      <PvSectionH count={3}>Report receipts</PvSectionH>
      <div style={{ padding: '0 18px 20px', display: 'grid', gap: 6 }}>
        {[
          { t: 'Comment by Random S.', s: 'Reported 3d · under review', k: 'amber' },
          { t: 'Post by Spam Acct',    s: 'Reported 1w · removed by admin', k: 'green' },
          { t: 'Profile by Fake Acct', s: 'Reported 2w · no action taken',  k: 'default' },
        ].map((r, i) => (
          <div key={i} style={{ padding: '10px 12px', background: paper, border: '1px solid ' + hair, borderRadius: 10, borderLeft: '3px solid ' + ({ amber, green, default: hair })[r.k] }}>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{r.t}</div>
            <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{r.s}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// ROOT — Pavilion shell
// ─────────────────────────────────────────────────────────
function CkPavilion({ face = 'captain', initialView = 'home' }) {
  const [view, setView] = React.useState(initialView);
  const [createOpen, setCreateOpen] = React.useState(false);
  const back = () => setView('home');

  // Lock body scroll while sheet is open
  React.useEffect(() => {
    if (!createOpen) return;
    const onKey = (e) => { if (e.key === 'Escape') setCreateOpen(false); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [createOpen]);

  const screens = {
    home: () => <PvHome face={face} go={setView} />,
    'status-invites':           () => <PvStatusInvites back={back} />,
    'status-claims':            () => <PvStatusClaims back={back} />,
    'status-drafts':            () => <PvStatusDrafts back={back} />,
    'status-today':             () => <PvStatusToday back={back} />,
    'captain-duties':           () => <PvCaptainDuties back={back} />,
    'organizer-duties':         () => <PvOrganizerDuties back={back} />,
    'calendar':                 () => <PvCalendar back={back} empty={face === 'new'} />,
    'my-teams':                 () => <PvMyTeams back={back} />,
    'my-tournaments':           () => <PvMyTournaments back={back} />,
    'my-stats':                 () => <PvMyStats back={back} />,
    'achievements':             () => <PvAchievements back={back} />,
    'wallet':                   () => <PvWallet back={back} />,
    'library-saved':            () => <PvLibrarySaved back={back} />,
    'library-followed':         () => <PvLibraryFollowed back={back} />,
    'library-scorer':           () => <PvLibraryScorer back={back} />,
    'settings-notifications':   () => <PvSettingsNotifications back={back} />,
    'settings-discoverability': () => <PvSettingsDiscoverability back={back} />,
    'settings-privacy':         () => <PvSettingsPrivacy back={back} />,
  };

  // V2 nav: Feed · Tours · Pavilion (active) · Matches · Messages
  const PavBottomNav = () => (
    <div style={{
      flexShrink: 0, borderTop: '1px solid ' + hair, background: paper,
      paddingBottom: 'env(safe-area-inset-bottom)',
    }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', height: 56, alignItems: 'center' }}>
        {[
          { id: 'feed',    label: 'FEED',   glyph: '☰' },
          { id: 'tours',   label: 'TOURS',  glyph: '♛' },
          { id: 'pav',     label: 'PAV',    glyph: '⌂', active: true },
          { id: 'matches', label: 'MATCH',  glyph: '◉' },
          { id: 'msgs',    label: 'MSGS',   glyph: '✎' },
        ].map(t => (
          <button key={t.id} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: 0, height: '100%',
          }}>
            <div style={{
              width: 28, height: 28, borderRadius: 8,
              background: t.active ? ink : 'transparent',
              color: t.active ? paper : muted,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, fontWeight: 700,
            }}>{t.glyph}</div>
            {t.active && (
              <span style={{
                fontFamily: 'JetBrains Mono', fontSize: 8.5, fontWeight: 700,
                color: ink, letterSpacing: '0.10em',
              }}>{t.label}</span>
            )}
          </button>
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0 6px' }}>
        <div style={{ width: 134, height: 4, borderRadius: 999, background: ink, opacity: 0.5 }}/>
      </div>
    </div>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      {/* Static title strip on home; drill-downs render their own header */}
      {view === 'home' && (
        <div style={{
          padding: '6px 18px 10px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span className="ck-display" style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.025em' }}>Pavilion</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button aria-label="Search" style={{ width: 36, height: 36, borderRadius: 999, background: paper2, border: '1px solid ' + hair, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
            </button>
            <button aria-label="Notifications" style={{ width: 36, height: 36, borderRadius: 999, background: paper2, border: '1px solid ' + hair, cursor: 'pointer', position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/>
                <path d="M10.3 21a2 2 0 0 0 3.4 0"/>
              </svg>
              <span style={{ position: 'absolute', top: 8, right: 8, width: 7, height: 7, borderRadius: 999, background: red, border: '1.5px solid ' + paper }}/>
            </button>
          </div>
        </div>
      )}
      <div style={{ flex: 1, overflow: 'auto', position: 'relative' }}>
        {(screens[view] || screens.home)()}
      </div>

      {/* ── Floating Action Button — only on home ─────────────────── */}
      {view === 'home' && !createOpen && (
        <button
          onClick={() => setCreateOpen(true)}
          aria-label="Create"
          style={{
            position: 'absolute', right: 18, bottom: 76,
            width: 56, height: 56, borderRadius: 28,
            background: ink, color: paper,
            border: '1px solid ' + ink,
            boxShadow: '0 8px 24px -6px rgba(0,0,0,0.35), 0 2px 6px rgba(0,0,0,0.18)',
            cursor: 'pointer', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            zIndex: 40, transition: 'transform 0.15s ease',
            fontFamily: 'inherit',
          }}
          onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.94)'}
          onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
          onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
            <path d="M12 5v14M5 12h14"/>
          </svg>
        </button>
      )}

      {/* ── Create Bottom Sheet ───────────────────────────────────── */}
      {createOpen && (
        <>
          {/* backdrop */}
          <div
            onClick={() => setCreateOpen(false)}
            style={{
              position: 'absolute', inset: 0, zIndex: 50,
              background: 'rgba(20, 18, 14, 0.42)',
              animation: 'pvFade 0.18s ease-out',
            }}
          />
          {/* sheet */}
          <div
            role="dialog"
            aria-label="Create"
            style={{
              position: 'absolute', left: 0, right: 0, bottom: 0,
              zIndex: 60, background: paper,
              borderTopLeftRadius: 20, borderTopRightRadius: 20,
              borderTop: '1px solid ' + hair,
              boxShadow: '0 -12px 40px -8px rgba(0,0,0,0.18)',
              padding: '10px 0 18px',
              animation: 'pvSlideUp 0.22s cubic-bezier(0.32, 0.72, 0, 1)',
              paddingBottom: 'calc(18px + env(safe-area-inset-bottom))',
            }}
          >
            {/* grabber */}
            <div style={{ display: 'flex', justifyContent: 'center', paddingBottom: 8 }}>
              <div style={{ width: 38, height: 4, borderRadius: 999, background: 'rgba(20,18,14,0.18)' }}/>
            </div>

            {/* header */}
            <div style={{
              display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
              padding: '4px 20px 14px',
            }}>
              <span className="ck-display" style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', color: ink }}>
                Create
              </span>
              <button
                onClick={() => setCreateOpen(false)}
                aria-label="Close"
                style={{
                  background: 'transparent', border: 'none', cursor: 'pointer',
                  fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 700,
                  color: muted, letterSpacing: '0.08em', padding: 4,
                }}
              >
                CLOSE
              </button>
            </div>

            {/* options */}
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {[
                { id: 'match', t: 'Match',      s: 'Friendly · league · cup match — live or post-match scoring', icon: '◉', accent: red },
                { id: 'team',  t: 'Team',       s: 'Club, village or one-off side · 5-step setup',              icon: '⚑', accent: ink },
                { id: 'tour',  t: 'Tournament', s: 'Knockout · round-robin · league · 8-step setup',            icon: '♛', accent: amber },
                { id: 'post',  t: 'Post',       s: 'Text or photo · announcement · recruitment',                icon: '✎', accent: green },
              ].map((c, i, arr) => (
                <button
                  key={c.id}
                  onClick={() => setCreateOpen(false)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: 14,
                    padding: '14px 20px',
                    background: 'transparent',
                    border: 'none',
                    borderTop: i === 0 ? '1px solid ' + hair : 'none',
                    borderBottom: '1px solid ' + hair,
                    cursor: 'pointer', textAlign: 'left',
                    fontFamily: 'inherit',
                  }}
                >
                  <div style={{
                    width: 40, height: 40, borderRadius: 10,
                    background: c.accent, color: paper,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 18, fontWeight: 700, flexShrink: 0,
                  }}>{c.icon}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 700, fontSize: 15, color: ink, letterSpacing: '-0.005em' }}>{c.t}</div>
                    <div style={{ fontSize: 12, color: muted, marginTop: 2, lineHeight: 1.4 }}>{c.s}</div>
                  </div>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
                    <path d="M9 18l6-6-6-6"/>
                  </svg>
                </button>
              ))}
            </div>
          </div>
          <style>{`
            @keyframes pvSlideUp { from { transform: translateY(100%); } to { transform: translateY(0); } }
            @keyframes pvFade { from { opacity: 0; } to { opacity: 1; } }
          `}</style>
        </>
      )}

      <PavBottomNav />
    </div>
  );
}

window.CkPavilion = CkPavilion;
})();

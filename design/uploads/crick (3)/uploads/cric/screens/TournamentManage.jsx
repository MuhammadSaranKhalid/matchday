// TournamentManage.jsx — Organizer view for Spring Cup '26
// Sits next to Tournament.jsx (the public/spectator view).
// Tabs: Overview · Teams · Fixtures · Scorers · Comms · Settings
// Reuses TEAMS + CkTBadge from Tournament.jsx (loaded earlier in the page).

function CkTournamentManage() {
  const [tab, setTab] = React.useState('Overview');
  const [teamRegs, setTeamRegs] = React.useState([
    { id: 'LL', captain: 'Bilal Ahmed',   players: 14, fee: 'paid',    applied: '2d',  status: 'approved'  },
    { id: 'KS', captain: 'Salman Raza',   players: 13, fee: 'paid',    applied: '2d',  status: 'approved'  },
    { id: 'MT', captain: 'Faraz Ali',     players: 12, fee: 'paid',    applied: '3d',  status: 'approved'  },
    { id: 'IT', captain: 'Hamza Tariq',   players: 14, fee: 'paid',    applied: '3d',  status: 'approved'  },
    { id: 'GG', captain: 'Adeel Sheikh',  players: 11, fee: 'paid',    applied: '4d',  status: 'approved'  },
    { id: 'PR', captain: 'Imran Iqbal',   players: 13, fee: 'paid',    applied: '4d',  status: 'approved'  },
    { id: 'FX', captain: 'Saad Mahmood',  players: 12, fee: 'unpaid',  applied: '1d',  status: 'pending'   },
    { id: 'ML', captain: 'Tariq Hussain', players: 10, fee: 'paid',    applied: '5h',  status: 'pending'   },
    { id: 'BR', captain: 'Asad Mehmood',  players: 14, fee: 'paid',    applied: '12h', status: 'pending'   },
  ]);

  const setStatus = (id, status) => setTeamRegs(prev => prev.map(t => t.id === id ? { ...t, status } : t));
  const approved = teamRegs.filter(t => t.status === 'approved').length;
  const pending  = teamRegs.filter(t => t.status === 'pending').length;

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
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.12em' }}>ORGANIZER</span>
        <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>
        </button>
      </div>

      {/* Hero — mirrors public Tournament hero but flagged manage */}
      <div style={{ padding: '4px 18px 14px', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4, fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--muted)' }}>
          <span>LAHORE</span><span>·</span><span>T20</span><span>·</span><span>LEATHER</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
          <h1 className="ck-display" style={{ fontSize: 30, fontWeight: 700, margin: 0, letterSpacing: '-0.03em', lineHeight: 1 }}>
            Spring Cup<span style={{ color: 'var(--muted)', fontWeight: 500 }}> ’26</span>
          </h1>
          <span className="ck-chip" style={{ background: 'var(--green-soft)', color: 'oklch(0.36 0.10 148)', borderColor: 'transparent', flexShrink: 0 }}>
            <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--green)' }}/>
            LIVE
          </span>
        </div>
        <div style={{ marginTop: 8, fontSize: 12, color: 'var(--muted)' }}>
          Knockout · Apr 30 → May 4 · Gaddafi B + 3 venues
        </div>
      </div>

      {/* Sticky tab strip */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', padding: '0 8px',
        background: 'var(--paper)', position: 'sticky', top: 0, zIndex: 5,
        overflowX: 'auto', flexShrink: 0 }}>
        <Tab id="Overview" />
        <Tab id="Teams" badge={pending} />
        <Tab id="Fixtures" />
        <Tab id="Scorers" />
        <Tab id="Comms" />
        <Tab id="Settings" />
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {tab === 'Overview' && <ManageOverview approved={approved} pending={pending} onJump={setTab} />}
        {tab === 'Teams' && <ManageTeams rows={teamRegs} setStatus={setStatus} approved={approved} />}
        {tab === 'Fixtures' && <ManageFixtures />}
        {tab === 'Scorers' && <ManageScorers />}
        {tab === 'Comms' && <ManageComms />}
        {tab === 'Settings' && <ManageSettings />}
        <div style={{ height: 90 }} />
      </div>

      {/* Sticky CTA */}
      <div style={{ flexShrink: 0, padding: '10px 16px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8 }}>
        <button style={{ flex: 1, padding: '12px 0', borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer', color: 'var(--ink)' }}>
          View public page
        </button>
        <button style={{ padding: '12px 18px', borderRadius: 12, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>
          Share invite
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Overview — KPI strip · action queue · live match · activity
// ─────────────────────────────────────────────
function ManageOverview({ approved, pending, onJump }) {
  return (
    <div>
      {/* KPI strip — 4 metrics, monospaced numbers */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
        borderBottom: '1px solid var(--hairline)' }}>
        {[
          { l: 'TEAMS', v: approved, sub: 'of 8 in' },
          { l: 'PLAYED', v: 14, sub: 'of 16' },
          { l: 'TODAY', v: 2, sub: 'matches' },
          { l: 'BUDGET', v: '76k', sub: 'PKR collected' },
        ].map((s, i) => (
          <div key={i} style={{ padding: '14px 12px', borderLeft: i ? '1px solid var(--hairline)' : 'none' }}>
            <div className="ck-section-h">{s.l}</div>
            <div className="ck-display ck-tnum" style={{ fontSize: 24, fontWeight: 700, lineHeight: 1, marginTop: 4 }}>{s.v}</div>
            <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{s.sub}</div>
          </div>
        ))}
      </div>

      {/* Live match strip — same pattern as public side */}
      <div style={{ padding: '14px 16px 0' }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Live now</div>
        <div style={{
          padding: '12px 14px', background: 'var(--ink)', color: 'var(--paper)',
          borderRadius: 14, display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <span className="ck-chip live" style={{ flexShrink: 0 }}>LIVE</span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
              <CkTBadge id="LL" size={18} />
              <span>177/8</span>
              <span style={{ opacity: 0.5, margin: '0 4px' }}>vs</span>
              <CkTBadge id="MT" size={18} />
              <span style={{ color: 'oklch(0.85 0.13 80)' }}>132/4</span>
            </div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>
              QF1 · scorer Adeel S. · 14.3 ov
            </div>
          </div>
          <button style={{ background: 'rgba(255,255,255,0.12)', border: 'none', color: 'var(--paper)', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', padding: '6px 10px', borderRadius: 8, cursor: 'pointer' }}>OPEN</button>
        </div>
      </div>

      {/* Action queue */}
      <div style={{ padding: '18px 16px 0' }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Needs you</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <ActionItem
            tone="amber"
            count={pending}
            title={`${pending} team${pending===1?'':'s'} waiting for approval`}
            sub="Review squad, captain, fee"
            cta="Review"
            onClick={() => onJump('Teams')}
          />
          <ActionItem
            tone="red"
            count={1}
            title="QF2 has no scorer"
            sub="Tomorrow 19:30 · Bagh-e-Jinnah"
            cta="Assign"
            onClick={() => onJump('Scorers')}
          />
          <ActionItem
            tone="muted"
            count={1}
            title="QF1 ball #87 was undone"
            sub="Adeel S. · 4 min ago · auto-restored"
            cta="View"
            onClick={() => {}}
          />
        </div>
      </div>

      {/* Activity feed */}
      <div style={{ padding: '20px 16px 0' }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Today</div>
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
          {[
            { who: 'KS',  what: 'beat ML by 34 runs', when: '12:14', kind: 'result' },
            { who: 'AS',  what: 'started scoring QF1', when: '14:00', kind: 'score' },
            { who: 'BR',  what: 'registered for the cup', when: '15:20', kind: 'reg' },
            { who: 'YOU', what: 'broadcasted: "Final venue confirmed."', when: '16:02', kind: 'broad' },
          ].map((a, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px',
              borderTop: i ? '1px solid var(--hairline)' : 'none',
            }}>
              <ActMark id={a.who} kind={a.kind} />
              <div style={{ flex: 1, fontSize: 13, color: 'var(--ink-2)' }}>
                <strong style={{ color: 'var(--ink)', fontWeight: 600 }}>{a.who === 'YOU' ? 'You' : a.who === 'AS' ? 'Adeel S.' : (TEAMS[a.who]?.name || a.who)}</strong>{' '}
                {a.what}
              </div>
              <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{a.when}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ActionItem({ tone, count, title, sub, cta, onClick }) {
  const map = {
    amber:  { bg: 'oklch(0.97 0.04 90)', border: 'oklch(0.88 0.05 90)', fg: 'oklch(0.45 0.12 80)' },
    red:    { bg: 'oklch(0.97 0.03 28)', border: 'oklch(0.88 0.05 28)', fg: 'oklch(0.50 0.18 28)' },
    muted:  { bg: 'var(--paper-2)',      border: 'var(--hairline)',     fg: 'var(--ink-2)' },
  }[tone];
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
      borderRadius: 14, border: `1px solid ${map.border}`, background: map.bg,
      cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit', width: '100%',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 10,
        background: 'var(--paper)', color: map.fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, flexShrink: 0,
      }}>{count}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: 'var(--ink)', letterSpacing: '-0.01em' }}>{title}</div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>{sub}</div>
      </div>
      <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', color: map.fg }}>
        {cta.toUpperCase()} →
      </span>
    </button>
  );
}

function ActMark({ id, kind }) {
  if (TEAMS[id]) return <CkTBadge id={id} size={26} />;
  if (id === 'YOU') return (
    <div style={{ width: 26, height: 26, borderRadius: 8, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 10, fontWeight: 700, flexShrink: 0 }}>YOU</div>
  );
  return (
    <div style={{ width: 26, height: 26, borderRadius: 8, background: 'var(--cream)', color: 'var(--ink-2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 10, fontWeight: 700, flexShrink: 0 }}>{id}</div>
  );
}

// ─────────────────────────────────────────────
// Teams — pending approval queue + approved roster
// ─────────────────────────────────────────────
function ManageTeams({ rows, setStatus, approved }) {
  const pending = rows.filter(r => r.status === 'pending');
  const approvedList = rows.filter(r => r.status === 'approved');
  const rejected = rows.filter(r => r.status === 'rejected');

  return (
    <div style={{ padding: '14px 0 16px' }}>
      {/* Capacity ribbon */}
      <div style={{ padding: '0 16px 12px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
          <div className="ck-display" style={{ fontSize: 16, fontWeight: 700 }}>Capacity</div>
          <div className="ck-mono" style={{ fontSize: 12, fontWeight: 600 }}>
            {approved}<span style={{ color: 'var(--muted)' }}>/8</span>
          </div>
        </div>
        <div style={{ height: 6, borderRadius: 999, background: 'var(--paper-2)', overflow: 'hidden' }}>
          <div style={{ width: `${(approved/8)*100}%`, height: '100%', background: 'var(--green)' }}/>
        </div>
        <div style={{ marginTop: 6, fontSize: 11, color: 'var(--muted)' }}>
          Bracket already drawn. Late entrants go on a waitlist.
        </div>
      </div>

      {pending.length > 0 && (
        <Section title={`Pending · ${pending.length}`} accent>
          {pending.map(t => (
            <div key={t.id} style={{ padding: '14px 16px', borderTop: '1px solid var(--hairline)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <CkTBadge id={t.id} size={36} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600 }}>{TEAMS[t.id]?.name || t.id}</span>
                    {t.fee === 'unpaid' && (
                      <span className="ck-chip" style={{ padding: '2px 7px', fontSize: 9, background: 'var(--red-soft)', color: 'var(--red)', borderColor: 'transparent' }}>FEE DUE</span>
                    )}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>
                    {t.captain} · {t.players} players · applied {t.applied}
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                <button onClick={() => setStatus(t.id, 'approved')} style={{
                  flex: 1, padding: '10px 0', borderRadius: 10,
                  border: 'none', background: 'var(--ink)', color: 'var(--paper)',
                  fontFamily: 'Inter', fontWeight: 600, fontSize: 13, cursor: 'pointer',
                }}>Approve</button>
                <button onClick={() => setStatus(t.id, 'rejected')} style={{
                  padding: '10px 14px', borderRadius: 10,
                  border: '1px solid var(--hairline)', background: 'var(--paper)',
                  fontFamily: 'Inter', fontWeight: 500, fontSize: 13, color: 'var(--ink-2)', cursor: 'pointer',
                }}>Reject</button>
                <button style={{
                  padding: '10px 12px', borderRadius: 10,
                  border: '1px solid var(--hairline)', background: 'var(--paper)', cursor: 'pointer',
                }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="2"><path d="M12 5v14M5 12h14"/></svg>
                </button>
              </div>
            </div>
          ))}
        </Section>
      )}

      <Section title={`Approved · ${approvedList.length}`}>
        {approvedList.map(t => (
          <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)' }}>
            <CkTBadge id={t.id} size={28} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{TEAMS[t.id]?.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{t.captain} · {t.players} players</div>
            </div>
            <button onClick={() => setStatus(t.id, 'pending')} style={{
              background: 'transparent', border: 'none', padding: 6, cursor: 'pointer',
              color: 'var(--muted)',
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
            </button>
          </div>
        ))}
      </Section>

      {rejected.length > 0 && (
        <Section title={`Rejected · ${rejected.length}`}>
          {rejected.map(t => (
            <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)', opacity: 0.55 }}>
              <CkTBadge id={t.id} size={26} />
              <div style={{ flex: 1, fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 500, textDecoration: 'line-through' }}>{TEAMS[t.id]?.name}</div>
              <button onClick={() => setStatus(t.id, 'pending')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted)', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em' }}>UNDO</button>
            </div>
          ))}
        </Section>
      )}

      <div style={{ padding: '16px 16px 0' }}>
        <button style={{
          width: '100%', padding: 12, borderRadius: 12,
          border: '1px dashed var(--line)', background: 'transparent',
          color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer',
        }}>+ Invite a team manually</button>
      </div>
    </div>
  );
}

function Section({ title, accent, children }) {
  return (
    <div style={{ marginTop: 18 }}>
      <div style={{ padding: '0 16px 6px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <span className="ck-section-h">{title.split(' · ')[0]}</span>
        {title.includes('·') && (
          <span className="ck-mono" style={{ fontSize: 10, color: accent ? 'var(--red)' : 'var(--muted)' }}>· {title.split(' · ')[1]}</span>
        )}
      </div>
      {children}
    </div>
  );
}

// ─────────────────────────────────────────────
// Fixtures — assign venue + scorer per match, mark walkover
// ─────────────────────────────────────────────
function ManageFixtures() {
  const days = [
    { day: 'Today · Apr 30', items: [
      { round: 'QF1', a: 'LL', b: 'MT', time: '14:00', venue: 'Gaddafi B', scorer: 'Adeel Sheikh', status: 'live' },
      { round: 'QF2', a: 'KS', b: 'IT', time: '19:30', venue: 'Bagh-e-Jinnah', scorer: null, status: 'upcoming' },
    ]},
    { day: 'Tomorrow · May 1', items: [
      { round: 'QF3', a: 'GG', b: 'PR', time: '14:00', venue: 'Model Town', scorer: 'Imran T.', status: 'upcoming' },
      { round: 'QF4', a: 'FX', b: 'ML', time: '19:30', venue: null, scorer: null, status: 'upcoming' },
    ]},
    { day: 'May 3', items: [
      { round: 'SF1', a: null, b: null, time: '14:00', venue: 'Gaddafi B', scorer: null, status: 'upcoming' },
      { round: 'SF2', a: null, b: null, time: '19:30', venue: 'Gaddafi B', scorer: null, status: 'upcoming' },
    ]},
    { day: 'May 4', items: [
      { round: 'Final', a: null, b: null, time: '19:30', venue: 'Gaddafi B', scorer: null, status: 'upcoming' },
    ]},
  ];

  return (
    <div style={{ padding: '14px 0 8px' }}>
      {days.map((g, gi) => (
        <div key={gi} style={{ marginBottom: 14 }}>
          <div style={{ padding: '0 16px 8px', display: 'flex', alignItems: 'center', gap: 10 }}>
            <span className="ck-section-h">{g.day}</span>
            <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
            <button style={{ background: 'transparent', border: 'none', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)', fontWeight: 700, letterSpacing: '0.08em', cursor: 'pointer' }}>+ ADD</button>
          </div>
          <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
            {g.items.map((m, i) => <FixtureRow key={i} m={m} />)}
          </div>
        </div>
      ))}
    </div>
  );
}

function FixtureRow({ m }) {
  const live = m.status === 'live';
  const missingScorer = !m.scorer && m.a;       // matches with teams known but no scorer
  const missingVenue = !m.venue;
  const tbd = !m.a;
  return (
    <div style={{
      borderRadius: 14,
      border: live ? '1px solid transparent' : '1px solid var(--hairline)',
      background: live ? 'var(--ink)' : 'var(--surface)',
      color: live ? 'var(--paper)' : 'var(--ink)',
      padding: '12px 14px',
      opacity: tbd ? 0.85 : 1,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <span className="ck-mono" style={{ fontSize: 10, color: live ? 'rgba(255,255,255,0.6)' : 'var(--muted)' }}>
          {m.round} · {m.time}
        </span>
        {live ? (
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', color: 'oklch(0.85 0.13 80)' }}>● LIVE</span>
        ) : (
          <button style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: live ? 'var(--paper)' : 'var(--ink-2)' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
          </button>
        )}
      </div>

      {/* Teams */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        {m.a ? <CkTBadge id={m.a} size={22} /> : <Tbd />}
        <span style={{ fontSize: 13, fontWeight: 600, flex: 1, minWidth: 0 }}>
          {m.a ? TEAMS[m.a].name : 'TBD'}
        </span>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: live ? 'rgba(255,255,255,0.5)' : 'var(--muted)' }}>vs</span>
        <span style={{ fontSize: 13, fontWeight: 600, flex: 1, minWidth: 0, textAlign: 'right' }}>
          {m.b ? TEAMS[m.b].name : 'TBD'}
        </span>
        {m.b ? <CkTBadge id={m.b} size={22} /> : <Tbd />}
      </div>

      {/* Assignments */}
      <div style={{ display: 'flex', gap: 6 }}>
        <Pill icon="pin" missing={missingVenue} live={live} label={m.venue || 'Set venue'} />
        <Pill icon="pen" missing={missingScorer} live={live} label={m.scorer || 'Assign scorer'} />
      </div>
    </div>
  );
}

function Tbd() {
  return <div style={{ width: 22, height: 22, borderRadius: 6, background: 'var(--paper-2)', border: '1px dashed var(--line)', flexShrink: 0 }} />;
}

function Pill({ icon, missing, live, label }) {
  const bg = missing ? 'var(--red-soft)'
    : live ? 'rgba(255,255,255,0.10)' : 'var(--paper-2)';
  const fg = missing ? 'var(--red)'
    : live ? 'var(--paper)' : 'var(--ink-2)';
  const border = missing ? 'transparent' : (live ? 'transparent' : 'var(--hairline)');
  return (
    <button style={{
      flex: 1, padding: '7px 10px', borderRadius: 10,
      border: `1px solid ${border}`, background: bg, color: fg,
      fontFamily: 'Inter', fontSize: 11, fontWeight: 600, cursor: 'pointer',
      display: 'flex', alignItems: 'center', gap: 6, minWidth: 0,
    }}>
      {icon === 'pin' ? (
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 1 1 18 0Z"/><circle cx="12" cy="10" r="3"/></svg>
      ) : (
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4Z"/></svg>
      )}
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{label}</span>
    </button>
  );
}

// ─────────────────────────────────────────────
// Scorers — manage delegated scoring permissions
// ─────────────────────────────────────────────
function ManageScorers() {
  const scorers = [
    { mono: 'AS', name: 'Adeel Sheikh', scope: 'Tournament-wide', matches: 4, color: 'oklch(0.36 0.10 148)', live: true },
    { mono: 'IT', name: 'Imran Tariq',  scope: 'QF3, SF1',         matches: 2, color: 'oklch(0.62 0.19 28)' },
    { mono: 'HR', name: 'Hassan Raza',  scope: 'Backup',           matches: 0, color: 'oklch(0.40 0.14 320)' },
  ];
  const unassigned = [
    { round: 'QF2', when: 'Tomorrow 19:30' },
    { round: 'QF4', when: 'Tomorrow 19:30' },
    { round: 'SF1', when: 'May 3' },
    { round: 'SF2', when: 'May 3' },
    { round: 'Final', when: 'May 4' },
  ];

  return (
    <div style={{ padding: '14px 16px 0' }}>
      <div style={{ marginBottom: 10 }}>
        <div className="ck-section-h" style={{ marginBottom: 8 }}>Active scorers</div>
        <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
          {scorers.map((s, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
              <div style={{ width: 36, height: 36, borderRadius: 999, background: s.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13 }}>
                {s.mono}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                  {s.name}
                  {s.live && <span className="ck-chip live" style={{ padding: '1px 6px', fontSize: 8 }}>SCORING</span>}
                </div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>{s.scope} · {s.matches} match{s.matches===1?'':'es'}</div>
              </div>
              <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted)' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
              </button>
            </div>
          ))}
        </div>
      </div>

      <button style={{
        width: '100%', padding: 12, borderRadius: 12, marginBottom: 18,
        border: '1px dashed var(--line)', background: 'transparent',
        color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer',
      }}>+ Invite a scorer by phone</button>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Unassigned matches · {unassigned.length}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {unassigned.map((u, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', borderRadius: 10,
            background: 'oklch(0.97 0.03 28)', border: '1px solid oklch(0.88 0.05 28)',
          }}>
            <span className="ck-mono" style={{ fontSize: 11, fontWeight: 700, color: 'var(--red)' }}>{u.round}</span>
            <span style={{ flex: 1, fontSize: 12, color: 'var(--ink-2)' }}>{u.when}</span>
            <button style={{
              padding: '6px 10px', borderRadius: 8, border: 'none',
              background: 'var(--red)', color: 'white',
              fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.08em',
              cursor: 'pointer',
            }}>ASSIGN</button>
          </div>
        ))}
      </div>

      <div style={{
        marginTop: 18, padding: '12px 14px', borderRadius: 12,
        background: 'var(--paper-2)', border: '1px solid var(--hairline)',
        fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.5,
      }}>
        <span className="ck-mono" style={{ color: 'var(--muted)', letterSpacing: '0.08em' }}>HOW THIS WORKS · </span>
        Tournament-wide scorers can record any match. Match-level scorers are limited to the matches you assign. Edits to past balls are locked after 5 minutes — only you can override.
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Comms — invite link, broadcast, history
// ─────────────────────────────────────────────
function ManageComms() {
  const [copied, setCopied] = React.useState(false);
  const [draft, setDraft] = React.useState('');
  const link = 'circk.app/t/spring-cup-26';

  return (
    <div style={{ padding: '14px 16px' }}>
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Public invite</div>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: 10, borderRadius: 12,
        background: 'var(--paper-2)', border: '1px solid var(--hairline)',
      }}>
        <span style={{ flex: 1, fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--ink-2)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{link}</span>
        <button onClick={() => { setCopied(true); setTimeout(()=>setCopied(false), 1200); }} style={{
          padding: '7px 12px', borderRadius: 8, border: 'none',
          background: copied ? 'var(--green)' : 'var(--ink)',
          color: 'var(--paper)',
          fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em',
          cursor: 'pointer',
        }}>{copied ? 'COPIED' : 'COPY'}</button>
      </div>
      <div style={{ marginTop: 6, fontSize: 11, color: 'var(--muted)' }}>
        Anyone with this link can register a team (subject to your approval).
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Broadcast</div>
      <textarea
        value={draft}
        onChange={e => setDraft(e.target.value)}
        rows={3}
        placeholder="Announce something to all captains and players…"
        style={{
          width: '100%', padding: 12, borderRadius: 12,
          border: '1px solid var(--hairline)', background: 'var(--surface)',
          fontFamily: 'Inter', fontSize: 13, color: 'var(--ink)',
          resize: 'none', outline: 'none', boxSizing: 'border-box',
        }}
      />
      <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
        {['All captains', 'Approved teams', 'Scorers'].map((p, i) => (
          <span key={i} style={{
            fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 600, letterSpacing: '0.08em',
            padding: '4px 8px', borderRadius: 999,
            background: i === 0 ? 'var(--ink)' : 'var(--paper-2)',
            color: i === 0 ? 'var(--paper)' : 'var(--ink-2)',
            border: i === 0 ? 'none' : '1px solid var(--hairline)',
            cursor: 'pointer',
          }}>{p.toUpperCase()}</span>
        ))}
        <span style={{ flex: 1 }} />
        <button disabled={!draft.trim()} style={{
          padding: '7px 14px', borderRadius: 8, border: 'none',
          background: draft.trim() ? 'var(--ink)' : 'var(--paper-2)',
          color: draft.trim() ? 'var(--paper)' : 'var(--muted)',
          fontFamily: 'Inter', fontSize: 12, fontWeight: 600,
          cursor: draft.trim() ? 'pointer' : 'not-allowed',
        }}>Send</button>
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Past broadcasts</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {[
          { when: 'Apr 29 · 17:30', body: 'Fixture lock confirmed. QF1 toss at 13:45 sharp.', read: 47, total: 56 },
          { when: 'Apr 26 · 09:14', body: 'Squad sheets due tonight. Late entries pay Rs.500 surcharge.', read: 56, total: 56 },
          { when: 'Apr 22 · 14:02', body: 'Iqbal Ground confirmed for opening week. Lights from 6:30 pm.', read: 56, total: 56 },
        ].map((b, i) => (
          <div key={i} style={{ padding: 12, borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--surface)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em' }}>{b.when}</span>
              <span className="ck-mono" style={{ fontSize: 10, color: b.read === b.total ? 'var(--green)' : 'var(--muted)' }}>{b.read}/{b.total} read</span>
            </div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 5, lineHeight: 1.4 }}>{b.body}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Settings — meta, organizers, danger zone
// ─────────────────────────────────────────────
function ManageSettings() {
  const rows = [
    { l: 'Name',        v: 'Spring Cup ’26' },
    { l: 'Format',      v: 'Knockout · 8 teams' },
    { l: 'Match',       v: 'T20 · Leather' },
    { l: 'Powerplay',   v: '6 ov · 4 ov/bowler' },
    { l: 'Reg. closes', v: 'Apr 29 · CLOSED', muted: true },
    { l: 'Multi-team',  v: 'Not allowed' },
    { l: 'Tie-break',   v: 'NRR → H2H → Wins' },
  ];
  const orgs = [
    { mono: 'YO', name: 'You',          role: 'Owner',         color: 'var(--ink)' },
    { mono: 'AS', name: 'Adeel Sheikh', role: 'Co-organizer',  color: 'oklch(0.36 0.10 148)' },
  ];

  return (
    <div style={{ padding: '14px 16px 16px' }}>
      <div className="ck-section-h" style={{ marginBottom: 4 }}>Tournament details</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginTop: 8 }}>
        {rows.map((r, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none',
          }}>
            <span style={{ fontSize: 12, color: 'var(--muted)' }}>{r.l}</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600, color: r.muted ? 'var(--muted)' : 'var(--ink)' }}>{r.v}</span>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
            </div>
          </div>
        ))}
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Organizers</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden' }}>
        {orgs.map((o, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none',
          }}>
            <div style={{ width: 32, height: 32, borderRadius: 999, background: o.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 700 }}>{o.mono}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{o.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{o.role}</div>
            </div>
            {i > 0 && <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted)' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
            </button>}
          </div>
        ))}
      </div>
      <button style={{
        width: '100%', marginTop: 8, padding: 12, borderRadius: 12,
        border: '1px dashed var(--line)', background: 'transparent',
        color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer',
      }}>+ Add organizer</button>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8, color: 'var(--red)' }}>Danger zone</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button style={dangerBtn}>Pause registration</button>
        <button style={dangerBtn}>Cancel tournament</button>
      </div>
    </div>
  );
}

const dangerBtn = {
  padding: '12px 14px', borderRadius: 12,
  border: '1px solid oklch(0.88 0.05 28)', background: 'var(--paper)',
  color: 'var(--red)', fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
  textAlign: 'left', cursor: 'pointer',
};

window.CkTournamentManage = CkTournamentManage;

// TournamentManage.jsx — Creator-side tournament dashboard
// Shown after publishing a new tournament; also reachable as a "manage" view
// for any tournament where the user is an organizer.
//
// Sections:
//   1. Status pill + cover (live editing for hero copy)
//   2. Action queue: pending team approvals, scorer gaps, fixture conflicts
//   3. Quick stats: teams approved / matches scheduled / registration days left
//   4. Tabs: Teams (approve/reject), Schedule (assign scorer/venue), Comms, Settings
//   5. Sticky CTA: open public tournament page
//
// Exposed as window.CkTournamentManage.

const TM_STATUSES = {
  draft:        { label: 'DRAFT',         color: 'oklch(0.62 0.02 80)', bg: 'oklch(0.94 0.01 80)' },
  registration: { label: 'REGISTRATION',  color: 'oklch(0.36 0.10 148)', bg: 'oklch(0.93 0.06 148)' },
  upcoming:     { label: 'UPCOMING',      color: 'oklch(0.30 0.02 80)', bg: 'oklch(0.93 0.04 80)' },
  live:         { label: 'LIVE',          color: 'oklch(0.55 0.21 28)', bg: 'oklch(0.94 0.05 28)' },
  done:         { label: 'COMPLETE',      color: 'oklch(0.42 0.08 148)', bg: 'oklch(0.92 0.04 148)' },
};

function TmHeader({ form, status }) {
  const cover = form?.coverColor || 'oklch(0.62 0.19 28)';
  const name = form?.tournamentName || 'Spring Cup \'26';
  const fmt = form?.tournamentType === 'GroupKnockout' ? 'Groups → KO'
    : form?.tournamentType === 'Knockout' ? 'Knockout'
    : form?.tournamentType === 'League' ? 'League'
    : form?.tournamentType === 'RoundRobin' ? 'Round-robin'
    : 'Groups → KO';
  const overs = form?.oversPerInnings || 20;
  const ball = form?.ballType || 'Hard-ball';
  const s = TM_STATUSES[status] || TM_STATUSES.registration;

  return (
    <div style={{ position: 'relative', overflow: 'hidden' }}>
      {/* nav bar over cover */}
      <div style={{
        background: cover, color: 'var(--paper)', padding: '14px 18px 18px',
        position: 'relative', overflow: 'hidden',
      }}>
        {/* tiny pitch markings */}
        <svg width="280" height="280" viewBox="0 0 200 200" style={{ position: 'absolute', right: -90, bottom: -90, opacity: 0.13 }}>
          <ellipse cx="100" cy="100" rx="90" ry="58" stroke="white" strokeWidth="0.6" fill="none"/>
          <ellipse cx="100" cy="100" rx="50" ry="32" stroke="white" strokeWidth="0.6" fill="none"/>
          <rect x="92" y="68" width="16" height="64" stroke="white" strokeWidth="0.6" fill="none"/>
        </svg>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative' }}>
          <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'inherit' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: '0.14em', opacity: 0.85 }}>ORGANIZER VIEW</div>
          <button style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', color: 'inherit' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
          </button>
        </div>

        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 16, padding: '4px 10px', borderRadius: 999, background: 'rgba(255,255,255,0.18)', backdropFilter: 'blur(6px)' }}>
          <span style={{ width: 6, height: 6, borderRadius: 999, background: 'oklch(0.78 0.14 80)' }} />
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 600, letterSpacing: '0.1em' }}>{s.label}</span>
        </div>

        <div style={{ fontFamily: 'Inter Tight', fontSize: 28, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1.05, marginTop: 10, position: 'relative' }}>
          {name}
        </div>
        <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4, position: 'relative' }}>
          {fmt} · T{overs} · {ball}
        </div>
      </div>
    </div>
  );
}

function StatTriple({ form, approvedCount }) {
  const min = form?.minTeams || 8;
  const max = form?.maxTeams || 16;
  const matches = form?.tournamentType === 'GroupKnockout' ? max + 6
    : form?.tournamentType === 'Knockout' ? max - 1
    : form?.tournamentType === 'League' ? max * (max - 1)
    : max * (max - 1) / 2;
  const days = 9; // mock countdown
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', borderTop: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
      {[
        { l: 'TEAMS', v: approvedCount, sub: `of ${max} · need ${min}` },
        { l: 'MATCHES', v: matches, sub: 'scheduled' },
        { l: 'REG. CLOSES', v: days, sub: 'days left' },
      ].map((s, i) => (
        <div key={i} style={{ padding: '14px 14px', borderLeft: i ? '1px solid var(--hairline)' : 'none' }}>
          <div style={{ fontSize: 9, fontFamily: 'JetBrains Mono', color: 'var(--muted)', letterSpacing: '0.08em' }}>{s.l}</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', marginTop: 2 }}>{s.v}</div>
          <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{s.sub}</div>
        </div>
      ))}
    </div>
  );
}

function ActionQueue({ pending, conflicts, scorerGaps, onJump }) {
  const items = [
    pending > 0 && {
      key: 'approve', tone: 'amber',
      title: `${pending} team${pending === 1 ? '' : 's'} waiting for approval`,
      sub: 'Review squads, captains and registration fees',
      cta: 'Review',
      target: 'teams',
      icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m9 11 3 3 8-8"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>,
    },
    conflicts > 0 && {
      key: 'conflict', tone: 'red',
      title: `${conflicts} schedule conflict${conflicts === 1 ? '' : 's'}`,
      sub: 'Two matches share the same venue and slot',
      cta: 'Resolve',
      target: 'schedule',
      icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z"/><path d="M12 9v4M12 17h.01"/></svg>,
    },
    scorerGaps > 0 && {
      key: 'scorer', tone: 'plain',
      title: `${scorerGaps} match${scorerGaps === 1 ? '' : 'es'} without a scorer`,
      sub: 'Auto-assign or invite a volunteer',
      cta: 'Assign',
      target: 'schedule',
      icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4Z"/></svg>,
    },
  ].filter(Boolean);

  if (items.length === 0) {
    return (
      <div style={{ margin: '14px 16px', padding: '14px 16px', borderRadius: 12, background: 'var(--green-soft)', border: '1px solid oklch(0.86 0.05 148)', display: 'flex', alignItems: 'center', gap: 12 }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="oklch(0.36 0.10 148)" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: 'oklch(0.30 0.10 148)' }}>All clear</div>
          <div style={{ fontSize: 11, color: 'oklch(0.36 0.10 148)' }}>No actions need your attention right now</div>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: '14px 16px 4px' }}>
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Needs you · {items.length}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map(it => {
          const bg = it.tone === 'amber' ? 'oklch(0.96 0.05 90)' : it.tone === 'red' ? 'oklch(0.96 0.04 28)' : 'var(--paper-2)';
          const fg = it.tone === 'amber' ? 'oklch(0.42 0.12 90)' : it.tone === 'red' ? 'oklch(0.45 0.18 28)' : 'var(--ink)';
          return (
            <button key={it.key} onClick={() => onJump(it.target)} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
              borderRadius: 12, border: '1px solid ' + (it.tone === 'amber' ? 'oklch(0.86 0.05 90)' : it.tone === 'red' ? 'oklch(0.86 0.05 28)' : 'var(--hairline)'),
              background: bg, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: fg, flexShrink: 0 }}>
                {it.icon}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: fg, letterSpacing: '-0.01em' }}>{it.title}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{it.sub}</div>
              </div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', color: fg }}>{it.cta.toUpperCase()} →</div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Teams tab — approve / reject pending registrations
// ─────────────────────────────────────────────
function TeamsTab({ form, teams, setTeams, approvedCount }) {
  const min = form?.minTeams || 8;
  const max = form?.maxTeams || 16;

  const setStatus = (id, status) => {
    setTeams(prev => prev.map(t => t.id === id ? { ...t, status } : t));
  };

  const pendingTeams = teams.filter(t => t.status === 'pending');
  const approvedTeams = teams.filter(t => t.status === 'approved');
  const rejectedTeams = teams.filter(t => t.status === 'rejected');

  return (
    <div style={{ padding: '4px 0 16px' }}>
      {/* Capacity bar */}
      <div style={{ padding: '14px 16px 6px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700 }}>Squad capacity</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600 }}>{approvedCount}<span style={{ color: 'var(--muted)' }}>/{max}</span></div>
        </div>
        <div style={{ height: 8, borderRadius: 999, background: 'var(--paper-2)', overflow: 'hidden', position: 'relative' }}>
          <div style={{ position: 'absolute', inset: 0, width: `${(approvedCount / max) * 100}%`, background: approvedCount >= min ? 'oklch(0.56 0.13 148)' : 'oklch(0.78 0.14 80)', transition: 'width 0.2s' }} />
          {/* min marker */}
          <div style={{ position: 'absolute', top: -2, bottom: -2, left: `${(min / max) * 100}%`, width: 2, background: 'var(--ink)' }} />
        </div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 6 }}>
          {approvedCount >= min
            ? <>Minimum reached. Tournament can start.</>
            : <>Need <strong style={{ color: 'var(--ink)' }}>{min - approvedCount} more</strong> approved to start. Black tick = minimum.</>}
        </div>
      </div>

      {/* Pending */}
      {pendingTeams.length > 0 && (
        <div style={{ marginTop: 14 }}>
          <div style={{ padding: '0 16px 8px', display: 'flex', alignItems: 'center', gap: 8 }}>
            <div className="ck-section-h">Pending approval</div>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, padding: '2px 7px', borderRadius: 999, background: 'oklch(0.96 0.05 90)', color: 'oklch(0.42 0.12 90)', letterSpacing: '0.06em' }}>
              {pendingTeams.length}
            </span>
          </div>
          {pendingTeams.map(t => (
            <div key={t.id} style={{ padding: '14px 16px', borderTop: '1px solid var(--hairline)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 40, height: 40, borderRadius: 10, background: t.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, flexShrink: 0 }}>
                  {t.mono}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>{t.name}</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{t.captain} · {t.players} players · {t.applied}</div>
                </div>
                {t.fee && (
                  <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, padding: '3px 8px', borderRadius: 999, background: t.feePaid ? 'var(--green-soft)' : 'oklch(0.96 0.05 28)', color: t.feePaid ? 'oklch(0.36 0.10 148)' : 'oklch(0.45 0.18 28)', fontWeight: 600 }}>
                    {t.feePaid ? 'PAID' : 'UNPAID'}
                  </div>
                )}
              </div>
              <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                <button onClick={() => setStatus(t.id, 'approved')} style={{ flex: 1, padding: '9px 0', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontWeight: 600, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer' }}>Approve</button>
                <button onClick={() => setStatus(t.id, 'rejected')} style={{ padding: '9px 16px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink-2)', fontWeight: 500, fontSize: 13, fontFamily: 'inherit', cursor: 'pointer' }}>Reject</button>
                <button style={{ padding: '9px 12px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="2"><circle cx="12" cy="12" r="9"/><path d="M9.1 9a3 3 0 1 1 5.8 1c0 2-3 2-3 4M12 17h.01"/></svg>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Approved */}
      <div style={{ marginTop: pendingTeams.length > 0 ? 18 : 14 }}>
        <div style={{ padding: '0 16px 8px' }}>
          <div className="ck-section-h">Approved · {approvedTeams.length}</div>
        </div>
        {approvedTeams.length === 0 && (
          <div style={{ padding: '18px 16px', fontSize: 12, color: 'var(--muted)', borderTop: '1px solid var(--hairline)' }}>No teams approved yet.</div>
        )}
        {approvedTeams.map(t => (
          <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--hairline)' }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: t.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, flexShrink: 0 }}>
              {t.mono}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{t.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>{t.captain} · {t.players} players</div>
            </div>
            <button onClick={() => setStatus(t.id, 'pending')} style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', color: 'var(--muted)' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 12a9 9 0 1 0 9-9"/><path d="M3 4v5h5"/></svg>
            </button>
          </div>
        ))}
      </div>

      {rejectedTeams.length > 0 && (
        <div style={{ marginTop: 14 }}>
          <div style={{ padding: '0 16px 8px' }}>
            <div className="ck-section-h" style={{ color: 'var(--muted)' }}>Rejected · {rejectedTeams.length}</div>
          </div>
          {rejectedTeams.map(t => (
            <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 16px', borderTop: '1px solid var(--hairline)', opacity: 0.55 }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--paper-2)', color: 'var(--muted)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700, textDecoration: 'line-through' }}>
                {t.mono}
              </div>
              <div style={{ flex: 1, fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 500, color: 'var(--ink-2)' }}>{t.name}</div>
              <button onClick={() => setStatus(t.id, 'pending')} style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.06em', background: 'transparent', border: 'none', color: 'var(--muted)', cursor: 'pointer' }}>UNDO</button>
            </div>
          ))}
        </div>
      )}

      <div style={{ padding: '18px 16px 0' }}>
        <button style={{ width: '100%', padding: 12, borderRadius: 10, border: '1px dashed var(--hairline)', background: 'transparent', color: 'var(--ink-2)', fontFamily: 'inherit', fontWeight: 500, fontSize: 13, cursor: 'pointer' }}>
          + Invite a team manually
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Schedule tab — fixtures with scorer / venue assignment
// ─────────────────────────────────────────────
function ScheduleTab() {
  const [filter, setFilter] = React.useState('All');
  const fixtures = [
    { id: 'f1', day: 'Sat May 3', time: '4:00 pm', match: 'Lions vs Eagles', venue: 'Iqbal Ground', scorer: 'Adeel Sheikh', status: 'ok' },
    { id: 'f2', day: 'Sat May 3', time: '4:00 pm', match: 'Defenders vs Mohalla Kings', venue: 'Iqbal Ground', scorer: '—', status: 'conflict' },
    { id: 'f3', day: 'Sun May 4', time: '4:00 pm', match: 'DHA United vs City Stars', venue: 'Iqbal Ground', scorer: '—', status: 'no-scorer' },
    { id: 'f4', day: 'Sun May 4', time: '6:30 pm', match: 'Galle Boys vs Friends XI', venue: 'Cantt Park', scorer: 'Hassan R.', status: 'ok' },
    { id: 'f5', day: 'Sat May 10', time: '4:00 pm', match: 'TBD vs TBD', venue: 'Iqbal Ground', scorer: '—', status: 'tbd' },
  ];
  const filtered = filter === 'All' ? fixtures
    : filter === 'Conflicts' ? fixtures.filter(f => f.status === 'conflict')
    : filter === 'No scorer' ? fixtures.filter(f => f.status === 'no-scorer' || f.status === 'tbd')
    : fixtures;

  const groupByDay = filtered.reduce((acc, f) => {
    if (!acc[f.day]) acc[f.day] = [];
    acc[f.day].push(f);
    return acc;
  }, {});

  return (
    <div style={{ padding: '4px 0 16px' }}>
      <div style={{ display: 'flex', gap: 6, padding: '14px 16px 0', overflowX: 'auto' }}>
        {['All', 'Conflicts', 'No scorer'].map(f => (
          <button key={f} onClick={() => setFilter(f)} style={{
            flex: 'none', padding: '6px 12px', borderRadius: 999,
            background: filter === f ? 'var(--ink)' : 'var(--paper-2)',
            color: filter === f ? 'var(--paper)' : 'var(--ink-2)',
            border: '1px solid ' + (filter === f ? 'var(--ink)' : 'var(--hairline)'),
            fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
          }}>{f}</button>
        ))}
      </div>

      {Object.entries(groupByDay).map(([day, items]) => (
        <div key={day} style={{ marginTop: 14 }}>
          <div style={{ padding: '8px 16px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em', textTransform: 'uppercase', fontWeight: 600 }}>{day}</div>
            <button style={{ background: 'transparent', border: 'none', fontSize: 11, fontFamily: 'JetBrains Mono', color: 'var(--ink-2)', cursor: 'pointer', letterSpacing: '0.06em', fontWeight: 600 }}>+ ADD</button>
          </div>
          {items.map(f => {
            const conflict = f.status === 'conflict';
            const noScorer = f.status === 'no-scorer';
            return (
              <div key={f.id} style={{
                margin: '0 16px 8px', padding: '12px 14px',
                borderRadius: 12, border: '1px solid ' + (conflict ? 'oklch(0.86 0.05 28)' : noScorer ? 'oklch(0.86 0.05 90)' : 'var(--hairline)'),
                background: conflict ? 'oklch(0.97 0.02 28)' : noScorer ? 'oklch(0.98 0.02 90)' : 'var(--paper)',
              }}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, letterSpacing: '-0.01em' }}>{f.match}</div>
                  <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{f.time}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14, fontSize: 11, color: 'var(--ink-2)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 1 1 18 0Z"/><circle cx="12" cy="10" r="3"/></svg>
                    {f.venue}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, color: f.scorer === '—' ? 'oklch(0.45 0.18 28)' : 'inherit' }}>
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4Z"/></svg>
                    {f.scorer}
                  </div>
                </div>
                {conflict && (
                  <div style={{ marginTop: 8, padding: '8px 10px', borderRadius: 8, background: 'oklch(0.94 0.04 28)', display: 'flex', alignItems: 'center', gap: 8 }}>
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="oklch(0.45 0.18 28)" strokeWidth="2.4"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z"/><path d="M12 9v4M12 17h.01"/></svg>
                    <div style={{ flex: 1, fontSize: 11, color: 'oklch(0.45 0.18 28)' }}>Same venue & slot as Lions vs Eagles</div>
                    <button style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.06em', background: 'oklch(0.55 0.21 28)', color: 'white', border: 'none', padding: '5px 10px', borderRadius: 6, cursor: 'pointer' }}>RESOLVE</button>
                  </div>
                )}
                {noScorer && (
                  <button style={{ marginTop: 8, width: '100%', padding: '8px 10px', borderRadius: 8, border: '1px solid oklch(0.86 0.05 90)', background: 'var(--paper)', fontFamily: 'inherit', fontSize: 11, fontWeight: 600, color: 'oklch(0.42 0.12 90)', cursor: 'pointer' }}>
                    Assign scorer
                  </button>
                )}
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────
// Comms tab — broadcast, invite link, organizer chat
// ─────────────────────────────────────────────
function CommsTab({ form }) {
  const [copied, setCopied] = React.useState(false);
  const link = `circk.app/t/${(form?.tournamentName || 'spring-cup').toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 20)}`;

  return (
    <div style={{ padding: '14px 16px 16px' }}>
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Invite link</div>
      <div style={{ display: 'flex', gap: 6, padding: 10, borderRadius: 12, background: 'var(--paper-2)', border: '1px solid var(--hairline)', alignItems: 'center' }}>
        <div style={{ flex: 1, fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--ink-2)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{link}</div>
        <button onClick={() => { setCopied(true); setTimeout(() => setCopied(false), 1200); }} style={{
          fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.08em',
          padding: '6px 12px', borderRadius: 8, border: 'none',
          background: copied ? 'oklch(0.56 0.13 148)' : 'var(--ink)', color: 'var(--paper)',
          cursor: 'pointer',
        }}>{copied ? 'COPIED' : 'COPY'}</button>
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Broadcast</div>
      <textarea
        placeholder="Announce something to all teams and players…"
        rows={3}
        style={{
          width: '100%', padding: 12, borderRadius: 10,
          border: '1px solid var(--hairline)', background: 'var(--paper)',
          fontFamily: 'inherit', fontSize: 13, resize: 'none', outline: 'none', color: 'var(--ink)',
          boxSizing: 'border-box',
        }}
      />
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 8 }}>
        <div style={{ fontSize: 11, color: 'var(--muted)' }}>Sends to all approved captains + organizers</div>
        <button style={{ padding: '8px 14px', borderRadius: 8, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'inherit', fontWeight: 600, fontSize: 12, cursor: 'pointer' }}>Send</button>
      </div>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Recent broadcasts</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {[
          { t: 'Apr 26 · 9:14 am', body: 'Reminder: Squad sheets due tonight. Late entries pay Rs.500 surcharge.' },
          { t: 'Apr 22 · 2:02 pm', body: 'Iqbal Ground confirmed for opening week. Lights from 6:30 pm onwards.' },
        ].map((b, i) => (
          <div key={i} style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{b.t}</div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.45 }}>{b.body}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Settings tab — meta, organizers, danger zone
// ─────────────────────────────────────────────
function ManageSettingsTab({ form }) {
  return (
    <div style={{ padding: '14px 16px 16px' }}>
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Tournament details</div>
      {[
        { l: 'Name', v: form?.tournamentName || 'Spring Cup \'26' },
        { l: 'Format', v: form?.tournamentType === 'GroupKnockout' ? 'Groups → Knockout' : (form?.tournamentType || 'Groups → KO') },
        { l: 'Match length', v: `T${form?.oversPerInnings || 20}` },
        { l: 'Ball type', v: form?.ballType || 'Hard-ball' },
        { l: 'Registration deadline', v: form?.registrationDeadline || 'May 1, 2026' },
      ].map((row, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
          <div style={{ fontSize: 12, color: 'var(--muted)' }}>{row.l}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{row.v}</div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
          </div>
        </div>
      ))}

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8 }}>Organizers</div>
      {[
        { name: 'You', sub: 'Owner · all permissions', mono: 'YO', color: 'oklch(0.18 0.02 80)' },
        { name: 'Adeel Sheikh', sub: 'Co-organizer · scoring', mono: 'AS', color: 'oklch(0.62 0.19 28)' },
      ].map((p, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
          <div style={{ width: 36, height: 36, borderRadius: 999, background: p.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700 }}>{p.mono}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{p.name}</div>
            <div style={{ fontSize: 11, color: 'var(--muted)' }}>{p.sub}</div>
          </div>
          {i > 0 && <button style={{ background: 'transparent', border: 'none', color: 'var(--muted)', padding: 4, cursor: 'pointer' }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
          </button>}
        </div>
      ))}
      <button style={{ width: '100%', marginTop: 10, padding: 11, borderRadius: 10, border: '1px dashed var(--hairline)', background: 'transparent', color: 'var(--ink-2)', fontFamily: 'inherit', fontWeight: 500, fontSize: 13, cursor: 'pointer' }}>
        + Add organizer
      </button>

      <div className="ck-section-h" style={{ marginTop: 22, marginBottom: 8, color: 'oklch(0.55 0.21 28)' }}>Danger zone</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button style={{ padding: '12px 14px', borderRadius: 10, border: '1px solid oklch(0.86 0.05 28)', background: 'var(--paper)', textAlign: 'left', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, color: 'oklch(0.45 0.18 28)', cursor: 'pointer' }}>Pause registration</button>
        <button style={{ padding: '12px 14px', borderRadius: 10, border: '1px solid oklch(0.86 0.05 28)', background: 'var(--paper)', textAlign: 'left', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, color: 'oklch(0.45 0.18 28)', cursor: 'pointer' }}>Cancel tournament</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// Root
// ─────────────────────────────────────────────
function CkTournamentManage() {
  // Pull form from window so AppShell can hand it off after Create publishes.
  const form = (typeof window !== 'undefined' && window.__ckLastTournament) || null;
  const status = (form && form.status) || 'registration';

  const [tab, setTab] = React.useState('overview');
  const [teams, setTeams] = React.useState(() => ([
    { id: 'tm1', name: 'Lahore Lions',     captain: 'Adeel Sheikh',  players: 14, applied: 'today',     status: 'pending',  fee: true,  feePaid: true,  mono: 'LL', color: 'oklch(0.62 0.19 28)' },
    { id: 'tm2', name: 'Defenders XI',     captain: 'Bilal Khan',    players: 13, applied: 'today',     status: 'pending',  fee: true,  feePaid: false, mono: 'DX', color: 'oklch(0.36 0.10 148)' },
    { id: 'tm3', name: 'Mohalla Kings',    captain: 'Hassan Raza',   players: 12, applied: 'yesterday', status: 'pending',  fee: true,  feePaid: true,  mono: 'MK', color: 'oklch(0.78 0.14 80)' },
    { id: 'tm4', name: 'DHA United',       captain: 'Faraz Ali',     players: 14, applied: '2d ago',    status: 'approved', fee: true,  feePaid: true,  mono: 'DU', color: 'oklch(0.55 0.18 250)' },
    { id: 'tm5', name: 'City Stars',       captain: 'Imran Tariq',   players: 11, applied: '2d ago',    status: 'approved', fee: true,  feePaid: true,  mono: 'CS', color: 'oklch(0.50 0.14 320)' },
    { id: 'tm6', name: 'Galle Boys',       captain: 'Saad Mahmood',  players: 13, applied: '3d ago',    status: 'approved', fee: true,  feePaid: true,  mono: 'GB', color: 'oklch(0.45 0.16 200)' },
    { id: 'tm7', name: 'Friends XI',       captain: 'Tariq Mehmood', players: 10, applied: '3d ago',    status: 'rejected', fee: true,  feePaid: false, mono: 'FX', color: 'oklch(0.55 0.10 50)' },
  ]));

  const approvedCount = teams.filter(t => t.status === 'approved').length;
  const pendingCount = teams.filter(t => t.status === 'pending').length;

  const TABS = [
    { id: 'overview', label: 'Overview' },
    { id: 'teams',    label: 'Teams', badge: pendingCount },
    { id: 'schedule', label: 'Schedule' },
    { id: 'comms',    label: 'Comms' },
    { id: 'settings', label: 'Settings' },
  ];

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TmHeader form={form} status={status} />

      {/* Tabs */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--hairline)', overflowX: 'auto', flexShrink: 0, background: 'var(--paper)' }}>
        {TABS.map(t => {
          const active = tab === t.id;
          return (
            <button key={t.id} onClick={() => setTab(t.id)} style={{
              flex: 'none', padding: '12px 14px',
              background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              color: active ? 'var(--ink)' : 'var(--muted)',
              fontSize: 13, fontWeight: 600,
              borderBottom: active ? '2px solid var(--ink)' : '2px solid transparent',
              marginBottom: -1, display: 'flex', alignItems: 'center', gap: 6,
            }}>
              {t.label}
              {t.badge > 0 && (
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, padding: '2px 6px', borderRadius: 999, background: active ? 'var(--ink)' : 'oklch(0.96 0.05 90)', color: active ? 'var(--paper)' : 'oklch(0.42 0.12 90)' }}>
                  {t.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {tab === 'overview' && (
          <>
            <StatTriple form={form} approvedCount={approvedCount} />
            <ActionQueue
              pending={pendingCount}
              conflicts={1}
              scorerGaps={2}
              onJump={setTab}
            />

            <div style={{ padding: '14px 16px 4px' }}>
              <div className="ck-section-h" style={{ marginBottom: 8 }}>Recent activity</div>
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                {[
                  { who: 'Lahore Lions', what: 'registered with 14 players', when: '2h ago', mono: 'LL', color: 'oklch(0.62 0.19 28)' },
                  { who: 'Adeel Sheikh', what: 'accepted co-organizer invite', when: '4h ago', mono: 'AS', color: 'oklch(0.36 0.10 148)' },
                  { who: 'Defenders XI', what: 'submitted squad (fee unpaid)', when: '6h ago', mono: 'DX', color: 'oklch(0.36 0.10 148)' },
                  { who: 'Iqbal Ground', what: 'confirmed booking for opening week', when: 'Yesterday', mono: 'IG', color: 'oklch(0.30 0.02 80)' },
                ].map((a, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 0', borderTop: i ? '1px solid var(--hairline)' : '1px solid var(--hairline)' }}>
                    <div style={{ width: 28, height: 28, borderRadius: 8, background: a.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 700 }}>{a.mono}</div>
                    <div style={{ flex: 1, fontSize: 13, color: 'var(--ink-2)' }}>
                      <strong style={{ color: 'var(--ink)', fontWeight: 600 }}>{a.who}</strong> {a.what}
                    </div>
                    <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{a.when}</div>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ height: 16 }} />
          </>
        )}

        {tab === 'teams' && <TeamsTab form={form} teams={teams} setTeams={setTeams} approvedCount={approvedCount} />}
        {tab === 'schedule' && <ScheduleTab />}
        {tab === 'comms' && <CommsTab form={form} />}
        {tab === 'settings' && <ManageSettingsTab form={form} />}
      </div>

      {/* Sticky CTA */}
      <div style={{ padding: '10px 16px 14px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 8, flexShrink: 0 }}>
        <button onClick={() => window.__ckNav && window.__ckNav.push('tournament')} style={{ flex: 1, padding: '12px 14px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>
          View public page
        </button>
        <button style={{ padding: '12px 16px', borderRadius: 10, border: 'none', background: 'var(--ink)', color: 'var(--paper)', fontFamily: 'inherit', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>
          Share
        </button>
      </div>
    </div>
  );
}

window.CkTournamentManage = CkTournamentManage;

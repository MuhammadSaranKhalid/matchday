// tp-tabs.jsx — tab content for TeamPage

(function () {

const { tpMono: mono, tpPlayerRow: PlayerRow } = window;

const ink = 'var(--ink)', ink2 = 'var(--ink-2)', muted = 'var(--muted)';
const paper = 'var(--paper)', paper2 = 'var(--paper-2)', surf = 'var(--surface)';
const hair = 'var(--hairline)', line = 'var(--line)';
const red = 'var(--red)', redS = 'var(--red-soft)';
const green = 'var(--green)', amber = 'var(--amber)', cream = 'var(--cream)';

function LivePulse({ size = 5 }) {
  return <span style={{ width: size, height: size, borderRadius: 999, background: 'currentColor', animation: 'ck-pulse 1.4s infinite', flexShrink: 0 }} />;
}

function SquadTab({ team, viewer, viewerIs }) {
  if (!team.squad || team.squad.length === 0) {
    return <div style={{ padding: '26px 18px', textAlign: 'center', color: muted, fontSize: 13 }}>Squad still being built.</div>;
  }
  if (team.squad.length === 1 && viewer === 'owner') {
    return (
      <div style={{ padding: '14px 16px 0' }}>
        <div style={{ padding: '24px 18px', textAlign: 'center', borderRadius: 14, background: paper2, border: '1px dashed ' + line, marginBottom: 18 }}>
          <div style={{
            width: 64, height: 64, margin: '0 auto 12px', borderRadius: 16,
            background: paper, border: '1px solid ' + hair,
            display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
          }}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="9" cy="9" r="4"/><path d="M2 21c0-4 3-6 7-6s7 2 7 6"/><path d="M19 8v6M16 11h6"/>
            </svg>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em' }}>It's just you so far.</div>
          <div style={{ fontSize: 12, color: ink2, marginTop: 6, lineHeight: 1.5, maxWidth: 260, margin: '6px auto 0' }}>
            Build {team.name}'s squad — search registered players, send SMS invites, or add unclaimed placeholders.
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { primary: true, t: 'Search registered players', s: 'Find someone already on MatchDay',
              icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg> },
            { t: 'Add as unclaimed', s: 'Just a name — they can claim later',
              icon: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/></svg> },
          ].map((p, i) => (
            <button key={i} style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
              background: p.primary ? ink : paper, color: p.primary ? paper : ink,
              border: '1px solid ' + (p.primary ? ink : hair),
              borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8, flexShrink: 0,
                background: p.primary ? 'rgba(255,255,255,0.14)' : paper2,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{p.icon}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 700, letterSpacing: '-0.01em' }}>{p.t}</div>
                <div style={{ fontSize: 11, opacity: p.primary ? 0.72 : 1, color: p.primary ? paper : muted, marginTop: 2 }}>{p.s}</div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ opacity: 0.6 }}><path d="M9 18l6-6-6-6"/></svg>
            </button>
          ))}
        </div>
        <div style={{ ...mono, padding: '18px 4px 8px' }}>You</div>
        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12 }}>
          <PlayerRow p={team.squad[0]} primary={team.primary} top viewerIs={viewerIs} />
        </div>
      </div>
    );
  }

  if (team.privacy === 'Private' && (viewer === 'stranger' || viewer === 'stranger-private')) {
    return (
      <div style={{ padding: '34px 24px', textAlign: 'center' }}>
        <div style={{ width: 52, height: 52, margin: '0 auto 12px', borderRadius: 13, background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={ink2} strokeWidth="1.8"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 1 1 8 0v3"/></svg>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em' }}>Private squad</div>
        <div style={{ fontSize: 12.5, color: muted, marginTop: 6, lineHeight: 1.5, maxWidth: 260, margin: '8px auto 0' }}>
          Only members can see the roster. Request to join — the captain will review.
        </div>
        <button style={{ marginTop: 16, padding: '11px 22px', borderRadius: 11, border: 'none', background: ink, color: paper, fontFamily: 'Inter', fontWeight: 700, fontSize: 13, cursor: 'pointer' }}>Request to join</button>
      </div>
    );
  }

  const lead = team.squad.filter(p => ['Captain', 'Vice-Captain', 'Wicket-Keeper'].includes(p.role));
  const players = team.squad.filter(p => p.role === 'Player');
  return (
    <div style={{ padding: '14px 0' }}>
      <div style={{ padding: '0 16px', display: 'flex', gap: 6, overflowX: 'auto', marginBottom: 4 }}>
        {['All', 'Batters', 'Bowlers', 'All-rounders', 'Keeper'].map((f, i) => (
          <button key={f} style={{
            flex: 'none', padding: '7px 12px', borderRadius: 999, fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
            border: i === 0 ? 'none' : '1px solid ' + hair,
            background: i === 0 ? ink : surf, color: i === 0 ? paper : ink2,
          }}>{f}</button>
        ))}
      </div>
      <div style={{ padding: '12px 16px 6px', display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={mono}>Captaincy & keeper</span>
        <span style={{ ...mono, fontSize: 10, color: muted }}>· {lead.length}</span>
      </div>
      {lead.map((p, i) => <PlayerRow key={p.n} p={p} primary={team.primary} top={i === 0} viewerIs={viewerIs} />)}
      <div style={{ padding: '14px 16px 6px', display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={mono}>Players</span>
        <span style={{ ...mono, fontSize: 10, color: muted }}>· {players.length}</span>
      </div>
      {players.map((p, i) => <PlayerRow key={p.n} p={p} primary={team.primary} top={i === 0} viewerIs={viewerIs} />)}
    </div>
  );
}

function AddPlayerRow({ top }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
      borderTop: top ? 'none' : '1px solid ' + hair,
      cursor: 'pointer', background: paper,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, flexShrink: 0,
        background: 'transparent', border: '1px dashed ' + line, color: ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600, color: ink }}>Add player</div>
        <div style={{ fontSize: 11, color: muted, marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>
          Search registered · or add unclaimed
        </div>
      </div>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2" strokeLinecap="round"><polyline points="9 6 15 12 9 18"/></svg>
    </div>
  );
}

function CapacityFooter({ team }) {
  const cap = team.maxSize || 25;
  const total = team.squad.length;
  const pct = Math.round((total / cap) * 100);
  return (
    <div style={{ padding: '16px 16px 4px' }}>
      <div style={{ padding: 14, background: paper2, borderRadius: 12 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
          <span style={{ ...mono }}>SQUAD CAPACITY</span>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, letterSpacing: '-0.02em', color: ink, fontVariantNumeric: 'tabular-nums' }}>
            {total} <span style={{ color: muted, fontWeight: 500 }}>of {cap}</span>
          </span>
        </div>
        <div style={{ height: 5, borderRadius: 999, background: paper, overflow: 'hidden' }}>
          <div style={{ width: pct + '%', height: '100%', background: ink, transition: 'width 0.3s' }} />
        </div>
        <div style={{ fontSize: 11, color: muted, marginTop: 8, lineHeight: 1.4 }}>
          {total < 6 ? `Need at least 6 to schedule matches. ${6 - total} to go.` :
           total < 11 ? `${total} players · ${11 - total} more to lock an XI.` :
           total < 18 ? `Solid roster. Room for ${cap - total} more.` :
           total < cap ? `Nearly full · ${cap - total} slots left.` :
           `Squad at capacity. Bump the limit in Settings.`}
        </div>
      </div>
    </div>
  );
}

function MatchesTab({ team }) {
  if (!team.upcoming && !team.recent) {
    return (
      <div style={{ padding: '36px 18px', textAlign: 'center', color: muted, fontSize: 13 }}>
        <div style={{ width: 52, height: 52, margin: '0 auto 12px', borderRadius: 13, background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="1.8"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, letterSpacing: '-0.02em', color: ink }}>No matches yet</div>
        <div style={{ marginTop: 6, lineHeight: 1.5, maxWidth: 240, margin: '6px auto 0' }}>Schedule a friendly or register for a tournament.</div>
      </div>
    );
  }
  return (
    <div style={{ padding: '14px 0' }}>
      {team.form && (
        <div style={{ padding: '0 16px 16px' }}>
          <div style={{ ...mono, marginBottom: 8 }}>Last 8</div>
          <div style={{ display: 'flex', gap: 6 }}>
            {team.form.map((r, i) => (
              <div key={i} style={{
                width: 28, height: 28, borderRadius: 8,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700,
                color: r === 'T' ? ink2 : '#fff',
                background: r === 'W' ? green : r === 'L' ? red : cream,
              }}>{r}</div>
            ))}
          </div>
        </div>
      )}
      {team.tournament && (
        <div style={{ padding: '0 16px 16px' }}>
          <div style={{ ...mono, marginBottom: 8 }}>In tournament</div>
          <div style={{
            padding: '14px', borderRadius: 14, position: 'relative', overflow: 'hidden',
            background: 'linear-gradient(135deg, ' + team.primary + ' 0%, oklch(0.22 0.05 80) 100%)', color: '#fff',
          }}>
            <div style={{ ...mono, fontSize: 9, color: 'rgba(255,255,255,0.7)' }}>{team.tournament.kind.toUpperCase()}</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em', marginTop: 4 }}>{team.tournament.name}</div>
            <div style={{ display: 'flex', gap: 10, marginTop: 12, fontSize: 12, color: 'rgba(255,255,255,0.85)', alignItems: 'center', flexWrap: 'wrap' }}>
              <span style={{ ...mono, fontSize: 9, padding: '3px 7px', borderRadius: 4, background: 'rgba(255,255,255,0.16)', color: '#fff' }}>STAGE · {team.tournament.stage.toUpperCase()}</span>
              <span>{team.tournament.played}/{team.tournament.total} played</span>
              <span>·</span>
              <span>{team.tournament.next}</span>
            </div>
          </div>
        </div>
      )}
      {team.upcoming && team.upcoming.length > 0 && (
        <>
          <div style={{ padding: '0 16px 6px' }}><span style={mono}>Upcoming · {team.upcoming.length}</span></div>
          <div>
            {team.upcoming.map((m, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid ' + hair }}>
                <div style={{ width: 44, textAlign: 'center', flexShrink: 0 }}>
                  <div style={{ ...mono, fontSize: 9 }}>{m.date.split(' · ')[0].toUpperCase()}</div>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, marginTop: 2 }}>{m.date.split(' · ')[1] || ''}</div>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>vs {m.vs}</div>
                  <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{m.round} · {m.venue}</div>
                </div>
                {m.live && (
                  <span style={{ ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 999, background: red, color: '#fff', display: 'inline-flex', alignItems: 'center', gap: 5, fontWeight: 700 }}>
                    <LivePulse size={5}/>LIVE
                  </span>
                )}
              </div>
            ))}
          </div>
        </>
      )}
      {team.recent && team.recent.length > 0 && (
        <>
          <div style={{ padding: '18px 16px 6px' }}><span style={mono}>Recent · {team.recent.length}</span></div>
          <div>
            {team.recent.map((m, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid ' + hair }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 7, flexShrink: 0,
                  background: m.won === true ? green : m.won === 'tie' ? cream : red,
                  color: m.won === 'tie' ? ink2 : '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 12,
                }}>{m.won === true ? 'W' : m.won === 'tie' ? 'T' : 'L'}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap', fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: 600 }}>
                    <span>{m.us}</span><span style={{ color: muted, fontSize: 11 }}>vs</span><span style={{ color: ink2 }}>{m.them}</span>
                  </div>
                  <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{m.date} · {m.summary}</div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

function StatsTab({ team }) {
  if (!team.stats) {
    return (
      <div style={{ padding: '36px 18px', textAlign: 'center' }}>
        <div style={{ width: 52, height: 52, margin: '0 auto 12px', borderRadius: 13, background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="1.8"><path d="M4 19V8M10 19V4M16 19V11M22 19H2"/></svg>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, letterSpacing: '-0.02em', color: ink }}>Stats unlock at first match</div>
        <div style={{ fontSize: 12.5, color: muted, marginTop: 6, lineHeight: 1.5, maxWidth: 240, margin: '6px auto 0' }}>Once you play your first match, win rates and top performers appear here.</div>
      </div>
    );
  }
  return (
    <div style={{ padding: '18px 16px 0' }}>
      <div style={{ padding: 18, borderRadius: 16, marginBottom: 16, background: paper2, border: '1px solid ' + hair }}>
        <div style={mono}>All-time</div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, marginTop: 6 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 52, fontWeight: 800, lineHeight: 0.9, letterSpacing: '-0.04em', fontVariantNumeric: 'tabular-nums' }}>{team.stats.winPct}</div>
          <div style={{ fontSize: 14, fontWeight: 600, color: muted, paddingBottom: 6 }}>%</div>
          <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
            <div style={mono}>WIN RATE</div>
            <div style={{ fontSize: 11, color: green, fontFamily: 'JetBrains Mono', marginTop: 2 }}>{team.stats.trend}</div>
          </div>
        </div>
      </div>
      <div style={mono}>Top performers · this season</div>
      <div style={{ background: surf, border: '1px solid ' + hair, borderRadius: 14, marginTop: 8, marginBottom: 16 }}>
        {team.stats.top.map((s, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px', borderTop: i ? '1px solid ' + hair : 'none' }}>
            <div style={{ width: 38, height: 38, borderRadius: 10, background: cream, color: ink2, display: 'flex', alignItems: 'center', justifyContent: 'center', ...mono, fontSize: 9, fontWeight: 700 }}>{s.kind}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={mono}>{s.label}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14.5, fontWeight: 600, marginTop: 2 }}>{s.name}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{s.detail}</div>
            </div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em', fontVariantNumeric: 'tabular-nums' }}>{s.v}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function AboutTab({ team }) {
  return (
    <div style={{ padding: '18px 16px 0' }}>
      {team.archived && (
        <div style={{ padding: '14px 16px', marginBottom: 18, borderRadius: 12, background: paper2, border: '1px dashed ' + line }}>
          <div style={{ ...mono, color: ink }}>DISBANDED · {team.archived}</div>
          <div style={{ fontSize: 12.5, color: ink2, marginTop: 6, lineHeight: 1.5 }}>
            This team's record is preserved for historical reference. Profile and stats are read-only.
          </div>
        </div>
      )}
      {team.about && (
        <div style={{ marginBottom: 18 }}>
          <div style={mono}>About</div>
          <p style={{ fontSize: 14, color: ink2, lineHeight: 1.55, margin: '6px 0 0' }}>{team.about}</p>
        </div>
      )}
      <div style={{ ...mono, marginBottom: 8 }}>Details</div>
      <div style={{ background: surf, border: '1px solid ' + hair, borderRadius: 14, marginBottom: 18 }}>
        {team.details.map((r, i) => (
          <div key={r[0]} style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 14px', borderTop: i ? '1px solid ' + hair : 'none' }}>
            <span style={{ ...mono, color: muted }}>{r[0].toUpperCase()}</span>
            <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 500, color: ink }}>{r[1]}</span>
          </div>
        ))}
      </div>
      {team.managers && team.managers.length > 0 && (
        <>
          <div style={{ ...mono, marginBottom: 8 }}>Managers · {team.managers.length}</div>
          <div style={{ background: surf, border: '1px solid ' + hair, borderRadius: 14, marginBottom: 18 }}>
            {team.managers.map((m, i) => (
              <div key={m.n} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid ' + hair : 'none' }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 999, background: paper2, color: ink2,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, letterSpacing: '-0.02em',
                  border: '1px solid ' + hair,
                }}>{m.n.split(' ').map(s => s[0]).slice(0,2).join('')}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{m.n}</div>
                  <div style={{ fontSize: 11, color: muted }}>{m.role}</div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

function ManageTab({ team }) {
  const queue = team.actionQueue || [];
  const active = team.squad.filter(p => p.status === 'app').length;
  const smsP   = team.squad.filter(p => p.status === 'sms').length;
  const unc    = team.squad.filter(p => p.status === 'unclaimed').length;
  const cap    = team.maxSize || 25;
  return (
    <div style={{ padding: '14px 16px 0' }}>
      <div style={mono}>Action queue · {queue.length}</div>
      {queue.length === 0 ? (
        <div style={{ marginTop: 8, padding: '18px 14px', borderRadius: 12, background: paper2, border: '1px solid ' + hair, color: muted, fontSize: 13, textAlign: 'center' }}>
          Inbox clear. ✓
        </div>
      ) : (
        <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
          {queue.map((q, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px',
              background: paper, border: '1px solid ' + hair, borderRadius: 12,
              borderLeft: '3px solid ' + (q.tone === 'red' ? red : q.tone === 'amber' ? amber : ink),
            }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ ...mono, fontSize: 8.5, fontWeight: 700, padding: '2px 5px', borderRadius: 3, background: q.tone === 'red' ? redS : cream, color: q.tone === 'red' ? red : 'oklch(0.42 0.10 80)' }}>{q.kind}</span>
                  <span style={{ ...mono, fontSize: 9, color: muted }}>{q.when}</span>
                </div>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 700, letterSpacing: '-0.01em', marginTop: 4 }}>{q.title}</div>
                <div style={{ fontSize: 12, color: ink2, marginTop: 2, lineHeight: 1.4 }}>{q.body}</div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                <button style={{ padding: '6px 10px', borderRadius: 8, border: 'none', background: ink, color: paper, fontFamily: 'Inter', fontSize: 11, fontWeight: 700, cursor: 'pointer' }}>{q.primary || 'Approve'}</button>
                <button style={{ padding: '6px 10px', borderRadius: 8, border: '1px solid ' + hair, background: paper, color: ink, fontFamily: 'Inter', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>Reject</button>
              </div>
            </div>
          ))}
        </div>
      )}

      <div style={{ ...mono, margin: '18px 0 8px' }}>Squad capacity</div>
      <div style={{ padding: 14, background: paper, border: '1px solid ' + hair, borderRadius: 12 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.02em' }}>{team.squad.length} of {cap}</span>
          <span style={{ ...mono, fontSize: 9 }}>{Math.round((team.squad.length / cap) * 100)}%</span>
        </div>
        <div style={{ height: 6, borderRadius: 999, background: paper2, overflow: 'hidden', display: 'flex' }}>
          <div style={{ width: (active / cap * 100) + '%', height: '100%', background: green }} />
          <div style={{ width: (smsP / cap * 100) + '%', height: '100%', background: amber }} />
          <div style={{ width: (unc / cap * 100) + '%', height: '100%', background: cream }} />
        </div>
        <div style={{ display: 'flex', gap: 12, marginTop: 8, fontSize: 11 }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: ink2 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: green }}/>Joined · {active}</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: ink2 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: amber }}/>Invited · {smsP}</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: ink2 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: cream, border: '1px solid ' + hair }}/>Unclaimed · {unc}</span>
        </div>
      </div>

      <div style={{ ...mono, margin: '18px 0 8px' }}>Quick</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        {[
          { l: 'Schedule match', icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg> },
          { l: 'Lock playing XI', icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 1 1 8 0v3"/></svg> },
          { l: 'Edit team', icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/></svg> },
          { l: 'Settings', icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.7l.1.1a2 2 0 0 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.7-.3 1.6 1.6 0 0 0-1 1.5"/></svg> },
        ].map(t => (
          <button key={t.l} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', background: paper, border: '1px solid ' + hair, borderRadius: 12, cursor: 'pointer', fontFamily: 'inherit' }}>
            <span style={{ width: 28, height: 28, borderRadius: 7, background: paper2, color: ink, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{t.icon}</span>
            <span style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em' }}>{t.l}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { tpSquadTab: SquadTab, tpMatchesTab: MatchesTab, tpStatsTab: StatsTab, tpAboutTab: AboutTab, tpManageTab: ManageTab });

})();

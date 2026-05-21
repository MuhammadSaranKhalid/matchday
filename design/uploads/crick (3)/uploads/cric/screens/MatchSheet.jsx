// TournamentMatchSheet.jsx — Organizer's match management bottom-sheet style screen
// Reschedule · Walkover · Abandon · Reassign scorer · Edit venue

function CkMatchSheet() {
  const [action, setAction] = React.useState(null);   // 'reschedule' | 'walkover' | 'abandon' | null
  const [walkoverWinner, setWalkoverWinner] = React.useState(null);
  const [done, setDone] = React.useState(null);       // string label of completed action
  const [date, setDate] = React.useState('May 2');
  const [time, setTime] = React.useState('19:30');

  const teams = ['KS', 'IT'];

  // Bottom-sheet height (within iPhone frame ~874)
  return (
    <div style={{ position: 'relative', height: '100%', background: 'rgba(0,0,0,0.45)', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      {/* Behind-sheet match preview chrome */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '100%', background: 'var(--paper)', zIndex: 0, opacity: 0.55, pointerEvents: 'none' }}/>
      <div style={{ position: 'absolute', top: 60, left: 18, right: 18, zIndex: 0, pointerEvents: 'none' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em' }}>QF2 · TOMORROW · 19:30</div>
        <div style={{ marginTop: 4, fontSize: 24, fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em' }}>Karachi Stars vs Islamabad Tigers</div>
        <div style={{ marginTop: 4, fontSize: 12, color: 'var(--muted)' }}>Bagh-e-Jinnah · scorer not yet assigned</div>
      </div>

      {/* Sheet */}
      <div style={{
        position: 'relative', zIndex: 1,
        background: 'var(--paper)',
        borderRadius: '20px 20px 0 0',
        boxShadow: '0 -20px 60px rgba(0,0,0,0.18)',
        maxHeight: '78%',
        display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ padding: '8px 0 4px', display: 'flex', justifyContent: 'center' }}>
          <div style={{ width: 38, height: 4, borderRadius: 999, background: 'var(--line)' }}/>
        </div>

        <div style={{ padding: '6px 18px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div className="ck-display" style={{ fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em' }}>Manage match</div>
            <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>QF2 · only the organizer can do this</div>
          </div>
          <button style={{ background: 'var(--paper-2)', border: 'none', width: 30, height: 30, borderRadius: 999, cursor: 'pointer' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" stroke="var(--ink-2)" strokeWidth="2.5" fill="none" strokeLinecap="round"><path d="M6 18 18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <div style={{ overflow: 'auto', padding: '0 18px 14px' }}>
          {done && (
            <div style={{
              padding: '10px 12px', borderRadius: 12, marginBottom: 12,
              background: 'var(--green-soft)', color: 'oklch(0.36 0.10 148)',
              fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 8,
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="m5 12 5 5L20 7"/></svg>
              {done}
            </div>
          )}

          {!action && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {/* Quick assignments */}
              <SheetRow icon="cal" title="Reschedule" sub="Move date or time" onClick={() => setAction('reschedule')} />
              <SheetRow icon="pin" title="Change venue" sub="Currently Bagh-e-Jinnah" onClick={() => setDone('Venue updated to Iqbal Ground.')} />
              <SheetRow icon="pen" title="Assign scorer" sub="Adeel Sheikh suggested" onClick={() => setDone('Adeel Sheikh assigned as scorer.')} />

              <div style={{ height: 6 }}/>
              <div className="ck-section-h">Result</div>
              <SheetRow icon="bolt" title="Mark walkover" sub="One team didn't show — award win" tone="amber" onClick={() => setAction('walkover')} />
              <SheetRow icon="rain" title="Abandon match" sub="No result — counts as NR" tone="red" onClick={() => setAction('abandon')} />
            </div>
          )}

          {action === 'reschedule' && (
            <div>
              <div className="ck-section-h" style={{ marginBottom: 8 }}>Pick a new slot</div>
              <div style={{ marginBottom: 12 }}>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginBottom: 6 }}>Day</div>
                <div style={{ display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 2 }}>
                  {['Apr 30', 'May 1', 'May 2', 'May 3', 'May 4'].map(d => (
                    <button key={d} onClick={() => setDate(d)} style={{
                      flexShrink: 0, padding: '8px 12px', borderRadius: 10,
                      border: `1px solid ${date === d ? 'var(--ink)' : 'var(--hairline)'}`,
                      background: date === d ? 'var(--ink)' : 'var(--paper)',
                      color: date === d ? 'var(--paper)' : 'var(--ink-2)',
                      fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
                    }}>{d}</button>
                  ))}
                </div>
              </div>
              <div style={{ marginBottom: 14 }}>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginBottom: 6 }}>Time</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
                  {['09:00', '14:00', '16:30', '19:30'].map(t => (
                    <button key={t} onClick={() => setTime(t)} style={{
                      padding: '10px 0', borderRadius: 10,
                      border: `1px solid ${time === t ? 'var(--ink)' : 'var(--hairline)'}`,
                      background: time === t ? 'var(--ink)' : 'var(--paper)',
                      color: time === t ? 'var(--paper)' : 'var(--ink-2)',
                      fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: 600, cursor: 'pointer',
                    }}>{t}</button>
                  ))}
                </div>
              </div>
              <div style={{ padding: 12, borderRadius: 12, background: 'var(--paper-2)', border: '1px solid var(--hairline)', fontSize: 12, color: 'var(--ink-2)', marginBottom: 12 }}>
                New slot: <strong>{date} · {time}</strong> · both captains will be notified.
              </div>
              <SheetActions
                primary="Confirm reschedule"
                onPrimary={() => { setDone(`QF2 moved to ${date} ${time}.`); setAction(null); }}
                onCancel={() => setAction(null)}
              />
            </div>
          )}

          {action === 'walkover' && (
            <div>
              <div className="ck-section-h" style={{ marginBottom: 8 }}>Award the win to</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {teams.map(id => (
                  <button key={id} onClick={() => setWalkoverWinner(id)} style={{
                    display: 'flex', alignItems: 'center', gap: 10, padding: '11px 12px',
                    borderRadius: 12, border: `1px solid ${walkoverWinner === id ? 'var(--ink)' : 'var(--hairline)'}`,
                    background: walkoverWinner === id ? 'var(--paper-2)' : 'var(--paper)',
                    cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
                  }}>
                    <CkTBadge id={id} size={26}/>
                    <span style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>{TEAMS[id].name}</span>
                    <span style={{
                      width: 16, height: 16, borderRadius: 999,
                      border: `1.5px solid ${walkoverWinner === id ? 'var(--ink)' : 'var(--line)'}`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      {walkoverWinner === id && <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--ink)' }}/>}
                    </span>
                  </button>
                ))}
              </div>
              <div style={{ marginTop: 10, padding: 10, borderRadius: 10, background: 'oklch(0.97 0.04 90)', border: '1px solid oklch(0.88 0.05 90)', fontSize: 11, color: 'oklch(0.40 0.10 80)', lineHeight: 1.5 }}>
                <strong>Note · </strong>No player stats are recorded for a walkover, but the winning team gets a W toward standings.
              </div>
              <div style={{ marginTop: 12 }}>
                <SheetActions
                  primary={`Award win${walkoverWinner ? ` to ${TEAMS[walkoverWinner].name}` : ''}`}
                  primaryDisabled={!walkoverWinner}
                  onPrimary={() => { setDone(`Walkover · ${TEAMS[walkoverWinner].name} advance.`); setAction(null); setWalkoverWinner(null); }}
                  onCancel={() => { setAction(null); setWalkoverWinner(null); }}
                />
              </div>
            </div>
          )}

          {action === 'abandon' && (
            <div>
              <div className="ck-section-h" style={{ marginBottom: 8 }}>Reason</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
                {['Rain', 'Pitch unfit', 'Crowd / safety', 'Light failure', 'Other'].map((r, i) => (
                  <button key={r} style={{
                    padding: '11px 12px', borderRadius: 10,
                    border: `1px solid ${i === 0 ? 'var(--red)' : 'var(--hairline)'}`,
                    background: i === 0 ? 'var(--red-soft)' : 'var(--paper)',
                    color: i === 0 ? 'var(--red)' : 'var(--ink-2)',
                    fontFamily: 'Inter', fontWeight: i === 0 ? 600 : 500, fontSize: 13,
                    cursor: 'pointer', textAlign: 'left',
                  }}>{r}</button>
                ))}
              </div>
              <div style={{ padding: 10, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)', fontSize: 11, color: 'var(--ink-2)', marginBottom: 12, lineHeight: 1.5 }}>
                Match counts as <strong>No Result</strong> for both teams. Stats up to abandonment are kept for players. Captains will be notified.
              </div>
              <SheetActions
                primary="Abandon match"
                primaryTone="red"
                onPrimary={() => { setDone('QF2 marked No Result · rain.'); setAction(null); }}
                onCancel={() => setAction(null)}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function SheetRow({ icon, title, sub, tone, onClick }) {
  const tint = tone === 'amber' ? 'oklch(0.45 0.12 80)' : tone === 'red' ? 'var(--red)' : 'var(--ink)';
  const bg   = tone === 'amber' ? 'oklch(0.97 0.04 90)' : tone === 'red' ? 'var(--red-soft)' : 'var(--paper-2)';
  const Icon = ({ name }) => {
    const sw = 1.8;
    if (name === 'cal') return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={sw}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>;
    if (name === 'pin') return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={sw}><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 1 1 18 0Z"/><circle cx="12" cy="10" r="3"/></svg>;
    if (name === 'pen') return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={sw}><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4Z"/></svg>;
    if (name === 'bolt') return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={sw}><path d="M13 2 3 14h7l-1 8 10-12h-7l1-8Z"/></svg>;
    if (name === 'rain') return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={sw}><path d="M16 13a5 5 0 1 0-10 0M8 19v2M12 19v3M16 19v2"/></svg>;
    return null;
  };
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
      borderRadius: 12, border: '1px solid var(--hairline)', background: 'var(--paper)',
      cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit', width: '100%',
    }}>
      <span style={{ width: 34, height: 34, borderRadius: 9, background: bg, color: tint, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <Icon name={icon}/>
      </span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: tint }}>{title}</div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>{sub}</div>
      </div>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
    </button>
  );
}

function SheetActions({ primary, onPrimary, onCancel, primaryDisabled, primaryTone }) {
  const bg = primaryDisabled ? 'var(--paper-2)' : (primaryTone === 'red' ? 'var(--red)' : 'var(--ink)');
  const fg = primaryDisabled ? 'var(--muted)' : 'var(--paper)';
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <button onClick={onCancel} style={{ padding: '11px 16px', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink-2)', fontFamily: 'Inter', fontWeight: 500, fontSize: 13, cursor: 'pointer' }}>
        Cancel
      </button>
      <button disabled={primaryDisabled} onClick={onPrimary} style={{
        flex: 1, padding: '11px 0', borderRadius: 10, border: 'none',
        background: bg, color: fg,
        fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
        cursor: primaryDisabled ? 'not-allowed' : 'pointer',
      }}>{primary}</button>
    </div>
  );
}

window.CkMatchSheet = CkMatchSheet;

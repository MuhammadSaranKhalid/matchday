// challenge-send.jsx — Send Challenge wizard (S2).
// IA: Team → Opponent → Format → When & Where → Pick XI (gated) → Review.
// Exports window.SendChallenge.

(function () {

const C = window.Ch;
const D = window.ChData;
const {
  ink, ink2, muted, soft, paper, paper2, surface, hair, red, redSoft,
  green, greenSoft, amber, cream, amberInk, greenInk,
  display, mono, Icon, ChHeader, ChCta, Chip, SectionLabel, Stepper, SliderRow,
  Crest, Avatar, RolePill, StatusPill,
} = C;
const { PRESETS, BALL_TYPES, PLAYERS_OPTS, MY_TEAMS, OPPONENTS, VENUES, TIMES, NEARBY, ROSTER, ballLabel, presetMatches } = D;

const STEP_TITLES = { team: 'Team', opponent: 'Opponent', format: 'Format', when: 'When & where', xi: 'Pick XI', review: 'Review' };

function clampBowler(f) {
  const cap = Math.max(1, Math.ceil(f.oversPerInnings / 5));
  return { ...f, maxOversPerBowler: Math.min(f.maxOversPerBowler, cap) };
}

// ══════════════════════════════════════════════════════════
// ROOT
// ══════════════════════════════════════════════════════════
function SendChallenge({ teamsCount = 3, squadSize = 18, sendFails = false, preTeamId, onExit, onSent }) {
  const teams = MY_TEAMS.slice(0, Math.max(0, teamsCount));
  const roster = ROSTER.slice(0, squadSize);

  const [teamId, setTeamId] = React.useState(preTeamId || (teams.length === 1 ? teams[0].id : null));
  const [open, setOpen] = React.useState(false);           // open challenge
  const [oppId, setOppId] = React.useState(null);
  const [query, setQuery] = React.useState('');
  const [format, setFormat] = React.useState({ ...PRESETS[0].f, presetId: PRESETS[0].id });
  const [when, setWhen] = React.useState({ dateKey: null, dateLabel: null, time: null });
  const [venue, setVenue] = React.useState('');
  const [xi, setXi] = React.useState(new Set());
  const [keeper, setKeeper] = React.useState(null);
  const [message, setMessage] = React.useState('');
  const [extras, setExtras] = React.useState([]);          // borrowed / unclaimed gap-fillers
  const [touched, setTouched] = React.useState(false);
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState(null);
  const [discard, setDiscard] = React.useState(false);

  const players = format.playersPerTeam;
  const effRoster = roster.concat(extras);
  const xiGated = effRoster.length > players;     // need a pick-XI step
  const rosterShort = effRoster.length < players; // can't field a side

  // active step sequence (auto-skips)
  const seq = ['team', 'opponent', 'format', 'when', 'xi', 'review'].filter(id => {
    if (id === 'team' && teams.length <= 1) return false;
    if (id === 'opponent' && open) return true; // still in sequence; user chose open here
    if (id === 'xi' && effRoster.length === players) return false;
    return true;
  });
  const [cur, setCur] = React.useState(() => (teams.length <= 1 ? 'opponent' : 'team'));
  const idx = Math.max(0, seq.indexOf(cur));
  const team = teams.find(t => t.id === teamId) || teams[0];
  const opp = OPPONENTS.find(o => o.id === oppId);

  const mark = () => setTouched(true);
  const go = (id) => { setError(null); setCur(id); };
  const next = () => { const i = seq.indexOf(cur); if (i < seq.length - 1) go(seq[i + 1]); };
  const back = () => {
    const i = seq.indexOf(cur);
    if (i <= 0) { if (touched) setDiscard(true); else onExit && onExit(); return; }
    // leaving format with open → back to opponent
    go(seq[i - 1]);
  };

  // keep bowler cap valid + keeper inside XI
  React.useEffect(() => { setFormat(f => clampBowler(f)); }, [format.oversPerInnings]);
  React.useEffect(() => { if (keeper && !xi.has(keeper)) setKeeper(null); }, [xi]); // eslint-disable-line

  // default XI when arriving at the pick step
  React.useEffect(() => {
    if (cur !== 'xi' || rosterShort) return;
    if (xi.size === 0) {
      const pick = effRoster.slice(0, players);
      setXi(new Set(pick.map(p => p.id)));
      const wk = pick.find(p => p.role === 'WK');
      setKeeper(wk ? wk.id : (pick[1] ? pick[1].id : pick[0].id));
    }
  }, [cur, effRoster.length]); // eslint-disable-line

  const submit = () => {
    setBusy(true); setError(null);
    setTimeout(() => {
      setBusy(false);
      if (sendFails) { setError("Couldn't reach matchday. Check your connection."); return; }
      onSent && onSent({
        team, opp: open ? null : opp, open, format, when, venue,
        xi: effRoster.filter(p => xi.has(p.id)), keeper, message,
      });
    }, 1100);
  };

  // contextual footer
  const fmtChip = `${presetLabel(format)} · ${players}/side`;
  const whenLabel = when.dateLabel && when.time ? `${when.dateLabel.split(' · ')[0]} ${when.time}` : null;

  const sharedHeader = (extra) => (
    <ChHeader
      kicker={`Send challenge${open ? ' · open' : ''}`}
      step={idx + 1} total={seq.length}
      onBack={back}
      {...extra}
    />
  );

  let body, footer;

  if (cur === 'team') {
    body = <StepTeam teams={teams} teamId={teamId} onPick={(id) => { setTeamId(id); mark(); }} onExit={onExit} />;
    footer = teams.length === 0 ? null :
      <ChCta hint="You manage these teams" cta="Continue" disabled={!teamId} onCta={next} />;
    return shell(sharedHeader({ title: 'Which team is challenging?', sub: 'Only teams you manage can send a challenge.' }), body, footer, discard, setDiscard, onExit);
  }

  if (cur === 'opponent') {
    const ranked = query ? OPPONENTS.filter(o => (o.name + o.city).toLowerCase().includes(query.toLowerCase())) : OPPONENTS;
    body = <StepOpponent team={team} ranked={ranked} oppId={oppId} query={query} players={players}
      onQuery={setQuery} onPick={(id) => { setOppId(id); setOpen(false); mark(); }}
      onOpen={() => { setOpen(true); setOppId(null); mark(); go('format'); }} />;
    footer = <ChCta hint={opp ? `${team.name} vs ${opp.name}` : 'Pick a team, or send an open challenge'}
      cta="Continue" disabled={!oppId} onCta={next} />;
    return shell(sharedHeader({ title: 'Pick your opponent', sub: <>{team.name} vs&hellip;</> }), body, footer, discard, setDiscard, onExit);
  }

  if (cur === 'format') {
    body = <StepFormat format={format} onChange={(f) => { setFormat(clampBowler(f)); mark(); }} />;
    footer = <ChCta hint="Both captains can change format up to 12h before the toss." cta={`Continue · ${fmtChip}`} onCta={next} />;
    return shell(sharedHeader({ title: 'Match format', sub: 'Pick a format — that sets the whole match.' }), body, footer, discard, setDiscard, onExit);
  }

  if (cur === 'when') {
    const ready = when.dateLabel && when.time && venue.trim();
    body = <StepWhen when={when} venue={venue} onWhen={(w) => { setWhen(w); mark(); }} onVenue={(v) => { setVenue(v); mark(); }} />;
    footer = <ChCta hint={ready ? `${whenLabel} · ${venue}` : 'Set a date, time and venue'}
      cta={ready ? `Continue · ${whenLabel} · ${venue}` : 'Continue'} disabled={!ready} onCta={next} />;
    return shell(sharedHeader({ title: 'When & where', sub: 'Propose a slot — the opponent can counter it.' }), body, footer, discard, setDiscard, onExit);
  }

  if (cur === 'xi') {
    if (rosterShort) {
      return (
        <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, position: 'relative' }}>
          <div style={{ height: 44, flexShrink: 0 }} />
          <RosterGate
            team={team} have={effRoster.length} need={players}
            step={idx + 1} total={seq.length}
            onBack={back} onFormat={() => go('format')}
            onAdd={(arr) => {
              const newLen = effRoster.length + arr.length;
              mark(); setExtras(prev => [...prev, ...arr]);
              if (newLen > players) go('xi'); else { setXi(new Set()); setKeeper(null); go('review'); }
            }}
          />
          {discard && <DiscardSheet onKeep={() => setDiscard(false)} onDiscard={() => { setDiscard(false); onExit && onExit(); }} />}
        </div>
      );
    }
    const ready = xi.size === players && keeper && xi.has(keeper);
    body = <StepXI roster={effRoster} players={players} xi={xi} keeper={keeper} team={team}
      onToggle={(id) => { mark(); setXi(prev => { const n = new Set(prev); if (n.has(id)) n.delete(id); else if (n.size < players) n.add(id); return n; }); }}
      onKeeper={(id) => { mark(); setKeeper(id); }}
      onAuto={() => { const pick = effRoster.slice(0, players); setXi(new Set(pick.map(p => p.id))); const wk = pick.find(p => p.role === 'WK'); setKeeper(wk ? wk.id : pick[1].id); }}
      onClear={() => { setXi(new Set()); setKeeper(null); }} />;
    footer = <ChCta
      hint={xi.size < players ? `Pick ${players - xi.size} more` : (!keeper ? 'Choose a wicket-keeper' : `XI locked · ${players} players`)}
      cta={ready ? 'Continue' : (xi.size < players ? `Pick ${players - xi.size} more` : 'Choose a keeper')}
      disabled={!ready} onCta={next} />;
    return shell(sharedHeader({ title: 'Pick your XI for this match', sub: `Choose ${players} from ${team.name}'s squad of ${effRoster.length}.`,
      right: <span style={{ ...mono, fontSize: 11, color: xi.size === players ? green : ink2, fontFamily: 'JetBrains Mono' }}>{xi.size}/{players}</span> }), body, footer, discard, setDiscard, onExit);
  }

  // review
  const ready = message !== undefined;
  body = <StepReview team={team} opp={opp} open={open} format={format} when={when} venue={venue}
    xi={roster.filter(p => xi.has(p.id))} keeper={keeper} xiGated={xiGated}
    message={message} onMessage={setMessage} />;
  footer = <ChCta
    hint={open ? 'Generates a 6-digit code to share' : `${whenLabel || 'TBD'} · ${venue || 'venue TBD'}`}
    cta={open ? 'Create open challenge' : `Send challenge to ${opp ? opp.name : ''}`}
    onCta={submit} busy={busy} error={error} onRetry={submit} />;
  return shell(sharedHeader({ title: open ? 'Review open challenge' : 'Review & send', sub: 'Final check before it goes out.' }), body, footer, discard, setDiscard, onExit);
}

function presetLabel(f) {
  if (!f.presetId || f.presetId === 'custom') return 'Custom';
  const p = PRESETS.find(x => x.id === f.presetId);
  return p ? p.label : 'Custom';
}

// shell with optional discard sheet
function shell(header, body, footer, discard, setDiscard, onExit) {
  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, position: 'relative' }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      {header}
      <div style={{ flex: 1, overflowY: 'auto', minHeight: 0 }}>{body}</div>
      {footer}
      {discard && <DiscardSheet onKeep={() => setDiscard(false)} onDiscard={() => { setDiscard(false); onExit && onExit(); }} />}
    </div>
  );
}

// ══════════════════════════════════════════════════════════
// STEP · Team
// ══════════════════════════════════════════════════════════
function StepTeam({ teams, teamId, onPick, onExit }) {
  if (teams.length === 0) {
    return (
      <div style={{ padding: '40px 24px', textAlign: 'center' }}>
        <div style={{ width: 60, height: 60, borderRadius: 16, margin: '0 auto 16px', background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="users" size={26} stroke={ink2} sw={1.8} />
        </div>
        <div style={display(19)}>No teams yet</div>
        <div style={{ fontSize: 13, color: ink2, marginTop: 8, lineHeight: 1.5, maxWidth: 260, margin: '8px auto 0' }}>
          You need a team before you can challenge anyone. Create one — it takes a minute.
        </div>
        <button style={{ marginTop: 20, padding: '13px 22px', borderRadius: 12, border: 'none', background: ink, color: paper, fontFamily: 'inherit', fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>Create a team first</button>
      </div>
    );
  }
  return (
    <div style={{ padding: '16px 18px', display: 'grid', gap: 10 }}>
      {teams.map(t => {
        const on = teamId === t.id;
        return (
          <button key={t.id} onClick={() => onPick(t.id)} style={selCard(on)}>
            <Crest size={42} bg={t.color} label={t.mono} />
            <div style={{ flex: 1, minWidth: 0, textAlign: 'left' }}>
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15 }}>{t.name}</div>
              <div style={{ fontSize: 11.5, color: muted, marginTop: 2, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>{t.area}, {t.city} · {t.squad} squad</div>
            </div>
            <Radio on={on} />
          </button>
        );
      })}
    </div>
  );
}

// ══════════════════════════════════════════════════════════
// STEP · Opponent
// ══════════════════════════════════════════════════════════
function StepOpponent({ team, ranked, oppId, query, players, onQuery, onPick, onOpen }) {
  return (
    <div>
      <div style={{ padding: '14px 18px 12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '11px 12px', background: paper2, border: '1px solid ' + hair, borderRadius: 12 }}>
          <Icon name="search" size={15} stroke={muted} sw={2} />
          <input value={query} onChange={e => onQuery(e.target.value)} placeholder="Search teams by name or city"
            style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontSize: 14, fontFamily: 'inherit', color: ink }} />
        </div>
      </div>

      <div style={{ padding: '0 18px 8px' }}>
        <SectionLabel hint={query ? `${ranked.length} found` : 'Nearest first'}>{query ? 'Results' : 'Nearby teams'}</SectionLabel>
        <div style={{ display: 'grid', gap: 6 }}>
          {ranked.map(o => {
            const on = oppId === o.id;
            const tight = o.squad < players;
            return (
              <button key={o.id} onClick={() => onPick(o.id)} style={selCard(on, 10)}>
                <Crest size={36} bg={o.color} label={o.mono} radius={9} />
                <div style={{ flex: 1, minWidth: 0, textAlign: 'left' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 600, fontSize: 13.5 }}>{o.name}</span>
                    {tight && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 4, background: cream, color: amberInk }}>NEEDS {players}</span>}
                  </div>
                  <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{o.meta}</div>
                </div>
                <span style={{ ...mono, fontSize: 9, color: tight ? amberInk : muted }}>{o.squad} SQ</span>
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ padding: '8px 18px 24px' }}>
        <button onClick={onOpen} style={{
          width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: 14,
          background: paper, border: '1px dashed ' + line(), borderRadius: 14, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
        }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: paper2, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Icon name="share" size={16} stroke={ink} sw={1.8} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontWeight: 600, fontSize: 13.5 }}>No team in mind?</div>
            <div style={{ fontSize: 11.5, color: muted, marginTop: 2 }}>Send as an open challenge — any nearby captain can claim it.</div>
          </div>
          <Icon name="next" size={15} stroke={muted} sw={2} />
        </button>
      </div>
    </div>
  );
}
function line() { return 'var(--line)'; }

// ══════════════════════════════════════════════════════════
// STEP · Format
// ══════════════════════════════════════════════════════════
function StepFormat({ format, onChange }) {
  const f = format;
  return (
    <div style={{ padding: '16px 18px 8px' }}>
      <SectionLabel hint="One tap sets it all">Choose a format</SectionLabel>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
        {PRESETS.map(p => {
          const pf = p.f;
          const on = f.presetId === p.id;
          const dot = pf.ballType === 'leather' ? '#a8332e' : pf.ballType === 'tape' ? '#d8a85e' : '#cdd64a';
          const ot = pf.ballsPerOver !== 6 ? `${pf.oversPerInnings * pf.ballsPerOver} balls` : `${pf.oversPerInnings} overs`;
          return (
            <button key={p.id} onClick={() => onChange({ ...pf, presetId: p.id })} style={{
              textAlign: 'left', cursor: 'pointer', fontFamily: 'inherit', padding: '13px 13px',
              borderRadius: 14, background: on ? paper2 : paper, border: '1.5px solid ' + (on ? ink : hair),
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                <span style={{ width: 10, height: 10, borderRadius: 999, background: dot, flexShrink: 0, border: pf.ballType === 'tennis' ? 'none' : '1px solid rgba(0,0,0,0.12)' }} />
                <span style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 14.5, letterSpacing: '-0.02em', whiteSpace: 'nowrap' }}>{p.label}</span>
                {on && <span style={{ marginLeft: 'auto', display: 'flex' }}><Icon name="check" size={14} stroke={ink} sw={2.6} /></span>}
              </div>
              <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 9 }}>{ot} · {pf.playersPerTeam}/side</div>
              <div style={{ fontSize: 11, color: ink2, marginTop: 3 }}>{ballLabel(pf.ballType)} · {pf.maxOversPerBowler} max/bow</div>
            </button>
          );
        })}
      </div>

      <div style={{ padding: '11px 14px', borderRadius: 12, background: paper2, border: '1px solid ' + hair }}>
        <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 4 }}>{presetLabel(f).toUpperCase()} · DETAIL</div>
        <div style={{ fontSize: 12, color: ink2, lineHeight: 1.5 }}>
          {f.ballsPerOver}-ball overs · {f.inningsPerSide} innings per side
          {f.endChangeBalls ? ` · ends change every ${f.endChangeBalls} balls` : ''}
          {f.scoredPostMatch ? ' · scored post-match, not ball-by-ball' : ''}
        </div>
      </div>

      <div style={{ ...mono, fontSize: 9, color: muted, textAlign: 'center', marginTop: 14 }}>SAME FORMAT FOR BOTH TEAMS</div>
      <div style={{ height: 12 }} />
    </div>
  );
}

// ══════════════════════════════════════════════════════════
// STEP · When & Where
// ══════════════════════════════════════════════════════════
function StepWhen({ when, venue, onWhen, onVenue }) {
  const DAYS = [
    { key: 'd0', dow: 'TODAY', n: 17, mon: 'MAY', label: 'Today · Sat 17 May' },
    { key: 'd1', dow: 'SUN',   n: 18, mon: 'MAY', label: 'Sun 18 May' },
    { key: 'd2', dow: 'MON',   n: 19, mon: 'MAY', label: 'Mon 19 May' },
    { key: 'd3', dow: 'TUE',   n: 20, mon: 'MAY', label: 'Tue 20 May' },
    { key: 'd4', dow: 'WED',   n: 21, mon: 'MAY', label: 'Wed 21 May' },
    { key: 'd5', dow: 'THU',   n: 22, mon: 'MAY', label: 'Thu 22 May' },
    { key: 'd6', dow: 'FRI',   n: 23, mon: 'MAY', label: 'Fri 23 May' },
    { key: 'd7', dow: 'SAT',   n: 24, mon: 'MAY', label: 'Sat 24 May' },
  ];
  const periods = [
    { label: 'Morning',   items: TIMES.filter(t => +t.split(':')[0] < 12) },
    { label: 'Afternoon', items: TIMES.filter(t => { const h = +t.split(':')[0]; return h >= 12 && h < 17; }) },
    { label: 'Evening',   items: TIMES.filter(t => +t.split(':')[0] >= 17) },
  ].filter(p => p.items.length);
  const resolved = venue.trim().length > 0;

  return (
    <div style={{ padding: '16px 0 8px' }}>
      <div style={{ padding: '0 18px' }}><SectionLabel hint="Tap a day">Date</SectionLabel></div>
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', padding: '0 18px 4px' }}>
        {DAYS.map(d => {
          const on = when.dateKey === d.key;
          return (
            <button key={d.key} onClick={() => onWhen({ ...when, dateKey: d.key, dateLabel: d.label })} style={{
              flexShrink: 0, width: 60, padding: '11px 0', borderRadius: 14, cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              background: on ? ink : paper, color: on ? paper : ink, border: '1px solid ' + (on ? ink : hair),
            }}>
              <span style={{ ...mono, fontSize: 8, opacity: on ? 0.85 : 0.55 }}>{d.dow}</span>
              <span style={{ fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 20, letterSpacing: '-0.03em' }}>{d.n}</span>
              <span style={{ fontSize: 8.5, opacity: 0.6, letterSpacing: '0.04em' }}>{d.mon}</span>
            </button>
          );
        })}
        <button onClick={() => onWhen({ ...when, dateKey: 'pick', dateLabel: 'Sat 31 May' })} style={{
          flexShrink: 0, width: 60, padding: '11px 0', borderRadius: 14, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 5,
          background: when.dateKey === 'pick' ? ink : paper, color: when.dateKey === 'pick' ? paper : muted,
          border: '1px dashed ' + (when.dateKey === 'pick' ? ink : line()),
        }}>
          <Icon name="cal" size={16} stroke={when.dateKey === 'pick' ? paper : muted} sw={1.8} />
          <span style={{ fontSize: 9 }}>Pick</span>
        </button>
      </div>

      <div style={{ padding: '18px 18px 0' }}>
        <SectionLabel hint="30-min slots">Start time</SectionLabel>
        {periods.map(p => (
          <div key={p.label} style={{ marginBottom: 14 }}>
            <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 7 }}>{p.label.toUpperCase()}</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {p.items.map(t => <Chip key={t} active={when.time === t} onClick={() => onWhen({ ...when, time: t })}>{t}</Chip>)}
            </div>
          </div>
        ))}
      </div>

      <div style={{ padding: '6px 18px 0' }}>
        <SectionLabel hint="Recent">Venue</SectionLabel>
        <div style={{ display: 'grid', gap: 6, marginBottom: 10 }}>
          {VENUES.map(v => {
            const on = venue === v.name;
            return (
              <button key={v.id} onClick={() => onVenue(v.name)} style={selCard(on, 12)}>
                <div style={{ width: 34, height: 34, borderRadius: 10, background: paper2, border: '1px solid ' + hair, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon name="pin" size={15} stroke={ink} sw={1.8} />
                </div>
                <div style={{ flex: 1, minWidth: 0, textAlign: 'left' }}>
                  <div style={{ fontWeight: 600, fontSize: 13 }}>{v.name}</div>
                  <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>{v.sub}</div>
                </div>
                {on && <Icon name="check" size={16} stroke={ink} sw={2.4} />}
              </button>
            );
          })}
        </div>
        <input value={venue} onChange={e => onVenue(e.target.value)} placeholder="Or type a new venue…" className="ck-input"
          style={{ fontSize: 14, borderRadius: 12, padding: '12px 14px' }} />

        {resolved && (
          <div style={{ marginTop: 12, borderRadius: 14, overflow: 'hidden', border: '1px solid ' + hair }}>
            <div style={{ height: 100, position: 'relative', background: 'repeating-linear-gradient(45deg, var(--paper-2) 0 14px, var(--paper) 14px 28px)' }}>
              <svg width="100%" height="100" style={{ position: 'absolute', inset: 0, opacity: 0.5 }}>
                <path d="M0 64 H400" stroke="var(--line)" strokeWidth="6" fill="none" />
                <path d="M130 0 V100" stroke="var(--line)" strokeWidth="4" fill="none" />
                <circle cx="130" cy="64" r="26" stroke="var(--line)" strokeWidth="2" fill="none" />
              </svg>
              <div style={{ position: 'absolute', left: '50%', top: '44%', transform: 'translate(-50%,-50%)' }}>
                <Icon name="pin" size={28} stroke={red} sw={2} />
              </div>
            </div>
            <div style={{ padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 8, background: paper }}>
              <Icon name="pin" size={13} stroke={muted} sw={2} />
              <span style={{ fontSize: 12, color: ink2, flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{venue}</span>
              <span style={{ ...mono, fontSize: 9, color: muted }}>MAP PREVIEW</span>
            </div>
          </div>
        )}
      </div>
      <div style={{ height: 12 }} />
    </div>
  );
}

// ══════════════════════════════════════════════════════════
// STEP · Pick XI
// ══════════════════════════════════════════════════════════
function StepXI({ roster, players, xi, keeper, team, onToggle, onKeeper, onAuto, onClear }) {
  const picked = roster.filter(p => xi.has(p.id));
  const full = xi.size >= players;
  return (
    <div>
      <div style={{ padding: '10px 18px', borderBottom: '1px solid ' + hair, background: paper, display: 'flex', alignItems: 'center', gap: 12 }}>
        <span style={{ ...mono, fontSize: 10, color: full ? green : ink2, fontFamily: 'JetBrains Mono' }}>XI · {xi.size}/{players}</span>
        <div style={{ flex: 1, height: 4, background: paper2, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ width: (xi.size / players * 100) + '%', height: '100%', background: full ? green : ink, transition: 'width .15s' }} />
        </div>
        <button onClick={onAuto} style={miniBtn}>AUTO</button>
        <button onClick={onClear} style={miniBtn}>CLEAR</button>
      </div>

      {/* keeper picker */}
      <div style={{ padding: '12px 18px 4px' }}>
        <SectionLabel hint={keeper ? '' : 'Required'}>Wicket-keeper</SectionLabel>
        {picked.length === 0 ? (
          <div style={{ fontSize: 12, color: muted, padding: '4px 0 6px' }}>Pick players first, then choose your keeper.</div>
        ) : (
          <div style={{ display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 4 }}>
            {picked.map(p => {
              const on = keeper === p.id;
              return (
                <button key={p.id} onClick={() => onKeeper(p.id)} style={{
                  flexShrink: 0, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '7px 11px', borderRadius: 999,
                  border: '1px solid ' + (on ? red : hair), background: on ? red : paper, color: on ? paper : ink2,
                  cursor: 'pointer', fontFamily: 'inherit', fontSize: 12, fontWeight: 600,
                }}>
                  <Icon name="glove" size={13} stroke={on ? paper : muted} sw={1.8} />
                  {p.name.split(' ')[0]}
                </button>
              );
            })}
          </div>
        )}
      </div>

      <div style={{ padding: '8px 18px 6px' }}><span style={{ ...mono, fontSize: 10, color: muted }}>SQUAD · {roster.length}</span></div>
      {roster.map((p, i) => {
        const on = xi.has(p.id);
        const isK = keeper === p.id;
        const disabled = !on && full;
        return (
          <div key={p.id} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '10px 18px',
            borderTop: i ? '1px solid ' + hair : 'none', background: on ? paper : 'transparent', opacity: disabled ? 0.45 : 1,
          }}>
            <button onClick={!disabled ? () => onToggle(p.id) : undefined} style={{
              width: 24, height: 24, borderRadius: 7, flexShrink: 0, padding: 0,
              border: on ? 'none' : '1.5px solid ' + soft, background: on ? ink : paper,
              cursor: disabled ? 'default' : 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>{on && <Icon name="check" size={13} stroke={paper} sw={3} />}</button>
            <Avatar name={p.name} size={34} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, whiteSpace: 'nowrap' }}>{p.name}</span>
                <RolePill role={p.role} />
                {p.guest && <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: cream, color: amberInk }}>GUEST</span>}
                {p.unclaimed && <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: paper2, color: muted, border: '1px solid ' + hair }}>NEW</span>}
                {p.captain && <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: ink, color: paper }}>C</span>}
                {isK && <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: red, color: paper }}>WK</span>}
              </div>
              <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2, fontFamily: 'JetBrains Mono' }}>{p.sub}</div>
            </div>
          </div>
        );
      })}
      <div style={{ height: 16 }} />
    </div>
  );
}
const miniBtn = {
  ...mono, fontSize: 9, padding: '6px 9px', borderRadius: 8, cursor: 'pointer',
  border: '1px solid ' + hair, background: paper, color: ink2, fontFamily: 'JetBrains Mono',
};

// ══════════════════════════════════════════════════════════
// Roster gap flow — picker → borrow / unclaimed → resolves
// ══════════════════════════════════════════════════════════
function RosterGate({ team, have, need, step, total, onBack, onFormat, onAdd }) {
  const [view, setView] = React.useState('picker');
  const short = need - have;
  if (view === 'borrow')    return <GateBorrow    short={short} step={step} total={total} onBack={() => setView('picker')} onDone={onAdd} />;
  if (view === 'unclaimed') return <GateUnclaimed short={short} step={step} total={total} onBack={() => setView('picker')} onDone={onAdd} />;
  return <GatePicker team={team} have={have} need={need} step={step} total={total} onBack={onBack} onFormat={onFormat} onBorrow={() => setView('borrow')} onUnclaimed={() => setView('unclaimed')} />;
}

function GatePicker({ team, have, need, step, total, onBack, onFormat, onBorrow, onUnclaimed }) {
  const short = need - have;
  const opts = [
    { id: 'borrow', title: `Borrow ${short} player${short === 1 ? '' : 's'}`, sub: 'Free agents or guests from nearby teams — allowed in friendlies.', icon: 'users', rec: true, on: onBorrow },
    { id: 'unclaimed', title: 'Add unclaimed names', sub: 'Just names for now. They claim the profile later; stats migrate.', icon: 'plus', on: onUnclaimed },
  ];
  return (
    <>
      <ChHeader kicker="Send challenge · roster gap" step={step} total={total} onBack={onBack}
        title="Not enough players" sub={`This format needs ${need} a side. ${team.name} has ${have}.`} />
      <div style={{ flex: 1, overflowY: 'auto', minHeight: 0, padding: '16px 18px 24px' }}>
        <div style={{ padding: 16, borderRadius: 16, background: cream, display: 'flex', alignItems: 'center', gap: 14, marginBottom: 18 }}>
          <div style={{ width: 56, height: 56, borderRadius: 14, background: amber, color: paper, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 24, letterSpacing: '-0.04em', flexShrink: 0 }}>−{short}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13.5, fontWeight: 700 }}>Short {short} player{short === 1 ? '' : 's'}</div>
            <div style={{ fontSize: 11.5, color: ink2, marginTop: 2 }}>Have {have} · need {need}</div>
            <div style={{ display: 'flex', gap: 3, marginTop: 8 }}>
              {Array.from({ length: need }, (_, i) => <span key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i < have ? green : 'rgba(20,18,14,0.10)' }} />)}
            </div>
          </div>
        </div>
        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>FILL THE GAP</div>
        {opts.map(o => (
          <button key={o.id} onClick={o.on} style={{ width: '100%', display: 'flex', gap: 12, padding: 14, marginBottom: 8, background: paper, border: '1.5px solid ' + hair, borderRadius: 14, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit' }}>
            <div style={{ width: 38, height: 38, borderRadius: 11, flexShrink: 0, background: o.id === 'borrow' ? ink : paper2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name={o.icon} size={18} stroke={o.id === 'borrow' ? paper : ink} sw={2} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <span style={{ fontWeight: 700, fontSize: 14 }}>{o.title}</span>
                {o.rec && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 4, background: ink, color: paper }}>EASIEST</span>}
              </div>
              <div style={{ fontSize: 11.5, color: muted, marginTop: 3, lineHeight: 1.45 }}>{o.sub}</div>
            </div>
            <Icon name="next" size={15} stroke={muted} sw={2} style={{ alignSelf: 'center', flexShrink: 0 }} />
          </button>
        ))}
        <div style={{ marginTop: 8, padding: 13, borderRadius: 12, background: paper2, fontSize: 12, color: ink2, lineHeight: 1.5 }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 6 }}>OR CHANGE FORMAT</div>
          Pick a smaller format (like 8-a-side) so {have} players is a full squad — no borrowing needed.
        </div>
      </div>
      <div style={{ borderTop: '1px solid ' + hair, padding: '10px 18px 12px', paddingBottom: 'calc(12px + env(safe-area-inset-bottom))', background: paper, flexShrink: 0 }}>
        <button onClick={onFormat} style={{ width: '100%', padding: '13px 0', borderRadius: 12, border: '1px solid ' + hair, background: paper, color: ink, fontFamily: 'inherit', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Change the format instead</button>
      </div>
    </>
  );
}

function GateBorrow({ short, step, total, onBack, onDone }) {
  const [q, setQ] = React.useState('');
  const [picked, setPicked] = React.useState(new Set());
  const matches = q ? NEARBY.filter(p => (p.name + p.team).toLowerCase().includes(q.toLowerCase())) : NEARBY;
  const toggle = (id) => setPicked(prev => { const n = new Set(prev); if (n.has(id)) n.delete(id); else if (n.size < short) n.add(id); return n; });
  const enough = picked.size === short;
  return (
    <>
      <ChHeader kicker="Roster gap · borrow" step={step} total={total} onBack={onBack}
        title="Borrow players" sub={`Add ${short} guest${short === 1 ? '' : 's'} from nearby teams. They appear with a guest tag in stats.`} />
      <div style={{ padding: '10px 18px', borderBottom: '1px solid ' + hair, background: paper, display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0 }}>
        <span style={{ ...mono, fontSize: 10, color: enough ? green : ink2, fontFamily: 'JetBrains Mono' }}>GUESTS · {picked.size}/{short}</span>
        <div style={{ flex: 1, height: 4, background: paper2, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ width: Math.min(100, (picked.size / short) * 100) + '%', height: '100%', background: enough ? green : ink }} />
        </div>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ padding: '12px 18px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '11px 12px', background: paper2, border: '1px solid ' + hair, borderRadius: 12 }}>
            <Icon name="search" size={15} stroke={muted} sw={2} />
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search by name or club" style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontSize: 14, fontFamily: 'inherit', color: ink }} />
          </div>
        </div>
        <div style={{ padding: '0 18px 6px' }}><SectionLabel hint={`${matches.length} nearby`}>{q ? 'Results' : 'Available nearby'}</SectionLabel></div>
        {matches.map((p, i) => {
          const on = picked.has(p.id); const dis = !on && picked.size >= short;
          return (
            <button key={p.id} onClick={!dis ? () => toggle(p.id) : undefined} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '11px 18px', borderTop: i ? '1px solid ' + hair : 'none', background: on ? paper2 : paper, cursor: dis ? 'default' : 'pointer', fontFamily: 'inherit', textAlign: 'left', opacity: dis ? 0.45 : 1 }}>
              <div style={{ width: 22, height: 22, borderRadius: 6, flexShrink: 0, border: on ? 'none' : '1.5px solid ' + soft, background: on ? ink : paper, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{on && <Icon name="check" size={12} stroke={paper} sw={3} />}</div>
              <Avatar name={p.name} size={32} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                  <span style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600, whiteSpace: 'nowrap' }}>{p.name}</span>
                  <RolePill role={p.role} />
                  <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: cream, color: amberInk }}>GUEST</span>
                </div>
                <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2, fontFamily: 'JetBrains Mono' }}>{p.team} · {p.sub}</div>
              </div>
              <span style={{ ...mono, fontSize: 9, color: muted }}>{p.dist}</span>
            </button>
          );
        })}
        <div style={{ padding: '16px 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 12, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
            Guests join your XI for this match only. Their stats credit their home club unless they're free agents.
          </div>
        </div>
      </div>
      <ChCta hint={enough ? `${short} guest${short === 1 ? '' : 's'} ready` : `Pick ${short - picked.size} more`}
        cta={enough ? `Add ${short} to squad` : `Pick ${short - picked.size} more`} disabled={!enough}
        secondary="Back" onSecondary={onBack}
        onCta={() => onDone(NEARBY.filter(p => picked.has(p.id)).map(p => ({ id: 'guest_' + p.id, name: p.name, role: p.role, sub: p.sub, form: 'OK', guest: true })))} />
    </>
  );
}

function GateUnclaimed({ short, step, total, onBack, onDone }) {
  const [rows, setRows] = React.useState(Array.from({ length: short }, () => ({ name: '', role: 'BAT' })));
  const set = (i, patch) => setRows(rs => rs.map((r, idx) => idx === i ? { ...r, ...patch } : r));
  const valid = rows.every(r => r.name.trim().length >= 2);
  return (
    <>
      <ChHeader kicker="Roster gap · unclaimed" step={step} total={total} onBack={onBack}
        title="Add unclaimed players" sub={`Type ${short} name${short === 1 ? '' : 's'}. They go on your squad as placeholders — claimable later.`} />
      <div style={{ flex: 1, overflowY: 'auto', minHeight: 0, padding: '14px 18px 24px' }}>
        {rows.map((r, i) => (
          <div key={i} style={{ padding: 14, background: paper, border: '1px solid ' + hair, borderRadius: 14, marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <span style={{ ...mono, fontSize: 10, color: muted }}>PLAYER {i + 1} OF {short}</span>
              <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 3, background: paper2, color: muted, border: '1px solid ' + hair }}>NEW</span>
            </div>
            <input className="ck-input" placeholder="Full name" value={r.name} onChange={e => set(i, { name: e.target.value })} style={{ marginBottom: 10, fontSize: 15 }} />
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {['BAT', 'BOW', 'AR', 'WK'].map(role => (
                <button key={role} onClick={() => set(i, { role })} style={{ padding: '7px 12px', borderRadius: 999, border: '1px solid ' + (r.role === role ? ink : hair), background: r.role === role ? ink : paper, color: r.role === role ? paper : ink, fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>{role}</button>
              ))}
            </div>
          </div>
        ))}
        <div style={{ padding: 12, borderRadius: 12, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
          Match stats accrue to the placeholder. When the player joins matchday they search their name and claim it — you approve, stats migrate.
        </div>
      </div>
      <ChCta hint={valid ? `${short} ready to add` : 'Enter every name'} cta={`Add ${short} to squad`} disabled={!valid}
        secondary="Back" onSecondary={onBack}
        onCta={() => onDone(rows.map((r, i) => ({ id: 'unc_' + i + '_' + Date.now(), name: r.name.trim(), role: r.role, sub: 'Unclaimed', form: 'OK', unclaimed: true })))} />
    </>
  );
}

// ══════════════════════════════════════════════════════════
// STEP · Review
// ══════════════════════════════════════════════════════════
function StepReview({ team, opp, open, format, when, venue, xi, keeper, xiGated, message, onMessage }) {
  const near = message.length >= 240;
  const fmtRow = `${presetLabel(format)} · ${format.playersPerTeam}/side · ${ballLabel(format.ballType).toLowerCase()} · ${format.maxOversPerBowler} max/bow`;
  return (
    <div style={{ padding: '16px 18px 8px' }}>
      {/* summary card */}
      <div style={{ borderRadius: 16, border: '1px solid ' + hair, overflow: 'hidden', marginBottom: 16 }}>
        <div style={{ padding: 16, background: ink, color: paper }}>
          <div style={{ ...mono, fontSize: 9, opacity: 0.65, marginBottom: 12 }}>{open ? 'OPEN CHALLENGE' : 'FRIENDLY MATCH'}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <Crest size={44} bg={team.color} label={team.mono} />
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12.5, marginTop: 6 }}>{team.name}</div>
            </div>
            <Icon name="swords" size={18} stroke="rgba(255,255,255,0.55)" sw={2} />
            <div style={{ flex: 1, textAlign: 'center' }}>
              {open ? (
                <>
                  <div style={{ width: 44, height: 44, margin: '0 auto', borderRadius: 11, border: '1.5px dashed rgba(255,255,255,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Icon name="share" size={18} stroke="rgba(255,255,255,0.7)" sw={1.8} />
                  </div>
                  <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12.5, marginTop: 6 }}>Open</div>
                </>
              ) : (
                <>
                  <Crest size={44} bg={opp.color} label={opp.mono} />
                  <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12.5, marginTop: 6 }}>{opp.name}</div>
                </>
              )}
            </div>
          </div>
          <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid rgba(255,255,255,0.12)', textAlign: 'center' }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em' }}>{when.dateLabel ? when.dateLabel.split(' · ').slice(-1)[0] : 'Date TBD'} · {when.time || '—'}</div>
            <div style={{ fontSize: 12, opacity: 0.75, marginTop: 2 }}>{venue || 'Venue TBD'}</div>
          </div>
        </div>
        <div>
          <RevRow k="Format" v={`${presetLabel(format)} · ${format.playersPerTeam} a side`} />
          <RevRow k="Overs" v={`${format.oversPerInnings >= 50 && format.inningsPerSide === 2 ? 'Unlimited' : format.oversPerInnings} · ${format.ballsPerOver}-ball`} />
          <RevRow k="Ball · bowler" v={`${ballLabel(format.ballType)} · ${format.maxOversPerBowler} max`} />
          <RevRow k="Innings" v={`${format.inningsPerSide} per side`} />
          {!open && keeper && <RevRow k="Your keeper" v={(xi.find(p => p.id === keeper) || {}).name || '—'} last />}
          {open && <RevRow k="Claim window" v="24h · 6-digit code" last />}
        </div>
      </div>

      {/* message */}
      <SectionLabel hint={near ? `${message.length}/280` : ''}>Message {open ? '(shown on claim)' : `to ${opp.name}`}</SectionLabel>
      <textarea value={message} maxLength={280} onChange={e => onMessage(e.target.value)} rows={3}
        placeholder={open ? 'e.g. Friendly this Saturday — hardball, bring 11.' : 'e.g. Rematch from May? Same ground, same time.'}
        style={{ width: '100%', padding: '12px 14px', borderRadius: 14, border: '1px solid ' + hair, background: paper, color: ink, fontSize: 13, fontFamily: 'inherit', resize: 'none', outline: 'none', lineHeight: 1.5 }} />
      {near && <div style={{ ...mono, fontSize: 9, color: message.length >= 280 ? red : muted, textAlign: 'right', marginTop: 4 }}>{280 - message.length} LEFT</div>}

      {/* XI chips */}
      {!open && xiGated && (
        <div style={{ marginTop: 16 }}>
          <SectionLabel hint={`${xi.length} players`}>Your XI</SectionLabel>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {xi.map(p => (
              <span key={p.id} style={{ display: 'inline-flex', alignItems: 'center', gap: 4, padding: '5px 9px', borderRadius: 999, background: paper2, fontSize: 11.5, fontWeight: 500, color: ink, whiteSpace: 'nowrap' }}>
                {p.name}
                {p.captain && <span style={{ ...mono, fontSize: 7.5, padding: '1px 3px', borderRadius: 3, background: ink, color: paper }}>C</span>}
                {keeper === p.id && <span style={{ ...mono, fontSize: 7.5, padding: '1px 3px', borderRadius: 3, background: red, color: paper }}>WK</span>}
              </span>
            ))}
          </div>
        </div>
      )}
      <div style={{ height: 12 }} />
    </div>
  );
}
function RevRow({ k, v, last }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, padding: '11px 16px', borderBottom: last ? 'none' : '1px solid ' + hair, background: paper }}>
      <span style={{ fontSize: 12, color: muted, flexShrink: 0 }}>{k}</span>
      <span style={{ fontSize: 12.5, fontWeight: 600, color: ink, textAlign: 'right' }}>{v}</span>
    </div>
  );
}

// ── shared selectable card style
function selCard(on, radius = 14) {
  return {
    display: 'flex', alignItems: 'center', gap: 12, padding: 12,
    background: on ? paper2 : paper, border: '2px solid ' + (on ? ink : hair),
    borderRadius: radius, cursor: 'pointer', fontFamily: 'inherit', width: '100%',
  };
}
function Radio({ on }) {
  return (
    <div style={{ width: 22, height: 22, borderRadius: 999, flexShrink: 0, border: '2px solid ' + (on ? ink : hair), background: on ? ink : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {on && <Icon name="check" size={11} stroke={paper} sw={3} />}
    </div>
  );
}

// ── discard sheet
function DiscardSheet({ onKeep, onDiscard }) {
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 40, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      <div onClick={onKeep} style={{ position: 'absolute', inset: 0, background: 'rgba(20,18,14,0.4)' }} />
      <div style={{ position: 'relative', background: paper, borderRadius: '20px 20px 0 0', padding: '20px 18px calc(18px + env(safe-area-inset-bottom))' }}>
        <div style={{ width: 36, height: 4, borderRadius: 999, background: hair, margin: '0 auto 16px' }} />
        <div style={display(20)}>Discard this challenge?</div>
        <div style={{ fontSize: 13, color: ink2, marginTop: 6, lineHeight: 1.5 }}>Your selections won't be saved — the app is online-only, with no drafts.</div>
        <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
          <button onClick={onKeep} style={{ flex: 1, padding: '13px 0', borderRadius: 12, border: '1px solid ' + hair, background: paper, color: ink, fontFamily: 'inherit', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Keep editing</button>
          <button onClick={onDiscard} style={{ flex: 1, padding: '13px 0', borderRadius: 12, border: 'none', background: paper2, color: ink, fontFamily: 'inherit', fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>Discard</button>
        </div>
      </div>
    </div>
  );
}

window.SendChallenge = SendChallenge;

})();

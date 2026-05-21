// MatchRequest.jsx — the OPPONENT captain's side of the friendly flow.
// Sender side: MatchSetup.jsx (6 steps → Request sent)
// THIS file: receiver sees the request → Accept · Propose changes · Decline → final state
//
// State machine (one component, props pick the starting state):
//   review           — full request detail, three CTAs
//   propose          — counter-proposal form (date · time · venue · overs · players)
//   propose-sent     — counter-proposal queued, ball back in Lions' court
//   decline          — optional reason picker
//   declined         — declined confirmation
//   accepted         — confirmed match, both calendars updated, next steps
//
// Public API:
//   <CkMatchRequest initialView="review" />

(function () {

const ink = 'var(--ink)';
const ink2 = 'var(--ink-2)';
const muted = 'var(--muted)';
const paper = 'var(--paper)';
const paper2 = 'var(--paper-2)';
const hair = 'var(--hairline)';
const surface = 'var(--surface)';
const red = 'var(--red)';
const redSoft = 'var(--red-soft)';
const green = 'var(--green)';
const greenSoft = 'var(--green-soft)';
const amber = 'var(--amber)';
const cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase' };
const display = (s) => ({ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: s, lineHeight: 1.05, color: ink });

// The request that's being reviewed — would come from notification deep-link in real app
const REQ = {
  id: 'req_kx91',
  from: { name: 'Lahore Lions', mono: 'LL', color: red, captain: 'Bilal Ahmed', captainMono: 'BA' },
  to:   { name: 'Karachi Eagles', mono: 'KE', color: 'oklch(0.55 0.15 250)', captain: 'You · Imran Saeed' },
  format: {
    type: 'Friendly',
    overs: 20,
    players: 11,
    ball: 'White ball',
    pp: 6,
    super: true,
    free: true,
  },
  when: { date: 'Sat 18 May', time: '15:00' },
  venue: 'Model Town Ground',
  scorer: 'Opponent captain (you)',
  history: 'Played 3× · won 2 · last May 2 (Lions 142/6 def. Eagles 119/9)',
  sent: '38 min ago',
  expiresIn: '23 h',
};

// ═══════════════════════════════════════════════════════════════════════════
// Shared chrome
// ═══════════════════════════════════════════════════════════════════════════

function RqHeader({ kicker, title, sub, onBack, right }) {
  return (
    <div style={{ padding: '14px 18px 14px', borderBottom: '1px solid ' + hair, background: paper }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        {onBack && (
          <button onClick={onBack} style={{
            width: 32, height: 32, borderRadius: 8, border: '1px solid ' + hair,
            background: paper, cursor: 'pointer', display: 'flex',
            alignItems: 'center', justifyContent: 'center', padding: 0,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
          </button>
        )}
        <div style={{ ...mono, fontSize: 10, color: muted, flex: 1 }}>{kicker}</div>
        {right}
      </div>
      <div style={display(24)}>{title}</div>
      {sub && <div style={{ fontSize: 13, color: ink2, marginTop: 4, lineHeight: 1.4 }}>{sub}</div>}
    </div>
  );
}

function StickyCta({ children }) {
  return (
    <div style={{
      borderTop: '1px solid ' + hair, padding: '12px 18px',
      background: paper, display: 'flex', gap: 10, alignItems: 'center',
      paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
    }}>{children}</div>
  );
}

function Primary({ children, danger, disabled, onClick }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      flex: 1, padding: '12px 16px', borderRadius: 10, border: 'none',
      background: disabled ? paper2 : (danger ? red : ink),
      color: disabled ? muted : paper,
      fontWeight: 700, fontSize: 14, cursor: disabled ? 'default' : 'pointer',
      fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    }}>{children}</button>
  );
}

function Ghost({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '12px 16px', borderRadius: 10,
      border: '1px solid ' + hair, background: paper, color: ink,
      fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
    }}>{children}</button>
  );
}

function SectionLabel({ children, hint }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
      <span style={{ ...mono, fontSize: 10, color: muted }}>{children}</span>
      {hint && <span style={{ fontSize: 11, color: muted }}>{hint}</span>}
    </div>
  );
}

function Crest({ size = 44, bg, fg = paper, label }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.23, flexShrink: 0,
      background: bg, color: fg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: size * 0.38, letterSpacing: '-0.03em',
    }}>{label}</div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW · review (default landing)
// ═══════════════════════════════════════════════════════════════════════════

function ReviewView({ onAccept, onPropose, onDecline }) {
  return (
    <>
      <RqHeader
        kicker="Match request · friendly"
        title={<>You've been challenged.</>}
        sub={<><b style={{ color: ink }}>{REQ.from.captain}</b> from {REQ.from.name} wants to play {REQ.to.name}.</>}
        right={<span style={{ ...mono, fontSize: 9, color: amber, padding: '4px 8px', borderRadius: 6, background: cream }}>Expires {REQ.expiresIn}</span>}
      />

      <div style={{ flex: 1, overflowY: 'auto' }}>

        {/* Hero match card */}
        <div style={{ padding: '14px 18px 4px' }}>
          <div style={{
            padding: '18px 16px', background: ink, color: paper, borderRadius: 14,
          }}>
            <div style={{ ...mono, fontSize: 9, opacity: 0.7, marginBottom: 10 }}>
              {REQ.format.type} · {REQ.format.overs} overs · {REQ.format.players}-a-side
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{ flex: 1, textAlign: 'center' }}>
                <Crest size={48} bg={REQ.from.color} label={REQ.from.mono} />
                <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, marginTop: 6 }}>{REQ.from.name}</div>
                <div style={{ fontSize: 10, opacity: 0.65, marginTop: 2 }}>Challenger</div>
              </div>
              <div style={{ ...mono, fontSize: 12, opacity: 0.7 }}>VS</div>
              <div style={{ flex: 1, textAlign: 'center' }}>
                <Crest size={48} bg={REQ.to.color} label={REQ.to.mono} />
                <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, marginTop: 6 }}>{REQ.to.name}</div>
                <div style={{ fontSize: 10, opacity: 0.65, marginTop: 2 }}>You</div>
              </div>
            </div>
            <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid rgba(255,255,255,0.12)', textAlign: 'center', display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em' }}>{REQ.when.date} · {REQ.when.time}</div>
              <div style={{ fontSize: 12, opacity: 0.75 }}>{REQ.venue}</div>
            </div>
          </div>
        </div>

        {/* Sender note */}
        <div style={{ padding: '16px 18px 6px' }}>
          <div style={{
            display: 'flex', gap: 12, padding: 12, background: paper2, borderRadius: 12,
          }}>
            <Crest size={32} bg={ink} fg={paper} label={REQ.from.captainMono} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600 }}>{REQ.from.captain}</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 1, marginBottom: 6 }}>Captain · {REQ.from.name} · sent {REQ.sent}</div>
              <div style={{ fontSize: 12, color: ink2, lineHeight: 1.5, fontStyle: 'italic' }}>
                "Rematch from May? Same ground, same time. Bring your A team."
              </div>
            </div>
          </div>
        </div>

        {/* Head-to-head */}
        <div style={{ padding: '12px 18px 6px' }}>
          <SectionLabel>Head-to-head</SectionLabel>
          <div style={{ padding: 10, background: paper, border: '1px solid ' + hair, borderRadius: 10, fontSize: 12, color: ink2, lineHeight: 1.5 }}>
            {REQ.history}
          </div>
        </div>

        {/* Format details */}
        <div style={{ padding: '12px 18px 6px' }}>
          <SectionLabel>Format details</SectionLabel>
          <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, overflow: 'hidden' }}>
            <DetailRow k="Overs" v={`${REQ.format.overs} per innings`} />
            <DetailRow k="Players" v={`${REQ.format.players} a side`} />
            <DetailRow k="Ball" v={REQ.format.ball} />
            <DetailRow k="Powerplay" v={`${REQ.format.pp} overs`} />
            <DetailRow k="Super over" v={REQ.format.super ? 'On tie' : 'Off'} />
            <DetailRow k="Free hit" v={REQ.format.free ? 'Front-foot no-ball' : 'Off'} last />
          </div>
        </div>

        {/* Logistics */}
        <div style={{ padding: '12px 18px 6px' }}>
          <SectionLabel>Logistics</SectionLabel>
          <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, overflow: 'hidden' }}>
            <DetailRow k="Venue" v={REQ.venue + ' · 8 km away'} />
            <DetailRow k="When" v={`${REQ.when.date} · ${REQ.when.time}`} />
            <DetailRow k="Scorer" v={REQ.scorer} last />
          </div>
        </div>

        {/* Lions' XI (penciled in) */}
        <div style={{ padding: '12px 18px 6px' }}>
          <SectionLabel hint="Pencilled in by Lions · may change">Their playing XI</SectionLabel>
          <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, padding: 12 }}>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {[
                { n: 'Bilal Ahmed',  c: true },
                { n: 'Adeel Sheikh', wk: true },
                { n: 'Faraz Khan' },
                { n: 'Hamza Tariq' },
                { n: 'Usman Riaz' },
                { n: 'Imran Akhtar' },
                { n: 'Shahid Iqbal' },
                { n: 'Junaid Ali' },
                { n: 'Tariq Mehmood' },
                { n: 'Saad Anwar' },
                { n: 'Bilal Khan' },
              ].map(p => (
                <span key={p.n} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                  padding: '5px 9px', borderRadius: 999, background: paper2,
                  fontSize: 11.5, fontWeight: 500, color: ink,
                }}>
                  {p.n}
                  {p.c  && <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: ink,  color: paper }}>C</span>}
                  {p.wk && <span style={{ ...mono, fontSize: 8, padding: '1px 4px', borderRadius: 3, background: red, color: paper }}>WK</span>}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Roster heads-up */}
        <div style={{ padding: '12px 18px 24px' }}>
          <div style={{
            display: 'flex', gap: 10, padding: 12, background: greenSoft, borderRadius: 12,
            alignItems: 'flex-start',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="oklch(0.36 0.10 148)" strokeWidth="2" style={{ flexShrink: 0, marginTop: 1 }}><polyline points="20 6 9 17 4 12"/></svg>
            <div style={{ fontSize: 12, color: 'oklch(0.30 0.10 148)', lineHeight: 1.45 }}>
              Your squad has <b>18 players</b> for an 11-a-side match — you'll pick your XI after accepting.
            </div>
          </div>
        </div>

      </div>

      {/* Three-way CTA */}
      <div style={{
        borderTop: '1px solid ' + hair, padding: '12px 18px',
        background: paper, paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
      }}>
        <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
          <button onClick={onDecline} style={{
            padding: '12px 16px', borderRadius: 10,
            border: '1px solid ' + hair, background: paper, color: ink,
            fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: 'inherit',
          }}>Decline</button>
          <button onClick={onPropose} style={{
            flex: 1, padding: '12px 16px', borderRadius: 10,
            border: '1px solid ' + ink, background: paper, color: ink,
            fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: 'inherit',
          }}>Propose changes</button>
        </div>
        <button onClick={onAccept} style={{
          flex: 1, padding: '12px 16px', borderRadius: 10, border: 'none',
          background: ink, color: paper,
          fontWeight: 700, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          Accept · pick XI
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
        </button>
      </div>
    </>
  );
}

function DetailRow({ k, v, last }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '11px 14px', borderBottom: last ? 'none' : '1px solid ' + hair,
    }}>
      <span style={{ fontSize: 12, color: muted }}>{k}</span>
      <span style={{ fontSize: 13, fontWeight: 600, color: ink, textAlign: 'right' }}>{v}</span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW · propose (counter-proposal)
// ═══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
// VIEW · accept-xi (pick OUR XI before confirming the match)
// ══════════════════════════════════════════════════════════════════════════

const EAGLES_SQUAD = [
  { id: 'e1',  name: 'Imran Saeed',     role: 'CPT · RHB · RM',  form: 'Hot' },
  { id: 'e2',  name: 'Kashif Bhatti',   role: 'WK · RHB',         form: 'OK'  },
  { id: 'e3',  name: 'Naveed Hassan',   role: 'AR · LHB · OS',   form: 'Hot' },
  { id: 'e4',  name: 'Owais Memon',     role: 'BAT · RHB',        form: 'OK'  },
  { id: 'e5',  name: 'Asad Qureshi',    role: 'BWL · RHB · RFM', form: 'Hot' },
  { id: 'e6',  name: 'Rizwan Aslam',    role: 'BAT · LHB',        form: 'OK'  },
  { id: 'e7',  name: 'Hassan Mirza',    role: 'AR · RHB · LFM',  form: 'Cold'},
  { id: 'e8',  name: 'Yasir Shabbir',   role: 'BWL · RHB · SLA', form: 'OK'  },
  { id: 'e9',  name: 'Salman Akhtar',   role: 'BAT · RHB',        form: 'Hot' },
  { id: 'e10', name: 'Bilal Pirzada',   role: 'AR · RHB · RM',   form: 'OK'  },
  { id: 'e11', name: 'Faisal Khan',     role: 'BWL · LHB · RFM', form: 'OK'  },
  { id: 'e12', name: 'Ahmed Niazi',     role: 'BAT · RHB',        form: 'Cold'},
  { id: 'e13', name: 'Wasim Younus',    role: 'BWL · RHB · LFM', form: 'OK'  },
  { id: 'e14', name: 'Junaid Salimi',   role: 'WK · LHB',         form: 'Hot' },
  { id: 'e15', name: 'Tahir Anjum',     role: 'AR · RHB · OS',   form: 'OK'  },
  { id: 'e16', name: 'Mohsin Pasha',    role: 'BAT · LHB',        form: 'OK'  },
  { id: 'e17', name: 'Sami Hashmi',     role: 'BWL · RHB · RFM', form: 'OK'  },
  { id: 'e18', name: 'Adnan Lodhi',     role: 'BAT · RHB',        form: 'Hot' },
];

function AcceptXIView({ onBack, onConfirm, demoThin }) {
  const need = REQ.format.players;
  const fullSquad = EAGLES_SQUAD;
  const squad = demoThin ? fullSquad.slice(0, Math.max(1, need - 3)) : fullSquad;
  const isShort = squad.length < need;
  const safeNeed = Math.min(need, squad.length);

  const [gatePassed, setGatePassed] = React.useState(!isShort);
  const [picked, setPicked] = React.useState(new Set(squad.slice(0, safeNeed).map(p => p.id)));
  const [keeper, setKeeper] = React.useState(squad[1] ? squad[1].id : squad[0].id);

  if (isShort && !gatePassed) {
    return <AcceptGate need={need} have={squad.length} onBack={onBack} onResolve={() => setGatePassed(true)} />;
  }

  const toggle = (id) => {
    setPicked(prev => {
      const next = new Set(prev);
      if (next.has(id)) { if (id === keeper) return prev; next.delete(id); }
      else if (next.size < need) next.add(id);
      return next;
    });
  };

  const playing  = squad.filter(p => picked.has(p.id));
  const reserves = squad.filter(p => !picked.has(p.id));
  const ready = picked.size === safeNeed && picked.has(keeper);
  const FORM_BG = { Hot: greenSoft, OK: paper2, Cold: cream };
  const FORM_FG = { Hot: 'oklch(0.36 0.10 148)', OK: ink2, Cold: muted };

  return (
    <>
      <RqHeader
        kicker="Accept · pick your XI"
        title="Lock your Eagles XI."
        sub={`Pick ${safeNeed} from your squad of ${squad.length}. Lions will see your XI when you accept — same way you saw theirs.`}
        onBack={onBack}
      />

      <div style={{
        padding: '10px 18px', borderBottom: '1px solid ' + hair, background: paper,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{ ...mono, fontSize: 10, color: picked.size === safeNeed ? green : ink2 }}>
          XI · {picked.size}/{safeNeed}
        </div>
        <div style={{ flex: 1, height: 4, background: paper2, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ width: `${(picked.size / safeNeed) * 100}%`, height: '100%', background: picked.size === safeNeed ? green : ink, transition: 'width 0.15s' }}/>
        </div>
        <div style={{ ...mono, fontSize: 10, color: muted }}>
          {squad.length - picked.size} RES
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto' }}>
        <div style={{ padding: '12px 18px 6px', display: 'flex', gap: 6 }}>
          <button onClick={() => setPicked(new Set(squad.slice(0, safeNeed).map(p => p.id)))} style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>AUTO · BEST FORM</button>
          <button onClick={() => setPicked(new Set())} style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>CLEAR</button>
        </div>

        <div style={{ padding: '8px 18px 4px', ...mono, fontSize: 10, color: ink }}>PLAYING XI · {picked.size}/{safeNeed}</div>
        {playing.map((p, i) => (
          <AXIRow key={p.id} p={p} picked onToggle={() => toggle(p.id)} isKeeper={keeper === p.id} onMakeKeeper={() => setKeeper(p.id)} formBg={FORM_BG[p.form]} formFg={FORM_FG[p.form]} hasBorder={i > 0} />
        ))}

        {reserves.length > 0 && (
          <>
            <div style={{ padding: '14px 18px 6px', borderTop: '1px solid ' + hair, marginTop: 6, ...mono, fontSize: 10, color: muted }}>
              RESERVES · {reserves.length}
            </div>
            {reserves.map((p, i) => (
              <AXIRow key={p.id} p={p} onToggle={() => toggle(p.id)} disabled={picked.size >= need} formBg={FORM_BG[p.form]} formFg={FORM_FG[p.form]} hasBorder={i > 0} />
            ))}
          </>
        )}

        <div style={{ padding: '14px 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 10, background: greenSoft, color: 'oklch(0.30 0.10 148)', fontSize: 11.5, lineHeight: 1.5 }}>
            On <b>Confirm</b>: match becomes <b>Confirmed</b> on both calendars, Lions and your {picked.size} players get notified, and your XI is locked until the toss.
          </div>
        </div>
      </div>

      <StickyCta>
        <Ghost onClick={onBack}>Back</Ghost>
        <Primary disabled={!ready} onClick={onConfirm}>
          {ready ? 'Confirm match' : `Pick ${safeNeed - picked.size} more`}
          {ready && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><polyline points="20 6 9 17 4 12"/></svg>}
        </Primary>
      </StickyCta>
    </>
  );
}

function AXIRow({ p, picked, isKeeper, onToggle, onMakeKeeper, disabled, formBg, formFg, hasBorder }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '10px 18px',
      borderTop: hasBorder ? '1px solid ' + hair : 'none',
      background: picked ? paper : 'transparent', opacity: disabled ? 0.5 : 1,
    }}>
      <button onClick={!disabled ? onToggle : undefined} style={{
        width: 22, height: 22, borderRadius: 6, flexShrink: 0,
        border: picked ? 'none' : '1.5px solid var(--soft)',
        background: picked ? ink : paper,
        cursor: disabled ? 'default' : 'pointer', padding: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {picked && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
      </button>
      <div style={{
        width: 32, height: 32, borderRadius: 9, flexShrink: 0,
        background: paper2, color: ink2,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
      }}>{p.name.split(' ').map(w => w[0]).join('').slice(0, 2)}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{p.name}</span>
          {isKeeper && <span style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', fontSize: 8, padding: '1px 5px', borderRadius: 3, background: red, color: paper }}>WK</span>}
          <span style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', fontSize: 8, padding: '2px 5px', borderRadius: 4, background: formBg, color: formFg }}>{p.form.toUpperCase()}</span>
        </div>
        <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{p.role}</div>
      </div>
      {picked && !isKeeper && (
        <button onClick={onMakeKeeper} style={{
          fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em',
          fontSize: 8, padding: '4px 7px', borderRadius: 5,
          border: '1px solid ' + hair, background: paper, color: muted, cursor: 'pointer',
        }}>WK</button>
      )}
    </div>
  );
}

// Receiver-side gate (when Eagles' squad < format.players)
function AcceptGate({ need, have, onBack, onResolve }) {
  const short = need - have;
  const [pick, setPick] = React.useState(null);
  const opts = [
    { id: 'borrow',    title: 'Borrow a player',   sub: `Find ${short} guest${short === 1 ? '' : 's'} from a nearby team — Lions agree.`, tint: ink, rec: true },
    { id: 'unclaimed', title: 'Add as unclaimed',  sub: 'Just a name. Stats follow when they claim later.', tint: amber },
  ];
  return (
    <>
      <RqHeader
        kicker="Accept · roster gap"
        title="You're short."
        sub={`Lions need ${need} a side. Eagles have ${have} confirmed. Resolve before picking XI.`}
        onBack={onBack}
      />
      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>
        <div style={{
          padding: 14, borderRadius: 12, background: cream, color: ink,
          display: 'flex', alignItems: 'center', gap: 14, marginBottom: 16,
        }}>
          <div style={{
            width: 52, height: 52, borderRadius: 12, background: amber, color: paper,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 24, letterSpacing: '-0.04em',
          }}>−{short}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 700 }}>Short {short} player{short === 1 ? '' : 's'}</div>
            <div style={{ fontSize: 11, color: ink2, marginTop: 2 }}>Have {have} · need {need}</div>
            <div style={{ display: 'flex', gap: 3, marginTop: 6 }}>
              {Array.from({ length: need }, (_, i) => (
                <span key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i < have ? green : 'rgba(20,18,14,0.10)' }} />
              ))}
            </div>
          </div>
        </div>

        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>FILL THE GAP</div>
        {opts.map(o => {
          const on = pick === o.id;
          return (
            <button key={o.id} onClick={() => setPick(o.id)} style={{
              width: '100%', display: 'flex', gap: 12, padding: 12, marginBottom: 8,
              background: on ? paper2 : paper,
              border: '2px solid ' + (on ? ink : hair),
              borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                background: o.tint, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16,
              }}>{o.id === 'borrow' ? '⊟' : '?'}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                  <span style={{ fontWeight: 700, fontSize: 13.5, color: ink }}>{o.title}</span>
                  {o.rec && <span style={{ ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 4, background: ink, color: paper }}>MOST COMMON</span>}
                </div>
                <div style={{ fontSize: 11.5, color: muted, marginTop: 3, lineHeight: 1.45 }}>{o.sub}</div>
              </div>
            </button>
          );
        })}

        <div style={{ marginTop: 14, padding: 14, background: paper2, borderRadius: 12, fontSize: 12, color: ink2, lineHeight: 1.5 }}>
          <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 6 }}>CAN'T FIELD A SIDE?</div>
          Go back and tap <b style={{ color: ink }}>Decline</b> on the request, or propose a smaller format with <b style={{ color: ink }}>Propose changes</b>. You haven't accepted yet — no walkover, no penalty.
        </div>
      </div>
      <StickyCta>
        <Ghost onClick={onBack}>Back</Ghost>
        <Primary disabled={!pick} onClick={() => onResolve(pick)}>
          Continue → pick XI
        </Primary>
      </StickyCta>
    </>
  );
}

function ProposeView({ onBack, onSend }) {
  const [edits, setEdits] = React.useState({});
  const [note, setNote] = React.useState('');
  const toggleField = (k) => setEdits(p => ({ ...p, [k]: !p[k] }));

  const fields = [
    { k: 'date',    label: 'Date',           orig: REQ.when.date,        suggest: 'Sun 19 May' },
    { k: 'time',    label: 'Start time',     orig: REQ.when.time,        suggest: '14:00' },
    { k: 'venue',   label: 'Venue',          orig: REQ.venue,            suggest: 'Race Course Ground' },
    { k: 'overs',   label: 'Overs',          orig: `${REQ.format.overs} overs`, suggest: '15 overs' },
    { k: 'players', label: 'Players / side', orig: `${REQ.format.players}-a-side`, suggest: '9-a-side' },
    { k: 'ball',    label: 'Ball',           orig: REQ.format.ball,      suggest: 'Tape ball' },
  ];

  const changeCount = Object.values(edits).filter(Boolean).length;

  return (
    <>
      <RqHeader
        kicker="Counter-proposal"
        title="Suggest changes."
        sub={<>Toggle the fields you want different. Lions get one tap to accept your counter — match stays Pending until they do.</>}
        onBack={onBack}
      />

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 20px' }}>
        <SectionLabel hint={changeCount > 0 ? `${changeCount} change${changeCount === 1 ? '' : 's'}` : 'Tap to flip'}>What to change</SectionLabel>

        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12, overflow: 'hidden', marginBottom: 18 }}>
          {fields.map((f, i) => {
            const on = !!edits[f.k];
            return (
              <button key={f.k} onClick={() => toggleField(f.k)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
                background: on ? paper2 : paper,
                border: 'none', borderTop: i ? '1px solid ' + hair : 'none',
                width: '100%', textAlign: 'left', cursor: 'pointer', fontFamily: 'inherit',
              }}>
                <div style={{
                  width: 36, height: 22, borderRadius: 999, padding: 2, flexShrink: 0,
                  background: on ? ink : 'rgba(20,18,14,0.10)',
                  display: 'flex', justifyContent: on ? 'flex-end' : 'flex-start',
                  transition: 'background 0.15s',
                }}>
                  <div style={{ width: 18, height: 18, borderRadius: 999, background: paper }}/>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: ink }}>{f.label}</div>
                  <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>
                    {on
                      ? <><span style={{ textDecoration: 'line-through' }}>{f.orig}</span> → <b style={{ color: ink }}>{f.suggest}</b></>
                      : f.orig}
                  </div>
                </div>
                {on && (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="1.8" style={{ flexShrink: 0 }}><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/></svg>
                )}
              </button>
            );
          })}
        </div>

        <SectionLabel>Note to Lions (optional)</SectionLabel>
        <textarea
          value={note}
          onChange={e => setNote(e.target.value)}
          placeholder="e.g. Our keeper is unavailable Saturday — can we do Sunday?"
          rows={3}
          style={{
            width: '100%', padding: '12px 14px', borderRadius: 12,
            border: '1px solid ' + hair, background: paper, color: ink,
            fontSize: 13, fontFamily: 'inherit', resize: 'none', outline: 'none',
          }}
        />
        <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 4, textAlign: 'right' }}>{note.length}/200</div>

        {changeCount === 0 && (
          <div style={{ marginTop: 14, padding: 12, background: cream, borderRadius: 10, fontSize: 12, color: ink2, display: 'flex', gap: 10, alignItems: 'flex-start' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink2} strokeWidth="1.8" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
            <span>You haven't changed anything yet. Toggle at least one field, or just accept the original.</span>
          </div>
        )}
      </div>

      <StickyCta>
        <Ghost onClick={onBack}>Back</Ghost>
        <Primary disabled={changeCount === 0} onClick={onSend}>
          Send counter-proposal
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
        </Primary>
      </StickyCta>
    </>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW · decline (reason picker)
// ═══════════════════════════════════════════════════════════════════════════

function DeclineView({ onBack, onConfirm }) {
  const [reason, setReason] = React.useState(null);
  const reasons = [
    { k: 'roster',  t: 'Roster too thin',           s: "We don't have enough players for this date" },
    { k: 'busy',    t: 'Already playing that day',  s: "We have another fixture booked" },
    { k: 'unknown', t: "Don't know this team",      s: "We'd rather not — no record yet" },
    { k: 'format',  t: "Format doesn't suit us",    s: "Different overs / ball type / players" },
    { k: 'venue',   t: 'Venue too far',             s: 'Travel is impractical' },
    { k: 'other',   t: 'Other',                     s: "I'll add a short note" },
  ];

  return (
    <>
      <RqHeader
        kicker="Declining match"
        title="Tell Lions why."
        sub="Optional but appreciated — helps both teams. They won't see anything except the reason you pick."
        onBack={onBack}
      />

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 20px' }}>
        <div style={{ display: 'grid', gap: 8 }}>
          {reasons.map(r => {
            const active = reason === r.k;
            return (
              <button key={r.k} onClick={() => setReason(r.k)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: 14,
                background: active ? paper2 : paper,
                border: '2px solid ' + (active ? ink : hair),
                borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
              }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{r.t}</div>
                  <div style={{ fontSize: 11.5, color: muted, marginTop: 2, lineHeight: 1.4 }}>{r.s}</div>
                </div>
                <div style={{
                  width: 20, height: 20, borderRadius: 999, flexShrink: 0,
                  border: '2px solid ' + (active ? ink : hair),
                  background: active ? ink : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {active && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
                </div>
              </button>
            );
          })}
        </div>

        <div style={{ marginTop: 18, padding: 12, background: paper2, borderRadius: 10, fontSize: 12, color: ink2, lineHeight: 1.5 }}>
          You can always restart this match by sending Lions a fresh challenge later.
        </div>
      </div>

      <StickyCta>
        <Ghost onClick={onBack}>Back</Ghost>
        <Primary danger onClick={onConfirm}>
          {reason ? 'Decline & send reason' : 'Decline without reason'}
        </Primary>
      </StickyCta>
    </>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW · result states (accepted / declined / proposal sent)
// ═══════════════════════════════════════════════════════════════════════════

function ResultView({ kind, onClose }) {
  const cfg = {
    accepted: {
      bg: green,
      icon: <polyline points="20 6 9 17 4 12"/>,
      title: 'Match confirmed.',
      sub: <>Lahore Lions vs Karachi Eagles is on your calendar. We've notified <b style={{ color: ink }}>Bilal Ahmed</b> and both squads.</>,
      tone: 'good',
      next: [
        { t: 'Pick your XI now',          s: 'Pencil in 11 from your squad of 18',              primary: true },
        { t: 'Add to team calendar',      s: 'iCal · Google · WhatsApp share',                  primary: false },
        { t: 'Set a team huddle',         s: 'Pre-match note for your players',                 primary: false },
      ],
    },
    'propose-sent': {
      bg: amber,
      icon: <><path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4z"/></>,
      title: 'Counter-proposal sent.',
      sub: <>Ball back in Lions' court. They have <b style={{ color: ink }}>24 h</b> to accept or counter again. Match stays Pending until they reply.</>,
      tone: 'pending',
      next: [
        { t: 'View pending match',        s: "It's already on your calendar as Pending",        primary: true },
        { t: 'Message Lions captain',     s: 'Quick chat helps move things along',              primary: false },
      ],
    },
    declined: {
      bg: muted,
      icon: <><path d="M6 6l12 12"/><path d="M18 6L6 18"/></>,
      title: 'Match declined.',
      sub: <>Lions have been notified. Nothing on your calendar.</>,
      tone: 'neutral',
      next: [
        { t: 'Browse other challengers',  s: '2 teams nearby are looking for a friendly',       primary: true },
        { t: 'Send Lions a fresh challenge', s: 'Different date or format',                      primary: false },
      ],
    },
  }[kind];

  return (
    <>
      <div style={{ flex: 1, overflowY: 'auto', padding: '50px 24px 30px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        <div style={{
          width: 88, height: 88, borderRadius: 22, background: cfg.bg, color: paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 22,
        }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">{cfg.icon}</svg>
        </div>
        <div style={{ ...display(26), marginBottom: 8 }}>{cfg.title}</div>
        <div style={{ fontSize: 13, color: ink2, lineHeight: 1.5, maxWidth: 300, marginBottom: 26 }}>{cfg.sub}</div>

        {/* Match summary card (only on accepted) */}
        {kind === 'accepted' && (
          <div style={{
            width: '100%', padding: 14, background: ink, color: paper, borderRadius: 12, marginBottom: 24,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <Crest size={36} bg={REQ.from.color} label={REQ.from.mono} />
              <div style={{ flex: 1, textAlign: 'left' }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>Lions vs Eagles</div>
                <div style={{ fontSize: 11, opacity: 0.7, marginTop: 1 }}>{REQ.when.date} · {REQ.when.time} · {REQ.venue}</div>
              </div>
              <Crest size={36} bg={REQ.to.color} label={REQ.to.mono} />
            </div>
          </div>
        )}

        {/* Next steps */}
        <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {cfg.next.map((n, i) => (
            <button key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '14px',
              borderRadius: 12, cursor: 'pointer', textAlign: 'left',
              border: n.primary ? 'none' : '1px solid ' + hair,
              background: n.primary ? ink : surface,
              color: n.primary ? paper : ink,
              fontFamily: 'inherit',
            }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 600 }}>{n.t}</div>
                <div style={{ fontSize: 11, opacity: n.primary ? 0.7 : 1, color: n.primary ? paper : muted, marginTop: 1 }}>{n.s}</div>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ opacity: n.primary ? 0.7 : 0.5 }}><path d="M9 18l6-6-6-6"/></svg>
            </button>
          ))}
        </div>
      </div>

      <StickyCta>
        <Primary onClick={onClose}>Done</Primary>
      </StickyCta>
    </>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT
// ═══════════════════════════════════════════════════════════════════════════

function CkMatchRequest({ initialView = 'review', demoThin } = {}) {
  const [view, setView] = React.useState(initialView);
  const back = () => setView('review');
  const close = () => setView('review');

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      {view === 'review'        && <ReviewView   onAccept={() => setView('accept-xi')} onPropose={() => setView('propose')} onDecline={() => setView('decline')} />}
      {view === 'accept-xi'     && <AcceptXIView onBack={() => setView('review')} onConfirm={() => setView('accepted')} demoThin={demoThin} />}
      {view === 'propose'       && <ProposeView  onBack={back} onSend={() => setView('propose-sent')} />}
      {view === 'decline'       && <DeclineView  onBack={back} onConfirm={() => setView('declined')} />}
      {view === 'accepted'      && <ResultView   kind="accepted"     onClose={close} />}
      {view === 'propose-sent'  && <ResultView   kind="propose-sent" onClose={close} />}
      {view === 'declined'      && <ResultView   kind="declined"     onClose={close} />}
    </div>
  );
}

window.CkMatchRequest = CkMatchRequest;

})();

// MatchStart.jsx — simplified 3-stage match-day flow.
// One match, two phones, runs in parallel. Each phone shows its own perspective.
//
//   Stage 1 · Toss          → sender's phone hosts the coin (both captains watch);
//                              winner taps Bat/Bowl on that phone.
//                              receiver's phone shows "Imran, walk to Bilal's phone".
//
//   Stage 2 · Lineup        → parallel. Batting captain picks openers on HIS phone.
//                              Bowling captain picks opening bowler on HIS phone.
//                              Each side waits for the other to submit.
//
//   Stage 3 · Ready         → batting captain (next scorer) taps "Start match".
//                              The other phone shows "Match starting…" — briefly.
//
// Public API:
//   <CkMatchStart viewer="sender"   stage="toss" />
//   <CkMatchStart viewer="receiver" stage="lineup" />
//   viewer:  'sender' (Lions / Bilal) | 'receiver' (Eagles / Imran)
//   stage:   'toss' | 'lineup' | 'ready' (controls which stage opens)

(function () {

const ink = 'var(--ink)', ink2 = 'var(--ink-2)', muted = 'var(--muted)';
const paper = 'var(--paper)', paper2 = 'var(--paper-2)', surface = 'var(--surface)';
const hair = 'var(--hairline)';
const red = 'var(--red)', redSoft = 'var(--red-soft)';
const green = 'var(--green)', greenSoft = 'var(--green-soft)';
const amber = 'var(--amber)', cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase' };
const display = (s) => ({ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: s, lineHeight: 1.05, color: ink });

// ── Match context ────────────────────────────────────────
const MATCH = {
  sender:   { team: 'Lions',  full: 'Lahore Lions',   mono: 'LL', color: red,                          captain: 'Bilal',  captainFull: 'Bilal Ahmed', captainMono: 'BA' },
  receiver: { team: 'Eagles', full: 'Karachi Eagles', mono: 'KE', color: 'oklch(0.55 0.15 250)',       captain: 'Imran',  captainFull: 'Imran Saeed', captainMono: 'IS' },
  when:  '3:00 PM',
  venue: 'Model Town Ground',
  format: 'T20 friendly · 11-a-side · White ball',
};

const LIONS_XI = [
  { id: 's1', n: 'Bilal Ahmed',   r: 'CPT · RHB · RM',  bat: true, bowl: true },
  { id: 's2', n: 'Adeel Sheikh',  r: 'WK · LHB',         bat: true, bowl: false },
  { id: 's3', n: 'Faraz Khan',    r: 'AR · RHB · OS',    bat: true, bowl: true },
  { id: 's4', n: 'Hamza Tariq',   r: 'BAT · RHB',        bat: true, bowl: false },
  { id: 's5', n: 'Usman Riaz',    r: 'AR · RHB · RFM',   bat: true, bowl: true },
  { id: 's6', n: 'Imran Akhtar',  r: 'BWL · RHB · RFM',  bat: false, bowl: true },
  { id: 's7', n: 'Shahid Iqbal',  r: 'BAT · LHB',        bat: true, bowl: false },
  { id: 's8', n: 'Junaid Ali',    r: 'WK · RHB',         bat: true, bowl: false },
  { id: 's9', n: 'Tariq Mehmood', r: 'AR · LHB · SLA',   bat: true, bowl: true },
  { id: 's10', n: 'Saad Anwar',   r: 'BWL · RHB · LFM',  bat: false, bowl: true },
  { id: 's11', n: 'Bilal Khan',   r: 'BAT · RHB',        bat: true, bowl: false },
];

const EAGLES_XI = [
  { id: 'e1', n: 'Imran Saeed',    r: 'CPT · RHB · RM',   bat: true,  bowl: true },
  { id: 'e2', n: 'Kashif Bhatti',  r: 'WK · RHB',         bat: true,  bowl: false },
  { id: 'e3', n: 'Naveed Hassan',  r: 'AR · LHB · OS',    bat: true,  bowl: true },
  { id: 'e4', n: 'Owais Memon',    r: 'BAT · RHB',        bat: true,  bowl: false },
  { id: 'e5', n: 'Asad Qureshi',   r: 'BWL · RHB · RFM',  bat: false, bowl: true },
  { id: 'e6', n: 'Rizwan Aslam',   r: 'BAT · LHB',        bat: true,  bowl: false },
  { id: 'e7', n: 'Hassan Mirza',   r: 'AR · RHB · LFM',   bat: true,  bowl: true },
  { id: 'e8', n: 'Yasir Shabbir',  r: 'BWL · RHB · SLA',  bat: false, bowl: true },
  { id: 'e9', n: 'Salman Akhtar',  r: 'BAT · RHB',        bat: true,  bowl: false },
  { id: 'e10', n: 'Bilal Pirzada', r: 'AR · RHB · RM',    bat: true,  bowl: true },
  { id: 'e11', n: 'Faisal Khan',   r: 'BWL · LFM',        bat: false, bowl: true },
];

// ═══════════════════════════════════════════════════════════════════════════
// Shared chrome
// ═══════════════════════════════════════════════════════════════════════════

const STAGES = ['toss', 'lineup', 'ready'];
function MsHeader({ stage, title, sub }) {
  const idx = STAGES.indexOf(stage);
  return (
    <div style={{ padding: '14px 18px 16px', borderBottom: '1px solid ' + hair, background: paper }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
        <div style={{ ...mono, fontSize: 10, color: muted, flex: 1 }}>
          Match start · {idx + 1}/3
        </div>
        <span style={{ ...mono, fontSize: 9, padding: '3px 7px', borderRadius: 4, background: redSoft, color: red }}>
          T-3 MIN
        </span>
      </div>
      <div style={{ display: 'flex', gap: 4, marginBottom: 12 }}>
        {STAGES.map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: i < idx ? green : (i === idx ? ink : 'rgba(20,18,14,0.10)'),
          }}/>
        ))}
      </div>
      <div style={display(24)}>{title}</div>
      {sub && <div style={{ fontSize: 13, color: ink2, marginTop: 4, lineHeight: 1.4 }}>{sub}</div>}
    </div>
  );
}

function PhonePill({ viewer }) {
  const me = MATCH[viewer];
  return (
    <div style={{
      padding: '6px 14px', background: paper2, borderBottom: '1px solid ' + hair,
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      <Crest size={20} bg={me.color} label={me.mono} />
      <span style={{ ...mono, fontSize: 9, color: muted }}>
        {me.captainFull.toUpperCase()} · {me.team.toUpperCase()} CAPTAIN · THIS PHONE
      </span>
    </div>
  );
}

function Crest({ size = 32, bg, label, fg = paper }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.25, flexShrink: 0,
      background: bg, color: fg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: size * 0.4, letterSpacing: '-0.02em',
    }}>{label}</div>
  );
}

function CtaBar({ children }) {
  return (
    <div style={{
      borderTop: '1px solid ' + hair, padding: '12px 18px',
      background: paper, display: 'flex', gap: 10, alignItems: 'center',
      paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
    }}>{children}</div>
  );
}

function Primary({ children, disabled, onClick, accent = ink }) {
  return (
    <button onClick={!disabled ? onClick : undefined} disabled={disabled} style={{
      flex: 1, padding: '13px 16px', borderRadius: 10, border: 'none',
      background: disabled ? paper2 : accent, color: disabled ? muted : paper,
      fontWeight: 700, fontSize: 14, cursor: disabled ? 'default' : 'pointer',
      fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    }}>{children}</button>
  );
}

// Waiting card — what the non-active phone shows
function WaitingCard({ kicker, title, sub, watcher }) {
  return (
    <div style={{
      margin: '24px 18px', padding: '24px 20px', borderRadius: 16,
      background: paper, border: '1.5px dashed ' + hair, textAlign: 'center',
    }}>
      <div style={{
        margin: '0 auto 14px', width: 48, height: 48, borderRadius: 12, background: paper2,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <span style={{
          width: 10, height: 10, borderRadius: 999, background: amber,
          animation: 'ms-pulse 1.4s infinite',
        }} />
      </div>
      <div style={{ ...mono, fontSize: 9, color: amber, marginBottom: 6 }}>{kicker}</div>
      <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, color: ink, letterSpacing: '-0.02em' }}>{title}</div>
      <div style={{ fontSize: 12.5, color: muted, marginTop: 8, lineHeight: 1.5, maxWidth: 280, margin: '8px auto 0' }}>{sub}</div>
      {watcher}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 1 · TOSS
// ═══════════════════════════════════════════════════════════════════════════

function TossStage({ viewer, toss, setToss, onNext }) {
  // Sender hosts the coin. Receiver sees waiting state UNLESS they've won the toss,
  // in which case the sender's phone is asking THEM to pick bat/bowl — but only
  // sender's phone has the controls. Receiver sees "walk to Bilal's phone" until result is synced.

  if (viewer === 'receiver') {
    // Eagles captain's view — always passive until toss result lands
    if (!toss.winner) {
      return (
        <>
          <MsHeader stage="toss" title="The toss." sub="Bilal is hosting the coin. Walk over and watch — call it when prompted." />
          <PhonePill viewer="receiver" />
          <div style={{ flex: 1, overflowY: 'auto' }}>
            <WaitingCard
              kicker="WAITING ON BILAL'S PHONE"
              title="The coin is on Bilal's phone."
              sub="Both captains watch the toss together on one device. You'll see the result here the moment it lands."
              watcher={
                <div style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 10, padding: 12, background: paper2, borderRadius: 10, textAlign: 'left' }}>
                  <Crest size={28} bg={MATCH.sender.color} label={MATCH.sender.mono} />
                  <div>
                    <div style={{ ...mono, fontSize: 9, color: muted }}>HOST PHONE</div>
                    <div style={{ fontSize: 12, color: ink, fontWeight: 600, marginTop: 1 }}>{MATCH.sender.captainFull}</div>
                  </div>
                </div>
              }
            />
          </div>
          <CtaBar><Primary disabled accent={paper2}>Waiting for toss result…</Primary></CtaBar>
        </>
      );
    }
    // Toss result is in — show summary, advance
    return (
      <>
        <MsHeader stage="toss" title="Toss done." sub={`${MATCH[toss.winner].full} won and chose to ${toss.decision}.`} />
        <PhonePill viewer="receiver" />
        <TossResultPanel toss={toss} viewer="receiver" />
        <CtaBar><Primary accent={ink} onClick={onNext}>Continue → your XI tasks</Primary></CtaBar>
      </>
    );
  }

  // ── SENDER VIEW ──
  return (
    <>
      <MsHeader stage="toss" title="The toss." sub="Both captains stand together. Tap the coin to flip. Whoever wins taps Bat or Bowl on this phone." />
      <PhonePill viewer="sender" />
      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        {!toss.winner ? (
          <CoinAnimation toss={toss} setToss={setToss} />
        ) : !toss.decision ? (
          <ChoosePanel toss={toss} setToss={setToss} />
        ) : (
          <TossResultPanel toss={toss} viewer="sender" />
        )}
      </div>
      <CtaBar>
        <Primary disabled={!toss.decision} accent={ink} onClick={onNext}>
          {toss.decision ? 'Continue → lineup' : 'Finish toss to continue'}
          {toss.decision && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </Primary>
      </CtaBar>
    </>
  );
}

function CoinAnimation({ toss, setToss }) {
  const [face, setFace] = React.useState('?');
  const [flipping, setFlipping] = React.useState(false);

  const flip = () => {
    if (flipping) return;
    setFlipping(true);
    let i = 0;
    const tick = setInterval(() => { setFace(i % 2 === 0 ? 'H' : 'T'); i++; }, 90);
    setTimeout(() => {
      clearInterval(tick);
      const w = Math.random() > 0.5 ? 'sender' : 'receiver';
      const f = Math.random() > 0.5 ? 'H' : 'T';
      setFace(f);
      setFlipping(false);
      setToss({ ...toss, winner: w, face: f });
    }, 1300);
  };

  React.useEffect(() => { flip(); /* eslint-disable-next-line */ }, []);

  return (
    <>
      <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 14, marginBottom: 24 }}>
        IMRAN — CALL IT IN THE AIR
      </div>
      <div onClick={() => !flipping && flip()} style={{
        width: 180, height: 180, borderRadius: 999, background: ink, color: paper,
        position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 18px 40px rgba(40,30,15,0.22), inset 0 -4px 0 oklch(0.10 0.02 80)',
        cursor: flipping ? 'default' : 'pointer',
        transform: flipping ? 'rotateY(720deg)' : 'rotateY(0)',
        transition: 'transform 1.3s cubic-bezier(.2,.8,.2,1)',
      }}>
        <div style={{ position: 'absolute', inset: 12, borderRadius: 999, border: '1.5px dashed oklch(0.30 0.02 80)' }} />
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 46, fontWeight: 700 }}>{face}</div>
          <div style={{ fontSize: 11, color: 'oklch(0.72 0.01 80)', marginTop: 6 }}>{flipping ? 'flipping…' : 'tap to flip'}</div>
        </div>
      </div>
      <div style={{ fontSize: 12, color: muted, marginTop: 24, textAlign: 'center', lineHeight: 1.5 }}>
        Imran calls heads or tails out loud before the coin lands.
      </div>
    </>
  );
}

function ChoosePanel({ toss, setToss }) {
  const winner = MATCH[toss.winner];
  const myTurn = true; // we're on the sender's phone — but ANY captain can tap here

  return (
    <>
      <div style={{ ...mono, fontSize: 9, color: amber, marginTop: 14, marginBottom: 6 }}>
        {winner.captainFull.toUpperCase()} — TAP YOUR CHOICE
      </div>
      <div style={display(26)}>{winner.team} won.</div>
      <div style={{ fontSize: 13, color: ink2, marginTop: 8, textAlign: 'center', lineHeight: 1.5, maxWidth: 280 }}>
        {toss.winner === 'sender' ? "It's your call." : "Imran, reach over and tap below."}
      </div>

      <div style={{ marginTop: 28, width: '100%', display: 'flex', gap: 8 }}>
        <button onClick={() => setToss({ ...toss, decision: 'bat' })} style={{
          flex: 1, padding: '20px 0', borderRadius: 14,
          border: '2px solid ' + ink, background: paper, color: ink,
          fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, cursor: 'pointer',
        }}>{winner.team} bat first</button>
        <button onClick={() => setToss({ ...toss, decision: 'bowl' })} style={{
          flex: 1, padding: '20px 0', borderRadius: 14,
          border: '2px solid ' + ink, background: paper, color: ink,
          fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, cursor: 'pointer',
        }}>{winner.team} bowl first</button>
      </div>
    </>
  );
}

function TossResultPanel({ toss, viewer }) {
  const winner = MATCH[toss.winner];
  const battingSide = toss.decision === 'bat' ? toss.winner : (toss.winner === 'sender' ? 'receiver' : 'sender');
  const batting = MATCH[battingSide];
  const bowlingSide = battingSide === 'sender' ? 'receiver' : 'sender';
  const bowling = MATCH[bowlingSide];

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>
      <div style={{
        padding: 18, background: greenSoft, color: 'oklch(0.30 0.10 148)', borderRadius: 14, marginBottom: 14,
        display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 52, height: 52, borderRadius: 13, background: green, color: paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, color: ink }}>{winner.team} won the toss</div>
          <div style={{ fontSize: 12, color: ink2, marginTop: 2 }}>{winner.captain} chose to {toss.decision}</div>
        </div>
      </div>

      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>FIRST INNINGS LINE-UP</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
        <SideCard team={batting} label="BATTING" accent={red} />
        <SideCard team={bowling} label="BOWLING" />
      </div>

      <div style={{ padding: 14, background: paper2, borderRadius: 12 }}>
        <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 6 }}>NEXT</div>
        <div style={{ fontSize: 13, color: ink, fontWeight: 600 }}>
          {viewer === 'sender' && bowlingSide === 'sender' && <>You'll pick Lions' opening bowler. Imran picks Eagles' openers in parallel.</>}
          {viewer === 'sender' && battingSide === 'sender' && <>You'll pick Lions' openers. Imran picks Eagles' opening bowler in parallel.</>}
          {viewer === 'receiver' && bowlingSide === 'receiver' && <>You'll pick Eagles' opening bowler. Bilal picks Lions' openers in parallel.</>}
          {viewer === 'receiver' && battingSide === 'receiver' && <>You'll pick Eagles' openers. Bilal picks Lions' opening bowler in parallel.</>}
        </div>
      </div>
    </div>
  );
}

function SideCard({ team, label, accent = ink }) {
  return (
    <div style={{
      padding: 12, background: paper, border: '1.5px solid ' + (accent === red ? red : hair),
      borderRadius: 12,
    }}>
      <div style={{ ...mono, fontSize: 9, color: accent === red ? red : muted, marginBottom: 6 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Crest size={28} bg={team.color} label={team.mono} />
        <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>{team.team}</div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 2 · LINEUP — parallel, on each captain's own phone
// ═══════════════════════════════════════════════════════════════════════════

function LineupStage({ viewer, toss, lineup, setLineup, onNext }) {
  // Who's batting? Who's bowling?
  const battingSide = toss.decision === 'bat' ? toss.winner : (toss.winner === 'sender' ? 'receiver' : 'sender');
  const myRole = viewer === battingSide ? 'batting' : 'bowling';

  // My XI to pick from
  const myXI = viewer === 'sender' ? LIONS_XI : EAGLES_XI;
  const otherCaptain = viewer === 'sender' ? MATCH.receiver : MATCH.sender;

  // Have I submitted my picks?
  const mySide = viewer === 'sender' ? 'sender' : 'receiver';
  const otherSide = mySide === 'sender' ? 'receiver' : 'sender';
  const mySubmitted = lineup[mySide].submitted;
  const otherSubmitted = lineup[otherSide].submitted;
  const bothDone = mySubmitted && otherSubmitted;

  // While my submitted but their not → waiting state
  // While both submitted → onNext available
  // Otherwise → picker

  if (myRole === 'batting') {
    // Only batting captain submits anything; bowling has no pre-pick
    return <BattingPicker viewer={viewer} myXI={myXI} lineup={lineup} setLineup={setLineup} otherSubmitted={true} otherCaptain={otherCaptain} onNext={onNext} bothDone={mySubmitted} mySubmitted={mySubmitted} />;
  }
  // Bowling captain — single waiting screen, no pick required
  const otherSide2 = viewer === 'sender' ? 'receiver' : 'sender';
  const battingSubmitted = lineup[otherSide2].submitted;
  return (
    <>
      <MsHeader stage="lineup" title="Waiting on the batting team." sub={`${otherCaptain.captain} is picking ${otherCaptain.team}' openers. You don't pre-pick a bowler — just hand the ball over at ball 1.`} />
      <PhonePill viewer={viewer} />
      <div style={{ flex: 1, overflowY: 'auto' }}>
        <WaitingCard
          kicker={`WAITING ON ${otherCaptain.captain.toUpperCase()}`}
          title={`${otherCaptain.captain} is picking ${otherCaptain.team}' openers.`}
          sub="When ball 1 is bowled, the scoring screen prompts for whoever has the ball. No commitment needed here."
        />
        <div style={{ padding: '0 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 10, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
            <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 6 }}>WHILE YOU WAIT</div>
            Tell your bowlers who's up first. The captain hand-off (ball, mark, run-up) happens at the pitch, not in the app.
          </div>
        </div>
      </div>
      <CtaBar>
        <Primary disabled={!battingSubmitted} accent={ink} onClick={onNext}>
          {battingSubmitted ? 'Continue → Ready' : `Waiting on ${otherCaptain.captain}…`}
          {battingSubmitted && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </Primary>
      </CtaBar>
    </>
  );
}

function BattingPicker({ viewer, myXI, lineup, setLineup, otherSubmitted, otherCaptain, onNext, bothDone, mySubmitted }) {
  const mySide = viewer === 'sender' ? 'sender' : 'receiver';
  const myPicks = lineup[mySide];

  const pickStriker = (id) => {
    if (id === myPicks.nonStriker) {
      setLineup({ ...lineup, [mySide]: { ...myPicks, striker: myPicks.nonStriker, nonStriker: myPicks.striker } });
    } else {
      setLineup({ ...lineup, [mySide]: { ...myPicks, striker: id } });
    }
  };
  const pickNonStriker = (id) => {
    if (id === myPicks.striker) {
      setLineup({ ...lineup, [mySide]: { ...myPicks, nonStriker: myPicks.striker, striker: myPicks.nonStriker } });
    } else {
      setLineup({ ...lineup, [mySide]: { ...myPicks, nonStriker: id } });
    }
  };
  const submit = () => setLineup({ ...lineup, [mySide]: { ...myPicks, submitted: true } });

  const batters = myXI.filter(p => p.bat);
  const sName = (id) => myXI.find(p => p.id === id)?.n;

  if (mySubmitted && !otherSubmitted) {
    return (
      <>
        <MsHeader stage="lineup" title="Openers locked." sub="Waiting on the other captain's opening bowler." />
        <PhonePill viewer={viewer} />
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <WaitingCard
            kicker={`WAITING ON ${otherCaptain.captain.toUpperCase()}`}
            title={`${otherCaptain.captain} is picking ${otherCaptain.team}' opening bowler.`}
            sub="As soon as they tap submit, both phones move to Ready."
          />
          <SubmittedSummary type="batting" striker={sName(myPicks.striker)} nonStriker={sName(myPicks.nonStriker)} onEdit={() => setLineup({ ...lineup, [mySide]: { ...myPicks, submitted: false } })} />
        </div>
        <CtaBar><Primary disabled accent={paper2}>Waiting on {otherCaptain.captain}…</Primary></CtaBar>
      </>
    );
  }

  if (bothDone) {
    return (
      <>
        <MsHeader stage="lineup" title="Both lineups in." sub="Ready to start the match." />
        <PhonePill viewer={viewer} />
        <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>
          <SubmittedSummary type="batting" striker={sName(myPicks.striker)} nonStriker={sName(myPicks.nonStriker)} />
        </div>
        <CtaBar><Primary accent={ink} onClick={onNext}>Continue → Ready
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>
        </Primary></CtaBar>
      </>
    );
  }

  // Active picker
  const ready = myPicks.striker && myPicks.nonStriker;
  return (
    <>
      <MsHeader stage="lineup" title="Pick your openers." sub="Striker faces the first ball. Non-striker stands at the other end." />
      <PhonePill viewer={viewer} />
      <div style={{ padding: '12px 18px', background: paper, borderBottom: '1px solid ' + hair, display: 'flex', gap: 8 }}>
        <SlotCard label="ON STRIKE" name={sName(myPicks.striker)} hot />
        <SlotCard label="NON-STRIKER" name={sName(myPicks.nonStriker)} />
      </div>
      <div style={{ flex: 1, overflowY: 'auto' }}>
        <div style={{ padding: '12px 18px 4px', ...mono, fontSize: 10, color: muted }}>YOUR XI · BATTING</div>
        {batters.map(p => {
          const isS = p.id === myPicks.striker;
          const isNS = p.id === myPicks.nonStriker;
          const next = !myPicks.striker ? 'striker' : !myPicks.nonStriker ? 'nonStriker' : 'striker';
          return (
            <button key={p.id} onClick={() => next === 'striker' ? pickStriker(p.id) : pickNonStriker(p.id)} style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 18px', borderTop: '1px solid ' + hair,
              background: (isS || isNS) ? paper2 : paper, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{
                width: 28, height: 28, borderRadius: 7, flexShrink: 0,
                background: isS ? red : (isNS ? ink : paper2), color: isS || isNS ? paper : muted,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                ...mono, fontSize: 9,
              }}>{isS ? 'STR' : isNS ? 'NS' : ''}</div>
              <div style={{
                width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                background: paper, color: ink2, border: '1px solid ' + hair,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
              }}>{p.n.split(' ').map(w => w[0]).join('').slice(0, 2)}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{p.n}</div>
                <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{p.r}</div>
              </div>
            </button>
          );
        })}
        <div style={{ padding: '14px 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 10, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
            <b style={{ color: ink }}>{otherCaptain.captain}</b> is picking their opening bowler on their phone right now. We'll lock both at the same time.
          </div>
        </div>
      </div>
      <CtaBar>
        <Primary disabled={!ready} accent={ink} onClick={submit}>
          {ready ? 'Submit my openers' : 'Pick two batters'}
          {ready && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </Primary>
      </CtaBar>
    </>
  );
}

function BowlingPicker({ viewer, myXI, lineup, setLineup, otherSubmitted, otherCaptain, onNext, bothDone, mySubmitted }) {
  const mySide = viewer === 'sender' ? 'sender' : 'receiver';
  const myPicks = lineup[mySide];
  const bowlers = myXI.filter(p => p.bowl);
  const sName = (id) => myXI.find(p => p.id === id)?.n;

  const submit = () => setLineup({ ...lineup, [mySide]: { ...myPicks, submitted: true } });

  if (mySubmitted && !otherSubmitted) {
    return (
      <>
        <MsHeader stage="lineup" title="Bowler locked." sub={`Waiting on ${otherCaptain.team}' openers.`} />
        <PhonePill viewer={viewer} />
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <WaitingCard
            kicker={`WAITING ON ${otherCaptain.captain.toUpperCase()}`}
            title={`${otherCaptain.captain} is picking ${otherCaptain.team}' openers.`}
            sub="Both phones move to Ready as soon as they submit."
          />
          <SubmittedSummary type="bowling" bowler={sName(myPicks.bowler)} onEdit={() => setLineup({ ...lineup, [mySide]: { ...myPicks, submitted: false } })} />
        </div>
        <CtaBar><Primary disabled accent={paper2}>Waiting on {otherCaptain.captain}…</Primary></CtaBar>
      </>
    );
  }

  if (bothDone) {
    return (
      <>
        <MsHeader stage="lineup" title="Both lineups in." sub="Ready to start the match." />
        <PhonePill viewer={viewer} />
        <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>
          <SubmittedSummary type="bowling" bowler={sName(myPicks.bowler)} />
        </div>
        <CtaBar><Primary accent={ink} onClick={onNext}>Continue → Ready
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>
        </Primary></CtaBar>
      </>
    );
  }

  const ready = !!myPicks.bowler;
  return (
    <>
      <MsHeader stage="lineup" title="Pick your opening bowler." sub="They bowl the first over. Max 4 overs each in a T20." />
      <PhonePill viewer={viewer} />
      <div style={{ padding: '12px 18px', background: paper, borderBottom: '1px solid ' + hair }}>
        <SlotCard label="OPENING THE BOWLING" name={sName(myPicks.bowler)} hot />
      </div>
      <div style={{ flex: 1, overflowY: 'auto' }}>
        <div style={{ padding: '12px 18px 4px', ...mono, fontSize: 10, color: muted }}>YOUR XI · BOWLERS</div>
        {bowlers.map(p => {
          const on = myPicks.bowler === p.id;
          return (
            <button key={p.id} onClick={() => setLineup({ ...lineup, [mySide]: { ...myPicks, bowler: p.id } })} style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 18px', borderTop: '1px solid ' + hair,
              background: on ? paper2 : paper, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{
                width: 22, height: 22, borderRadius: 999, flexShrink: 0,
                border: '2px solid ' + (on ? red : hair),
                background: on ? red : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {on && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3"><path d="M20 6L9 17l-5-5"/></svg>}
              </div>
              <div style={{
                width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                background: paper, color: ink2, border: '1px solid ' + hair,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 12,
              }}>{p.n.split(' ').map(w => w[0]).join('').slice(0, 2)}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 600 }}>{p.n}</div>
                <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 2 }}>{p.r}</div>
              </div>
            </button>
          );
        })}
        <div style={{ padding: '14px 18px 24px' }}>
          <div style={{ padding: 12, borderRadius: 10, background: paper2, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
            <b style={{ color: ink }}>{otherCaptain.captain}</b> is picking their openers on their phone right now. We'll lock both at the same time.
          </div>
        </div>
      </div>
      <CtaBar>
        <Primary disabled={!ready} accent={ink} onClick={submit}>
          {ready ? 'Submit my bowler' : 'Pick a bowler'}
          {ready && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </Primary>
      </CtaBar>
    </>
  );
}

function SlotCard({ label, name, hot }) {
  return (
    <div style={{
      flex: 1, padding: 10, borderRadius: 10,
      background: name ? (hot ? redSoft : paper2) : paper,
      border: '1.5px solid ' + (name ? (hot ? red : ink) : hair),
    }}>
      <div style={{ ...mono, fontSize: 9, color: hot && name ? red : muted, marginBottom: 4 }}>{label}</div>
      <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, color: name ? ink : muted, minHeight: 16 }}>
        {name || '— tap below —'}
      </div>
    </div>
  );
}

function SubmittedSummary({ type, striker, nonStriker, bowler, onEdit }) {
  return (
    <div style={{ padding: '14px 18px 24px' }}>
      <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>YOUR LOCKED PICKS</div>
      <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12, overflow: 'hidden' }}>
        {type === 'batting' && (
          <>
            <SummaryRow k="On strike" v={striker} accent={red} />
            <SummaryRow k="Non-striker" v={nonStriker} last />
          </>
        )}
        {type === 'bowling' && (
          <SummaryRow k="Opening bowler" v={bowler} last />
        )}
      </div>
      {onEdit && (
        <button onClick={onEdit} style={{
          marginTop: 10, ...mono, fontSize: 9, padding: '7px 12px', borderRadius: 999,
          border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
        }}>EDIT PICKS</button>
      )}
    </div>
  );
}

function SummaryRow({ k, v, accent, last }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '11px 14px', borderBottom: last ? 'none' : '1px solid ' + hair,
    }}>
      <span style={{ fontSize: 12, color: muted }}>{k}</span>
      <span style={{ fontSize: 13, fontWeight: 600, color: accent || ink }}>{v}</span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE 3 · READY — batting captain taps Start; other phone waits
// ═══════════════════════════════════════════════════════════════════════════

function ReadyStage({ viewer, toss, lineup, onBack }) {
  const battingSide = toss.decision === 'bat' ? toss.winner : (toss.winner === 'sender' ? 'receiver' : 'sender');
  const battingTeam = MATCH[battingSide];
  const bowlingTeam = MATCH[battingSide === 'sender' ? 'receiver' : 'sender'];
  const battingXI = battingSide === 'sender' ? LIONS_XI : EAGLES_XI;
  const bowlingXI = battingSide === 'sender' ? EAGLES_XI : LIONS_XI;
  const battingPicks = lineup[battingSide];
  const striker = battingXI.find(p => p.id === battingPicks.striker)?.n;
  const nonStriker = battingXI.find(p => p.id === battingPicks.nonStriker)?.n;

  const HeroCard = () => (
    <div style={{ padding: 16, background: ink, color: paper, borderRadius: 14, marginBottom: 16 }}>
      <div style={{ ...mono, fontSize: 9, opacity: 0.7, marginBottom: 10 }}>FIRST BALL · OVER 0.1</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        <Crest size={42} bg={battingTeam.color} label={battingTeam.mono} />
        <div style={{ flex: 1, textAlign: 'left' }}>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15 }}>{battingTeam.team}</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 2 }}>0/0</div>
          <div style={{ ...mono, fontSize: 9, opacity: 0.7, marginTop: 4 }}>BATTING</div>
        </div>
        <div style={{ ...mono, fontSize: 10, opacity: 0.7 }}>VS</div>
        <div style={{ flex: 1, textAlign: 'right' }}>
          <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15 }}>{bowlingTeam.team}</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 26, fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 2 }}>—</div>
          <div style={{ ...mono, fontSize: 9, opacity: 0.7, marginTop: 4 }}>BOWLING</div>
        </div>
        <Crest size={42} bg={bowlingTeam.color} label={bowlingTeam.mono} />
      </div>
    </div>
  );

  const Summary = () => (
    <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 12, overflow: 'hidden', marginBottom: 16 }}>
      <SummaryRow k="Toss" v={`${MATCH[toss.winner].team} · chose to ${toss.decision}`} />
      <SummaryRow k="On strike" v={striker} accent={red} />
      <SummaryRow k="Non-striker" v={nonStriker} />
      <SummaryRow k="Opening bowler" v={<span style={{ color: muted, fontStyle: 'italic', fontWeight: 500 }}>Picked at ball 1</span>} />
      <SummaryRow k="Format" v={MATCH.format} last />
    </div>
  );

  // Spectator role tells the user what they'll see next
  const myBatting = (viewer === battingSide);

  if (myBatting) {
    // Batting captain taps Start — they're about to be the scorer
    return (
      <>
        <MsHeader stage="ready" title="Ready to start." sub="You're about to score this innings. Tap below when the umpire calls play." />
        <PhonePill viewer={viewer} />
        <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>
          <HeroCard />
          <Summary />
          <YourRoleAfterStart myBatting={myBatting} />
        </div>
        <CtaBar>
          <Primary accent={red} onClick={() => alert('Match started')}>
            Start match — first ball
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
          </Primary>
        </CtaBar>
      </>
    );
  }

  // Non-batting captain — waits for batting captain to start
  const battingCaptain = MATCH[battingSide].captain;
  return (
    <>
      <MsHeader stage="ready" title="Ready." sub={`${battingCaptain} is about to start the match. Your phone flips to the live scoreboard when they tap.`} />
      <PhonePill viewer={viewer} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>
        <HeroCard />
        <Summary />
        <WaitingCard
          kicker={`WAITING ON ${battingCaptain.toUpperCase()}`}
          title={`${battingCaptain} is starting the match.`}
          sub="They're scoring this innings. Your phone shows the live scoreboard the moment they tap."
        />
      </div>
      <CtaBar>
        <Primary disabled accent={paper2}>Waiting for {battingCaptain} to tap Start…</Primary>
      </CtaBar>
    </>
  );
}

// Tag — role-after-tap card for the sender view
function YourRoleAfterStart({ myBatting }) {
  return (
    <div style={{
      padding: 14, background: paper2, borderRadius: 12,
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 9, background: myBatting ? red : ink, color: paper, flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {myBatting
          ? <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/></svg>
          : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="3"/><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/></svg>}
      </div>
      <div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 13.5, fontWeight: 700 }}>
          {myBatting ? "You're scoring this innings" : "You're spectating this innings"}
        </div>
        <div style={{ fontSize: 11.5, color: muted, marginTop: 2, lineHeight: 1.4 }}>
          {myBatting
            ? 'Your team is batting — you enter every ball. When your innings ends, scoring auto-transfers.'
            : 'Your team is bowling — see the live scoreboard. You score when your team bats.'}
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT
// ═══════════════════════════════════════════════════════════════════════════

function CkMatchStart({ viewer = 'sender', stage: initialStage = 'toss' } = {}) {
  const [stage, setStage] = React.useState(initialStage);
  // Toss state — pre-filled when jumping to later stages
  const presetWinner = initialStage === 'toss' ? null : 'receiver'; // Eagles won the toss in the demo
  const presetDecision = initialStage === 'toss' ? null : 'bat';
  const [toss, setToss] = React.useState({ winner: presetWinner, decision: presetDecision, face: presetWinner ? 'H' : '?' });

  // Lineup state — pre-filled when jumping to ready
  const [lineup, setLineup] = React.useState({
    sender:   { striker: null, nonStriker: null, bowler: 's10', submitted: initialStage === 'ready' },
    receiver: { striker: 'e1', nonStriker: 'e4', bowler: null, submitted: initialStage === 'ready' },
  });

  const next = () => setStage(s => STAGES[STAGES.indexOf(s) + 1] || s);
  const back = () => setStage(s => STAGES[STAGES.indexOf(s) - 1] || s);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      {stage === 'toss'   && <TossStage   viewer={viewer} toss={toss} setToss={setToss} onNext={next} />}
      {stage === 'lineup' && <LineupStage viewer={viewer} toss={toss} lineup={lineup} setLineup={setLineup} onNext={next} />}
      {stage === 'ready'  && <ReadyStage  viewer={viewer} toss={toss} lineup={lineup} onBack={back} />}
    </div>
  );
}

// Replace NextRoleCard mounting via simple wrapper that returns YourRoleAfterStart
// (defensive fix for the placeholder above)
window.YourRoleAfterStart = YourRoleAfterStart;

// pulse for waiting cards
const styleEl = document.createElement('style');
styleEl.textContent = `@keyframes ms-pulse { 0%, 100% { opacity: 1 } 50% { opacity: 0.35 } }`;
document.head.appendChild(styleEl);

window.CkMatchStart = CkMatchStart;

})();

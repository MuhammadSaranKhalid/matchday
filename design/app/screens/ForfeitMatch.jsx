// ForfeitMatch.jsx — Withdrawing from a CONFIRMED match (post-acceptance).
// Entry points: confirmed-match manage screen · roster-alert notification deep-link.
//
// This is the ONLY place a captain can declare a walkover. The pre-send and pre-accept
// gates don't carry forfeit because no commitment has been made yet at those points.
//
// 4 views: reason → confirm → success
//   <CkForfeitMatch initialView="reason" />

(function () {

const ink = 'var(--ink)';
const ink2 = 'var(--ink-2)';
const muted = 'var(--muted)';
const paper = 'var(--paper)';
const paper2 = 'var(--paper-2)';
const hair = 'var(--hairline)';
const red = 'var(--red)';
const redSoft = 'var(--red-soft)';
const cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase' };
const display = (s) => ({ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: s, lineHeight: 1.05, color: ink });

const FIXTURE = {
  status: 'Confirmed',
  hours: 28,
  ours:  { name: 'Lahore Lions',   mono: 'LL', color: red, role: 'You (Captain)' },
  them:  { name: 'Karachi Eagles', mono: 'KE', color: 'oklch(0.55 0.15 250)' },
  when: 'Sat 18 May · 3:00 PM',
  venue: 'Model Town Ground',
  format: 'T20 friendly · 11-a-side · white ball',
  h2h: 'Played 3× · won 2',
};

function Header({ kicker, title, sub, onBack }) {
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
        <div style={{ ...mono, fontSize: 10, color: red, flex: 1 }}>{kicker}</div>
      </div>
      <div style={display(24)}>{title}</div>
      {sub && <div style={{ fontSize: 13, color: ink2, marginTop: 4, lineHeight: 1.4 }}>{sub}</div>}
    </div>
  );
}

function FixtureCard() {
  return (
    <div style={{
      padding: 14, background: paper, border: '1px solid ' + hair, borderRadius: 12, marginBottom: 16,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <span style={{ ...mono, fontSize: 9, padding: '3px 7px', borderRadius: 4, background: redSoft, color: red }}>CONFIRMED · T-{FIXTURE.hours}H</span>
        <span style={{ ...mono, fontSize: 9, color: muted }}>{FIXTURE.h2h}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <Crest bg={FIXTURE.ours.color} label={FIXTURE.ours.mono} />
        <div style={{ ...mono, fontSize: 10, color: muted }}>VS</div>
        <Crest bg={FIXTURE.them.color} label={FIXTURE.them.mono} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, color: ink }}>Lions vs Eagles</div>
          <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>{FIXTURE.when} · {FIXTURE.venue}</div>
        </div>
      </div>
      <div style={{ fontSize: 11, color: muted, marginTop: 10, paddingTop: 10, borderTop: '1px solid ' + hair }}>{FIXTURE.format}</div>
    </div>
  );
}

function Crest({ bg, label }) {
  return (
    <div style={{
      width: 36, height: 36, borderRadius: 9, background: bg, color: paper,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 13, flexShrink: 0,
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

function Ghost({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '12px 16px', borderRadius: 10,
      border: '1px solid ' + hair, background: paper, color: ink,
      fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
    }}>{children}</button>
  );
}

function DangerBtn({ children, disabled, onClick }) {
  return (
    <button onClick={!disabled ? onClick : undefined} disabled={disabled} style={{
      flex: 1, padding: '12px 16px', borderRadius: 10, border: 'none',
      background: disabled ? paper2 : red, color: disabled ? muted : paper,
      fontWeight: 700, fontSize: 14, cursor: disabled ? 'default' : 'pointer',
      fontFamily: 'inherit',
    }}>{children}</button>
  );
}

// ─── REASON picker ──────────────────────────────────
function ReasonView({ onBack, onNext, reason, setReason }) {
  const reasons = [
    { k: 'roster',   t: "Can't field a side",       s: 'Too many drop-outs or injuries' },
    { k: 'venue',    t: 'Lost the venue',           s: 'Ground unavailable last-minute' },
    { k: 'weather',  t: 'Weather called off',       s: 'Match abandoned by both captains' },
    { k: 'family',   t: 'Family / personal',        s: 'Genuine emergency' },
    { k: 'other',    t: 'Other',                    s: "I'll add a note" },
  ];
  return (
    <>
      <Header kicker="Withdraw · confirmed match" title="Why are you forfeiting?" sub="This match is on Eagles' calendar. Pick a reason — they'll see it." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 20px' }}>
        <FixtureCard />

        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>REASON</div>
        <div style={{ display: 'grid', gap: 8 }}>
          {reasons.map(r => {
            const on = reason === r.k;
            return (
              <button key={r.k} onClick={() => setReason(r.k)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: 14,
                background: on ? paper2 : paper,
                border: '2px solid ' + (on ? ink : hair),
                borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
              }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{r.t}</div>
                  <div style={{ fontSize: 11.5, color: muted, marginTop: 2, lineHeight: 1.4 }}>{r.s}</div>
                </div>
                <div style={{
                  width: 20, height: 20, borderRadius: 999, flexShrink: 0,
                  border: '2px solid ' + (on ? ink : hair),
                  background: on ? ink : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {on && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
                </div>
              </button>
            );
          })}
        </div>

        <div style={{ marginTop: 16, padding: 12, background: paper2, borderRadius: 10, fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
          If there's still time, you can <b style={{ color: ink }}>renegotiate</b> instead — propose a smaller format, new date or venue. Eagles' captain will see your request.
        </div>
      </div>
      <CtaBar>
        <Ghost onClick={onBack}>Back</Ghost>
        <DangerBtn disabled={!reason} onClick={onNext}>Continue</DangerBtn>
      </CtaBar>
    </>
  );
}

// ─── CONFIRM ────────────────────────────────────────
function ConfirmView({ onBack, onConfirm, reason }) {
  const [ack1, setAck1] = React.useState(false);
  const [ack2, setAck2] = React.useState(false);
  const ready = ack1 && ack2;

  const REASON_TEXT = {
    roster: "Can't field a side",
    venue: 'Lost the venue',
    weather: 'Weather called off',
    family: 'Family / personal',
    other: 'Other',
  }[reason] || 'Other';

  return (
    <>
      <Header kicker="Confirm forfeit" title="Are you sure?" sub="Once you submit, this is final. Eagles get a walkover win in their record." onBack={onBack}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 24px' }}>
        <FixtureCard />

        <div style={{
          padding: 14, borderRadius: 12, background: redSoft, color: red, marginBottom: 16,
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 11, background: red, color: paper, flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><circle cx="12" cy="12" r="9"/><path d="M9 9l6 6M15 9l-6 6"/></svg>
          </div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>This can't be undone</div>
            <div style={{ fontSize: 11.5, color: 'oklch(0.36 0.10 28)', marginTop: 2, lineHeight: 1.4 }}>Reason logged: <b>{REASON_TEXT}</b></div>
          </div>
        </div>

        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 8 }}>WHAT WILL HAPPEN</div>
        <div style={{ background: paper, border: '1px solid ' + hair, borderRadius: 10, overflow: 'hidden', marginBottom: 16 }}>
          {[
            { k: 'Match result',       v: 'Walkover · Eagles win', danger: true },
            { k: 'Eagles head-to-head', v: '3 wins of 4' },
            { k: 'Your no-show rate',  v: 'Adjusts upward · visible on team page', danger: true },
            { k: 'Player stats',       v: 'No stats accumulate' },
            { k: 'Notifications',      v: 'Eagles + your 11 players notified' },
          ].map((r, i) => (
            <div key={r.k} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
              padding: '11px 14px', borderTop: i ? '1px solid ' + hair : 'none',
            }}>
              <span style={{ fontSize: 12, color: muted }}>{r.k}</span>
              <span style={{ fontSize: 12, fontWeight: 600, color: r.danger ? red : ink, textAlign: 'right', maxWidth: '60%' }}>{r.v}</span>
            </div>
          ))}
        </div>

        <button onClick={() => setAck1(c => !c)} style={{
          width: '100%', display: 'flex', alignItems: 'flex-start', gap: 12, padding: 12, marginBottom: 8,
          background: ack1 ? paper2 : paper, border: '1.5px solid ' + (ack1 ? ink : hair),
          borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
        }}>
          <Checkbox on={ack1} />
          <span style={{ fontSize: 12.5, color: ink, lineHeight: 1.45 }}>
            I understand this records a walkover and updates my team's record.
          </span>
        </button>
        <button onClick={() => setAck2(c => !c)} style={{
          width: '100%', display: 'flex', alignItems: 'flex-start', gap: 12, padding: 12,
          background: ack2 ? paper2 : paper, border: '1.5px solid ' + (ack2 ? ink : hair),
          borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
        }}>
          <Checkbox on={ack2} />
          <span style={{ fontSize: 12.5, color: ink, lineHeight: 1.45 }}>
            I tried to renegotiate first, or there isn't time to.
          </span>
        </button>
      </div>
      <CtaBar>
        <Ghost onClick={onBack}>Back</Ghost>
        <DangerBtn disabled={!ready} onClick={onConfirm}>Forfeit match</DangerBtn>
      </CtaBar>
    </>
  );
}

function Checkbox({ on }) {
  return (
    <div style={{
      width: 22, height: 22, borderRadius: 6, flexShrink: 0,
      background: on ? ink : paper,
      border: on ? 'none' : '1.5px solid var(--soft)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      marginTop: 1,
    }}>
      {on && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3"><path d="M20 6L9 17l-5-5"/></svg>}
    </div>
  );
}

// ─── SUCCESS ────────────────────────────────────────
function SuccessView({ onClose }) {
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '50px 24px 30px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        <div style={{
          width: 88, height: 88, borderRadius: 22, background: muted, color: paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 22,
        }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M6 6l12 12"/><path d="M18 6L6 18"/></svg>
        </div>
        <div style={{ ...display(26), marginBottom: 8 }}>Walkover recorded.</div>
        <div style={{ fontSize: 13, color: ink2, lineHeight: 1.5, maxWidth: 300, marginBottom: 24 }}>
          Lions vs Eagles is removed from your calendar. Eagles' captain has been notified and credited a win.
        </div>

        <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '14px',
            borderRadius: 12, cursor: 'pointer', textAlign: 'left',
            border: 'none', background: ink, color: paper, fontFamily: 'inherit',
          }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 600 }}>Message Eagles' captain</div>
              <div style={{ fontSize: 11, opacity: 0.7, marginTop: 1 }}>Apologise · suggest a rematch</div>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ opacity: 0.7 }}><path d="M9 18l6-6-6-6"/></svg>
          </button>
          <button onClick={onClose} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '14px',
            borderRadius: 12, cursor: 'pointer', textAlign: 'left',
            border: '1px solid ' + hair, background: paper, color: ink, fontFamily: 'inherit',
          }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 600 }}>Back to calendar</div>
              <div style={{ fontSize: 11, color: muted, marginTop: 1 }}>2 other fixtures this month</div>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2" style={{ opacity: 0.5 }}><path d="M9 18l6-6-6-6"/></svg>
          </button>
        </div>
      </div>
    </>
  );
}

// ─── ROOT ───────────────────────────────────────────
function CkForfeitMatch({ initialView = 'reason' } = {}) {
  const [view, setView] = React.useState(initialView);
  const [reason, setReason] = React.useState('roster');

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      {view === 'reason'  && <ReasonView  onBack={() => {}} onNext={() => setView('confirm')} reason={reason} setReason={setReason} />}
      {view === 'confirm' && <ConfirmView onBack={() => setView('reason')} onConfirm={() => setView('success')} reason={reason} />}
      {view === 'success' && <SuccessView onClose={() => setView('reason')} />}
    </div>
  );
}

window.CkForfeitMatch = CkForfeitMatch;

})();

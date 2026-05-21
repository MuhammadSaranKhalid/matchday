// RosterGate.jsx — handles squad vs playing-XI mismatches in the friendly flow.
//
// Three connected screens, one file:
//   <CkRosterThin />            Under-strength resolver — squad < playing-XI
//                                Four CTAs: borrow · unclaimed · drop format · forfeit
//   <CkXISelect />              XI picker — squad > playing-XI (or any match-day)
//                                Pick N, assign WK + VC, set batting order, reserves below
//   <CkXISelect provisional />  Same picker, framed as "pencil in" while opponent decides
//
// All three are full-bleed screens rendered inside the iOS frame.

(function () {

const ink = 'var(--ink)';
const ink2 = 'var(--ink-2)';
const muted = 'var(--muted)';
const paper = 'var(--paper)';
const paper2 = 'var(--paper-2)';
const hair = 'var(--hairline)';
const red = 'var(--red)';
const green = 'var(--green)';
const greenSoft = 'var(--green-soft)';
const amber = 'var(--amber)';
const cream = 'var(--cream)';

const mono = { fontFamily: 'JetBrains Mono', fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase' };
const display = (s) => ({ fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.025em', fontSize: s, lineHeight: 1.05, color: ink });

// Squad for "Lahore Lions" — 14 players, used by both screens
const SQUAD = [
  { id: 's1',  name: 'Bilal Ahmed',   role: 'Captain',       bat: 'RHB',  bowl: 'RM',  form: 'Hot',  stats: '42 · SR 138' },
  { id: 's2',  name: 'Adeel Sheikh',  role: 'Wicket-Keeper', bat: 'LHB',  bowl: '—',   form: 'OK',   stats: '31 · 4ct' },
  { id: 's3',  name: 'Faraz Khan',    role: 'All-rounder',   bat: 'RHB',  bowl: 'OS',  form: 'Hot',  stats: '38 · 2/22' },
  { id: 's4',  name: 'Hamza Tariq',   role: 'Batter',        bat: 'RHB',  bowl: '—',   form: 'OK',   stats: '54* · SR 121' },
  { id: 's5',  name: 'Usman Riaz',    role: 'All-rounder',   bat: 'RHB',  bowl: 'RFM', form: 'Hot',  stats: '24 · 3/19' },
  { id: 's6',  name: 'Imran Akhtar',  role: 'Bowler',        bat: 'RHB',  bowl: 'RFM', form: 'OK',   stats: '4/28' },
  { id: 's7',  name: 'Shahid Iqbal',  role: 'Batter',        bat: 'LHB',  bowl: '—',   form: 'Cold', stats: '12 · SR 92' },
  { id: 's8',  name: 'Junaid Ali',    role: 'Wicket-Keeper', bat: 'RHB',  bowl: '—',   form: 'OK',   stats: '18 · 2st' },
  { id: 's9',  name: 'Tariq Mehmood', role: 'All-rounder',   bat: 'LHB',  bowl: 'SLA', form: 'OK',   stats: '29 · 1/24' },
  { id: 's10', name: 'Saad Anwar',    role: 'Bowler',        bat: 'RHB',  bowl: 'LFM', form: 'Hot',  stats: '3/17' },
  { id: 's11', name: 'Bilal Khan',    role: 'Batter',        bat: 'RHB',  bowl: '—',   form: 'OK',   stats: '47 · SR 118' },
  { id: 's12', name: 'Adnan Latif',   role: 'Bowler',        bat: 'RHB',  bowl: 'OS',  form: 'OK',   stats: '2/31' },
  { id: 's13', name: 'Kashif Raza',   role: 'All-rounder',   bat: 'RHB',  bowl: 'RM',  form: 'Cold', stats: '8 · 0/22' },
  { id: 's14', name: 'Zain Mansoor',  role: 'Batter',        bat: 'LHB',  bowl: '—',   form: 'Hot',  stats: '63 · SR 144' },
];

const FORM_CHIP = {
  Hot:  { bg: greenSoft, fg: 'oklch(0.36 0.10 148)' },
  OK:   { bg: paper2,    fg: ink2 },
  Cold: { bg: cream,     fg: muted },
};

// ═══════════════════════════════════════════════════════════════════════════
// Shared chrome
// ═══════════════════════════════════════════════════════════════════════════

function GateHeader({ kicker, title, sub, onBack }) {
  return (
    <div style={{ padding: '14px 18px 14px', borderBottom: '1px solid ' + hair, background: paper }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <button onClick={onBack} style={{
          width: 32, height: 32, borderRadius: 8, border: '1px solid ' + hair,
          background: paper, cursor: 'pointer', display: 'flex',
          alignItems: 'center', justifyContent: 'center', padding: 0,
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={ink} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
        </button>
        <div style={{ ...mono, fontSize: 10, color: muted }}>{kicker}</div>
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

function PrimaryBtn({ children, disabled, onClick, danger }) {
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

function GhostBtn({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '12px 16px', borderRadius: 10,
      border: '1px solid ' + hair, background: paper, color: ink,
      fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
    }}>{children}</button>
  );
}

function Avatar({ name, size = 36, bg = paper2, fg = ink2 }) {
  const initials = (name || '').split(' ').slice(0, 2).map(w => w[0]).join('');
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.28, flexShrink: 0,
      background: bg, color: fg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: size * 0.4, letterSpacing: '-0.02em',
    }}>{initials}</div>
  );
}

function FormChip({ form }) {
  const c = FORM_CHIP[form] || FORM_CHIP.OK;
  return (
    <span style={{
      ...mono, fontSize: 8, padding: '2px 5px', borderRadius: 4,
      background: c.bg, color: c.fg, letterSpacing: '0.06em',
    }}>{form}</span>
  );
}

function RoleAbbr({ role, bat, bowl }) {
  const r = role === 'Captain' ? 'CPT'
          : role === 'Wicket-Keeper' ? 'WK'
          : role === 'Batter' ? 'BAT'
          : role === 'Bowler' ? 'BWL'
          : 'ALL';
  return (
    <span style={{
      ...mono, fontSize: 9, color: muted, letterSpacing: '0.08em',
    }}>{r} · {bat}{bowl !== '—' ? ' · ' + bowl : ''}</span>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CkRosterThin — under-strength resolver
// ═══════════════════════════════════════════════════════════════════════════

function CkRosterThin({ have = 8, need = 11 } = {}) {
  const short = need - have;
  const [chosen, setChosen] = React.useState(null);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />
      <GateHeader
        kicker="Roster check · Lions vs Eagles"
        title="You're short on players."
        sub={`This match needs ${need} a side. You have ${have} confirmed. Pick how to handle it — both captains will see the change.`}
      />

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 18px 24px' }}>

        {/* Shortfall hero */}
        <div style={{
          padding: 16, borderRadius: 14,
          background: 'oklch(0.94 0.05 90)', color: ink,
          display: 'flex', alignItems: 'center', gap: 16, marginBottom: 18,
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: 14, background: amber, color: paper,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 28, letterSpacing: '-0.04em',
          }}>−{short}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 700 }}>
              Short {short} player{short === 1 ? '' : 's'}
            </div>
            <div style={{ fontSize: 12, color: ink2, marginTop: 2, lineHeight: 1.4 }}>
              Need {need} · have {have} confirmed in your squad
            </div>
            <div style={{ display: 'flex', gap: 4, marginTop: 8 }}>
              {Array.from({ length: need }, (_, i) => (
                <span key={i} style={{
                  flex: 1, height: 4, borderRadius: 2,
                  background: i < have ? green : 'rgba(20,18,14,0.10)',
                }} />
              ))}
            </div>
          </div>
        </div>

        <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 10 }}>OPTIONS</div>

        {/* The four resolvers */}
        {[
          {
            id: 'borrow',
            icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="9" cy="8" r="3.4"/><path d="M2 21c0-3.8 3-7 7-7s5 1 6 2.5"/><path d="M19 8v6M16 11h6"/></svg>,
            tint: ink,
            recommended: true,
            title: 'Borrow a player',
            sub: 'Guest from another team. Allowed in friendlies — both captains agree.',
            meta: `Find ${short} guest${short === 1 ? '' : 's'} · ~12 nearby`,
          },
          {
            id: 'unclaimed',
            icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="8" r="4" strokeDasharray="2.5 2"/><path d="M4 21c0-4 3-7 8-7s8 3 8 7" strokeDasharray="2.5 2"/></svg>,
            tint: amber,
            title: 'Add as unclaimed',
            sub: 'Just a name — they can claim the profile later, stats will follow.',
            meta: 'Fastest · stays on your squad after',
          },
          {
            id: 'reduce',
            icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M5 12h14M13 6l-6 6 6 6"/></svg>,
            tint: green,
            title: `Drop to ${have}-a-side`,
            sub: `Propose to Eagles. They confirm, format updates, both squads relax.`,
            meta: `${have}-a-side · same overs · same ball`,
          },
          {
            id: 'forfeit',
            icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="9"/><path d="M9 9l6 6M15 9l-6 6"/></svg>,
            tint: red,
            destructive: true,
            title: 'Withdraw — forfeit match',
            sub: 'Eagles get a walkover win. Your no-show rate goes up.',
            meta: 'Last resort',
          },
        ].map((opt, i) => {
          const active = chosen === opt.id;
          return (
            <button key={opt.id} onClick={() => setChosen(opt.id)} style={{
              width: '100%', display: 'flex', gap: 12, padding: 14, marginBottom: 8,
              background: active ? paper2 : paper,
              border: '2px solid ' + (active ? (opt.destructive ? red : ink) : hair),
              borderRadius: 12, cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10, flexShrink: 0,
                background: opt.tint, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{opt.icon}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                  <span style={{ fontWeight: 700, fontSize: 14, color: opt.destructive ? red : ink }}>{opt.title}</span>
                  {opt.recommended && <span style={{ ...mono, fontSize: 9, padding: '2px 6px', borderRadius: 4, background: ink, color: paper }}>Most common</span>}
                </div>
                <div style={{ fontSize: 12, color: muted, marginTop: 3, lineHeight: 1.45 }}>{opt.sub}</div>
                <div style={{ ...mono, fontSize: 9, color: muted, marginTop: 6 }}>{opt.meta}</div>
              </div>
              <div style={{
                width: 20, height: 20, borderRadius: 999, alignSelf: 'center', flexShrink: 0,
                border: '2px solid ' + (active ? (opt.destructive ? red : ink) : hair),
                background: active ? (opt.destructive ? red : ink) : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {active && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
              </div>
            </button>
          );
        })}

        {/* Live preview based on choice */}
        {chosen && (
          <div style={{
            marginTop: 10, padding: 12, borderRadius: 12,
            background: chosen === 'forfeit' ? 'oklch(0.96 0.04 28)' : paper2,
            border: '1px solid ' + hair,
          }}>
            <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 6 }}>NEXT</div>
            <div style={{ fontSize: 12.5, color: ink2, lineHeight: 1.5 }}>
              {chosen === 'borrow'    && <>Search nearby cricketers by role / city. Send guest-player requests. Eagles' captain sees borrowed players named with a “guest” pill.</>}
              {chosen === 'unclaimed' && <>Type {short} player name{short === 1 ? '' : 's'}. They go onto your squad as unclaimed placeholders. Stats accumulate; they can claim later.</>}
              {chosen === 'reduce'    && <>Eagles' captain gets a “Drop to {have}-a-side?” request. Match stays Pending until they confirm. Auto-cancels at T-12h if no reply.</>}
              {chosen === 'forfeit'   && <>This is logged as a walkover. Eagles get a win in their record. Your team's no-show rate adjusts. You'll be asked to confirm.</>}
            </div>
          </div>
        )}
      </div>

      <StickyCta>
        <GhostBtn>Save & exit</GhostBtn>
        <PrimaryBtn disabled={!chosen} danger={chosen === 'forfeit'}>
          {chosen === 'forfeit' ? 'Confirm forfeit' : 'Continue'}
          {chosen && chosen !== 'forfeit' && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </PrimaryBtn>
      </StickyCta>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CkXISelect — over-strength playing XI picker
// ═══════════════════════════════════════════════════════════════════════════

function CkXISelect({ need = 11, provisional = false } = {}) {
  // Pre-pick a sensible default XI
  const defaultXI = SQUAD.slice(0, need).map(p => p.id);
  const [picked, setPicked] = React.useState(new Set(defaultXI));
  const [keeper, setKeeper] = React.useState('s2');   // Adeel
  const [viceCpt, setViceCpt] = React.useState('s5'); // Usman

  const toggle = (id) => {
    setPicked(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        if (id === keeper) return prev; // can't unpick keeper
        next.delete(id);
      } else if (next.size < need) {
        next.add(id);
      }
      return next;
    });
  };

  const playing = SQUAD.filter(p => picked.has(p.id));
  const reserves = SQUAD.filter(p => !picked.has(p.id));
  const ready = picked.size === need && picked.has(keeper);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      <GateHeader
        kicker={provisional ? 'Provisional XI · pending Eagles' : 'Playing XI · Lions vs Eagles'}
        title={provisional ? 'Pencil in your XI.' : 'Pick your playing XI.'}
        sub={provisional
          ? `Match is still Pending. Players you pick get a heads-up — "you're penciled in for Sat 3 PM."`
          : `Choose ${need} from your squad of ${SQUAD.length}. The rest are reserves — they don't appear in stats unless they come on.`}
      />

      {/* Counter bar */}
      <div style={{
        padding: '10px 18px', borderBottom: '1px solid ' + hair, background: paper,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          ...mono, fontSize: 10, color: picked.size === need ? green : ink2, letterSpacing: '0.08em',
        }}>
          XI · {picked.size}/{need}
        </div>
        <div style={{ flex: 1, height: 4, background: paper2, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{
            width: `${(picked.size / need) * 100}%`, height: '100%',
            background: picked.size === need ? green : ink,
            transition: 'width 0.15s',
          }} />
        </div>
        <div style={{ ...mono, fontSize: 10, color: muted }}>
          {SQUAD.length - picked.size} RESERVE{SQUAD.length - picked.size === 1 ? '' : 'S'}
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto' }}>

        {/* Auto-pick helper */}
        <div style={{ padding: '12px 18px 8px', display: 'flex', gap: 6 }}>
          <button onClick={() => setPicked(new Set(SQUAD.slice(0, need).map(p => p.id)))} style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>AUTO · BEST FORM</button>
          <button onClick={() => setPicked(new Set())} style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>CLEAR</button>
          <button style={{
            ...mono, fontSize: 9, padding: '6px 10px', borderRadius: 999,
            border: '1px solid ' + hair, background: paper, color: ink2, cursor: 'pointer', fontFamily: 'JetBrains Mono',
          }}>LAST XI</button>
        </div>

        {/* Playing XI block */}
        <div style={{ padding: '8px 18px 4px' }}>
          <div style={{ ...mono, fontSize: 10, color: ink, marginBottom: 6 }}>PLAYING XI · {picked.size}/{need}</div>
        </div>
        <div>
          {playing.length === 0 && (
            <div style={{ padding: '20px 18px', textAlign: 'center', color: muted, fontSize: 12 }}>
              No one selected. Tap players below to add.
            </div>
          )}
          {playing.map(p => (
            <PlayerRow key={p.id}
              p={p}
              picked
              isKeeper={keeper === p.id}
              isVc={viceCpt === p.id}
              onToggle={() => toggle(p.id)}
              onMakeKeeper={() => setKeeper(p.id)}
              onMakeVc={() => setViceCpt(p.id)} />
          ))}
        </div>

        {/* Reserves block */}
        {reserves.length > 0 && (
          <>
            <div style={{ padding: '14px 18px 6px', borderTop: '1px solid ' + hair, marginTop: 6 }}>
              <div style={{ ...mono, fontSize: 10, color: muted, marginBottom: 2 }}>RESERVES · {reserves.length}</div>
              <div style={{ fontSize: 11, color: muted, lineHeight: 1.4 }}>
                Not in the XI. Stats don't accumulate unless they sub on.
              </div>
            </div>
            <div>
              {reserves.map(p => (
                <PlayerRow key={p.id} p={p} onToggle={() => toggle(p.id)} disabled={picked.size >= need} />
              ))}
            </div>
          </>
        )}

        {/* Validation note */}
        <div style={{ padding: '14px 18px 24px' }}>
          <div style={{
            padding: 12, borderRadius: 10, background: paper2,
            display: 'flex', gap: 10, alignItems: 'flex-start',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={ink2} strokeWidth="1.8" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
            <div style={{ fontSize: 11.5, color: ink2, lineHeight: 1.5 }}>
              {provisional
                ? <>You can edit this until match day. Final lock-in happens at the toss.</>
                : <>The XI locks when the first ball is bowled. You can still swap a Concussion-sub mid-match per the rules.</>}
            </div>
          </div>
        </div>
      </div>

      <StickyCta>
        <GhostBtn>Save draft</GhostBtn>
        <PrimaryBtn disabled={!ready}>
          {provisional ? 'Save provisional XI' : 'Lock XI'}
          {ready && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M9 18l6-6-6-6"/></svg>}
        </PrimaryBtn>
      </StickyCta>
    </div>
  );
}

function PlayerRow({ p, picked, isKeeper, isVc, onToggle, onMakeKeeper, onMakeVc, disabled }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '12px 18px',
      borderTop: '1px solid ' + hair,
      background: picked ? paper : 'transparent',
      opacity: disabled ? 0.5 : 1,
    }}>
      <button onClick={!disabled ? onToggle : undefined} style={{
        width: 24, height: 24, borderRadius: 6, flexShrink: 0,
        border: picked ? 'none' : '1.5px solid ' + (disabled ? hair : 'var(--soft)'),
        background: picked ? ink : paper,
        cursor: disabled ? 'default' : 'pointer', padding: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {picked && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={paper} strokeWidth="3" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>}
      </button>

      <Avatar name={p.name} />

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, color: ink }}>{p.name}</span>
          {p.role === 'Captain' && <span style={{ ...mono, fontSize: 8, padding: '1px 5px', borderRadius: 3, background: ink, color: paper }}>C</span>}
          {isVc && <span style={{ ...mono, fontSize: 8, padding: '1px 5px', borderRadius: 3, background: ink2, color: paper }}>VC</span>}
          {isKeeper && <span style={{ ...mono, fontSize: 8, padding: '1px 5px', borderRadius: 3, background: red, color: paper }}>WK</span>}
          <FormChip form={p.form} />
        </div>
        <div style={{ marginTop: 2, display: 'flex', alignItems: 'center', gap: 8 }}>
          <RoleAbbr role={p.role} bat={p.bat} bowl={p.bowl} />
          <span style={{ ...mono, fontSize: 9, color: muted }}>· {p.stats}</span>
        </div>
      </div>

      {picked && (
        <div style={{ display: 'flex', gap: 4 }}>
          {!isKeeper && (
            <button onClick={onMakeKeeper} title="Make wicket-keeper" style={{
              ...mono, fontSize: 8, padding: '4px 7px', borderRadius: 5,
              border: '1px solid ' + hair, background: paper, color: muted,
              cursor: 'pointer', fontFamily: 'JetBrains Mono',
            }}>WK</button>
          )}
          {!isVc && p.role !== 'Captain' && (
            <button onClick={onMakeVc} title="Make vice-captain" style={{
              ...mono, fontSize: 8, padding: '4px 7px', borderRadius: 5,
              border: '1px solid ' + hair, background: paper, color: muted,
              cursor: 'pointer', fontFamily: 'JetBrains Mono',
            }}>VC</button>
          )}
        </div>
      )}
    </div>
  );
}

window.CkRosterThin = CkRosterThin;
window.CkXISelect   = CkXISelect;

})();

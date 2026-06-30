// challenge-shared.jsx — shared atoms for the matchday Match-Request flow.
// Visual family: warm paper, Inter Tight display, JetBrains Mono kickers,
// 1px hairlines, no shadows on primary surfaces. Rounded line icons only.

(function () {

const ink    = 'var(--ink)';
const ink2   = 'var(--ink-2)';
const muted  = 'var(--muted)';
const soft   = 'var(--soft)';
const paper  = 'var(--paper)';
const paper2 = 'var(--paper-2)';
const surface= 'var(--surface)';
const hair   = 'var(--hairline)';
const line   = 'var(--line)';
const red    = 'var(--red)';
const redSoft= 'var(--red-soft)';
const green  = 'var(--green)';
const greenSoft = 'var(--green-soft)';
const amber  = 'var(--amber)';
const cream  = 'var(--cream)';

// amber that reads on paper for "countered" copy
const amberInk = 'oklch(0.46 0.11 75)';
const greenInk = 'oklch(0.34 0.10 148)';

const display = (size, weight = 700) => ({
  fontFamily: 'Inter Tight, system-ui', fontSize: size, fontWeight: weight,
  letterSpacing: '-0.025em', color: ink, lineHeight: 1.08,
});
const mono = {
  fontFamily: 'JetBrains Mono, monospace', fontWeight: 700,
  letterSpacing: '0.10em', textTransform: 'uppercase',
};

// ─────────────────────────────────────────────────────────
// Rounded line icons (Material-rounded flavour)
// ─────────────────────────────────────────────────────────
const PATHS = {
  back:   <path d="M15 18l-6-6 6-6"/>,
  next:   <path d="M9 18l6-6-6-6"/>,
  arrow:  <path d="M5 12h14M13 6l6 6-6 6"/>,
  check:  <polyline points="20 6 9 17 4 12"/>,
  close:  <path d="M6 6l12 12M18 6L6 18"/>,
  search: <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
  pin:    <><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></>,
  clock:  <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
  cal:    <><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></>,
  plus:   <path d="M12 5v14M5 12h14"/>,
  minus:  <path d="M5 12h14"/>,
  users:  <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></>,
  glove:  <path d="M6 11V6.5a1.5 1.5 0 0 1 3 0V10m0 0V4.5a1.5 1.5 0 0 1 3 0V10m0-0.5V5.5a1.5 1.5 0 0 1 3 0V12m0-3.5a1.5 1.5 0 0 1 3 0V15a6 6 0 0 1-6 6h-2a6 6 0 0 1-5.2-3l-2.3-4a1.5 1.5 0 0 1 2.6-1.5L6 14"/>,
  copy:   <><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h8"/></>,
  share:  <><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/></>,
  info:   <><circle cx="12" cy="12" r="9"/><path d="M12 16v-4M12 8h.01"/></>,
  alert:  <><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/></>,
  flag:   <><path d="M4 22V4M4 4h13l-2 4 2 4H4"/></>,
  swords: <><path d="M14.5 17.5 22 10l-2-2-7.5 7.5M9.5 6.5 2 14l2 2 7.5-7.5"/></>,
  retry:  <><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/></>,
  pencil: <path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>,
  msg:    <path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>,
  bell:   <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></>,
  star:   <path d="M12 3l2.9 5.9 6.5.9-4.7 4.6 1.1 6.5L12 18l-5.8 3.4 1.1-6.5L2.6 9.8l6.5-.9z"/>,
  trophy: <><path d="M6 4h12v4a6 6 0 0 1-12 0z"/><path d="M6 6H3v2a3 3 0 0 0 3 3M18 6h3v2a3 3 0 0 1-3 3M9 20h6M12 14v6"/></>,
  play:   <path d="M6 4l14 8-14 8z"/>,
  dots:   <><circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/></>,
  whistle:<><circle cx="9" cy="14" r="6"/><path d="M15 12l7-3-1 4-6 1M9 14h.01"/></>,
  ticket: <><rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 11a2 2 0 0 0 0 2M21 11a2 2 0 0 1 0 2"/></>,
};
function Icon({ name, size = 18, stroke = 'currentColor', sw = 2, style }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style}>
      {PATHS[name] || null}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────
// Header — kicker · step indicator · progress · title · sub
// ─────────────────────────────────────────────────────────
function ChHeader({ kicker, step, total, title, sub, onBack, right }) {
  return (
    <div style={{ padding: '14px 18px 16px', borderBottom: '1px solid ' + hair, background: paper, flexShrink: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: total ? 10 : 12 }}>
        {onBack && (
          <button onClick={onBack} aria-label="Back" style={iconBtn}>
            <Icon name="back" size={14} stroke={ink} sw={2.2} />
          </button>
        )}
        <div style={{ ...mono, fontSize: 10, color: muted, flex: 1 }}>{kicker}</div>
        {right}
      </div>
      {total ? (
        <div style={{ display: 'flex', gap: 4, marginBottom: 14 }}>
          {Array.from({ length: total }, (_, i) => (
            <div key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i < step ? ink : 'rgba(20,18,14,0.10)', transition: 'background .18s' }} />
          ))}
        </div>
      ) : null}
      <div style={display(24)}>{title}</div>
      {sub && <div style={{ fontSize: 13, color: ink2, marginTop: 5, lineHeight: 1.45 }}>{sub}</div>}
    </div>
  );
}

const iconBtn = {
  width: 32, height: 32, borderRadius: 8, border: '1px solid ' + hair,
  background: paper, cursor: 'pointer', display: 'flex',
  alignItems: 'center', justifyContent: 'center', padding: 0, flexShrink: 0,
};

// ─────────────────────────────────────────────────────────
// Sticky footer — hint line + primary CTA, optional secondary,
// optional inline error (retry) that replaces the hint line.
// ─────────────────────────────────────────────────────────
function ChCta({ hint, cta, onCta, disabled, secondary, onSecondary, error, onRetry, busy }) {
  return (
    <div style={{
      borderTop: '1px solid ' + hair, padding: '10px 18px 12px', background: paper, flexShrink: 0,
      paddingBottom: 'calc(12px + env(safe-area-inset-bottom))',
    }}>
      {error ? (
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8, marginBottom: 9,
          padding: '8px 10px', borderRadius: 9, background: redSoft,
        }}>
          <Icon name="alert" size={14} stroke={red} sw={2} style={{ flexShrink: 0 }} />
          <span style={{ flex: 1, fontSize: 11.5, color: 'oklch(0.40 0.16 28)', lineHeight: 1.35 }}>{error}</span>
          <button onClick={onRetry} style={{
            ...mono, fontSize: 9, padding: '5px 9px', borderRadius: 7, cursor: 'pointer',
            border: 'none', background: red, color: paper, fontFamily: 'JetBrains Mono',
            display: 'inline-flex', alignItems: 'center', gap: 5,
          }}><Icon name="retry" size={11} stroke={paper} sw={2.4} />RETRY</button>
        </div>
      ) : hint ? (
        <div style={{ fontSize: 11.5, color: muted, textAlign: 'center', marginBottom: 9, lineHeight: 1.35 }}>{hint}</div>
      ) : null}
      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        {secondary && (
          <button onClick={onSecondary} style={{
            padding: '13px 16px', borderRadius: 12, border: '1px solid ' + hair,
            background: paper, color: ink, fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
          }}>{secondary}</button>
        )}
        <button onClick={!disabled && !busy ? onCta : undefined} disabled={disabled} style={{
          flex: 1, padding: '13px 16px', borderRadius: 12, border: 'none',
          background: disabled ? paper2 : ink, color: disabled ? muted : paper,
          fontWeight: 700, fontSize: 14, cursor: disabled || busy ? 'default' : 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, minWidth: 0,
        }}>
          {busy ? <Spinner /> : (
            <>
              <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{cta}</span>
              {!disabled && <Icon name="arrow" size={15} stroke={paper} sw={2.2} style={{ flexShrink: 0 }} />}
            </>
          )}
        </button>
      </div>
    </div>
  );
}

function Spinner() {
  return (
    <span style={{
      width: 16, height: 16, borderRadius: 999, display: 'inline-block',
      border: '2px solid rgba(255,255,255,0.35)', borderTopColor: paper,
      animation: 'ch-spin 0.7s linear infinite',
    }} />
  );
}

// ─────────────────────────────────────────────────────────
// Chip / SectionLabel
// ─────────────────────────────────────────────────────────
function Chip({ active, onClick, children, disabled }) {
  return (
    <button onClick={!disabled ? onClick : undefined} style={{
      padding: '9px 14px', borderRadius: 999,
      border: '1px solid ' + (active ? ink : hair),
      background: active ? ink : paper, color: active ? paper : (disabled ? soft : ink),
      fontWeight: 600, fontSize: 13, cursor: disabled ? 'default' : 'pointer', fontFamily: 'inherit',
      whiteSpace: 'nowrap', minHeight: 38,
    }}>{children}</button>
  );
}

function SectionLabel({ children, hint }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8, marginBottom: 9 }}>
      <span style={{ ...mono, fontSize: 10, color: muted }}>{children}</span>
      {hint && <span style={{ fontSize: 11, color: muted }}>{hint}</span>}
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// Stepper — ±  numeric with mono read-out (a11y: not slider-only)
// ─────────────────────────────────────────────────────────
function Stepper({ value, min, max, step = 1, onChange, suffix, big }) {
  const dec = () => onChange(Math.max(min, value - step));
  const inc = () => onChange(Math.min(max, value + step));
  const sBtn = (d) => ({
    width: 40, height: 40, borderRadius: 11, flexShrink: 0,
    border: '1px solid ' + hair, background: paper, cursor: d ? 'default' : 'pointer',
    color: d ? soft : ink, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
  });
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <button onClick={value <= min ? undefined : dec} style={sBtn(value <= min)} aria-label="Decrease"><Icon name="minus" size={16} sw={2.4} /></button>
      <div style={{ flex: 1, textAlign: 'center' }}>
        <span style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, fontSize: big ? 26 : 19, color: ink, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
        {suffix && <span style={{ fontSize: 12, color: muted, marginLeft: 6 }}>{suffix}</span>}
      </div>
      <button onClick={value >= max ? undefined : inc} style={sBtn(value >= max)} aria-label="Increase"><Icon name="plus" size={16} sw={2.4} /></button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// Slider with mono read-out + ± steppers either side
// ─────────────────────────────────────────────────────────
function SliderRow({ value, min, max, step = 1, onChange, unit, unlimited, isUnlimited, onToggleUnlimited }) {
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={() => !isUnlimited && onChange(Math.max(min, value - step))} style={sqBtn} aria-label="Decrease"><Icon name="minus" size={15} sw={2.4} stroke={isUnlimited ? soft : ink} /></button>
        <div style={{ flex: 1, position: 'relative', height: 36, display: 'flex', alignItems: 'center' }}>
          <div style={{ position: 'absolute', left: 0, right: 0, height: 4, borderRadius: 2, background: paper2 }} />
          {!isUnlimited && <div style={{ position: 'absolute', left: 0, width: pct + '%', height: 4, borderRadius: 2, background: ink }} />}
          <input type="range" min={min} max={max} step={step} value={value} disabled={isUnlimited}
            onChange={(e) => onChange(Number(e.target.value))}
            style={{ position: 'absolute', left: -2, right: -2, width: 'calc(100% + 4px)', margin: 0, accentColor: ink, opacity: isUnlimited ? 0.4 : 1 }} />
        </div>
        <button onClick={() => !isUnlimited && onChange(Math.min(max, value + step))} style={sqBtn} aria-label="Increase"><Icon name="plus" size={15} sw={2.4} stroke={isUnlimited ? soft : ink} /></button>
        <div style={{ minWidth: 58, textAlign: 'right' }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontWeight: 700, fontSize: 17, color: ink, fontVariantNumeric: 'tabular-nums' }}>{isUnlimited ? '∞' : value}</span>
          {unit && !isUnlimited && <span style={{ fontSize: 10.5, color: muted, marginLeft: 4 }}>{unit}</span>}
        </div>
      </div>
      {unlimited && (
        <button onClick={onToggleUnlimited} style={{
          marginTop: 8, width: '100%', padding: '9px 0', borderRadius: 10, cursor: 'pointer', fontFamily: 'inherit',
          border: '1px solid ' + (isUnlimited ? ink : hair), background: isUnlimited ? ink : paper,
          color: isUnlimited ? paper : ink2, fontSize: 12.5, fontWeight: 600,
        }}>Unlimited overs · Test match</button>
      )}
    </div>
  );
}
const sqBtn = {
  width: 36, height: 36, borderRadius: 10, flexShrink: 0,
  border: '1px solid ' + hair, background: paper, cursor: 'pointer',
  display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
};

// ─────────────────────────────────────────────────────────
// Crest + avatar + role pill
// ─────────────────────────────────────────────────────────
function Crest({ size = 44, bg, fg = paper, label, radius }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: radius != null ? radius : size * 0.24, flexShrink: 0,
      background: bg, color: fg, display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 800, fontSize: size * 0.36, letterSpacing: '-0.03em',
    }}>{label}</div>
  );
}

function Avatar({ name, size = 32 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.28, flexShrink: 0,
      background: paper2, color: ink2, display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter Tight', fontWeight: 700, fontSize: size * 0.38,
    }}>{name.split(' ').map(w => w[0]).join('').slice(0, 2)}</div>
  );
}

const ROLE_TONE = {
  BAT: { bg: paper2, fg: ink2 },
  BOW: { bg: cream, fg: amberInk },
  AR:  { bg: greenSoft, fg: greenInk },
  WK:  { bg: 'var(--red)', fg: paper },
};
function RolePill({ role }) {
  const t = ROLE_TONE[role] || ROLE_TONE.BAT;
  return (
    <span style={{ ...mono, fontSize: 8.5, padding: '2px 5px', borderRadius: 4, background: t.bg, color: t.fg, letterSpacing: '0.08em' }}>{role}</span>
  );
}

// Status pill (pending/countered/accepted/declined/cancelled/expired)
const STATUS_TONE = {
  pending:   { bg: paper2, fg: ink2, dot: muted, label: 'PENDING' },
  countered: { bg: cream, fg: amberInk, dot: amber, label: 'COUNTERED' },
  accepted:  { bg: greenSoft, fg: greenInk, dot: green, label: 'ACCEPTED' },
  declined:  { bg: paper2, fg: muted, dot: soft, label: 'DECLINED' },
  cancelled: { bg: paper2, fg: muted, dot: soft, label: 'CANCELLED' },
  expired:   { bg: paper2, fg: muted, dot: soft, label: 'EXPIRED' },
};
function StatusPill({ status }) {
  const t = STATUS_TONE[status] || STATUS_TONE.pending;
  return (
    <span style={{ ...mono, fontSize: 9, padding: '4px 8px', borderRadius: 6, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', gap: 5 }}>
      <span style={{ width: 5, height: 5, borderRadius: 999, background: t.dot }} />{t.label}
    </span>
  );
}

window.Ch = {
  ink, ink2, muted, soft, paper, paper2, surface, hair, line,
  red, redSoft, green, greenSoft, amber, cream, amberInk, greenInk,
  display, mono, Icon, ChHeader, ChCta, Chip, SectionLabel, Stepper, SliderRow,
  Crest, Avatar, RolePill, StatusPill, Spinner, iconBtn,
};

})();

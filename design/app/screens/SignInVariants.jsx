// SignInVariants.jsx — Three directions for the sign-in screen.
// All three deliver the same two auth methods (Email→OTP, Google) but differ in:
//   · A — Minimal & calm  (refined current direction, fix the dead-zone)
//   · B — Editorial brand-forward (giant wordmark, magazine-cover energy)
//   · C — Split dark/light (ink hero panel above, paper auth panel below)
//
// Each is a self-contained component that renders inside <IOSDevice> (402×874).

(function () {

const ink = 'var(--ink)';
const ink2 = 'var(--ink-2)';
const muted = 'var(--muted)';
const soft = 'var(--soft)';
const paper = 'var(--paper)';
const paper2 = 'var(--paper-2)';
const hair = 'var(--hairline)';
const line = 'var(--line)';
const red = 'var(--red)';
const cream = 'var(--cream)';
const amber = 'var(--amber)';

// Shared Google G mark
function GoogleG({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ flexShrink: 0 }}>
      <path fill="#4285F4" d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4c-.2 1.3-.9 2.4-2 3.1v2.6h3.3c1.9-1.8 3-4.4 3-7.5z"/>
      <path fill="#34A853" d="M12 22c2.7 0 5-.9 6.7-2.4l-3.3-2.6c-.9.6-2 1-3.4 1-2.6 0-4.8-1.8-5.6-4.1H2.9v2.6C4.6 19.9 8 22 12 22z"/>
      <path fill="#FBBC05" d="M6.4 13.9c-.2-.6-.3-1.3-.3-1.9s.1-1.3.3-1.9V7.5H2.9C2.3 8.9 2 10.4 2 12s.3 3.1.9 4.5l3.5-2.6z"/>
      <path fill="#EA4335" d="M12 6c1.5 0 2.8.5 3.8 1.5l2.9-2.9C16.9 2.9 14.7 2 12 2 8 2 4.6 4.1 2.9 7.5l3.5 2.6C7.2 7.8 9.4 6 12 6z"/>
    </svg>
  );
}

// Tiny pitch motif (cricket field markings) — for atmosphere
function PitchMotif({ opacity = 0.06, size = 220 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 200 200" style={{ opacity }}>
      <ellipse cx="100" cy="100" rx="95" ry="60" stroke="currentColor" strokeWidth="0.6" fill="none"/>
      <ellipse cx="100" cy="100" rx="55" ry="34" stroke="currentColor" strokeWidth="0.6" fill="none"/>
      <rect x="92" y="70" width="16" height="60" stroke="currentColor" strokeWidth="0.6" fill="none"/>
      <line x1="100" y1="40" x2="100" y2="160" stroke="currentColor" strokeWidth="0.6"/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────
// VARIANT A — Minimal & calm
// Refined current direction. Drop the dead-zone with a quiet
// value-prop strip. Tighter copy. Pitch motif as background.
// ─────────────────────────────────────────────────────────
function SignInVariantA() {
  const [email, setEmail] = React.useState('');
  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative', overflow: 'hidden' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Background pitch motif — bottom-right corner */}
      <div style={{ position: 'absolute', right: -60, bottom: 60, color: ink, pointerEvents: 'none' }}>
        <PitchMotif size={300} opacity={0.04} />
      </div>

      <div style={{ flex: 1, padding: '20px 24px 24px', display: 'flex', flexDirection: 'column', gap: 22, position: 'relative', zIndex: 1 }}>
        {/* Brand mark */}
        <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 22, letterSpacing: '-0.045em', color: ink }}>
          matchday<span style={{ color: red }}>.</span>
        </div>

        {/* Headline */}
        <div style={{ marginTop: 24 }}>
          <h1 className="ck-display" style={{
            fontSize: 36, fontWeight: 700, margin: 0, lineHeight: 0.98, letterSpacing: '-0.04em', color: ink,
          }}>
            Get on the field.
          </h1>
          <p style={{ margin: '10px 0 0', color: ink2, fontSize: 14, lineHeight: 1.5 }}>
            Cricket for the club, the village, the mohalla.
          </p>
        </div>

        {/* Email + Send code */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 8 }}>
          <label className="ck-label">Email address</label>
          <input
            className="ck-input"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={e => setEmail(e.target.value)}
            style={{ fontSize: 16, fontWeight: 500 }}
          />
          <button className="ck-btn" disabled={!valid} style={{ marginTop: 4 }}>
            Send code
          </button>
          <div style={{ fontSize: 11, color: muted, textAlign: 'center', marginTop: 2 }}>
            We'll email you a 6-digit code · no password
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {/* OR + Google */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          color: soft, fontSize: 11, fontFamily: 'JetBrains Mono',
          fontWeight: 600, letterSpacing: '0.14em',
        }}>
          <div style={{ flex: 1, height: 1, background: hair }} />
          <span>OR</span>
          <div style={{ flex: 1, height: 1, background: hair }} />
        </div>

        <button className="ck-btn" style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          background: paper, color: ink, border: '1px solid ' + line,
          padding: '14px 18px', fontSize: 15,
          boxShadow: '0 1px 2px rgba(40,30,15,0.04)',
        }}>
          <GoogleG />
          Continue with Google
        </button>

        <div style={{ textAlign: 'center', fontSize: 11, color: soft, lineHeight: 1.5 }}>
          By continuing you agree to our <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Terms</a> &amp; <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Privacy Policy</a>.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// VARIANT B — Editorial brand-forward
// Giant stacked wordmark dominates the top. Auth controls sit
// in a quiet band below. Cream accent band. Magazine cover energy.
// ─────────────────────────────────────────────────────────
function SignInVariantB() {
  const [email, setEmail] = React.useState('');
  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, position: 'relative', overflow: 'hidden' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Editorial hero — fills top */}
      <div style={{ padding: '16px 24px 0', flexShrink: 0 }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 600, color: muted, letterSpacing: '0.16em', marginBottom: 18 }}>
          ISSUE NO. 01 · GRASSROOTS CRICKET
        </div>
        <div style={{ position: 'relative' }}>
          <div className="ck-display" style={{
            fontSize: 86, fontWeight: 700, lineHeight: 0.88, letterSpacing: '-0.06em',
            color: ink,
          }}>
            match<br/>day<span style={{ color: red }}>.</span>
          </div>
          <div style={{
            position: 'absolute', top: 8, right: -8,
            width: 80, height: 80, color: ink, opacity: 0.08,
          }}>
            <PitchMotif size={80} opacity={1} />
          </div>
        </div>
        <div style={{ marginTop: 14, fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 500, color: ink2, lineHeight: 1.35, letterSpacing: '-0.005em', maxWidth: 280 }}>
          Score the match. Run the tournament. Find your team.
        </div>
      </div>

      {/* Cream auth band */}
      <div style={{ flex: 1 }} />
      <div style={{
        flexShrink: 0, background: cream,
        borderTop: '1px solid ' + 'oklch(0.86 0.05 90)',
        padding: '20px 24px 24px',
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <input
            className="ck-input"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={e => setEmail(e.target.value)}
            style={{ flex: 1, fontSize: 15, fontWeight: 500, background: paper }}
          />
          <button
            disabled={!valid}
            style={{
              padding: '13px 18px', borderRadius: 12,
              background: ink, color: paper, border: 'none',
              fontFamily: 'Inter', fontWeight: 700, fontSize: 14,
              cursor: valid ? 'pointer' : 'default',
              opacity: valid ? 1 : 0.4, flexShrink: 0,
              display: 'inline-flex', alignItems: 'center', gap: 6,
            }}
          >
            Send
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
          </button>
        </div>
        <div style={{ fontSize: 11, color: 'oklch(0.42 0.05 80)', textAlign: 'left', marginTop: -2 }}>
          We'll email a 6-digit code · no password
        </div>

        <button style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          padding: '13px 18px', borderRadius: 12,
          background: paper, color: ink, border: '1px solid ' + line,
          fontFamily: 'Inter', fontWeight: 600, fontSize: 14, cursor: 'pointer',
          marginTop: 2,
        }}>
          <GoogleG size={18} />
          Continue with Google
        </button>

        <div style={{ textAlign: 'center', fontSize: 10.5, color: 'oklch(0.45 0.05 80)', lineHeight: 1.5, marginTop: 4 }}>
          By continuing you agree to our <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Terms</a> &amp; <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Privacy Policy</a>.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// VARIANT C — Split dark/light
// Dark ink hero panel at top with brand + tagline.
// Paper auth panel at bottom. Strong split, calm controls.
// ─────────────────────────────────────────────────────────
function SignInVariantC() {
  const [email, setEmail] = React.useState('');
  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, overflow: 'hidden' }}>
      <div style={{ height: 44, flexShrink: 0, background: ink }} />

      {/* Dark ink hero */}
      <div style={{
        background: ink, color: paper,
        padding: '28px 24px 36px', flexShrink: 0,
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Subtle pitch motif */}
        <div style={{ position: 'absolute', right: -40, top: 20, color: paper, opacity: 0.08 }}>
          <PitchMotif size={240} opacity={1} />
        </div>

        <div style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 600, letterSpacing: '0.16em', color: 'rgba(255,255,255,0.6)' }}>
            v0.1 · KARACHI
          </div>
          <div style={{ marginTop: 22, fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 56, letterSpacing: '-0.045em', lineHeight: 0.92 }}>
            matchday<span style={{ color: red }}>.</span>
          </div>
          <div style={{ marginTop: 14, fontSize: 15, color: 'rgba(255,255,255,0.78)', lineHeight: 1.45, maxWidth: 260 }}>
            Cricket for the club, the village, the mohalla. Score, organize, follow — all in one place.
          </div>
        </div>
      </div>

      {/* Paper auth panel */}
      <div style={{
        flex: 1, padding: '24px 24px 24px',
        display: 'flex', flexDirection: 'column', gap: 14,
        position: 'relative',
      }}>
        {/* Notch — the panel "lifts" out of the dark hero */}
        <div style={{
          position: 'absolute', top: -12, left: 24, right: 24, height: 4,
          background: 'transparent',
          borderTop: '1px solid ' + hair,
        }} />

        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, letterSpacing: '0.14em', color: muted, marginBottom: -2 }}>
          SIGN IN
        </div>

        <div>
          <label className="ck-label" style={{ marginBottom: 6, display: 'block' }}>Email address</label>
          <input
            className="ck-input"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={e => setEmail(e.target.value)}
            style={{ fontSize: 16, fontWeight: 500 }}
          />
          <div style={{ fontSize: 11, color: muted, marginTop: 6 }}>
            6-digit code · no password needed
          </div>
        </div>

        <button className="ck-btn" disabled={!valid}>
          Send code
        </button>

        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          color: soft, fontSize: 11, fontFamily: 'JetBrains Mono',
          fontWeight: 600, letterSpacing: '0.14em', marginTop: 2,
        }}>
          <div style={{ flex: 1, height: 1, background: hair }} />
          <span>OR</span>
          <div style={{ flex: 1, height: 1, background: hair }} />
        </div>

        <button className="ck-btn" style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          background: paper, color: ink, border: '1px solid ' + line,
          padding: '14px 18px', fontSize: 15,
          boxShadow: '0 1px 2px rgba(40,30,15,0.04)',
        }}>
          <GoogleG />
          Continue with Google
        </button>

        <div style={{ flex: 1 }} />

        <div style={{ textAlign: 'center', fontSize: 11, color: soft, lineHeight: 1.5 }}>
          By continuing you agree to our <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Terms</a> &amp; <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Privacy Policy</a>.
        </div>
      </div>
    </div>
  );
}

window.CkSignInA = SignInVariantA;
window.CkSignInB = SignInVariantB;
window.CkSignInC = SignInVariantC;

// ─────────────────────────────────────────────────────────
// VARIANT D — Iconographic / illustrated hero
// A drawn cricket motif occupies the top half — pitch markings,
// stumps and a batter silhouette as ink line-art. Brand tucked
// underneath. Auth controls compact at the bottom. Less type-driven,
// more visual identity. Feels like a sports brand intro.
// ─────────────────────────────────────────────────────────
function SignInVariantD() {
  const [email, setEmail] = React.useState('');
  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, overflow: 'hidden' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* Illustrated hero — top 40% */}
      <div style={{
        position: 'relative', height: 320, flexShrink: 0,
        background: cream,
        borderBottom: '1px solid oklch(0.86 0.05 90)',
        overflow: 'hidden',
      }}>
        {/* Pitch overhead — large, off-center */}
        <svg viewBox="0 0 200 200" style={{
          position: 'absolute', left: -40, top: 20, width: 360, height: 360,
          color: ink, opacity: 0.18,
        }}>
          <ellipse cx="100" cy="100" rx="95" ry="60" stroke="currentColor" strokeWidth="0.8" fill="none"/>
          <ellipse cx="100" cy="100" rx="55" ry="34" stroke="currentColor" strokeWidth="0.8" fill="none"/>
          <rect x="92" y="70" width="16" height="60" stroke="currentColor" strokeWidth="0.8" fill="none"/>
          <line x1="100" y1="40" x2="100" y2="160" stroke="currentColor" strokeWidth="0.8"/>
        </svg>

        {/* Stumps + bails — bottom right */}
        <svg width="80" height="120" viewBox="0 0 80 120" style={{
          position: 'absolute', right: 28, bottom: 28, color: ink,
        }}>
          <line x1="20" y1="20" x2="20" y2="100" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
          <line x1="40" y1="20" x2="40" y2="100" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
          <line x1="60" y1="20" x2="60" y2="100" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
          <line x1="14" y1="18" x2="46" y2="18" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"/>
          <line x1="34" y1="18" x2="66" y2="18" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"/>
        </svg>

        {/* Red ball — top right */}
        <div style={{
          position: 'absolute', top: 36, right: 56,
          width: 44, height: 44, borderRadius: 999,
          background: red,
          boxShadow: 'inset -6px -8px 14px rgba(0,0,0,0.18)',
        }}>
          {/* seam */}
          <svg viewBox="0 0 44 44" width="44" height="44" style={{ position: 'absolute', inset: 0 }}>
            <path d="M 6 22 Q 22 4 38 22" stroke="white" strokeWidth="1" fill="none" opacity="0.7"/>
            <path d="M 6 22 Q 22 40 38 22" stroke="white" strokeWidth="1" fill="none" opacity="0.7"/>
          </svg>
        </div>

        {/* Wordmark in bottom-left of hero */}
        <div style={{
          position: 'absolute', left: 24, bottom: 22,
          fontFamily: 'Inter Tight', fontWeight: 700,
          fontSize: 44, letterSpacing: '-0.045em', lineHeight: 1, color: ink,
        }}>
          matchday<span style={{ color: red }}>.</span>
        </div>
      </div>

      {/* Auth panel */}
      <div style={{
        flex: 1, padding: '20px 24px 24px',
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>
        <div style={{ fontSize: 14.5, color: ink2, lineHeight: 1.45 }}>
          Cricket for the club, the village, the mohalla.
        </div>

        <div style={{ marginTop: 6 }}>
          <input
            className="ck-input"
            type="email"
            placeholder="Email address"
            value={email}
            onChange={e => setEmail(e.target.value)}
            style={{ fontSize: 16, fontWeight: 500 }}
          />
        </div>

        <button className="ck-btn" disabled={!valid}>
          Send code
        </button>

        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          color: soft, fontSize: 11, fontFamily: 'JetBrains Mono',
          fontWeight: 600, letterSpacing: '0.14em',
        }}>
          <div style={{ flex: 1, height: 1, background: hair }} />
          <span>OR</span>
          <div style={{ flex: 1, height: 1, background: hair }} />
        </div>

        <button className="ck-btn" style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          background: paper, color: ink, border: '1px solid ' + line,
          padding: '14px 18px', fontSize: 15,
        }}>
          <GoogleG />
          Continue with Google
        </button>

        <div style={{ flex: 1 }} />

        <div style={{ textAlign: 'center', fontSize: 11, color: soft, lineHeight: 1.5 }}>
          By continuing you agree to our <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Terms</a> &amp; <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Privacy Policy</a>.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// VARIANT E — Method picker (two equal cards)
// No primary/secondary hierarchy — both methods presented as equal
// stacked cards with a short value-prop each. Tap email card to
// reveal the input inline. Cleaner pattern when you don't want to
// privilege one method over the other.
// ─────────────────────────────────────────────────────────
function SignInVariantE() {
  const [picked, setPicked] = React.useState(null); // null | 'email' | 'google'
  const [email, setEmail] = React.useState('');
  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: paper, overflow: 'hidden' }}>
      <div style={{ height: 44, flexShrink: 0 }} />

      <div style={{ flex: 1, padding: '24px 24px 24px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        {/* Brand */}
        <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 22, letterSpacing: '-0.045em', color: ink }}>
          matchday<span style={{ color: red }}>.</span>
        </div>

        {/* Headline */}
        <div style={{ marginTop: 18 }}>
          <h1 className="ck-display" style={{
            fontSize: 30, fontWeight: 700, margin: 0, lineHeight: 1.05, letterSpacing: '-0.035em',
          }}>
            How would you like<br/>to sign in?
          </h1>
          <p style={{ margin: '8px 0 0', color: ink2, fontSize: 14, lineHeight: 1.45 }}>
            Either way, we'll get you to your team in under a minute.
          </p>
        </div>

        {/* Method cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 4 }}>

          {/* Email card */}
          <div style={{
            background: picked === 'email' ? paper : paper,
            border: '1.5px solid ' + (picked === 'email' ? ink : line),
            borderRadius: 14,
            padding: 16,
            transition: 'border-color .15s',
            cursor: picked === 'email' ? 'default' : 'pointer',
          }} onClick={() => picked !== 'email' && setPicked('email')}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10,
                background: ink, color: paper,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>
                </svg>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, letterSpacing: '-0.015em', color: ink }}>
                  Continue with email
                </div>
                <div style={{ fontSize: 12, color: muted, marginTop: 2 }}>
                  We'll send a 6-digit code · no password
                </div>
              </div>
              {picked !== 'email' && (
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
              )}
            </div>

            {picked === 'email' && (
              <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
                <input
                  className="ck-input"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  autoFocus
                  style={{ fontSize: 15, fontWeight: 500 }}
                />
                <button className="ck-btn" disabled={!valid}>
                  Send code
                </button>
              </div>
            )}
          </div>

          {/* Google card */}
          <button
            onClick={() => setPicked('google')}
            style={{
              width: '100%', textAlign: 'left',
              background: paper,
              border: '1.5px solid ' + (picked === 'google' ? ink : line),
              borderRadius: 14,
              padding: 16,
              cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', alignItems: 'center', gap: 12,
              transition: 'border-color .15s',
            }}
          >
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: paper2, border: '1px solid ' + hair,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <GoogleG size={20} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 16, letterSpacing: '-0.015em', color: ink }}>
                Continue with Google
              </div>
              <div style={{ fontSize: 12, color: muted, marginTop: 2 }}>
                One-tap sign-in with your Google account
              </div>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={muted} strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
          </button>
        </div>

        <div style={{ flex: 1 }} />

        <div style={{ textAlign: 'center', fontSize: 11, color: soft, lineHeight: 1.5 }}>
          By continuing you agree to our <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Terms</a> &amp; <a href="#" style={{ color: ink2, textDecoration: 'underline' }}>Privacy Policy</a>.
        </div>
      </div>
    </div>
  );
}

window.CkSignInD = SignInVariantD;
window.CkSignInE = SignInVariantE;

})();

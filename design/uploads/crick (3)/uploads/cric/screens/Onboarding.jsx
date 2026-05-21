// Onboarding.jsx — Circk onboarding flow (phone OTP → profile → player profile)
// Renders inside <IOSDevice>. Self-contained step machine.

const ck = (cls, ...rest) => [cls, ...rest].filter(Boolean).join(' ');

function CkLogo({ size = 28 }) {
  return (
    <div style={{
      fontFamily: 'Inter Tight', fontWeight: 700, letterSpacing: '-0.045em',
      fontSize: size, lineHeight: 1, color: 'var(--ink)',
    }}>
      circk<span style={{ color: 'var(--red)' }}>.</span>
    </div>
  );
}

// Step indicator (1..n) — small dashes
function StepDots({ index, total }) {
  return (
    <div style={{ display: 'flex', gap: 6, padding: '0 24px' }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          flex: 1, height: 3, borderRadius: 2,
          background: i <= index ? 'var(--ink)' : 'var(--hairline)',
          transition: 'background .25s',
        }} />
      ))}
    </div>
  );
}

// ── Step 1: Phone entry ───────────────────────────────────────
function PhoneStep({ value, setValue, onNext }) {
  return (
    <div style={{ padding: '32px 24px 24px', display: 'flex', flexDirection: 'column', gap: 28, flex: 1 }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <h1 className="ck-display" style={{
          fontSize: 32, fontWeight: 700, margin: 0, lineHeight: 1.05,
        }}>
          What’s your<br/>number?
        </h1>
        <p style={{ margin: 0, color: 'var(--muted)', fontSize: 15, lineHeight: 1.4 }}>
          We’ll text you a code. No spam — promise.
        </p>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <div className="ck-input" style={{
          width: 92, display: 'flex', alignItems: 'center', gap: 6,
          padding: '14px 12px', flex: 'none',
        }}>
          <span style={{ fontSize: 18 }}>🇵🇰</span>
          <span style={{ fontWeight: 600 }}>+92</span>
        </div>
        <input
          className="ck-input"
          inputMode="numeric"
          placeholder="3xx xxx xxxx"
          value={value}
          onChange={e => setValue(e.target.value.replace(/[^\d ]/g, '').slice(0, 12))}
          style={{ flex: 1, fontVariantNumeric: 'tabular-nums', fontSize: 18, fontWeight: 500 }}
          autoFocus
        />
      </div>

      <div style={{ flex: 1 }} />

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <button className="ck-btn" onClick={onNext} disabled={value.replace(/\D/g,'').length < 9}>
          Send code
        </button>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          color: 'var(--soft)', fontSize: 12, padding: '4px 0',
        }}>
          <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
          <span>or</span>
          <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
        </div>
        <button className="ck-btn tonal" style={{ display: 'flex', justifyContent: 'center', gap: 10, alignItems: 'center' }}>
          <svg width="18" height="18" viewBox="0 0 24 24"><path fill="#4285F4" d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4c-.2 1.3-.9 2.4-2 3.1v2.6h3.3c1.9-1.8 3-4.4 3-7.5z"/><path fill="#34A853" d="M12 22c2.7 0 5-.9 6.7-2.4l-3.3-2.6c-.9.6-2 1-3.4 1-2.6 0-4.8-1.8-5.6-4.1H2.9v2.6C4.6 19.9 8 22 12 22z"/><path fill="#FBBC05" d="M6.4 13.9c-.2-.6-.3-1.3-.3-1.9s.1-1.3.3-1.9V7.5H2.9C2.3 8.9 2 10.4 2 12s.3 3.1.9 4.5l3.5-2.6z"/><path fill="#EA4335" d="M12 6c1.5 0 2.8.5 3.8 1.5l2.9-2.9C16.9 2.9 14.7 2 12 2 8 2 4.6 4.1 2.9 7.5l3.5 2.6C7.2 7.8 9.4 6 12 6z"/></svg>
          Continue with Google
        </button>
      </div>

      <div style={{ textAlign: 'center', fontSize: 11, color: 'var(--soft)', lineHeight: 1.5 }}>
        By continuing you agree to our Terms<br/>& Privacy Policy.
      </div>
    </div>
  );
}

// ── Step 2: OTP ───────────────────────────────────────────────
function OtpStep({ phone, otp, setOtp, onNext, onBack }) {
  const inputs = React.useRef([]);
  const [resendIn, setResendIn] = React.useState(28);
  React.useEffect(() => {
    const t = setInterval(() => setResendIn(s => Math.max(0, s - 1)), 1000);
    return () => clearInterval(t);
  }, []);

  const handle = (i, v) => {
    const digit = v.replace(/\D/g, '').slice(-1);
    const next = otp.split('');
    next[i] = digit || '';
    const merged = next.join('').padEnd(6, '');
    setOtp(merged.slice(0, 6));
    if (digit && i < 5) inputs.current[i+1]?.focus();
  };

  const filled = otp.replace(/\s/g, '').length === 6;

  return (
    <div style={{ padding: '32px 24px 24px', display: 'flex', flexDirection: 'column', gap: 28, flex: 1 }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <h1 className="ck-display" style={{ fontSize: 32, fontWeight: 700, margin: 0, lineHeight: 1.05 }}>
          Code from<br/>the SMS
        </h1>
        <p style={{ margin: 0, color: 'var(--muted)', fontSize: 15 }}>
          Sent to <span style={{ color: 'var(--ink)', fontWeight: 600 }}>+92 {phone || '300 123 4567'}</span>
          {' · '}
          <button onClick={onBack} style={{
            background: 'none', border: 'none', padding: 0,
            color: 'var(--red)', fontWeight: 600, fontSize: 15, cursor: 'pointer',
          }}>change</button>
        </p>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        {Array.from({ length: 6 }).map((_, i) => (
          <input
            key={i}
            ref={el => inputs.current[i] = el}
            inputMode="numeric"
            maxLength={1}
            value={otp[i] || ''}
            onChange={e => handle(i, e.target.value)}
            onKeyDown={e => {
              if (e.key === 'Backspace' && !otp[i] && i > 0) inputs.current[i-1]?.focus();
            }}
            className="ck-input ck-display"
            style={{
              flex: 1, height: 60, textAlign: 'center', fontSize: 28,
              fontWeight: 700, padding: 0, fontVariantNumeric: 'tabular-nums',
            }}
          />
        ))}
      </div>

      <div style={{ color: 'var(--muted)', fontSize: 13 }}>
        {resendIn > 0
          ? <>Resend in <span className="ck-tnum" style={{ fontWeight: 600 }}>0:{String(resendIn).padStart(2, '0')}</span></>
          : <span style={{ color: 'var(--red)', fontWeight: 600 }}>Resend code</span>}
      </div>

      <div style={{ flex: 1 }} />
      <button className="ck-btn" onClick={onNext} disabled={!filled}>Verify</button>
    </div>
  );
}

// ── Step 3: Profile (display name + username + location) ──────
function ProfileStep({ profile, setProfile, onNext }) {
  const set = (k, v) => setProfile(p => ({ ...p, [k]: v }));
  const ok = profile.name && profile.username.length >= 3 && profile.city;

  // Suggested usernames as user types
  const suggestion = profile.name
    ? profile.name.toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 14) + (profile.name.length > 4 ? '92' : '')
    : '';

  return (
    <div style={{ padding: '24px 24px 20px', display: 'flex', flexDirection: 'column', gap: 20, flex: 1 }}>
      <div>
        <h1 className="ck-display" style={{ fontSize: 28, fontWeight: 700, margin: 0, lineHeight: 1.1 }}>
          Set up your profile
        </h1>
        <p style={{ margin: '4px 0 0', color: 'var(--muted)', fontSize: 14 }}>
          So teams can find you.
        </p>
      </div>

      <div>
        <label className="ck-label">Display name</label>
        <input
          className="ck-input"
          placeholder="Ahmed Khan"
          value={profile.name}
          onChange={e => set('name', e.target.value)}
        />
      </div>

      <div>
        <label className="ck-label">Username</label>
        <div style={{ position: 'relative' }}>
          <span style={{
            position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)',
            color: 'var(--soft)', fontSize: 17, fontWeight: 500,
          }}>@</span>
          <input
            className="ck-input"
            placeholder={suggestion || 'ahmed_khan'}
            value={profile.username}
            onChange={e => set('username', e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, '').slice(0, 20))}
            style={{ paddingLeft: 32 }}
          />
        </div>
        {profile.username.length >= 3 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, fontSize: 12, color: 'var(--green)' }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="7" cy="7" r="6.5" fill="oklch(0.56 0.13 148)"/><path d="M4 7.2l2 2 4-4.4" stroke="white" strokeWidth="1.6" fill="none" strokeLinecap="round"/></svg>
            <span style={{ fontWeight: 600 }}>@{profile.username}</span> available
          </div>
        )}
      </div>

      <div>
        <label className="ck-label">City / village</label>
        <div style={{ position: 'relative' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" style={{
            position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)',
          }}>
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" fill="oklch(0.62 0.19 28)"/>
          </svg>
          <input
            className="ck-input"
            placeholder="Lahore, Punjab"
            value={profile.city}
            onChange={e => set('city', e.target.value)}
            style={{ paddingLeft: 40 }}
          />
        </div>
      </div>

      <div style={{ flex: 1 }} />
      <button className="ck-btn" onClick={onNext} disabled={!ok}>Continue</button>
    </div>
  );
}

// ── Step 4: Player profile (opt-in) ───────────────────────────
function PlayerStep({ player, setPlayer, onNext, onSkip }) {
  const set = (k, v) => setPlayer(p => ({ ...p, [k]: v }));

  const Pill = ({ active, onClick, children }) => (
    <button onClick={onClick} style={{
      padding: '10px 14px', borderRadius: 999,
      border: active ? '1.5px solid var(--ink)' : '1.5px solid var(--line)',
      background: active ? 'var(--ink)' : 'var(--surface)',
      color: active ? 'var(--paper)' : 'var(--ink)',
      fontFamily: 'Inter', fontWeight: 600, fontSize: 14,
      cursor: 'pointer', transition: 'all .12s',
    }}>{children}</button>
  );

  return (
    <div style={{ padding: '24px 24px 20px', display: 'flex', flexDirection: 'column', gap: 22, flex: 1 }}>
      <div>
        <div className="ck-chip" style={{ marginBottom: 10, background: 'var(--cream)', borderColor: 'transparent', color: 'var(--ink-2)' }}>Optional</div>
        <h1 className="ck-display" style={{ fontSize: 28, fontWeight: 700, margin: 0, lineHeight: 1.1 }}>
          Are you a cricket player?
        </h1>
        <p style={{ margin: '4px 0 0', color: 'var(--muted)', fontSize: 14, lineHeight: 1.4 }}>
          Add your style so teams can scout you. You can always edit later.
        </p>
      </div>

      <div>
        <label className="ck-label">Role</label>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {['Batter', 'Bowler', 'All-rounder', 'Keeper'].map(r =>
            <Pill key={r} active={player.role === r} onClick={() => set('role', r)}>{r}</Pill>
          )}
        </div>
      </div>

      <div>
        <label className="ck-label">Batting</label>
        <div style={{ display: 'flex', gap: 8 }}>
          {['Right-hand', 'Left-hand'].map(r =>
            <Pill key={r} active={player.bat === r} onClick={() => set('bat', r)}>{r}</Pill>
          )}
        </div>
      </div>

      <div>
        <label className="ck-label">Bowling</label>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {['Right-arm fast', 'Right-arm spin', 'Left-arm fast', 'Left-arm spin', "Doesn't bowl"].map(r =>
            <Pill key={r} active={player.bowl === r} onClick={() => set('bowl', r)}>{r}</Pill>
          )}
        </div>
      </div>

      <div>
        <label className="ck-label">Preferred ball</label>
        <div style={{ display: 'flex', gap: 8 }}>
          {['Leather', 'Tape', 'Tennis'].map(r =>
            <Pill key={r} active={player.ball === r} onClick={() => set('ball', r)}>{r}</Pill>
          )}
        </div>
      </div>

      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button className="ck-btn" onClick={onNext}>Save profile</button>
        <button className="ck-btn ghost" onClick={onSkip} style={{ color: 'var(--muted)' }}>Skip — I just watch</button>
      </div>
    </div>
  );
}

// ── Step 5: Welcome (tiny celebration + invite found) ─────────
function WelcomeStep({ profile, onDone }) {
  return (
    <div style={{ padding: '40px 24px 24px', display: 'flex', flexDirection: 'column', gap: 24, flex: 1, alignItems: 'stretch' }}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, padding: '24px 0' }}>
        <div style={{
          width: 72, height: 72, borderRadius: 999,
          background: 'var(--green-soft)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="34" height="34" viewBox="0 0 24 24"><circle cx="12" cy="12" r="11" fill="oklch(0.56 0.13 148)"/><path d="M7 12.5l3.2 3.2L17 8.5" stroke="white" strokeWidth="2.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </div>
        <h1 className="ck-display" style={{ fontSize: 30, fontWeight: 700, margin: 0, textAlign: 'center', lineHeight: 1.05 }}>
          You’re in,<br/>{profile.name?.split(' ')[0] || 'player'}.
        </h1>
      </div>

      {/* Invite card — found teams */}
      <div style={{
        background: 'var(--paper-2)', borderRadius: 18, padding: 16,
        border: '1px solid var(--hairline)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
          <span className="ck-chip" style={{ background: 'var(--cream)', borderColor: 'transparent' }}>2 invites</span>
          <span style={{ fontSize: 12, color: 'var(--muted)' }}>found via your number</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10,
              background: 'oklch(0.36 0.10 148)', color: 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 14, letterSpacing: '-0.02em',
            }}>LL</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 15 }}>Lahore Lions</div>
              <div style={{ fontSize: 12, color: 'var(--muted)' }}>Club · Bilal Ahmed added you</div>
            </div>
            <button style={{
              background: 'var(--ink)', color: 'var(--paper)',
              border: 'none', borderRadius: 10, padding: '8px 14px',
              fontWeight: 600, fontSize: 13, cursor: 'pointer',
            }}>Accept</button>
          </div>
          <div style={{ height: 1, background: 'var(--hairline)' }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10,
              background: 'oklch(0.42 0.16 28)', color: 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 14, letterSpacing: '-0.02em',
            }}>MT</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 15 }}>Model Town XI</div>
              <div style={{ fontSize: 12, color: 'var(--muted)' }}>Village · 14 players</div>
            </div>
            <button style={{
              background: 'transparent', color: 'var(--ink)',
              border: '1.5px solid var(--line)', borderRadius: 10, padding: '7px 13px',
              fontWeight: 600, fontSize: 13, cursor: 'pointer',
            }}>View</button>
          </div>
        </div>
      </div>

      <div style={{ flex: 1 }} />
      <button className="ck-btn" onClick={onDone}>Open feed</button>
    </div>
  );
}

// ── Onboarding shell ──────────────────────────────────────────
function CkOnboarding() {
  const [step, setStep] = React.useState(0);
  const [phone, setPhone] = React.useState('300 412 8821');
  const [otp, setOtp] = React.useState('428');
  const [profile, setProfile] = React.useState({
    name: 'Ahmed Khan', username: 'ahmed_k92', city: 'Lahore, Punjab',
  });
  const [player, setPlayer] = React.useState({
    role: 'All-rounder', bat: 'Right-hand', bowl: 'Right-arm spin', ball: 'Tape',
  });

  // Top bar
  const Top = () => (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '12px 20px 0',
    }}>
      <button
        onClick={() => setStep(s => Math.max(0, s - 1))}
        style={{
          background: 'transparent', border: 'none', padding: 6,
          opacity: step === 0 ? 0 : 1, cursor: 'pointer',
        }}
        disabled={step === 0}
      >
        <svg width="22" height="22" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" stroke="oklch(0.18 0.02 80)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </button>
      <CkLogo size={22} />
      <div style={{ width: 22 }} />
    </div>
  );

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ height: 44 }} /> {/* status bar offset */}
      <Top />
      <div style={{ padding: '14px 24px 0' }}>
        <StepDots index={Math.min(step, 4)} total={5} />
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        {step === 0 && <PhoneStep value={phone} setValue={setPhone} onNext={() => setStep(1)} />}
        {step === 1 && <OtpStep phone={phone} otp={otp} setOtp={setOtp} onNext={() => setStep(2)} onBack={() => setStep(0)} />}
        {step === 2 && <ProfileStep profile={profile} setProfile={setProfile} onNext={() => setStep(3)} />}
        {step === 3 && <PlayerStep player={player} setPlayer={setPlayer} onNext={() => setStep(4)} onSkip={() => setStep(4)} />}
        {step === 4 && <WelcomeStep profile={profile} onDone={() => setStep(0)} />}
      </div>
    </div>
  );
}

window.CkOnboarding = CkOnboarding;
window.CkLogo = CkLogo;

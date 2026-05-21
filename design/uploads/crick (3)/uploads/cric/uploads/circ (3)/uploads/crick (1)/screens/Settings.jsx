// Settings.jsx — Account / privacy / notifications / blocked users (Feature 8)

function Settings() {
  const [pushMatch, setPushMatch] = React.useState(true);
  const [pushMilestone, setPushMilestone] = React.useState(true);
  const [pushFollows, setPushFollows] = React.useState(true);
  const [pushMentions, setPushMentions] = React.useState(true);
  const [pushTournament, setPushTournament] = React.useState(true);
  const [pushRecruit, setPushRecruit] = React.useState(false);
  const [emailDigest, setEmailDigest] = React.useState('Weekly');
  const [profileVis, setProfileVis] = React.useState('Public');
  const [statsVis, setStatsVis] = React.useState('Public');
  const [phoneVis, setPhoneVis] = React.useState('Team-mates');
  const [allowClaims, setAllowClaims] = React.useState(true);
  const [allowDM, setAllowDM] = React.useState('Followers');
  const [showSignOut, setShowSignOut] = React.useState(false);
  const [showVisSheet, setShowVisSheet] = React.useState(null);

  const blocked = [
    { name: 'Junaid Q.', sub: '@jq · blocked 14 Apr' },
    { name: 'Anonymous', sub: 'phone +92 *** **27 · blocked 2 Apr' },
  ];

  const Toggle = ({ on, onClick }) => (
    <button onClick={onClick} style={{
      width: 42, height: 26, borderRadius: 999,
      background: on ? 'var(--ink)' : 'oklch(0.86 0.01 80)',
      border: 'none', position: 'relative', cursor: 'pointer', flexShrink: 0,
      transition: 'background .15s',
    }}>
      <div style={{
        position: 'absolute', top: 3, left: on ? 19 : 3,
        width: 20, height: 20, borderRadius: 999, background: 'white',
        transition: 'left .15s',
        boxShadow: '0 1px 2px rgba(0,0,0,0.15)',
      }} />
    </button>
  );

  const Row = ({ label, sub, children, onClick }) => (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '13px 20px', borderTop: '1px solid var(--hairline)',
      cursor: onClick ? 'pointer' : 'default',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 500 }}>{label}</div>
        {sub && <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{sub}</div>}
      </div>
      {children}
    </div>
  );

  const ChevValue = ({ v }) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--muted)' }}>
      <span style={{ fontSize: 13, fontFamily: 'inherit' }}>{v}</span>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m9 18 6-6-6-6"/></svg>
    </div>
  );

  const visOptions = {
    profileVis: ['Public', 'Followers only', 'Private'],
    statsVis: ['Public', 'Followers only', 'Team-mates', 'Private'],
    phoneVis: ['Public', 'Team-mates', 'Private'],
    emailDigest: ['Daily', 'Weekly', 'Off'],
    allowDM: ['Anyone', 'Followers', 'Team-mates only', 'No-one'],
  };
  const visLabels = {
    profileVis: 'Profile visibility',
    statsVis: 'Stats visibility',
    phoneVis: 'Phone number',
    emailDigest: 'Email digest',
    allowDM: 'Who can DM you',
  };
  const visSetters = {
    profileVis: setProfileVis,
    statsVis: setStatsVis,
    phoneVis: setPhoneVis,
    emailDigest: setEmailDigest,
    allowDM: setAllowDM,
  };
  const visValues = { profileVis, statsVis, phoneVis, emailDigest, allowDM };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
      <div style={{ padding: '14px 20px 16px', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
          <button onClick={() => window.__ckNav && window.__ckNav.pop()} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em' }}>Settings</div>
        </div>

        {/* Account card */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 12, borderRadius: 12, background: 'var(--paper-2)' }}>
          <div className="ck-avatar" style={{ width: 48, height: 48, fontSize: 16 }}>BK</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700 }}>Bilal Khan</div>
            <div style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>@bilalk · +92 *** **34</div>
          </div>
          <button style={{ padding: '6px 11px', borderRadius: 8, background: 'var(--paper)', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Edit</button>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* ── ACCOUNT ── */}
        <div style={{ padding: '16px 20px 6px' }}>
          <div className="ck-section-h">Account</div>
        </div>
        <Row label="Phone number" sub="+92 *** **34 · verified" onClick={() => {}}>
          <ChevValue v="Change" />
        </Row>
        <Row label="Player profile" sub="Linked to Bilal Khan · Lahore Lions">
          <ChevValue v="Edit" />
        </Row>
        <Row label="Teams I play for" sub="Lahore Lions · Mohalla Cantt">
          <ChevValue v="Manage" />
        </Row>

        {/* ── PRIVACY ── */}
        <div style={{ padding: '20px 20px 6px' }}>
          <div className="ck-section-h">Privacy</div>
        </div>
        <Row label={visLabels.profileVis} sub="Who can see your profile" onClick={() => setShowVisSheet('profileVis')}>
          <ChevValue v={profileVis} />
        </Row>
        <Row label={visLabels.statsVis} sub="Career stats and recent form" onClick={() => setShowVisSheet('statsVis')}>
          <ChevValue v={statsVis} />
        </Row>
        <Row label={visLabels.phoneVis} sub="Discoverable by phone number" onClick={() => setShowVisSheet('phoneVis')}>
          <ChevValue v={phoneVis} />
        </Row>
        <Row label={visLabels.allowDM} onClick={() => setShowVisSheet('allowDM')}>
          <ChevValue v={allowDM} />
        </Row>
        <Row label="Allow claim requests" sub="Let people search and claim records linked to you">
          <Toggle on={allowClaims} onClick={() => setAllowClaims(!allowClaims)} />
        </Row>

        {/* ── NOTIFICATIONS ── */}
        <div style={{ padding: '20px 20px 6px' }}>
          <div className="ck-section-h">Push notifications</div>
        </div>
        <Row label="Match starts" sub="Teams I follow go live">
          <Toggle on={pushMatch} onClick={() => setPushMatch(!pushMatch)} />
        </Row>
        <Row label="Milestones" sub="50s, 100s, 5-fers, hat-tricks, debuts">
          <Toggle on={pushMilestone} onClick={() => setPushMilestone(!pushMilestone)} />
        </Row>
        <Row label="New followers">
          <Toggle on={pushFollows} onClick={() => setPushFollows(!pushFollows)} />
        </Row>
        <Row label="Mentions & comments">
          <Toggle on={pushMentions} onClick={() => setPushMentions(!pushMentions)} />
        </Row>
        <Row label="Tournament updates" sub="Fixtures, brackets, your team's matches">
          <Toggle on={pushTournament} onClick={() => setPushTournament(!pushTournament)} />
        </Row>
        <Row label="Recruitment posts" sub="Teams looking for your role">
          <Toggle on={pushRecruit} onClick={() => setPushRecruit(!pushRecruit)} />
        </Row>
        <Row label={visLabels.emailDigest} sub="Summary of activity in your circle" onClick={() => setShowVisSheet('emailDigest')}>
          <ChevValue v={emailDigest} />
        </Row>

        {/* ── BLOCKED ── */}
        <div style={{ padding: '20px 20px 6px' }}>
          <div className="ck-section-h">Blocked</div>
        </div>
        {blocked.map((b, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 20px', borderTop: '1px solid var(--hairline)' }}>
            <div className="ck-avatar ck-placeholder" style={{ width: 32, height: 32 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{b.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono', marginTop: 2 }}>{b.sub}</div>
            </div>
            <button style={{ padding: '5px 10px', borderRadius: 8, background: 'transparent', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>Unblock</button>
          </div>
        ))}
        {blocked.length === 0 && (
          <div style={{ padding: '14px 20px', fontSize: 12, color: 'var(--muted)', borderTop: '1px solid var(--hairline)' }}>You haven't blocked anyone.</div>
        )}

        {/* ── DATA & SUPPORT ── */}
        <div style={{ padding: '20px 20px 6px' }}>
          <div className="ck-section-h">Data & support</div>
        </div>
        <Row label="Download your data" sub="All matches, stats, posts as CSV"><ChevValue v="" /></Row>
        <Row label="Help centre"><ChevValue v="" /></Row>
        <Row label="Send feedback"><ChevValue v="" /></Row>
        <Row label="Terms of service"><ChevValue v="" /></Row>
        <Row label="Privacy policy"><ChevValue v="" /></Row>

        {/* ── DANGER ── */}
        <div style={{ padding: '24px 20px 8px' }}>
          <button onClick={() => setShowSignOut(true)} style={{
            width: '100%', padding: '13px 0', borderRadius: 10,
            background: 'var(--paper-2)', color: 'var(--ink)', border: '1px solid var(--hairline)',
            fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer',
          }}>Sign out</button>
          <button style={{
            width: '100%', marginTop: 8, padding: '13px 0', borderRadius: 10,
            background: 'transparent', color: 'var(--red)', border: 'none',
            fontFamily: 'inherit', fontSize: 13, fontWeight: 600, cursor: 'pointer',
          }}>Delete account</button>
        </div>

        <div style={{ padding: '12px 20px 24px', textAlign: 'center', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>
          CIRCK · v0.1.4 · BUILD 187
        </div>
      </div>

      {/* Visibility sheet */}
      {showVisSheet && (
        <div onClick={() => setShowVisSheet(null)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.45)', zIndex: 30, display: 'flex', alignItems: 'flex-end' }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--paper)', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: '18px 20px 24px' }}>
            <div style={{ width: 40, height: 4, background: 'var(--hairline)', borderRadius: 999, margin: '0 auto 14px' }} />
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginBottom: 14 }}>{visLabels[showVisSheet]}</div>
            {visOptions[showVisSheet].map((o, i) => (
              <button key={o} onClick={() => { visSetters[showVisSheet](o); setShowVisSheet(null); }} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                width: '100%', padding: '14px 0', border: 'none',
                borderBottom: i < visOptions[showVisSheet].length - 1 ? '1px solid var(--hairline)' : 'none',
                background: 'transparent', fontFamily: 'inherit', fontSize: 15, fontWeight: 500, color: 'var(--ink)', cursor: 'pointer', textAlign: 'left',
              }}>
                <span>{o}</span>
                {visValues[showVisSheet] === o && <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2.4"><path d="M20 6 9 17l-5-5"/></svg>}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Sign-out confirm */}
      {showSignOut && (
        <div onClick={() => setShowSignOut(false)} style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.5)', zIndex: 30, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', maxWidth: 300, background: 'var(--paper)', borderRadius: 16, padding: 20, textAlign: 'center' }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700 }}>Sign out?</div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 8, lineHeight: 1.4 }}>You'll need to verify your phone again next time.</div>
            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              <button onClick={() => setShowSignOut(false)} style={{ flex: 1, padding: '10px 0', borderRadius: 10, background: 'var(--paper-2)', color: 'var(--ink)', border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Cancel</button>
              <button onClick={() => setShowSignOut(false)} style={{ flex: 1, padding: '10px 0', borderRadius: 10, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Sign out</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

window.CkSettings = Settings;

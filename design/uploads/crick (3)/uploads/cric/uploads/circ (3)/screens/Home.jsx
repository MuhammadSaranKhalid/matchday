// Home.jsx — Home / Feed screen
// 4 states (Tweak): default · empty · live-pinned · composer
// All post types: text, photo, match-result, live-alert, tournament-update, milestone, recruitment
// Uses CkAppShell from AppShell.jsx (loaded earlier).

function CkHome({ state = 'default', onTab, onAvatar, onBell }) {
  const [filter, setFilter] = React.useState('All');
  const FILTERS = ['All', 'Teams', 'Tournaments', 'Players', 'Live'];

  return (
    <CkAppShell
      tab="Home"
      onTab={onTab}
      onAvatar={onAvatar}
      onBell={onBell}
      livePulse={state === 'live-pinned'}
    >
      {/* Filter pills */}
      <div style={{
        position: 'sticky', top: 0, zIndex: 5, background: 'var(--paper)',
        padding: '6px 16px 10px', borderBottom: '1px solid var(--hairline)',
      }}>
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto' }}>
          {FILTERS.map(f => (
            <button key={f} onClick={() => setFilter(f)} style={{
              flex: 'none', padding: '7px 13px', borderRadius: 999,
              border: filter === f ? '1px solid var(--ink)' : '1px solid var(--hairline)',
              background: filter === f ? 'var(--ink)' : 'var(--surface)',
              color: filter === f ? 'var(--paper)' : 'var(--ink-2)',
              fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', gap: 5,
            }}>
              {f === 'Live' && <span style={{ width: 5, height: 5, borderRadius: 999, background: filter === f ? 'white' : 'var(--red)' }}/>}
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Live strip — only in live-pinned */}
      {state === 'live-pinned' && <FeedLiveStrip />}

      {/* States */}
      {state === 'empty' ? <FeedEmpty /> : <FeedDefault state={state} />}

      {/* Composer overlay */}
      {state === 'composer' && <FeedComposer onClose={() => {}} />}
    </CkAppShell>
  );
}

// ─── Live now strip (live-pinned state) ────────────
function FeedLiveStrip() {
  const ROWS = [
    { id: 1, a: 'LL', b: 'MT', score: 'LL 132/4 · 14.3', sub: 'need 46 from 33', tag: 'Spring Cup QF1' },
    { id: 2, a: 'KS', b: 'IT', score: 'KS 88/2 · 9.0',   sub: 'IT batting next', tag: 'Spring Cup QF2' },
  ];
  return (
    <div style={{ background: 'var(--ink)', color: 'var(--paper)', padding: '12px 0' }}>
      <div style={{ padding: '0 16px 8px', display: 'flex', alignItems: 'center', gap: 6 }}>
        <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--red)' }}/>
        <span className="ck-mono" style={{ fontSize: 10, color: 'rgba(255,255,255,0.65)', letterSpacing: '0.10em' }}>LIVE NOW · {ROWS.length}</span>
        <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.65)', letterSpacing: '0.08em' }}>SEE ALL ›</span>
      </div>
      <div style={{ display: 'flex', gap: 10, padding: '0 16px', overflowX: 'auto' }}>
        {ROWS.map(r => (
          <div key={r.id} style={{
            flex: 'none', minWidth: 250, padding: '12px 14px',
            background: 'rgba(255,255,255,0.06)', borderRadius: 12,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
              <CkTBadge id={r.a} size={20} />
              <span style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11 }}>vs</span>
              <CkTBadge id={r.b} size={20} />
              <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 9, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.06em' }}>{r.tag.toUpperCase()}</span>
            </div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.01em' }}>{r.score}</div>
            <div style={{ fontSize: 11, color: 'oklch(0.85 0.13 80)', marginTop: 2 }}>{r.sub}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Default populated feed ────────────────────────
function FeedDefault({ state }) {
  return (
    <div>
      {state !== 'live-pinned' && <ComposerInlineCue />}
      <PostText />
      <PostMatchResult />
      <PostMilestone />
      <PostPhoto />
      <PostLiveAlert />
      <PostTournamentUpdate />
      <PostRecruitment />
      <SuggestedFollows />
      <PostText author="Lahore Lions" mark="LL" handle="@lahore.lions" when="6h" body="Practice tomorrow 6am at Gaddafi B. Bring whites. Net 3 booked." kind="team" />
      <div style={{ height: 14 }} />
    </div>
  );
}

// ─── Composer inline cue (top of feed) ─────────────
function ComposerInlineCue() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px 16px', borderBottom: '1px solid var(--hairline)' }}>
      <div className="ck-avatar" style={{ background: 'var(--ink)', color: 'var(--paper)', borderColor: 'transparent' }}>BA</div>
      <button style={{
        flex: 1, padding: '10px 14px', borderRadius: 999,
        border: '1px solid var(--hairline)', background: 'var(--surface)',
        textAlign: 'left', cursor: 'pointer', fontFamily: 'Inter', fontSize: 13, color: 'var(--muted)',
      }}>What's happening on the pitch?</button>
      <button aria-label="Add photo" style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', color: 'var(--ink-2)' }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/><path d="M21 16l-5-5-9 9"/></svg>
      </button>
    </div>
  );
}

// ─── POST CARDS ────────────────────────────────────
// Shared shell — author row, body slot, action row.

function PostShell({ mark, markBg, author, handle, when, kind, children, noActions, accent }) {
  return (
    <article style={{
      borderBottom: '1px solid var(--hairline)',
      padding: '14px 16px 12px',
      background: 'var(--paper)',
      ...(accent && { borderLeft: `3px solid ${accent}` }),
    }}>
      {/* Author row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
        {kind === 'team' || kind === 'tournament' ? (
          <CkTBadge id={mark} size={36} />
        ) : (
          <div className="ck-avatar" style={{ background: markBg || 'var(--cream)', color: 'var(--ink-2)', borderColor: 'transparent', fontFamily: 'Inter Tight', fontWeight: 700 }}>
            {mark}
          </div>
        )}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700, letterSpacing: '-0.01em' }}>{author}</span>
            {kind && <PostKindBadge kind={kind} />}
          </div>
          <div style={{ fontSize: 11, color: 'var(--muted)', fontFamily: 'JetBrains Mono', letterSpacing: '0.02em', marginTop: 1 }}>
            {handle} · {when}
          </div>
        </div>
        <button aria-label="More" style={{ background: 'transparent', border: 'none', padding: 4, cursor: 'pointer', color: 'var(--muted)' }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/></svg>
        </button>
      </div>

      {children}

      {!noActions && <PostActions />}
    </article>
  );
}

function PostKindBadge({ kind }) {
  const map = {
    auto:        { bg: 'var(--cream)', fg: 'var(--ink-2)', label: 'AUTO' },
    live:        { bg: 'var(--red)', fg: 'white', label: 'LIVE' },
    milestone:   { bg: 'var(--green-soft)', fg: 'oklch(0.36 0.10 148)', label: 'MILESTONE' },
    organizer:   { bg: 'var(--ink)', fg: 'var(--paper)', label: 'ORGANIZER' },
    recruit:     { bg: 'oklch(0.97 0.04 90)', fg: 'oklch(0.45 0.12 80)', label: 'LFP' },
    team:        null, tournament: null,
  };
  const m = map[kind];
  if (!m) return null;
  return (
    <span style={{
      padding: '1px 6px', borderRadius: 4, background: m.bg, color: m.fg,
      fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.08em',
    }}>{m.label}</span>
  );
}

function PostActions({ liked }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 18, marginTop: 12, color: 'var(--muted)', fontSize: 12, fontFamily: 'JetBrains Mono', letterSpacing: '0.04em' }}>
      <button style={iconBtn}><HeartIcon/> 12</button>
      <button style={iconBtn}><ChatIcon/> 3</button>
      <button style={iconBtn}><RepostIcon/></button>
      <button style={{ ...iconBtn, marginLeft: 'auto' }}><BookmarkIcon/></button>
    </div>
  );
}

const iconBtn = {
  display: 'inline-flex', alignItems: 'center', gap: 5,
  background: 'transparent', border: 'none', cursor: 'pointer',
  color: 'inherit', font: 'inherit', padding: 0,
};

function HeartIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 1 0-7.78 7.78L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78z"/></svg>; }
function ChatIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M21 12a8 8 0 0 1-12.5 6.6L3 20l1.4-5.5A8 8 0 1 1 21 12z"/></svg>; }
function RepostIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M17 1l4 4-4 4M3 11V9a4 4 0 0 1 4-4h14M7 23l-4-4 4-4M21 13v2a4 4 0 0 1-4 4H3"/></svg>; }
function BookmarkIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>; }

// ─── Concrete post-type cards ──────────────────────

function PostText({ author='Faraz Khan', mark='FK', handle='@faraz.k', when='12m', body, kind } = {}) {
  return (
    <PostShell author={author} mark={mark} handle={handle} when={when} kind={kind}>
      <p style={{ margin: 0, fontFamily: 'Inter', fontSize: 14, lineHeight: 1.45, color: 'var(--ink)' }}>
        {body || 'Got a 5-fer in the friendly today. The wrist ball is coming back. Ready for QF1.'}
      </p>
    </PostShell>
  );
}

function PostMatchResult() {
  return (
    <PostShell author="Spring Cup '26" mark="SC" handle="@springcup26" when="32m" kind="auto" markBg="var(--cream)">
      <div style={{
        marginTop: 4, padding: 14, borderRadius: 14,
        background: 'var(--paper-2)', border: '1px solid var(--hairline)',
      }}>
        <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.08em', marginBottom: 8 }}>
          QUARTER-FINAL · APR 28
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <CkTBadge id="KS" size={36} />
            <div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600 }}>Karachi Stars</div>
              <div className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700, lineHeight: 1, marginTop: 2 }}>176/8</div>
            </div>
          </div>
          <div style={{ width: 24, height: 24, borderRadius: 999, background: 'var(--green)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontSize: 11, fontWeight: 700 }}>W</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'flex-end' }}>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600 }}>Multan Mavericks</div>
              <div className="ck-display ck-tnum" style={{ fontSize: 22, fontWeight: 700, lineHeight: 1, marginTop: 2, color: 'var(--muted)' }}>142</div>
            </div>
            <CkTBadge id="ML" size={36} />
          </div>
        </div>
        <div style={{ marginTop: 10, paddingTop: 10, borderTop: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 10, fontSize: 11, color: 'var(--ink-2)' }}>
          <strong style={{ color: 'var(--ink)', fontFamily: 'Inter Tight', fontSize: 13 }}>KS won by 34 runs</strong>
          <span className="ck-mono" style={{ color: 'var(--muted)' }}>POM Salman Raza · 67(42)</span>
        </div>
      </div>
    </PostShell>
  );
}

function PostMilestone() {
  return (
    <PostShell author="Bilal Ahmed" mark="BA" handle="@bilal" when="1h" kind="milestone" markBg="var(--green-soft)" accent="var(--green)">
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 4 }}>
        <div style={{
          width: 64, height: 64, borderRadius: 16, flexShrink: 0,
          background: 'var(--green)', color: 'white',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 26, letterSpacing: '-0.03em',
        }}>50</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 700 }}>First half-century of the season</div>
          <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 2, lineHeight: 1.4 }}>67(42) · 8×4, 2×6 · vs Multan Mavericks</div>
          <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', marginTop: 4, letterSpacing: '0.06em' }}>SR 159.5 · 12TH FIFTY OVERALL</div>
        </div>
      </div>
    </PostShell>
  );
}

function PostPhoto() {
  return (
    <PostShell author="Adeel Sheikh" mark="AS" handle="@adeelk" when="2h">
      <p style={{ margin: '0 0 10px', fontFamily: 'Inter', fontSize: 14, lineHeight: 1.45 }}>
        Kit's ready. See you all 6am sharp.
      </p>
      <div style={{
        height: 220, borderRadius: 14, overflow: 'hidden', position: 'relative',
        background: 'linear-gradient(135deg, oklch(0.36 0.10 148), oklch(0.32 0.07 148))',
      }}>
        {/* placeholder pitch lines */}
        <svg width="100%" height="100%" viewBox="0 0 200 130" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0, opacity: 0.18 }}>
          <ellipse cx="100" cy="65" rx="95" ry="55" stroke="white" strokeWidth="0.4" fill="none"/>
          <ellipse cx="100" cy="65" rx="55" ry="32" stroke="white" strokeWidth="0.4" fill="none"/>
          <rect x="92" y="35" width="16" height="60" stroke="white" strokeWidth="0.4" fill="none"/>
          <line x1="100" y1="20" x2="100" y2="110" stroke="white" strokeWidth="0.4"/>
        </svg>
        <div style={{ position: 'absolute', left: 14, bottom: 10, fontFamily: 'JetBrains Mono', fontSize: 10, color: 'rgba(255,255,255,0.7)', letterSpacing: '0.08em' }}>
          GADDAFI B · 5:42 AM
        </div>
      </div>
    </PostShell>
  );
}

function PostLiveAlert() {
  return (
    <PostShell author="Spring Cup '26" mark="SC" handle="@springcup26" when="3h" kind="live" markBg="var(--red-soft)" accent="var(--red)">
      <div style={{
        marginTop: 4, padding: 14, borderRadius: 14, color: 'white',
        background: 'linear-gradient(135deg, oklch(0.62 0.19 28), oklch(0.55 0.18 28))',
        position: 'relative', overflow: 'hidden',
      }}>
        <div className="ck-mono" style={{ fontSize: 10, opacity: 0.8, letterSpacing: '0.08em', marginBottom: 6 }}>
          STARTING NOW · QF1 · GADDAFI B
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, lineHeight: 1.2 }}>
          Lahore Lions vs Model Town XI
        </div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
          <CkTBadge id="LL" size={26} />
          <CkTBadge id="MT" size={26} />
          <button style={{
            marginLeft: 'auto', padding: '8px 14px', borderRadius: 10,
            background: 'white', color: 'var(--red)',
            fontFamily: 'Inter', fontSize: 12, fontWeight: 700, border: 'none', cursor: 'pointer',
          }}>WATCH LIVE</button>
        </div>
      </div>
    </PostShell>
  );
}

function PostTournamentUpdate() {
  return (
    <PostShell author="Spring Cup '26" mark="SC" handle="@springcup26" when="5h" kind="organizer" markBg="var(--ink)">
      <p style={{ margin: '0 0 10px', fontFamily: 'Inter', fontSize: 14, lineHeight: 1.45 }}>
        Final venue is locked: <strong>Gaddafi B, May 4, 19:30</strong>. Captains' meeting May 3 at 5pm.
      </p>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        {['LL','KS','MT','IT','GG','PR','FX','ML'].map(id => <CkTBadge key={id} id={id} size={22} />)}
      </div>
    </PostShell>
  );
}

function PostRecruitment() {
  return (
    <PostShell author="Faisalabad XI" mark="FX" handle="@faisalabadxi" when="1d" kind="recruit">
      <p style={{ margin: 0, fontFamily: 'Inter', fontSize: 14, lineHeight: 1.45 }}>
        Looking for a left-arm spinner for the Spring Cup. Practice Sundays. DM if interested.
      </p>
      <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
        {['Spinner', 'LHB welcome', 'Sundays', 'Faisalabad'].map(t => (
          <span key={t} style={{
            padding: '4px 8px', borderRadius: 999, background: 'oklch(0.97 0.04 90)',
            color: 'oklch(0.45 0.12 80)', fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: 600, letterSpacing: '0.04em',
          }}>{t}</span>
        ))}
      </div>
    </PostShell>
  );
}

function SuggestedFollows() {
  const SUGS = [
    { id: 'GG', name: 'Gujranwala Giants', sub: 'Club · Gujranwala', kind: 'team' },
    { id: 'BR', name: 'Bahria Rangers',    sub: 'Club · Karachi',    kind: 'team' },
    { id: 'AK', name: 'Asad Khan',         sub: 'All-rounder · Lahore', kind: 'player' },
  ];
  return (
    <div style={{ borderBottom: '1px solid var(--hairline)', padding: '14px 0' }}>
      <div className="ck-section-h" style={{ padding: '0 16px 8px' }}>Suggested for you</div>
      <div style={{ display: 'flex', gap: 10, padding: '0 16px', overflowX: 'auto' }}>
        {SUGS.map(s => (
          <div key={s.id} style={{
            flex: 'none', width: 140, padding: 12,
            border: '1px solid var(--hairline)', borderRadius: 14, background: 'var(--surface)',
            textAlign: 'center',
          }}>
            {s.kind === 'team' ? (
              <CkTBadge id={s.id} size={48} />
            ) : (
              <div className="ck-avatar" style={{ width: 48, height: 48, fontSize: 17, margin: '0 auto' }}>{s.id}</div>
            )}
            <div style={{ fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 600, marginTop: 8, lineHeight: 1.2 }}>{s.name}</div>
            <div style={{ fontSize: 10.5, color: 'var(--muted)', marginTop: 2 }}>{s.sub}</div>
            <button style={{
              marginTop: 10, width: '100%', padding: '7px 0', borderRadius: 8,
              background: 'var(--ink)', color: 'var(--paper)', border: 'none',
              fontFamily: 'Inter', fontSize: 11, fontWeight: 600, cursor: 'pointer',
            }}>Follow</button>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── EMPTY STATE ───────────────────────────────────
function FeedEmpty() {
  return (
    <div style={{ padding: '24px 16px 0' }}>
      <div style={{
        padding: 22, borderRadius: 16, background: 'var(--paper-2)', border: '1px solid var(--hairline)',
        marginBottom: 18, position: 'relative', overflow: 'hidden',
      }}>
        <svg width="180" height="120" viewBox="0 0 200 130" style={{ position: 'absolute', right: -30, top: -10, opacity: 0.06 }}>
          <ellipse cx="100" cy="65" rx="95" ry="55" stroke="var(--ink)" strokeWidth="0.4" fill="none"/>
          <ellipse cx="100" cy="65" rx="55" ry="32" stroke="var(--ink)" strokeWidth="0.4" fill="none"/>
        </svg>
        <div className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em', marginBottom: 6 }}>WELCOME TO CIRCK</div>
        <h2 className="ck-display" style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.025em', margin: 0, lineHeight: 1.1 }}>
          Your feed is quiet.<br/>Let's fix that.
        </h2>
        <p style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 8, lineHeight: 1.45 }}>
          Follow teams, tournaments and players you care about. Their posts and match updates will land here.
        </p>
      </div>

      {/* Suggested teams nearby */}
      <div className="ck-section-h" style={{ marginBottom: 8 }}>Teams near you · Lahore</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, overflow: 'hidden', marginBottom: 18 }}>
        {['LL','MT','IT','GG'].map((id, i) => (
          <div key={id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 'none' }}>
            <CkTBadge id={id} size={36} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600 }}>{TEAMS[id].name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>Club · 18 members</div>
            </div>
            <button style={{ padding: '7px 14px', borderRadius: 9, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Follow</button>
          </div>
        ))}
      </div>

      <div className="ck-section-h" style={{ marginBottom: 8 }}>Live tournaments in Lahore</div>
      <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 14, padding: 14, marginBottom: 18 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ width: 38, height: 38, borderRadius: 10, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 800, fontSize: 14 }}>SC</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 700 }}>Spring Cup '26</div>
            <div style={{ fontSize: 11, color: 'var(--muted)' }}>Knockout · 8 teams · QF in progress</div>
          </div>
          <button style={{ padding: '7px 14px', borderRadius: 9, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Follow</button>
        </div>
      </div>

      <div style={{ padding: '4px 0 24px', textAlign: 'center' }}>
        <button style={{
          padding: '10px 18px', borderRadius: 10,
          background: 'transparent', color: 'var(--ink)',
          border: '1px solid var(--hairline)',
          fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>Browse Discover →</button>
      </div>
    </div>
  );
}

// ─── COMPOSER OVERLAY ──────────────────────────────
function FeedComposer({ onClose }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: 'rgba(40,30,15,0.35)', zIndex: 20,
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
    }}>
      <div style={{
        background: 'var(--paper)', borderTopLeftRadius: 24, borderTopRightRadius: 24,
        boxShadow: '0 -8px 30px rgba(40,30,15,0.18)',
        display: 'flex', flexDirection: 'column',
        maxHeight: '80%',
      }}>
        {/* Drag handle */}
        <div style={{ display: 'flex', justifyContent: 'center', padding: '8px 0 4px' }}>
          <span style={{ width: 36, height: 4, borderRadius: 999, background: 'var(--line)' }}/>
        </div>

        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 16px 10px' }}>
          <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'Inter', fontSize: 13, color: 'var(--muted)' }}>Cancel</button>
          <span className="ck-mono" style={{ fontSize: 10, color: 'var(--muted)', letterSpacing: '0.10em' }}>NEW POST</span>
          <button style={{ padding: '7px 14px', borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'Inter', fontSize: 12, fontWeight: 700, cursor: 'pointer' }}>POST</button>
        </div>

        {/* Author switcher */}
        <div style={{ padding: '0 16px 10px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div className="ck-avatar" style={{ background: 'var(--ink)', color: 'var(--paper)', borderColor: 'transparent' }}>BA</div>
          <button style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '6px 10px', borderRadius: 999, background: 'var(--paper-2)', border: '1px solid var(--hairline)',
            fontFamily: 'Inter', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: 'var(--ink)',
          }}>
            Posting as <strong style={{ fontWeight: 700 }}>Bilal Ahmed</strong>
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M6 9l6 6 6-6"/></svg>
          </button>
        </div>

        {/* Textarea */}
        <div style={{ padding: '0 16px 12px', flex: 1 }}>
          <div style={{
            minHeight: 110, padding: '4px 0',
            fontFamily: 'Inter', fontSize: 17, color: 'var(--ink)', lineHeight: 1.4,
          }}>
            Got a 5-fer in the friendly today.<span style={{
              display: 'inline-block', width: 1.5, height: '1.1em', verticalAlign: 'text-bottom',
              background: 'var(--ink)', marginLeft: 1, animation: 'ck-pulse 1s infinite',
            }}/>
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6 }}>
            <span style={{ padding: '4px 8px', borderRadius: 999, background: 'oklch(0.96 0.04 250)', color: 'oklch(0.40 0.18 250)', fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: 600 }}>@lahore.lions</span>
            <span style={{ padding: '4px 8px', borderRadius: 999, background: 'var(--paper-2)', color: 'var(--muted)', fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: 600 }}>#springcup26</span>
          </div>
        </div>

        {/* Toolbar */}
        <div style={{ borderTop: '1px solid var(--hairline)', padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 14 }}>
          <button style={iconBtn}><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.7"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/><path d="M21 16l-5-5-9 9"/></svg></button>
          <button style={iconBtn}><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.7"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg></button>
          <button style={iconBtn}><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.7"><path d="M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.4 8.4 0 0 1 3.8-.9h.5a8.5 8.5 0 0 1 8 8z"/></svg></button>
          <button style={iconBtn}><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink-2)" strokeWidth="1.7"><circle cx="12" cy="12" r="9"/><path d="M12 3v18M3 12h18"/></svg></button>
          <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.06em' }}>240/280</span>
        </div>
      </div>
    </div>
  );
}

window.CkHome = CkHome;

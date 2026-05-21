// PostFlow.jsx — Post Creation Flow audit + redesign deliverable.
// Purpose: a single, dense visual spec the user can scan to confirm the entire
// post-creation surface area: every entry point, every type, every state.

// ─────────────────────────────────────────────────────────────────────────
// 1. AUDIT BOARD — current state of compose entry points (problem statement)
// ─────────────────────────────────────────────────────────────────────────
function PFAudit() {
  const issues = [
    { tag: '×', label: 'Home feed FAB',           where: 'screens/Feed.jsx', verdict: 'Remove', why: 'Feed is for consuming. A red action button on a reading surface trains people to broadcast every scroll.' },
    { tag: '×', label: 'Home composer overlay',   where: 'screens/Home.jsx (state="composer")', verdict: 'Remove', why: 'Duplicate of Feed.jsx Composer. Single source of truth needed.' },
    { tag: '×', label: 'Inline cue at top of feed',where: 'Home.jsx · ComposerInlineCue', verdict: 'Remove', why: 'Twitter-style cue. Pulls authoring into the consumption surface.' },
    { tag: '~', label: 'Bottom-nav "+" Create tab',where: 'AppShell.jsx · NavItem isCreate', verdict: 'Repurpose', why: 'Today opens a generic creator. Becomes a router: New post / New team / New tournament — choose intent first.' },
    { tag: '✓', label: 'Profile · "Post" button',  where: 'screens/Profile.jsx · NEW',  verdict: 'Add (canonical)', why: 'Posting is an act of self-publishing. It belongs on the surface that represents the author — the profile.' },
    { tag: '✓', label: 'Team manage · "Post"',     where: 'screens/TeamManage.jsx',     verdict: 'Add', why: 'Captain/manager posts as the team. Must be reachable from the team console.' },
    { tag: '✓', label: 'Tournament manage · "Post"',where: 'screens/TournamentManage.jsx',verdict: 'Add', why: 'Organizer posts as the tournament — fixtures, rules, results, awards.' },
  ];
  return (
    <div style={{ width: 720, height: 874, padding: 40, background: 'var(--paper)', fontFamily: 'Inter, sans-serif', color: 'var(--ink)', display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>POST CREATION · AUDIT / 01</div>
        <h2 style={{ fontFamily: 'Inter Tight', fontSize: 38, fontWeight: 700, letterSpacing: '-0.03em', margin: '8px 0 0', lineHeight: 1.05 }}>
          Compose belongs on Profile,<br/>not on Home.
        </h2>
        <p style={{ fontSize: 14, color: 'var(--ink-2)', lineHeight: 1.5, marginTop: 12, maxWidth: 560 }}>
          Today the prototype has a compose surface in <strong>three</strong> places — Home FAB, Home composer overlay, and a generic Create tab in the bottom nav. The Home feed is a reading surface; tucking a publishing affordance onto it confuses the IA and produces low-quality posts. Move authoring to the surface that represents the author: <strong>Profile</strong> (personal posts), <strong>Team manage</strong> (team posts), <strong>Tournament manage</strong> (organizer posts).
        </p>
      </div>

      <div style={{ borderTop: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
        {issues.map((i, idx) => (
          <div key={idx} style={{ display: 'grid', gridTemplateColumns: '24px 180px 1fr 110px', gap: 14, padding: '12px 0', borderTop: idx === 0 ? 'none' : '1px dashed var(--hairline)', alignItems: 'baseline' }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, color: i.tag === '×' ? 'var(--red)' : i.tag === '✓' ? 'oklch(0.45 0.13 148)' : 'var(--amber)' }}>{i.tag}</div>
            <div>
              <div style={{ fontSize: 13, fontWeight: 700 }}>{i.label}</div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{i.where}</div>
            </div>
            <div style={{ fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.45 }}>{i.why}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--ink)', letterSpacing: '0.08em', textAlign: 'right' }}>{i.verdict.toUpperCase()}</div>
          </div>
        ))}
      </div>

      <div style={{ flex: 1 }} />

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
        <div style={{ padding: 14, background: 'var(--paper-2)', borderRadius: 10, border: '1px solid var(--hairline)' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.12em' }}>BEFORE</div>
          <div style={{ fontSize: 13, marginTop: 6, lineHeight: 1.45 }}>3 entry points · all on Home · author identity ambiguous · spec required user to "choose context: Personal / Team / Tournament" inside the composer.</div>
        </div>
        <div style={{ padding: 14, background: 'oklch(0.96 0.04 148)', borderRadius: 10, border: '1px solid oklch(0.86 0.05 148)' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'oklch(0.36 0.10 148)', letterSpacing: '0.12em' }}>AFTER</div>
          <div style={{ fontSize: 13, marginTop: 6, lineHeight: 1.45 }}>Author identity is determined by <em>where you launched compose from</em>. Profile → personal post. Team → team post. Tournament → tournament post. Composer never asks.</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 2. POST-TYPE MATRIX — every type, who can author, where it appears
// ─────────────────────────────────────────────────────────────────────────
function PFMatrix() {
  const rows = [
    { id: 'text',  glyph: 'T',  name: 'Text',                  author: 'User · Team · Tournament', creation: 'Manual', surfaces: 'Home feed · Profile · Team page · Tournament page', tone: 'oklch(0.45 0.05 240)' },
    { id: 'photo', glyph: '◰',  name: 'Photo / Album',         author: 'User · Team · Tournament', creation: 'Manual', surfaces: 'Home feed · Profile · Team · Tournament', tone: 'oklch(0.55 0.12 200)' },
    { id: 'match-ann',glyph: 'V', name: 'Match announcement',  author: 'Team · Tournament',         creation: 'Manual (linked match)', surfaces: 'Home feed · Team · Tournament · linked-match details', tone: 'var(--red)' },
    { id: 'recruit',glyph: '★', name: 'Recruitment',           author: 'Team',                      creation: 'Manual', surfaces: 'Home feed (filter: People/Teams) · Team page · Discover', tone: 'oklch(0.55 0.13 80)' },
    { id: 'tour-up',glyph: '◇', name: 'Tournament update',     author: 'Tournament',                creation: 'Manual', surfaces: 'Home feed · Tournament page · subscribed teams', tone: 'oklch(0.45 0.12 280)' },
    { id: 'milestone',glyph: '50',name: 'Milestone (50/100/5w/hat-trick)', author: 'System (auto)', creation: 'Auto on score event', surfaces: 'Home feed · Player profile · linked match', tone: 'var(--amber)' },
    { id: 'result', glyph: '=', name: 'Match result',          author: 'System (auto)',             creation: 'Auto on match end', surfaces: 'Home feed · both team pages · tournament · player profiles', tone: 'oklch(0.36 0.10 148)' },
    { id: 'award',  glyph: '♕', name: 'Award / Trophy',        author: 'System (auto)',             creation: 'Auto on tournament finalize', surfaces: 'Home feed · Tournament · winning team · player profiles', tone: 'oklch(0.55 0.16 50)' },
    { id: 'claim',  glyph: '✓', name: 'Profile claimed',       author: 'System (auto)',             creation: 'Auto on claim approved', surfaces: 'Player profile only', tone: 'var(--muted)' },
  ];

  return (
    <div style={{ width: 720, height: 874, padding: 40, background: 'var(--paper)', fontFamily: 'Inter, sans-serif', color: 'var(--ink)', display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>POST CREATION · MATRIX / 02</div>
        <h2 style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 700, letterSpacing: '-0.025em', margin: '8px 0 0', lineHeight: 1.05 }}>
          Nine post types. Five manual, four automatic.
        </h2>
        <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.45, marginTop: 8, maxWidth: 560 }}>
          Manual types appear in the type-picker. Auto types are emitted by the scoring / tournament engines and are read-only from the user's perspective — but they are still <em>posts</em>: likable, commentable, savable.
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 6 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '40px 1.2fr 1.4fr 1fr 2fr', gap: 10, padding: '6px 12px', background: 'var(--ink)', color: 'var(--paper)', borderRadius: 8, fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: '0.10em', fontWeight: 700 }}>
          <div></div><div>TYPE</div><div>AUTHOR</div><div>CREATION</div><div>APPEARS ON</div>
        </div>
        {rows.map(r => (
          <div key={r.id} style={{ display: 'grid', gridTemplateColumns: '40px 1.2fr 1.4fr 1fr 2fr', gap: 10, padding: '10px 12px', borderRadius: 8, alignItems: 'center', background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
            <div style={{ width: 28, height: 28, borderRadius: 6, background: r.tone, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: r.glyph.length > 1 ? 11 : 14 }}>{r.glyph}</div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>{r.name}</div>
            <div style={{ fontSize: 11, color: 'var(--ink-2)' }}>{r.author}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: r.creation.startsWith('Auto') ? 'var(--red)' : 'var(--muted)', letterSpacing: '0.05em', fontWeight: r.creation.startsWith('Auto') ? 700 : 500 }}>{r.creation.toUpperCase()}</div>
            <div style={{ fontSize: 10, color: 'var(--muted)', fontFamily: 'JetBrains Mono', lineHeight: 1.4 }}>{r.surfaces}</div>
          </div>
        ))}
      </div>

      <div style={{ flex: 1 }} />

      <div style={{ padding: 14, background: 'oklch(0.94 0.05 90)', borderRadius: 10, border: '1px solid oklch(0.86 0.05 90)', fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5 }}>
        <strong>Visibility</strong> for every manual type: <em>Public</em> (default · indexable, deep-linkable), <em>Followers</em> (gated to followers of the author entity), <em>Members</em> (team posts only · team roster only). No private DMs in MVP.
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 3. IA MAP — three entry points, all converge on one composer engine
// ─────────────────────────────────────────────────────────────────────────
function PFMap() {
  return (
    <div style={{ width: 720, height: 874, padding: 40, background: 'var(--paper)', fontFamily: 'Inter, sans-serif', color: 'var(--ink)', display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>POST CREATION · IA MAP / 03</div>
        <h2 style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 700, letterSpacing: '-0.025em', margin: '8px 0 0', lineHeight: 1.05 }}>
          Three doors. One composer.
        </h2>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 14, justifyContent: 'center' }}>
        {/* Three entry surfaces */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
          {[
            { tag: 'PERSONAL', name: 'Profile', sub: 'tap "Post" CTA on your profile header', color: 'var(--ink)' },
            { tag: 'TEAM',     name: 'Team manage', sub: 'team console → "Post as team"', color: 'var(--red)' },
            { tag: 'TOURNAMENT', name: 'Tournament manage', sub: 'organizer console → "Post update"', color: 'oklch(0.45 0.12 280)' },
          ].map((e, i) => (
            <div key={i} style={{ padding: 14, borderRadius: 10, border: '1.5px solid ' + e.color, background: 'var(--paper)' }}>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: e.color, letterSpacing: '0.12em' }}>{e.tag}</div>
              <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginTop: 4, letterSpacing: '-0.02em' }}>{e.name}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4, lineHeight: 1.4 }}>{e.sub}</div>
            </div>
          ))}
        </div>

        {/* Funnel arrows */}
        <div style={{ display: 'flex', justifyContent: 'space-around', color: 'var(--muted)' }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 5v14M5 14l7 7 7-7"/></svg>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 5v14M5 14l7 7 7-7"/></svg>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 5v14M5 14l7 7 7-7"/></svg>
        </div>

        {/* Author chip carries through */}
        <div style={{ padding: 16, background: 'var(--ink)', color: 'var(--paper)', borderRadius: 12 }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--amber)', letterSpacing: '0.12em' }}>STEP 1 · TYPE PICKER</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, marginTop: 4, letterSpacing: '-0.02em' }}>Choose what you're posting</div>
          <div style={{ fontSize: 12, color: 'oklch(0.78 0.01 80)', marginTop: 4, lineHeight: 1.45 }}>
            Author (you / Lahore Lions / Spring Cup '26) is locked in by entry point. Type list is filtered: a personal profile cannot post Tournament Updates.
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', color: 'var(--muted)' }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 5v14M5 14l7 7 7-7"/></svg>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 6 }}>
          {['Text','Photo','Match annc.','Recruitment','Tour update'].map((s, i) => (
            <div key={i} style={{ padding: '10px 8px', textAlign: 'center', borderRadius: 8, background: 'var(--paper-2)', border: '1px solid var(--hairline)', fontSize: 11, fontWeight: 700, fontFamily: 'Inter Tight' }}>{s}</div>
          ))}
        </div>
        <div style={{ textAlign: 'center', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em' }}>STEP 2 · PER-TYPE COMPOSER → STEP 3 · PREVIEW → STEP 4 · PUBLISH</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// PHONE FRAME (lightweight — we render many)
// ─────────────────────────────────────────────────────────────────────────
function PFPhone({ children, label, sub }) {
  return (
    <div style={{ width: 402, display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingBottom: 8 }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.12em' }}>{label}</div>
        {sub && <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2, lineHeight: 1.35 }}>{sub}</div>}
      </div>
      <div style={{ width: 402, height: 798, borderRadius: 36, background: 'var(--ink)', padding: 6, boxShadow: '0 12px 32px rgba(40,30,15,0.18)' }}>
        <div style={{ width: '100%', height: '100%', borderRadius: 30, overflow: 'hidden', background: 'var(--paper)', position: 'relative' }}>
          {children}
        </div>
      </div>
    </div>
  );
}

// Status bar + bottom nav helpers
function Status() {
  return (
    <div style={{ height: 38, padding: '12px 22px 0', display: 'flex', justifyContent: 'space-between', fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 700, color: 'var(--ink)' }}>
      <span>9:41</span><span>•••</span>
    </div>
  );
}
function MiniNav({ active = 'Profile' }) {
  const items = ['Home','Tour','+','Live','You'];
  return (
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 64, borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', alignItems: 'center', paddingBottom: 18 }}>
      {items.map((t, i) => (
        <div key={i} style={{ textAlign: 'center', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, letterSpacing: '0.06em', color: t === active ? 'var(--ink)' : 'var(--muted)' }}>
          {t === '+' ? <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto', fontSize: 18, fontWeight: 400 }}>+</div> : t.toUpperCase()}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 4. ENTRY POINT — Profile with NEW "Post" CTA (canonical entry)
// ─────────────────────────────────────────────────────────────────────────
function PFProfileEntry() {
  return (
    <PFPhone label="04 · ENTRY POINT — PROFILE" sub="Compose lives here. The 'Post' button is the primary CTA on your own profile header — replaces the 'Message' button when you're viewing yourself.">
      <Status/>
      <div style={{ padding: '8px 18px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em' }}>YOUR PROFILE</div>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/></svg>
      </div>

      <div style={{ padding: '16px 20px 8px', display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{ width: 64, height: 64, borderRadius: 999, background: 'var(--paper-2)', border: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 22 }}>BA</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1 }}>Bilal Ahmed</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>@bilala · Lahore Lions</div>
          <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 4 }}>Top-order bat · Right arm med</div>
        </div>
      </div>

      {/* Post CTA — primary, replaces Message when self */}
      <div style={{ display: 'flex', gap: 8, padding: '4px 20px 14px' }}>
        <button style={{ flex: 1, padding: '12px 0', borderRadius: 10, border: 'none', background: 'var(--red)', color: 'white', fontWeight: 700, fontSize: 14, fontFamily: 'inherit', boxShadow: '0 4px 12px rgba(190,60,40,0.28)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M12 5v14M5 12h14"/></svg>
          Post
        </button>
        <button style={{ flex: 1, padding: '12px 0', borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper)', color: 'var(--ink)', fontWeight: 600, fontSize: 14, fontFamily: 'inherit' }}>Edit profile</button>
      </div>

      {/* Stats row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 0, borderTop: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
        {[['142','Mat'],['4,217','Runs'],['36.4','Avg'],['138','SR']].map(([v, l], i) => (
          <div key={i} style={{ padding: '12px 8px', textAlign: 'center', borderRight: i < 3 ? '1px solid var(--hairline)' : 'none' }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em' }}>{v}</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>{l.toUpperCase()}</div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', padding: '8px 16px 0', gap: 4, borderBottom: '1px solid var(--hairline)' }}>
        {['Posts','Career','Form','Trophies'].map((t, i) => (
          <div key={i} style={{ padding: '8px 12px', fontSize: 12, fontWeight: 700, color: i === 0 ? 'var(--ink)' : 'var(--muted)', borderBottom: i === 0 ? '2px solid var(--ink)' : '2px solid transparent', marginBottom: -1 }}>{t}</div>
        ))}
      </div>

      {/* Posts list (your posts) */}
      <div style={{ padding: '10px 16px 70px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)' }}>
          <div style={{ fontSize: 13, lineHeight: 1.4 }}>Maiden hundred today 🥹 thanks to the Lahore Lions boys for backing me up.</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', marginTop: 6 }}>2H · 87 LIKES · PHOTO</div>
        </div>
        <div style={{ padding: 12, borderRadius: 10, border: '1px solid var(--hairline)', background: 'oklch(0.96 0.06 80)' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'oklch(0.55 0.13 50)', letterSpacing: '0.1em' }}>★ MILESTONE · AUTO</div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 700, letterSpacing: '-0.03em', marginTop: 4 }}>52 <span style={{ fontSize: 14, color: 'var(--muted)', fontWeight: 600 }}>off 41 · FIFTY</span></div>
        </div>
      </div>

      {/* Pointer to CTA */}
      <div style={{ position: 'absolute', top: 168, right: 20, fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.1em' }}>
        ← CANONICAL ENTRY
      </div>
      <MiniNav active="You"/>
    </PFPhone>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 5. STEP 1 — TYPE PICKER (full-screen sheet)
// ─────────────────────────────────────────────────────────────────────────
function PFTypePicker({ context = 'personal' }) {
  const all = [
    { id: 'text',  ttl: 'Text', sub: 'Quick thought, recap, opinion', glyph: 'Aa', tone: 'oklch(0.45 0.05 240)', who: ['personal','team','tournament'] },
    { id: 'photo', ttl: 'Photo / Album', sub: 'Up to 10 · highlight any moment', glyph: '◰', tone: 'oklch(0.55 0.12 200)', who: ['personal','team','tournament'] },
    { id: 'match', ttl: 'Match announcement', sub: 'Link a fixture · ask for an XI', glyph: 'V', tone: 'var(--red)', who: ['team','tournament'] },
    { id: 'recruit',ttl: 'Recruitment', sub: 'Open trial · role · deadline', glyph: '★', tone: 'oklch(0.55 0.13 80)', who: ['team'] },
    { id: 'tour',  ttl: 'Tournament update', sub: 'Fixtures · rules · standings', glyph: '◇', tone: 'oklch(0.45 0.12 280)', who: ['tournament'] },
  ];
  const items = all.map(i => ({ ...i, locked: !i.who.includes(context) }));
  const ctxLabel = context === 'personal' ? 'You · @bilala' : context === 'team' ? 'Lahore Lions' : "Spring Cup '26";
  const ctxColor = context === 'personal' ? 'var(--ink)' : context === 'team' ? 'var(--red)' : 'oklch(0.45 0.12 280)';

  return (
    <PFPhone label={`05 · STEP 1 — TYPE PICKER (${context.toUpperCase()})`} sub="Reached from Profile / Team manage / Tournament manage. Author chip is locked. Types greyed out are not permitted for this author.">
      <Status/>
      <div style={{ padding: '8px 18px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 13, color: 'var(--muted)' }}>Cancel</div>
        <div style={{ fontWeight: 700, fontSize: 15 }}>New post</div>
        <div style={{ fontSize: 13, color: 'var(--muted)', opacity: 0.4 }}>Next</div>
      </div>

      {/* Author chip */}
      <div style={{ margin: '0 18px 14px', padding: 10, borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper-2)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ width: 28, height: 28, borderRadius: context === 'personal' ? 999 : 6, background: ctxColor, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>
          {context === 'personal' ? 'BA' : context === 'team' ? 'LL' : 'SC'}
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>POSTING AS</div>
          <div style={{ fontSize: 13, fontWeight: 700, marginTop: 1 }}>{ctxLabel}</div>
        </div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--red)', fontWeight: 700, letterSpacing: '0.08em' }}>LOCKED</div>
      </div>

      <div style={{ padding: '0 18px', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--ink)', letterSpacing: '0.12em', marginBottom: 8 }}>WHAT ARE YOU POSTING?</div>

      <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map(it => (
          <div key={it.id} style={{ padding: 14, borderRadius: 12, border: '1px solid ' + (it.locked ? 'var(--hairline)' : 'var(--hairline)'), background: it.locked ? 'transparent' : 'var(--paper)', display: 'flex', alignItems: 'center', gap: 12, opacity: it.locked ? 0.4 : 1 }}>
            <div style={{ width: 38, height: 38, borderRadius: 8, background: it.tone, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15 }}>{it.glyph}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>{it.ttl}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{it.sub}</div>
            </div>
            {it.locked
              ? <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>NOT FOR YOU</div>
              : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ color: 'var(--muted)' }}><path d="m9 6 6 6-6 6"/></svg>}
          </div>
        ))}
      </div>

      {/* Auto-generated info banner */}
      <div style={{ position: 'absolute', left: 18, right: 18, bottom: 88, padding: 10, borderRadius: 8, background: 'oklch(0.94 0.05 90)', border: '1px solid oklch(0.86 0.05 90)', fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.4 }}>
        <strong>Heads up:</strong> Milestones · results · awards are auto-posted by the scoring engine. They appear on your profile without you doing anything.
      </div>
    </PFPhone>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 6. PER-TYPE COMPOSERS
// ─────────────────────────────────────────────────────────────────────────
function ComposeChrome({ title, postEnabled = false, children }) {
  return (
    <>
      <Status/>
      <div style={{ padding: '8px 18px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 13, color: 'var(--muted)' }}>Cancel</div>
        <div style={{ fontWeight: 700, fontSize: 15 }}>{title}</div>
        <div style={{ fontSize: 13, color: postEnabled ? 'var(--red)' : 'var(--muted)', fontWeight: 700 }}>Post</div>
      </div>
      {children}
    </>
  );
}

function PFComposeText() {
  return (
    <PFPhone label="06a · COMPOSE — TEXT" sub="Plain prose. Up to 2000 chars. Mentions @user / @team / @tournament. Hashtags. Counter visible.">
      <ComposeChrome title="New text post" postEnabled>
        <div style={{ padding: '0 18px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>BA</div>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Bilal Ahmed</div>
          <div style={{ flex: 1 }}/>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.08em' }}>PUBLIC ▾</div>
        </div>
        <div style={{ padding: '14px 18px 0', fontSize: 16, lineHeight: 1.5 }}>
          Best match of the season was our final last summer. Down 60 in 5, then <span style={{ color: 'var(--red)', fontWeight: 600 }}>@asad</span> walks in and hits 78 off 30. Cricket's a wild game.
          <span style={{ display: 'inline-block', width: 1.5, height: 18, background: 'var(--red)', marginLeft: 1, verticalAlign: '-3px', animation: 'caret 1s infinite' }}/>
        </div>
        <style>{`@keyframes caret{0%,49%{opacity:1}50%,100%{opacity:0}}`}</style>
        <div style={{ position: 'absolute', left: 18, right: 18, bottom: 76, padding: '10px 0', borderTop: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 16, color: 'var(--muted)' }}>
          <span style={{ fontSize: 13 }}>@</span>
          <span style={{ fontSize: 13 }}>#</span>
          <span style={{ fontSize: 13 }}>🔗 Link</span>
          <div style={{ flex: 1 }}/>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11 }}>183/2000</span>
        </div>
      </ComposeChrome>
    </PFPhone>
  );
}

function PFComposePhoto() {
  return (
    <PFPhone label="06b · COMPOSE — PHOTO / ALBUM" sub="Up to 10 photos. Drag to reorder. Optional caption. Optional linked match (auto-pulls scoreline tag).">
      <ComposeChrome title="New photo post" postEnabled>
        <div style={{ padding: '0 18px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>BA</div>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Bilal Ahmed</div>
          <div style={{ flex: 1 }}/>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.08em' }}>PUBLIC ▾</div>
        </div>

        {/* Photo grid */}
        <div style={{ padding: '12px 18px 0', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6 }}>
          {[0,1,2].map(i => (
            <div key={i} style={{ aspectRatio: '1', background: i === 0 ? 'var(--red)' : i === 1 ? 'oklch(0.42 0.10 260)' : 'oklch(0.55 0.12 200)', borderRadius: 8, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: '0.1em' }}>
              IMG {i+1}
              {i === 0 && <span style={{ position: 'absolute', top: 4, left: 4, padding: '2px 5px', borderRadius: 4, background: 'rgba(0,0,0,0.5)', fontSize: 8, fontWeight: 700 }}>COVER</span>}
            </div>
          ))}
          <div style={{ aspectRatio: '1', borderRadius: 8, border: '1.5px dashed var(--hairline)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted)', fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 600 }}>+</div>
        </div>

        <div style={{ padding: '14px 18px 0', fontSize: 14, lineHeight: 1.45, color: 'var(--ink)' }}>
          Maiden hundred today 🥹 thanks to <span style={{ color: 'var(--red)', fontWeight: 600 }}>@lahore-lions</span> for backing me up.
        </div>

        {/* Match link chip */}
        <div style={{ padding: '14px 18px 0' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>LINKED MATCH</div>
          <div style={{ marginTop: 6, padding: 10, borderRadius: 8, background: 'var(--paper-2)', border: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 22, height: 22, borderRadius: 4, background: 'var(--red)', color: 'white', fontFamily: 'Inter Tight', fontSize: 9, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>LL</div>
            <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>vs</span>
            <div style={{ width: 22, height: 22, borderRadius: 4, background: 'oklch(0.42 0.10 260)', color: 'white', fontFamily: 'Inter Tight', fontSize: 9, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>CTY</div>
            <div style={{ flex: 1, fontSize: 12, fontWeight: 600 }}>Spring Cup QF</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--red)', fontWeight: 700 }}>107* (62)</div>
          </div>
        </div>

        <div style={{ position: 'absolute', left: 18, right: 18, bottom: 76, padding: '10px 0', borderTop: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 16, color: 'var(--muted)', fontSize: 12 }}>
          <span>@ Tag</span><span>🏏 Match</span><span style={{ flex: 1 }}/><span style={{ fontFamily: 'JetBrains Mono', fontSize: 11 }}>3/10</span>
        </div>
      </ComposeChrome>
    </PFPhone>
  );
}

function PFComposeMatch() {
  return (
    <PFPhone label="06c · COMPOSE — MATCH ANNOUNCEMENT" sub="Team / organizer only. Picks a match (or creates inline). Auto-builds the versus block in the published post. Optional 'Need Xth player' flag.">
      <ComposeChrome title="Match announcement" postEnabled>
        <div style={{ padding: '0 18px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: 6, background: 'var(--red)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>LL</div>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Lahore Lions</div>
          <div style={{ flex: 1 }}/>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.08em' }}>FOLLOWERS ▾</div>
        </div>

        {/* Pick match */}
        <div style={{ padding: '12px 18px 0' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>MATCH</div>
          <div style={{ marginTop: 6, padding: 12, borderRadius: 10, border: '1.5px solid var(--ink)', background: 'var(--paper)' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 10, alignItems: 'center' }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <div style={{ width: 32, height: 32, borderRadius: 6, background: 'var(--red)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>LL</div>
                <div style={{ fontSize: 11, fontWeight: 600 }}>Lahore Lions</div>
              </div>
              <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, color: 'var(--muted)', fontSize: 14 }}>vs</div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <div style={{ width: 32, height: 32, borderRadius: 6, background: 'oklch(0.42 0.10 260)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>CTY</div>
                <div style={{ fontSize: 11, fontWeight: 600 }}>City Eagles</div>
              </div>
            </div>
            <div style={{ marginTop: 10, paddingTop: 8, borderTop: '1px dashed var(--hairline)', display: 'flex', justifyContent: 'space-between', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)' }}>
              <span>Fri 14 Mar · 6:00 PM</span><span>Model Town</span>
            </div>
          </div>
        </div>

        {/* Body */}
        <div style={{ padding: '12px 18px 0' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>MESSAGE</div>
          <div style={{ marginTop: 6, padding: 10, borderRadius: 8, border: '1px solid var(--hairline)', fontSize: 13, lineHeight: 1.45, minHeight: 70 }}>
            Friday 6 PM — playoff vs City Eagles. Model Town pitch. We need a 12th. DM if available.
          </div>
        </div>

        {/* Toggles */}
        <div style={{ padding: '12px 18px 0', display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 12px', borderRadius: 8, border: '1px solid var(--hairline)' }}>
            <div>
              <div style={{ fontSize: 12, fontWeight: 700 }}>Allow RSVP</div>
              <div style={{ fontSize: 10, color: 'var(--muted)' }}>Going / Maybe / Can't</div>
            </div>
            <div style={{ width: 32, height: 18, borderRadius: 999, background: 'var(--ink)', position: 'relative' }}>
              <div style={{ position: 'absolute', top: 2, right: 2, width: 14, height: 14, borderRadius: 999, background: 'white' }}/>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 12px', borderRadius: 8, border: '1px solid var(--hairline)' }}>
            <div>
              <div style={{ fontSize: 12, fontWeight: 700 }}>Need a player?</div>
              <div style={{ fontSize: 10, color: 'var(--muted)' }}>Surfaces a "Last spot" badge</div>
            </div>
            <div style={{ width: 32, height: 18, borderRadius: 999, background: 'var(--paper-2)', border: '1px solid var(--hairline)', position: 'relative' }}>
              <div style={{ position: 'absolute', top: 1, left: 1, width: 14, height: 14, borderRadius: 999, background: 'white', border: '1px solid var(--hairline)' }}/>
            </div>
          </div>
        </div>
      </ComposeChrome>
    </PFPhone>
  );
}

function PFComposeRecruit() {
  return (
    <PFPhone label="06d · COMPOSE — RECRUITMENT" sub="Team only. Structured fields: role, body, location, deadline, spots. Renders the wanted-poster card.">
      <ComposeChrome title="Recruitment post" postEnabled>
        <div style={{ padding: '0 18px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: 6, background: 'var(--red)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>LL</div>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Lahore Lions</div>
          <div style={{ flex: 1 }}/>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.08em' }}>PUBLIC ▾</div>
        </div>

        <div style={{ padding: '12px 18px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>ROLE NEEDED</div>
            <div style={{ marginTop: 4, padding: '10px 12px', borderRadius: 8, border: '1.5px solid var(--ink)', fontSize: 14, fontFamily: 'Inter Tight', fontWeight: 700 }}>Right-arm fast bowler</div>
          </div>
          <div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>DETAILS</div>
            <div style={{ marginTop: 4, padding: 10, borderRadius: 8, border: '1px solid var(--hairline)', fontSize: 12, lineHeight: 1.45, minHeight: 60 }}>
              One quick needed for the Sunday League. Ages 18–28. Tape ball, evening matches at Gulberg.
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            <div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>LOCATION</div>
              <div style={{ marginTop: 4, padding: '8px 10px', borderRadius: 8, border: '1px solid var(--hairline)', fontSize: 12 }}>Lahore · Gulberg</div>
            </div>
            <div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>DEADLINE</div>
              <div style={{ marginTop: 4, padding: '8px 10px', borderRadius: 8, border: '1px solid var(--hairline)', fontSize: 12 }}>Apply by Wed</div>
            </div>
          </div>
          <div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>SPOTS</div>
            <div style={{ marginTop: 4, display: 'flex', gap: 6 }}>
              {[1,2,3,'5+'].map((n,i) => (
                <div key={i} style={{ flex: 1, padding: '8px 0', textAlign: 'center', borderRadius: 8, border: '1px solid ' + (i === 0 ? 'var(--ink)' : 'var(--hairline)'), background: i === 0 ? 'var(--ink)' : 'var(--paper)', color: i === 0 ? 'var(--paper)' : 'var(--ink)', fontWeight: 700, fontSize: 13, fontFamily: 'Inter Tight' }}>{n}</div>
              ))}
            </div>
          </div>
        </div>
      </ComposeChrome>
    </PFPhone>
  );
}

function PFComposeTour() {
  return (
    <PFPhone label="06e · COMPOSE — TOURNAMENT UPDATE" sub="Organizer only. Headline + body + optional fixture rail. Tag types: Schedule · Rule · Result · Bracket · General.">
      <ComposeChrome title="Tournament update" postEnabled>
        <div style={{ padding: '0 18px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: 6, background: 'oklch(0.45 0.12 280)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>SC</div>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Spring Cup '26</div>
          <div style={{ flex: 1 }}/>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.08em' }}>PUBLIC ▾</div>
        </div>

        {/* tag selector */}
        <div style={{ padding: '12px 18px 0', display: 'flex', gap: 6, overflowX: 'auto' }}>
          {['Schedule','Rule','Result','Bracket','General'].map((t,i) => (
            <div key={i} style={{ flex: 'none', padding: '6px 12px', borderRadius: 999, background: i === 0 ? 'var(--ink)' : 'transparent', color: i === 0 ? 'var(--paper)' : 'var(--ink-2)', border: '1px solid ' + (i === 0 ? 'var(--ink)' : 'var(--hairline)'), fontSize: 11, fontWeight: 600 }}>{t}</div>
          ))}
        </div>

        <div style={{ padding: '12px 18px 0' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>HEADLINE</div>
          <div style={{ marginTop: 4, padding: '10px 12px', borderRadius: 8, border: '1.5px solid var(--ink)', fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, letterSpacing: '-0.015em' }}>Round 2 fixtures announced</div>
        </div>
        <div style={{ padding: '10px 18px 0' }}>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>BODY</div>
          <div style={{ marginTop: 4, padding: 10, borderRadius: 8, border: '1px solid var(--hairline)', fontSize: 12, lineHeight: 1.45 }}>4 quarterfinals across this weekend. Brackets locked.</div>
        </div>

        {/* attached fixtures */}
        <div style={{ padding: '12px 18px 0' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>ATTACH FIXTURES</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--red)', fontWeight: 700, letterSpacing: '0.1em' }}>4 SELECTED</div>
          </div>
          <div style={{ marginTop: 6, borderRadius: 8, overflow: 'hidden', border: '1px solid var(--hairline)' }}>
            {[['QF1','Lions','Eagles','Fri 6 PM',true],['QF2','Kings','Old Boys','Sat 5 PM',true],['QF3','DHA U.','New School','Sat 7 PM',true]].map(([n,a,b,t,sel],i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 10px', borderTop: i === 0 ? 'none' : '1px solid var(--hairline)', background: sel ? 'oklch(0.96 0.04 28)' : 'transparent' }}>
                <div style={{ width: 14, height: 14, borderRadius: 3, background: sel ? 'var(--red)' : 'transparent', border: '1.5px solid ' + (sel ? 'var(--red)' : 'var(--hairline)') }}/>
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.06em' }}>{n}</span>
                <span style={{ flex: 1, fontFamily: 'Inter Tight', fontSize: 12, fontWeight: 700 }}>{a} <span style={{ color: 'var(--muted)', fontWeight: 500 }}>vs</span> {b}</span>
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)' }}>{t}</span>
              </div>
            ))}
          </div>
        </div>
      </ComposeChrome>
    </PFPhone>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 7. PREVIEW + PUBLISH + SUCCESS
// ─────────────────────────────────────────────────────────────────────────
function PFPreview() {
  return (
    <PFPhone label="07 · STEP 3 — PREVIEW" sub="Render the post exactly as it will appear in the feed. User can swipe between author surfaces (Profile / Home / Team) to see all surface contexts.">
      <Status/>
      <div style={{ padding: '8px 18px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 13, color: 'var(--muted)' }}>← Edit</div>
        <div style={{ fontWeight: 700, fontSize: 15 }}>Preview</div>
        <div style={{ fontSize: 13, color: 'var(--red)', fontWeight: 700 }}>Publish</div>
      </div>

      {/* surface tabs */}
      <div style={{ padding: '0 18px 10px', display: 'flex', gap: 6 }}>
        {['Home feed','Profile','Team page'].map((t,i) => (
          <div key={i} style={{ padding: '5px 10px', borderRadius: 999, background: i === 0 ? 'var(--ink)' : 'transparent', color: i === 0 ? 'var(--paper)' : 'var(--muted)', border: '1px solid ' + (i === 0 ? 'var(--ink)' : 'var(--hairline)'), fontSize: 10, fontWeight: 700, fontFamily: 'JetBrains Mono', letterSpacing: '0.06em' }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* the rendered post (photo example) */}
      <div style={{ margin: '0 18px', borderRadius: 12, border: '1px solid var(--hairline)', overflow: 'hidden', background: 'var(--paper)' }}>
        <div style={{ padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 22, height: 22, borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 9 }}>BA</div>
          <span style={{ fontSize: 12, fontWeight: 600 }}>Bilal Ahmed</span>
          <span style={{ flex: 1 }}/>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>now</span>
        </div>
        <div style={{ padding: '0 14px 10px', fontSize: 13, lineHeight: 1.45 }}>Maiden hundred today 🥹 thanks to <span style={{ color: 'var(--red)', fontWeight: 600 }}>@lahore-lions</span> for backing me up.</div>
        <div style={{ height: 180, background: 'var(--red)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, opacity: 0.8, letterSpacing: '0.14em' }}>HIGHLIGHT · CH. 3</div>
            <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 56, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 2 }}>SIX</div>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, opacity: 0.85, marginTop: 4 }}>107* (62)</div>
          </div>
        </div>
        <div style={{ padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 14, borderTop: '1px solid var(--hairline)' }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>♡ 0</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>💬 0</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>↗</span>
        </div>
      </div>

      {/* visibility / scheduling */}
      <div style={{ position: 'absolute', left: 18, right: 18, bottom: 88, padding: 12, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>VISIBILITY</span>
          <span style={{ fontWeight: 700 }}>Public</span>
          <span style={{ flex: 1 }}/>
          <span style={{ fontSize: 11, color: 'var(--red)', fontWeight: 700 }}>Change ›</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, marginTop: 6 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>POST AT</span>
          <span style={{ fontWeight: 700 }}>Now</span>
          <span style={{ flex: 1 }}/>
          <span style={{ fontSize: 11, color: 'var(--red)', fontWeight: 700 }}>Schedule ›</span>
        </div>
      </div>
    </PFPhone>
  );
}

function PFSuccess() {
  return (
    <PFPhone label="08 · STEP 4 — POSTED" sub="Confirmation. Auto-dismiss after 1.6s. Returns user to wherever they launched from (Profile by default). Toast at top of returned screen too.">
      <div style={{ height: '100%', background: 'var(--ink)', color: 'var(--paper)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14 }}>
        <div style={{ width: 72, height: 72, borderRadius: 999, border: '2px solid var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5L20 7"/></svg>
        </div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 28, fontWeight: 700, letterSpacing: '-0.03em' }}>Posted<span style={{ color: 'var(--red)' }}>.</span></div>
        <div style={{ fontSize: 13, color: 'oklch(0.78 0.01 80)', textAlign: 'center', maxWidth: 240, lineHeight: 1.4 }}>Visible on your profile and the feeds of everyone who follows you.</div>
        <div style={{ marginTop: 8, display: 'flex', gap: 8 }}>
          <div style={{ padding: '8px 16px', borderRadius: 999, background: 'var(--paper)', color: 'var(--ink)', fontSize: 12, fontWeight: 700 }}>View on profile</div>
          <div style={{ padding: '8px 16px', borderRadius: 999, border: '1px solid oklch(0.30 0.02 80)', color: 'var(--paper)', fontSize: 12, fontWeight: 700 }}>Share</div>
        </div>
      </div>
    </PFPhone>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 9. AUTO-POSTS — system-emitted, read-only from author POV
// ─────────────────────────────────────────────────────────────────────────
function PFAuto() {
  return (
    <div style={{ width: 720, height: 874, padding: 40, background: 'var(--paper)', fontFamily: 'Inter, sans-serif', color: 'var(--ink)', display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>POST CREATION · AUTO / 09</div>
        <h2 style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 700, letterSpacing: '-0.025em', margin: '8px 0 0', lineHeight: 1.05 }}>
          Auto-posts: emitted, not composed.
        </h2>
        <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.45, marginTop: 8, maxWidth: 580 }}>
          Four post types are written by the system, never by a user. They show up in feeds and on the relevant profile/team/tournament without the user lifting a finger. Author can mute or delete an auto-post about themselves; they cannot edit its content.
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {[
          { tag: 'MILESTONE', name: '50 · 100 · 5w · hat-trick', trigger: 'Scoring engine: bat 50/100, bowl 5w, 3-in-3, century stand, debut hundred', emits: 'Player profile + home feeds of followers + linked match details', tone: 'oklch(0.55 0.13 50)', bg: 'oklch(0.96 0.06 80)' },
          { tag: 'RESULT', name: 'Match result', trigger: 'On match finalize: winner, MoM, scoreline summary', emits: 'Both team pages + tournament page + player profiles of MoM/top contributors', tone: 'oklch(0.36 0.10 148)', bg: 'oklch(0.94 0.05 148)' },
          { tag: 'AWARD', name: 'Trophy / award', trigger: 'On tournament finalize: winner, runner-up, Player of Tournament', emits: 'Tournament page + winning team + awarded player profiles', tone: 'oklch(0.55 0.16 50)', bg: 'oklch(0.94 0.06 80)' },
          { tag: 'CLAIM', name: 'Profile claimed', trigger: 'On unclaimed → claimed transition', emits: 'Newly-claimed profile only (history reveal)', tone: 'var(--muted)', bg: 'var(--paper-2)' },
        ].map((a, i) => (
          <div key={i} style={{ padding: 14, borderRadius: 10, background: a.bg, border: '1px solid var(--hairline)' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: a.tone, letterSpacing: '0.12em' }}>★ {a.tag} · AUTO</div>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, marginTop: 4, letterSpacing: '-0.02em' }}>{a.name}</div>
            <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 8, lineHeight: 1.45 }}><strong>Trigger:</strong> {a.trigger}</div>
            <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.45 }}><strong>Emits to:</strong> {a.emits}</div>
          </div>
        ))}
      </div>

      <div style={{ flex: 1 }} />

      <div style={{ padding: 14, background: 'var(--ink)', color: 'var(--paper)', borderRadius: 10 }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--amber)', letterSpacing: '0.12em' }}>RULES</div>
        <ul style={{ margin: '6px 0 0', paddingLeft: 18, fontSize: 12, lineHeight: 1.6, color: 'oklch(0.85 0.01 80)' }}>
          <li>Auto-posts always carry an <code style={{ fontFamily: 'JetBrains Mono', background: 'oklch(0.30 0.02 80)', padding: '1px 5px', borderRadius: 3 }}>· AUTO</code> badge — they're not human writing.</li>
          <li>The "subject" can mute future auto-posts of that type for themselves (Settings · Auto-post preferences).</li>
          <li>Unclaimed players still get auto-posts; on claim, the post lineage transfers to the new owner's profile feed.</li>
          <li>Auto-posts are likable / commentable / savable like any other post.</li>
        </ul>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 10. EDGE CASES & RULES — final summary card
// ─────────────────────────────────────────────────────────────────────────
function PFRules() {
  const rules = [
    ['Author identity', 'Determined by entry surface. Profile → personal · Team manage → team · Tour manage → tournament. Composer never asks "who am I?".'],
    ['Permissions', 'A user can post personally always. Team posts only by team manager(s). Tournament posts only by organizer(s).'],
    ['Visibility', 'Public (default · indexable) · Followers only · Members only (team posts). Per-post, persistent default in Settings.'],
    ['Mentions', '@user / @team / @tournament. Mention triggers a notification. Non-existent handles render as plain text, no link.'],
    ['Hashtags', 'Free-form. Discoverable in Search. No moderation in MVP.'],
    ['Linked match', 'Photo & Text posts may attach a match → renders an inline scoreline tag. Match Announcement REQUIRES a match.'],
    ['Media', 'Up to 10 photos per post. Video deferred to v1.2. All media uploaded to posts/{postId}/{filename}.'],
    ['Editing', 'Edit window of 15 min for text body / caption only. After that, content is locked. (RSVPs, applications keep flowing.)'],
    ['Deletion', 'Author can delete anytime. Engagement counts vanish. Auto-posts have a "Hide from my profile" instead of delete.'],
    ['Drafts', 'Compose state auto-saves locally. One draft per type. Surfaced as a "Pick up where you left off" chip on Profile.'],
    ['Scheduling', 'Schedule for any time within next 30 days. Scheduled posts visible in Profile · Drafts tab.'],
    ['Reporting', 'Three-dot menu on every post → Report (spam · harassment · off-topic · IP). Reported posts go to a moderation queue.'],
    ['Moderation', 'Team / tournament managers can hide a post from their entity surface (post still exists on author profile).'],
    ['Empty state', 'Profile with zero posts shows a quiet onboarding: "Your first post is a recap. Tap Post to begin."'],
    ['Failure', 'Network failure during publish keeps the draft and shows a retry banner — never silently loses the user\'s text.'],
  ];
  return (
    <div style={{ width: 720, height: 874, padding: 40, background: 'var(--paper)', fontFamily: 'Inter, sans-serif', color: 'var(--ink)', display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 600, color: 'var(--muted)', letterSpacing: '0.12em' }}>POST CREATION · RULES / 10</div>
        <h2 style={{ fontFamily: 'Inter Tight', fontSize: 32, fontWeight: 700, letterSpacing: '-0.025em', margin: '8px 0 0', lineHeight: 1.05 }}>
          The 15 rules nothing is allowed to break.
        </h2>
      </div>

      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr', gap: 0, borderTop: '1px solid var(--hairline)' }}>
        {rules.map(([k, v], i) => (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: '180px 1fr', gap: 16, padding: '10px 0', borderBottom: '1px dashed var(--hairline)', alignItems: 'baseline' }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--ink)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>{k}</div>
            <div style={{ fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5 }}>{v}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────
window.PFAudit = PFAudit;
window.PFMatrix = PFMatrix;
window.PFMap = PFMap;
window.PFProfileEntry = PFProfileEntry;
window.PFTypePicker = PFTypePicker;
window.PFComposeText = PFComposeText;
window.PFComposePhoto = PFComposePhoto;
window.PFComposeMatch = PFComposeMatch;
window.PFComposeRecruit = PFComposeRecruit;
window.PFComposeTour = PFComposeTour;
window.PFPreview = PFPreview;
window.PFSuccess = PFSuccess;
window.PFAuto = PFAuto;
window.PFRules = PFRules;

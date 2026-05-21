// SuggestFollows.jsx — First-run "follow tournaments/teams/players in your city" sheet (§7.7)

function SuggestFollows() {
  const [step, setStep] = React.useState('tournaments'); // tournaments | teams | players | done
  const [followed, setFollowed] = React.useState({
    tournaments: new Set(['t1']),
    teams: new Set(['tm1']),
    players: new Set(),
  });

  const toggle = (cat, id) => {
    setFollowed(f => {
      const next = new Set(f[cat]);
      next.has(id) ? next.delete(id) : next.add(id);
      return { ...f, [cat]: next };
    });
  };

  const data = {
    tournaments: [
      { id: 't1', name: 'Spring Cup \'26', sub: 'T20 · Lahore · live now', meta: '16 teams · 47 followers in your circle', kind: 'tournament' },
      { id: 't2', name: 'Mohalla Champions \'26', sub: 'T20 · Cantt · starts May 2', meta: '24 teams · open registration', kind: 'tournament' },
      { id: 't3', name: 'Galle Night League', sub: 'Tape-ball T10 · 2.4km away', meta: '12 teams · matches every Sat', kind: 'tournament' },
      { id: 't4', name: 'Friday League', sub: 'Hard-ball T20 · Cantt', meta: '8 teams · 24 followers in your circle', kind: 'tournament' },
      { id: 't5', name: 'Rotary Friendship Cup', sub: 'T20 · Defence · May 9', meta: 'Open registration · 7/16 teams', kind: 'tournament' },
    ],
    teams: [
      { id: 'tm1', name: 'Lahore Lions', sub: 'Your team', meta: '14W·2L · 24 players · captained by Adeel S.', kind: 'team', c: 'oklch(0.62 0.19 28)', isYours: true },
      { id: 'tm2', name: 'Defenders XI', sub: 'Cantt rivals · 2.1 km', meta: '13W·3L · plays Lions twice this season', kind: 'team', c: 'oklch(0.36 0.10 148)' },
      { id: 'tm3', name: 'Mohalla Kings', sub: 'Tape-ball · DHA', meta: '11W·5L · followed by 8 of your team-mates', kind: 'team', c: 'oklch(0.78 0.14 80)' },
      { id: 'tm4', name: 'Galle Boys', sub: 'Hard-ball · Iqbal Town', meta: '9W·3L · 4 mutuals follow', kind: 'team', c: 'oklch(0.30 0.02 80)' },
      { id: 'tm5', name: 'City Eagles', sub: 'Lahore Premier League', meta: '11W·5L · faced Lions in QF', kind: 'team', c: 'oklch(0.55 0.08 240)' },
    ],
    players: [
      { id: 'p1', name: 'Adeel Sheikh', sub: 'Captain · Lahore Lions', meta: 'Your captain · WK · 312 r this season', kind: 'player', avatar: 'AS', isCaptain: true },
      { id: 'p2', name: 'Hassan Raza', sub: 'All-rounder · Mohalla Kings', meta: 'Best SR in city · 168.4 · 31 sixes', kind: 'player', avatar: 'HR' },
      { id: 'p3', name: 'Tariq Mahmood', sub: 'Pacer · Lahore Lions', meta: 'Team-mate · top wicket-taker', kind: 'player', avatar: 'TM' },
      { id: 'p4', name: 'Ahmed Sheikh', sub: 'Top order · Defenders XI', meta: 'Rival · best avg 51.5', kind: 'player', avatar: 'AS' },
      { id: 'p5', name: 'Lasith Silva', sub: 'Spinner · Galle Boys', meta: '24 wkts · econ 5.8 · 2 5-fers', kind: 'player', avatar: 'LS' },
    ],
  };

  const labels = {
    tournaments: { title: 'Follow tournaments', sub: 'Get fixtures, results, and bracket updates from tournaments near you.', icon: 'trophy' },
    teams: { title: 'Follow teams', sub: 'See match announcements, results, and recruitment posts from teams you care about.', icon: 'team' },
    players: { title: 'Follow players', sub: 'Their milestones, posts, and best knocks will appear in your feed.', icon: 'player' },
  };

  const stepOrder = ['tournaments', 'teams', 'players'];
  const stepIdx = stepOrder.indexOf(step);
  const next = () => {
    if (stepIdx < stepOrder.length - 1) setStep(stepOrder[stepIdx + 1]);
    else setStep('done');
  };
  const back = () => { if (stepIdx > 0) setStep(stepOrder[stepIdx - 1]); };
  const skip = () => setStep('done');

  const totalFollowed = () => Object.values(followed).reduce((a, s) => a + s.size, 0);

  if (step === 'done') {
    return (
      <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--paper)' }}>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px', textAlign: 'center' }}>
          <div style={{ width: 84, height: 84, borderRadius: 999, background: 'var(--green-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 24 }}>
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="oklch(0.36 0.10 148)" strokeWidth="2.5"><path d="M20 6 9 17l-5-5"/></svg>
          </div>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 30, fontWeight: 700, letterSpacing: '-0.025em', lineHeight: 1.1 }}>Your feed is ready</div>
          <div style={{ fontSize: 14, color: 'var(--ink-2)', marginTop: 12, lineHeight: 1.5, maxWidth: 280 }}>
            Following <strong>{totalFollowed()}</strong> {totalFollowed() === 1 ? 'thing' : 'things'} — {followed.tournaments.size} tournament{followed.tournaments.size !== 1 ? 's' : ''}, {followed.teams.size} team{followed.teams.size !== 1 ? 's' : ''}, {followed.players.size} player{followed.players.size !== 1 ? 's' : ''}.
          </div>
          <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 14, lineHeight: 1.5, maxWidth: 280 }}>
            We'll keep suggesting people to follow as you play more matches.
          </div>
        </div>
        <div style={{ padding: '0 24px 28px' }}>
          <button onClick={() => setStep('tournaments')} style={{
            width: '100%', padding: '15px 0', borderRadius: 14, background: 'var(--ink)', color: 'var(--paper)',
            border: 'none', fontFamily: 'inherit', fontSize: 16, fontWeight: 600, cursor: 'pointer',
          }}>Take me to my feed</button>
          <button onClick={() => setStep('tournaments')} style={{ width: '100%', marginTop: 8, padding: '12px 0', background: 'transparent', color: 'var(--muted)', border: 'none', fontFamily: 'inherit', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Review my picks</button>
        </div>
      </div>
    );
  }

  const cur = labels[step];
  const items = data[step];
  const followedCount = followed[step].size;

  const Icon = ({ kind, c, avatar, isYours, isCaptain }) => {
    if (kind === 'team') {
      return (
        <div style={{ width: 44, height: 44, borderRadius: 10, background: c, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontFamily: 'Inter Tight', fontSize: 13, fontWeight: 700, flexShrink: 0, position: 'relative' }}>
          {data.teams.find(t => t.c === c)?.name.split(' ').map(w => w[0]).slice(0,2).join('')}
          {isYours && <div style={{ position: 'absolute', top: -3, right: -3, width: 14, height: 14, borderRadius: 999, background: 'var(--ink)', color: 'oklch(0.78 0.14 80)', fontSize: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'JetBrains Mono', fontWeight: 700, border: '2px solid var(--paper)' }}>★</div>}
        </div>
      );
    }
    if (kind === 'player') {
      return (
        <div className="ck-avatar" style={{ width: 44, height: 44, fontSize: 13, position: 'relative' }}>
          {avatar}
          {isCaptain && <div style={{ position: 'absolute', top: -3, right: -3, fontSize: 8, fontFamily: 'JetBrains Mono', fontWeight: 700, padding: '1px 4px', borderRadius: 4, background: 'var(--ink)', color: 'var(--paper)', letterSpacing: '0.08em', border: '2px solid var(--paper)' }}>C</div>}
        </div>
      );
    }
    return (
      <div style={{ width: 44, height: 44, borderRadius: 10, background: 'var(--cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="1.8"><path d="M6 9V7a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M6 9h12l-1 11H7Z"/></svg>
      </div>
    );
  };

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--paper)' }}>
      {/* Header w/ progress */}
      <div style={{ padding: '14px 20px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
          <button onClick={back} disabled={stepIdx === 0} style={{
            background: 'transparent', border: 'none', cursor: stepIdx === 0 ? 'default' : 'pointer', padding: 0,
            opacity: stepIdx === 0 ? 0.25 : 1,
          }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
          </button>
          <div style={{ display: 'flex', gap: 6 }}>
            {stepOrder.map((s, i) => (
              <div key={s} style={{
                width: i === stepIdx ? 22 : 6, height: 6, borderRadius: 999,
                background: i <= stepIdx ? 'var(--ink)' : 'var(--hairline)',
                transition: 'all .2s',
              }} />
            ))}
          </div>
          <button onClick={skip} style={{ background: 'transparent', border: 'none', fontSize: 13, fontFamily: 'inherit', color: 'var(--muted)', cursor: 'pointer', fontWeight: 600 }}>Skip</button>
        </div>

        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', letterSpacing: '0.1em' }}>STEP {stepIdx + 1} OF 3 · LAHORE</div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 30, fontWeight: 700, letterSpacing: '-0.03em', marginTop: 6, lineHeight: 1.1 }}>{cur.title}</div>
        <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 10, lineHeight: 1.45 }}>{cur.sub}</div>
      </div>

      {/* List */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* Quick action: follow all */}
        <div style={{ padding: '8px 20px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div className="ck-section-h">Suggested for you · {items.length}</div>
          <button onClick={() => setFollowed(f => ({ ...f, [step]: new Set(items.map(it => it.id)) }))} style={{ background: 'transparent', border: 'none', fontSize: 12, fontFamily: 'inherit', color: 'var(--ink)', cursor: 'pointer', fontWeight: 600 }}>Follow all</button>
        </div>
        {items.map(it => {
          const on = followed[step].has(it.id);
          return (
            <div key={it.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderTop: '1px solid var(--hairline)' }}>
              <Icon kind={it.kind} c={it.c} avatar={it.avatar} isYours={it.isYours} isCaptain={it.isCaptain} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'Inter Tight', fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em' }}>{it.name}</div>
                <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 2 }}>{it.sub}</div>
                <div style={{ fontSize: 10.5, color: 'var(--muted)', marginTop: 3, fontFamily: 'JetBrains Mono', letterSpacing: '0.02em' }}>{it.meta}</div>
              </div>
              <button onClick={() => toggle(step, it.id)} style={{
                padding: '7px 14px', borderRadius: 999,
                background: on ? 'var(--paper-2)' : 'var(--ink)',
                color: on ? 'var(--ink)' : 'var(--paper)',
                border: on ? '1px solid var(--hairline)' : 'none',
                fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer',
                minWidth: 84, flexShrink: 0,
              }}>{on ? 'Following ✓' : 'Follow'}</button>
            </div>
          );
        })}
        <div style={{ height: 12 }} />
      </div>

      {/* Sticky footer */}
      <div style={{ padding: '12px 20px 18px', borderTop: '1px solid var(--hairline)', background: 'var(--paper)', display: 'flex', gap: 10, alignItems: 'center' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', lineHeight: 1 }}>
            {followedCount} <span style={{ color: 'var(--muted)', fontSize: 13, fontWeight: 500 }}>following</span>
          </div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>
            {followedCount === 0 ? 'You can follow people any time' : `Total across all steps: ${totalFollowed()}`}
          </div>
        </div>
        <button onClick={next} style={{
          padding: '12px 22px', borderRadius: 12,
          background: 'var(--ink)', color: 'var(--paper)', border: 'none',
          fontFamily: 'inherit', fontSize: 14, fontWeight: 600, cursor: 'pointer',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          {stepIdx === stepOrder.length - 1 ? 'Done' : 'Next'}
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="m9 18 6-6-6-6"/></svg>
        </button>
      </div>
    </div>
  );
}

window.CkSuggestFollows = SuggestFollows;

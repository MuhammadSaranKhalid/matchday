// pavilion-app-v2.jsx — Pavilion workspace, v2.
// Same hub, but match cards are status-only and open a full Match Detail page
// where every action lives. The Today hero keeps the one urgent action.

(function () {

const C = window.Ch;
const D = window.PavData;
const P = window.PavParts;   // shared Overview / TeamsLane / ToursLane / Account
const V = window.PavV2;      // v2 MatchesLane + MatchDetail
const { ink, ink2, muted, soft, paper, paper2, hair, red, green, amber, display, mono, Icon, Avatar } = C;
const { Overview, TeamsLane, ToursLane, Account } = P;
const { MatchesLane, MatchDetail } = V;
const { useState, useEffect, useRef } = React;

const SEGMENTS = [
  { id: 'matches', l: 'Matches', create: 'Schedule match' },
  { id: 'teams', l: 'Teams', create: 'Create team' },
  { id: 'tournaments', l: 'Tournaments', create: 'Create tournament' },
];

function PavilionBody({ scenario = 'Match day', overview = true, onProfile }) {
  const [matches, setMatches] = useState(D.seedMatches);
  const [teams, setTeams] = useState(D.seedTeams);
  const [tours, setTours] = useState(D.seedTournaments);
  const [seg, setSeg] = useState('matches');
  const [account, setAccount] = useState(false);
  const [sendOpen, setSendOpen] = useState(false);
  const [openMatchId, setOpenMatchId] = useState(null);  // match detail
  const [toast, setToast] = useState(null);
  const scrollRef = useRef(null);

  useEffect(() => {
    const empty = scenario === 'New user';
    setMatches(empty ? [] : D.seedMatches());
    setTeams(empty ? [] : D.seedTeams());
    setTours(empty ? [] : D.seedTournaments());
    setOpenMatchId(null);
  }, [scenario]);
  const flash = (m) => { setToast(m); setTimeout(() => setToast(null), 2400); };
  const showOverview = overview && scenario === 'Match day';

  // single action dispatcher — used by both the Today hero and the detail page
  const onMatchAction = (id, action) => {
    if (action === 'lineup') { setMatches(ms => ms.map(x => x.id === id ? { ...x, lineupSet: true } : x)); flash('Lineup set'); return; }
    if (action === 'start') { setMatches(ms => ms.map(x => x.id === id ? { ...x, phase: 'live', scoreA: '0/0', when: 'Now · 0.0 ov' } : x)); flash('Match started — you’re live'); return; }
    if (action === 'resume') { flash('Opening live scoring…'); return; }
    if (action === 'withdraw' || action === 'cancel') { setMatches(ms => ms.filter(x => x.id !== id)); setOpenMatchId(null); flash(action === 'cancel' ? 'Match cancelled' : 'Challenge withdrawn'); return; }
    if (action === 'viewlineup') { flash('Opening lineup…'); return; }
    if (action === 'reschedule') { flash('Propose a new time…'); return; }
    if (action === 'message') { flash('Opening chat…'); return; }
    if (action === 'scorecard' || action === 'view') { flash('Opening scorecard…'); return; }
    if (action === 'share') { flash('Sharing result…'); return; }
  };

  const onCreate = () => {
    if (seg === 'matches') { setSendOpen(true); return; }
    flash(seg === 'teams' ? 'Opening team setup…' : 'Opening tournament setup…');
  };

  const onSent = (payload) => {
    setSendOpen(false);
    const opp = payload.open ? 'MK' : (payload.opp && payload.opp.mono) || 'KE';
    setMatches(ms => [{ id: 'm_new_' + Date.now(), phase: 'scheduled', opp: opp.slice(0, 2).toUpperCase(), team: 'LL', role: 'captain',
      when: payload.when && payload.when.dateLabel ? payload.when.dateLabel.split(' · ').slice(-1)[0] + ' · ' + (payload.when.time || '') : 'Scheduled', venue: payload.venue || 'TBD', sub: payload.open ? 'Open challenge' : 'Friendly', lineupSet: true }, ...ms]);
    setSeg('matches');
    flash(payload.open ? 'Open challenge created' : 'Challenge sent — added to Matches');
  };

  const activeSeg = SEGMENTS.find(s => s.id === seg);
  const heroMatch = matches.find(m => m.phase === 'live') || matches.find(m => m.phase === 'startsSoon');
  const heroIds = heroMatch ? [heroMatch.id] : [];
  const openMatch = openMatchId ? matches.find(m => m.id === openMatchId) : null;

  return (
        <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: paper, position: 'relative', overflow: 'hidden' }}>
          <div style={{ height: 44, flexShrink: 0 }} />
          {/* header */}
          <div style={{ padding: '6px 16px 12px', flexShrink: 0, display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ ...mono, fontSize: 9, color: muted, marginBottom: 2 }}>YOUR WORKSPACE</div>
              <h1 style={{ ...display(26) }}>Pavilion</h1>
            </div>
            <button onClick={() => onProfile ? onProfile() : setAccount(true)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 0, borderRadius: 999 }} aria-label="Profile">
              <Avatar name="Bilal Ahmed" size={40} />
            </button>
          </div>

          {/* segmented control */}
          <div style={{ padding: '0 16px 8px', flexShrink: 0 }}>
            <div style={{ display: 'flex', padding: 3, background: paper2, border: '1px solid ' + hair, borderRadius: 11 }}>
              {SEGMENTS.map(s => {
                const on = seg === s.id;
                const badge = s.id === 'matches' ? matches.filter(m => m.lineupSet === false || m.phase === 'awaitingReply').length
                  : s.id === 'teams' ? teams.reduce((a, x) => a + (x.pending || 0), 0)
                  : tours.reduce((a, x) => a + (x.needs || 0), 0);
                return (
                  <button key={s.id} onClick={() => { setSeg(s.id); scrollRef.current && (scrollRef.current.scrollTop = 0); }} style={{
                    flex: 1, padding: '8px 0', borderRadius: 8, cursor: 'pointer', fontFamily: 'inherit',
                    background: on ? paper : 'transparent', border: 'none',
                    boxShadow: on ? '0 1px 3px rgba(40,30,15,0.10)' : 'none',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                  }}>
                    <span style={{ fontSize: 12.5, fontWeight: on ? 700 : 600, color: on ? ink : muted }}>{s.l}</span>
                    {badge > 0 && <span style={{ ...mono, fontSize: 8.5, minWidth: 15, padding: '1px 4px', borderRadius: 999, background: on ? amber : 'transparent', color: on ? 'oklch(0.30 0.02 80)' : muted }}>{badge}</span>}
                  </button>
                );
              })}
            </div>
          </div>

          {/* scroll body */}
          <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', minHeight: 0, paddingTop: 10 }}>
            {showOverview && seg === 'matches' && <Overview matches={matches} teams={teams} tournaments={tours} onAction={onMatchAction} onSegment={setSeg} />}
            {seg === 'matches' && <MatchesLane matches={matches} onOpen={(m) => setOpenMatchId(m.id)} onCreate={() => setSendOpen(true)} hideIds={showOverview ? heroIds : []} />}
            {seg === 'teams' && <TeamsLane teams={teams} onOpen={(tm) => flash('Opening ' + D.CRESTS[tm.crest].name + '…')} onAction={(id, a, n) => flash(n || 'Resolving…')} onCreate={() => flash('Opening team setup…')} />}
            {seg === 'tournaments' && <ToursLane tournaments={tours} onOpen={(tr) => flash('Opening ' + tr.name + '…')} onAction={() => flash('Opening fixture scheduler…')} onCreate={() => flash('Opening tournament setup…')} />}
            <div style={{ height: 84 }} />
          </div>

          {/* context-aware Create FAB */}
          <div style={{ position: 'absolute', right: 16, bottom: 18, zIndex: 30 }}>
            <button onClick={onCreate} style={{ height: 44, padding: '0 18px 0 16px', borderRadius: 999, border: 'none', background: ink, color: paper, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 8, fontFamily: 'inherit', fontWeight: 700, fontSize: 14, boxShadow: '0 8px 22px -6px rgba(20,18,14,0.45)' }}>
              <Icon name="plus" size={18} stroke={paper} sw={2.4} />{activeSeg.create}
            </button>
          </div>

          {/* toast */}
          {toast && (
            <div style={{ position: 'absolute', left: 16, right: 16, bottom: 74, padding: '13px 16px', borderRadius: 14, background: ink, color: paper, display: 'flex', alignItems: 'center', gap: 10, boxShadow: '0 8px 28px rgba(20,18,14,0.28)', zIndex: 35, animation: 'ch-pop 0.3s cubic-bezier(0.22,1,0.36,1)' }}>
              <Icon name="check" size={16} stroke={paper} sw={2.6} /><span style={{ fontSize: 13, fontWeight: 600 }}>{toast}</span>
            </div>
          )}

          {/* match detail overlay */}
          {openMatch && (
            <SlideOver zIndex={70}>
              <MatchDetail m={openMatch} onBack={() => setOpenMatchId(null)} onAction={onMatchAction} />
            </SlideOver>
          )}

          {/* account */}
          {account && (
            <SlideOver zIndex={75}>
              <Account onClose={() => setAccount(false)} onToast={(m) => flash(m)} bare />
            </SlideOver>
          )}

          {/* send challenge overlay */}
          {sendOpen && (
            <SlideOver zIndex={80}>
              <window.SendChallenge teamsCount={3} squadSize={18} preTeamId="t_ll" onExit={() => setSendOpen(false)} onSent={onSent} />
            </SlideOver>
          )}
        </div>
  );
}
window.PavilionBody = PavilionBody;

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  return (
    <React.Fragment>
      <Stage><PavilionBody scenario={t.scenario} overview={t.overview} /></Stage>
      <TweaksPanel>
        <TweakSection label="Scenario" />
        <TweakRadio label="Day" value={t.scenario} options={['Match day', 'Quiet day', 'New user']} onChange={(v) => setTweak('scenario', v)} />
        <div style={{ fontSize: 11, color: '#9a958c', padding: '2px 2px 8px', lineHeight: 1.45 }}>
          Cards are status-only — tap any match to open its detail page. “New user” shows the empty states for each tab.
        </div>
        <TweakSection label="Layout" />
        <TweakToggle label="Show Today overview" value={t.overview} onChange={(v) => setTweak('overview', v)} />
      </TweaksPanel>
    </React.Fragment>
  );
}

function Stage({ children }) {
  const [scale, setScale] = useState(1);
  const W = 402, H = 874;
  useEffect(() => {
    const fit = () => { const pad = window.innerWidth < 560 ? 16 : 48; setScale(Math.min(1, (window.innerWidth - pad) / W, (window.innerHeight - pad) / H)); };
    fit(); window.addEventListener('resize', fit); return () => window.removeEventListener('resize', fit);
  }, []);
  return (
    <div style={{ position: 'fixed', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--stage-bg)' }}>
      <div style={{ transform: `scale(${scale})`, transformOrigin: 'center center' }}>
        <IOSDevice width={W} height={H}>{children}</IOSDevice>
      </div>
    </div>
  );
}

// Slide-up overlay driven by state + CSS transition (not a one-shot keyframe),
// so the panel can never get stuck off-screen if a render interrupts it.
// Overlay container. Rendered visible by default (no transform/animation gating)
// so the panel can never be stuck off-screen — robust to re-renders, remounts,
// and paused-paint (headless/background) contexts.
function SlideOver({ zIndex, children }) {
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex, background: 'var(--paper)' }}>
      {children}
    </div>
  );
}

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "scenario": "Match day",
  "overview": true
}/*EDITMODE-END*/;

window.PavilionAppV2 = App;

})();

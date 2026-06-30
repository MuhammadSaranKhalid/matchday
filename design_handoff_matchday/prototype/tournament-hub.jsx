// tournament-hub.jsx — Tournament Hub for the main prototype.
// window.TournamentHub({ sample:'league'|'knockout'|'hybrid', role:'organizer'|'participant', onBack, flash })

(function () {
const { useState } = React;
const C = {
  ink:'var(--ink)', ink2:'var(--ink-2)', muted:'var(--muted)', soft:'var(--soft)',
  paper:'var(--paper)', paper2:'var(--paper-2)', surface:'var(--surface)', hair:'var(--hairline)', line:'var(--line)',
  red:'var(--red)', redSoft:'var(--red-soft)', green:'var(--green)', greenSoft:'var(--green-soft)', greenInk:'var(--green-ink)',
  amber:'var(--amber)', amberInk:'var(--amber-ink)', cream:'var(--cream)',
  gold:'oklch(0.74 0.12 85)', goldSoft:'oklch(0.93 0.06 88)', goldInk:'oklch(0.50 0.10 80)',
};
const display = (s, w=700) => ({ fontFamily:'Inter Tight, system-ui', fontSize:s, fontWeight:w, letterSpacing:'-0.025em', color:C.ink, lineHeight:1.1 });
const mono = { fontFamily:'JetBrains Mono, monospace', fontWeight:700, letterSpacing:'0.10em', textTransform:'uppercase' };
const PATHS = {
  back:'<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>', next:'<path d="M9 18l6-6-6-6"/>',
  dots:'<circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/>',
  trophy:'<path d="M6 4h12v4a6 6 0 0 1-12 0z"/><path d="M6 6H3v2a3 3 0 0 0 3 3M18 6h3v2a3 3 0 0 1-3 3M9 20h6M12 14v6"/>',
  users:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
  cal:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  check:'<polyline points="20 6 9 17 4 12"/>', pencil:'<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',
  bell:'<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>',
  money:'<circle cx="12" cy="12" r="9"/><path d="M14.5 9.5a2.5 2.5 0 0 0-2.5-1.5c-1.4 0-2.5.8-2.5 2s1.1 1.8 2.5 2 2.5.8 2.5 2-1.1 2-2.5 2a2.5 2.5 0 0 1-2.5-1.5M12 6.5v11"/>',
  whistle:'<circle cx="9" cy="14" r="6"/><path d="M15 12l7-3-1 4-6 1M9 14h.01"/>',
  plus:'<path d="M12 5v14M5 12h14"/>', close:'<path d="M6 6l12 12M18 6L6 18"/>', clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  pin:'<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>', share:'<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>', trash:'<path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14"/>',
};
function Icon({ name, size=18, stroke='currentColor', sw=2, style }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{__html:PATHS[name]||''}} />;
}
function Crest({ size=44, bg, fg=C.paper, label, radius }) {
  return <div style={{ width:size, height:size, borderRadius:radius!=null?radius:size*0.24, flexShrink:0, background:bg, color:fg, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:size*0.36, letterSpacing:'-0.03em' }}>{label}</div>;
}
const TONE = {
  progress:{ bg:C.greenSoft, fg:C.greenInk, dot:C.green },
  registration:{ bg:C.cream, fg:C.amberInk, dot:C.amber },
  upcoming:{ bg:C.paper2, fg:C.ink2, dot:C.muted },
  completed:{ bg:C.paper2, fg:C.muted, dot:C.soft },
};
function StatusPill({ status, label }) {
  const t = TONE[status] || TONE.upcoming;
  return <span style={{ ...mono, fontSize:9, padding:'4px 9px', borderRadius:999, background:t.bg, color:t.fg, display:'inline-flex', alignItems:'center', gap:5 }}><span style={{ width:5, height:5, borderRadius:999, background:t.dot }} />{label}</span>;
}
function SecH({ children, side }) {
  return <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', padding:'18px 2px 9px' }}><span style={{ ...mono, fontSize:10, color:C.muted }}>{children}</span>{side && <span style={{ fontSize:11, color:C.muted }}>{side}</span>}</div>;
}

const T = {
  LL:{ short:'LL', name:'Lyari Lions', color:'oklch(0.62 0.19 28)' },
  KE:{ short:'KE', name:'Karsaz Eagles', color:'oklch(0.55 0.13 250)' },
  MB:{ short:'MB', name:'Malir Blasters', color:'oklch(0.56 0.13 148)' },
  NN:{ short:'NN', name:'Nazimabad XI', color:'oklch(0.55 0.17 305)' },
  SC:{ short:'SC', name:'Saddar CC', color:'oklch(0.62 0.14 55)' },
  GG:{ short:'GG', name:'Gulshan Galacticos', color:'oklch(0.52 0.10 200)' },
  DC:{ short:'DC', name:'Defence Chargers', color:'oklch(0.46 0.13 18)' },
  KT:{ short:'KT', name:'Korangi Titans', color:'oklch(0.42 0.07 285)' },
};
const TBD = { short:'?', name:'To be decided', color:'oklch(0.86 0.01 85)', fg:'var(--soft)', tbd:true };
const seed = (k, label) => ({ ...(T[k]||TBD), seedLabel:label });

// pending team registrations (open-entry tournaments)
const REQUESTS = [
  { id:'rq1', short:'DC', name:'Defence Chargers', color:'oklch(0.46 0.13 18)', captain:'Wajahat Ali', when:'2h ago', players:13 },
  { id:'rq2', short:'KT', name:'Korangi Titans', color:'oklch(0.42 0.07 285)', captain:'Bilal Pirzada', when:'5h ago', players:11 },
  { id:'rq3', short:'OB', name:'Old Boys XI', color:'oklch(0.36 0.04 80)', captain:'Saad Anwar', when:'Yesterday', players:15 },
];

const SAMPLES = {
  league: { name:'Karachi Sunday League', mono:'KSL', color:'oklch(0.62 0.19 28)', structureLabel:'League · round-robin', format:'T20',
    status:'progress', statusLabel:'IN PROGRESS', stage:'Matchday 4 of 5', teamsCount:6, dates:'6 Apr – 11 May', structure:'league', standTab:'Table', leaderNote:'Top of the table takes the title', highlight:1, venue:'Multiple grounds',
    table:[ {...T.LL,p:4,w:4,l:0,nr:0,pts:8,nrr:'+1.24'},{...T.MB,p:4,w:3,l:1,nr:0,pts:6,nrr:'+0.62'},{...T.KE,p:4,w:2,l:2,nr:0,pts:4,nrr:'+0.10'},{...T.SC,p:4,w:2,l:2,nr:0,pts:4,nrr:'-0.20'},{...T.GG,p:4,w:1,l:3,nr:0,pts:2,nrr:'-0.55'},{...T.NN,p:4,w:0,l:4,nr:0,pts:0,nrr:'-1.30'} ],
    fixtures:[ {round:'Matchday 4',a:T.LL,b:T.NN,sa:'171/6',sb:'148',res:'a',sub:'LL won by 23 runs',venue:'KMC Ground',phase:'completed'},{round:'Matchday 4',a:T.MB,b:T.GG,sa:'142/8',sb:'139/9',res:'a',sub:'MB won by 3 runs',venue:'Aga Khan Gym',phase:'completed'},{round:'Matchday 5',a:T.KE,b:T.SC,when:'Sun 10:00',venue:'KMC Ground',phase:'upcoming'},{round:'Matchday 5',a:T.LL,b:T.MB,when:'Sun 14:00',venue:'KMC Ground',phase:'upcoming'} ],
    teams:['LL','MB','KE','SC','GG','NN'] },
  knockout: { name:'Ramzan Night Cup', mono:'RNC', color:'oklch(0.55 0.17 305)', structureLabel:'Knockout · 8 teams', format:'Tape-ball T10',
    status:'progress', statusLabel:'IN PROGRESS', stage:'Semi-finals', teamsCount:8, dates:'18 – 27 Mar', structure:'knockout', standTab:'Bracket', venue:'Liaquatabad floodlights',
    rounds:[ {name:'Quarter-finals',matches:[{a:T.LL,b:T.KT,sa:'92/4',sb:'71',win:'a',phase:'completed'},{a:T.MB,b:T.SC,sa:'88/6',sb:'85/8',win:'a',phase:'completed'},{a:T.KE,b:T.GG,sa:'104/3',sb:'99/7',win:'a',phase:'completed'},{a:T.NN,b:T.DC,sa:'77/9',sb:'78/2',win:'b',phase:'completed'}]},
      {name:'Semi-finals',matches:[{a:T.LL,b:T.MB,sa:'96/5',sb:'90',win:'a',phase:'completed'},{a:T.KE,b:T.DC,when:'Sat 21:30',phase:'upcoming'}]},
      {name:'Final',matches:[{a:T.LL,b:seed(null,'Winner SF2'),when:'Sun 22:00',phase:'upcoming'}]} ],
    teams:['LL','MB','KE','SC','GG','NN','DC','KT'] },
  done: { name:'Winter Smash', mono:'WS', color:'oklch(0.55 0.17 305)', structureLabel:'Knockout · 8 teams', format:'Tape-ball T10',
    status:'completed', statusLabel:'COMPLETED', stage:'Champions: Lyari Lions', teamsCount:8, dates:'18 – 27 Mar', structure:'knockout', standTab:'Bracket', venue:'Liaquatabad floodlights', champion:'LL',
    rounds:[ {name:'Quarter-finals',matches:[{a:T.LL,b:T.KT,sa:'92/4',sb:'71',win:'a',phase:'completed'},{a:T.MB,b:T.SC,sa:'88/6',sb:'85/8',win:'a',phase:'completed'},{a:T.KE,b:T.GG,sa:'104/3',sb:'99/7',win:'a',phase:'completed'},{a:T.NN,b:T.DC,sa:'77/9',sb:'78/2',win:'b',phase:'completed'}]},
      {name:'Semi-finals',matches:[{a:T.LL,b:T.MB,sa:'96/5',sb:'90',win:'a',phase:'completed'},{a:T.KE,b:T.DC,sa:'81/9',sb:'112/4',win:'b',phase:'completed'}]},
      {name:'Final',matches:[{a:T.LL,b:T.DC,sa:'134/4',sb:'90',win:'a',phase:'completed'}]} ],
    teams:['LL','MB','KE','SC','GG','NN','DC','KT'],
    awards:{ champion:{...T.LL, note:'Beat Defence Chargers by 44 runs'}, runner:{...T.DC}, third:{...T.KE, note:'Beat Malir Blasters in the 3rd-place playoff'},
      players:[ {role:'PLAYER OF THE TOURNAMENT', name:'Bilal Ahmed', team:T.LL, stat:'241 runs · 7 wkts'},
        {role:'TOP RUN-SCORER', name:'Asad Raza', team:T.KE, stat:'276 runs · avg 69'},
        {role:'TOP WICKET-TAKER', name:'Imran Shah', team:T.DC, stat:'14 wickets · econ 5.2'} ] } },
  hybrid: { name:'City Champions Trophy', mono:'CCT', color:'oklch(0.56 0.13 148)', structureLabel:'Groups → Knockout · 8 teams', format:'8-a-side',
    status:'progress', statusLabel:'IN PROGRESS', stage:'Knockout · semi-finals', teamsCount:8, dates:'2 – 16 Feb', structure:'hybrid', standTab:'Standings', advance:2, venue:'DHA Sports Complex',
    groups:[ {name:'Group A',table:[{...T.LL,p:3,w:3,l:0,nr:0,pts:6,nrr:'+1.05'},{...T.KE,p:3,w:2,l:1,nr:0,pts:4,nrr:'+0.40'},{...T.SC,p:3,w:1,l:2,nr:0,pts:2,nrr:'-0.32'},{...T.KT,p:3,w:0,l:3,nr:0,pts:0,nrr:'-1.10'}]},
      {name:'Group B',table:[{...T.MB,p:3,w:3,l:0,nr:0,pts:6,nrr:'+0.88'},{...T.NN,p:3,w:2,l:1,nr:0,pts:4,nrr:'+0.21'},{...T.GG,p:3,w:1,l:2,nr:0,pts:2,nrr:'-0.44'},{...T.DC,p:3,w:0,l:3,nr:0,pts:0,nrr:'-0.95'}]} ],
    rounds:[ {name:'Semi-finals',matches:[{a:seed('LL','A1'),b:seed('NN','B2'),when:'Sat 15:00',phase:'upcoming'},{a:seed('MB','B1'),b:seed('KE','A2'),when:'Sat 17:30',phase:'upcoming'}]},
      {name:'Final',matches:[{a:seed(null,'Winner SF1'),b:seed(null,'Winner SF2'),when:'Sun 16:00',phase:'upcoming'}]} ],
    teams:['LL','KE','SC','KT','MB','NN','GG','DC'] },
};

function PointsTable({ rows, highlight, advance, compact }) {
  const cols = compact ? ['P','W','L','Pts'] : ['P','W','L','NR','Pts'];
  return (
    <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, padding:'8px 12px', background:C.paper2, borderBottom:'1px solid '+C.hair }}>
        <span style={{ width:18, ...mono, fontSize:8.5, color:C.muted }}>#</span>
        <span style={{ flex:1, ...mono, fontSize:8.5, color:C.muted }}>TEAM</span>
        {cols.map(c => <span key={c} style={{ width:c==='Pts'?26:20, textAlign:'center', ...mono, fontSize:8.5, color:c==='Pts'?C.ink2:C.muted }}>{c}</span>)}
        {!compact && <span style={{ width:42, textAlign:'right', ...mono, fontSize:8.5, color:C.muted }}>NRR</span>}
      </div>
      {rows.map((r,i) => {
        const qual = advance!=null && i < advance; const lead = highlight!=null && i <= highlight;
        return (
          <React.Fragment key={r.short+i}>
            <div style={{ display:'flex', alignItems:'center', gap:10, padding:'9px 12px', borderTop:i?'1px solid '+C.hair:'none', background:qual?C.greenSoft:'transparent' }}>
              <span style={{ width:18, textAlign:'center', fontFamily:'JetBrains Mono', fontWeight:700, fontSize:11, color:(qual||lead)?C.greenInk:C.muted, fontVariantNumeric:'tabular-nums' }}>{i+1}</span>
              <Crest size={22} bg={r.color} label={r.short} radius={7} />
              <span style={{ flex:1, minWidth:0, fontFamily:'Inter Tight', fontWeight:700, fontSize:12.5, letterSpacing:'-0.01em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{r.name}</span>
              {cols.map(c => { const v = c==='P'?r.p:c==='W'?r.w:c==='L'?r.l:c==='NR'?r.nr:r.pts; return <span key={c} style={{ width:c==='Pts'?26:20, textAlign:'center', fontFamily:'JetBrains Mono', fontWeight:c==='Pts'?700:600, fontSize:c==='Pts'?12.5:11, color:c==='Pts'?C.ink:C.ink2, fontVariantNumeric:'tabular-nums' }}>{v}</span>; })}
              {!compact && <span style={{ width:42, textAlign:'right', fontFamily:'JetBrains Mono', fontWeight:500, fontSize:10.5, color:C.muted, fontVariantNumeric:'tabular-nums' }}>{r.nrr}</span>}
            </div>
            {advance!=null && i===advance-1 && (
              <div style={{ display:'flex', alignItems:'center', gap:7, padding:'3px 12px', background:'oklch(0.97 0.02 148)' }}>
                <span style={{ flex:1, height:1, background:C.green, opacity:0.4 }} /><span style={{ ...mono, fontSize:7.5, color:C.greenInk }}>QUALIFY</span><span style={{ flex:1, height:1, background:C.green, opacity:0.4 }} />
              </div>
            )}
          </React.Fragment>
        );
      })}
    </div>
  );
}
function BracketMatch({ m, w }) {
  const decided = m.win != null;
  const row = (team, score, win, top) => (
    <div style={{ display:'flex', alignItems:'center', gap:7, padding:'6px 8px', background:win?C.greenSoft:'transparent', borderTop:top?'none':'1px solid '+C.hair }}>
      <Crest size={18} bg={team.color} fg={team.fg||C.paper} label={team.short} radius={5} />
      <span style={{ flex:1, minWidth:0, fontFamily:'Inter Tight', fontWeight:700, fontSize:11, letterSpacing:'-0.01em', color:team.tbd?C.soft:(win===false?C.muted:C.ink), whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{team.tbd?team.seedLabel:team.short}</span>
      {win && <Icon name="check" size={11} stroke={C.greenInk} sw={2.8} style={{ flexShrink:0 }} />}
      <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:11, color:score?C.ink:C.soft, fontVariantNumeric:'tabular-nums' }}>{score||'–'}</span>
    </div>
  );
  return (
    <div style={{ width:w, border:'1px solid '+C.hair, borderRadius:10, overflow:'hidden', background:C.paper, position:'relative', zIndex:2 }}>
      {row(m.a, m.sa, decided?m.win==='a':undefined, true)}{row(m.b, m.sb, decided?m.win==='b':undefined, false)}
      <div style={{ padding:'4px 8px', borderTop:'1px solid '+C.hair, background:C.paper2 }}><span style={{ ...mono, fontSize:7.5, color:m.phase==='completed'?C.greenInk:C.muted }}>{m.phase==='completed'?'FINAL':(m.when||'TBD')}</span></div>
    </div>
  );
}
// elbow connectors drawn in the gap to the right of each card
function Connectors({ isTop, last, cardW, gap }) {
  if (last) return null;
  const spine = cardW + gap/2, lc = C.line;
  return (
    <>
      <div style={{ position:'absolute', left:cardW, top:'50%', width:gap/2, height:2, background:lc, transform:'translateY(-1px)' }} />
      {isTop
        ? <div style={{ position:'absolute', left:spine-1, top:'50%', bottom:0, width:2, background:lc }} />
        : <div style={{ position:'absolute', left:spine-1, top:0, bottom:'50%', width:2, background:lc }} />}
      {isTop && <div style={{ position:'absolute', left:spine-1, bottom:0, width:gap/2+1, height:2, background:lc, transform:'translateY(1px)' }} />}
    </>
  );
}
function Bracket({ rounds }) {
  const CARDW = 140, GAP = 30, ROWH = 116;
  const h = (rounds[0]?.matches.length || 1) * ROWH;
  return (
    <div style={{ overflowX:'auto', padding:'4px 2px 14px', WebkitOverflowScrolling:'touch' }}>
      <div style={{ display:'flex', width:'max-content' }}>
        {rounds.map((rd, ri) => {
          const last = ri === rounds.length - 1;
          return (
            <div key={rd.name} style={{ display:'flex', flexDirection:'column', width: last ? CARDW : CARDW + GAP }}>
              <div style={{ ...mono, fontSize:9, color:C.muted, textAlign:'center', marginBottom:6 }}>{rd.name}</div>
              <div style={{ display:'flex', flexDirection:'column', height:h }}>
                {rd.matches.map((m, mi) => (
                  <div key={mi} style={{ flex:1, display:'flex', alignItems:'center', position:'relative' }}>
                    <BracketMatch m={m} w={CARDW} />
                    <Connectors isTop={mi % 2 === 0} last={last} cardW={CARDW} gap={GAP} />
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
function FixtureCard({ f }) {
  const done = f.phase === 'completed';
  return (
    <div style={{ borderRadius:14, border:'1px solid '+C.hair, background:C.paper, overflow:'hidden', marginBottom:9 }}>
      <div style={{ display:'flex', alignItems:'center', gap:8, padding:'9px 12px 0' }}><StatusPill status={done?'completed':'upcoming'} label={done?'PLAYED':'UPCOMING'} /><span style={{ ...mono, fontSize:9, color:C.muted, marginLeft:'auto' }}>{done?'':f.when}</span></div>
      {done ? (<>
        <div style={{ height:6 }} />
        {[[f.a,f.sa,f.res==='a'],[f.b,f.sb,f.res==='b']].map(([t,s,win],i)=>(
          <div key={i} style={{ display:'flex', alignItems:'center', gap:10, padding:'7px 12px', borderTop:i?'1px solid '+C.hair:'none', background:win?C.greenSoft:'transparent' }}>
            <Crest size={24} bg={t.color} label={t.short} radius={7} /><span style={{ flex:1, minWidth:0, fontFamily:'Inter Tight', fontWeight:700, fontSize:12.5, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{t.name}</span>{win && <Icon name="check" size={13} stroke={C.greenInk} sw={2.6} />}<span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:13.5, color:C.ink, fontVariantNumeric:'tabular-nums' }}>{s}</span>
          </div>
        ))}
        <div style={{ padding:'8px 12px', borderTop:'1px solid '+C.hair }}><span style={{ fontSize:11, color:C.muted }}>{f.sub} · {f.venue}</span></div>
      </>) : (
        <div style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 12px 13px' }}>
          <div style={{ display:'flex', alignItems:'center' }}><Crest size={34} bg={f.a.color} label={f.a.short} radius={9} /><div style={{ marginLeft:-8, border:'2px solid '+C.paper, borderRadius:11 }}><Crest size={34} bg={f.b.color} label={f.b.short} radius={9} /></div></div>
          <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.02em' }}>{f.a.short} vs {f.b.short}</div><div style={{ fontSize:11, color:C.muted, marginTop:2, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{f.venue}</div></div>
          <Icon name="next" size={16} stroke={C.soft} sw={2} />
        </div>
      )}
    </div>
  );
}
function StandingsTab({ t }) {
  if (t.structure === 'league') return <div style={{ padding:'14px 18px 8px' }}><PointsTable rows={t.table} highlight={t.highlight} /><div style={{ display:'flex', alignItems:'center', gap:7, marginTop:11, padding:'10px 12px', borderRadius:11, background:C.goldSoft }}><Icon name="trophy" size={15} stroke={C.goldInk} sw={2} /><span style={{ fontSize:11.5, color:C.ink2 }}>{t.leaderNote}</span></div></div>;
  if (t.structure === 'knockout') return <div style={{ padding:'10px 6px 8px' }}><Bracket rounds={t.rounds} /></div>;
  return <div style={{ padding:'6px 18px 8px' }}>{t.groups.map(g => <div key={g.name}><SecH side="Top 2 advance">{g.name}</SecH><PointsTable rows={g.table} advance={t.advance} compact /></div>)}<SecH side="Cross-paired from groups">Knockout</SecH><div style={{ margin:'0 -18px' }}><Bracket rounds={t.rounds} /></div></div>;
}
function FixturesTab({ t }) {
  let list = [];
  if (t.fixtures) list = t.fixtures;
  else (t.rounds||[]).forEach(rd => rd.matches.forEach(m => list.push({ round:rd.name, a:m.a, b:m.b, sa:m.sa, sb:m.sb, res:m.win, when:m.when, sub:(m.win?(m.win==='a'?m.a.short:m.b.short)+' won':''), venue:t.venue, phase:m.phase })));
  const groups = {}; list.forEach(f => { (groups[f.round]=groups[f.round]||[]).push(f); });
  return <div style={{ padding:'8px 18px 8px' }}>{Object.keys(groups).map(rn => <div key={rn}><SecH>{rn}</SecH>{groups[rn].map((f,i)=><FixtureCard key={i} f={f} />)}</div>)}</div>;
}
function TeamsTab({ t }) {
  return <div style={{ padding:'8px 18px 8px' }}><SecH side={t.teamsCount+' teams'}>Participants</SecH>
    <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
      {t.teams.map((k,i) => { const tm=T[k]; return (
        <div key={k} style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 13px', borderTop:i?'1px solid '+C.hair:'none' }}>
          <Crest size={32} bg={tm.color} label={tm.short} radius={9} /><div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5 }}>{tm.name}</div><div style={{ fontSize:10.5, color:C.muted, marginTop:1 }}>11 players</div></div><Icon name="next" size={16} stroke={C.soft} sw={2} />
        </div>
      );})}
    </div>
  </div>;
}
function ManageTab({ t, draft, state, pending, onOpen, flash }) {
  const rows = state==='draft' ? [
    { k:'teams', ic:'users', l:'Add teams', s:'Share your code or invite teams to enter', badge:pending },
    { k:'settings', ic:'whistle', l:'Tournament settings', s:'Format, dates, registration & visibility' },
  ] : state==='registration' ? [
    { k:'requests', ic:'bell', l:'Join requests', s:'Teams asking to enter — approve or decline', badge:pending },
    { k:'teams', ic:'users', l:'Manage teams', s:'Mark paid or remove confirmed teams' },
    { k:'settings', ic:'whistle', l:'Tournament settings', s:'Close registration, edit dates & fee' },
  ] : state==='ready' ? [
    { k:'gendraw', ic:'trophy', l:'Generate draw', s:'Seed the bracket from confirmed teams' },
    { k:'teams', ic:'users', l:'Manage teams', s:'Review the 8 confirmed entrants' },
    { k:'settings', ic:'whistle', l:'Tournament settings', s:'Format, dates & visibility' },
  ] : [
    { k:'result', ic:'pencil', l:'Enter a result', s:'Record runs, wickets & overs for a fixture' },
    { k:'schedule', ic:'cal', l:'Schedule fixtures', s:'Set dates, times and grounds' },
    { k:'teams', ic:'users', l:'Manage teams', s:'Seed or remove participating teams' },
    { k:'update', ic:'whistle', l:'Post an update', s:'Share news with everyone following the cup' },
    { k:'fee', ic:'money', l:'Entry & prize pool', s:'Track who has paid — settled off-app' },
  ];
  const opens = { requests:1, teams:1, result:1, gendraw:1, schedule:1, settings:1, update:1, fee:1 };
  return <div style={{ padding:'8px 18px 8px' }}>
    <div style={{ display:'flex', alignItems:'center', gap:7, margin:'6px 0 12px', padding:'9px 11px', borderRadius:11, background:draft?C.cream:C.paper2 }}><Icon name="whistle" size={15} stroke={draft?C.amberInk:C.ink2} sw={2} /><span style={{ fontSize:11.5, color:draft?C.amberInk:C.ink2 }}>{state==='draft' ? <>This cup is a <b style={{color:C.amberInk}}>Draft</b> — add teams to begin.</> : state==='registration' ? <>Registration is <b style={{color:C.amberInk}}>open</b> — approve teams, then generate the draw.</> : state==='ready' ? <>All teams are <b style={{color:C.amberInk}}>in</b> — generate the draw to go live.</> : <>You're the <b style={{color:C.ink}}>organizer</b> of this tournament.</>}</span></div>
    <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
      {rows.map((r,i)=>(
        <div key={r.k} onClick={()=> opens[r.k] ? onOpen(r.k) : flash&&flash(r.l)} style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 13px', borderTop:i?'1px solid '+C.hair:'none', cursor:'pointer' }}>
          <div style={{ width:34, height:34, borderRadius:10, background:C.paper2, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Icon name={r.ic} size={17} stroke={C.ink} sw={2} /></div>
          <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5 }}>{r.l}</div><div style={{ fontSize:11, color:C.muted, marginTop:1, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{r.s}</div></div>
          {r.badge>0 && <span style={{ minWidth:20, height:20, padding:'0 6px', borderRadius:999, background:C.red, color:'#fff', fontFamily:'Inter Tight', fontWeight:700, fontSize:11, display:'flex', alignItems:'center', justifyContent:'center' }}>{r.badge}</span>}
          <Icon name="next" size={16} stroke={C.soft} sw={2} />
        </div>
      ))}
    </div>
  </div>;
}

function SubHeader({ title, sub, onBack, right }) {
  return <div style={{ flexShrink:0, borderBottom:'1px solid '+C.hair, background:C.paper }}>
    <div style={{ height:44 }} />
    <div style={{ padding:'2px 12px 12px', display:'flex', alignItems:'center', gap:8 }}>
      <button onClick={onBack} aria-label="Back" style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:C.ink }}><Icon name="back" size={20} stroke={C.ink} sw={2} /></button>
      <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:18, letterSpacing:'-0.02em' }}>{title}</div>{sub && <div style={{ fontSize:11.5, color:C.muted, marginTop:1 }}>{sub}</div>}</div>
      {right}
    </div>
  </div>;
}

function RequestsScreen({ t, onBack, flash }) {
  const [reqs, setReqs] = useState(REQUESTS);
  const [done, setDone] = useState({});
  const act = (r, kind) => { setDone(d=>({ ...d, [r.id]:kind })); flash && flash(kind==='accepted' ? r.name+' added to the cup' : r.name+' declined'); setTimeout(()=>setReqs(rs=>rs.filter(x=>x.id!==r.id)), 650); };
  const pending = reqs.filter(r=>!done[r.id]);
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Join requests" sub={`${pending.length} pending · open registration`} onBack={onBack} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'12px 18px' }}>
      {reqs.length===0 ? (
        <div style={{ textAlign:'center', padding:'56px 24px', color:C.muted }}>
          <div style={{ width:56, height:56, borderRadius:16, background:C.paper2, display:'flex', alignItems:'center', justifyContent:'center', margin:'0 auto 14px' }}><Icon name="check" size={24} stroke={C.green} sw={2.4} /></div>
          <div style={{ ...display(16), color:C.ink }}>All caught up</div>
          <div style={{ fontSize:12.5, marginTop:6, lineHeight:1.5 }}>No pending requests. New ones land here as captains apply with your join code.</div>
        </div>
      ) : reqs.map(r => {
        const st = done[r.id];
        return <div key={r.id} style={{ border:'1px solid '+C.hair, borderRadius:14, padding:13, marginBottom:10, background:C.paper, opacity:st?0.6:1, transition:'opacity .2s' }}>
          <div style={{ display:'flex', alignItems:'center', gap:11 }}>
            <Crest size={42} bg={r.color} label={r.short} radius={12} />
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14.5, letterSpacing:'-0.01em' }}>{r.name}</div>
              <div style={{ fontSize:11.5, color:C.muted, marginTop:2 }}>Captain {r.captain} · {r.players} players · {r.when}</div>
            </div>
          </div>
          {st ? (
            <div style={{ ...mono, fontSize:9, color:st==='accepted'?C.greenInk:C.muted, marginTop:11, display:'flex', alignItems:'center', gap:6 }}><Icon name={st==='accepted'?'check':'close'} size={13} stroke={st==='accepted'?C.greenInk:C.muted} sw={2.4} />{st==='accepted'?'ADDED TO TOURNAMENT':'DECLINED'}</div>
          ) : (
            <div style={{ display:'flex', gap:8, marginTop:12 }}>
              <button onClick={()=>act(r,'declined')} style={{ flex:1, padding:'10px 0', borderRadius:11, border:'1px solid '+C.line, background:C.paper, color:C.ink, fontFamily:'inherit', fontWeight:600, fontSize:13, cursor:'pointer' }}>Decline</button>
              <button onClick={()=>act(r,'accepted')} style={{ flex:2, padding:'10px 0', borderRadius:11, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:13, cursor:'pointer', display:'inline-flex', alignItems:'center', justifyContent:'center', gap:7 }}><Icon name="check" size={15} stroke={C.paper} sw={2.4} />Accept</button>
            </div>
          )}
        </div>;
      })}
      <div style={{ height:20 }} />
    </div>
  </div>;
}

function ManageTeamsScreen({ t, pending, onBack, onRequests, flash }) {
  const [teams, setTeams] = useState(t.teams.slice());
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Manage teams" sub={`${teams.length} entrants`} onBack={onBack}
      right={<button onClick={()=>flash&&flash('Invite team — share code')} style={{ height:32, padding:'0 12px', borderRadius:10, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:12, cursor:'pointer', display:'inline-flex', alignItems:'center', gap:6, flexShrink:0 }}><Icon name="plus" size={14} stroke={C.paper} sw={2.4} />Invite</button>} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'12px 18px' }}>
      {pending>0 && (
        <div onClick={onRequests} style={{ display:'flex', alignItems:'center', gap:11, padding:'12px 13px', borderRadius:13, border:'1px solid '+C.hair, background:C.cream, cursor:'pointer', marginBottom:14 }}>
          <div style={{ width:34, height:34, borderRadius:10, background:C.paper, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Icon name="bell" size={16} stroke={C.amberInk} sw={2} /></div>
          <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5, color:C.amberInk }}>{pending} team{pending>1?'s':''} waiting to join</div><div style={{ fontSize:11, color:C.amberInk, opacity:0.8, marginTop:1 }}>Review join requests</div></div>
          <Icon name="next" size={16} stroke={C.amberInk} sw={2} />
        </div>
      )}
      <div style={{ ...mono, fontSize:10, color:C.muted, padding:'0 2px 9px' }}>ENTRANTS</div>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
        {teams.map((k,i) => { const tm=T[k]; return (
          <div key={k} style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 13px', borderTop:i?'1px solid '+C.hair:'none' }}>
            <span style={{ ...mono, fontSize:10, color:C.soft, width:16 }}>{i+1}</span>
            <Crest size={32} bg={tm.color} label={tm.short} radius={9} />
            <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5 }}>{tm.name}</div><div style={{ fontSize:10.5, color:C.muted, marginTop:1 }}>11 players · confirmed</div></div>
            <button onClick={()=>{ setTeams(ts=>ts.filter(x=>x!==k)); flash&&flash(tm.name+' removed'); }} aria-label="Remove" style={{ width:30, height:30, borderRadius:8, border:'none', background:'none', cursor:'pointer', color:C.soft, display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="trash" size={16} stroke={C.muted} sw={2} /></button>
          </div>
        );})}
      </div>
      <div style={{ height:20 }} />
    </div>
  </div>;
}

function EnterResultScreen({ t, onBack, flash }) {
  const ups = [];
  if (t.fixtures) t.fixtures.forEach(f=>{ if(f.phase==='upcoming') ups.push({ a:f.a, b:f.b, round:f.round }); });
  else (t.rounds||[]).forEach(rd=>rd.matches.forEach(m=>{ if(m.phase==='upcoming' && !m.a.tbd && !m.b.tbd) ups.push({ a:m.a, b:m.b, round:rd.name }); }));
  const [pick, setPick] = useState(null);
  const [sa, setSa] = useState(''); const [sb, setSb] = useState('');
  if (pick==null) {
    return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
      <SubHeader title="Enter a result" sub="Pick a fixture to score" onBack={onBack} />
      <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'12px 18px' }}>
        {ups.length===0 ? <div style={{ textAlign:'center', padding:'56px 24px', color:C.muted, fontSize:13 }}>No upcoming fixtures to score.</div> :
        ups.map((f,i)=>(
          <button key={i} onClick={()=>setPick(f)} style={{ width:'100%', display:'flex', alignItems:'center', gap:11, padding:'12px 13px', borderRadius:13, border:'1px solid '+C.hair, background:C.paper, cursor:'pointer', marginBottom:9, fontFamily:'inherit', textAlign:'left' }}>
            <div style={{ display:'flex', alignItems:'center' }}><Crest size={32} bg={f.a.color} label={f.a.short} radius={9} /><div style={{ marginLeft:-8, border:'2px solid '+C.paper, borderRadius:11 }}><Crest size={32} bg={f.b.color} label={f.b.short} radius={9} /></div></div>
            <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5 }}>{f.a.short} vs {f.b.short}</div><div style={{ ...mono, fontSize:9, color:C.muted, marginTop:2 }}>{f.round}</div></div>
            <Icon name="next" size={16} stroke={C.soft} sw={2} />
          </button>
        ))}
      </div>
    </div>;
  }
  const winner = (sa&&sb) ? (parseInt(sa)>parseInt(sb)?pick.a:parseInt(sb)>parseInt(sa)?pick.b:null) : null;
  const scoreRow = (tm, val, onCh) => (
    <div style={{ display:'flex', alignItems:'center', gap:11, padding:'13px 14px', border:'1px solid '+(winner===tm?C.green:C.hair), borderRadius:13, background:winner===tm?C.greenSoft:C.paper, marginBottom:10 }}>
      <Crest size={36} bg={tm.color} label={tm.short} radius={10} />
      <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:700, fontSize:14 }}>{tm.name}</span>
      <input value={val} onChange={e=>onCh(e.target.value)} placeholder="142/6" style={{ width:96, padding:'9px 11px', borderRadius:10, border:'1px solid '+C.line, background:C.surface, fontFamily:'JetBrains Mono', fontWeight:700, fontSize:14, textAlign:'center', color:C.ink, outline:'none' }} />
    </div>
  );
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Enter result" sub={pick.round} onBack={()=>setPick(null)} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'16px 18px' }}>
      <div style={{ ...mono, fontSize:10, color:C.muted, marginBottom:10 }}>SCORES</div>
      {scoreRow(pick.a, sa, setSa)}
      {scoreRow(pick.b, sb, setSb)}
      {winner && <div style={{ display:'flex', alignItems:'center', gap:7, padding:'10px 12px', borderRadius:11, background:C.greenSoft, marginTop:4 }}><Icon name="trophy" size={15} stroke={C.greenInk} sw={2} /><span style={{ fontSize:12, color:C.greenInk, fontWeight:600 }}>{winner.name} win this fixture</span></div>}
    </div>
    <div style={{ borderTop:'1px solid '+C.hair, padding:'10px 18px calc(14px + env(safe-area-inset-bottom))', flexShrink:0 }}>
      <button onClick={ sa&&sb ? ()=>{ flash&&flash('Result saved — bracket updated'); onBack(); } : undefined} disabled={!(sa&&sb)} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:(sa&&sb)?C.ink:C.paper2, color:(sa&&sb)?C.paper:C.muted, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:(sa&&sb)?'pointer':'default' }}>Save result</button>
    </div>
  </div>;
}

function OrganizerDesk({ t, state, pending, onAddTeams, onGenerate, onRequests, flash }) {
  const code = (t.mono || 'TMT').toUpperCase() + '-' + (4000 + ((t.name||'').length * 137) % 5999);
  const [reqs, setReqs] = useState(() => REQUESTS.map(r => ({ ...r })));
  const [confirmed, setConfirmed] = useState(() => ([
    { short:'LL', name:'Lyari Lions', color:'oklch(0.62 0.19 28)', paid:true },
    { short:'KE', name:'Karsaz Eagles', color:'oklch(0.55 0.13 250)', paid:false },
    { short:'MB', name:'Malir Blasters', color:'oklch(0.56 0.13 148)', paid:true },
    { short:'NN', name:'Nazimabad XI', color:'oklch(0.55 0.17 305)', paid:true },
  ]));
  const accept = (r) => { setReqs(p=>p.filter(x=>x.id!==r.id)); setConfirmed(p=>[...p, { short:r.short, name:r.name, color:r.color, paid:false }]); flash&&flash(r.name+' accepted'); };
  const decline = (r) => { setReqs(p=>p.filter(x=>x.id!==r.id)); flash&&flash(r.name+' declined'); };
  const markPaid = (i) => { setConfirmed(p=>p.map((x,idx)=>idx===i?{...x,paid:true}:x)); flash&&flash('Marked paid'); };
  const inCount = confirmed.filter(c=>c.paid).length;
  const cap = t.teamsCount || 8;

  // DRAFT
  if (state === 'draft') {
    const Ck = ({ s, title, sub }) => (
      <div style={{ display:'flex', alignItems:'center', gap:10, padding:'11px 13px', border:'1px solid '+C.hair, borderRadius:12, marginBottom:8, background:C.paper }}>
        <div style={{ width:22, height:22, borderRadius:7, flexShrink:0, display:'flex', alignItems:'center', justifyContent:'center',
          background: s==='done'?C.green : s==='now'?C.ink : C.paper2, border: s==='wait'?'1px solid '+C.line:'none' }}>
          {s==='done' ? <Icon name="check" size={13} stroke={C.paper} sw={3} /> : <span style={{ ...mono, fontSize:9, color: s==='now'?C.paper:C.soft }}>{s==='now'?'2':'3'}</span>}
        </div>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontWeight:600, fontSize:13.5, color: s==='wait'?C.muted:C.ink }}>{title}</div>
          <div style={{ fontSize:11, color:C.muted, marginTop:1 }}>{sub}</div>
        </div>
      </div>
    );
    return <div style={{ padding:'14px 18px 8px' }}>
      <Ck s="done" title="Tournament created" sub="Format, dates & fee set" />
      <Ck s="now" title="Add teams" sub="Share your code — teams request to join" />
      <Ck s="next" title="Seed, schedule & go live" sub="Once you have 4+ teams, set the draw and publish" />
      <SecH>Your join code</SecH>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, padding:'14px 16px', background:C.paper, display:'flex', alignItems:'center', gap:12 }}>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:18, letterSpacing:'0.14em', color:C.ink }}>{code}</div>
          <div style={{ fontSize:11.5, color:C.muted, marginTop:3 }}>0 of {cap} teams · min 4 to start</div>
        </div>
        <button onClick={()=>flash&&flash('Code copied')} style={{ padding:'9px 14px', borderRadius:10, border:'1px solid '+C.line, background:C.paper, color:C.ink, fontFamily:'inherit', fontWeight:600, fontSize:12.5, cursor:'pointer' }}>Copy</button>
      </div>
      <button onClick={onAddTeams} style={{ marginTop:14, width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:'pointer' }}>Add teams</button>
      <button onClick={onGenerate} style={{ marginTop:10, width:'100%', padding:'14px 0', borderRadius:12, border:'1px solid '+C.line, background:C.paper, color:C.ink, fontFamily:'inherit', fontWeight:600, fontSize:14, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>Seed, schedule &amp; go live <Icon name="arrow" size={15} stroke={C.ink} sw={2} /></button>
      <div style={{ fontSize:11, color:C.muted, textAlign:'center', marginTop:9, lineHeight:1.45 }}>You can go live anytime once 4+ teams have joined.</div>
    </div>;
  }

  // READY
  if (state === 'ready') {
    const entrants = (t.teams||[]).slice(0, cap);
    return <div style={{ padding:'14px 18px 8px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:9, padding:'12px 14px', borderRadius:14, background:C.greenSoft, marginBottom:4 }}>
        <Icon name="check" size={16} stroke={C.greenInk} sw={2.6} /><span style={{ fontSize:12.5, color:C.greenInk, fontWeight:600 }}>All {cap} teams in & paid — generate the draw to go live.</span>
      </div>
      <SecH side={`${entrants.length} in`}>Entrants</SecH>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
        {entrants.map((k,i)=>{ const col=(T[k]&&T[k].color)||'var(--ink)'; return (
          <div key={i} style={{ display:'flex', alignItems:'center', gap:9, padding:'10px 11px', border:'1px solid '+C.hair, borderRadius:12, background:C.paper }}>
            <Crest size={28} bg={col} label={k} radius={8} />
            <span style={{ fontSize:12.5, fontWeight:600, color:C.ink, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{k}</span>
            <span style={{ ...mono, fontSize:7.5, color:C.greenInk, background:C.greenSoft, padding:'2px 5px', borderRadius:4, marginLeft:'auto' }}>IN</span>
          </div>
        );})}
      </div>
      <button onClick={onGenerate} style={{ marginTop:16, width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:'pointer' }}>Generate the draw</button>
    </div>;
  }

  // REGISTRATION
  return <div style={{ padding:'14px 18px 8px' }}>
    <div style={{ height:5, borderRadius:999, background:C.paper2, overflow:'hidden', marginBottom:12 }}><div style={{ width:Math.round(inCount/cap*100)+'%', height:'100%', background:C.amber }} /></div>
    <div style={{ display:'flex', alignItems:'center', gap:8, padding:'9px 11px', borderRadius:11, background:C.cream, marginBottom:4 }}>
      <Icon name="check" size={13} stroke={C.amberInk} sw={2.2} /><span style={{ fontSize:11.5, color:C.amberInk, lineHeight:1.4 }}>matchday <b>tracks</b> the cash you collect — it doesn’t process payments.</span>
    </div>
    {reqs.length>0 && <>
      <SecH>Requests · {reqs.length}</SecH>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
        {reqs.map((r,i)=>(
          <div key={r.id} style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 13px', borderTop:i?'1px solid '+C.hair:'none' }}>
            <Crest size={34} bg={r.color} label={r.short} radius={9} />
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ fontWeight:600, fontSize:13.5, color:C.ink, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{r.name}</div>
              <div style={{ fontSize:11, color:C.muted, marginTop:1 }}>Capt. {r.captain} · {r.players} players · {r.when}</div>
            </div>
            <button onClick={()=>decline(r)} style={{ width:32, height:32, borderRadius:9, border:'1px solid '+C.line, background:C.paper, color:C.muted, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Icon name="back" size={14} stroke={C.muted} sw={2.4} style={{ transform:'rotate(45deg)' }} /></button>
            <button onClick={()=>accept(r)} style={{ padding:'0 13px', height:32, borderRadius:9, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:12, cursor:'pointer', flexShrink:0 }}>Accept</button>
          </div>
        ))}
      </div>
    </>}
    <SecH side={`${inCount}/${cap} in`}>Confirmed · {confirmed.length}</SecH>
    <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
      {confirmed.map((c,i)=>(
        <div key={i} style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 13px', borderTop:i?'1px solid '+C.hair:'none' }}>
          <Crest size={34} bg={c.color} label={c.short} radius={9} />
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontWeight:600, fontSize:13.5, color:C.ink }}>{c.name}</div>
            <div style={{ fontSize:11, color:C.muted, marginTop:1 }}>{c.paid?'Accepted & paid':'Accepted · awaiting cash'}</div>
          </div>
          {c.paid
            ? <span style={{ ...mono, fontSize:8.5, color:C.greenInk, background:C.greenSoft, padding:'4px 8px', borderRadius:6 }}>IN</span>
            : <button onClick={()=>markPaid(i)} style={{ padding:'0 12px', height:30, borderRadius:9, border:'none', background:C.amber, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:11.5, cursor:'pointer' }}>Mark paid</button>}
        </div>
      ))}
    </div>
  </div>;
}

function EmptyState({ icon, title, sub, cta, onCta }) {
  return <div style={{ textAlign:'center', padding:'48px 30px' }}>
    <div style={{ width:56, height:56, borderRadius:16, background:C.paper2, display:'flex', alignItems:'center', justifyContent:'center', margin:'0 auto 14px' }}><Icon name={icon} size={24} stroke={C.muted} sw={1.9} /></div>
    <div style={{ ...display(16), color:C.ink }}>{title}</div>
    <div style={{ fontSize:12.5, color:C.muted, marginTop:6, lineHeight:1.5, maxWidth:240, marginLeft:'auto', marginRight:'auto' }}>{sub}</div>
    {cta && <button onClick={onCta} style={{ marginTop:18, padding:'11px 20px', borderRadius:12, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:13.5, cursor:'pointer' }}>{cta}</button>}
  </div>;
}

function ScheduleScreen({ t, onBack, onGoLive, flash }) {
  const list = [];
  if (t.fixtures) t.fixtures.forEach(f=>list.push({ a:f.a, b:f.b, round:f.round, when:f.when||f.sub, venue:f.venue, done:f.phase==='completed' }));
  else (t.rounds||[]).forEach(rd=>rd.matches.forEach(m=>list.push({ a:m.a, b:m.b, round:rd.name, when:m.when||(m.win?'Played':''), venue:t.venue, done:m.phase==='completed' })));
  const SLOTS = ['Sat 15:00','Sat 17:30','Sat 21:30','Sun 10:00','Sun 14:00','Sun 16:00','Sun 22:00'];
  const [slots, setSlots] = useState({});
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Schedule fixtures" sub={`${list.filter(f=>!f.done).length} to schedule`} onBack={onBack} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'12px 18px' }}>
      {list.map((f,i)=>{
        const sel = slots[i] || (f.done?f.when:null);
        return <div key={i} style={{ border:'1px solid '+C.hair, borderRadius:14, padding:12, marginBottom:10, background:C.paper, opacity:f.done?0.7:1 }}>
          <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:f.done?0:10 }}>
            <div style={{ display:'flex', alignItems:'center' }}><Crest size={28} bg={f.a.color} label={f.a.short} radius={8} /><div style={{ marginLeft:-7, border:'2px solid '+C.paper, borderRadius:9 }}><Crest size={28} bg={f.b.color} label={f.b.short} radius={8} /></div></div>
            <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5 }}>{f.a.short} vs {f.b.short}</div><div style={{ ...mono, fontSize:8.5, color:C.muted, marginTop:1 }}>{f.round}{f.done?' · '+f.when:''}</div></div>
            {f.done && <span style={{ ...mono, fontSize:8, color:C.muted, padding:'3px 7px', borderRadius:6, background:C.paper2 }}>PLAYED</span>}
          </div>
          {!f.done && <div style={{ display:'flex', gap:6, overflowX:'auto', paddingBottom:2 }}>
            {SLOTS.map(s=><button key={s} onClick={()=>setSlots(p=>({ ...p, [i]:s }))} style={{ flexShrink:0, padding:'7px 11px', borderRadius:999, border:'1px solid '+(sel===s?C.ink:C.hair), background:sel===s?C.ink:C.paper, color:sel===s?C.paper:C.ink2, fontFamily:'inherit', fontSize:12, fontWeight:600, cursor:'pointer', whiteSpace:'nowrap' }}>{s}</button>)}
          </div>}
        </div>;
      })}
      <div style={{ display:'flex', alignItems:'center', gap:7, padding:'10px 12px', borderRadius:11, background:C.paper2, marginTop:4 }}><Icon name="pin" size={14} stroke={C.muted} sw={2} /><span style={{ fontSize:11, color:C.muted }}>All at {t.venue} unless changed per fixture.</span></div>
    </div>
    <div style={{ borderTop:'1px solid '+C.hair, padding:'10px 18px calc(14px + env(safe-area-inset-bottom))', flexShrink:0 }}>
      <button onClick={()=>{ if(onGoLive){ onGoLive(); } else { flash&&flash('Fixtures scheduled'); onBack(); } }} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>{onGoLive && <Icon name="trophy" size={16} stroke={C.paper} sw={2.2} />}{onGoLive ? 'Publish & go live' : 'Save schedule'}</button>
    </div>
  </div>;
}

function SettingsScreen({ t, override, onBack, flash }) {
  const [open, setOpen] = useState((override&&override.entry)!=='invite');
  const [pub, setPub] = useState(true);
  const Row = ({ k, v, onClick }) => <div onClick={onClick} style={{ display:'flex', alignItems:'center', justifyContent:'space-between', gap:12, padding:'13px 14px', borderTop:'1px solid '+C.hair, cursor:onClick?'pointer':'default' }}>
    <span style={{ fontSize:13, color:C.ink2 }}>{k}</span><span style={{ display:'flex', alignItems:'center', gap:6, fontSize:13, fontWeight:600, color:C.ink }}>{v}{onClick && <Icon name="next" size={15} stroke={C.soft} sw={2} />}</span>
  </div>;
  const Switch = ({ k, s, on, onCh }) => <div onClick={()=>onCh(!on)} style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 14px', borderTop:'1px solid '+C.hair, cursor:'pointer' }}>
    <div style={{ flex:1 }}><div style={{ fontSize:13.5, fontWeight:600, color:C.ink }}>{k}</div><div style={{ fontSize:11, color:C.muted, marginTop:1 }}>{s}</div></div>
    <div style={{ width:44, height:26, borderRadius:999, background:on?C.ink:C.line, position:'relative', flexShrink:0 }}><div style={{ position:'absolute', top:3, left:on?21:3, width:20, height:20, borderRadius:999, background:'#fff', transition:'left .15s' }} /></div>
  </div>;
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Tournament settings" onBack={onBack} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 18px' }}>
      <div style={{ ...mono, fontSize:10, color:C.muted, marginBottom:9 }}>BASICS</div>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
        <div style={{ height:0 }} /><Row k="Format" v={t.format} onClick={()=>flash&&flash('Edit format')} />
        <Row k="Structure" v={t.structureLabel.split('·')[0].trim()} />
        <Row k="Dates" v={t.dates} onClick={()=>flash&&flash('Edit dates')} />
        <Row k="Ground" v={t.venue} onClick={()=>flash&&flash('Edit ground')} />
      </div>
      <div style={{ ...mono, fontSize:10, color:C.muted, margin:'18px 0 9px' }}>REGISTRATION & VISIBILITY</div>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
        <div style={{ height:0 }} /><Switch k="Registration open" s={open?'Captains can request to join':'Closed — no new entries'} on={open} onCh={(v)=>{ setOpen(v); flash&&flash(v?'Registration opened':'Registration closed'); }} />
        <Switch k="Public" s={pub?'Anyone can find & follow':'Hidden — link/code only'} on={pub} onCh={(v)=>{ setPub(v); flash&&flash(v?'Now public':'Now private'); }} />
        <Row k="Share / join code" v={<span style={{ ...mono, fontSize:12, letterSpacing:'0.1em' }}>{t.mono}-4821</span>} onClick={()=>flash&&flash('Code copied')} />
      </div>
      <div style={{ ...mono, fontSize:10, color:C.muted, margin:'18px 0 9px' }}>DANGER ZONE</div>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
        <div onClick={()=>flash&&flash('Cancel tournament')} style={{ padding:'13px 14px', cursor:'pointer', fontSize:13.5, fontWeight:600, color:C.red }}>Cancel tournament</div>
      </div>
      <div style={{ height:20 }} />
    </div>
  </div>;
}

function PostUpdateScreen({ t, onBack, flash }) {
  const [text, setText] = useState('');
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Post an update" sub="Shared with everyone following" onBack={onBack}
      right={<button onClick={ text.trim() ? ()=>{ flash&&flash('Update posted'); onBack(); } : undefined} disabled={!text.trim()} style={{ height:32, padding:'0 14px', borderRadius:10, border:'none', background:text.trim()?C.ink:C.paper2, color:text.trim()?C.paper:C.muted, fontFamily:'inherit', fontWeight:700, fontSize:12.5, cursor:text.trim()?'pointer':'default' }}>Post</button>} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 18px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}><Crest size={36} bg={t.color} label={t.mono} radius={10} /><div><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14 }}>{t.name}</div><div style={{ fontSize:11, color:C.muted }}>Posting as organizer</div></div></div>
      <textarea autoFocus value={text} onChange={e=>setText(e.target.value.slice(0,280))} placeholder="Rain delay? Venue change? Semi-final line-ups? Tell the teams…" rows={5} style={{ width:'100%', border:'1px solid '+C.hair, borderRadius:14, padding:'13px 14px', fontFamily:'inherit', fontSize:14, color:C.ink, outline:'none', resize:'none', lineHeight:1.5, boxSizing:'border-box', background:C.surface }} />
      <div style={{ ...mono, fontSize:9, color:C.soft, textAlign:'right', marginTop:6 }}>{text.length}/280</div>
      <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginTop:6 }}>
        {['Rain delay','Venue changed','Line-ups out','Final today'].map(q=><button key={q} onClick={()=>setText(x=>x?x:q+' — ')} style={{ padding:'7px 12px', borderRadius:999, border:'1px solid '+C.hair, background:C.paper, color:C.ink2, fontFamily:'inherit', fontSize:12, cursor:'pointer' }}>{q}</button>)}
      </div>
    </div>
  </div>;
}

function FeeScreen({ t, onBack, flash, locked }) {
  const teams = t.teams || [];
  const [paid, setPaid] = useState(()=>{ const m={}; teams.forEach((k,i)=>m[k]=i%3!==2); return m; });
  const paidCount = teams.filter(k=>paid[k]).length;
  const [amt, setAmt] = useState(2000);
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Entry & prize pool" sub={`${paidCount}/${teams.length} paid`} onBack={onBack} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 18px' }}>
      <div style={{ display:'flex', gap:10, marginBottom:16 }}>
        {[['Collected', (paidCount*amt).toLocaleString(), C.green],['Outstanding', ((teams.length-paidCount)*amt).toLocaleString(), C.amberInk]].map(([k,v,c])=>(
          <div key={k} style={{ flex:1, border:'1px solid '+C.hair, borderRadius:14, padding:'13px 14px' }}><div style={{ ...mono, fontSize:8.5, color:C.muted, marginBottom:6 }}>{k.toUpperCase()}</div><div style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:18, color:c }}>{v}</div><div style={{ ...mono, fontSize:8, color:C.muted, marginTop:2 }}>PKR</div></div>
        ))}
      </div>
      <div style={{ ...mono, fontSize:10, color:C.muted, marginBottom:9 }}>ENTRY FEE / TEAM</div>
      {locked ? (
        <div style={{ display:'flex', alignItems:'center', gap:7, padding:'11px 13px', borderRadius:12, border:'1px solid '+C.hair, background:C.paper2, marginBottom:14 }}><Icon name="money" size={15} stroke={C.muted} sw={2} /><span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:15, color:C.ink }}>{amt.toLocaleString()}</span><span style={{ fontSize:11, color:C.muted }}>PKR · locked — set before go-live</span></div>
      ) : (
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:8 }}>
          {[0,500,1000,2000,3000,5000].map(v=><button key={v} onClick={()=>setAmt(v)} style={{ padding:'8px 12px', borderRadius:999, border:'1px solid '+(amt===v?C.ink:C.hair), background:amt===v?C.ink:C.paper, color:amt===v?C.paper:C.ink, fontFamily:'JetBrains Mono', fontWeight:700, fontSize:12, cursor:'pointer' }}>{v===0?'Free':v.toLocaleString()}</button>)}
        </div>
      )}
      <div style={{ display:'flex', alignItems:'center', gap:7, padding:'9px 11px', borderRadius:10, background:C.cream, marginBottom:14 }}><Icon name="money" size={14} stroke={C.amberInk} sw={2} /><span style={{ fontSize:11, color:C.amberInk }}>Tracked here, settled off-app — matchday doesn’t process payments.</span></div>
      <div style={{ ...mono, fontSize:10, color:C.muted, marginBottom:9 }}>TEAMS</div>
      <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden', background:C.paper }}>
        {teams.map((k,i)=>{ const tm=T[k]; const p=paid[k]; return (
          <div key={k} style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 13px', borderTop:i?'1px solid '+C.hair:'none' }}>
            <Crest size={30} bg={tm.color} label={tm.short} radius={9} />
            <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5 }}>{tm.name}</span>
            <button onClick={()=>{ setPaid(m=>({ ...m, [k]:!m[k] })); flash&&flash(tm.short+(p?' marked unpaid':' marked paid')); }} style={{ padding:'6px 11px', borderRadius:999, border:'1px solid '+(p?'transparent':C.line), background:p?C.greenSoft:C.paper, color:p?C.greenInk:C.muted, fontFamily:'inherit', fontWeight:700, fontSize:11, cursor:'pointer', display:'inline-flex', alignItems:'center', gap:5 }}>{p && <Icon name="check" size={12} stroke={C.greenInk} sw={2.6} />}{p?'Paid':'Unpaid'}</button>
          </div>
        );})}
      </div>
      <div style={{ height:20 }} />
    </div>
  </div>;
}

function DrawPreviewScreen({ t, onBack, onConfirm, onReseed }) {
  const teams = (t.teams||[]).map(k=>T[k]||TBD);
  const struct = t.structure;
  const pairs = [];
  if (struct !== 'league') {
    const n = teams.length; const half = Math.ceil(n/2);
    for (let i=0;i<half;i++){ pairs.push([teams[i], teams[n-1-i]]); }
  }
  const r1name = struct==='hybrid' ? 'Group stage opener' : teams.length<=4 ? 'Semi-finals' : teams.length<=8 ? 'Quarter-finals' : 'Round 1';
  return <div style={{ position:'absolute', inset:0, zIndex:98, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Preview the draw" sub={`${teams.length} teams · not public yet`} onBack={onBack} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 18px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:7, padding:'10px 12px', borderRadius:11, background:C.cream, marginBottom:16 }}><Icon name="trophy" size={15} stroke={C.amberInk} sw={2} /><span style={{ fontSize:11.5, color:C.amberInk }}>This is a draft. Reshuffle until it looks right — nothing is public until you go live.</span></div>
      {struct==='league' ? (
        <div style={{ border:'1px solid '+C.hair, borderRadius:14, padding:'16px 14px', textAlign:'center', background:C.paper }}>
          <div style={{ ...display(17) }}>Round-robin</div>
          <div style={{ fontSize:12.5, color:C.muted, marginTop:5, lineHeight:1.5 }}>Every team plays every other once — {teams.length} teams, {teams.length-1} matchdays, {teams.length*(teams.length-1)/2} matches.</div>
        </div>
      ) : (<>
        <div style={{ ...mono, fontSize:10, color:C.muted, marginBottom:9 }}>{r1name.toUpperCase()}</div>
        {pairs.map(([a,b],i)=>(
          <div key={i} style={{ border:'1px solid '+C.hair, borderRadius:13, padding:'10px 12px', marginBottom:8, background:C.paper, display:'flex', alignItems:'center', gap:10 }}>
            <span style={{ ...mono, fontSize:9, color:C.muted, width:30 }}>M{i+1}</span>
            <div style={{ flex:1, display:'flex', alignItems:'center', gap:8 }}>
              <Crest size={26} bg={a.color} fg={a.fg||C.paper} label={a.short} radius={7} />
              <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13 }}>{a.short}</span>
              <span style={{ ...mono, fontSize:9, color:C.soft, margin:'0 2px' }}>VS</span>
              <Crest size={26} bg={b.color} fg={b.fg||C.paper} label={b.short} radius={7} />
              <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13 }}>{b.short}</span>
            </div>
          </div>
        ))}
      </>)}
    </div>
    <div style={{ borderTop:'1px solid '+C.hair, padding:'10px 18px calc(14px + env(safe-area-inset-bottom))', flexShrink:0, display:'flex', gap:10 }}>
      <button onClick={onReseed} style={{ flex:'0 0 auto', padding:'14px 16px', borderRadius:12, border:'1px solid '+C.line, background:C.paper, color:C.ink, fontFamily:'inherit', fontWeight:600, fontSize:14, cursor:'pointer' }}>Reseed</button>
      <button onClick={onConfirm} style={{ flex:1, padding:'14px 0', borderRadius:12, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}><Icon name="cal" size={16} stroke={C.paper} sw={2.2} />Set fixtures</button>
    </div>
  </div>;
}

function GenerateDrawScreen({ t, onBack, onGenerate }) {
  const [seeding, setSeeding] = useState('random');
  const teams = t.teams || [];
  const MIN = 4;
  const enough = teams.length >= MIN;
  const struct = t.structure;
  const out = struct==='league' ? 'A round-robin schedule' : struct==='hybrid' ? 'Groups + a knockout bracket' : 'A single-elimination bracket';
  return <div style={{ position:'absolute', inset:0, zIndex:97, background:C.paper, display:'flex', flexDirection:'column' }}>
    <SubHeader title="Generate draw" sub={`${teams.length} teams · ${t.structureLabel}`} onBack={onBack} />
    <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 18px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:7, padding:'10px 12px', borderRadius:11, background:C.paper2, marginBottom:16 }}><Icon name="trophy" size={15} stroke={C.ink2} sw={2} /><span style={{ fontSize:11.5, color:C.ink2 }}>Builds <b style={{color:C.ink}}>{out.toLowerCase()}</b> from the {teams.length} entrants.</span></div>
      <div style={{ ...mono, fontSize:10, color:C.muted, marginBottom:9 }}>SEEDING</div>
      {[['random','dice','Random draw','Shuffle teams in. No setup, reads as fair.'],['manual','hand','Manual / seeded','Place teams yourself or seed 1…N to keep the strong ones apart.']].map(([k,ic,ti,s])=>{
        const on=seeding===k;
        return <button key={k} onClick={()=>setSeeding(k)} style={{ width:'100%', display:'flex', alignItems:'center', gap:12, padding:13, borderRadius:14, border:'2px solid '+(on?C.ink:C.hair), background:on?C.paper2:C.paper, cursor:'pointer', marginBottom:8, textAlign:'left', fontFamily:'inherit' }}>
          <div style={{ width:36, height:36, borderRadius:10, background:on?C.ink:C.paper2, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Icon name={ic==='dice'?'money':'whistle'} size={17} stroke={on?C.paper:C.ink} sw={2} /></div>
          <div style={{ flex:1, minWidth:0 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14 }}>{ti}</div><div style={{ fontSize:11.5, color:C.muted, marginTop:2, lineHeight:1.4 }}>{s}</div></div>
          <div style={{ width:22, height:22, borderRadius:999, border:'2px solid '+(on?C.ink:C.hair), background:on?C.ink:'transparent', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>{on && <Icon name="check" size={11} stroke={C.paper} sw={3} />}</div>
        </button>;
      })}
      <div style={{ ...mono, fontSize:10, color:C.muted, margin:'16px 0 9px' }}>ENTRANTS</div>
      <div style={{ display:'flex', flexWrap:'wrap', gap:6 }}>
        {teams.map(k=>{ const tm=T[k]; return <span key={k} style={{ display:'inline-flex', alignItems:'center', gap:6, padding:'5px 10px 5px 5px', borderRadius:999, background:C.paper2 }}><Crest size={22} bg={tm.color} label={tm.short} radius={6} /><span style={{ fontSize:11.5, fontWeight:600, color:C.ink }}>{tm.short}</span></span>; })}
      </div>
    </div>
    <div style={{ borderTop:'1px solid '+C.hair, padding:'10px 18px calc(14px + env(safe-area-inset-bottom))', flexShrink:0 }}>
      {!enough && <div style={{ fontSize:11.5, color:C.amberInk, textAlign:'center', marginBottom:9 }}>Needs at least {MIN} teams to start · {teams.length} in</div>}
      <button onClick={enough?onGenerate:undefined} disabled={!enough} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:enough?C.ink:C.paper2, color:enough?C.paper:C.muted, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:enough?'pointer':'default', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>{enough && <Icon name="trophy" size={16} stroke={C.paper} sw={2.2} />}Preview the draw</button>
    </div>
  </div>;
}

function AwardsTab({ t, role, onPick }) {
  const a = t.awards;
  if (!a) return <EmptyState icon="trophy" title="No awards yet" sub="Awards appear when the tournament finishes." />;
  const podium = [
    { rank:1, label:'CHAMPIONS', team:a.champion },
    { rank:2, label:'RUNNERS-UP', team:a.runner },
    { rank:3, label:'THIRD PLACE', team:a.third },
  ];
  return (
    <div style={{ padding:'14px 18px 8px' }}>
      <div style={{ borderRadius:18, background:C.goldSoft, padding:'20px 16px', textAlign:'center', marginBottom:18 }}>
        <div style={{ width:64, height:64, borderRadius:18, background:C.gold, display:'flex', alignItems:'center', justifyContent:'center', margin:'0 auto 12px' }}><Icon name="trophy" size={34} stroke={C.paper} sw={1.9} /></div>
        <div style={{ ...mono, fontSize:9, color:C.goldInk, marginBottom:6 }}>CHAMPIONS</div>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'center', gap:10 }}>
          <Crest size={32} bg={a.champion.color} label={a.champion.short} />
          <span style={{ ...display(22) }}>{a.champion.name}</span>
        </div>
        {a.champion.note && <div style={{ fontSize:12, color:C.ink2, marginTop:7 }}>{a.champion.note}</div>}
      </div>

      <SecH>Final standings</SecH>
      <div style={{ display:'grid', gap:8, marginBottom:4 }}>
        {podium.map(p => (
          <div key={p.rank} style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 14px', borderRadius:14, border:'1px solid '+C.hair, background:C.paper }}>
            <div style={{ width:26, height:26, borderRadius:999, background:p.rank===1?C.goldSoft:C.paper2, color:p.rank===1?C.goldInk:C.muted, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, fontFamily:'Inter Tight', fontWeight:800, fontSize:13 }}>{p.rank}</div>
            <Crest size={36} bg={p.team.color} label={p.team.short} radius={10} />
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.01em' }}>{p.team.name}</div>
              <div style={{ ...mono, fontSize:8, color:C.muted, marginTop:2 }}>{p.label}</div>
            </div>
            {p.rank===1 && <Icon name="trophy" size={18} stroke={C.gold} sw={2} />}
          </div>
        ))}
      </div>

      <SecH side={role==='organizer'?'You picked these':null}>Player awards</SecH>
      <div style={{ display:'grid', gap:8 }}>
        {a.players.map((pl,i) => (
          <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'12px 14px', borderRadius:14, border:'1px solid '+C.hair, background:C.paper }}>
            <div style={{ width:40, height:40, borderRadius:999, background:pl.team.color, color:C.paper, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, fontFamily:'Inter Tight', fontWeight:800, fontSize:14 }}>{pl.name.split(' ').map(w=>w[0]).slice(0,2).join('')}</div>
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ ...mono, fontSize:8, color:C.goldInk, marginBottom:3 }}>{pl.role}</div>
              <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.01em' }}>{pl.name}</div>
              <div style={{ fontSize:11, color:C.muted, marginTop:1 }}>{pl.team.name} · {pl.stat}</div>
            </div>
            {role==='organizer' && <button onClick={onPick} style={{ background:'none', border:'none', cursor:'pointer', padding:6, color:C.muted }}><Icon name="pencil" size={15} stroke={C.muted} sw={2} /></button>}
          </div>
        ))}
      </div>
      {role==='organizer' && <div style={{ ...mono, fontSize:8.5, color:C.soft, textAlign:'center', padding:'14px 0 4px' }}>TAP A PENCIL TO RE-PICK AN AWARD</div>}
    </div>
  );
}

function TournamentHub({ sample='knockout', role='organizer', override, onBack, flash }) {
  const base = SAMPLES[sample] || SAMPLES.knockout;
  const [activated, setActivated] = useState(false);
  const draft = !!(override && override.draft) && !activated;
  const t = override ? { ...base, name:override.name||base.name, mono:override.mono||base.mono, color:override.color||base.color, structureLabel:override.structureLabel||base.structureLabel, stage:override.stage||base.stage } : base;
  const psLabel = t.standTab === 'Table' ? 'Points Table' : t.standTab;
  const TABS = draft
    ? [{ k:'stand', l:'Setup' }]
    : [{ k:'over', l:'Overview' }, { k:'stand', l:psLabel }, { k:'fix', l:'Matches' }, { k:'team', l:'Teams' }];
  if (override && override.completed && t.awards) TABS.push({ k:'awards', l:'Awards' });
  if (role === 'organizer') TABS.push({ k:'manage', l:'Manage' });
  const [tab, setTab] = useState(draft ? 'stand' : 'over');
  const [manageView, setManageView] = useState(null);
  const pending = (override && override.entry==='invite') ? 0 : REQUESTS.length;
  const st = override && override.state;
  const inCount = 3; // confirmed-and-paid for registration sample
  const meta = (st==='draft') ? [['Format', t.format], ['Teams', '0'], ['Status', 'Draft']]
    : (st==='registration') ? [['Format', t.format], ['Teams', inCount+'/'+(t.teamsCount||8)], ['Status', 'Registration']]
    : (st==='ready') ? [['Format', t.format], ['Teams', String(t.teamsCount||8)], ['Status', 'Ready']]
    : [['Format', t.format], ['Teams', t.teamsCount], ['Dates', t.dates]];
  if (manageView === 'requests') return <RequestsScreen t={t} onBack={()=>setManageView(null)} flash={flash} />;
  if (manageView === 'teams') return <ManageTeamsScreen t={draft?{...t,teams:[]}:t} pending={pending} onBack={()=>setManageView(null)} onRequests={()=>setManageView('requests')} flash={flash} />;
  if (manageView === 'result') return <EnterResultScreen t={t} onBack={()=>setManageView(null)} flash={flash} />;
  if (manageView === 'gendraw') return <GenerateDrawScreen t={t} onBack={()=>setManageView(null)} onGenerate={()=>setManageView('preview')} />;
  if (manageView === 'preview') return <DrawPreviewScreen t={t} onBack={()=>setManageView('gendraw')} onReseed={()=>flash&&flash('Reshuffled the draw')} onConfirm={()=>setManageView('golive')} />;
  if (manageView === 'golive') return <ScheduleScreen t={t} onBack={()=>setManageView('preview')} onGoLive={()=>{ setActivated(true); setManageView(null); setTab('stand'); flash&&flash('Published — tournament is live'); }} flash={flash} />;
  if (manageView === 'schedule') return <ScheduleScreen t={t} onBack={()=>setManageView(null)} flash={flash} />;
  if (manageView === 'settings') return <SettingsScreen t={t} override={override} onBack={()=>setManageView(null)} flash={flash} />;
  if (manageView === 'update') return <PostUpdateScreen t={t} onBack={()=>setManageView(null)} flash={flash} />;
  if (manageView === 'fee') return <FeeScreen t={t} onBack={()=>setManageView(null)} flash={flash} locked={!draft} />;
  return (
    <div style={{ position:'absolute', inset:0, zIndex:96, background:C.paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'2px 10px 8px', borderBottom:'1px solid '+C.hair, flexShrink:0 }}>
        <button onClick={onBack} style={{ background:'transparent', border:'none', cursor:'pointer', padding:6, marginLeft:-2, display:'flex', alignItems:'center', color:C.ink }}><Icon name="back" size={20} stroke={C.ink} sw={2} /></button>
        <span style={{ ...mono, fontSize:9, color:C.muted }}>TOURNAMENT</span>
        <button onClick={()=>flash&&flash('More')} style={{ background:'transparent', border:'none', cursor:'pointer', padding:6, color:C.ink2 }}><Icon name="dots" size={18} stroke={C.ink2} sw={2} /></button>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        <div style={{ margin:'12px 18px 0', padding:'16px 16px', borderRadius:18, background:C.paper2, position:'relative', overflow:'hidden' }}>
          <div style={{ display:'flex', alignItems:'center', gap:13, position:'relative' }}>
            <Crest size={52} bg={t.color} label={t.mono} radius={15} />
            <div style={{ flex:1, minWidth:0 }}><div style={{ ...display(19), lineHeight:1.12 }}>{t.name}</div><div style={{ fontSize:11.5, color:C.muted, marginTop:4 }}>{t.structureLabel}</div></div>
            {role !== 'organizer' && <TFollow flash={flash} />}
          </div>
          <div style={{ display:'flex', alignItems:'center', gap:8, marginTop:14, paddingTop:13, borderTop:'1px solid '+C.hair }}><StatusPill status={st==='draft'?'upcoming':st==='registration'?'registration':st==='ready'?'progress':(override&&override.completed?'completed':t.status)} label={st==='draft'?'DRAFT':st==='registration'?'REGISTRATION':st==='ready'?'READY':(override&&override.completed?'COMPLETED':t.statusLabel)} /><span style={{ fontSize:11.5, color:C.ink2, fontWeight:600 }}>{st==='draft'?'Not started':st==='registration'?'Open · accepting teams':st==='ready'?'Ready to draw':(override&&override.completed?'Lyari Lions — champions':t.stage)}</span></div>
          <div style={{ display:'flex', gap:18, marginTop:13 }}>{meta.map(([k,v]) => <div key={k}><div style={{ ...mono, fontSize:8.5, color:C.muted, marginBottom:3 }}>{k}</div><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13, color:C.ink }}>{v}</div></div>)}</div>
        </div>
        {override && override.completed && <div style={{ margin:'12px 18px 0', padding:'14px 16px', borderRadius:16, background:C.goldSoft, display:'flex', alignItems:'center', gap:12 }}><div style={{ width:42, height:42, borderRadius:12, background:C.gold, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Icon name="trophy" size={22} stroke={C.paper} sw={2} /></div><div style={{ flex:1, minWidth:0 }}><div style={{ ...mono, fontSize:8.5, color:C.goldInk, marginBottom:2 }}>CHAMPIONS</div><div style={{ ...display(17) }}>Lyari Lions</div><div style={{ fontSize:11.5, color:C.ink2, marginTop:2 }}>Beat Defence Chargers by 44 runs in the final</div></div></div>}
        {draft && override && override.ready && false && <div style={{ margin:'12px 18px 0', padding:'12px 14px', borderRadius:14, background:C.greenSoft, display:'flex', alignItems:'center', gap:9 }}><Icon name="check" size={16} stroke={C.greenInk} sw={2.6} /><span style={{ fontSize:12, color:C.greenInk, fontWeight:600 }}>All 8 teams in & paid — generate the draw to go live.</span></div>}
          <div style={{ display:'flex', gap:4, padding:'14px 18px 0', position:'sticky', top:0, background:C.paper, zIndex:3 }}>
          {TABS.map(tb => <button key={tb.k} onClick={()=>setTab(tb.k)} style={{ flex:1, padding:'9px 4px', borderRadius:10, border:'none', cursor:'pointer', fontFamily:'inherit', fontWeight:600, fontSize:12.5, letterSpacing:'-0.01em', background:tab===tb.k?C.ink:C.paper2, color:tab===tb.k?C.paper:C.ink2 }}>{tb.l}</button>)}
        </div>
        {role !== 'organizer' && tab==='stand' && !draft && <div style={{ ...mono, fontSize:8.5, color:C.soft, textAlign:'center', padding:'10px 18px 0' }}>VIEW ONLY · YOU FOLLOW THIS CUP</div>}
        {draft && tab==='stand' && <OrganizerDesk t={t} state={override&&override.ready?'ready':(override&&override.entry==='open'?'registration':'draft')} pending={pending}
          onAddTeams={()=>{ setTab('manage'); setManageView('teams'); }}
          onGenerate={()=>{ setTab('manage'); setManageView('gendraw'); }}
          onRequests={()=>{ setTab('manage'); setManageView('requests'); }} flash={flash} />}
        {draft && tab==='fix' && <EmptyState icon="cal" title="No fixtures yet" sub="Fixtures appear here once the draw is generated and dates are set." />}
        {draft && tab==='team' && <EmptyState icon="users" title="No teams yet" sub={(override&&override.entry==='invite')?'Invite teams to fill the tournament.':'Share your join code — teams will request to enter.'} cta={role==='organizer'?'Add teams':null} onCta={()=>{ setTab('manage'); setManageView('teams'); }} />}
        {!draft && tab==='over' && <OverviewTab t={t} role={role} onAll={()=>setTab('fix')} flash={flash} />}
        {!draft && tab==='stand' && <StandingsTab t={t} />}
        {!draft && tab==='fix' && <FixturesTab t={t} />}
        {!draft && tab==='team' && <TeamsTab t={t} />}
        {tab==='awards' && <AwardsTab t={t} role={role} onPick={()=>flash&&flash('Re-pick award — choose a player')} />}
        {tab==='manage' && <ManageTab t={t} draft={draft} state={override&&override.ready?'ready':(override&&override.entry==='open'?'registration':draft?'draft':'live')} pending={pending} onOpen={setManageView} flash={flash} />}
        <div style={{ height:28 }} />
      </div>
    </div>
  );
}
function TFollow({ flash }) {
  const [f, setF] = React.useState(false);
  return (
    <button onClick={()=>{ setF(v=>!v); flash&&flash(f?'Unfollowed':'Following — you’ll get match alerts'); }} style={{ flexShrink:0, height:30, padding:'0 14px', borderRadius:999, border:'1px solid '+(f?C.hair:C.ink), background:f?C.paper:C.ink, color:f?C.ink2:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:12, cursor:'pointer' }}>{f?'Following':'Follow'}</button>
  );
}

const KEYSTATS = [
  { k:'Most runs',   n:'T Seifert',  team:'Seattle Orcas', v:'256', u:'runs' },
  { k:'Most wickets',n:'H Singh',    team:'MI New York',   v:'14',  u:'wkts' },
  { k:'Best figures',n:'N Pooran',   team:'LA Knights',    v:'5/19',u:'' },
];

function FeaturedMatch({ f }) {
  const live = f.phase==='live', done = f.phase==='completed';
  const center = live ? <span style={{ ...mono, fontSize:9, color:C.red, display:'inline-flex', alignItems:'center', gap:5 }}><span style={{ width:5, height:5, borderRadius:999, background:C.red, animation:'ck-pulse 1.4s ease-in-out infinite' }} />LIVE</span>
    : done ? <span style={{ fontSize:11.5, fontWeight:700, color:C.ink, textAlign:'center' }}>{f.sub}</span>
    : <span style={{ fontSize:11, color:C.muted, textAlign:'center' }}>{f.sub||f.venue}</span>;
  const side = (tm, sc, r) => (
    <div style={{ flex:1, display:'flex', alignItems:'center', gap:8, flexDirection:r?'row-reverse':'row', minWidth:0 }}>
      <Crest size={28} bg={tm.color} label={tm.short} radius={9} />
      <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{tm.short}</span>
    </div>
  );
  return (
    <div style={{ display:'flex', alignItems:'center', gap:8, padding:'13px 14px', borderRadius:14, background:C.paper2, marginBottom:8 }}>
      {side(f.a, f.sa)}
      <div style={{ width:78, display:'flex', justifyContent:'center' }}>{center}</div>
      {side(f.b, f.sb, true)}
    </div>
  );
}

function OverviewTab({ t, role, onAll, flash }) {
  const fx = (t.fixtures||[]);
  const featured = []
    .concat(fx.filter(f=>f.phase==='live'))
    .concat(fx.filter(f=>f.phase==='upcoming'))
    .concat(fx.filter(f=>f.phase==='completed'))
    .slice(0,3);
  return (
    <div style={{ padding:'14px 18px 8px' }}>
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', marginBottom:11 }}>
        <span style={{ ...display(15) }}>Featured matches</span>
        <button onClick={onAll} style={{ background:'none', border:'none', cursor:'pointer', fontFamily:'inherit', fontSize:12, fontWeight:600, color:C.ink2, padding:0 }}>All matches →</button>
      </div>
      {featured.length ? featured.map((f,i)=><FeaturedMatch key={i} f={f} />) : <div style={{ fontSize:12.5, color:C.muted, padding:'4px 0 12px' }}>Fixtures appear here once the draw is set.</div>}

      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', margin:'18px 0 11px' }}>
        <span style={{ ...display(15) }}>Key stats</span>
        <button onClick={()=>flash&&flash('Full stats — coming soon')} style={{ background:'none', border:'none', cursor:'pointer', fontFamily:'inherit', fontSize:12, fontWeight:600, color:C.ink2, padding:0 }}>See all →</button>
      </div>
      <div style={{ display:'grid', gap:8 }}>
        {KEYSTATS.map((s,i)=>(
          <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 14px', borderRadius:14, border:'1px solid '+C.hair, background:C.paper }}>
            <div style={{ width:38, height:38, borderRadius:999, background:C.paper2, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, fontFamily:'Inter Tight', fontWeight:700, fontSize:13, color:C.ink2 }}>{s.n.split(' ').map(w=>w[0]).join('').slice(0,2)}</div>
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ ...mono, fontSize:8.5, color:C.muted, marginBottom:2 }}>{s.k.toUpperCase()}</div>
              <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, color:C.ink, whiteSpace:'nowrap' }}>{s.n}</div>
              <div style={{ fontSize:11, color:C.muted, marginTop:1 }}>{s.team}</div>
            </div>
            <div style={{ textAlign:'right' }}>
              <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:20, color:C.ink }}>{s.v}</span>
              {s.u && <div style={{ fontSize:10, color:C.muted, marginTop:1 }}>{s.u}</div>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

window.TournamentHub = TournamentHub;
window.TOURNAMENT_SAMPLES = SAMPLES;
})();

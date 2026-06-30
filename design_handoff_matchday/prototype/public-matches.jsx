// public-matches.jsx — the Matches TAB: a public, watch-anyone's-match feed.
// Live tournament matches first, grouped by tournament, relevant-first.
// window.PublicMatches({ header, onOpenTournament })

(function () {
const { useState } = React;
const C = window.Ch;
const D = window.PavData;
const ink=C.ink, ink2=C.ink2, muted=C.muted, soft=C.soft, paper=C.paper, paper2=C.paper2,
      surface=C.surface, hair=C.hair, line=C.line, red=C.red, redSoft=C.redSoft,
      green=C.green, greenSoft=C.greenSoft, greenInk=C.greenInk, amber=C.amber, cream=C.cream, amberInk=C.amberInk;
const CR = D.CRESTS || {};
const mono = { fontFamily:'JetBrains Mono,monospace', fontWeight:700, letterSpacing:'0.1em', textTransform:'uppercase' };
const numCell = { fontFamily:'JetBrains Mono', fontWeight:600, fontSize:12, color:'var(--ink)', textAlign:'right', flexShrink:0 };

const P = {
  back:'<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>',
  chev:'<path d="M9 6l6 6-6 6"/>',
  arrow:'<path d="M5 12h14M13 6l6 6-6 6"/>',
  trophy:'<path d="M7 4h10v4a5 5 0 0 1-10 0z"/><path d="M7 5H4v2a3 3 0 0 0 3 3M17 5h3v2a3 3 0 0 1-3 3"/><path d="M12 13v4M9 21h6M10 17h4"/>',
  pin:'<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>',
  eye:'<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>',
  speaker:'<path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/>',
  coin:'<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 0 1 5 0c0 1.6-2.5 2-2.5 3.5M12 16h.01"/>',
  bat:'<path d="M14.5 4.5a2 2 0 0 1 2.9 2.9l-8 8-2.9-2.9z"/><path d="M6.5 12.5 4 15l1.5 1.5L8 14"/><circle cx="17.5" cy="17.5" r="2.5"/>',
};
function Ic({ n, s=18, sw=1.9, stroke='currentColor', style }) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{ __html:P[n] }} />;
}
function Crest({ k, size=30 }) {
  const c = CR[k] || { short:k, color:'var(--ink)' };
  return <div style={{ width:size, height:size, borderRadius:size*0.26, background:c.color, color:'#fff', flexShrink:0,
    display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:size*0.4, letterSpacing:'-0.02em' }}>{c.short}</div>;
}

// ── public tournaments + their matches ──────────────────
// rel: relevant to you (following / your city) → surfaced first
const TOURS = [
  { id:'spring', name:'Spring Cup', stage:'Quarter-finals', city:'Lahore', rel:'Following', crest:'LL',
    matches:[
      { id:'sp1', state:'live', a:'LL', b:'MT', sa:'112/4', sb:'149/7', note:'LL need 38 off 22', watchers:214 },
      { id:'sp2', state:'live', a:'KE', b:'CC', sa:'88/2', sb:'—', note:'KE batting · 9.1 ov', watchers:96 },
      { id:'sp3', state:'upcoming', a:'GG', b:'MK', when:'Today · 6:00 PM', venue:'Gulberg' },
    ] },
  { id:'ramadan', name:'Ramadan Night League', stage:'League · MD 4', city:'Lahore', rel:'Your city', crest:'IT',
    matches:[
      { id:'rn1', state:'live', a:'IT', b:'MS', sa:'64/3', sb:'—', note:'IT batting · 7.4 ov', watchers:152 },
      { id:'rn2', state:'upcoming', a:'LL', b:'KE', when:'Tomorrow · 9:00 PM', venue:'Iqbal Park' },
      { id:'rn3', state:'result', a:'MK', b:'GG', sa:'141/8', sb:'138/9', win:'a', note:'Mohalla Kings won by 3 runs' },
    ] },
  { id:'gulberg', name:'Gulberg T20 Bash', stage:'Group A', city:'Karachi', rel:null, crest:'CC',
    matches:[
      { id:'gb1', state:'live', a:'CC', b:'MT', sa:'45/1', sb:'—', note:'CC batting · 5.2 ov', watchers:58 },
      { id:'gb2', state:'upcoming', a:'KE', b:'GG', when:'Today · 8:30 PM', venue:'Karachi Gymkhana' },
    ] },
];

function LiveCard({ m, onWatch }) {
  return (
    <button onClick={()=>onWatch(m)} style={{ width:'calc(100% - 36px)', margin:'0 18px 10px', textAlign:'left', fontFamily:'inherit',
      borderRadius:16, border:'1px solid '+hair, background:surface, cursor:'pointer', padding:0, display:'block', overflow:'hidden' }}>
      <div style={{ display:'flex', alignItems:'center', gap:8, padding:'10px 12px 0' }}>
        <span style={{ ...mono, fontSize:9, padding:'3px 7px', borderRadius:5, background:redSoft, color:red, display:'inline-flex', alignItems:'center', gap:5 }}>
          <span style={{ width:5, height:5, borderRadius:999, background:red, animation:'ck-pulse 1.4s ease-in-out infinite' }} />LIVE
        </span>
        <span style={{ ...mono, fontSize:9, color:muted, marginLeft:'auto', display:'inline-flex', alignItems:'center', gap:4 }}>
          <Ic n="eye" s={12} sw={1.8} stroke={muted} />{m.watchers}
        </span>
      </div>
      <div style={{ padding:'10px 12px 4px' }}>
        {[[m.a, m.sa, true], [m.b, m.sb, false]].map(([k,sc],i)=>(
          <div key={i} style={{ display:'flex', alignItems:'center', gap:10, padding:'5px 0' }}>
            <Crest k={k} size={28} />
            <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:700, fontSize:14, color:ink }}>{(CR[k]||{}).name||k}</span>
            <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:15, color: sc==='—'?soft:ink }}>{sc}</span>
          </div>
        ))}
      </div>
      <div style={{ padding:'8px 12px', borderTop:'1px solid '+hair, display:'flex', alignItems:'center', gap:8 }}>
        <span style={{ flex:1, minWidth:0, fontSize:11.5, color:ink2, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{m.note}</span>
        <span style={{ ...mono, fontSize:9, color:red, display:'inline-flex', alignItems:'center', gap:4 }}>WATCH<Ic n="chev" s={13} sw={2.4} stroke={red} /></span>
      </div>
    </button>
  );
}

function UpcomingRow({ m, top }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:11, padding:'11px 14px', borderTop:top?'none':'1px solid '+hair }}>
      <div style={{ display:'flex', alignItems:'center' }}>
        <Crest k={m.a} size={30} />
        <div style={{ marginLeft:-7, border:'2px solid '+surface, borderRadius:10 }}><Crest k={m.b} size={30} /></div>
      </div>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5, letterSpacing:'-0.01em' }}>{(CR[m.a]||{}).short} vs {(CR[m.b]||{}).short}</div>
        <div style={{ fontSize:11, color:muted, marginTop:1, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{m.when} · {m.venue}</div>
      </div>
    </div>
  );
}

function ResultRow({ m, top }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:11, padding:'10px 14px', borderTop:top?'none':'1px solid '+hair }}>
      <div style={{ display:'flex', alignItems:'center' }}>
        <Crest k={m.a} size={28} />
        <div style={{ marginLeft:-7, border:'2px solid '+surface, borderRadius:9 }}><Crest k={m.b} size={28} /></div>
      </div>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontSize:12, color:ink2, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{m.note}</div>
      </div>
      <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:12, color:ink }}>{m.sa}</span>
      <span style={{ fontFamily:'JetBrains Mono', fontSize:11, color:muted }}>{m.sb}</span>
    </div>
  );
}

function TourGroup({ t, onOpen, onWatch, show }) {
  const [open, setOpen] = useState(true);
  const want = show || ['live','upcoming','result'];
  const live = want.includes('live') ? t.matches.filter(m=>m.state==='live') : [];
  const upcoming = want.includes('upcoming') ? t.matches.filter(m=>m.state==='upcoming') : [];
  const results = want.includes('result') ? t.matches.filter(m=>m.state==='result') : [];
  if (!live.length && !upcoming.length && !results.length) return null;
  return (
    <div style={{ marginBottom:14 }}>
      <button onClick={()=>setOpen(o=>!o)} style={{ width:'100%', display:'flex', alignItems:'center', gap:11, padding:'10px 18px', background:'none', border:'none', cursor:'pointer', textAlign:'left', fontFamily:'inherit' }}>
        <Crest k={t.crest} size={32} />
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ display:'flex', alignItems:'center', gap:6 }}>
            <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:15, letterSpacing:'-0.01em', whiteSpace:'nowrap' }}>{t.name}</span>
            {t.rel && <span style={{ ...mono, fontSize:7.5, padding:'2px 5px', borderRadius:4, background:t.rel==='Following'?redSoft:paper2, color:t.rel==='Following'?red:muted }}>{t.rel.toUpperCase()}</span>}
          </div>
          <div style={{ fontSize:11, color:muted, marginTop:1 }}>{t.stage} · {t.city}</div>
        </div>
        <Ic n="chev" s={16} sw={2} stroke={soft} style={{ transform:open?'rotate(90deg)':'none', transition:'transform .15s' }} />
      </button>
      {open && (
        <div style={{ paddingTop:2 }}>
          {live.map(m=><LiveCard key={m.id} m={m} onWatch={(mm)=>onWatch({ ...mm, tourName:t.name, stage:t.stage })} />)}
          {(upcoming.length>0 || results.length>0) && (
            <div style={{ margin:'0 18px 4px', border:'1px solid '+hair, borderRadius:14, overflow:'hidden' }}>
              {upcoming.map((m,i)=><UpcomingRow key={m.id} m={m} top={i===0} />)}
              {results.map((m,i)=><ResultRow key={m.id} m={m} top={i===0 && upcoming.length===0} />)}
            </div>
          )}
          <button onClick={()=>onOpen&&onOpen(t)} style={{ display:'flex', alignItems:'center', gap:5, margin:'8px 18px 0', background:'none', border:'none', cursor:'pointer', fontFamily:'inherit', fontSize:12, fontWeight:600, color:ink2, padding:0 }}>
            View all fixtures <Ic n="arrow" s={14} sw={2} stroke={ink2} />
          </button>
        </div>
      )}
    </div>
  );
}

// read-only watch / match-detail screen — Info · Live · Scorecard · Commentary
const BATTERS = [
  { n:'Wiaan Mulder', r:22, b:12, f4:0, f6:2, sr:'183.3', out:false, strike:true },
  { n:'Donovan Ferreira', r:8, b:5, f4:0, f6:1, sr:'160.0', out:false, strike:false },
];
// full first-innings card (batting)
const INN1_BAT = [
  { n:'S Hope †', how:'c Owen b Shamsi', r:34, b:21, f4:3, f6:1, sr:'161.9' },
  { n:'M Kumar', how:'b Maharaj', r:13, b:15, f4:1, f6:0, sr:'86.7' },
  { n:'Wiaan Mulder', how:'not out', r:22, b:12, f4:0, f6:2, sr:'183.3' },
  { n:'Donovan Ferreira', how:'not out', r:8, b:5, f4:0, f6:1, sr:'160.0' },
];
const INN1_BOWL = [
  { n:'Mitchell Owen', ov:'4', m:0, r:34, w:1, econ:'8.50' },
  { n:'T Shamsi', ov:'3', m:0, r:21, w:2, econ:'7.00' },
  { n:'K Maharaj', ov:'4', m:0, r:28, w:1, econ:'7.00' },
];
const BOWLER = { n:'Mitchell Owen', w:0, r:21, ov:'1.2', econ:'15.75' };
const XI = {
  TSK:['S Hope †','M Kumar','Wiaan Mulder','Donovan Ferreira (c)','A Russell','S Rutherford','R Powell','A Hosein','M Theekshana','A Joseph','O Thomas'],
  WF:['W Sundar','M Owen','T Stubbs','H Brook (c)','J Inglis †','M Marsh','C Green','K Maharaj','T Shamsi','R Topley','A Joseph'],
};
const COMMENTARY = [
  ['14.3','Akhtar to Bilal, 1 run, worked to mid-on'],
  ['14.2','FOUR — punched through covers, in control'],
  ['14.1','dot, beaten outside off'],
  ['13.6','2 runs, clipped off the pads to deep square'],
  ['13.5','SIX — slog-swept over deep mid-wicket!'],
  ['13.4','single to long-on, easy'],
];
function WatchMatch({ m, onBack }) {
  const live = m.state === 'live';
  const done = m.state === 'result';
  const TABS = live ? ['live','scorecard','commentary','info'] : (done ? ['scorecard','commentary','info'] : ['info','scorecard','commentary']);
  const [tab, setTab] = useState(TABS[0]);
  const cur = TABS.includes(tab) ? tab : TABS[0];
  const [inn, setInn] = useState(1); // scorecard innings toggle
  const Th = ({ children, w, r }) => <span style={{ ...mono, fontSize:8.5, color:muted, width:w, textAlign:r?'right':'left', flexShrink:0 }}>{children}</span>;
  const battingK = m.sa!=='—' ? m.a : m.b;
  const otherK = battingK===m.a ? m.b : m.a;
  const stateWord = m.stateWord || 'Ball';
  const statusNote = m.statusNote || (live ? 'Live ball-by-ball' : null);

  return (
    <div style={{ position:'absolute', inset:0, zIndex:84, background:paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      {/* header: back + title + breadcrumb + actions */}
      <div style={{ padding:'4px 12px 0', flexShrink:0, display:'flex', alignItems:'center', gap:8 }}>
        <button onClick={onBack} style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:ink }}><Ic n="back" s={20} sw={2} /></button>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:15, letterSpacing:'-0.01em', whiteSpace:'nowrap' }}>{(CR[m.a]||{}).short} vs {(CR[m.b]||{}).short}</div>
          {m.tourName && <div style={{ fontFamily:'JetBrains Mono', fontSize:9, color:muted, marginTop:1, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{m.tourName} · {m.stage}</div>}
        </div>
        <span style={{ ...mono, fontSize:9, color:muted, display:'inline-flex', alignItems:'center', gap:4 }}><Ic n="eye" s={13} sw={1.8} stroke={muted} />{m.watchers||0}</span>
      </div>
      {/* tabs */}
      <div style={{ display:'flex', gap:7, padding:'10px 14px 10px', borderBottom:'1px solid '+hair, flexShrink:0 }}>
        {TABS.map(k=>{ const on=cur===k; const lbl={live:'Live',scorecard:'Scorecard',commentary:'Commentary',info:'Info'}[k];
          return <button key={k} onClick={()=>setTab(k)} style={{ display:'inline-flex', alignItems:'center', gap:6, height:30, padding:'0 13px', borderRadius:999, cursor:'pointer', fontFamily:'inherit', fontSize:12, fontWeight:on?700:600, border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink2 }}>
            {k==='live'&&live&&<span style={{ width:5, height:5, borderRadius:999, background:on?'#fff':red, animation:'ck-pulse 1.4s ease-in-out infinite' }} />}{lbl}
          </button>;
        })}
      </div>

      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {/* ── HERO scoreline ── */}
        <div style={{ background:ink, color:paper, padding:'16px 18px 20px', position:'relative', overflow:'hidden' }}>
          {/* soft glow */}
          <div style={{ position:'absolute', top:-40, right:-30, width:160, height:160, borderRadius:999, background:'radial-gradient(circle, rgba(220,77,50,0.28), transparent 70%)', pointerEvents:'none' }} />
          <div style={{ position:'relative' }}>
            {live
              ? <div style={{ ...mono, fontSize:9, color:'#fff', display:'inline-flex', alignItems:'center', gap:6, marginBottom:14, background:red, padding:'4px 9px', borderRadius:999 }}><span style={{ width:5, height:5, borderRadius:999, background:'#fff', animation:'ck-pulse 1.4s ease-in-out infinite' }} />LIVE</div>
              : <div style={{ ...mono, fontSize:9, opacity:0.55, marginBottom:14 }}>{m.state==='result'?'RESULT':'UPCOMING'}</div>}

            {(() => {
              const battingK = m.sa!=='—' ? m.a : m.b;
              const battingSc = m.sa!=='—' ? m.sa : m.sb;
              const otherK = battingK===m.a ? m.b : m.a;
              const otherSc = battingK===m.a ? m.sb : m.sa;
              const ov = (m.note.match(/([\d.]+)\s*ov/)||[])[1];
              const bc = CR[battingK]||{}, oc = CR[otherK]||{};
              const chaseM = m.note.match(/need\s+(\d+)\s+off\s+(\d+)/i);
              const isChase = live && chaseM && otherSc!=='—';

              const statusEl = (live && statusNote) ? (
                <div style={{ display:'flex', alignItems:'center', gap:9, marginTop:12, padding:'9px 13px', borderRadius:11, background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.08)' }}>
                  <Ic n="speaker" s={15} sw={1.8} stroke="rgba(255,255,255,0.7)" />
                  <span style={{ fontSize:12, fontWeight:600, opacity:0.85 }}>{statusNote}</span>
                  <span style={{ flex:1 }} />
                  <span style={{ ...mono, fontSize:8.5, opacity:0.5 }}>{stateWord.toUpperCase()}</span>
                </div>
              ) : null;

              if (isChase) {
                const need = +chaseM[1], off = +chaseM[2];
                const req = off>0 ? (need/off*6).toFixed(1) : '—';
                const wk = (battingSc.split('/')[1]!=null) ? (10 - +battingSc.split('/')[1]) : null;
                return (
                  <>
                    <div style={{ textAlign:'center', margin:'18px 0 4px' }}>
                      <div style={{ ...mono, fontSize:9, opacity:0.55, letterSpacing:'0.1em' }}>{(bc.name||battingK).toUpperCase()} NEED</div>
                      <div style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:50, lineHeight:1, letterSpacing:'-0.02em', marginTop:4 }}>{need}<span style={{ fontSize:21, opacity:0.6 }}> off </span>{off}</div>
                      <div style={{ ...mono, fontSize:10, opacity:0.6, marginTop:8 }}>REQ {req}{wk!=null?` · ${wk} WKT${wk===1?'':'S'} IN HAND`:''}</div>
                    </div>
                    <div style={{ display:'flex', gap:8, marginTop:14 }}>
                      <div style={{ flex:1, minWidth:0, display:'flex', alignItems:'center', gap:9, padding:'9px 11px', borderRadius:11, background:'rgba(255,255,255,0.07)' }}>
                        <Crest k={battingK} size={26} />
                        <span style={{ flex:1, minWidth:0, fontWeight:600, fontSize:12, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{bc.name||battingK}</span>
                        <span style={{ ...mono, fontWeight:700, fontSize:14 }}>{battingSc}</span>
                      </div>
                      <div style={{ flex:1, minWidth:0, display:'flex', alignItems:'center', gap:9, padding:'9px 11px', borderRadius:11, background:'rgba(255,255,255,0.04)', opacity:0.7 }}>
                        <Crest k={otherK} size={26} />
                        <span style={{ flex:1, minWidth:0, fontWeight:600, fontSize:12, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{oc.name||otherK}</span>
                        <span style={{ ...mono, fontWeight:700, fontSize:14 }}>{otherSc}</span>
                      </div>
                    </div>
                    {statusEl}
                  </>
                );
              }

              return (
                <>
                  <div style={{ display:'flex', alignItems:'center', gap:12 }}>
                    <Crest k={battingK} size={42} />
                    <div style={{ flex:1, minWidth:0 }}>
                      <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:16, letterSpacing:'-0.01em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{bc.name||battingK}</div>
                      {live && <div style={{ ...mono, fontSize:9, opacity:0.6, marginTop:2 }}>BATTING{ov?` · ${ov} OV`:''}</div>}
                    </div>
                    <div style={{ textAlign:'right' }}>
                      <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:30, letterSpacing:'-0.01em', lineHeight:1 }}>{battingSc}</span>
                    </div>
                  </div>
                  <div style={{ display:'flex', alignItems:'center', gap:12, marginTop:10, opacity:0.62 }}>
                    <Crest k={otherK} size={26} />
                    <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:600, fontSize:13, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{oc.name||otherK}</span>
                    <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:15 }}>{otherSc==='—'?'Yet to bat':otherSc}</span>
                  </div>
                  <div style={{ marginTop:14, padding:'10px 14px', borderRadius:12, background:'rgba(255,255,255,0.08)', fontSize:12.5, fontWeight:600, fontFamily:'Inter Tight', letterSpacing:'-0.01em' }}>{m.note}</div>
                  {statusEl}
                  {live && (
                    <div style={{ display:'flex', gap:10, marginTop:12 }}>
                      {[['CRR','7.71'],['REQ','9.45'],['BALLS LEFT','22']].map(([l,v])=>(
                        <div key={l} style={{ flex:1, padding:'9px 10px', borderRadius:10, background:'rgba(255,255,255,0.06)' }}>
                          <div style={{ ...mono, fontSize:7.5, opacity:0.55 }}>{l}</div>
                          <div style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:15, marginTop:2 }}>{v}</div>
                        </div>
                      ))}
                    </div>
                  )}
                </>
              );
            })()}
          </div>
        </div>

        {cur==='live' && (
          <div style={{ padding:'16px 18px' }}>
            {/* this over */}
            <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:11 }}>
              <span style={{ ...mono, fontSize:10, color:muted }}>THIS OVER</span>
              <span style={{ ...mono, fontSize:9, color:soft }}>· OVER 17</span>
              <span style={{ flex:1 }} />
              <span style={{ ...mono, fontSize:9, color:soft }}>PREV 14 ·</span>
              <span style={{ ...mono, fontSize:9, color:ink2 }}>7 RUNS</span>
            </div>
            <div style={{ display:'flex', gap:8, marginBottom:22 }}>
              {['1','4','0','W','2','·'].map((b,i)=>{ const wk=b==='W',four=b==='4',six=b==='6',dot=b==='·';
                return <div key={i} style={{ width:33, height:33, borderRadius:999, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'JetBrains Mono', fontWeight:700, fontSize:12.5,
                  background: wk?red:(four||six)?green:dot?paper:paper2, color: (wk||four||six)?'#fff':dot?soft:ink, border:'1px solid '+(wk?red:(four||six)?green:hair) }}>{b}</div>;
              })}
            </div>

            {/* batters card */}
            <div style={{ border:'1px solid '+hair, borderRadius:14, overflow:'hidden', marginBottom:14 }}>
              <div style={{ display:'flex', alignItems:'center', padding:'10px 14px 9px', background:paper2 }}>
                <Th w={'auto'}>BATTING</Th><span style={{ flex:1 }} />
                <Th w={50} r>R (B)</Th><Th w={28} r>4S</Th><Th w={28} r>6S</Th><Th w={48} r>SR</Th>
              </div>
              {BATTERS.map((p,i)=>(
                <div key={i} style={{ display:'flex', alignItems:'center', padding:'11px 14px', borderTop:'1px solid '+hair, background: p.strike?'rgba(220,77,50,0.04)':surface }}>
                  <span style={{ fontFamily:'Inter Tight', fontWeight:600, fontSize:13.5, color:ink, display:'inline-flex', alignItems:'center', gap:6 }}>{p.n}{p.strike && <span style={{ width:6, height:6, borderRadius:999, background:red, display:'inline-block' }} />}</span>
                  <span style={{ flex:1 }} />
                  <span style={{ ...numCell, width:50, fontSize:13, color:ink, fontWeight:700 }}>{p.r} <span style={{ color:muted, fontSize:10, fontWeight:600 }}>({p.b})</span></span>
                  <span style={{ ...numCell, width:28 }}>{p.f4}</span>
                  <span style={{ ...numCell, width:28 }}>{p.f6}</span>
                  <span style={{ ...numCell, width:48 }}>{p.sr}</span>
                </div>
              ))}
              <div style={{ fontSize:11, color:muted, padding:'9px 14px', borderTop:'1px solid '+hair, background:paper2 }}>Partnership <b style={{ color:ink2 }}>16 (8)</b> · Last out: M Kumar 13 (15)</div>
            </div>

            {/* bowler card */}
            <div style={{ border:'1px solid '+hair, borderRadius:14, overflow:'hidden' }}>
              <div style={{ display:'flex', alignItems:'center', padding:'10px 14px 9px', background:paper2 }}>
                <Th>BOWLING</Th><span style={{ flex:1 }} /><Th w={50} r>W-R</Th><Th w={44} r>OV</Th><Th w={50} r>ECON</Th>
              </div>
              <div style={{ display:'flex', alignItems:'center', padding:'11px 14px', borderTop:'1px solid '+hair }}>
                <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:600, fontSize:13.5, color:ink }}>{BOWLER.n} <span style={{ ...mono, fontSize:8, color:red, marginLeft:2 }}>●</span></span>
                <span style={{ ...numCell, width:50, fontWeight:700, color:ink, fontSize:13 }}>{BOWLER.w}-{BOWLER.r}</span>
                <span style={{ ...numCell, width:44 }}>{BOWLER.ov}</span>
                <span style={{ ...numCell, width:50 }}>{BOWLER.econ}</span>
              </div>
            </div>
            <div style={{ height:24 }} />
          </div>
        )}

        {cur==='scorecard' && (
          <div style={{ padding:'14px 18px' }}>
            {/* innings toggle */}
            <div style={{ display:'flex', gap:7, marginBottom:14 }}>
              {[[1,(CR[m.a]||{}).short],[2,(CR[m.b]||{}).short]].map(([n,lbl])=>{ const on=inn===n;
                return <button key={n} onClick={()=>setInn(n)} style={{ flex:1, height:34, borderRadius:10, cursor:'pointer', fontFamily:'inherit', fontSize:12.5, fontWeight:on?700:600, border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink2 }}>{lbl} innings</button>;
              })}
            </div>
            {inn===2 && !done ? (
              <div style={{ textAlign:'center', padding:'48px 24px', color:muted }}>
                <div style={{ width:54, height:54, borderRadius:16, background:paper2, border:'1px solid '+hair, display:'flex', alignItems:'center', justifyContent:'center', margin:'0 auto 12px' }}><Ic n="bat" s={24} sw={1.6} stroke={soft} /></div>
                <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:15, color:ink }}>Innings not started</div>
                <div style={{ fontSize:12.5, marginTop:4, lineHeight:1.5 }}>{(CR[m.b]||{}).name} bat after the innings break.</div>
              </div>
            ) : (
              <>
                <div style={{ display:'flex', alignItems:'center', padding:'0 0 8px' }}>
                  <Th w={'auto'}>BATTER</Th><span style={{ flex:1 }} />
                  <Th w={54} r>R (B)</Th><Th w={56} r>4s/6s</Th><Th w={46} r>SR</Th>
                </div>
                {INN1_BAT.map((p,i)=>(
                  <div key={i} style={{ display:'flex', alignItems:'flex-start', padding:'9px 0', borderTop:'1px solid '+hair }}>
                    <span style={{ minWidth:0 }}>
                      <span style={{ display:'block', fontFamily:'Inter Tight', fontWeight:600, fontSize:13, color:ink }}>{p.n}</span>
                      <span style={{ fontSize:10.5, color:muted }}>{p.how}</span>
                    </span>
                    <span style={{ flex:1 }} />
                    <span style={{ ...numCell, width:54, fontWeight:700, color:ink, fontSize:13 }}>{p.r} <span style={{ color:muted, fontSize:10 }}>({p.b})</span></span>
                    <span style={{ ...numCell, width:56 }}>{p.f4}/{p.f6}</span>
                    <span style={{ ...numCell, width:46 }}>{p.sr}</span>
                  </div>
                ))}
                <div style={{ display:'flex', justifyContent:'space-between', padding:'10px 0', borderTop:'2px solid '+line, marginTop:2 }}>
                  <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13, color:ink }}>Total</span>
                  <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:13, color:ink }}>{m.sa} (16.2 ov)</span>
                </div>
                {/* bowling card */}
                <div style={{ ...mono, fontSize:10, color:muted, margin:'18px 0 8px' }}>BOWLING</div>
                <div style={{ display:'flex', alignItems:'center', padding:'0 0 8px' }}>
                  <Th w={'auto'}>BOWLER</Th><span style={{ flex:1 }} />
                  <Th w={40} r>O</Th><Th w={34} r>M</Th><Th w={40} r>R</Th><Th w={34} r>W</Th><Th w={48} r>ECON</Th>
                </div>
                {INN1_BOWL.map((p,i)=>(
                  <div key={i} style={{ display:'flex', alignItems:'center', padding:'9px 0', borderTop:'1px solid '+hair }}>
                    <span style={{ fontFamily:'Inter Tight', fontWeight:600, fontSize:13, color:ink }}>{p.n}</span>
                    <span style={{ flex:1 }} />
                    <span style={{ ...numCell, width:40 }}>{p.ov}</span>
                    <span style={{ ...numCell, width:34 }}>{p.m}</span>
                    <span style={{ ...numCell, width:40 }}>{p.r}</span>
                    <span style={{ ...numCell, width:34, fontWeight:700, color:ink }}>{p.w}</span>
                    <span style={{ ...numCell, width:48 }}>{p.econ}</span>
                  </div>
                ))}
              </>
            )}
            <div style={{ height:24 }} />
          </div>
        )}

        {cur==='commentary' && (
          <div style={{ padding:'14px 18px' }}>
            {live && (
              <div style={{ display:'flex', gap:10, marginBottom:16 }}>
                {[['TARGET','187'],['CRR','7.71'],['REQ','9.45']].map(([l,v])=>(
                  <div key={l} style={{ flex:1, padding:'10px 12px', borderRadius:11, background:paper2, border:'1px solid '+hair }}>
                    <div style={{ ...mono, fontSize:8, color:muted }}>{l}</div>
                    <div style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:15, color:ink, marginTop:2 }}>{v}</div>
                  </div>
                ))}
              </div>
            )}
            {live && <div style={{ padding:'11px 14px', borderRadius:11, background:'rgba(220,77,50,0.06)', border:'1px solid rgba(220,77,50,0.18)', fontSize:12.5, fontWeight:600, color:red, marginBottom:16, fontFamily:'Inter Tight' }}>{(CR[otherK]||{}).short} need 61 runs in 22 balls</div>}
            {COMMENTARY.map(([o,t],i)=>(
              <div key={i} style={{ display:'flex', gap:12, padding:'9px 0', borderTop:i?'1px solid '+hair:'none' }}>
                <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:11, color:muted, flexShrink:0, width:30 }}>{o}</span>
                <span style={{ fontSize:12.5, color:ink, lineHeight:1.45 }}>{t}</span>
              </div>
            ))}
            <div style={{ height:24 }} />
          </div>
        )}

        {cur==='info' && (
          <div style={{ padding:'14px 18px' }}>
            {/* toss / match facts */}
            {live || done ? (
              <div style={{ display:'flex', alignItems:'center', gap:10, padding:'12px 14px', borderRadius:12, background:paper2, border:'1px solid '+hair, marginBottom:16 }}>
                <Ic n="coin" s={18} sw={1.8} stroke={ink2} />
                <span style={{ fontSize:12.5, color:ink2 }}><b style={{ color:ink, fontFamily:'Inter Tight', fontWeight:700 }}>{(CR[m.a]||{}).short}</b> won the toss & chose to bat</span>
              </div>
            ) : (
              <div style={{ display:'flex', alignItems:'center', gap:10, padding:'12px 14px', borderRadius:12, background:cream, marginBottom:16 }}>
                <Ic n="coin" s={18} sw={1.8} stroke={'var(--amber-ink)'} />
                <span style={{ fontSize:12.5, color:'var(--amber-ink)', fontWeight:600 }}>Toss at {m.toss||'30 min before start'}</span>
              </div>
            )}
            {[['Match', `${m.tourName||'Friendly'} · ${m.stage||''}`],['Format', m.fmt||'T20 · 20 overs'],['Date', m.date||'Today'],['Venue', m.venue||'Model Town Ground, Lahore']].map(([k,v],i)=>(
              <div key={i} style={{ display:'flex', justifyContent:'space-between', gap:12, padding:'11px 0', borderTop:i?'1px solid '+hair:'none' }}>
                <span style={{ fontSize:12.5, color:muted }}>{k}</span>
                <span style={{ fontSize:12.5, color:ink, fontWeight:600, textAlign:'right' }}>{v}</span>
              </div>
            ))}
            {/* playing XIs */}
            <div style={{ ...mono, fontSize:10, color:muted, margin:'20px 0 10px' }}>PLAYING XI</div>
            {[m.a,m.b].map(k=>(
              <div key={k} style={{ marginBottom:14 }}>
                <div style={{ display:'flex', alignItems:'center', gap:9, marginBottom:8 }}>
                  <Crest k={k} size={24} /><span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13.5, color:ink }}>{(CR[k]||{}).name||k}</span>
                </div>
                <div style={{ display:'flex', flexWrap:'wrap', gap:'6px 8px' }}>
                  {(XI[(CR[k]||{}).short]||XI.TSK).map((p,i)=>(
                    <span key={i} style={{ fontSize:11.5, color:ink2, padding:'5px 10px', borderRadius:999, background:paper2, border:'1px solid '+hair }}>{p}</span>
                  ))}
                </div>
              </div>
            ))}
            <div style={{ height:24 }} />
          </div>
        )}
      </div>
    </div>
  );
}

function PublicMatches({ header, onOpenTournament }) {
  const [watch, setWatch] = useState(null);
  const liveCount = TOURS.reduce((n,t)=>n+t.matches.filter(m=>m.state==='live').length,0);
  const [tab, setTab] = useState(liveCount>0 ? 'live' : 'following');

  const SHOW = { live:['live'], following:['live','upcoming','result'], upcoming:['upcoming'], results:['result'] };
  const show = SHOW[tab];
  // Following tab → only relevant tournaments; others show every tournament
  const pool = tab==='following' ? TOURS.filter(t=>t.rel) : TOURS;
  const relevant = pool.filter(t=>t.rel);
  const others = pool.filter(t=>!t.rel);
  const groups = (list) => list.map(t=><TourGroup key={t.id} t={t} onOpen={onOpenTournament} onWatch={setWatch} show={show} />).filter(Boolean);
  const relEls = groups(relevant);
  const otherEls = groups(others);
  const empty = relEls.every(e=>!e) && otherEls.every(e=>!e);

  const TABS = [
    { k:'live', l: liveCount>0 ? `Live · ${liveCount}` : 'Live' },
    { k:'following', l:'Following' },
    { k:'upcoming', l:'Upcoming' },
    { k:'results', l:'Results' },
  ];

  return (
    <div style={{ flex:1, display:'flex', flexDirection:'column', background:paper, minHeight:0, position:'relative', overflow:'hidden' }}>
      {header}
      <div style={{ flexShrink:0, background:paper }}>
        <div style={{ display:'flex', gap:7, overflowX:'auto', padding:'12px 18px 10px', borderBottom:'1px solid '+hair }}>
          {TABS.map(tb=>{
            const on = tab===tb.k;
            const isLive = tb.k==='live' && liveCount>0;
            return (
              <button key={tb.k} onClick={()=>setTab(tb.k)} style={{ flexShrink:0, display:'inline-flex', alignItems:'center', gap:6, height:32, padding:'0 13px', borderRadius:999, cursor:'pointer', fontFamily:'inherit', fontSize:12.5, fontWeight:on?700:600,
                border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink2 }}>
                {isLive && <span style={{ width:5, height:5, borderRadius:999, background:on?'#fff':red, animation:'ck-pulse 1.4s ease-in-out infinite' }} />}{tb.l}
              </button>
            );
          })}
        </div>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0, paddingTop:10 }}>
        {empty ? (
          <div style={{ padding:'56px 30px', textAlign:'center' }}>
            <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:16, color:ink }}>{tab==='live'?'Nothing live right now':tab==='following'?'Nothing from who you follow':tab==='upcoming'?'No upcoming matches':'No results yet'}</div>
            <div style={{ fontSize:13, color:muted, marginTop:6, lineHeight:1.5 }}>{tab==='live'?'Live tournament matches will show here the moment they start.':tab==='following'?'Follow teams and tournaments to see their matches first.':'Check back soon.'}</div>
          </div>
        ) : (<>
          {relEls}
          {tab!=='following' && otherEls.some(Boolean) && <div style={{ ...mono, fontSize:10, color:muted, padding:'10px 18px 4px', borderTop:'1px solid '+hair, marginTop:4 }}>MORE ACROSS MATCHDAY</div>}
          {tab!=='following' && otherEls}
          <div style={{ height:24 }} />
        </>)}
      </div>
      {watch && <WatchMatch m={watch} onBack={()=>setWatch(null)} />}
    </div>
  );
}

window.PublicMatches = PublicMatches;
})();

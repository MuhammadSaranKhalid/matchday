// tournament-create.jsx — 8-step Create-Tournament wizard for the prototype.
// Adapted from uploads/files/matchday Create Tournament.html.
// Exports window.TournamentCreate({ onExit, onCreated }) and window.TournamentCreated.

(function () {
const { useState } = React;
const C = {
  ink:'var(--ink)', ink2:'var(--ink-2)', muted:'var(--muted)', soft:'var(--soft)',
  paper:'var(--paper)', paper2:'var(--paper-2)', surface:'var(--surface)', hair:'var(--hairline)', line:'var(--line)',
  red:'var(--red)', redSoft:'var(--red-soft)', green:'var(--green)', greenSoft:'var(--green-soft)', greenInk:'var(--green-ink)',
  amber:'var(--amber)', amberInk:'var(--amber-ink)', cream:'var(--cream)',
};
const display = (size, weight=700) => ({ fontFamily:'Inter Tight, system-ui', fontSize:size, fontWeight:weight, letterSpacing:'-0.025em', color:C.ink, lineHeight:1.1 });
const mono = { fontFamily:'JetBrains Mono, monospace', fontWeight:700, letterSpacing:'0.10em', textTransform:'uppercase' };
const COLORS = ['oklch(0.62 0.19 28)','oklch(0.45 0.12 280)','oklch(0.50 0.13 200)','oklch(0.55 0.15 145)','oklch(0.58 0.13 60)','oklch(0.45 0.10 30)','oklch(0.40 0.06 250)','oklch(0.55 0.17 305)'];
const monogram = (n) => { const w=n.trim().split(/\s+/).filter(Boolean); if(!w.length) return '?'; if(w.length===1) return w[0].slice(0,2).toUpperCase(); return (w[0][0]+w[w.length-1][0]).toUpperCase(); };

const PATHS = {
  back:<path d="M19 12H5M12 19l-7-7 7-7"/>, next:<path d="M9 18l6-6-6-6"/>, check:<polyline points="20 6 9 17 4 12"/>,
  bracket:<><path d="M3 5h5a2 2 0 0 1 2 2v3M3 19h5a2 2 0 0 0 2-2v-3M10 12h5M15 12a2 2 0 0 0 2 2h4M15 12a2 2 0 0 1 2-2h4"/></>,
  table:<><rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 9h18M3 14h18M9 4v16"/></>,
  groups:<><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></>,
  dice:<><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8" cy="8" r="1.2"/><circle cx="16" cy="8" r="1.2"/><circle cx="12" cy="12" r="1.2"/><circle cx="8" cy="16" r="1.2"/><circle cx="16" cy="16" r="1.2"/></>,
  hand:<path d="M7 11V6.5a1.5 1.5 0 0 1 3 0V10m0 0V5a1.5 1.5 0 0 1 3 0v5m0-1a1.5 1.5 0 0 1 3 0v6a6 6 0 0 1-6 6h-1a6 6 0 0 1-5.2-3l-1.8-3a1.5 1.5 0 0 1 2.6-1.5L7 14"/>,
  globe:<><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.5 2.5 15.5 0 18M12 3c-2.5 2.5-2.5 15.5 0 18"/></>,
  lock:<><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></>,
  share:<><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/></>,
  money:<><circle cx="12" cy="12" r="9"/><path d="M14.5 9.5a2.5 2.5 0 0 0-2.5-1.5c-1.4 0-2.5.8-2.5 2s1.1 1.8 2.5 2 2.5.8 2.5 2-1.1 2-2.5 2a2.5 2.5 0 0 1-2.5-1.5M12 6.5v11"/></>,
  cal:<><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></>,
  pin:<><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></>,
  users:<><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></>,
  trophy:<><path d="M6 4h12v4a6 6 0 0 1-12 0z"/><path d="M6 6H3v2a3 3 0 0 0 3 3M18 6h3v2a3 3 0 0 1-3 3M9 20h6M12 14v6"/></>,
  plus:<path d="M12 5v14M5 12h14"/>, minus:<path d="M5 12h14"/>, info:<><circle cx="12" cy="12" r="9"/><path d="M12 16v-4M12 8h.01"/></>,
};
function Icon({ name, size=18, stroke='currentColor', sw=2, style }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style}>{PATHS[name]||null}</svg>;
}
function Crest({ size=44, bg, fg=C.paper, label, radius }) {
  return <div style={{ width:size, height:size, borderRadius:radius!=null?radius:size*0.24, flexShrink:0, background:bg, color:fg, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:size*0.36, letterSpacing:'-0.03em' }}>{label}</div>;
}
function SecLabel({ children, hint }) {
  return <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', gap:8, marginBottom:9 }}>
    <span style={{ ...mono, fontSize:10, color:C.muted }}>{children}</span>{hint && <span style={{ fontSize:11, color:C.muted }}>{hint}</span>}
  </div>;
}
function Radio({ on }) {
  return <div style={{ width:22, height:22, borderRadius:999, flexShrink:0, border:'2px solid '+(on?C.ink:C.hair), background:on?C.ink:'transparent', display:'flex', alignItems:'center', justifyContent:'center' }}>{on && <Icon name="check" size={11} stroke={C.paper} sw={3} />}</div>;
}
function OptCard({ on, onClick, icon, title, sub, right }) {
  return <button onClick={onClick} style={{ display:'flex', alignItems:'center', gap:12, padding:13, width:'100%', textAlign:'left', fontFamily:'inherit', cursor:'pointer', background:on?C.paper2:C.paper, border:'2px solid '+(on?C.ink:C.hair), borderRadius:14, marginBottom:8 }}>
    {icon && <div style={{ width:38, height:38, borderRadius:11, background:on?C.ink:C.paper2, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Icon name={icon} size={19} stroke={on?C.paper:C.ink} sw={2} /></div>}
    <div style={{ flex:1, minWidth:0 }}>
      <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14.5 }}>{title}</div>
      {sub && <div style={{ fontSize:11.5, color:C.muted, marginTop:2, lineHeight:1.4 }}>{sub}</div>}
    </div>
    {right!==undefined ? right : <Radio on={on} />}
  </button>;
}
function Stepper({ value, min, max, onChange, suffix }) {
  const b = (dis) => ({ width:38, height:38, borderRadius:11, flexShrink:0, border:'1px solid '+C.hair, background:C.paper, cursor:dis?'default':'pointer', color:dis?C.soft:C.ink, display:'flex', alignItems:'center', justifyContent:'center', padding:0 });
  return <div style={{ display:'flex', alignItems:'center', gap:12 }}>
    <button onClick={value<=min?undefined:()=>onChange(value-1)} style={b(value<=min)}><Icon name="minus" size={15} sw={2.4} /></button>
    <div style={{ flex:1, textAlign:'center' }}><span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:19, color:C.ink, fontVariantNumeric:'tabular-nums' }}>{value}</span>{suffix && <span style={{ fontSize:12, color:C.muted, marginLeft:6 }}>{suffix}</span>}</div>
    <button onClick={value>=max?undefined:()=>onChange(value+1)} style={b(value>=max)}><Icon name="plus" size={15} sw={2.4} /></button>
  </div>;
}
function Toggle({ on, onChange, title, sub }) {
  return <div onClick={()=>onChange(!on)} style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 14px', border:'1px solid '+C.hair, borderRadius:14, background:C.paper, cursor:'pointer' }}>
    <div style={{ flex:1 }}><div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14 }}>{title}</div>{sub && <div style={{ fontSize:11.5, color:C.muted, marginTop:2 }}>{sub}</div>}</div>
    <div style={{ width:44, height:26, borderRadius:999, background:on?C.ink:C.line, position:'relative', transition:'background .15s', flexShrink:0 }}>
      <div style={{ position:'absolute', top:3, left:on?21:3, width:20, height:20, borderRadius:999, background:'#fff', transition:'left .15s', boxShadow:'0 1px 2px rgba(0,0,0,0.2)' }} />
    </div>
  </div>;
}
function Field({ value, onChange, placeholder, max, suffix }) {
  return <div style={{ display:'flex', alignItems:'center', gap:8, padding:'12px 14px', borderRadius:12, border:'1.5px solid '+C.line, background:C.surface }}>
    <input value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder} maxLength={max}
      style={{ flex:1, border:'none', outline:'none', background:'transparent', fontSize:15, fontFamily:'inherit', color:C.ink }} />
    {suffix && <span style={{ ...mono, fontSize:9, color:C.muted }}>{suffix}</span>}
  </div>;
}
function RevRow({ k, v, last }) {
  return <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', gap:12, padding:'11px 16px', borderBottom:last?'none':'1px solid '+C.hair, background:C.paper }}>
    <span style={{ fontSize:12, color:C.muted, flexShrink:0 }}>{k}</span><span style={{ fontSize:12.5, fontWeight:600, color:C.ink, textAlign:'right' }}>{v}</span>
  </div>;
}

const PRESETS = [
  { id:'t20', label:'T20', overs:20, players:11, ball:'leather', max:4 },
  { id:'t10', label:'T10', overs:10, players:11, ball:'leather', max:2 },
  { id:'odi', label:'ODI', overs:50, players:11, ball:'leather', max:10 },
  { id:'h100', label:'The Hundred', balls:100, players:11, ball:'leather', max:20 },
  { id:'8a', label:'8-a-side', overs:12, players:8, ball:'tape', max:3 },
  { id:'tape', label:'Tape-ball', overs:16, players:11, ball:'tape', max:4 },
  { id:'box', label:'Box cricket', overs:6, players:6, ball:'tennis', max:2 },
];
const BALL_DOT = { leather:'#a8332e', tape:'#d8a85e', tennis:'#cdd64a' };
const BALL_LABEL = { leather:'Leather', tape:'Tape-ball', tennis:'Tennis' };
const presetById = (id) => PRESETS.find(p=>p.id===id) || PRESETS[0];
const STRUCT = { knockout:{ label:'Knockout' }, league:{ label:'League' }, hybrid:{ label:'Groups → Knockout' } };

function StepStructure({ d, set }) {
  const opts = [
    ['knockout','bracket','Knockout','Single elimination — lose and you’re out, last team standing wins.'],
    ['league','table','League','Round-robin — everyone plays everyone, a points table decides it.'],
    ['hybrid','groups','Groups → Knockout','Group stage into a knockout — the classic cup shape.'],
  ];
  return <div style={{ padding:'16px 18px 8px' }}>
    <SecLabel hint="Shapes the whole setup">Pick a structure</SecLabel>
    {opts.map(([k,ic,t,s]) => <OptCard key={k} on={d.structure===k} onClick={()=>set({ structure:k })} icon={ic} title={t} sub={s} />)}
  </div>;
}
function StepIdentity({ d, set }) {
  const mg = monogram(d.name);
  return <div style={{ padding:'18px 18px 8px' }}>
    <div style={{ display:'flex', justifyContent:'center', marginBottom:18 }}><Crest size={84} bg={d.color} label={mg} radius={22} /></div>
    <SecLabel hint={d.name.trim().length>=2 ? `Crest: ${mg}` : ''}>Tournament name</SecLabel>
    <Field value={d.name} onChange={v=>set({ name:v })} placeholder="e.g. Ramzan Night Cup" max={40} suffix={`${d.name.length}/40`} />
    <div style={{ height:18 }} />
    <SecLabel>Colour</SecLabel>
    <div style={{ display:'flex', gap:10, flexWrap:'wrap' }}>
      {COLORS.map(c => { const on=d.color===c; return (
        <button key={c} onClick={()=>set({ color:c })} style={{ width:38, height:38, borderRadius:11, background:c, border:'none', cursor:'pointer', position:'relative', outline:on?'2px solid '+C.ink:'none', outlineOffset:2 }}>
          {on && <span style={{ position:'absolute', inset:0, display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="check" size={16} stroke="#fff" sw={3} /></span>}
        </button>
      );})}
    </div>
  </div>;
}
function StepFormat({ d, set }) {
  return <div style={{ padding:'16px 18px 8px' }}>
    <SecLabel hint="Same for every match">Match format</SecLabel>
    <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8, marginBottom:14 }}>
      {PRESETS.map(p => { const on=d.format===p.id; const meta = p.balls ? `${p.balls} balls` : `${p.overs} overs`; return (
        <button key={p.id} onClick={()=>set({ format:p.id })} style={{ textAlign:'left', cursor:'pointer', fontFamily:'inherit', padding:'13px 13px', borderRadius:14, background:on?C.paper2:C.paper, border:'1.5px solid '+(on?C.ink:C.hair) }}>
          <div style={{ display:'flex', alignItems:'center', gap:7 }}>
            <span style={{ width:10, height:10, borderRadius:999, background:BALL_DOT[p.ball], flexShrink:0, border:p.ball==='tennis'?'none':'1px solid rgba(0,0,0,0.12)' }} />
            <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.02em', whiteSpace:'nowrap' }}>{p.label}</span>
            {on && <span style={{ marginLeft:'auto', display:'flex' }}><Icon name="check" size={13} stroke={C.ink} sw={2.6} /></span>}
          </div>
          <div style={{ ...mono, fontSize:8.5, color:C.muted, marginTop:9 }}>{meta} · {p.players}/side</div>
          <div style={{ fontSize:10.5, color:C.ink2, marginTop:3 }}>{BALL_LABEL[p.ball]} · {p.max} max/bow</div>
        </button>
      );})}
    </div>
    <div style={{ ...mono, fontSize:9, color:C.muted, textAlign:'center' }}>EVERY FIXTURE PLAYS THIS FORMAT</div>
  </div>;
}
function StepSettings({ d, set }) {
  const s = d.structure;
  return <div style={{ padding:'16px 18px 8px' }}>
    {(s==='knockout' || s==='hybrid') && (
      <>
        {s==='hybrid' && <>
          <SecLabel>Groups & advancement</SecLabel>
          <div style={{ border:'1px solid '+C.hair, borderRadius:14, padding:'14px', marginBottom:8 }}>
            <div style={{ fontSize:12, color:C.ink2, marginBottom:10 }}>Number of groups</div>
            <Stepper value={d.groups} min={2} max={8} onChange={v=>set({ groups:v })} suffix="groups" />
            <div style={{ height:1, background:C.hair, margin:'14px 0' }} />
            <div style={{ fontSize:12, color:C.ink2, marginBottom:10 }}>Advance from each group</div>
            <Stepper value={d.advance} min={1} max={4} onChange={v=>set({ advance:v })} suffix="per group" />
            <div style={{ display:'flex', alignItems:'center', gap:7, marginTop:12, padding:'9px 11px', borderRadius:10, background:C.paper2 }}>
              <Icon name="info" size={14} stroke={C.muted} sw={2} />
              <span style={{ fontSize:11, color:C.ink2 }}>{d.groups} groups · top {d.advance} → <b style={{color:C.ink}}>{d.groups*d.advance} into the knockout</b></span>
            </div>
          </div>
        </>}
        <SecLabel>Seeding the bracket</SecLabel>
        <OptCard on={d.seeding==='random'} onClick={()=>set({ seeding:'random' })} icon="dice" title="Random draw" sub="Shuffle teams into the bracket. No setup, reads as fair." />
        <OptCard on={d.seeding==='manual'} onClick={()=>set({ seeding:'manual' })} icon="hand" title="Manual / seeded" sub="Place teams yourself, or seed 1…N to keep the strong ones apart." />
        <div style={{ height:10 }} />
        <Toggle on={d.thirdPlace} onChange={v=>set({ thirdPlace:v })} title="Third-place playoff" sub="An extra match between the losing semi-finalists." />
      </>
    )}
    {s==='league' && (
      <>
        <SecLabel>Round-robin</SecLabel>
        <OptCard on={d.rr==='single'} onClick={()=>set({ rr:'single' })} title="Single" sub="Everyone plays everyone once." />
        <OptCard on={d.rr==='double'} onClick={()=>set({ rr:'double' })} title="Double (home & away)" sub="Everyone plays everyone twice — double the fixtures." />
        <div style={{ height:10 }} />
        <SecLabel hint="Tap to edit">Points</SecLabel>
        <div style={{ border:'1px solid '+C.hair, borderRadius:14, overflow:'hidden' }}>
          {[['Win','2'],['Tie / no result','1'],['Loss','0']].map(([k,v],i)=>(
            <div key={k} style={{ display:'flex', justifyContent:'space-between', padding:'11px 14px', borderTop:i?'1px solid '+C.hair:'none' }}>
              <span style={{ fontSize:13, color:C.ink2 }}>{k}</span>
              <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:13, color:C.ink }}>{v} pts</span>
            </div>
          ))}
          <div style={{ display:'flex', alignItems:'center', gap:7, padding:'10px 14px', borderTop:'1px solid '+C.hair, background:C.paper2 }}>
            <Icon name="info" size={13} stroke={C.muted} sw={2} />
            <span style={{ fontSize:11, color:C.muted }}>Tie-break: points → NRR → head-to-head. Standard — editable under advanced.</span>
          </div>
        </div>
      </>
    )}
  </div>;
}
function StepEntry({ d, set }) {
  return <div style={{ padding:'16px 18px 8px' }}>
    <SecLabel>How teams join</SecLabel>
    <OptCard on={d.entry==='invite'} onClick={()=>set({ entry:'invite' })} icon="users" title="Invite only" sub="You add or invite the teams. A known line-up." />
    <OptCard on={d.entry==='open'} onClick={()=>set({ entry:'open' })} icon="share" title="Open registration" sub="Share a code — captains request to join. You approve." />
    {d.entry==='open' && (
      <div style={{ marginTop:2, marginBottom:8 }}>
        <SecLabel>Registration closes</SecLabel>
        <Field value={d.deadline} onChange={v=>set({ deadline:v })} placeholder="e.g. 15 Mar" />
      </div>
    )}
    <div style={{ height:8 }} />
    <SecLabel>Teams</SecLabel>
    <div style={{ display:'flex', gap:10 }}>
      <div style={{ flex:1, border:'1px solid '+C.hair, borderRadius:14, padding:'12px 14px' }}>
        <div style={{ ...mono, fontSize:8.5, color:C.muted, marginBottom:8 }}>MIN</div>
        <Stepper value={d.minT} min={2} max={d.maxT} onChange={v=>set({ minT:v })} />
      </div>
      <div style={{ flex:1, border:'1px solid '+C.hair, borderRadius:14, padding:'12px 14px' }}>
        <div style={{ ...mono, fontSize:8.5, color:C.muted, marginBottom:8 }}>MAX</div>
        <Stepper value={d.maxT} min={d.minT} max={32} onChange={v=>set({ maxT:v })} />
      </div>
    </div>
    <div style={{ height:14 }} />
    <SecLabel>Entry fee</SecLabel>
    <div style={{ display:'flex', gap:8, marginBottom:8 }}>
      {[['free','Free'],['paid','Paid entry']].map(([k,l])=>(
        <button key={k} onClick={()=>set({ fee:k })} style={{ flex:1, padding:'11px 0', borderRadius:12, cursor:'pointer', fontFamily:'inherit', fontWeight:600, fontSize:13.5, border:'2px solid '+(d.fee===k?C.ink:C.hair), background:d.fee===k?C.paper2:C.paper, color:C.ink }}>{l}</button>
      ))}
    </div>
    {d.fee==='paid' && (
      <>
        <Field value={d.feeAmt} onChange={v=>set({ feeAmt:v.replace(/[^0-9]/g,'') })} placeholder="2000" suffix="PKR / TEAM" />
        <div style={{ display:'flex', alignItems:'center', gap:7, marginTop:8, padding:'9px 11px', borderRadius:10, background:C.cream }}>
          <Icon name="money" size={14} stroke={C.amberInk} sw={2} />
          <span style={{ fontSize:11, color:C.amberInk }}>Tracked here as paid / unpaid — money is settled off-app.</span>
        </div>
      </>
    )}
  </div>;
}
function StepWindow({ d, set }) {
  return <div style={{ padding:'16px 18px 8px' }}>
    <SecLabel>When it runs</SecLabel>
    <div style={{ display:'flex', gap:10 }}>
      {[['startDate','Start'],['endDate','End']].map(([key,lbl])=>(
        <div key={key} style={{ flex:1 }}>
          <div style={{ ...mono, fontSize:8.5, color:C.muted, marginBottom:7 }}>{lbl.toUpperCase()}</div>
          <div style={{ display:'flex', alignItems:'center', gap:8, padding:'12px 14px', borderRadius:12, border:'1.5px solid '+C.line, background:C.surface }}>
            <Icon name="cal" size={15} stroke={C.muted} sw={2} />
            <input value={d[key]} onChange={e=>set({ [key]:e.target.value })} placeholder={lbl==='Start'?'18 Mar':'27 Mar'} style={{ flex:1, minWidth:0, border:'none', outline:'none', background:'transparent', fontSize:14, fontFamily:'inherit', color:C.ink }} />
          </div>
        </div>
      ))}
    </div>
    <div style={{ ...mono, fontSize:8.5, color:C.muted, textAlign:'center', margin:'10px 0 16px' }}>FIXTURE TIMES ARE SET PER MATCH LATER</div>
    <SecLabel>Default ground</SecLabel>
    <div style={{ display:'flex', alignItems:'center', gap:8, padding:'12px 14px', borderRadius:12, border:'1.5px solid '+C.line, background:C.surface }}>
      <Icon name="pin" size={15} stroke={C.muted} sw={2} />
      <input value={d.venue} onChange={e=>set({ venue:e.target.value })} placeholder="e.g. Liaquatabad floodlights" style={{ flex:1, border:'none', outline:'none', background:'transparent', fontSize:14, fontFamily:'inherit', color:C.ink }} />
    </div>
  </div>;
}
function StepVisibility({ d, set }) {
  return <div style={{ padding:'16px 18px 8px' }}>
    <SecLabel>Who can find it</SecLabel>
    {[['public','globe','Public','Anyone can find and follow it. Shows up in search and discovery.'],['private','lock','Private','Hidden. People need your link or code to see it.']].map(([k,ic,t,s])=>(
      <OptCard key={k} on={d.visibility===k} onClick={()=>set({ visibility:k })} icon={ic} title={t} sub={s} />
    ))}
  </div>;
}
function StepReview({ d }) {
  const p = presetById(d.format);
  const structRow = STRUCT[d.structure].label;
  const fmt = `${p.label} · ${p.players}/side · ${BALL_LABEL[p.ball].toLowerCase()}`;
  let shapeRow;
  if (d.structure==='league') shapeRow = d.rr==='double' ? 'Double round-robin' : 'Single round-robin';
  else if (d.structure==='knockout') shapeRow = `Single elimination · ${d.seeding} draw${d.thirdPlace?' · 3rd-place playoff':''}`;
  else shapeRow = `${d.groups} groups · top ${d.advance} advance · ${d.seeding} draw`;
  const entryRow = d.entry==='open' ? `Open registration${d.deadline?' · closes '+d.deadline:''}` : 'Invite only';
  const feeRow = d.fee==='paid' ? `${d.feeAmt||'—'} PKR / team (tracked)` : 'Free';
  return <div style={{ padding:'16px 18px 8px' }}>
    <div style={{ borderRadius:16, border:'1px solid '+C.hair, overflow:'hidden', marginBottom:16 }}>
      <div style={{ padding:16, background:C.ink, color:C.paper }}>
        <div style={{ ...mono, fontSize:9, opacity:0.65, marginBottom:12 }}>NEW TOURNAMENT · DRAFT</div>
        <div style={{ display:'flex', alignItems:'center', gap:13 }}>
          <Crest size={48} bg={d.color} label={monogram(d.name)} radius={14} />
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:17, letterSpacing:'-0.02em', lineHeight:1.15 }}>{d.name||'Untitled tournament'}</div>
            <div style={{ fontSize:11.5, opacity:0.7, marginTop:3 }}>{structRow} · {d.visibility}</div>
          </div>
        </div>
      </div>
      <div>
        <RevRow k="Structure" v={structRow} />
        <RevRow k="Match format" v={fmt} />
        <RevRow k="Shape" v={shapeRow} />
        <RevRow k="Entry" v={entryRow} />
        <RevRow k="Teams" v={`${d.minT}–${d.maxT}`} />
        <RevRow k="Entry fee" v={feeRow} />
        <RevRow k="Window" v={`${d.startDate||'TBD'} – ${d.endDate||'TBD'}`} />
        <RevRow k="Ground" v={d.venue||'—'} last />
      </div>
    </div>
    <div style={{ display:'flex', alignItems:'center', gap:7, padding:'10px 12px', borderRadius:11, background:C.paper2 }}>
      <Icon name="info" size={14} stroke={C.muted} sw={2} />
      <span style={{ fontSize:11.5, color:C.ink2 }}>Creating lands you in a <b style={{color:C.ink}}>Draft</b> — you add teams next.</span>
    </div>
  </div>;
}

const STEPS = ['Structure','Identity','Match format','Settings','Entry','When & where','Visibility','Review'];

function TournamentCreate({ onExit, onCreated }) {
  const [step, setStep] = useState(0);
  const [d, setD] = useState({
    structure:'knockout', name:'', color:COLORS[7], format:'tape',
    rr:'single', seeding:'random', thirdPlace:false, groups:2, advance:2,
    entry:'open', deadline:'', minT:4, maxT:16, fee:'free', feeAmt:'',
    startDate:'', endDate:'', venue:'', visibility:'public',
  });
  const set = (patch) => setD(prev => ({ ...prev, ...patch }));
  const valid = () => {
    if (step===1) return d.name.trim().length>=2;
    if (step===5) return d.startDate.trim() && d.endDate.trim();
    return true;
  };
  const titles = {
    0:['Structure','How is the tournament won?'],
    1:['Name & crest','Give it an identity.'],
    2:['Match format','What format do the games play?'],
    3:['Settings', d.structure==='league' ? 'Round-robin and points.' : d.structure==='hybrid' ? 'Groups, advancement, and the bracket.' : 'How the bracket is drawn.'],
    4:['Entry','Who plays, and how they get in.'],
    5:['When & where','The window and the default ground.'],
    6:['Visibility','Who can find it.'],
    7:['Review','One look before it’s created.'],
  };
  const [title, sub] = titles[step];
  const body = () => {
    switch(step){
      case 0: return <StepStructure d={d} set={set} />;
      case 1: return <StepIdentity d={d} set={set} />;
      case 2: return <StepFormat d={d} set={set} />;
      case 3: return <StepSettings d={d} set={set} />;
      case 4: return <StepEntry d={d} set={set} />;
      case 5: return <StepWindow d={d} set={set} />;
      case 6: return <StepVisibility d={d} set={set} />;
      case 7: return <StepReview d={d} />;
    }
  };
  const last = step===STEPS.length-1;
  return (
    <div style={{ position:'absolute', inset:0, zIndex:98, background:C.paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      <div style={{ padding:'2px 18px 16px', borderBottom:'1px solid '+C.hair, flexShrink:0 }}>
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:10 }}>
          <button onClick={()=> step===0 ? onExit() : setStep(step-1)} aria-label="Back" style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:C.ink }}>
            <Icon name="back" size={20} stroke={C.ink} sw={2} />
          </button>
          <div style={{ ...mono, fontSize:9.5, color:C.muted, flex:1 }}>Create tournament · {step+1}/{STEPS.length}</div>
        </div>
        <div style={{ display:'flex', gap:4, marginBottom:14 }}>
          {STEPS.map((_,i)=><div key={i} style={{ flex:1, height:3, borderRadius:2, background:i<=step?C.ink:'rgba(20,18,14,0.10)', transition:'background .2s' }} />)}
        </div>
        <div style={display(20)}>{title}</div>
        <div style={{ fontSize:13, color:C.ink2, marginTop:5, lineHeight:1.45 }}>{sub}</div>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>{body()}<div style={{ height:16 }} /></div>
      <div style={{ borderTop:'1px solid '+C.hair, padding:'10px 18px calc(14px + env(safe-area-inset-bottom))', flexShrink:0 }}>
        <button onClick={valid() ? ()=> last ? onCreated(d) : setStep(step+1) : undefined} disabled={!valid()} style={{
          width:'100%', padding:'14px 16px', borderRadius:12, border:'none', cursor:valid()?'pointer':'default', fontFamily:'inherit', fontWeight:700, fontSize:14.5,
          background:valid()?C.ink:C.paper2, color:valid()?C.paper:C.muted, display:'flex', alignItems:'center', justifyContent:'center', gap:8,
        }}>
          {last ? <><Icon name="trophy" size={16} stroke={C.paper} sw={2.2} />Create tournament</> : 'Continue'}
        </button>
      </div>
    </div>
  );
}

function TournamentCreated({ d, onAddTeams, onHub }) {
  return (
    <div style={{ position:'absolute', inset:0, zIndex:99, background:C.paper, padding:'48px 24px', textAlign:'center', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
      <div style={{ width:96, height:96, borderRadius:26, background:d.color, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:34, letterSpacing:'-0.03em', animation:'ch-pop 0.45s cubic-bezier(0.22,1,0.36,1)' }}>{monogram(d.name)}</div>
      <div style={{ display:'inline-flex', alignItems:'center', gap:6, ...mono, fontSize:9, color:C.greenInk, background:C.greenSoft, padding:'4px 9px', borderRadius:6, marginTop:16 }}><Icon name="check" size={12} sw={3} stroke={C.greenInk} />CREATED · DRAFT</div>
      <div style={{ ...display(22), marginTop:14 }}>{d.name}</div>
      <div style={{ fontSize:13, color:C.ink2, marginTop:8, lineHeight:1.5, maxWidth:280 }}>It’s set up as a draft. Add the teams, then generate the draw to get it ready.</div>
      <button onClick={onAddTeams} style={{ marginTop:22, width:'100%', maxWidth:280, padding:'14px 0', borderRadius:12, border:'none', background:C.ink, color:C.paper, fontFamily:'inherit', fontWeight:700, fontSize:14.5, cursor:'pointer' }}>Add teams</button>
      <button onClick={onHub} style={{ marginTop:10, width:'100%', maxWidth:280, padding:'14px 0', borderRadius:12, border:'1px solid '+C.hair, background:C.paper, color:C.ink, fontFamily:'inherit', fontWeight:600, fontSize:14, cursor:'pointer' }}>Go to tournament</button>
    </div>
  );
}

window.TournamentCreate = TournamentCreate;
window.TournamentCreated = TournamentCreated;
window.__tourPreset = presetById;
})();

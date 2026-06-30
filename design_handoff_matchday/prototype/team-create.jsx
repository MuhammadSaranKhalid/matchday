// team-create.jsx — Create-a-team flow (window.TeamCreate).
// Steps: Identity (name) → Crest (color) → Type & format → Home & privacy → Review.

(function () {
const { useState } = React;
const ink='var(--ink)', ink2='var(--ink-2)', muted='var(--muted)', soft='var(--soft)',
      paper='var(--paper)', paper2='var(--paper-2)', surface='var(--surface)',
      hair='var(--hairline)', line='var(--line)', red='var(--red)', redSoft='var(--red-soft)',
      green='var(--green)', greenSoft='var(--green-soft)', greenInk='var(--green-ink)', cream='var(--cream)';
const mono = { fontFamily:'JetBrains Mono,monospace', fontWeight:700, letterSpacing:'0.1em', textTransform:'uppercase' };

const P = {
  back:'<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>',
  arrow:'<path d="M5 12h14M13 6l6 6-6 6"/>',
  check:'<polyline points="20 6 9 17 4 12"/>',
  pin:'<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>',
  lock:'<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
  globe:'<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.5 2.5 15 0 18M12 3c-2.5 2.5-2.5 15 0 18"/>',
};
function Ic({n, s=18, sw=2, stroke='currentColor', style}) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{__html:P[n]}} />;
}

const COLORS = ['oklch(0.62 0.19 28)','oklch(0.45 0.12 280)','oklch(0.50 0.13 200)','oklch(0.55 0.15 145)','oklch(0.58 0.13 60)','oklch(0.45 0.10 30)','oklch(0.40 0.06 250)','oklch(0.36 0.03 80)'];
const TYPES = [
  { id:'club', t:'Club', s:'A standing side that plays regularly' },
  { id:'village', t:'Village / mohalla', s:'Your area’s team' },
  { id:'oneoff', t:'One-off', s:'A friendly XI for a single game' },
  { id:'office', t:'Office / college', s:'Workplace or campus team' },
];
const FORMATS = ['T20','T10','Tape-ball','8-a-side','Hardball','Mixed'];

function monogram(name) {
  const w = name.trim().split(/\s+/).filter(Boolean);
  if (!w.length) return 'TM';
  if (w.length === 1) return w[0].slice(0,2).toUpperCase();
  return (w[0][0] + w[w.length-1][0]).toUpperCase();
}

function Header({ step, total, onBack, title, sub }) {
  return (
    <div style={{ flexShrink:0, background:paper, borderBottom:'1px solid '+hair }}>
      <div style={{ height:44 }} />
      <div style={{ padding:'2px 12px 0', display:'flex', alignItems:'center', gap:8 }}>
        <button onClick={onBack} aria-label="Back" style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:ink }}><Ic n="back" s={20} /></button>
        <span style={{ ...mono, fontSize:9, color:muted }}>Create team · {step}/{total}</span>
      </div>
      <div style={{ display:'flex', gap:4, padding:'10px 18px 0' }}>
        {Array.from({length:total},(_,i)=><div key={i} style={{ flex:1, height:3, borderRadius:2, background:i<step?ink:'rgba(20,18,14,0.10)' }} />)}
      </div>
      <div style={{ padding:'14px 18px 16px' }}>
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:20, letterSpacing:'-0.02em', color:ink }}>{title}</div>
        {sub && <div style={{ fontSize:13, color:ink2, marginTop:5, lineHeight:1.45 }}>{sub}</div>}
      </div>
    </div>
  );
}
function Cta({ label, onClick, disabled, hint }) {
  return (
    <div style={{ flexShrink:0, borderTop:'1px solid '+hair, padding:'10px 18px calc(12px + env(safe-area-inset-bottom))', background:paper }}>
      {hint && <div style={{ fontSize:11.5, color:muted, textAlign:'center', marginBottom:9 }}>{hint}</div>}
      <button onClick={!disabled?onClick:undefined} disabled={disabled} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:disabled?paper2:ink, color:disabled?muted:paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:disabled?'default':'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>
        {label}{!disabled && <Ic n="arrow" s={15} stroke={paper} />}
      </button>
    </div>
  );
}
function SecLabel({ children }) { return <div style={{ ...mono, fontSize:10, color:muted, padding:'0 0 9px' }}>{children}</div>; }

function TeamCreate({ onExit, onCreated }) {
  const [step, setStep] = useState(1);
  const [name, setName] = useState('');
  const [color, setColor] = useState(COLORS[0]);
  const [type, setType] = useState('club');
  const [format, setFormat] = useState('Tape-ball');
  const [city, setCity] = useState('Lahore');
  const [area, setArea] = useState('');
  const [priv, setPriv] = useState('public');
  const TOTAL = 4;
  const mg = monogram(name);
  const back = () => step === 1 ? onExit() : setStep(s=>s-1);
  const next = () => setStep(s=>s+1);

  const Crest = ({ size=84 }) => (
    <div style={{ width:size, height:size, borderRadius:size*0.26, background:color, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:size*0.34, letterSpacing:'-0.03em', flexShrink:0 }}>{mg}</div>
  );

  let body, cta, title, sub;

  if (step === 1) {
    title = 'Name your team'; sub = 'You can change this later in team settings.';
    body = (
      <div style={{ padding:'4px 18px' }}>
        <div style={{ display:'flex', justifyContent:'center', marginBottom:22 }}><Crest /></div>
        <SecLabel>Team name</SecLabel>
        <input autoFocus value={name} onChange={e=>setName(e.target.value.slice(0,40))} placeholder="e.g. Gulberg Greens" className="ck-input" style={{ fontSize:16, borderRadius:12, padding:'13px 14px' }} />
        <div style={{ ...mono, fontSize:9, color:soft, textAlign:'right', marginTop:6 }}>{name.length}/40</div>
      </div>
    );
    cta = <Cta label="Continue" disabled={name.trim().length<2} onClick={next} hint={name.trim().length>=2 ? `Crest monogram: ${mg}` : 'Enter at least 2 characters'} />;
  } else if (step === 2) {
    title = 'Pick your colours'; sub = 'Your crest is how the team shows up everywhere in matchday.';
    body = (
      <div style={{ padding:'4px 18px' }}>
        <div style={{ display:'flex', justifyContent:'center', marginBottom:24 }}><Crest size={96} /></div>
        <SecLabel>Crest colour</SecLabel>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:12 }}>
          {COLORS.map(c=>{
            const on = c===color;
            return <button key={c} onClick={()=>setColor(c)} aria-label="colour" style={{ height:54, borderRadius:14, background:c, border:'none', cursor:'pointer', position:'relative', boxShadow:on?'0 0 0 2px var(--paper), 0 0 0 4px '+ink:'none' }}>{on && <span style={{ position:'absolute', inset:0, display:'flex', alignItems:'center', justifyContent:'center', color:'#fff' }}><Ic n="check" s={20} sw={3} stroke="#fff" /></span>}</button>;
          })}
        </div>
      </div>
    );
    cta = <Cta label="Continue" onClick={next} />;
  } else if (step === 3) {
    title = 'Type & format'; sub = 'Helps opponents find the right match against you.';
    body = (
      <div style={{ padding:'4px 18px' }}>
        <SecLabel>Team type</SecLabel>
        <div style={{ display:'grid', gap:8, marginBottom:22 }}>
          {TYPES.map(t=>{
            const on = t.id===type;
            return (
              <button key={t.id} onClick={()=>setType(t.id)} style={{ display:'flex', alignItems:'center', gap:12, padding:13, borderRadius:14, border:'2px solid '+(on?ink:hair), background:on?paper2:paper, cursor:'pointer', textAlign:'left', fontFamily:'inherit', width:'100%' }}>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ fontWeight:600, fontSize:14, color:ink }}>{t.t}</div>
                  <div style={{ fontSize:11.5, color:muted, marginTop:1 }}>{t.s}</div>
                </div>
                <div style={{ width:22, height:22, borderRadius:999, border:'2px solid '+(on?ink:hair), background:on?ink:'transparent', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>{on && <Ic n="check" s={12} sw={3} stroke={paper} />}</div>
              </button>
            );
          })}
        </div>
        <SecLabel>Usual format</SecLabel>
        <div style={{ display:'flex', flexWrap:'wrap', gap:8 }}>
          {FORMATS.map(f=>{
            const on = f===format;
            return <button key={f} onClick={()=>setFormat(f)} style={{ padding:'9px 14px', borderRadius:999, border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink, fontWeight:600, fontSize:13, cursor:'pointer', fontFamily:'inherit' }}>{f}</button>;
          })}
        </div>
      </div>
    );
    cta = <Cta label="Continue" onClick={next} />;
  } else {
    title = 'Home & visibility'; sub = 'Last step — where you play and who can find you.';
    body = (
      <div style={{ padding:'4px 18px' }}>
        <SecLabel>Home city</SecLabel>
        <input value={city} onChange={e=>setCity(e.target.value)} placeholder="City" className="ck-input" style={{ fontSize:15, borderRadius:12, padding:'12px 14px', marginBottom:10 }} />
        <input value={area} onChange={e=>setArea(e.target.value)} placeholder="Area / ground (optional)" className="ck-input" style={{ fontSize:15, borderRadius:12, padding:'12px 14px' }} />
        <div style={{ height:22 }} />
        <SecLabel>Visibility</SecLabel>
        <div style={{ display:'grid', gap:8 }}>
          {[['public','globe','Public','Anyone can find and follow. Strangers can request to join.'],['private','lock','Private','Hidden squad. People need a code or invite to join.']].map(([id,icon,t,s])=>{
            const on = id===priv;
            return (
              <button key={id} onClick={()=>setPriv(id)} style={{ display:'flex', alignItems:'center', gap:12, padding:13, borderRadius:14, border:'2px solid '+(on?ink:hair), background:on?paper2:paper, cursor:'pointer', textAlign:'left', fontFamily:'inherit', width:'100%' }}>
                <div style={{ width:34, height:34, borderRadius:10, background:paper2, border:'1px solid '+hair, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Ic n={icon} s={16} sw={1.8} stroke={ink} /></div>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ fontWeight:600, fontSize:14, color:ink }}>{t}</div>
                  <div style={{ fontSize:11.5, color:muted, marginTop:1, lineHeight:1.4 }}>{s}</div>
                </div>
                <div style={{ width:22, height:22, borderRadius:999, border:'2px solid '+(on?ink:hair), background:on?ink:'transparent', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>{on && <Ic n="check" s={12} sw={3} stroke={paper} />}</div>
              </button>
            );
          })}
        </div>
      </div>
    );
    cta = <Cta label="Create team" disabled={!city.trim()} onClick={()=>onCreated({ name:name.trim(), mono:mg, color, type, format, city:city.trim(), area:area.trim(), priv })} hint="You’ll be the owner — invite players next." />;
  }

  return (
    <div style={{ position:'absolute', inset:0, zIndex:98, background:paper, display:'flex', flexDirection:'column' }}>
      <Header step={step} total={TOTAL} onBack={back} title={title} sub={sub} />
      <div style={{ flex:1, overflowY:'auto', minHeight:0, paddingTop:6, paddingBottom:16 }}>{body}</div>
      {cta}
    </div>
  );
}

// Success splash after create
function TeamCreated({ team, onOpen, onInvite }) {
  return (
    <div style={{ position:'absolute', inset:0, zIndex:99, background:paper, display:'flex', flexDirection:'column', alignItems:'center', textAlign:'center', padding:'0 24px' }}>
      <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:14 }}>
        <div style={{ width:96, height:96, borderRadius:26, background:team.color, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:34, letterSpacing:'-0.03em', animation:'ch-pop 0.4s cubic-bezier(0.22,1,0.36,1)' }}>{team.mono}</div>
        <div style={{ display:'inline-flex', alignItems:'center', gap:6, ...mono, fontSize:9, color:greenInk, background:greenSoft, padding:'4px 9px', borderRadius:6 }}><Ic n="check" s={12} sw={3} stroke={greenInk} />CREATED</div>
        <div style={{ fontFamily:'Inter Tight', fontWeight:800, fontSize:24, letterSpacing:'-0.03em', color:ink }}>{team.name} is live.</div>
        <div style={{ fontSize:13.5, color:ink2, lineHeight:1.5, maxWidth:300 }}>You’re the owner. A team needs players — invite your squad to start scheduling matches.</div>
      </div>
      <div style={{ width:'100%', paddingBottom:'calc(20px + env(safe-area-inset-bottom))', display:'flex', flexDirection:'column', gap:10 }}>
        <button onClick={onInvite} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:ink, color:paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:'pointer' }}>Invite players</button>
        <button onClick={onOpen} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'1px solid '+line, background:paper, color:ink, fontFamily:'inherit', fontWeight:600, fontSize:14, cursor:'pointer' }}>Go to team page</button>
      </div>
    </div>
  );
}

window.TeamCreate = TeamCreate;
window.TeamCreated = TeamCreated;
})();

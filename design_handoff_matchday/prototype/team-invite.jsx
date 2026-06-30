// team-invite.jsx — Invite players flow (window.TeamInvite).
// Three routes: share link/code · add nearby players · add unclaimed names.

(function () {
const { useState } = React;
const ink='var(--ink)', ink2='var(--ink-2)', muted='var(--muted)', soft='var(--soft)',
      paper='var(--paper)', paper2='var(--paper-2)', surface='var(--surface)',
      hair='var(--hairline)', line='var(--line)', red='var(--red)', redSoft='var(--red-soft)',
      green='var(--green)', greenSoft='var(--green-soft)', greenInk='var(--green-ink)', cream='var(--cream)', amberInk='#7a5a1e';
const mono = { fontFamily:'JetBrains Mono,monospace', fontWeight:700, letterSpacing:'0.1em', textTransform:'uppercase' };

const P = {
  back:'<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>',
  next:'<path d="M9 6l6 6-6 6"/>',
  check:'<polyline points="20 6 9 17 4 12"/>',
  search:'<circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/>',
  link:'<path d="M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1"/><path d="M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/>',
  copy:'<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h8"/>',
  wa:'<path d="M12 3a9 9 0 0 0-7.7 13.6L3 21l4.5-1.2A9 9 0 1 0 12 3z"/>',
  users:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  pencil:'<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',
};
function Ic({n, s=18, sw=2, stroke='currentColor', style}) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{__html:P[n]}} />;
}
function Avatar({ name, c, s=38 }) {
  return <div style={{ width:s, height:s, borderRadius:999, background:c||paper2, color:c?'#fff':ink2, flexShrink:0, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:s*0.36 }}>{name.split(' ').map(w=>w[0]).join('').slice(0,2)}</div>;
}
function RolePill({ role }) {
  const tone = { BAT:[paper2,ink2], BOW:[cream,amberInk], AR:[greenSoft,greenInk], WK:[red,'#fff'] }[role]||[paper2,ink2];
  return <span style={{ ...mono, fontSize:8, padding:'2px 5px', borderRadius:4, background:tone[0], color:tone[1] }}>{role}</span>;
}

const NEARBY = [
  { id:'n1', name:'Wajid Ali', role:'AR', sub:'Model Town XI', dist:'2 km', c:'#3563B6' },
  { id:'n2', name:'Salman Yousuf', role:'BAT', sub:'Free agent', dist:'4 km', c:'#2F7D54' },
  { id:'n3', name:'Naveed Iqbal', role:'BOW', sub:'Cantt Cricketers', dist:'5 km', c:'#C98A2B' },
  { id:'n4', name:'Tariq Bhatti', role:'BAT', sub:'Iqbal Park XI', dist:'6 km', c:'#6A6F2A' },
  { id:'n5', name:'Aamir Shah', role:'WK', sub:'Free agent', dist:'7 km', c:'#A8552E' },
  { id:'n6', name:'Rauf Cheema', role:'BOW', sub:'Garrison XI', dist:'9 km', c:'#3a8f8f' },
];

function Header({ onBack, title }) {
  return (
    <div style={{ flexShrink:0, background:paper, borderBottom:'1px solid '+hair }}>
      <div style={{ height:44 }} />
      <div style={{ padding:'4px 12px 12px', display:'flex', alignItems:'center', gap:8 }}>
        <button onClick={onBack} aria-label="Back" style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:ink }}><Ic n="back" s={20} /></button>
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:18, letterSpacing:'-0.02em', color:ink }}>{title}</div>
      </div>
    </div>
  );
}
function SecLabel({ children, hint }) {
  return <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline', padding:'0 0 9px' }}><span style={{ ...mono, fontSize:10, color:muted }}>{children}</span>{hint && <span style={{ fontSize:11, color:muted }}>{hint}</span>}</div>;
}

function TeamInvite({ team, onClose }) {
  const [route, setRoute] = useState('root'); // root | nearby | unclaimed
  const [toast, setToast] = useState(null);
  const flash = (m)=>{ setToast(m); setTimeout(()=>setToast(null),1500); };
  const t = team || { name:'your team', mono:'TM', color:'var(--ink)' };
  const code = 'JOIN-' + (t.mono||'TM').toUpperCase() + '-4827';

  const Toast = () => toast ? <div style={{ position:'absolute', left:16, right:16, bottom:20, padding:'13px 16px', borderRadius:14, background:ink, color:paper, zIndex:30, fontSize:13, fontWeight:600, textAlign:'center', animation:'ch-pop 0.3s cubic-bezier(0.22,1,0.36,1)' }}>{toast}</div> : null;

  if (route === 'nearby') return <NearbyRoute team={t} onBack={()=>setRoute('root')} onAdded={(n)=>{ setRoute('root'); flash(n+' invited'); }} flash={flash} ToastEl={Toast} />;
  if (route === 'unclaimed') return <UnclaimedRoute team={t} onBack={()=>setRoute('root')} onAdded={(n)=>{ setRoute('root'); flash(n+' added'); }} ToastEl={Toast} />;

  const Method = ({ icon, title, sub, onClick, rec }) => (
    <button onClick={onClick} style={{ width:'100%', display:'flex', alignItems:'center', gap:13, padding:14, marginBottom:9, background:paper, border:'1.5px solid '+hair, borderRadius:14, cursor:'pointer', textAlign:'left', fontFamily:'inherit' }}>
      <div style={{ width:40, height:40, borderRadius:11, background:rec?ink:paper2, color:rec?paper:ink, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Ic n={icon} s={18} stroke={rec?paper:ink} /></div>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ display:'flex', alignItems:'center', gap:6 }}>
          <span style={{ fontWeight:700, fontSize:14 }}>{title}</span>
          {rec && <span style={{ ...mono, fontSize:8, padding:'2px 5px', borderRadius:4, background:ink, color:paper }}>EASIEST</span>}
        </div>
        <div style={{ fontSize:11.5, color:muted, marginTop:2, lineHeight:1.4 }}>{sub}</div>
      </div>
      <Ic n="next" s={15} stroke={soft} style={{ alignSelf:'center', flexShrink:0 }} />
    </button>
  );

  return (
    <div style={{ position:'absolute', inset:0, zIndex:100, background:paper, display:'flex', flexDirection:'column' }}>
      <Header onBack={onClose} title="Invite players" />
      <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'16px 18px 24px' }}>
        {/* share-link card */}
        <SecLabel>Share an invite link</SecLabel>
        <div style={{ padding:14, borderRadius:16, border:'1px solid '+hair, background:paper2, marginBottom:14 }}>
          <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
            <div style={{ width:40, height:40, borderRadius:11, background:t.color, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:15, flexShrink:0 }}>{t.mono}</div>
            <div style={{ minWidth:0 }}>
              <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14 }}>{t.name}</div>
              <div style={{ ...mono, fontSize:10, color:muted, marginTop:2 }}>{code}</div>
            </div>
          </div>
          <div style={{ display:'flex', gap:8 }}>
            <button onClick={()=>flash('Shared to WhatsApp')} style={{ flex:1, padding:'11px 0', borderRadius:11, border:'none', background:'#25923a', color:'#fff', fontFamily:'inherit', fontWeight:700, fontSize:13, cursor:'pointer', display:'inline-flex', alignItems:'center', justifyContent:'center', gap:7 }}><Ic n="wa" s={16} stroke="#fff" />WhatsApp</button>
            <button onClick={()=>flash('Link copied')} style={{ flex:1, padding:'11px 0', borderRadius:11, border:'1px solid '+line, background:paper, color:ink, fontFamily:'inherit', fontWeight:700, fontSize:13, cursor:'pointer', display:'inline-flex', alignItems:'center', justifyContent:'center', gap:7 }}><Ic n="copy" s={15} stroke={ink} />Copy link</button>
          </div>
          <div style={{ fontSize:11, color:muted, marginTop:10, lineHeight:1.4 }}>Anyone with the link can request to join. You approve each request.</div>
        </div>

        <SecLabel>Or add directly</SecLabel>
        <Method icon="users" title="Add nearby players" sub="Free agents & players from other teams near you" rec onClick={()=>setRoute('nearby')} />
        <Method icon="pencil" title="Add unclaimed names" sub="Type names now — they claim their profile later" onClick={()=>setRoute('unclaimed')} />
      </div>
      <Toast />
    </div>
  );
}

function NearbyRoute({ team, onBack, onAdded, flash, ToastEl }) {
  const [q, setQ] = useState('');
  const [invited, setInvited] = useState({});
  const list = q ? NEARBY.filter(p=>(p.name+p.sub).toLowerCase().includes(q.toLowerCase())) : NEARBY;
  const count = Object.values(invited).filter(Boolean).length;
  return (
    <div style={{ position:'absolute', inset:0, zIndex:101, background:paper, display:'flex', flexDirection:'column' }}>
      <Header onBack={onBack} title="Add nearby players" />
      <div style={{ padding:'12px 18px', flexShrink:0 }}>
        <div style={{ display:'flex', alignItems:'center', gap:10, padding:'11px 12px', background:paper2, border:'1px solid '+hair, borderRadius:12 }}>
          <Ic n="search" s={15} stroke={muted} />
          <input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search by name or club" style={{ flex:1, background:'transparent', border:'none', outline:'none', fontSize:14, fontFamily:'inherit', color:ink }} />
        </div>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        <div style={{ padding:'0 18px 6px' }}><SecLabel hint={`${list.length} nearby`}>{q?'Results':'Available nearby'}</SecLabel></div>
        {list.map((p,i)=>{
          const inv = invited[p.id];
          return (
            <div key={p.id} style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 18px', borderTop:i?'1px solid '+hair:'none' }}>
              <Avatar name={p.name} c={p.c} size={38} />
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ display:'flex', alignItems:'center', gap:6 }}><span style={{ fontFamily:'Inter Tight', fontWeight:600, fontSize:14, whiteSpace:'nowrap' }}>{p.name}</span><RolePill role={p.role} /></div>
                <div style={{ ...mono, fontSize:9, color:muted, marginTop:2 }}>{p.sub} · {p.dist}</div>
              </div>
              <button onClick={()=>setInvited(v=>({...v,[p.id]:!v[p.id]}))} style={{ flexShrink:0, height:32, padding:'0 14px', borderRadius:10, cursor:'pointer', fontFamily:'inherit', fontWeight:700, fontSize:12, border:inv?'1px solid '+line:'none', background:inv?paper:ink, color:inv?ink2:paper, display:'inline-flex', alignItems:'center', gap:5 }}>
                {inv ? <><Ic n="check" s={13} sw={2.6} stroke={ink2} />Invited</> : 'Invite'}
              </button>
            </div>
          );
        })}
        <div style={{ height:90 }} />
      </div>
      {count>0 && (
        <div style={{ flexShrink:0, borderTop:'1px solid '+hair, padding:'10px 18px calc(12px + env(safe-area-inset-bottom))', background:paper }}>
          <button onClick={()=>onAdded(count+' player'+(count>1?'s':''))} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:ink, color:paper, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:'pointer' }}>Send {count} invite{count>1?'s':''}</button>
        </div>
      )}
      <ToastEl />
    </div>
  );
}

function UnclaimedRoute({ team, onBack, onAdded, ToastEl }) {
  const [rows, setRows] = useState([{ name:'', role:'BAT' }]);
  const set = (i,patch)=>setRows(rs=>rs.map((r,idx)=>idx===i?{...r,...patch}:r));
  const valid = rows.filter(r=>r.name.trim().length>=2).length;
  return (
    <div style={{ position:'absolute', inset:0, zIndex:101, background:paper, display:'flex', flexDirection:'column' }}>
      <Header onBack={onBack} title="Add unclaimed players" />
      <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 18px 24px' }}>
        <div style={{ fontSize:12.5, color:ink2, lineHeight:1.5, marginBottom:14 }}>Add players by name now. Match stats accrue to the placeholder; when they join matchday they claim it and stats migrate.</div>
        {rows.map((r,i)=>(
          <div key={i} style={{ padding:14, background:paper, border:'1px solid '+hair, borderRadius:14, marginBottom:10 }}>
            <div style={{ ...mono, fontSize:9, color:muted, marginBottom:9 }}>PLAYER {i+1}</div>
            <input value={r.name} onChange={e=>set(i,{name:e.target.value})} placeholder="Full name" className="ck-input" style={{ marginBottom:10, fontSize:15 }} autoFocus={i===rows.length-1} />
            <div style={{ display:'flex', gap:6 }}>
              {['BAT','BOW','AR','WK'].map(role=>(
                <button key={role} onClick={()=>set(i,{role})} style={{ padding:'7px 12px', borderRadius:999, border:'1px solid '+(r.role===role?ink:hair), background:r.role===role?ink:paper, color:r.role===role?paper:ink, fontFamily:'inherit', fontSize:12, fontWeight:600, cursor:'pointer' }}>{role}</button>
              ))}
            </div>
          </div>
        ))}
        <button onClick={()=>setRows(rs=>[...rs,{name:'',role:'BAT'}])} style={{ width:'100%', padding:'12px 0', borderRadius:12, border:'1px dashed '+line, background:paper, color:ink2, fontFamily:'inherit', fontWeight:600, fontSize:13, cursor:'pointer', display:'inline-flex', alignItems:'center', justifyContent:'center', gap:7 }}><Ic n="plus" s={16} stroke={ink2} />Add another player</button>
      </div>
      <div style={{ flexShrink:0, borderTop:'1px solid '+hair, padding:'10px 18px calc(12px + env(safe-area-inset-bottom))', background:paper }}>
        <button onClick={valid?()=>onAdded(valid+' player'+(valid>1?'s':'')):undefined} disabled={!valid} style={{ width:'100%', padding:'14px 0', borderRadius:12, border:'none', background:valid?ink:paper2, color:valid?paper:muted, fontFamily:'inherit', fontWeight:700, fontSize:14, cursor:valid?'pointer':'default' }}>{valid?`Add ${valid} to squad`:'Enter a name'}</button>
      </div>
      <ToastEl />
    </div>
  );
}

window.TeamInvite = TeamInvite;
})();

// followers-screen.jsx — Followers / Following list, pushed from the profile.
// window.FollowersScreen({ initialTab, onBack })

(function () {
const { useState } = React;

const ink='var(--ink)', ink2='var(--ink-2)', muted='var(--muted)', soft='var(--soft)',
      paper='var(--paper)', paper2='var(--paper-2)', surface='var(--surface)',
      hair='var(--hairline)', line='var(--line)', red='var(--red)', cream='var(--cream)', amberInk='#7a5a1e';
const mono = {fontFamily:'JetBrains Mono,monospace',fontWeight:700,letterSpacing:'0.1em',textTransform:'uppercase'};

const P = {
  back:'<path d="M15 18l-6-6 6-6"/>',
  search:'<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
  close:'<path d="M6 6l12 12M18 6L6 18"/>',
};
function Icon({n, s=18, sw=2, stroke='currentColor', style}) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth={sw}
    strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{__html:P[n]}} />;
}

// follows = they follow you · youFollow = you follow them
const PEOPLE = [
  { id:'u1', n:'Adeel Sheikh',  h:'adeel_wk', sub:'Wicket-keeper · Lahore Lions',   c:'#3563B6', follows:true,  youFollow:true  },
  { id:'u2', n:'Faraz Khan',    h:'faraz',    sub:'All-rounder · Lahore Lions',     c:'#2F7D54', follows:true,  youFollow:false },
  { id:'u3', n:'Bilal Pasha',   h:'bilalp',   sub:'Captain · Mohalla Kings',        c:'#DC4D32', follows:true,  youFollow:false },
  { id:'u4', n:'Hamza Tariq',   h:'hamza',    sub:'Batter · Old Boys',              c:'#7a4a2a', follows:true,  youFollow:true  },
  { id:'u5', n:'Usman Riaz',    h:'usman',    sub:'Fast bowler · Gulberg Greens',   c:'#C98A2B', follows:true,  youFollow:false },
  { id:'u6', n:'Junaid Ali',    h:'junaid_ar',sub:'All-rounder · Lahore Lions',     c:'#3a8f8f', follows:true,  youFollow:false },
  { id:'u7', n:'Saad Anwar',    h:'saad',     sub:'Batter · Model Town XI',         c:'#5b53a6', follows:false, youFollow:true  },
  { id:'u8', n:'Kashif Bhatti', h:'kashif',   sub:'Wicket-keeper · Sherwani CC',    c:'#a8552e', follows:false, youFollow:true  },
  { id:'u9', n:'Owais Memon',   h:'owais',    sub:'Off-spinner · Cantt Cricketers', c:'#6a6f2a', follows:false, youFollow:true  },
];

function Avatar({ n, c, s=42 }) {
  const init = n.split(' ').map(w=>w[0]).join('').slice(0,2);
  return <div style={{ width:s, height:s, borderRadius:999, background:c, color:'#fff', flexShrink:0,
    display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800,
    fontSize:s*0.38, letterSpacing:'-0.02em' }}>{init}</div>;
}

function Row({ p, tab, following, onToggle }) {
  const youFollow = following[p.id];
  const mutual = p.follows && youFollow;
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 18px', borderBottom:'1px solid '+hair }}>
      <Avatar n={p.n} c={p.c} />
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ display:'flex', alignItems:'center', gap:6, flexWrap:'wrap' }}>
          <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.01em', whiteSpace:'nowrap' }}>{p.n}</span>
          {mutual && <span style={{ ...mono, fontSize:7.5, padding:'2px 5px', borderRadius:4, background:paper2, color:muted, whiteSpace:'nowrap' }}>FOLLOWS YOU</span>}
        </div>
        <div style={{ fontFamily:'JetBrains Mono', fontSize:10, color:muted, marginTop:2, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>@{p.h}</div>
        <div style={{ fontSize:11.5, color:ink2, marginTop:2, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{p.sub}</div>
      </div>
      <button onClick={()=>onToggle(p.id)} style={{
        flexShrink:0, padding:'8px 14px', borderRadius:10, cursor:'pointer', fontFamily:'inherit', fontWeight:700, fontSize:12,
        border: youFollow ? '1px solid '+line : 'none',
        background: youFollow ? paper : red, color: youFollow ? ink : '#fff',
        boxShadow: youFollow ? 'none' : '0 3px 9px rgba(220,77,50,.24)', whiteSpace:'nowrap',
      }}>{youFollow ? 'Following' : (p.follows ? 'Follow back' : 'Follow')}</button>
    </div>
  );
}

function FollowersScreen({ initialTab='followers', onBack }) {
  const [tab, setTab] = useState(initialTab);
  const [q, setQ] = useState('');
  const [following, setFollowing] = useState(() => {
    const m = {}; PEOPLE.forEach(p => m[p.id] = p.youFollow); return m;
  });
  const toggle = (id) => setFollowing(prev => ({ ...prev, [id]: !prev[id] }));

  const base = tab === 'followers' ? PEOPLE.filter(p=>p.follows) : PEOPLE.filter(p=>following[p.id]);
  const list = q ? base.filter(p => (p.n + p.h + p.sub).toLowerCase().includes(q.toLowerCase())) : base;

  return (
    <div style={{ position:'absolute', inset:0, background:paper, display:'flex', flexDirection:'column', zIndex:50, fontFamily:'Inter,system-ui' }}>
      <div style={{ height:50, flexShrink:0 }} />
      {/* header */}
      <div style={{ flexShrink:0, borderBottom:'1px solid '+hair, background:paper }}>
        <div style={{ display:'flex', alignItems:'center', padding:'2px 12px 8px' }}>
          <button onClick={onBack} aria-label="Back" style={{ width:34, height:34, borderRadius:999, border:'none',
            background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, flexShrink:0, color:ink }}>
            <Icon n="back" s={20} sw={2.2} stroke={ink} />
          </button>
          <div style={{ flex:1, textAlign:'center', minWidth:0 }}>
            <div style={{ fontFamily:'Inter Tight', fontWeight:800, fontSize:15, letterSpacing:'-0.02em', whiteSpace:'nowrap' }}>Muhammad Saran</div>
            <div style={{ fontFamily:'JetBrains Mono', fontSize:9.5, color:muted, letterSpacing:'0.04em' }}>@saran</div>
          </div>
          <div style={{ width:34, flexShrink:0 }} />
        </div>
        {/* big-count segmented tabs */}
        <div style={{ display:'flex', padding:'4px 12px 0' }}>
          {[['followers','284','Followers'],['following','92','Following']].map(([k,num,label])=>{
            const on = tab===k;
            return (
              <button key={k} onClick={()=>setTab(k)} style={{
                flex:1, padding:'4px 0 11px', background:'none', border:'none', cursor:'pointer', fontFamily:'inherit',
                display:'flex', flexDirection:'column', alignItems:'center', gap:1,
                borderBottom:'2px solid '+(on?ink:'transparent'), marginBottom:-1,
              }}>
                <span style={{ fontFamily:'Inter Tight', fontWeight:800, fontSize:21, letterSpacing:'-0.03em', color:on?ink:ink2, fontVariantNumeric:'tabular-nums', lineHeight:1.1 }}>{num}</span>
                <span style={{ ...mono, fontSize:9, color:on?ink:muted }}>{label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* search */}
      <div style={{ padding:'12px 18px', flexShrink:0 }}>
        <div style={{ display:'flex', alignItems:'center', gap:10, padding:'10px 12px', background:paper2, border:'1px solid '+hair, borderRadius:12 }}>
          <Icon n="search" s={15} sw={2} stroke={muted} />
          <input value={q} onChange={e=>setQ(e.target.value)} placeholder={`Search ${tab}`}
            style={{ flex:1, background:'transparent', border:'none', outline:'none', fontSize:14, fontFamily:'inherit', color:ink }} />
          {q && <button onClick={()=>setQ('')} style={{ background:'none', border:'none', cursor:'pointer', padding:0, display:'flex' }}><Icon n="close" s={14} stroke={muted} /></button>}
        </div>
      </div>

      {/* list */}
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {list.length === 0 ? (
          <div style={{ padding:'48px 24px', textAlign:'center', color:muted, fontSize:13 }}>No one matches “{q}”.</div>
        ) : list.map(p => <Row key={p.id} p={p} tab={tab} following={following} onToggle={toggle} />)}
        <div style={{ height:24 }} />
      </div>
    </div>
  );
}

window.FollowersScreen = FollowersScreen;
})();

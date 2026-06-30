// profile-you.jsx — the live "You" tab. Captain-led, lean social profile.
// Self vs stranger views, bio written/empty/fallback, interactive feed.

(function () {
const { useState } = React;

// tokens
const ink='var(--ink)', ink2='var(--ink-2)', muted='var(--muted)', soft='var(--soft)',
      paper='var(--paper)', paper2='var(--paper-2)', surface='var(--surface)',
      hair='var(--hairline)', line='var(--line)', red='var(--red)', redSoft='var(--red-soft)',
      green='var(--green)', greenSoft='var(--green-soft)', greenInk='var(--green-ink)',
      amber='var(--amber)', cream='var(--cream)';
const display = (s,w=800)=>({fontFamily:'Inter Tight,system-ui',fontWeight:w,letterSpacing:'-0.03em',color:ink,lineHeight:1.05});
const mono = {fontFamily:'JetBrains Mono,monospace',fontWeight:700,letterSpacing:'0.1em',textTransform:'uppercase'};

const P = {
  gear:'<path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>',
  dots:'<circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/>',
  pin:'<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>',
  edit:'<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',
  share:'<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  msg:'<path d="M20 14a2 2 0 0 1-2 2H8l-4 3V6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2z"/>',
  heart:'<path d="M20.8 5.6a5 5 0 0 0-7.1 0L12 7.3l-1.7-1.7a5 5 0 1 0-7.1 7.1L12 21l8.8-8.3a5 5 0 0 0 0-7.1z"/>',
  cmt:'<path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 9 9 0 0 1-3.9-.9L3 20l1.3-3.6A8.4 8.4 0 1 1 21 11.5z"/>',
  send:'<path d="M22 2 11 13M22 2l-7 20-4-9-9-4z"/>',
  bm:'<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>',
  img:'<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="m21 15-5-5L5 21"/>',
  home:'<path d="M4 11l8-7 8 7"/><path d="M6 9.5V20h12V9.5"/><path d="M10 20v-5h4v5"/>',
  bat:'<path d="M14.5 4.5a2 2 0 0 1 2.9 2.9l-8 8-2.9-2.9z"/><path d="M6.5 12.5 4 15l1.5 1.5L8 14"/><circle cx="17.5" cy="17.5" r="2.5"/>',
  shield:'<path d="M12 3l7 3v5c0 4.2-3 7.4-7 8.5C8 18.4 5 15.2 5 11V6z"/><path d="M12 8.4l1 2.1 2.3.3-1.7 1.6.4 2.3-2-1.1-2 1.1.4-2.3-1.7-1.6 2.3-.3z" stroke-width="1.4"/>',
  back:'<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>',
  check:'<polyline points="20 6 9 17 4 12"/>',
  camera:'<path d="M3 8a2 2 0 0 1 2-2h2l1.5-2h7L19 6h2a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H3z" transform="translate(0 1) scale(0.92)"/><circle cx="12" cy="13" r="3.5"/>',
};
function Icon({n, s=18, sw=2, fill='none', stroke='currentColor', style}) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill={fill} stroke={stroke} strokeWidth={sw}
    strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{__html:P[n]}} />;
}

const TEAMS = [
  { crest:'LL', name:'Lahore Lions', role:'CAPTAIN', color:'#DC4D32', cap:true },
  { crest:'OB', name:'Old Boys', role:'ALL-ROUNDER', color:'#5b4a3a', cap:false },
  { crest:'MK', name:'Mohalla Kings', role:'BATTER', color:'#C98A2B', cap:false },
];
const POSTS = [
  { id:'p1', txt:'Good knock from the boys today — Lions through to the semis. Proud of this squad.', when:'2d', media:true, likes:42, cmts:7 },
  { id:'p2', txt:'Anyone free for a tape-ball friendly this Sunday at Model Town? Need 2 more — DM me.', when:'4d', media:false, likes:11, cmts:9 },
  { id:'p3', txt:'New gloves finally broke in. Match-ready.', when:'1w', media:true, likes:23, cmts:3 },
];

function Toast({ msg }) {
  if (!msg) return null;
  return (
    <div style={{ position:'absolute', left:'50%', bottom:84, transform:'translateX(-50%)', zIndex:60,
      background:ink, color:paper, padding:'10px 16px', borderRadius:11, fontSize:12.5, fontWeight:600,
      whiteSpace:'nowrap', boxShadow:'0 8px 24px -8px rgba(20,18,14,0.5)' }}>{msg}</div>
  );
}

function Avatar({ s=62, fs=22, color, label }) {
  return <div style={{ width:s, height:s, borderRadius:999, background:color||ink, color:paper, flexShrink:0,
    display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800,
    fontSize:fs, letterSpacing:'-0.03em' }}>{label||'MS'}</div>;
}

function TeamChip({ t, onClick }) {
  return (
    <div onClick={onClick} style={{ flexShrink:0, display:'flex', alignItems:'center', gap:9, padding:'8px 14px 8px 8px',
      borderRadius:999, border:'1px solid '+(t.cap?ink:hair), background:t.cap?ink:paper, cursor:'pointer' }}>
      <div style={{ width:30, height:30, borderRadius:999, background:t.color, color:'#fff', display:'flex',
        alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:11, flexShrink:0 }}>{t.crest}</div>
      <div>
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13, letterSpacing:'-0.01em', whiteSpace:'nowrap', color:t.cap?paper:ink }}>{t.name}</div>
        <div style={{ ...mono, fontSize:8, color:t.cap?'rgba(255,255,255,0.6)':muted, marginTop:1, whiteSpace:'nowrap' }}>{t.role}</div>
      </div>
    </div>
  );
}

function Post({ p, onToast }) {
  const [liked, setLiked] = useState(false);
  const [saved, setSaved] = useState(false);
  const likes = p.likes + (liked ? 1 : 0);
  return (
    <div style={{ padding:'14px 18px', borderBottom:'1px solid '+hair }}>
      <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
        <Avatar s={26} fs={10} />
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:12, whiteSpace:'nowrap' }}>Muhammad Saran</div>
        <div style={{ ...mono, fontSize:9, color:soft, marginLeft:'auto' }}>{p.when}</div>
      </div>
      <div style={{ fontSize:13.5, color:ink, lineHeight:1.5 }}>{p.txt}</div>
      {p.media && (
        <div style={{ marginTop:9, height:130, borderRadius:12, background:'linear-gradient(135deg,var(--paper-2),var(--cream))',
          border:'1px solid '+hair, display:'flex', alignItems:'center', justifyContent:'center' }}>
          <Icon n="img" s={26} sw={1.8} stroke={soft} />
        </div>
      )}
      <div style={{ display:'flex', alignItems:'center', gap:18, marginTop:11 }}>
        <button onClick={()=>setLiked(v=>!v)} style={actBtn}>
          <Icon n="heart" s={16} sw={1.9} fill={liked?red:'none'} stroke={liked?red:muted} />
          <span style={{ color:liked?red:muted }}>{likes}</span>
        </button>
        <button onClick={()=>onToast('Comments coming soon')} style={actBtn}>
          <Icon n="cmt" s={16} sw={1.9} stroke={muted} /><span>{p.cmts}</span>
        </button>
        <button onClick={()=>onToast('Shared')} style={actBtn}>
          <Icon n="send" s={16} sw={1.9} stroke={muted} /><span>Share</span>
        </button>
        <button onClick={()=>setSaved(v=>!v)} style={{ ...actBtn, marginLeft:'auto' }}>
          <Icon n="bm" s={16} sw={1.9} fill={saved?ink:'none'} stroke={saved?ink:muted} />
        </button>
      </div>
    </div>
  );
}
const actBtn = { display:'flex', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer',
  fontFamily:'inherit', fontSize:11, color:muted, padding:0 };

function BottomNav({ onToast }) {
  const tabs = [['home','Home'],['bat','Matches'],['shield','Pavilion'],['msg','Messages']];
  return (
    <div style={{ position:'absolute', left:0, right:0, bottom:0, height:62, background:surface,
      borderTop:'1px solid '+hair, display:'grid', gridTemplateColumns:'repeat(5,1fr)', alignItems:'center',
      paddingBottom:4, zIndex:40 }}>
      {tabs.map(([icon,label])=>(
        <button key={label} onClick={()=>onToast(label)} style={navBtn(false)}>
          <span style={{ position:'relative', color:soft }}>
            <Icon n={icon} s={20} sw={1.9} />
            {label==='Messages' && <span style={badge}>2</span>}
          </span>
          <span style={{ fontSize:8.5, fontWeight:600, color:muted }}>{label}</span>
        </button>
      ))}
      <button style={navBtn(true)}>
        <span style={{ width:20, height:20, borderRadius:999, background:paper2, color:ink2, border:'1.5px solid '+red,
          display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:8 }}>BA</span>
        <span style={{ fontSize:8.5, fontWeight:700, color:ink }}>You</span>
      </button>
    </div>
  );
}
const navBtn = () => ({ display:'flex', flexDirection:'column', alignItems:'center', gap:3, background:'none', border:'none', cursor:'pointer', fontFamily:'inherit', padding:0 });
const badge = { position:'absolute', top:-4, right:-7, minWidth:13, height:13, padding:'0 3px', borderRadius:999,
  background:'var(--red)', color:'#fff', fontFamily:'Inter Tight', fontWeight:700, fontSize:8,
  display:'flex', alignItems:'center', justifyContent:'center', border:'1.5px solid var(--surface)' };

const EDIT_COLORS = ['var(--ink)','#DC4D32','#3563B6','#2F7D54','#C98A2B','#6A6F2A','#5b53a6','#a8552e'];
const ROLE_OPTS = ['BATTER','BOWLER','ALL-ROUNDER','KEEPER'];
const BAT_OPTS = ['Right-hand bat','Left-hand bat'];
const BOWL_OPTS = ['Right-arm fast','Right-arm medium','Off-spin','Leg-spin','Left-arm fast','Left-arm orthodox','—'];

function EditProfile({ profile, initials, onCancel, onSave }) {
  const [p, setP] = useState(profile);
  const set = (k,v) => setP(prev=>({ ...prev, [k]:v }));
  const Section = ({ children }) => <div style={{ ...mono, fontSize:10, color:muted, padding:'18px 18px 8px' }}>{children}</div>;
  const Field = ({ label, value, onChange, ph, max }) => (
    <div style={{ padding:'0 18px 12px' }}>
      <div style={{ fontSize:11.5, color:muted, marginBottom:6 }}>{label}</div>
      <input value={value} onChange={e=>onChange(max?e.target.value.slice(0,max):e.target.value)} placeholder={ph}
        style={{ width:'100%', padding:'12px 14px', borderRadius:11, border:'1px solid '+hair, background:surface, fontSize:15, fontFamily:'inherit', color:ink, outline:'none', boxSizing:'border-box' }} />
    </div>
  );
  const Pills = ({ label, opts, value, onChange }) => (
    <div style={{ padding:'0 18px 14px' }}>
      <div style={{ fontSize:11.5, color:muted, marginBottom:8 }}>{label}</div>
      <div style={{ display:'flex', flexWrap:'wrap', gap:7 }}>
        {opts.map(o=>{ const on=value===o; return <button key={o} onClick={()=>onChange(o)} style={{ padding:'8px 13px', borderRadius:999, border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink, fontWeight:600, fontSize:12.5, cursor:'pointer', fontFamily:'inherit' }}>{o}</button>; })}
      </div>
    </div>
  );
  return (
    <div style={{ position:'absolute', inset:0, zIndex:96, background:paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      <div style={{ padding:'4px 12px 12px', flexShrink:0, display:'flex', alignItems:'center', gap:8, borderBottom:'1px solid '+hair }}>
        <button onClick={onCancel} style={{ background:'none', border:'none', cursor:'pointer', fontFamily:'inherit', fontSize:14, color:ink2, padding:'4px 6px' }}>Cancel</button>
        <div style={{ flex:1, textAlign:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:16, letterSpacing:'-0.02em' }}>Edit profile</div>
        <button onClick={()=>onSave(p)} disabled={p.name.trim().length<2} style={{ background:'none', border:'none', cursor:p.name.trim().length<2?'default':'pointer', fontFamily:'inherit', fontSize:14, fontWeight:700, color:p.name.trim().length<2?soft:red, padding:'4px 6px' }}>Save</button>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {/* avatar + color */}
        <div style={{ display:'flex', flexDirection:'column', alignItems:'center', padding:'20px 0 4px', gap:12 }}>
          <div style={{ position:'relative' }}>
            <Avatar s={84} fs={30} color={p.color} label={p.name.split(/\s+/).filter(Boolean).map(w=>w[0]).slice(0,2).join('').toUpperCase()||'MS'} />
            <div style={{ position:'absolute', right:-2, bottom:-2, width:30, height:30, borderRadius:999, background:ink, border:'2px solid '+paper, display:'flex', alignItems:'center', justifyContent:'center' }}><Icon n="camera" s={15} sw={1.8} stroke={paper} /></div>
          </div>
          <div style={{ display:'flex', gap:9 }}>
            {EDIT_COLORS.map(c=>{ const on=p.color===c; return <button key={c} onClick={()=>set('color',c)} aria-label="colour" style={{ width:26, height:26, borderRadius:999, background:c, border:'none', cursor:'pointer', boxShadow:on?'0 0 0 2px var(--paper), 0 0 0 4px '+ink:'inset 0 0 0 1px rgba(0,0,0,0.12)' }} />; })}
          </div>
        </div>

        <Section>Identity</Section>
        <Field label="Full name" value={p.name} onChange={v=>set('name',v)} ph="Your name" max={40} />
        <Field label="Username" value={p.handle} onChange={v=>set('handle',v.replace(/[^a-z0-9_.]/gi,'').toLowerCase())} ph="username" max={20} />
        <Field label="Location" value={p.city} onChange={v=>set('city',v)} ph="Area, city" />

        <Section>Bio</Section>
        <div style={{ padding:'0 18px 12px' }}>
          <textarea value={p.bio} onChange={e=>set('bio', e.target.value.slice(0,160))} rows={3} placeholder="A line about your game…"
            style={{ width:'100%', padding:'12px 14px', borderRadius:11, border:'1px solid '+hair, background:surface, fontSize:14, fontFamily:'inherit', color:ink, outline:'none', resize:'none', lineHeight:1.5, boxSizing:'border-box' }} />
          <div style={{ ...mono, fontSize:9, color:soft, textAlign:'right', marginTop:4 }}>{p.bio.length}/160</div>
        </div>

        <Section>Playing style</Section>
        <Pills label="Role" opts={ROLE_OPTS} value={p.role} onChange={v=>set('role',v)} />
        <Pills label="Batting" opts={BAT_OPTS} value={p.bat} onChange={v=>set('bat',v)} />
        <Pills label="Bowling" opts={BOWL_OPTS} value={p.bowl} onChange={v=>set('bowl',v)} />
        <div style={{ height:24 }} />
      </div>
    </div>
  );
}

function ShareProfileSheet({ name, handle, onClose }) {
  const Row = ({ icon, label, sub, accent }) => (
    <button onClick={onClose} style={{ width:'100%', display:'flex', alignItems:'center', gap:13, padding:'13px 18px', background:paper, border:'none', borderTop:'1px solid '+hair, cursor:'pointer', textAlign:'left', fontFamily:'inherit' }}>
      <div style={{ width:38, height:38, borderRadius:999, background:accent||paper2, color:accent?'#fff':ink, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>{icon}</div>
      <div style={{ flex:1, minWidth:0 }}><div style={{ fontSize:14, fontWeight:600 }}>{label}</div>{sub && <div style={{ fontSize:11.5, color:muted, marginTop:1 }}>{sub}</div>}</div>
    </button>
  );
  return (
    <div style={{ position:'absolute', inset:0, zIndex:70, display:'flex', flexDirection:'column', justifyContent:'flex-end' }}>
      <div onClick={onClose} style={{ position:'absolute', inset:0, background:'rgba(40,30,15,0.35)' }} />
      <div style={{ position:'relative', background:paper, borderRadius:'18px 18px 0 0', paddingBottom:'calc(8px + env(safe-area-inset-bottom))' }}>
        <div style={{ width:36, height:4, borderRadius:999, background:hair, margin:'12px auto 6px' }} />
        <div style={{ ...mono, fontSize:10, color:muted, padding:'6px 18px 4px' }}>SHARE PROFILE · @{handle}</div>
        <Row icon={<Icon n="msg" s={19} stroke="#fff" />} label="WhatsApp" sub="Send to a contact or group" accent="#25923a" />
        <Row icon={<Icon n="share" s={18} stroke={ink} />} label="Copy link" />
        <Row icon={<Icon n="share" s={18} stroke={ink} />} label="More…" sub="Other apps" />
      </div>
    </div>
  );
}

const DEFAULT_PROFILE = {
  name:'Muhammad Saran', handle:'saran', color:'var(--ink)', mono:'MS',
  city:'Gaggarwali, Lahore', role:'ALL-ROUNDER', bat:'Right-hand bat', bowl:'Off-spin',
  bio:'Opening all-rounder & Lions skipper. Tape-ball or hardball — always up for a Sunday game at Model Town.',
};

function ProfileYou({ viewer='self', bioState='written', embedded=false, onBack, onOpenTeam }) {
  const isMe = viewer === 'self';
  const [following, setFollowing] = useState(false);
  const [followView, setFollowView] = useState(null); // null | 'followers' | 'following'
  const [editing, setEditing] = useState(false);
  const [share, setShare] = useState(false);
  const [profile, setProfile] = useState(() => ({ ...DEFAULT_PROFILE, bio: bioState==='written'?DEFAULT_PROFILE.bio:'' }));
  const [toast, setToast] = useState(null);
  const flash = (m) => { setToast(m); clearTimeout(window.__pt); window.__pt = setTimeout(()=>setToast(null), 1400); };
  const initials = profile.name.split(/\s+/).filter(Boolean).map(w=>w[0]).slice(0,2).join('').toUpperCase() || 'MS';

  // bio block
  let bioEl;
  if (profile.bio) {
    bioEl = <div style={{ padding:'11px 20px 0', fontSize:12.5, color:ink2, lineHeight:1.5 }}>{profile.bio}</div>;
  } else if (isMe) {
    bioEl = <div style={{ padding:'11px 20px 0' }}>
      <button onClick={()=>setEditing(true)} style={{ display:'inline-flex', alignItems:'center', gap:6, color:muted,
        border:'1px dashed '+line, borderRadius:9, padding:'8px 12px', fontSize:12, fontWeight:600, background:'none', cursor:'pointer', fontFamily:'inherit', whiteSpace:'nowrap' }}>
        <Icon n="plus" s={13} sw={2.4} /> Add a bio
      </button>
    </div>;
  } else {
    bioEl = <div style={{ padding:'11px 20px 0', fontSize:12.5, color:muted, lineHeight:1.5, fontStyle:'italic' }}>{profile.role.toLowerCase()} · {profile.bat.toLowerCase()} · open to friendlies</div>;
  }

  if (editing) return <EditProfile profile={profile} initials={initials} onCancel={()=>setEditing(false)} onSave={(p)=>{ setProfile(p); setEditing(false); flash('Profile saved'); }} />;

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%', background:paper, position:'relative', fontFamily:'Inter,system-ui' }}>
      <div style={{ height:44, flexShrink:0 }} />
      {/* standard back-header */}
      <div style={{ padding:'4px 12px 12px', flexShrink:0, display:'flex', alignItems:'center', gap:8, borderBottom:'1px solid '+hair }}>
        {onBack && <button onClick={onBack} aria-label="Back" style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, flexShrink:0, color:ink }}><Icon n="back" s={20} sw={2} stroke={ink} /></button>}
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:18, letterSpacing:'-0.02em' }}>{isMe ? 'Profile' : '@'+profile.handle}</div>
        <button onClick={()=>isMe?setEditing(true):flash('More')} style={{ ...iconBtn, marginLeft:'auto' }}>{isMe ? <Icon n="gear" s={18} sw={1.7} stroke={ink} /> : <Icon n="dots" s={18} stroke={ink} />}</button>
      </div>

      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {/* identity */}
        <div style={{ padding:'4px 18px 0' }}>
          <div style={{ display:'flex', gap:14, alignItems:'center' }}>
            <Avatar color={profile.color} label={initials} />
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ ...display(20) }}>{profile.name}</div>
              <div style={{ fontFamily:'JetBrains Mono', fontSize:11, color:muted, marginTop:3 }}>@{profile.handle}</div>
              <div style={{ display:'flex', alignItems:'center', gap:5, fontSize:12, color:ink2, marginTop:5 }}>
                <Icon n="pin" s={12} sw={2} stroke={muted} /> {profile.city}
              </div>
            </div>
          </div>
          <div style={{ display:'flex', flexWrap:'wrap', alignItems:'center', gap:7, marginTop:9, fontSize:11.5, color:ink2 }}>
            <span style={{ ...mono, fontSize:8.5, padding:'2px 6px', borderRadius:5, background:paper2, color:ink2, whiteSpace:'nowrap' }}>{profile.role}</span>
            <span style={{ whiteSpace:'nowrap' }}>{profile.bat} · {profile.bowl}</span>
          </div>
        </div>

        {bioEl}

        {/* quiet metrics — tappable */}
        <div style={{ padding:'14px 20px 0', fontSize:12.5, color:muted }}>
          <button onClick={()=>setFollowView('followers')} style={countBtn}><b style={{ color:ink, fontFamily:'Inter Tight', fontWeight:700, fontSize:15 }}>284</b> followers</button>
          <span style={{ margin:'0 4px' }}>·</span>
          <button onClick={()=>setFollowView('following')} style={countBtn}><b style={{ color:ink, fontFamily:'Inter Tight', fontWeight:700, fontSize:15 }}>92</b> following</button>
        </div>

        {/* actions */}
        <div style={{ display:'flex', gap:8, padding:'14px 18px 0' }}>
          {isMe ? (
            <>
              <button onClick={()=>setEditing(true)} style={btn(true)}><Icon n="edit" s={15} sw={2.2} stroke={paper} /> Edit profile</button>
              <button onClick={()=>setShare(true)} style={btn(false)}><Icon n="share" s={15} sw={1.9} stroke={ink} /> Share</button>
            </>
          ) : (
            <>
              <button onClick={()=>setFollowing(v=>!v)} style={following ? btn(false) : btnRed()}>
                {following ? 'Following' : 'Follow'}
              </button>
              <button onClick={()=>flash('Message')} style={btn(false)}><Icon n="msg" s={15} sw={1.9} stroke={ink} /> Message</button>
            </>
          )}
        </div>

        {/* captains */}
        <div style={{ padding:'18px 0 0' }}>
          <div style={{ ...mono, fontSize:10, color:muted, padding:'0 20px 9px', fontFamily:'JetBrains Mono' }}>CAPTAINS</div>
          <div style={{ display:'flex', gap:8, overflowX:'auto', padding:'0 18px' }}>
            {TEAMS.filter(t=>t.cap).map(t=><TeamChip key={t.crest} t={t} onClick={()=>onOpenTeam?onOpenTeam(t):flash('Open '+t.name)} />)}
          </div>
        </div>
        {/* plays for */}
        <div style={{ padding:'14px 0 0' }}>
          <div style={{ ...mono, fontSize:10, color:muted, padding:'0 20px 9px', fontFamily:'JetBrains Mono' }}>PLAYS FOR</div>
          <div style={{ display:'flex', gap:8, overflowX:'auto', padding:'0 18px' }}>
            {TEAMS.filter(t=>!t.cap).map(t=><TeamChip key={t.crest} t={t} onClick={()=>onOpenTeam?onOpenTeam(t):flash('Open '+t.name)} />)}
          </div>
        </div>

        {/* feed */}
        <div style={{ borderTop:'1px solid '+hair, marginTop:16 }} />
        {POSTS.map(p=><Post key={p.id} p={p} onToast={flash} />)}
        <div style={{ height:74 }} />
      </div>

      {isMe && (
        <button onClick={()=>flash('New post')} style={{ position:'absolute', right:16, bottom:74, width:50, height:50,
          borderRadius:999, background:ink, color:paper, border:'none', display:'flex', alignItems:'center', justifyContent:'center',
          boxShadow:'0 8px 20px -6px rgba(40,30,15,0.5)', cursor:'pointer', zIndex:45 }}>
          <Icon n="plus" s={22} sw={2.4} stroke={paper} />
        </button>
      )}

      {!embedded && <BottomNav onToast={flash} />}
      <Toast msg={toast} />
      {share && <ShareProfileSheet name={profile.name} handle={profile.handle} onClose={()=>setShare(false)} />}
      {followView && window.FollowersScreen && <window.FollowersScreen initialTab={followView} onBack={()=>setFollowView(null)} />}
    </div>
  );
}
const iconBtn = { width:30, height:30, display:'flex', alignItems:'center', justifyContent:'center', background:'none', border:'none', cursor:'pointer', padding:0, color:ink };
const countBtn = { background:'none', border:'none', padding:0, cursor:'pointer', fontFamily:'inherit', fontSize:12.5, color:muted };
const btn = (solid) => ({ flex:1, padding:'10px 0', borderRadius:11, fontFamily:'inherit', fontWeight:solid?700:600, fontSize:13,
  cursor:'pointer', border:solid?'1px solid '+ink:'1px solid '+line, background:solid?ink:paper, color:solid?paper:ink,
  display:'inline-flex', alignItems:'center', justifyContent:'center', gap:7, whiteSpace:'nowrap' });
const btnRed = () => ({ flex:1, padding:'10px 0', borderRadius:11, fontFamily:'inherit', fontWeight:700, fontSize:13, cursor:'pointer',
  border:'none', background:red, color:'#fff', boxShadow:'0 4px 12px rgba(220,77,50,.26)', whiteSpace:'nowrap' });

window.ProfileYou = ProfileYou;
})();

// home-messages.jsx — real Home (feed) + Messages (threads + chat) for the shell.
// Exports window.HomeFeed and window.MessagesScreen.

(function () {
const { useState } = React;

const ink='var(--ink)', ink2='var(--ink-2)', muted='var(--muted)', soft='var(--soft)',
      paper='var(--paper)', paper2='var(--paper-2)', surface='var(--surface)',
      hair='var(--hairline)', line='var(--line)', red='var(--red)', redSoft='var(--red-soft)',
      green='var(--green)', greenSoft='var(--green-soft)', greenInk='var(--green-ink)',
      amber='var(--amber)', cream='var(--cream)';
const mono = { fontFamily:'JetBrains Mono,monospace', fontWeight:700, letterSpacing:'0.1em', textTransform:'uppercase' };

const P = {
  heart:'<path d="M20.8 5.6a5 5 0 0 0-7.1 0L12 7.3l-1.7-1.7a5 5 0 1 0-7.1 7.1L12 21l8.8-8.3a5 5 0 0 0 0-7.1z"/>',
  thumb:'<path d="M7 11v9H4a1 1 0 0 1-1-1v-7a1 1 0 0 1 1-1z"/><path d="M7 11l4.5-7.4a1.6 1.6 0 0 1 2.9 1.1L13.5 9H19a2 2 0 0 1 2 2.4l-1.4 6.6a2 2 0 0 1-2 1.6H7"/>',
  share:'<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>',
  wa:'<path d="M12 3a9 9 0 0 0-7.7 13.6L3 21l4.5-1.2A9 9 0 1 0 12 3z"/><path d="M8.5 8.5c-.3 1.2.3 2.6 1.4 3.7s2.5 1.7 3.7 1.4c.5-.1.7-.7.5-1.1l-.5-.9a.7.7 0 0 0-.8-.3l-.8.3-1.8-1.8.3-.8a.7.7 0 0 0-.3-.8l-.9-.5c-.4-.2-1 0-1.1.5z"/>',
  link:'<path d="M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1"/><path d="M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/>',
  flag:'<path d="M4 22V4M4 4h13l-2 4 2 4H4"/>',
  mute:'<path d="M11 5 6 9H2v6h4l5 4z"/><path d="M22 9l-6 6M16 9l6 6"/>',
  trash:'<path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14"/>',
  cmt:'<path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 9 9 0 0 1-3.9-.9L3 20l1.3-3.6A8.4 8.4 0 1 1 21 11.5z"/>',
  repost:'<path d="M17 2l4 4-4 4M3 11V9a4 4 0 0 1 4-4h14M7 22l-4-4 4-4M21 13v2a4 4 0 0 1-4 4H3"/>',
  bm:'<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>',
  dots:'<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>',
  chev:'<path d="M9 6l6 6-6 6"/>',
  img:'<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="m21 15-5-5L5 21"/>',
  back:'<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>',
  send:'<path d="M22 2 11 13M22 2l-7 20-4-9-9-4z"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  pencil:'<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',
};
function Ic({n, s=18, sw=1.9, stroke='currentColor', fill='none', style}) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill={fill} stroke={stroke} strokeWidth={sw}
    strokeLinecap="round" strokeLinejoin="round" style={style} dangerouslySetInnerHTML={{__html:P[n]}} />;
}
function Crest({ m, color, size=42, round }) {
  return <div style={{ width:size, height:size, borderRadius:round?999:12, background:color||ink, color:'#fff', flexShrink:0,
    display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:size*0.36, letterSpacing:'-0.02em' }}>{m}</div>;
}

// ─────────────────────────────────────────────────────────
// HOME FEED
// ─────────────────────────────────────────────────────────
const KIND = {
  live:      { bg:red, fg:'#fff', label:'LIVE' },
  milestone: { bg:greenSoft, fg:greenInk, label:'MILESTONE' },
  result:    { bg:paper2, fg:ink2, label:'RESULT' },
  recruit:   { bg:cream, fg:'#7a5a1e', label:'LOOKING FOR PLAYERS' },
  team:      null,
};

function PostActions({ likes, comments, onComment, onShare }) {
  const [liked, setLiked] = useState(false);
  return (
    <div style={{ display:'flex', alignItems:'center', marginTop:6, marginLeft:-8, color:muted }}>
      <button onClick={()=>setLiked(v=>!v)} style={aBtn}><Ic n="thumb" s={18} fill={liked?red:'none'} stroke={liked?red:muted} /><span style={{ ...num, color:liked?red:muted }}>{likes+(liked?1:0)}</span></button>
      <button onClick={onShare} style={{ ...aBtn, marginLeft:'auto', marginRight:-8 }}><Ic n="share" s={18} stroke={muted} /></button>
    </div>
  );
}
const aBtn = { display:'inline-flex', alignItems:'center', gap:7, minHeight:44, padding:'0 8px', background:'none', border:'none', cursor:'pointer', color:'inherit' };
const num = { fontFamily:'JetBrains Mono', fontSize:12, fontWeight:600 };

function FollowPill() {
  const [f, setF] = useState(false);
  return (
    <button onClick={(e)=>{ e.stopPropagation(); setF(v=>!v); }} style={{ flexShrink:0, height:28, padding:'0 13px', borderRadius:999,
      border:'1px solid '+(f?hair:ink), background:f?paper:ink, color:f?ink2:paper, fontFamily:'inherit', fontSize:11.5, fontWeight:700, cursor:'pointer' }}>
      {f?'Following':'Follow'}
    </button>
  );
}

function Post({ p, onComment, onAuthor }) {
  const k = KIND[p.kind];
  const [menu, setMenu] = useState(false);
  const [share, setShare] = useState(false);
  const [report, setReport] = useState(false);
  const tc = TOPCMT[p.author];
  return (
    <article style={{ borderBottom:'1px solid '+hair, padding:'12px 18px 8px', background:paper, position:'relative' }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:10 }}>
        <button onClick={()=>onAuthor&&onAuthor(p)} style={{ background:'none', border:'none', padding:0, cursor:'pointer' }}><Crest m={p.mono} color={p.color} size={40} round={!p.team} /></button>
        <button onClick={()=>onAuthor&&onAuthor(p)} style={{ flex:1, minWidth:0, background:'none', border:'none', padding:'4px 0', cursor:'pointer', textAlign:'left', fontFamily:'inherit' }}>
          <div style={{ display:'flex', alignItems:'center', gap:6, flexWrap:'wrap' }}>
            <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.01em', whiteSpace:'nowrap', color:ink }}>{p.author}</span>
            {k && <span style={{ ...mono, fontSize:8.5, padding:'2px 6px', borderRadius:4, background:k.bg, color:k.fg, letterSpacing:'0.06em' }}>{k.label}</span>}
          </div>
          <div style={{ fontFamily:'JetBrains Mono', fontSize:10.5, color:muted, marginTop:2 }}>{p.handle} · {p.when}</div>
        </button>
        {p.notFollowed && <FollowPill />}
        <button onClick={()=>setMenu(true)} style={{ background:'none', border:'none', width:40, height:40, marginRight:-8, cursor:'pointer', color:muted, display:'flex', alignItems:'center', justifyContent:'center' }}><Ic n="dots" s={17} sw={2} /></button>
      </div>

      {p.body && <div onClick={()=>onComment&&onComment(p)} style={{ fontSize:13.5, color:ink, lineHeight:1.5, marginBottom:p.card||p.photo?10:0, cursor:'pointer' }}>{p.body}</div>}

      {p.kind==='result' && p.card && (
        <div onClick={()=>onComment&&onComment(p)} style={{ border:'1px solid '+hair, borderRadius:12, overflow:'hidden', marginBottom:2, cursor:'pointer' }}>
          {[[p.card.a, p.card.as, p.card.win], [p.card.b, p.card.bs, !p.card.win]].map((r,i)=>(
            <div key={i} style={{ display:'flex', alignItems:'center', gap:10, padding:'10px 12px', borderTop:i?'1px solid '+hair:'none', background:r[2]?greenSoft:paper }}>
              <Crest m={r[0].m} color={r[0].c} size={26} />
              <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:700, fontSize:13 }}>{r[0].n}</span>
              <span style={{ fontFamily:'JetBrains Mono', fontWeight:700, fontSize:14, color:ink }}>{r[1]}</span>
            </div>
          ))}
          <div onClick={()=>onComment&&onComment(p)} style={{ padding:'8px 12px', borderTop:'1px solid '+hair, fontSize:11.5, color:muted, display:'flex', alignItems:'center', justifyContent:'space-between', cursor:'pointer' }}>
            <span>{p.card.note}</span>
            <span style={{ ...mono, fontSize:9, color:ink2 }}>SCORECARD →</span>
          </div>
        </div>
      )}
      {p.photo && (
        <div style={{ height:170, borderRadius:12, background:'linear-gradient(135deg,var(--paper-2),var(--cream))', border:'1px solid '+hair, display:'flex', alignItems:'center', justifyContent:'center' }}>
          <Ic n="img" s={28} sw={1.6} stroke={soft} />
        </div>
      )}
      {p.kind==='recruit' && (
        <button style={{ marginTop:10, width:'100%', padding:'11px 0', borderRadius:12, border:'none', background:ink, color:paper, fontFamily:'inherit', fontWeight:700, fontSize:13, cursor:'pointer' }}>Offer to play</button>
      )}

      <PostActions likes={p.likes} comments={p.comments} onComment={()=>onComment&&onComment(p)} onShare={()=>setShare(true)} />

      {/* inline top comment, or 'be the first' when empty */}
      {p.comments>0 ? (tc && (
        <div style={{ marginTop:11, display:'flex', flexDirection:'column', gap:6 }}>
          <div style={{ display:'flex', alignItems:'flex-start', gap:8 }}>
            <Crest m={tc.m} color={tc.c} size={22} round />
            <div style={{ fontSize:12.5, color:ink, lineHeight:1.4, flex:1, minWidth:0 }}><b style={{ fontFamily:'Inter Tight', fontWeight:700 }}>{tc.who}</b>&nbsp; {tc.t}</div>
          </div>
          <button onClick={()=>onComment&&onComment(p)} style={{ background:'none', border:'none', padding:0, cursor:'pointer', fontFamily:'inherit', fontSize:12, color:muted, textAlign:'left' }}>View all {p.comments} comments</button>
        </div>
      )) : (
        <button onClick={()=>onComment&&onComment(p)} style={{ marginTop:11, background:'none', border:'none', padding:0, cursor:'pointer', fontFamily:'inherit', fontSize:12.5, color:muted, textAlign:'left' }}>Be the first to comment</button>
      )}

      {menu && <OverflowMenu own={p.own} onClose={()=>setMenu(false)} onReport={()=>{ setMenu(false); setReport(true); }} />}
      {share && <ShareSheet onClose={()=>setShare(false)} />}
      {report && <ReportSheet onClose={()=>setReport(false)} />}
    </article>
  );
}

const FEED = [
  { author:'Faraz Khan', mono:'FK', handle:'@faraz.k', when:'12m', body:"What a finish at Gaddafi. Bilal holding his nerve in the last over — that's how you close a game. 🦁", likes:24, comments:6 },
  { author:'Lahore Lions', mono:'LL', color:'#DC4D32', team:true, kind:'result', handle:'@lahore.lions', when:'1h',
    body:'Full time — Lions take the Spring Cup QF.',
    card:{ a:{m:'LL',n:'Lahore Lions',c:'#DC4D32'}, as:'142/6', b:{m:'MT',n:'Multan Tigers',c:'#7a4a2a'}, bs:'119/9', win:true, note:'Won by 23 runs · Player of the match: B. Ahmed' },
    likes:88, comments:14 },
  { author:'Adeel Sheikh', mono:'AS', color:'#3563B6', handle:'@adeel_wk', when:'3h', kind:'milestone',
    body:'50 dismissals behind the stumps this season. Slowly getting there.', likes:41, comments:9 },
  { author:'Mohalla Kings', mono:'MK', color:'#C98A2B', team:true, kind:'recruit', handle:'@mohalla.kings', when:'5h', notFollowed:true,
    body:'Need 2 seam bowlers for Sunday’s tape-ball friendly at Model Town. DHA side, 8 PM start.', likes:11, comments:21 },
  { author:'Usman Riaz', mono:'UR', color:'#6A6F2A', handle:'@usman', when:'6h', photo:true, notFollowed:true,
    body:'New run-up marked out. Match ready.', likes:33, comments:4 },
  { author:'Lahore Lions', mono:'LL', color:'#DC4D32', team:true, kind:'team', handle:'@lahore.lions', when:'8h',
    body:'Practice tomorrow 6 AM at Gaddafi B. Bring whites. Net 3 booked.', likes:19, comments:0 },
];

const TOPCMT = {
  'Faraz Khan': { who:'Bilal Ahmed', m:'BA', c:'#DC4D32', t:'Top edge that last six 😄 clutch.' },
  'Lahore Lions': { who:'Adeel Sheikh', m:'AS', c:'#3563B6', t:'What a chase. POTM well deserved.' },
  'Adeel Sheikh': { who:'Imran Saeed', m:'IS', c:'#3a8f8f', t:'Safe hands all season 🧤' },
  'Mohalla Kings': { who:'Usman Riaz', m:'UR', c:'#6A6F2A', t:'I’m in — RFM, can do Sunday.' },
  'Usman Riaz': { who:'Faraz Khan', m:'FK', c:'#2F7D54', t:'That run-up looks smooth.' },
};

function OverflowMenu({ own, onClose, onReport }) {
  const Item = ({ icon, label, danger, onClick, top }) => (
    <button onClick={onClick} style={{ width:'100%', display:'flex', alignItems:'center', gap:11, padding:'11px 14px', background:paper, border:'none', borderTop:top?'none':'1px solid '+hair, cursor:'pointer', textAlign:'left', fontFamily:'inherit', fontSize:13.5, fontWeight:500, color:danger?red:ink, whiteSpace:'nowrap' }}>
      <Ic n={icon} s={17} stroke={danger?red:ink2} /> {label}
    </button>
  );
  return (
    <>
      <div onClick={onClose} style={{ position:'fixed', inset:0, zIndex:59 }} />
      <div style={{ position:'absolute', top:40, right:14, zIndex:61, minWidth:184, background:paper, border:'1px solid '+hair, borderRadius:14, boxShadow:'0 12px 30px -10px rgba(40,30,15,0.30)', overflow:'hidden' }}>
        {own ? (<>
          <Item icon="pencil" label="Edit post" top onClick={onClose} />
          <Item icon="trash" label="Delete post" danger onClick={onClose} />
        </>) : (<>
          <Item icon="mute" label="Mute" top onClick={onClose} />
          <Item icon="link" label="Copy link" onClick={onClose} />
          <Item icon="flag" label="Report post" danger onClick={onReport} />
        </>)}
      </div>
    </>
  );
}

function ShareSheet({ onClose }) {
  const Row = ({ icon, label, sub, accent, onClick }) => (
    <button onClick={onClick} style={{ width:'100%', display:'flex', alignItems:'center', gap:13, padding:'13px 18px', background:paper, border:'none', borderTop:'1px solid '+hair, cursor:'pointer', textAlign:'left', fontFamily:'inherit' }}>
      <div style={{ width:38, height:38, borderRadius:999, background:accent||paper2, color:accent?'#fff':ink, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Ic n={icon} s={19} stroke={accent?'#fff':ink} /></div>
      <div style={{ flex:1, minWidth:0 }}><div style={{ fontSize:14, fontWeight:600 }}>{label}</div>{sub && <div style={{ fontSize:11.5, color:muted, marginTop:1 }}>{sub}</div>}</div>
    </button>
  );
  return (
    <div style={{ position:'absolute', inset:0, zIndex:60, display:'flex', flexDirection:'column', justifyContent:'flex-end' }}>
      <div onClick={onClose} style={{ position:'absolute', inset:0, background:'rgba(40,30,15,0.35)' }} />
      <div style={{ position:'relative', background:paper, borderRadius:'18px 18px 0 0', paddingBottom:'calc(8px + env(safe-area-inset-bottom))' }}>
        <div style={{ width:36, height:4, borderRadius:999, background:hair, margin:'12px auto 6px' }} />
        <div style={{ ...mono, fontSize:10, color:muted, padding:'6px 18px 4px' }}>SHARE TO</div>
        <Row icon="wa" label="WhatsApp" sub="Send to a team group" accent="#25923a" onClick={onClose} />
        <Row icon="link" label="Copy link" onClick={onClose} />
        <Row icon="share" label="More…" sub="Other apps" onClick={onClose} />
      </div>
    </div>
  );
}

function ReportSheet({ onClose }) {
  const reasons = ['Spam or scam','Abuse or harassment','Wrong / misleading info','Nudity or violence','Other'];
  return (
    <div style={{ position:'absolute', inset:0, zIndex:62, display:'flex', flexDirection:'column', justifyContent:'flex-end' }}>
      <div onClick={onClose} style={{ position:'absolute', inset:0, background:'rgba(40,30,15,0.35)' }} />
      <div style={{ position:'relative', background:paper, borderRadius:'18px 18px 0 0', paddingBottom:'calc(8px + env(safe-area-inset-bottom))' }}>
        <div style={{ width:36, height:4, borderRadius:999, background:hair, margin:'12px auto 8px' }} />
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:16, letterSpacing:'-0.01em', padding:'2px 18px 4px' }}>Report post</div>
        <div style={{ fontSize:12, color:muted, padding:'0 18px 8px' }}>Why are you reporting this?</div>
        {reasons.map((r,i)=>(
          <button key={i} onClick={onClose} style={{ width:'100%', display:'flex', alignItems:'center', justifyContent:'space-between', padding:'13px 18px', background:paper, border:'none', borderTop:'1px solid '+hair, cursor:'pointer', textAlign:'left', fontFamily:'inherit', fontSize:14, color:ink }}>
            {r} <Ic n="chev" s={16} stroke={soft} />
          </button>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// COMMENTS
// ─────────────────────────────────────────────────────────
const COMMENTS = {
  'Faraz Khan': [
    { who:'Bilal Ahmed', m:'BA', c:'#DC4D32', t:'Top edge that last six 😄 clutch.', when:'10m', likes:8 },
    { who:'Imran Saeed', m:'IS', c:'#3a8f8f', t:'Captain’s knock under pressure. Proud of the boys.', when:'8m', likes:3 },
    { who:'Adeel Sheikh', m:'AS', c:'#3563B6', t:'That yorker at the death was unplayable.', when:'5m', likes:1 },
    { who:'Usman Riaz', m:'UR', c:'#6A6F2A', t:'Whites washed and ready for Sunday 😅', when:'2m', likes:0 },
  ],
  'Lahore Lions': [
    { who:'Adeel Sheikh', m:'AS', c:'#3563B6', t:'What a chase. POTM well deserved.', when:'50m', likes:12 },
    { who:'Mohalla Kings', m:'MK', c:'#C98A2B', t:'Rematch when? 👀', when:'40m', likes:6 },
    { who:'Faraz Khan', m:'FK', c:'#2F7D54', t:'Lions on top of the table now.', when:'30m', likes:4 },
  ],
  _default: [
    { who:'Imran Saeed', m:'IS', c:'#3a8f8f', t:'Nice one 👏', when:'1h', likes:2 },
    { who:'Bilal Ahmed', m:'BA', c:'#DC4D32', t:'Let’s go!', when:'45m', likes:0 },
  ],
};

function CommentRow({ c }) {
  const [liked, setLiked] = useState(false);
  return (
    <div style={{ display:'flex', gap:10, padding:'12px 18px', borderTop:'1px solid '+hair }}>
      <Crest m={c.m} color={c.c} size={32} round />
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontSize:13, lineHeight:1.45, color:ink }}>
          <b style={{ fontFamily:'Inter Tight', fontWeight:700 }}>{c.who}</b>&nbsp; {c.t}
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:16, marginTop:6 }}>
          <span style={{ fontFamily:'JetBrains Mono', fontSize:9, color:muted }}>{c.when.toUpperCase()}</span>
          <button onClick={()=>setLiked(v=>!v)} style={{ background:'none', border:'none', padding:0, cursor:'pointer', fontFamily:'JetBrains Mono', fontSize:9, fontWeight:700, letterSpacing:'0.06em', color:liked?red:muted }}>{(c.likes+(liked?1:0))>0 ? (c.likes+(liked?1:0))+' ' : ''}LIKE</button>
          <button style={{ background:'none', border:'none', padding:0, cursor:'pointer', fontFamily:'JetBrains Mono', fontSize:9, fontWeight:700, letterSpacing:'0.06em', color:muted }}>REPLY</button>
        </div>
      </div>
      <button onClick={()=>setLiked(v=>!v)} style={{ background:'none', border:'none', padding:'2px 0', cursor:'pointer', color:liked?red:soft, alignSelf:'flex-start' }}><Ic n="thumb" s={15} fill={liked?red:'none'} stroke={liked?red:soft} /></button>
    </div>
  );
}

function CommentsScreen({ post, onBack }) {
  const list = post.comments === 0 ? [] : (COMMENTS[post.author] || COMMENTS._default);
  const wrapRef = React.useRef(null);
  const dragging = React.useRef(false);
  const [frac, setFrac] = useState(0.66);
  const onDown = (e) => { dragging.current = true; e.currentTarget.setPointerCapture && e.currentTarget.setPointerCapture(e.pointerId); };
  const onMove = (e) => {
    if (!dragging.current || !wrapRef.current) return;
    const r = wrapRef.current.getBoundingClientRect();
    const f = (r.bottom - e.clientY) / r.height;
    setFrac(Math.max(0.34, Math.min(0.95, f)));
  };
  const onUp = () => { if (!dragging.current) return; dragging.current = false; if (frac < 0.42) onBack(); };

  return (
    <div ref={wrapRef} onPointerMove={onMove} onPointerUp={onUp} onPointerLeave={onUp}
      style={{ position:'absolute', inset:0, zIndex:92, display:'flex', flexDirection:'column', justifyContent:'flex-end' }}>
      <div onClick={onBack} style={{ position:'absolute', inset:0, background:'rgba(40,30,15,0.35)' }} />
      <div style={{ position:'relative', height:(frac*100)+'%', background:paper, borderRadius:'20px 20px 0 0',
        display:'flex', flexDirection:'column', overflow:'hidden', boxShadow:'0 -10px 40px -12px rgba(40,30,15,0.3)',
        transition: dragging.current ? 'none' : 'height 0.22s cubic-bezier(0.32,0.72,0,1)' }}>
        {/* drag handle + title */}
        <div onPointerDown={onDown} style={{ flexShrink:0, cursor:'grab', touchAction:'none', borderBottom:'1px solid '+hair }}>
          <div style={{ width:38, height:4, borderRadius:999, background:hair, margin:'10px auto 4px' }} />
          <div style={{ display:'flex', alignItems:'center', gap:8, padding:'2px 18px 11px' }}>
            <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:16, letterSpacing:'-0.02em' }}>Comments</div>
            <span style={{ fontFamily:'JetBrains Mono', fontSize:11, color:muted }}>{list.length}</span>
            <button onClick={onBack} style={{ marginLeft:'auto', background:'none', border:'none', cursor:'pointer', padding:4, color:muted }}><Ic n="back" s={0} /><span style={{ fontFamily:'JetBrains Mono', fontSize:10, fontWeight:700, letterSpacing:'0.08em' }}>CLOSE</span></button>
          </div>
        </div>

        <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
          {/* original post summary */}
          <div style={{ display:'flex', gap:10, padding:'12px 18px', background:paper2 }}>
            <Crest m={post.mono} color={post.color} size={32} round={!post.team} />
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ display:'flex', alignItems:'center', gap:6 }}>
                <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:13 }}>{post.author}</span>
                <span style={{ fontFamily:'JetBrains Mono', fontSize:9.5, color:muted }}>· {post.when}</span>
              </div>
              <div style={{ fontSize:12.5, color:ink2, lineHeight:1.45, marginTop:3, display:'-webkit-box', WebkitLineClamp:2, WebkitBoxOrient:'vertical', overflow:'hidden' }}>{post.body}</div>
            </div>
          </div>

          {list.length === 0 ? (
            <div style={{ display:'flex', flexDirection:'column', alignItems:'center', textAlign:'center', padding:'48px 34px', gap:8 }}>
              <div style={{ width:56, height:56, borderRadius:16, background:paper2, border:'1px solid '+hair, display:'flex', alignItems:'center', justifyContent:'center', marginBottom:4 }}>
                <Ic n="cmt" s={24} sw={1.7} stroke={soft} />
              </div>
              <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:16, letterSpacing:'-0.01em' }}>No comments yet</div>
              <div style={{ fontSize:13, color:muted, lineHeight:1.5 }}>Be the first to share your take.</div>
            </div>
          ) : list.map((c,i)=><CommentRow key={i} c={c} />)}
          <div style={{ height:12 }} />
        </div>

        {/* reply bar */}
        <div style={{ flexShrink:0, borderTop:'1px solid '+hair, padding:'10px 12px calc(12px + env(safe-area-inset-bottom))', display:'flex', alignItems:'center', gap:9, background:paper }}>
          <Crest m="MS" size={30} round />
          <div style={{ flex:1, height:38, borderRadius:999, background:paper2, border:'1px solid '+hair, display:'flex', alignItems:'center', padding:'0 14px', fontSize:13.5, color:muted }}>{list.length===0?'Add the first comment…':'Add a comment…'}</div>
          <button style={{ width:38, height:38, borderRadius:999, border:'none', background:ink, color:paper, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Ic n="send" s={17} sw={2} stroke={paper} /></button>
        </div>
      </div>
    </div>
  );
}

function HomeFeed({ header, onCompose, onComment, onAuthor }) {
  const [cmt, setCmt] = useState(null);
  const [feed, setFeed] = useState('following');
  return (
    <div style={{ flex:1, display:'flex', flexDirection:'column', background:paper, minHeight:0, position:'relative' }}>
      {header}
      <div style={{ display:'flex', gap:6, padding:'8px 18px 10px', flexShrink:0, borderBottom:'1px solid '+hair }}>
        {[['following','Following'],['discover','Discover']].map(([id,label])=>{
          const on = feed===id;
          return <button key={id} onClick={()=>setFeed(id)} style={{ height:34, padding:'0 16px', borderRadius:999, cursor:'pointer', fontFamily:'inherit', fontSize:13, fontWeight:on?700:600, border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink2 }}>{label}</button>;
        })}
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {FEED.map((p,i)=><Post key={i} p={p} onComment={setCmt} onAuthor={onAuthor} />)}
        <div style={{ height:24 }} />
      </div>
      {cmt && <CommentsScreen post={cmt} onBack={()=>setCmt(null)} />}
    </div>
  );
}

// ─────────────────────────────────────────────────────────
// MESSAGES
// ─────────────────────────────────────────────────────────
const THREADS = [
  { id:'t1', m:'LL', color:'#DC4D32', team:true, name:'Lahore Lions', preview:[['Imran: ',true],['XI confirmed for tomorrow. Faraz at 3.',false]], time:'now', unread:5, scope:'teams' },
  { id:'t2', m:'QF', color:'#7a4a2a', team:true, name:'QF · Lions vs Cobras', preview:[['Scorer: ',true],['Toss done. Lions chose to bowl.',false]], time:'2h', unread:1, pinned:true, scope:'teams' },
  { id:'t3', m:'BA', name:'Bilal Ahmed', preview:[['Are we still on for nets Wednesday?',false]], time:'Yesterday', unread:0, scope:'dms' },
  { id:'t4', m:'IS', name:'Imran Saeed', preview:[['You: ',true],['Yeah, I’ll be there by 7.',false]], time:'2d', unread:0, scope:'dms' },
  { id:'t5', m:'KE', color:'#3563B6', team:true, name:'Karachi Eagles · Roster', preview:[['Faisal joined the team',false]], time:'3d', unread:0, system:true, scope:'teams' },
];

function ThreadRow({ t, onOpen }) {
  return (
    <button onClick={()=>onOpen(t)} style={{ width:'100%', display:'flex', gap:12, padding:'13px 18px', borderTop:'1px solid '+hair, background:t.unread?paper2:paper, cursor:'pointer', textAlign:'left', fontFamily:'inherit' }}>
      <Crest m={t.m} color={t.color} size={42} round={!t.team} />
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ display:'flex', alignItems:'baseline', gap:6 }}>
          <span style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:14, letterSpacing:'-0.01em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{t.name}</span>
          {t.pinned && <span style={{ width:5, height:5, borderRadius:999, background:soft, flexShrink:0 }} />}
          <span style={{ flex:1 }} />
          <span style={{ fontFamily:'JetBrains Mono', fontSize:9, fontWeight:700, color:t.unread?red:muted, flexShrink:0 }}>{t.time.toUpperCase()}</span>
        </div>
        <div style={{ fontSize:12.5, color:t.unread?ink:muted, marginTop:3, lineHeight:1.4, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis', fontStyle:t.system?'italic':'normal' }}>
          {t.preview.map(([txt,b],i)=> b ? <b key={i} style={{ color:ink2 }}>{txt}</b> : <span key={i}>{txt}</span>)}
        </div>
      </div>
      {t.unread>0 && <span style={{ minWidth:18, height:18, padding:'0 5px', borderRadius:999, background:red, color:paper, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:10, alignSelf:'center', flexShrink:0 }}>{t.unread}</span>}
    </button>
  );
}

function MsgBubble({ me, name, body, time, mono, color }) {
  if (me) return (
    <div style={{ display:'flex', justifyContent:'flex-end', marginTop:2 }}>
      <div style={{ maxWidth:'76%' }}>
        <div style={{ background:ink, color:paper, padding:'9px 13px', borderRadius:'16px 16px 4px 16px', fontSize:13.5, lineHeight:1.4 }}>{body}</div>
        <div style={{ fontFamily:'JetBrains Mono', fontSize:8.5, color:soft, marginTop:3, textAlign:'right' }}>{time.toUpperCase()}</div>
      </div>
    </div>
  );
  return (
    <div style={{ display:'flex', gap:8, marginTop:2 }}>
      <Crest m={mono} color={color} size={28} round />
      <div style={{ maxWidth:'76%' }}>
        <div style={{ fontFamily:'JetBrains Mono', fontSize:9, color:muted, marginBottom:3, marginLeft:2 }}>{name}</div>
        <div style={{ background:surface, border:'1px solid '+hair, color:ink, padding:'9px 13px', borderRadius:'16px 16px 16px 4px', fontSize:13.5, lineHeight:1.4 }}>{body}</div>
        <div style={{ fontFamily:'JetBrains Mono', fontSize:8.5, color:soft, marginTop:3, marginLeft:2 }}>{time.toUpperCase()}</div>
      </div>
    </div>
  );
}
function Divider({ children }) {
  return <div style={{ display:'flex', alignItems:'center', gap:10, margin:'6px 0' }}>
    <div style={{ flex:1, height:1, background:hair }} /><span style={{ ...mono, fontSize:8.5, color:muted }}>{children}</span><div style={{ flex:1, height:1, background:hair }} />
  </div>;
}
function SystemLine({ children }) {
  return <div style={{ textAlign:'center', fontSize:11, color:muted, fontStyle:'italic', padding:'4px 20px' }}>{children}</div>;
}

function Thread({ t, onBack }) {
  return (
    <div style={{ position:'absolute', inset:0, zIndex:92, background:paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      <div style={{ padding:'4px 12px 12px', flexShrink:0, display:'flex', alignItems:'center', gap:10, borderBottom:'1px solid '+hair }}>
        <button onClick={onBack} style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:ink }}><Ic n="back" s={20} sw={2} /></button>
        <Crest m={t.m} color={t.color} size={32} round={!t.team} />
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:15, letterSpacing:'-0.01em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{t.name}</div>
          <div style={{ fontSize:11, color:muted, marginTop:1 }}>{t.team?'14 members · 4 online':'Active now'}</div>
        </div>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0, padding:'14px 14px', display:'flex', flexDirection:'column', gap:8 }}>
        <Divider>Today</Divider>
        <MsgBubble mono="IS" name="Imran Saeed" color="#3a8f8f" body="XI confirmed for tomorrow. Faraz at 3, Bilal opens with me." time="9:14 am" />
        <MsgBubble mono="IS" name="Imran Saeed" color="#3a8f8f" body="Toss at 3:45. Be at the ground by 3:30." time="9:14 am" />
        <SystemLine>Imran added a match · <b style={{color:ink2}}>Lions vs Cobras · Sat 25 · 4 PM</b></SystemLine>
        <MsgBubble mono="FK" name="Faraz Khan" color="#2F7D54" body="On it. Bringing two extra balls." time="9:31 am" />
        <MsgBubble me body="Booking the practice net for Wed 7 PM" time="11:22 am" />
        <Divider>Now</Divider>
        <MsgBubble mono="IS" name="Imran Saeed" color="#3a8f8f" body="Anyone got spare pads for Adeel? His are torn." time="just now" />
      </div>
      <div style={{ flexShrink:0, borderTop:'1px solid '+hair, padding:'10px 12px calc(12px + env(safe-area-inset-bottom))', display:'flex', alignItems:'center', gap:9, background:paper }}>
        <button style={{ width:34, height:34, borderRadius:999, border:'1px solid '+hair, background:paper, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, color:ink }}><Ic n="plus" s={18} sw={2} /></button>
        <div style={{ flex:1, height:38, borderRadius:999, background:paper2, border:'1px solid '+hair, display:'flex', alignItems:'center', padding:'0 14px', fontSize:13.5, color:muted }}>Message…</div>
        <button style={{ width:38, height:38, borderRadius:999, border:'none', background:ink, color:paper, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}><Ic n="send" s={17} sw={2} stroke={paper} /></button>
      </div>
    </div>
  );
}

function MessagesScreen({ onBack }) {
  const [scope, setScope] = useState('all');
  const [open, setOpen] = useState(null);
  const list = scope==='all' ? THREADS : THREADS.filter(t=>t.scope===scope);
  const tabs = [['all','All',THREADS.length],['teams','Teams',THREADS.filter(t=>t.scope==='teams').length],['dms','DMs',THREADS.filter(t=>t.scope==='dms').length]];
  if (open) return <Thread t={open} onBack={()=>setOpen(null)} />;
  return (
    <div style={{ position:'absolute', inset:0, zIndex:88, background:paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      <div style={{ padding:'4px 12px 12px', flexShrink:0, display:'flex', alignItems:'center', gap:8, borderBottom:'1px solid '+hair }}>
        <button onClick={onBack} style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:ink }}><Ic n="back" s={20} sw={2} /></button>
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:18, letterSpacing:'-0.02em' }}>Messages</div>
      </div>
      <div style={{ display:'flex', gap:6, padding:'12px 18px 10px', flexShrink:0 }}>
        {tabs.map(([id,label,n])=>{
          const on = scope===id;
          return <button key={id} onClick={()=>setScope(id)} style={{ display:'inline-flex', alignItems:'center', gap:6, height:34, padding:'0 13px', borderRadius:999, cursor:'pointer', fontFamily:'inherit', fontSize:12.5, fontWeight:600, border:'1px solid '+(on?ink:hair), background:on?ink:paper, color:on?paper:ink2 }}>{label}<span style={{ fontFamily:'JetBrains Mono', fontSize:10, opacity:0.7 }}>{n}</span></button>;
        })}
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {list.map(t=><ThreadRow key={t.id} t={t} onOpen={setOpen} />)}
        <div style={{ height:24 }} />
      </div>
    </div>
  );
}

window.HomeFeed = HomeFeed;
window.MessagesScreen = MessagesScreen;

// ─────────────────────────────────────────────────────────
// TEAM SCREEN (opened from a team-authored post)
// ─────────────────────────────────────────────────────────
const TEAM_DETAIL = {
  LL: { name:'Lahore Lions', color:'#DC4D32', city:'Lahore · Model Town', founded:'2019', record:'W 14 · L 6', form:['W','W','L','W','W'],
    squad:[['Bilal Ahmed','AR','C'],['Adeel Sheikh','WK',''],['Faraz Khan','AR',''],['Usman Riaz','BOW',''],['Imran Akhtar','BOW',''],['Hamza Tariq','BAT',''],['Junaid Ali','AR',''],['Saad Anwar','BAT','']] },
  MK: { name:'Mohalla Kings', color:'#C98A2B', city:'Lahore · DHA', founded:'2021', record:'W 8 · L 9', form:['L','W','L','L','W'],
    squad:[['Bilal Pasha','BAT','C'],['Rauf Cheema','BOW',''],['Wajid Ali','AR',''],['Tariq Bhatti','BAT',''],['Aamir Shah','WK','']] },
};
function teamFromPost(p){
  return TEAM_DETAIL[p.mono] || { name:p.author, color:p.color, city:'Lahore', founded:'—', record:'—', form:[], squad:[] };
}
const ROLE_TONE = { BAT:[paper2,ink2], BOW:[cream,'#7a5a1e'], AR:[greenSoft,greenInk], WK:[red,'#fff'] };

function TeamScreen({ post, onBack }) {
  const t = teamFromPost(post);
  const [tab, setTab] = useState('Squad');
  const [following, setFollowing] = useState(false);
  return (
    <div style={{ position:'absolute', inset:0, zIndex:95, background:paper, display:'flex', flexDirection:'column' }}>
      <div style={{ height:44, flexShrink:0 }} />
      <div style={{ padding:'4px 12px 12px', flexShrink:0, display:'flex', alignItems:'center', gap:8, borderBottom:'1px solid '+hair }}>
        <button onClick={onBack} style={{ width:32, height:32, border:'none', background:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', padding:0, marginLeft:-4, color:ink }}><Ic n="back" s={20} sw={2} /></button>
        <div style={{ fontFamily:'Inter Tight', fontWeight:700, fontSize:18, letterSpacing:'-0.02em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{t.name}</div>
      </div>
      <div style={{ flex:1, overflowY:'auto', minHeight:0 }}>
        {/* hero */}
        <div style={{ padding:'18px 18px 14px', display:'flex', gap:14, alignItems:'center' }}>
          <div style={{ width:64, height:64, borderRadius:16, background:t.color, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:800, fontSize:24, letterSpacing:'-0.03em', flexShrink:0 }}>{post.mono}</div>
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontFamily:'Inter Tight', fontWeight:800, fontSize:20, letterSpacing:'-0.02em' }}>{t.name}</div>
            <div style={{ fontSize:12.5, color:muted, marginTop:3 }}>{t.city}</div>
            <div style={{ fontFamily:'JetBrains Mono', fontSize:10, color:ink2, marginTop:5, letterSpacing:'0.04em' }}>{t.record} · EST {t.founded}</div>
          </div>
        </div>
        {/* form + follow */}
        <div style={{ padding:'0 18px 14px', display:'flex', alignItems:'center', gap:10 }}>
          <div style={{ display:'flex', gap:4 }}>
            {t.form.map((f,i)=><span key={i} style={{ width:22, height:22, borderRadius:6, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'JetBrains Mono', fontSize:10, fontWeight:700, background:f==='W'?greenSoft:paper2, color:f==='W'?greenInk:muted }}>{f}</span>)}
          </div>
          <button onClick={()=>setFollowing(v=>!v)} style={{ marginLeft:'auto', height:36, padding:'0 18px', borderRadius:999, border:'1px solid '+(following?hair:ink), background:following?paper:ink, color:following?ink2:paper, fontFamily:'inherit', fontSize:13, fontWeight:700, cursor:'pointer' }}>{following?'Following':'Follow'}</button>
          <button style={{ width:36, height:36, borderRadius:999, border:'1px solid '+hair, background:paper, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', color:ink }}><Ic n="msg" s={17} /></button>
        </div>
        {/* tabs */}
        <div style={{ display:'flex', gap:0, padding:'0 18px', borderBottom:'1px solid '+hair }}>
          {['Squad','Matches','About'].map(tb=>{
            const on=tab===tb;
            return <button key={tb} onClick={()=>setTab(tb)} style={{ flex:1, padding:'10px 0 11px', background:'none', border:'none', borderBottom:'2px solid '+(on?ink:'transparent'), marginBottom:-1, cursor:'pointer', fontFamily:'inherit', fontSize:13, fontWeight:on?700:600, color:on?ink:muted }}>{tb}</button>;
          })}
        </div>

        {tab==='Squad' && (t.squad.length ? t.squad.map(([nm,role,cap],i)=>(
          <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 18px', borderTop:i?'1px solid '+hair:'none' }}>
            <div style={{ width:34, height:34, borderRadius:999, background:paper2, color:ink2, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Inter Tight', fontWeight:700, fontSize:13, flexShrink:0 }}>{nm.split(' ').map(w=>w[0]).join('').slice(0,2)}</div>
            <span style={{ flex:1, fontFamily:'Inter Tight', fontWeight:600, fontSize:14 }}>{nm}{cap && <span style={{ ...mono, fontSize:8, padding:'1px 4px', borderRadius:3, background:ink, color:paper, marginLeft:6 }}>C</span>}</span>
            <span style={{ ...mono, fontSize:8.5, padding:'2px 6px', borderRadius:4, background:(ROLE_TONE[role]||ROLE_TONE.BAT)[0], color:(ROLE_TONE[role]||ROLE_TONE.BAT)[1] }}>{role}</span>
          </div>
        )) : <div style={{ padding:'40px 24px', textAlign:'center', color:muted, fontSize:13 }}>Squad not public.</div>)}

        {tab==='Matches' && (
          <div style={{ padding:'16px 18px', color:muted, fontSize:13, lineHeight:1.6 }}>Recent &amp; upcoming fixtures for {t.name} appear here.</div>
        )}
        {tab==='About' && (
          <div style={{ padding:'16px 18px', fontSize:13.5, color:ink2, lineHeight:1.6 }}>
            {t.name} · {t.city}. Founded {t.founded}. Season record {t.record}. Friendly challenges welcome.
          </div>
        )}
        <div style={{ height:24 }} />
      </div>
    </div>
  );
}

window.TeamScreen = TeamScreen;
})();

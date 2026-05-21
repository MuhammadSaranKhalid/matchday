// Composer.jsx — live, working post-creation flow.
// Reachable from any screen via window.openCkComposer({author}).
// Renders a full-screen sheet over the current device frame.
//
// Usage:
//   window.openCkComposer({ author: { kind:'personal', name:'Bilal Ahmed', initials:'BA', color:'var(--ink)' } });
//   window.openCkComposer({ author: { kind:'team',     name:'Lahore Lions', initials:'LL', color:'var(--red)' } });
//   window.openCkComposer({ author: { kind:'tournament', name:"Spring Cup '26", initials:'SC', color:'oklch(0.45 0.12 280)' } });
//
// The host page renders <CkComposerHost/> once near the root and a portal effect
// pipes the open() call into local React state.

const COMPOSER_TYPES = [
  { id: 'text',    ttl: 'Text',                  sub: 'Quick thought, recap, opinion',     glyph: 'Aa', tone: 'oklch(0.45 0.05 240)', who: ['personal','team','tournament'] },
  { id: 'photo',   ttl: 'Photo / Album',         sub: 'Up to 10 · highlight any moment',   glyph: '◰',  tone: 'oklch(0.55 0.12 200)', who: ['personal','team','tournament'] },
  { id: 'match',   ttl: 'Match announcement',    sub: 'Link a fixture · ask for an XI',    glyph: 'V',  tone: 'var(--red)',           who: ['team','tournament'] },
  { id: 'recruit', ttl: 'Recruitment',           sub: 'Open trial · role · deadline',      glyph: '★',  tone: 'oklch(0.55 0.13 80)',  who: ['team'] },
  { id: 'tour',    ttl: 'Tournament update',     sub: 'Fixtures · rules · standings',      glyph: '◇',  tone: 'oklch(0.45 0.12 280)', who: ['tournament'] },
];

const DEFAULT_AUTHORS = {
  personal:   { kind: 'personal',   name: 'Bilal Ahmed',     initials: 'BA', color: 'var(--ink)' },
  team:       { kind: 'team',       name: 'Lahore Lions',    initials: 'LL', color: 'var(--red)' },
  tournament: { kind: 'tournament', name: "Spring Cup '26",  initials: 'SC', color: 'oklch(0.45 0.12 280)' },
};

// =========================================================================
// HOST — drop one of these onto every screen that wants composer support
// =========================================================================

function CkComposerHost() {
  const [open, setOpen] = React.useState(null); // null | { author }
  const [toast, setToast] = React.useState(null); // 'Posted.' etc

  React.useEffect(() => {
    window.openCkComposer = (opts = {}) => {
      const author = opts.author || DEFAULT_AUTHORS.personal;
      setOpen({ author });
    };
    return () => { delete window.openCkComposer; };
  }, []);

  const handlePosted = (kindLabel) => {
    setOpen(null);
    setToast(kindLabel + ' posted.');
    setTimeout(() => setToast(null), 1900);
  };

  return (
    <>
      {open && <CkComposer author={open.author} onClose={() => setOpen(null)} onPosted={handlePosted} />}
      {toast && (
        <div style={{
          position: 'absolute', bottom: 80, left: 16, right: 16, zIndex: 60,
          padding: '12px 16px', borderRadius: 12, background: 'var(--ink)', color: 'var(--paper)',
          display: 'flex', alignItems: 'center', gap: 10, boxShadow: '0 12px 28px rgba(40,30,15,0.18)',
          animation: 'ckToast .25s ease-out',
        }}>
          <div style={{ width: 20, height: 20, borderRadius: 999, border: '1.5px solid var(--paper)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5L20 7"/></svg>
          </div>
          <span style={{ fontSize: 13, fontWeight: 600 }}>{toast}</span>
        </div>
      )}
      <style>{`@keyframes ckToast{from{transform:translateY(8px);opacity:0}to{transform:translateY(0);opacity:1}}`}</style>
    </>
  );
}

// =========================================================================
// COMPOSER — full-screen sheet, internal step machine
// =========================================================================

function CkComposer({ author, onClose, onPosted }) {
  // step: 'pick' | 'text' | 'photo' | 'match' | 'recruit' | 'tour' | 'preview'
  const [step, setStep] = React.useState('pick');
  const [type, setType] = React.useState(null);
  const [draft, setDraft] = React.useState({
    text: '',
    photos: 3,
    visibility: author.kind === 'team' ? 'Followers' : 'Public',
    matchId: 'spring-qf',
    recruitRole: 'Right-arm fast bowler',
    recruitBody: 'One quick needed for the Sunday League. Ages 18–28. Tape ball, evening matches at Gulberg.',
    recruitLocation: 'Lahore · Gulberg',
    recruitDeadline: 'Apply by Wed',
    recruitSpots: 1,
    tourTag: 'Schedule',
    tourHeadline: 'Round 2 fixtures announced',
    tourBody: '4 quarterfinals across this weekend. Brackets locked.',
    rsvp: true,
    needPlayer: false,
  });

  const update = (patch) => setDraft(d => ({ ...d, ...patch }));

  const goCompose = (t) => { setType(t); setStep(t.id); };
  const back = () => {
    if (step === 'preview') return setStep(type.id);
    if (step !== 'pick') return setStep('pick');
    onClose();
  };

  // Validate the right action label for the top-right corner
  const cornerLabel = step === 'pick' ? 'Cancel'
                    : step === 'preview' ? null
                    : 'Cancel';
  const nextLabel = step === 'pick' ? null
                  : step === 'preview' ? 'Publish'
                  : 'Next';
  const nextEnabled = step === 'text' ? draft.text.trim().length > 0
                    : step === 'photo' ? draft.photos > 0
                    : step === 'match' ? !!draft.matchId
                    : step === 'recruit' ? draft.recruitRole.trim().length > 0
                    : step === 'tour' ? draft.tourHeadline.trim().length > 0
                    : step === 'preview' ? true
                    : true;

  const onNext = () => {
    if (step === 'preview') {
      onPosted(type ? type.ttl : 'Post');
      return;
    }
    setStep('preview');
  };

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 50,
      background: 'var(--paper)',
      display: 'flex', flexDirection: 'column',
      animation: 'ckSheetUp .26s cubic-bezier(.2,.8,.2,1)',
      overflow: 'hidden',
    }}>
      {/* status bar spacer */}
      <div style={{ height: 44, flexShrink: 0 }} />

      {/* nav row */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 18px 12px', flexShrink: 0 }}>
        <button onClick={back} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: 14, color: 'var(--muted)', padding: 0 }}>
          {step === 'pick' ? 'Cancel' : '← Back'}
        </button>
        <div style={{ fontWeight: 700, fontSize: 15 }}>
          {step === 'pick'    ? 'New post'
          : step === 'preview' ? 'Preview'
          : type ? `New ${type.ttl.toLowerCase()}` : 'New post'}
        </div>
        <button onClick={onNext} disabled={!nextLabel || !nextEnabled} style={{
          background: 'transparent', border: 'none', cursor: nextLabel && nextEnabled ? 'pointer' : 'default',
          fontFamily: 'inherit', fontSize: 14, padding: 0,
          color: !nextLabel ? 'transparent'
              : !nextEnabled ? 'var(--muted)'
              : step === 'preview' ? 'var(--red)' : 'var(--ink)',
          fontWeight: 700,
          opacity: !nextLabel ? 0 : 1,
        }}>{nextLabel || '_'}</button>
      </div>

      {/* author chip — always visible (shows you who's posting) */}
      {step !== 'preview' && (
        <div style={{ margin: '0 18px 12px', padding: 10, borderRadius: 10, border: '1px solid var(--hairline)', background: 'var(--paper-2)', display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
          <div style={{
            width: 28, height: 28, borderRadius: author.kind === 'personal' ? 999 : 6,
            background: author.color, color: 'white',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11,
          }}>{author.initials}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>POSTING AS</div>
            <div style={{ fontSize: 13, fontWeight: 700, marginTop: 1 }}>{author.name}</div>
          </div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--red)', fontWeight: 700, letterSpacing: '0.08em' }}>LOCKED</div>
        </div>
      )}

      {/* content */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {step === 'pick'    && <PickerStep author={author} onPick={goCompose} />}
        {step === 'text'    && <TextStep draft={draft} update={update} />}
        {step === 'photo'   && <PhotoStep draft={draft} update={update} />}
        {step === 'match'   && <MatchStep draft={draft} update={update} />}
        {step === 'recruit' && <RecruitStep draft={draft} update={update} />}
        {step === 'tour'    && <TourStep draft={draft} update={update} />}
        {step === 'preview' && <PreviewStep author={author} type={type} draft={draft} update={update} />}
      </div>

      <style>{`@keyframes ckSheetUp{from{transform:translateY(100%)}to{transform:translateY(0)}}`}</style>
    </div>
  );
}

// =========================================================================
// STEP 1 — type picker
// =========================================================================
function PickerStep({ author, onPick }) {
  const items = COMPOSER_TYPES.map(t => ({ ...t, locked: !t.who.includes(author.kind) }));
  return (
    <>
      <div style={{ padding: '0 18px', fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: 700, color: 'var(--ink)', letterSpacing: '0.12em', marginBottom: 8 }}>WHAT ARE YOU POSTING?</div>
      <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map(it => (
          <button key={it.id} onClick={() => !it.locked && onPick(it)} disabled={it.locked}
            style={{
              padding: 14, borderRadius: 12,
              border: '1px solid var(--hairline)',
              background: 'var(--paper)',
              display: 'flex', alignItems: 'center', gap: 12,
              opacity: it.locked ? 0.4 : 1,
              cursor: it.locked ? 'not-allowed' : 'pointer',
              fontFamily: 'inherit', textAlign: 'left',
            }}>
            <div style={{ width: 38, height: 38, borderRadius: 8, background: it.tone, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 15, flexShrink: 0 }}>{it.glyph}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>{it.ttl}</div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{it.sub}</div>
            </div>
            {it.locked
              ? <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--muted)', letterSpacing: '0.08em' }}>NOT FOR YOU</div>
              : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ color: 'var(--muted)' }}><path d="m9 6 6 6-6 6"/></svg>}
          </button>
        ))}
      </div>
      <div style={{ margin: '14px 18px 0', padding: 10, borderRadius: 8, background: 'oklch(0.94 0.05 90)', border: '1px solid oklch(0.86 0.05 90)', fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.4 }}>
        <strong>Heads up:</strong> Milestones · results · awards are auto-posted by the scoring engine. They appear on profiles without you doing anything.
      </div>
    </>
  );
}

// =========================================================================
// STEP 2 — per-type
// =========================================================================
function TextStep({ draft, update }) {
  return (
    <div style={{ padding: '0 18px' }}>
      <textarea autoFocus value={draft.text} onChange={e => update({ text: e.target.value })}
        placeholder="Share something with your followers…"
        style={{
          width: '100%', minHeight: 200, border: 'none', outline: 'none', resize: 'none',
          fontFamily: 'inherit', fontSize: 16, lineHeight: 1.5, color: 'var(--ink)', background: 'transparent',
          padding: 0,
        }}/>
      <div style={{ marginTop: 12, paddingTop: 10, borderTop: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 16, color: 'var(--muted)' }}>
        <span style={{ fontSize: 14 }}>@</span>
        <span style={{ fontSize: 14 }}>#</span>
        <span style={{ fontSize: 12 }}>🔗 Link</span>
        <div style={{ flex: 1 }}/>
        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: draft.text.length > 1800 ? 'var(--red)' : 'var(--muted)' }}>{draft.text.length}/2000</span>
      </div>
    </div>
  );
}

function PhotoStep({ draft, update }) {
  const photos = draft.photos;
  return (
    <div style={{ padding: '0 18px' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6 }}>
        {Array.from({ length: photos }, (_, i) => (
          <div key={i} style={{
            aspectRatio: '1',
            background: i === 0 ? 'var(--red)' : i === 1 ? 'oklch(0.42 0.10 260)' : 'oklch(0.55 0.12 200)',
            borderRadius: 8, position: 'relative', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            color: 'white', fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: '0.1em',
          }}>
            IMG {i+1}
            {i === 0 && <span style={{ position: 'absolute', top: 4, left: 4, padding: '2px 5px', borderRadius: 4, background: 'rgba(0,0,0,0.5)', fontSize: 8, fontWeight: 700 }}>COVER</span>}
          </div>
        ))}
        {photos < 10 && (
          <button onClick={() => update({ photos: photos + 1 })} style={{
            aspectRatio: '1', borderRadius: 8, border: '1.5px dashed var(--hairline)',
            background: 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'var(--muted)', fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 600, cursor: 'pointer',
          }}>+</button>
        )}
      </div>

      <textarea value={draft.text} onChange={e => update({ text: e.target.value })}
        placeholder="Add a caption…"
        style={{
          marginTop: 14, width: '100%', minHeight: 60, border: 'none', outline: 'none', resize: 'none',
          fontFamily: 'inherit', fontSize: 14, lineHeight: 1.45, color: 'var(--ink)', background: 'transparent',
          padding: 0,
        }}/>

      <div style={{ marginTop: 12 }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>LINKED MATCH (OPTIONAL)</div>
        <div style={{ marginTop: 6, padding: 10, borderRadius: 8, background: 'var(--paper-2)', border: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 22, height: 22, borderRadius: 4, background: 'var(--red)', color: 'white', fontFamily: 'Inter Tight', fontSize: 9, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>LL</div>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>vs</span>
          <div style={{ width: 22, height: 22, borderRadius: 4, background: 'oklch(0.42 0.10 260)', color: 'white', fontFamily: 'Inter Tight', fontSize: 9, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>CTY</div>
          <div style={{ flex: 1, fontSize: 12, fontWeight: 600 }}>Spring Cup QF</div>
          <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--red)', fontWeight: 700 }}>107* (62)</div>
        </div>
      </div>

      <div style={{ marginTop: 14, paddingTop: 10, borderTop: '1px solid var(--hairline)', display: 'flex', alignItems: 'center', gap: 16, color: 'var(--muted)', fontSize: 12 }}>
        <span>@ Tag</span><span>🏏 Match</span><span style={{ flex: 1 }}/><span style={{ fontFamily: 'JetBrains Mono', fontSize: 11 }}>{photos}/10</span>
      </div>
    </div>
  );
}

function MatchStep({ draft, update }) {
  return (
    <div style={{ padding: '0 18px' }}>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>MATCH</div>
      <div style={{ marginTop: 6, padding: 12, borderRadius: 10, border: '1.5px solid var(--ink)', background: 'var(--paper)' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 10, alignItems: 'center' }}>
          {[['LL','Lahore Lions','var(--red)'], null, ['CTY','City Eagles','oklch(0.42 0.10 260)']].map((t, i) => t === null
            ? <div key={i} style={{ fontFamily: 'Inter Tight', fontWeight: 700, color: 'var(--muted)', fontSize: 14, textAlign: 'center' }}>vs</div>
            : (
              <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <div style={{ width: 32, height: 32, borderRadius: 6, background: t[2], color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11 }}>{t[0]}</div>
                <div style={{ fontSize: 11, fontWeight: 600 }}>{t[1]}</div>
              </div>
            ))}
        </div>
        <div style={{ marginTop: 10, paddingTop: 8, borderTop: '1px dashed var(--hairline)', display: 'flex', justifyContent: 'space-between', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)' }}>
          <span>Fri 14 Mar · 6:00 PM</span><span>Model Town</span>
        </div>
      </div>

      <div style={{ marginTop: 12, fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em' }}>MESSAGE</div>
      <textarea value={draft.text} onChange={e => update({ text: e.target.value })}
        placeholder="Friday 6 PM — playoff vs City Eagles. We need a 12th. DM if available."
        style={{ marginTop: 6, width: '100%', minHeight: 70, padding: 10, borderRadius: 8, border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 13, lineHeight: 1.45, resize: 'none', outline: 'none' }}/>

      <ToggleRow title="Allow RSVP" sub="Going / Maybe / Can't" on={draft.rsvp} onChange={v => update({ rsvp: v })} />
      <ToggleRow title="Need a player?" sub='Surfaces a "Last spot" badge' on={draft.needPlayer} onChange={v => update({ needPlayer: v })} />
    </div>
  );
}

function ToggleRow({ title, sub, on, onChange }) {
  return (
    <button onClick={() => onChange(!on)} style={{
      width: '100%', marginTop: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '10px 12px', borderRadius: 8, border: '1px solid var(--hairline)', background: 'var(--paper)',
      fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left',
    }}>
      <div>
        <div style={{ fontSize: 12, fontWeight: 700 }}>{title}</div>
        {sub && <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 2 }}>{sub}</div>}
      </div>
      <div style={{ width: 32, height: 18, borderRadius: 999, background: on ? 'var(--ink)' : 'var(--paper-2)', border: on ? 'none' : '1px solid var(--hairline)', position: 'relative', flexShrink: 0, transition: 'background .15s' }}>
        <div style={{ position: 'absolute', top: on ? 2 : 1, left: on ? 'auto' : 1, right: on ? 2 : 'auto', width: 14, height: 14, borderRadius: 999, background: 'white', border: on ? 'none' : '1px solid var(--hairline)', transition: 'all .15s' }}/>
      </div>
    </button>
  );
}

function RecruitStep({ draft, update }) {
  return (
    <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 12 }}>
      <Field label="ROLE NEEDED">
        <input value={draft.recruitRole} onChange={e => update({ recruitRole: e.target.value })}
          style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1.5px solid var(--ink)', fontSize: 14, fontFamily: 'Inter Tight', fontWeight: 700, outline: 'none', background: 'var(--paper)' }}/>
      </Field>
      <Field label="DETAILS">
        <textarea value={draft.recruitBody} onChange={e => update({ recruitBody: e.target.value })}
          style={{ width: '100%', minHeight: 70, padding: 10, borderRadius: 8, border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 13, lineHeight: 1.45, resize: 'none', outline: 'none' }}/>
      </Field>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <Field label="LOCATION">
          <input value={draft.recruitLocation} onChange={e => update({ recruitLocation: e.target.value })}
            style={{ width: '100%', padding: '8px 10px', borderRadius: 8, border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 12, outline: 'none' }}/>
        </Field>
        <Field label="DEADLINE">
          <input value={draft.recruitDeadline} onChange={e => update({ recruitDeadline: e.target.value })}
            style={{ width: '100%', padding: '8px 10px', borderRadius: 8, border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 12, outline: 'none' }}/>
        </Field>
      </div>
      <Field label="SPOTS">
        <div style={{ display: 'flex', gap: 6 }}>
          {[1, 2, 3, '5+'].map(n => {
            const active = draft.recruitSpots === (n === '5+' ? 5 : n);
            return (
              <button key={n} onClick={() => update({ recruitSpots: n === '5+' ? 5 : n })} style={{
                flex: 1, padding: '8px 0', textAlign: 'center', borderRadius: 8,
                border: '1px solid ' + (active ? 'var(--ink)' : 'var(--hairline)'),
                background: active ? 'var(--ink)' : 'var(--paper)',
                color: active ? 'var(--paper)' : 'var(--ink)',
                fontWeight: 700, fontSize: 13, fontFamily: 'Inter Tight', cursor: 'pointer',
              }}>{n}</button>
            );
          })}
        </div>
      </Field>
    </div>
  );
}

function TourStep({ draft, update }) {
  const tags = ['Schedule', 'Rule', 'Result', 'Bracket', 'General'];
  return (
    <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div style={{ display: 'flex', gap: 6, overflowX: 'auto', padding: '2px 0' }}>
        {tags.map(t => {
          const active = draft.tourTag === t;
          return (
            <button key={t} onClick={() => update({ tourTag: t })} style={{
              flex: 'none', padding: '6px 12px', borderRadius: 999,
              background: active ? 'var(--ink)' : 'transparent',
              color: active ? 'var(--paper)' : 'var(--ink-2)',
              border: '1px solid ' + (active ? 'var(--ink)' : 'var(--hairline)'),
              fontSize: 11, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
            }}>{t}</button>
          );
        })}
      </div>
      <Field label="HEADLINE">
        <input value={draft.tourHeadline} onChange={e => update({ tourHeadline: e.target.value })}
          style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1.5px solid var(--ink)', fontFamily: 'Inter Tight', fontSize: 16, fontWeight: 700, letterSpacing: '-0.015em', outline: 'none' }}/>
      </Field>
      <Field label="BODY">
        <textarea value={draft.tourBody} onChange={e => update({ tourBody: e.target.value })}
          style={{ width: '100%', minHeight: 70, padding: 10, borderRadius: 8, border: '1px solid var(--hairline)', fontFamily: 'inherit', fontSize: 13, lineHeight: 1.45, resize: 'none', outline: 'none' }}/>
      </Field>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em', marginBottom: 4 }}>{label}</div>
      {children}
    </div>
  );
}

// =========================================================================
// STEP 3 — preview (renders the post as it'll appear)
// =========================================================================
function PreviewStep({ author, type, draft, update }) {
  return (
    <div>
      {/* author chip + visibility selector at the top */}
      <div style={{ padding: '0 18px 12px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 28, height: 28, borderRadius: author.kind === 'personal' ? 999 : 6,
          background: author.color, color: 'white',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 11,
        }}>{author.initials}</div>
        <div style={{ fontSize: 13, fontWeight: 700 }}>{author.name}</div>
        <div style={{ flex: 1 }}/>
        <VisibilityPicker value={draft.visibility} onChange={v => update({ visibility: v })} authorKind={author.kind}/>
      </div>

      {/* the rendered post card */}
      <div style={{ margin: '0 18px', borderRadius: 12, border: '1px solid var(--hairline)', overflow: 'hidden', background: 'var(--paper)' }}>
        <div style={{ padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 22, height: 22, borderRadius: author.kind === 'personal' ? 999 : 5, background: author.color, color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 9 }}>{author.initials}</div>
          <span style={{ fontSize: 12, fontWeight: 600 }}>{author.name}</span>
          <span style={{ flex: 1 }}/>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>now</span>
        </div>

        <PostBody type={type} draft={draft} />

        <div style={{ padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 14, borderTop: '1px solid var(--hairline)' }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>♡ 0</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>💬 0</span>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>↗</span>
        </div>
      </div>

      <div style={{ margin: '14px 18px 24px', padding: 12, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em', minWidth: 70 }}>VISIBILITY</span>
          <span style={{ fontWeight: 700 }}>{draft.visibility}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, marginTop: 6 }}>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--muted)', letterSpacing: '0.1em', minWidth: 70 }}>POST AT</span>
          <span style={{ fontWeight: 700 }}>Now</span>
        </div>
      </div>
    </div>
  );
}

function VisibilityPicker({ value, onChange, authorKind }) {
  const opts = authorKind === 'team' ? ['Public','Followers','Members'] : ['Public','Followers'];
  const [open, setOpen] = React.useState(false);
  return (
    <div style={{ position: 'relative' }}>
      <button onClick={() => setOpen(o => !o)} style={{
        background: 'transparent', border: '1px solid var(--hairline)', borderRadius: 999,
        padding: '4px 10px', fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700,
        color: 'var(--ink)', letterSpacing: '0.08em', cursor: 'pointer',
      }}>{value.toUpperCase()} ▾</button>
      {open && (
        <div style={{
          position: 'absolute', right: 0, top: 'calc(100% + 4px)', zIndex: 10,
          background: 'var(--paper)', border: '1px solid var(--hairline)', borderRadius: 8,
          boxShadow: '0 8px 22px rgba(40,30,15,0.12)', overflow: 'hidden', minWidth: 130,
        }}>
          {opts.map(o => (
            <button key={o} onClick={() => { onChange(o); setOpen(false); }} style={{
              display: 'block', width: '100%', padding: '8px 12px', textAlign: 'left',
              background: value === o ? 'var(--paper-2)' : 'transparent',
              border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: 12,
              color: 'var(--ink)', fontWeight: value === o ? 700 : 500,
            }}>{o}</button>
          ))}
        </div>
      )}
    </div>
  );
}

function PostBody({ type, draft }) {
  if (!type) return null;

  if (type.id === 'text') {
    return (
      <div style={{ padding: '0 14px 12px', fontSize: 13, lineHeight: 1.5, whiteSpace: 'pre-wrap' }}>
        {draft.text || <span style={{ color: 'var(--muted)' }}>(no text)</span>}
      </div>
    );
  }

  if (type.id === 'photo') {
    return (
      <>
        {draft.text && <div style={{ padding: '0 14px 10px', fontSize: 13, lineHeight: 1.45 }}>{draft.text}</div>}
        <div style={{ display: 'grid', gridTemplateColumns: draft.photos === 1 ? '1fr' : 'repeat(' + Math.min(draft.photos, 3) + ', 1fr)', gap: 2 }}>
          {Array.from({ length: Math.min(draft.photos, 6) }, (_, i) => (
            <div key={i} style={{
              aspectRatio: '1',
              background: i === 0 ? 'var(--red)' : i === 1 ? 'oklch(0.42 0.10 260)' : 'oklch(0.55 0.12 200)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white',
              fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: '0.1em',
            }}>IMG {i+1}</div>
          ))}
        </div>
      </>
    );
  }

  if (type.id === 'match') {
    return (
      <div style={{ padding: '0 14px 14px' }}>
        {draft.text && <div style={{ fontSize: 13, lineHeight: 1.45, marginBottom: 10 }}>{draft.text}</div>}
        <div style={{ padding: 12, borderRadius: 10, background: 'var(--paper-2)', border: '1px solid var(--hairline)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 10, alignItems: 'center' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <div style={{ width: 28, height: 28, borderRadius: 6, background: 'var(--red)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 10 }}>LL</div>
              <div style={{ fontSize: 10, fontWeight: 600 }}>Lahore Lions</div>
            </div>
            <div style={{ fontFamily: 'Inter Tight', fontWeight: 700, color: 'var(--muted)', fontSize: 12 }}>vs</div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <div style={{ width: 28, height: 28, borderRadius: 6, background: 'oklch(0.42 0.10 260)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter Tight', fontWeight: 700, fontSize: 10 }}>CTY</div>
              <div style={{ fontSize: 10, fontWeight: 600 }}>City Eagles</div>
            </div>
          </div>
          <div style={{ marginTop: 10, paddingTop: 8, borderTop: '1px dashed var(--hairline)', display: 'flex', justifyContent: 'space-between', fontFamily: 'JetBrains Mono', fontSize: 9, color: 'var(--ink-2)' }}>
            <span>Fri 14 Mar · 6:00 PM</span><span>Model Town</span>
          </div>
          {draft.rsvp && (
            <div style={{ marginTop: 10, display: 'flex', gap: 4 }}>
              <Pill>Going</Pill><Pill>Maybe</Pill><Pill>Can't</Pill>
            </div>
          )}
          {draft.needPlayer && (
            <div style={{ marginTop: 8, fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'var(--red)', letterSpacing: '0.08em' }}>★ NEED 12TH PLAYER</div>
          )}
        </div>
      </div>
    );
  }

  if (type.id === 'recruit') {
    return (
      <div style={{ padding: '12px 14px 14px' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'oklch(0.55 0.13 80)', letterSpacing: '0.12em' }}>★ RECRUITING</div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em', marginTop: 4, lineHeight: 1.1 }}>{draft.recruitRole}</div>
        <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 6, lineHeight: 1.5 }}>{draft.recruitBody}</div>
        <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <Pill>📍 {draft.recruitLocation}</Pill>
          <Pill>⏱ {draft.recruitDeadline}</Pill>
          <Pill>{draft.recruitSpots === 5 ? '5+' : draft.recruitSpots} spot{draft.recruitSpots > 1 ? 's' : ''}</Pill>
        </div>
        <button style={{ marginTop: 12, padding: '10px 16px', borderRadius: 999, background: 'var(--ink)', color: 'var(--paper)', border: 'none', fontFamily: 'inherit', fontSize: 12, fontWeight: 700, cursor: 'pointer' }}>Apply</button>
      </div>
    );
  }

  if (type.id === 'tour') {
    return (
      <div style={{ padding: '12px 14px 14px' }}>
        <div style={{ fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: 700, color: 'oklch(0.45 0.12 280)', letterSpacing: '0.12em' }}>◇ {draft.tourTag.toUpperCase()}</div>
        <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em', marginTop: 4, lineHeight: 1.15 }}>{draft.tourHeadline}</div>
        <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 6, lineHeight: 1.5 }}>{draft.tourBody}</div>
      </div>
    );
  }

  return null;
}

function Pill({ children }) {
  return <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, padding: '4px 9px', borderRadius: 999, background: 'var(--paper-2)', border: '1px solid var(--hairline)', fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--ink-2)' }}>{children}</span>;
}

window.CkComposerHost = CkComposerHost;
window.CkComposer = CkComposer;
window.CK_COMPOSER_AUTHORS = DEFAULT_AUTHORS;

// Notifications.jsx — Notifications inbox (§6.10)

function Notifications() {
  const [filter, setFilter] = React.useState('All');
  const [read, setRead] = React.useState(new Set(['n7', 'n8', 'n9']));

  const markRead = id => setRead(s => new Set([...s, id]));
  const markAllRead = () => setRead(new Set(items.map(i => i.id)));

  const items = [
    {
      id: 'n1', kind: 'match-live', when: '2m', group: 'Today',
      icon: 'live', title: 'Lions vs Eagles is live',
      sub: 'Spring Cup QF · Lions chasing 156 · 14.3 ov',
      cta: 'Watch',
    },
    {
      id: 'n2', kind: 'milestone', when: '38m', group: 'Today',
      icon: 'trophy', title: 'You hit 50',
      sub: 'Your 5th half-century · 64 (38) vs Defenders XI',
      cta: 'Share',
    },
    {
      id: 'n3', kind: 'follow', when: '1h', group: 'Today',
      icon: 'user', title: 'Hassan R. started following you',
      sub: '@hassan_r · Mohalla Kings',
      cta: 'Follow back',
      avatar: 'HR',
    },
    {
      id: 'n4', kind: 'mention', when: '2h', group: 'Today',
      icon: 'at', title: 'Adeel S. mentioned you',
      sub: '"@bilalk carried us today. 64 off 38. Sublime."',
      avatar: 'AS',
    },
    {
      id: 'n5', kind: 'claim-decision', when: '4h', group: 'Today',
      icon: 'check', title: 'Your claim was approved',
      sub: 'You\'re now linked to Bilal Khan on Lahore Lions',
      tone: 'green',
    },
    {
      id: 'n6', kind: 'tournament', when: 'Yesterday', group: 'Earlier',
      icon: 'trophy', title: 'Spring Cup \'26 · QF starts tomorrow',
      sub: 'Lions vs Eagles · Sat 4pm · Iqbal Ground',
      cta: 'Add to calendar',
    },
    {
      id: 'n7', kind: 'recruit', when: '2d', group: 'Earlier',
      icon: 'megaphone', title: 'City Eagles is recruiting a wicket-keeper',
      sub: 'Within 6km · matches your role',
    },
    {
      id: 'n8', kind: 'comment', when: '2d', group: 'Earlier',
      icon: 'comment', title: '3 new comments on your post',
      sub: '"Lions for the win" and 2 others',
      avatar: 'AS',
    },
    {
      id: 'n9', kind: 'match-result', when: '3d', group: 'Earlier',
      icon: 'check', title: 'Lions won by 14 runs',
      sub: 'You: 64 (38) · POM nominated',
      tone: 'green',
    },
    {
      id: 'n10', kind: 'mom', when: '5d', group: 'Earlier',
      icon: 'star', title: 'You were nominated Player of the Match',
      sub: 'Confirm or thank your team-mates.',
      tone: 'amber',
      cta: 'Confirm',
    },
  ];

  const Icon = ({ kind, tone }) => {
    const bg = tone === 'green' ? 'var(--green-soft)' :
               tone === 'amber' ? 'oklch(0.94 0.05 90)' :
               kind === 'live' ? 'var(--red-soft)' :
               'var(--paper-2)';
    const fg = tone === 'green' ? 'oklch(0.36 0.10 148)' :
               tone === 'amber' ? 'oklch(0.30 0.02 80)' :
               kind === 'live' ? 'var(--red)' :
               'var(--ink)';
    const path = {
      live: <><circle cx="12" cy="12" r="3" fill={fg}/><circle cx="12" cy="12" r="9"/></>,
      trophy: <><path d="M6 9V7a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M6 9h12l-1 11H7Z"/></>,
      user: <><circle cx="12" cy="8" r="4"/><path d="M4 21v-1a8 8 0 0 1 16 0v1"/></>,
      at: <><circle cx="12" cy="12" r="4"/><path d="M16 12v1.5a2.5 2.5 0 0 0 5 0V12a9 9 0 1 0-3.5 7.1"/></>,
      check: <path d="M20 6 9 17l-5-5"/>,
      megaphone: <><path d="m3 11 18-5v12L3 13Z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></>,
      comment: <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2Z"/>,
      star: <path d="m12 2 3 7 7 .6-5.4 4.7 1.7 6.9L12 17.7 5.7 21.2l1.7-6.9L2 9.6 9 9Z"/>,
    }[kind];
    return (
      <div style={{ width: 36, height: 36, borderRadius: 10, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={fg} strokeWidth="2">{path}</svg>
      </div>
    );
  };

  const tabs = ['All', 'Mentions', 'Matches', 'Tournaments'];
  const filterMap = {
    Mentions: ['mention', 'comment', 'follow'],
    Matches: ['match-live', 'match-result', 'mom'],
    Tournaments: ['tournament'],
  };
  const visible = filter === 'All' ? items : items.filter(i => filterMap[filter].includes(i.kind));
  const unread = items.filter(i => !read.has(i.id)).length;

  // group
  const groups = {};
  visible.forEach(i => { (groups[i.group] = groups[i.group] || []).push(i); });

  return (
    <div className="ck-screen" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Header */}
      <div style={{ padding: '14px 20px 10px', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--ink)" strokeWidth="2"><path d="m15 18-6-6 6-6"/></svg>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 22, fontWeight: 700, letterSpacing: '-0.025em' }}>Notifications</div>
            {unread > 0 && (
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: 700, padding: '2px 8px', borderRadius: 999, background: 'var(--red)', color: 'white' }}>{unread}</div>
            )}
          </div>
          <button onClick={markAllRead} style={{ background: 'transparent', border: 'none', fontSize: 12, fontFamily: 'inherit', color: 'var(--ink-2)', cursor: 'pointer', fontWeight: 600 }}>Mark all read</button>
        </div>

        <div style={{ display: 'flex', gap: 6, marginTop: 14, overflowX: 'auto' }}>
          {tabs.map(t => (
            <button key={t} onClick={() => setFilter(t)} style={{
              flex: 'none', padding: '6px 12px', borderRadius: 999,
              background: filter === t ? 'var(--ink)' : 'var(--paper-2)',
              color: filter === t ? 'var(--paper)' : 'var(--ink-2)',
              border: '1px solid ' + (filter === t ? 'var(--ink)' : 'var(--hairline)'),
              fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
            }}>{t}</button>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        {Object.entries(groups).map(([g, gItems]) => (
          <div key={g}>
            <div style={{ padding: '14px 20px 6px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
              <div className="ck-section-h">{g}</div>
              <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)' }}>{gItems.length}</div>
            </div>
            {gItems.map(it => {
              const isRead = read.has(it.id);
              const navFor = (k) => {
                if (!window.__ckNav) return null;
                if (k === 'match-live' || k === 'match-result') return 'match';
                if (k === 'tournament') return 'tournament';
                if (k === 'recruit') return 'team';
                if (k === 'follow' || k === 'mention' || k === 'comment' || k === 'milestone' || k === 'mom' || k === 'claim-decision') return 'profile';
                return null;
              };
              return (
                <div key={it.id} onClick={() => { markRead(it.id); const dest = navFor(it.kind); if (dest) window.__ckNav.push(dest); }} style={{
                  display: 'flex', gap: 12, padding: '12px 20px',
                  borderTop: '1px solid var(--hairline)',
                  background: isRead ? 'var(--paper)' : 'oklch(0.99 0.012 85)',
                  position: 'relative', cursor: 'pointer',
                }}>
                  {!isRead && <div style={{ position: 'absolute', left: 8, top: '50%', transform: 'translateY(-50%)', width: 6, height: 6, borderRadius: 999, background: 'var(--red)' }} />}
                  <Icon kind={it.icon} tone={it.tone} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 6 }}>
                      <div style={{ fontFamily: 'Inter Tight', fontSize: 14, fontWeight: 600, letterSpacing: '-0.005em', flex: 1 }}>{it.title}</div>
                      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--muted)', flexShrink: 0 }}>{it.when}</div>
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 3, lineHeight: 1.4 }}>{it.sub}</div>
                    {it.cta && (
                      <button onClick={e => { e.stopPropagation(); markRead(it.id); }} style={{
                        marginTop: 8, padding: '6px 12px', borderRadius: 8,
                        background: it.tone === 'amber' ? 'var(--ink)' : 'var(--paper-2)',
                        color: it.tone === 'amber' ? 'var(--paper)' : 'var(--ink)',
                        border: it.tone === 'amber' ? 'none' : '1px solid var(--hairline)',
                        fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer',
                      }}>{it.cta}</button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        ))}

        {visible.length === 0 && (
          <div style={{ padding: '60px 24px', textAlign: 'center', color: 'var(--muted)' }}>
            <div style={{ fontFamily: 'Inter Tight', fontSize: 18, fontWeight: 600, color: 'var(--ink)', marginBottom: 6 }}>Nothing here</div>
            <div style={{ fontSize: 12 }}>No {filter.toLowerCase()} notifications.</div>
          </div>
        )}

        <div style={{ padding: '20px', textAlign: 'center', borderTop: '1px solid var(--hairline)' }}>
          <button style={{ padding: '8px 14px', background: 'transparent', color: 'var(--muted)', border: '1px solid var(--hairline)', borderRadius: 999, fontFamily: 'inherit', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>Notification settings</button>
        </div>
      </div>
    </div>
  );
}

window.CkNotifications = Notifications;

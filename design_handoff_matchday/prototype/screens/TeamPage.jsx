// TeamPage.jsx — main component, looks up case and renders

(function () {

const { tpHero: Hero, tpTabs: Tabs, tpLiveBanner: LiveBanner, tpInfoBanner: InfoBanner,
        tpSquadTab: SquadTab, tpMatchesTab: MatchesTab, tpStatsTab: StatsTab,
        tpAboutTab: AboutTab, tpManageTab: ManageTab, tpCases: CASES } = window;

const paper = 'var(--paper)';

function CkTeamPage({ caseId = 'owner-active', caseData, onBack, onAction }) {
  const data = caseData || CASES[caseId] || CASES['owner-active'];
  const team = data.team;
  const tabs = data.tabs;
  const [active, setActive] = React.useState(data.initial || tabs[0]);

  const tabsWithBadges = tabs.map(label => {
    const id = label;
    let badge = null;
    if (label === 'Manage' && team.actionQueue) badge = team.actionQueue.length;
    if (label === 'Recent' && team.recent) badge = team.recent.length;
    return { id, label, badge };
  });

  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', background: paper, position: 'relative' }}>
      <Hero team={team} viewer={data.viewer} badges={data.badges} onBack={onBack} onAction={onAction} />

      {team.live && <LiveBanner data={team.live} />}
      {data.banner && <InfoBanner {...data.banner} />}

      <Tabs active={active} setActive={setActive} items={tabsWithBadges} />

      <div style={{ flex: 1, overflow: 'auto' }}>
        {active === 'Squad'   && <SquadTab   team={team} viewer={data.viewer} viewerIs={data.viewerIs} />}
        {active === 'Matches' && <MatchesTab team={team} />}
        {active === 'Stats'   && <StatsTab   team={team} />}
        {active === 'About'   && <AboutTab   team={team} />}
        {active === 'Manage'  && <ManageTab  team={team} />}
        {active === 'Recent'  && <MatchesTab team={{ ...team, upcoming: null }} />}
        <div style={{ height: 28 }} />
      </div>
    </div>
  );
}

window.CkTeamPage = CkTeamPage;

})();

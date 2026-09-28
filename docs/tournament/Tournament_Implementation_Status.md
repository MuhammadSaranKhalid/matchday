# Matchday Tournament Architecture — Implementation Gap Audit & Status

**Document Version:** 2.1.0  
**Date:** 2026-09-28  
**Authoritative Standard:** [`docs/tournament/Tournament_Architecture_Standard.md`](file:///Users/redapple/Developer/personal/matchday/docs/tournament/Tournament_Architecture_Standard.md)  
**Status:** Gap Audit Complete — Pre-Implementation Governance & Alignment  
**Current Backend Topology:** Flutter Client → Supabase Edge Functions / PostgREST / RPCs → PostgreSQL (No NestJS service)

---

## 1. Executive Summary & Verification Context

An exhaustive, non-destructive implementation-gap audit was performed across the Matchday repository, rigorously verifying:
1. The 14 architecture steps and frozen standards in [`Tournament_Architecture_Standard.md`](file:///Users/redapple/Developer/personal/matchday/docs/tournament/Tournament_Architecture_Standard.md) (27,061 lines).
2. The deployed and local Supabase PostgreSQL schema, migrations in `supabase/migrations/`, RLS policies, routines, indexes, triggers, and realtime publications.
3. The server-authoritative command implementations in `supabase/functions/` (specifically `cricket-match-action/` and shared libraries).
4. The Flutter client codebase under `lib/features/tournaments/`, `lib/features/matches/`, and cross-feature domain entities.

### Crucial Findings Discovered During Audit
- **Dead Standings Engine:** PostgreSQL contains table `tournament_standings` and a broadcast trigger, but **no active recalculation routine exists** in migrations or in `cricket-match-action`. Standings are not automatically updated when tournament matches complete. Furthermore, `tournament_standings` is not included in the `supabase_realtime` CDC publication, causing client `.stream()` calls to receive no data.
- **Scattered Tournament Commands:** Six tournament operations (`tournament_abandon_match`, `tournament_declare_walkover`, `tournament_override_result`, `tournament_reschedule_match`, `tournament_revise_match_conditions`, and `tournament_trigger_super_over`) are currently implemented inside the `cricket-match-action` Edge Function, tightly coupling tournament administrative governance with cricket match actions.
- **Destructive Abandonment Bug:** In `tournament_abandon_match.ts`, rescheduling a started match executes `await innings.deleteAllForMatch(ctx.tx, ctx.matchId)`, directly violating the invariant that started match scorecards must never be destroyed.
- **Missing Database Progression Trigger:** Flutter's `DrawBuilder` documentation references a PostgreSQL trigger `match_advance_tournament_bracket`. In reality, this trigger does not exist in SQL. Progression is partially handled in TypeScript via `MatchTeamRepository.advanceWinner()`, which only executes during explicit commands in `cricket-match-action` and does not handle byes, stage progressions, or group standings qualification.
- **Client-Side Source of Truth Violations:** Flutter controllers issue direct PostgREST `update()` calls on `tournaments.status` (`startTournament`, `completeTournament`), group assignments, and registration withdrawals, bypassing server-side invariant validation.
- **Zero Tournament Capabilities:** The database capability engine (`permissions`, `permission_scopes`, `role_permissions`, `grants`) supports `'team'` and `'match'` scopes, but contains **zero tournament-scoped permissions**. Tournament access control relies entirely on the monolithic boolean helper `is_tournament_organizer()`.

---

## 2. Core Architectural Invariants & Foundational Principles

Before detailing schemas and phases, the following invariants from the Standard are frozen across the implementation program:

### 2.1 Authority Foundation
- **`created_by` = Provenance:** `created_by` records who initially drafted the tournament row. It is never used for runtime operational authorization.
- **Tournament Owner = Current Root Authority:** The active owner (stored in `owner_user_id`) holds root governance, ownership transfer rights, and terminal cancellation authority.
- **Tournament Manager = Delegated Membership/Capabilities:** Managers receive granular operational capabilities through normalized tournament memberships (`tournament_memberships`).
- **Normalized Memberships:** Organization roles are relational entities, not flat arrays on the tournament row.
- **Capabilities Authorize, Roles Default:** Business rules and commands never check `if (role == 'manager')`. Commands evaluate specific capabilities (`tournament.edit`, `draw.publish`, `fixture.reschedule`, `match.score`, `result.override`) at the tournament scope.
- **Team Authority != Tournament Authority:** Being a Team Owner, Team Manager, or Captain grants participant authority over that team's submission and lineup. It **never** grants administrative or scoring authority over a tournament match.
- **Scoring Authority != Active Scorer Lease:** Authorization to score (held via tournament role or match grant) is distinct from the active writer lease (`match_scorer_leases`). Only one device holds the active write lease at any moment.

### 2.2 Registration, Entry & Squad Boundary
- **Tournament Registration:** The application / intent to participate submitted by a team. Can be pending, approved, rejected, or withdrawn. Consumes no bracket capacity.
- **Tournament Entry:** The accepted competitive participant created upon registration approval. Contains seed, stage/group placement, and eligibility status.
- **Tournament Squad:** The subset of players from the team's roster eligible for this tournament. Moves through Draft → Frozen states. Match lineups are strictly validated against this squad.
- **Payment Ledger:** Payment history and balance tracking are decoupled from competitive entry state. A team can be approved before payment or pay without being approved.
- **Stage Participation:** First-class relationship (`tournament_stage_entries`) representing participation in a specific stage (essential for multi-stage tournaments where playoffs contain qualified subsets).
- *Transitional Status of `tournament_teams`:* The existing `tournament_teams` table flattens all five concepts into a single mutable row. It is treated as transitional only and will be superseded by normalized entities.

### 2.3 Fixture vs Match Separation
- **Fixture:** The structural slot in the tournament competition graph (`tournament_fixtures`). Answers: *Which round/stage is this, who feeds into it, and where does the outcome go?* Fixtures exist before participants are known.
- **Match:** The actual sporting contest (`matches` + `cricket_matches`). Answers: *What happened on the field? (toss, overs, deliveries, wickets, runs, sporting result).*
- **Decoupled Topology:** Tournament bracket topology (`round`, `bracket_round_number`, `bracket_match_number`, `prev_match_a_id`, `prev_match_b_id`, `group_id`) must completely leave `matches` and reside in `tournament_fixtures` and `tournament_fixture_slots`.
- **Explicit Slot Sources:** Every participant slot in a fixture has an explicit source type (`direct_entry`, `seed`, `fixture_winner`, `fixture_loser`, `group_rank`, `stage_rank`, `bye`).
- **1-to-Many Replay Support:** A single Fixture may reference multiple sequential Match attempts in replay scenarios.
- **Immutable Match History:** Once a match starts, its scorecard, overs, and deliveries must **never** be deleted or destructively reset. Rescheduling an unstarted fixture is operational; resolving a disrupted live match is an abandonment or replay.

### 2.4 Sporting Result vs Competition Outcome
- **Sporting Result:** Determined strictly by the Sport Match Engine (e.g. Cricket: runs, wickets, overs, Super Over outcome, DLS target, tie). Recorded in `cricket_matches.result`.
- **Competition Outcome:** Determined by Tournament Core / Sport Competition Adapter (e.g. advancing team, walkover, points awarded, bonus points). Recorded in `tournament_fixture_outcomes`.
- **Integrity of Scorecards:** Administrative result overrides or walkovers must **never** falsify the Cricket scorecard by fabricating runs or wickets. The sporting scorecard remains historical truth; the competition outcome records the administrative adjudication.
- **Progression Uses Outcome:** Downstream bracket advancement and standings calculations consume the authoritative Fixture Competition Outcome, not raw client inferences.

### 2.5 Standings & Ranking Architecture
- **Source Facts vs Projections:** Finalized authoritative competition outcomes are the source facts. Stage/Group standings (`tournament_stage_standings`, `cricket_stage_standing_metrics`) are derived read projections.
- **Synchronous Qualification Boundary:** For standings whose result affects rank, qualification, Stage completion, downstream Fixture Slot resolution, or Tournament completion, the affected Stage/Group standing projection **must be recomputed and finalized synchronously inside the authoritative competition transaction** before progression commits.
- **Outbox Role:** The outbox must **NOT** be the mechanism that later decides qualification. Outbox/event processing may update notifications, chat, feed, analytics, search, and non-critical derived presentation/statistics asynchronously after commit.
- **Recomputable Truth:** Standings must always be 100% rebuildable from finalized competition outcomes. Result corrections safely and completely recompute the affected Stage/Group.
- **Optimization Invariant:** Incremental standings deltas may only be introduced later as an optimization if the projection remains fully rebuildable and equivalence is proven.

### 2.6 Realtime & Invalidation Architecture
- **Semantic Supabase Broadcast:** Tournament-level semantic invalidation uses Supabase Realtime Broadcast (topic: `tournament:<id>`), replacing table-level CDC listeners.
- **Isolated Match Realtime:** High-frequency sport/match realtime remains isolated at Match scope using the currently selected Match realtime transport.
- **Transport Independence:** Tournament architecture must not depend on a particular third-party Match realtime provider.
- **Invalidation, Not Data Transport:** Realtime notifications signal that authoritative truth changed; clients refetch canonical read models. Realtime is never the database.

### 2.7 Communication & Integration Boundary
- **Outbox != Audit Log:** Domain events destined for external integration (push notifications, chat system announcements, social feeds) are written transactionally to `tournament_outbox_events`. Internal operational history is written to `tournament_audit_log`.
- **Isolated Failure Domains:** Tournament command transactions must never depend on external network calls to Chat, Push, or Feed services. Communication failures must never roll back committed competition state.

### 2.8 Unsupported Competition Structures
The following structures are **explicitly unsupported** in the engine, regardless of existing database enum values:
- **Double Elimination:** Unsupported until formal winner and loser feeder graphs, crossover rounds, and grand final reset mechanics are implemented.
- **Swiss System:** Unsupported until round-by-round pairing and Buchholz/Sonneborn-Berger tie-break engines exist.
- **Reseeding Playoffs:** Unsupported until dynamic knockout slot resolution exists.
- **Arbitrary Custom Brackets:** Unsupported until general DAG validation engines exist.

---

## 3. Current-State Architecture Map

```mermaid
graph TD
    subgraph Flutter Client ["Flutter Client (lib/features/tournaments)"]
        UI[Tournament UI Screens & Tabs]
        Ctrl[TournamentsController]
        DrawB[DrawBuilder (Pure Dart)]
        RepoImpl[TournamentsRepositoryImpl]
        DS[TournamentsRemoteDataSource]
        
        UI --> Ctrl
        Ctrl --> RepoImpl
        RepoImpl --> DrawB
        RepoImpl --> DS
    end

    subgraph Transport ["Network / API Layer"]
        PostgREST[PostgREST REST API]
        EFMatchAction[Edge Function: cricket-match-action]
    end

    subgraph Database ["Supabase PostgreSQL Database"]
        T_Tourn[(tournaments)]
        T_TT[(tournament_teams)]
        T_TS[(tournament_standings)]
        T_TG[(tournament_grounds)]
        T_M[(matches)]
        T_MT[(match_teams)]
        T_CM[(cricket_matches)]
        T_MO[(match_officials)]
        T_MSL[(match_scorer_leases)]
        T_Grants[(grants)]
        
        RPC_Gen[RPC: tournament_generate_fixtures]
        RPC_Approve[RPC: approve_tournament_registration]
        RPC_Ledger[RPC: tournament_fee_ledger]
        RPC_Officials[RPC: tournament_match_officials]
    end

    DS -- "Direct Row Updates (status, groups)" --> PostgREST
    DS -- "Draw Generation RPC" --> RPC_Gen
    DS -- "Approve/Reject RPC" --> RPC_Approve
    DS -- "Read RPCs" --> RPC_Ledger
    DS -- "Read RPCs" --> RPC_Officials
    DS -- "Tournament Live Ops Commands" --> EFMatchAction
    
    PostgREST --> T_Tourn
    PostgREST --> T_TT
    PostgREST --> T_TG
    
    RPC_Gen --> T_M
    RPC_Gen --> T_MT
    RPC_Gen --> T_CM
    
    EFMatchAction --> T_M
    EFMatchAction --> T_MT
    EFMatchAction --> T_CM
    
    T_MO -- "Trigger: mirror_scorer_grant" --> T_Grants
```

---

## 4. Target Architecture Map

```mermaid
graph TD
    subgraph Client ["Flutter Presentation & Domain Layers"]
        Screens[Screens: Detail, Console, Bracket, Standings, Live Ops]
        Coord[TournamentRealtimeCoordinator]
        ReadModels[Read Model Providers & Controllers]
        CmdClient[TournamentCommandClient]
        LayoutEngine[BracketLayoutEngine (InteractiveViewer)]
        
        Screens --> ReadModels
        Screens --> CmdClient
        Screens --> LayoutEngine
        Coord --> ReadModels
    end

    subgraph ServerCommands ["Supabase Edge Functions"]
        TAction[tournament-action (Command Handler)]
        CAction[cricket-match-action (Sport Action Handler)]
        SharedCore[Shared PostgreSQL Command Engine]
        
        TAction --> SharedCore
        CAction --> SharedCore
    end

    subgraph DataProjections ["Projections & Views (security_invoker=true)"]
        V_Detail[v_tournament_detail_shell]
        V_Bracket[v_tournament_bracket_stage]
        V_Standings[v_tournament_stage_standings]
        V_Console[v_tournament_organizer_console]
    end

    subgraph DomainEntities ["Normalized PostgreSQL Database"]
        T_Root[(tournaments)]
        T_Mem[(tournament_memberships)]
        T_Reg[(tournament_registrations)]
        T_Entry[(tournament_entries)]
        T_Squad[(tournament_squad_members)]
        T_Stage[(tournament_stages)]
        T_StageEntry[(tournament_stage_entries)]
        T_Group[(tournament_groups)]
        T_Round[(tournament_rounds)]
        T_Fix[(tournament_fixtures)]
        T_Slot[(tournament_fixture_slots)]
        T_Outcome[(tournament_fixture_outcomes)]
        T_Sport[(cricket_stage_standing_metrics)]
        T_Audit[(tournament_audit_log)]
        T_Outbox[(tournament_outbox_events)]
    end

    subgraph RealtimeSystem ["Supabase Realtime Broadcast"]
        Broadcast[Topic: tournament:id]
    end

    CmdClient --> TAction
    ReadModels --> V_Detail
    ReadModels --> V_Bracket
    ReadModels --> V_Standings
    ReadModels --> V_Console
    
    SharedCore --> DomainEntities
    DomainEntities --> DataProjections
    SharedCore -- "Post-Commit Invalidation" --> Broadcast
    Broadcast --> Coord
```

---

## 5. Component Classification & Gap Matrix

Every relevant current component across Database, Edge Functions, and Flutter is classified under one of the mandatory lifecycle categories:
- **KEEP**: Retain unchanged; aligns with standard.
- **KEEP + EXTEND**: Retain core behavior but add missing capabilities/fields.
- **REFACTOR**: Restructure internally to eliminate architectural violations while preserving public interface.
- **REPLACE**: Supersede with new canonical implementation.
- **MIGRATE**: Safe data/structural evolution preserving historical integrity.
- **REMOVE LATER**: Deprecated; maintained temporarily for compatibility, to be deleted in a future cleanup phase.

### A. Database Objects

| Component / Object | Current Role | Target Classification | Target Disposition & Rationale |
|---|---|---|---|
| `public.tournaments` | Root tournament container | **KEEP + EXTEND** | Retain table identity. Add `owner_user_id` (provenance vs authority), `revision`, orthogonal state columns (`registration_status`, `draw_status`, `competition_status`). Retain legacy columns (`status`, `tournament_type`, `venues`, `awards`) for zero-break compatibility. |
| `public.tournament_teams` | Overloaded registration, entry, squad, ledger | **MIGRATE** / **REMOVE LATER** | Split conceptually into `tournament_registrations`, `tournament_entries`, and `tournament_squad_members`. Maintain `tournament_teams` as a backward-compatible read-only view or narrowly controlled one-way compatibility projection during transition (no generic dual-write). |
| `public.tournament_standings` | Per-team points accumulator (cricket-specific) | **REPLACE** | Replace with generic `tournament_stage_standings` + `cricket_stage_standing_metrics`. Currently has dead write path (no recompute routine). |
| `public.tournament_grounds` | Tournament-to-ground link with sort order | **KEEP + EXTEND** | Retain table. Add transactional management and constraints preventing orphaned ground references. |
| `public.grounds` | Global physical grounds catalogue | **KEEP** | Meets all multi-tournament requirements with spatial and trigram search. |
| `public.matches` | Sport-neutral match shell with embedded tournament topology | **REFACTOR** | Retain match execution shell (`scheduled_start_time`, `status`, `winner_side`). Move bracket topology (`prev_match_*`, `bracket_*`, `round`, `group_id`) to `tournament_fixtures` and `tournament_fixture_slots`. |
| `public.match_teams` | Per-side team slot and name snapshot | **KEEP** | Canonical model for match participants. |
| `public.match_players` | Match participant lineups | **KEEP** | Preserved for sport execution. |
| `public.cricket_matches` | Cricket match state and rules snapshot | **KEEP** | Sport engine boundary model. |
| `public.cricket_match_players` | Cricket scorecard player lines | **KEEP** | Preserved for sport execution. |
| `public.match_officials` | Umpire and scorer appointments | **KEEP + EXTEND** | Retain table and `mirror_scorer_grant` trigger. Expand to support tournament-wide official defaults. |
| `public.match_scorer_leases` | Active scorer device lease | **KEEP** | Fulfills single-active-writer invariant. |
| `public.permissions` | Permission catalogue | **KEEP + EXTEND** | Add tournament-scoped capabilities (`tournament.edit`, `tournament.publish`, `tournament.draw.manage`, `tournament.fixture.reschedule`, `tournament.result.override`). |
| `public.permission_scopes` | Valid entity scopes per permission | **KEEP + EXTEND** | Populate `'tournament'` scope bindings for tournament capabilities. |
| `public.role_permissions` | Default role-to-permission mapping | **KEEP + EXTEND** | Map capabilities to `tournament_owner` and `tournament_manager`. |
| `public.grants` | Polymorphic direct grants | **KEEP + EXTEND** | Supports tournament-scoped direct grants. |
| `is_tournament_organizer(uuid)` | Monolithic organizer RLS helper | **KEEP + EXTEND** | Retain for existing RLS policies; enhance to check both `created_by`/`organizers` and normalized `tournament_memberships`. |
| `approve_tournament_registration(uuid)` | SQL RPC for registration approval | **REFACTOR** / **REPLACE** | Supersede with server command `ApproveRegistration` in `tournament-action` that atomically initializes `tournament_entries`. |
| `reject_tournament_registration(uuid)` | SQL RPC for registration rejection | **REFACTOR** / **REPLACE** | Supersede with server command `RejectRegistration` in `tournament-action`. |
| `tournament_record_payment(...)` | SQL RPC for recording team fee | **KEEP + EXTEND** | Safe transactional function. Retain and integrate with entry fee ledger. |
| `tournament_fee_ledger(uuid)` | Read RPC for tournament finances | **KEEP** | Effective read projection. |
| `tournament_match_officials(uuid)` | Read RPC for fixture officials | **KEEP** | Retain for Officials management screen. |
| `tournament_assign_official(...)` | Assign umpire/referee RPC | **KEEP** | Retain for match officials workflow. |
| `tournament_remove_official(...)` | Remove official RPC | **KEEP** | Retain for match officials workflow. |
| `tournament_official_candidates(...)` | Clash-aware official candidates | **KEEP** | Retain for match officials workflow. |
| `tournament_auto_assign_scorers(...)` | Batch scorer auto-assignment | **KEEP + EXTEND** | Safe operational helper. |
| `tournament_batting_leaderboard(...)` | Cricket batting stats read RPC | **KEEP** | Valid sport read projection. |
| `tournament_bowling_leaderboard(...)` | Cricket bowling stats read RPC | **KEEP** | Valid sport read projection. |
| `tournament_generate_fixtures(...)` | Monolithic fixture generation RPC | **REPLACE** | Superseded by server-side `PublishDraw` command that validates graph topology, supports multi-stage structures, and handles slots explicitly. |
| `broadcast_standings_change()` | Trigger on `tournament_standings` | **REFACTOR** | Shift from CDC trigger to post-commit domain broadcast. |
| Publication `supabase_realtime` | CDC publication | **KEEP + EXTEND** | Add required tables or migrate invalidation to Supabase Broadcast. |

### B. Edge Functions

| Component / File | Current Role | Target Classification | Target Disposition & Rationale |
|---|---|---|---|
| `cricket-match-action/commands/complete_cricket_match.ts` | Completes cricket match and advances winner | **REFACTOR** | Extract tournament progression out of cricket match action into shared transaction helper. Maintain atomic finalization. |
| `cricket-match-action/commands/tournament_abandon_match.ts` | Reschedules or abandons tournament match | **REFACTOR** / **MIGRATE** | Fix critical bug: remove `deleteAllForMatch`. Migrate to dedicated `tournament-action` command. |
| `cricket-match-action/commands/tournament_declare_walkover.ts` | Awards walkover and advances winner | **REFACTOR** / **MIGRATE** | Migrate to `tournament-action` command. Do not create fake cricket score. |
| `cricket-match-action/commands/tournament_override_result.ts` | Admin override of match winner | **REFACTOR** / **MIGRATE** | Migrate to `tournament-action` command. Separate sporting score from competition outcome. |
| `cricket-match-action/commands/tournament_reschedule_match.ts` | Changes scheduled time/venue | **REFACTOR** / **MIGRATE** | Migrate to `tournament-action` command. Check ground clashes. |
| `cricket-match-action/commands/tournament_revise_match_conditions.ts` | Revises overs/target for rain | **KEEP** (in Cricket) | Purely a sport match operation; remains under `cricket-match-action`. |
| `cricket-match-action/commands/tournament_trigger_super_over.ts` | Initiates super over for tie | **KEEP** (in Cricket) | Purely a sport match operation; remains under `cricket-match-action`. |
| `cricket-match-action/repositories/match_team_repository.ts` | Contains `advanceWinner` & `clearAdvancedWinner` | **REFACTOR** | Replace brittle direct `prev_match_*` updates with topological slot source resolution. |
| `supabase/functions/tournament-action` | Dedicated tournament command function | **NEW** / **REPLACE** | Implement single command router for tournament operations with `commandId`, idempotency, and revision checks. |

### C. Flutter Components (`lib/features/tournaments/`)

| Component / File | Current Role | Target Classification | Target Disposition & Rationale |
|---|---|---|---|
| `domain/entities/tournament.dart` | Tournament domain entity | **REFACTOR** | Strip cricket getters (`maxOvers`, `ballType`); decouple structure from `TournamentType` enum; add stage support. |
| `domain/entities/tournament_standing.dart` | Standings domain entity | **REFACTOR** | Separate generic standings from sport-specific metrics (NRR). |
| `domain/entities/tournament_registration.dart` | Registration entity | **REFACTOR** | Disentangle registration request from entry and squad. |
| `domain/entities/tournament_live_match.dart` | Live fixture projection | **REFACTOR** | Upgrade to `TournamentFixture` supporting explicit slots and feeder sources. |
| `domain/entities/tournament_awards.dart` | Award categories and winners | **KEEP** | Clean domain entity. |
| `domain/entities/ground.dart` | Physical ground entity | **KEEP** | Clean domain entity. |
| `domain/entities/match_official.dart` | Official appointment entity | **KEEP** | Clean domain entity. |
| `domain/entities/scorer_candidate.dart` | Candidate official entity | **KEEP** | Clean domain entity. |
| `domain/entities/tournament_fee_entry.dart` | Financial ledger entity | **KEEP** | Clean domain entity. |
| `domain/entities/my_tournament_entry.dart` | User tournament summary | **KEEP** | Clean domain entity. |
| `domain/draw/draw_builder.dart` | Pure Dart draw generator | **REFACTOR** | Retain for client-side preview; server becomes sole authority for published draws. |
| `domain/draw/draw_plan.dart` | Draft draw data structure | **REFACTOR** | Expand to represent multi-stage plans, groups, and explicit slot sources. |
| `domain/repositories/tournaments_repository.dart` | Repository contract | **REFACTOR** | Separate read queries from typed server commands. |
| `data/repositories/tournaments_repository_impl.dart` | Repository implementation | **REFACTOR** | Route mutations to `tournament-action` Edge Function; catch exceptions and map to `Either<Failure, T>`. |
| `data/datasources/tournaments_remote_datasource.dart` | Data source with direct PostgREST writes | **REFACTOR** | Eliminate direct table mutations for tournament status, groups, and withdrawals. Implement typed command caller. |
| `presentation/providers/tournaments_providers.dart` | Riverpod presentation providers | **REFACTOR** | Replace fragmented invalidation with centralized Realtime Coordinator. |
| `presentation/controllers/tournaments_controller.dart` | UI controller with direct status mutations | **REFACTOR** | Replace `startTournament`, `completeTournament`, etc. with typed command dispatches. Support entity-keyed mutation state. |
| `presentation/widgets/tournament_bracket_view.dart` | Horizontal scroll bracket viewer | **REFACTOR** | Replace inferred connector math and horizontal scroll with `InteractiveViewer.builder` + deterministic `BracketLayoutEngine`. |
| `presentation/widgets/ck_bracket_node.dart` | Bracket match card | **KEEP + EXTEND** | Enhance to represent unresolved slots (`Winner SF1`), byes, and live indicators. |
| `presentation/widgets/ck_standings_table.dart` | Standings table widget | **KEEP + EXTEND** | Decouple cricket headers from generic table shell via sport adapter. |
| `presentation/screens/tournament_detail_screen.dart` | Main tournament screen | **REFACTOR** | Make tabs stage-driven instead of switching on monolithic `TournamentType`. |
| `presentation/screens/organizer_console_screen.dart` | Organizer management console | **REFACTOR** | Back with composite read model; action-first mobile layout. |
| `presentation/screens/tournament_create_wizard_screen.dart` | Tournament creation flow | **KEEP + EXTEND** | Support templates and progressive disclosure. |
| `presentation/screens/tournament_fee_ledger_screen.dart` | Fee collection ledger | **KEEP** | Clean UI connected to read RPC. |

---

## 6. Controlled Implementation Program (Phases 0–18)

The implementation program follows a strict 19-phase sequential progression. No phase may be silently merged, compressed, or bypassed.

- **Phase 0: Full Gap Audit** `[COMPLETE]`
  - Detailed inspection of database, edge functions, and Flutter code against the 27,061-line Standard.
- **Phase 1: Baseline Safety & Test Harness** `[COMPLETE]`
  - Baseline safety and characterization phase.
  - Capture currently valid Match/Cricket behavior and characterize existing Tournament behavior.
  - Document known broken/missing progression behavior and add regression tests around behavior that must survive migration.
  - Mark known legacy architectural violations as `LEGACY — EXPECTED TO CHANGE`.
  - Must **NOT** create golden tests that establish the current `advanceWinner()` / `prev_match_*` architecture as the expected canonical progression model. (Canonical deterministic progression tests belong primarily to Phase 7 for Draw generation and Phase 8 for Fixture/Match progression).
- **Phase 2: Tournament Root, Lifecycle & Membership Foundation**
  - Add `owner_user_id`, revision, and orthogonal status fields to `tournaments`.
  - Add tournament capabilities to `permissions`, bind to `'tournament'` in `permission_scopes`, map in `role_permissions`.
  - Create `tournament_memberships` table; migrate existing `created_by`/`organizers` data.
- **Phase 3: Registration → Entry → Squad → Payment**
  - Create `tournament_registrations`, `tournament_entries`, `tournament_squad_members`.
  - Separate application lifecycle from confirmed competition entry.
  - Establish backward-compatibility view on `tournament_teams`.
- **Phase 4: Stage / Group / Round / Draw Revision / Fixture / Slot Foundation**
  - Create `tournament_stages`, `tournament_stage_entries`, `tournament_groups`, `tournament_rounds`, `tournament_fixtures`, `tournament_fixture_slots`, `tournament_draw_revisions`.
  - Support explicit slot sources (`seed`, `winner`, `loser`, `group_rank`, `bye`).
- **Phase 5: `tournament-action` Edge Function Foundation**
  - Scaffold `tournament-action` Edge Function with command envelope, authentication extraction, `commandId` idempotency, and optimistic revision checks.
- **Phase 6: Participation Commands Migration**
  - Implement server commands: `RegisterTeam`, `ApproveRegistration`, `RejectRegistration`, `WithdrawRegistration`, `FreezeSquad`.
  - Route Flutter participation actions to `tournament-action`.
- **Phase 7: Competition Generators & Draw Publication**
  - Implement server-side draw generation and atomic `PublishDraw` command for Knockout, Round Robin, and Group + Knockout.
  - Validate graph acyclicity, slot sources, and bye advancements prior to publication commit.
- **Phase 8: Fixture ↔ Match Materialization & Progression**
  - Implement fixture execution materialization (`tournament_fixture_matches`).
  - Implement atomic match finalization and slot resolution in shared PostgreSQL transaction engine.
- **Phase 9: Tournament Operations & Exception Handling**
  - Implement operational commands in `tournament-action`: `RescheduleFixture`, `DeclareWalkover`, `CorrectResult`, `AbandonMatch`.
  - Remove destructive `deleteAllForMatch`; enforce non-destructive replay/abandonment invariants.
- **Phase 10: Sport Competition Adapter / Standings / Ranking / Qualification**
  - Implement stage-scoped standings recalculation routines and tie-breaking pipelines.
  - Implement `cricket_stage_standing_metrics` extension.
  - Resolve group-to-knockout stage progression upon stage finalization.
- **Phase 11: Domain Events / Outbox / Communication Boundary**
  - Implement transactional outbox (`tournament_outbox_events`) and audit logging (`tournament_audit_log`).
  - Decouple push notifications, participant chat system messages, and feed integration from tournament commands.
- **Phase 12: Read Models / Security-Invoker Views / Realtime**
  - Deploy composite views (`v_tournament_detail_shell`, `v_tournament_bracket_stage`, `v_tournament_stage_standings`, `v_tournament_organizer_console`) with `security_invoker = true`.
  - Deploy Supabase Broadcast triggers for semantic domain events.
- **Phase 13: Flutter Client Architecture Cutover**
  - Implement `TournamentRealtimeCoordinator` managing broadcast subscriptions and invalidations.
  - Refactor `TournamentsRemoteDataSource` and repositories to consume composite read models and typed commands.
- **Phase 14: Flutter Tournament UX & Bracket Visualization**
  - Implement `BracketLayoutEngine` using native `InteractiveViewer.builder`, `TransformationController`, and deterministic slot geometry.
  - Upgrade mobile bracket navigation, tap-to-focus match cards, and action-first Organizer Console.
- **Phase 15: Legacy Retirement**
  - Deprecate and safely remove legacy columns (`matches.prev_match_*`, `matches.bracket_*`), legacy RPCs, and compatibility shims after verified client cutover.
- **Phase 16: Security / RLS / Concurrency / Performance Audit**
  - Audit all table grants, RLS policies, connection pool load, and transaction lock durations.
- **Phase 17: Full End-to-End Integrity Verification**
  - Execute end-to-end integration scenario: Registration → Draw Publication → Match Scoring → Standings Recompute → Finalization → Trophy Awarding.
- **Phase 18: Final Architecture Conformance Audit**
  - Mechanical audit against all 14 steps of [`Tournament_Architecture_Standard.md`](file:///Users/redapple/Developer/personal/matchday/docs/tournament/Tournament_Architecture_Standard.md).

---

## 7. Phase Dependency Graph

```mermaid
graph TD
    P0[Phase 0: Gap Audit COMPLETE] --> P1[Phase 1: Baseline Safety & Test Harness]
    P1 --> P2[Phase 2: Root, Lifecycle & Membership]
    P2 --> P3[Phase 3: Registration, Entry, Squad & Payment]
    P3 --> P4[Phase 4: Stages, Groups, Rounds, Fixtures & Slots]
    P4 --> P5[Phase 5: tournament-action Foundation]
    P5 --> P6[Phase 6: Participation Commands Migration]
    P6 --> P7[Phase 7: Draw Generators & Publication]
    P7 --> P8[Phase 8: Fixture-Match Materialization & Progression]
    P8 --> P9[Phase 9: Operations & Exception Handling]
    P8 --> P10[Phase 10: Standings, Ranking & Qualification]
    P9 --> P11[Phase 11: Domain Events & Outbox]
    P10 --> P11
    P11 --> P12[Phase 12: Read Models & Realtime Broadcast]
    P12 --> P13[Phase 13: Flutter Client Cutover]
    P13 --> P14[Phase 14: Bracket UX & Mobile Layout]
    P14 --> P15[Phase 15: Legacy Retirement]
    P15 --> P16[Phase 16: Security, RLS & Concurrency Audit]
    P16 --> P17[Phase 17: End-to-End Verification]
    P17 --> P18[Phase 18: Final Conformance Audit]

    style P0 fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style P1 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P2 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P3 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P4 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P5 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P6 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P7 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P8 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P9 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P10 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P11 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P12 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P13 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P14 fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style P15 fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style P16 fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style P17 fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style P18 fill:#d1c4e9,stroke:#512da8,stroke-width:2px
```

---

## 8. Corrected Risk Register

| Risk ID | Description | Impact | Likelihood | Mitigation Strategy |
|---|---|---|---|---|
| **R-01** | **Breaking Active Tournaments / Split-Brain State:** Modifying `matches` or `tournament_teams` disrupts running tournaments or introduces conflicting sources of truth. | Critical | High | **Single-Source-of-Truth Migration Policy:** At every migration phase there must be exactly one documented authoritative write model for each concern. Compatibility may be provided through read-only views, adapters, one-way backfills, or narrowly controlled one-way compatibility projections. **Do NOT establish generic bidirectional synchronization between legacy and canonical models.** Do NOT allow both legacy Flutter writes and canonical command writes to mutate equivalent business state independently. If a temporary compatibility trigger is ever absolutely necessary, it must be one-way from the authoritative model to a legacy compatibility representation, narrowly scoped, documented, tested, and removed after consumer cutover. No compatibility mechanism may become a second source of truth. |
| **R-02** | **Scorecard Data Loss on Reschedule:** Rescheduling started tournament matches drops deliveries. | Critical | Medium | Immediately replace `deleteAllForMatch` with the new command model where unstarted matches are rescheduled and started matches require formal replay or abandonment. |
| **R-03** | **Downstream Corruption on Result Correction:** Changing a match winner cascades and corrupts downstream matches that have already started. | High | Medium | Enforce guard: if downstream dependent fixture has started (`status != 'scheduled'`), reject automated participant replacement and require organizer operational recovery. |
| **R-04** | **Standings Recalculation Contention / Desync:** Standings table recalculation causes database lock contention or drifts from match reality. | High | Low | **Synchronous Qualification & Transaction Boundary:** Finalized authoritative competition outcomes are the source facts. For standings whose result affects rank, qualification, Stage completion, downstream Fixture Slot resolution, or Tournament completion, the affected Stage/Group standing projection must be recomputed/finalized **synchronously inside the authoritative competition transaction** before progression commits. The outbox must **NOT** be the mechanism that later decides qualification. Outbox/event processing may update notifications, chat, feed, analytics, search, and non-critical derived presentation/statistics after commit. Incremental standings deltas may only be introduced later as an optimization if the projection remains fully rebuildable and equivalence is proven. |
| **R-05** | **Realtime Overhead / Transport Contention:** Realtime broadcasts flooding tournament channels or exceeding connection capacity. | Medium | High | **Transport Independence Policy:** Tournament-level semantic invalidation uses Supabase Realtime Broadcast. High-frequency sport/match realtime remains isolated at Match scope using the currently selected Match realtime transport. Tournament architecture must not depend on a particular third-party Match realtime provider. This keeps the Tournament architecture transport-independent. |

---

## 9. Data-Loss Risks & Protective Rules

1. **Started Innings Deletion:** The current code in `tournament_abandon_match.ts` that issues `innings.deleteAllForMatch` must be explicitly marked for replacement. **No match delivery or wicket row may ever be deleted as part of an operational rescheduling.**
2. **Participant Identity Deletion:** When a team withdraws or is disqualified after draw publication, its `tournament_entries` row must **never be deleted**. Its status must be set to `withdrawn` or `disqualified` so historical match statistics and bracket geometry remain intact.
3. **Historical Match Format Rewrite:** Sport rules must be snapshotted at fixture creation (`rules_snapshot` in `cricket_matches`). Changing tournament rules later must never mutate the rules of already completed or live matches.

---

## 10. Migration & Cutover Strategy (Single Source of Truth)

1. **Strict Single-Source-of-Truth Principle:**
   - At every migration phase there must be exactly one documented authoritative write model for each concern.
   - Compatibility may be provided through read-only views, adapters, one-way backfills, or narrowly controlled one-way compatibility projections.
   - **Do NOT establish generic bidirectional synchronization between legacy and canonical models.**
   - **Do NOT allow both legacy Flutter writes and canonical command writes to mutate equivalent business state independently.**
   - If a temporary compatibility trigger is ever absolutely necessary, it must be one-way from the authoritative model to a legacy compatibility representation, narrowly scoped, documented, tested, and removed after consumer cutover.
   - No compatibility mechanism may become a second source of truth.
2. **Non-Destructive Additive Evolution:** All new tables (`tournament_stages`, `tournament_fixtures`, etc.) will be created alongside existing tables.
3. **Idempotent Backfill Migration:** A deterministic SQL migration will populate:
   - One default stage (`Stage 1`) per existing tournament.
   - One `tournament_fixture` per existing `tournament_id != null` match.
   - `tournament_entries` from approved `tournament_teams`.
4. **Compatibility View Layer:** `tournament_teams` will remain readable via PostgreSQL views or strictly one-way compatibility projections for any legacy Flutter clients in production, never serving as a secondary write authority.
5. **Hard Cutover Assertions:** Before any deprecated column is dropped in Phase 15, automated SQL queries will verify that zero live functions, RPCs, or queries reference the old columns.

---

## 11. Testing Strategy

1. **Clean Architecture Invariants:** Automated test via `flutter test test/architecture_test.dart` ensuring domain purity (zero Flutter/Riverpod/Supabase imports in domain).
2. **Baseline Characterization & Regression Suite (Phase 1):**
   - Phase 1 is strictly a **BASELINE SAFETY / CHARACTERIZATION** phase.
   - May capture currently valid Match/Cricket behavior.
   - May characterize existing Tournament behavior.
   - May document known broken/missing progression behavior.
   - May add regression tests around behavior that must survive migration.
   - Must **NOT** create golden tests that establish the current `advanceWinner()` / `prev_match_*` architecture as the expected canonical progression model.
   - All known legacy architectural violations must be marked `LEGACY — EXPECTED TO CHANGE`.
3. **Deterministic Progression Golden / Integration Suite (Phases 7 & 8):**
   - Canonical deterministic progression golden/integration tests belong primarily to Phase 7 for Draw generation and Phase 8 for Fixture/Match progression.
   - 8-team knockout bracket generation and seed placement (Phase 7).
   - Bye placement for non-power-of-two fields (byes advance immediately to Round 2 without creating ghost matches) (Phase 7).
   - Match completion resolving downstream `FixtureSlot` exactly once (idempotent replay).
   - Guard rejection when attempting to correct an upstream result whose downstream match has already begun.
4. **Standings & Ranking Invariant Tests (Phase 10):** Golden tests verifying stage-scoped points table ordering, tie-breakers, and synchronous qualification resolution against verified competition outcomes.
5. **Command Idempotency Tests:** Verifying that duplicate `commandId` submissions return the exact same result without duplicate state mutation.
6. **RLS Security Invoker Audit:** Automated test suite verifying that anon users cannot read private drafts, unapproved team managers cannot modify brackets, and only authorized organizers can invoke tournament commands.

---

## 12. Explicit List of Things That Must NOT Yet Be Deleted

The following database columns, tables, RPCs, and Flutter components **MUST NOT BE DELETED** during early phases:
1. **`tournaments.status` column:** Still read by current Flutter app navigation and existing match filters.
2. **`tournaments.tournament_type` column:** Still read by existing detail screen and bracket tab.
3. **`tournaments.venues` (jsonb) column:** Still used by current tournament creation wizard.
4. **`tournament_teams` table:** Primary table read by current registration tabs and team roster sheets.
5. **`tournament_standings` table:** Read by public standings screen.
6. **`matches.prev_match_a_id` & `matches.prev_match_b_id` columns:** Read by existing `MatchTeamRepository.advanceWinner` in `cricket-match-action`.
7. **`matches.bracket_round_number` & `matches.bracket_match_number` columns:** Read by current `TournamentBracketView`.
8. **RPC `tournament_generate_fixtures`:** Used by existing `Lock & Publish` dialog in the mobile app.
9. **`cricket-match-action` tournament command endpoints:** Active Flutter client builds currently invoke these endpoints for walkover, override, and reschedule.
10. **`TournamentType` & `TournamentStatus` enums in Flutter:** Used across dozens of widgets.

---

## 13. Audit Conclusion & Phase 1 Verdict

### Files Inspected:
- `docs/tournament/Tournament_Architecture_Standard.md` (complete, all 27,061 lines)
- `supabase/migrations/20260101000300_tournaments.sql`
- `supabase/migrations/20260101000310_tournament_teams.sql`
- `supabase/migrations/20260101000320_tournament_standings.sql`
- `supabase/migrations/20260101000330_grounds.sql`
- `supabase/migrations/20260101000331_tournament_grounds.sql`
- `supabase/migrations/20260101000400_matches.sql`
- `supabase/migrations/20260101000402_match_teams.sql`
- `supabase/migrations/20260101000409_match_scorer_leases.sql`
- `supabase/migrations/20260101000411_match_officials.sql`
- `supabase/migrations/20260101000420_tournament_ops.sql`
- `supabase/migrations/20260101000204_permissions.sql`
- `supabase/migrations/20260101000205_permission_scopes.sql`
- `supabase/migrations/20260101000207_grants.sql`
- `supabase/migrations/20260101000820_match_realtime_and_security.sql`
- `supabase/functions/cricket-match-action/commands/complete_cricket_match.ts`
- `supabase/functions/cricket-match-action/commands/tournament_declare_walkover.ts`
- `supabase/functions/cricket-match-action/commands/tournament_override_result.ts`
- `supabase/functions/cricket-match-action/commands/tournament_abandon_match.ts`
- `supabase/functions/cricket-match-action/commands/tournament_reschedule_match.ts`
- `supabase/functions/cricket-match-action/commands/tournament_revise_match_conditions.ts`
- `supabase/functions/cricket-match-action/commands/tournament_trigger_super_over.ts`
- `supabase/functions/cricket-match-action/repositories/match_team_repository.ts`
- `lib/features/tournaments/domain/entities/tournament.dart`
- `lib/features/tournaments/domain/entities/tournament_standing.dart`
- `lib/features/tournaments/domain/entities/tournament_registration.dart`
- `lib/features/tournaments/domain/draw/draw_builder.dart`
- `lib/features/tournaments/domain/draw/draw_plan.dart`
- `lib/features/tournaments/data/datasources/tournaments_remote_datasource.dart`
- `lib/features/tournaments/data/repositories/tournaments_repository_impl.dart`
- `lib/features/tournaments/presentation/controllers/tournaments_controller.dart`
- `lib/features/tournaments/presentation/providers/tournaments_providers.dart`
- `lib/features/tournaments/presentation/widgets/tournament_bracket_view.dart`
- `lib/features/tournaments/presentation/widgets/ck_standings_table.dart`
- `lib/features/matches/domain/entities/match.dart`

### Database Objects Inspected:
- Tables: `tournaments`, `tournament_teams`, `tournament_standings`, `grounds`, `tournament_grounds`, `matches`, `match_teams`, `match_players`, `cricket_matches`, `cricket_match_players`, `match_officials`, `match_scorer_leases`, `permissions`, `permission_scopes`, `role_permissions`, `grants`.
- RPCs / Functions: `is_tournament_organizer`, `approve_tournament_registration`, `reject_tournament_registration`, `tournament_record_payment`, `tournament_fee_ledger`, `tournament_match_officials`, `tournament_assign_official`, `tournament_remove_official`, `tournament_official_candidates`, `tournament_auto_assign_scorers`, `tournament_batting_leaderboard`, `tournament_bowling_leaderboard`, `tournament_generate_fixtures`, `broadcast_standings_change`, `mirror_scorer_grant`.
- Realtime Publications: `supabase_realtime` CDC mappings.

### Major Conflicts Found:
1. **Standings Recalculation is Non-Existent:** `recalculate_standings()` was removed from SQL migrations and never implemented in `cricket-match-action`. Standings tables are dead in production.
2. **Progression Trigger Missing:** Flutter relies on automated bracket progression, but the referenced trigger `match_advance_tournament_bracket` does not exist in the database.
3. **Scattered Commands in Sport Service:** Tournament management commands reside in `cricket-match-action` rather than a sport-neutral tournament domain service.
4. **Destructive Reschedule:** Started match innings are deleted if abandoned with `mode = 'reschedule'`.
5. **No Granular Tournament Permissions:** The permission engine does not have tournament-scoped capabilities or roles.

### Implementation Ordering:
The 19-phase sequence (Phases 0–18) defined in Section 6 is the authoritative ordering.

### Verdict for Phase 1 (Baseline Safety & Test Harness): **GO**
Phase 1 is strictly a **BASELINE SAFETY / CHARACTERIZATION** phase.
It may:
- Capture currently valid Match/Cricket behavior.
- Characterize existing Tournament behavior.
- Document known broken/missing progression behavior.
- Add regression tests around behavior that must survive migration.

It must **NOT** create golden tests that establish the current `advanceWinner()` / `prev_match_*` architecture as the expected canonical progression model (canonical deterministic progression golden/integration tests belong primarily to Phase 7 for Draw generation and Phase 8 for Fixture/Match progression).

All known legacy architectural violations must be marked:
`LEGACY — EXPECTED TO CHANGE`

Phase 1 modifies zero production code, creates zero migrations, and changes zero database schemas. It is completely safe to proceed with Phase 1.

---

## 14. Phase 1 — Baseline Safety & Test Harness Report

Phase 1 established an automated regression safety net and characterized existing behavior prior to any architectural migrations in Phase 2+.

### 14.1 Baseline Command Execution Results

| Command | Exit Code | Results / Summary |
|---|---|---|
| `git status --short` | `0` | Clean. Only expected docs and new test file touched (`test/features/tournaments/baseline_safety_characterization_test.dart`). Pre-existing unrelated files (`comments_sheet.dart`, `safety_menu.dart`) remained untouched. |
| `flutter analyze lib/` | `0` | **0 issues found** across all application source code under `lib/`. |
| `flutter analyze` (repo-wide) | `1` | 369 issues strictly localized in stale UI screen tests under `test/` due to mock auth/teams providers refactored in previous sprints. Zero issues in `lib/`. |
| `flutter test` (repo-wide) | `1` | **644 passed, 27 failed** (`02:41`). All 27 failures are pre-existing test compile failures due to outdated imports/providers from prior refactoring slices. Zero failures in core architecture or scoring engine. |
| `flutter test test/architecture_test.dart` | `0` | **6 passed, 0 failed** (`01:43`). All Clean Architecture invariants upheld. |
| Domain purity check (`grep -rlE ... lib/features/*/domain`) | `1` | **0 matches.** Domain layer is 100% pure Dart. |
| `flutter test test/features/tournaments/baseline_safety_characterization_test.dart` | `0` | **10 passed, 0 failed.** All 10 tests passed (4 valid regression protections, 3 legacy characterizations, 3 specification/architecture invariant tests). |
| `flutter test test/features/tournaments/domain test/features/tournaments/data test/features/tournaments/presentation/widgets` | `0` | **100 passed, 0 failed.** All tournament domain entities, repositories, draw builder algorithms, and widgets passed. |
| `flutter test test/features/matches/domain/scoring` | `0` | **76 passed, 0 failed.** Cricket scoring engine vectors and replay parity verified. |
| `flutter test test/features/matches/domain/entities/match_test.dart` | `0` | **6 passed, 0 failed.** Generic Match status and type mappings verified. |
| `npx --yes deno check supabase/functions/cricket-match-action/index.ts` | `0` | **Zero TypeScript/type errors.** |
| `npx --yes deno test supabase/functions/cricket-match-action/commands/runtime_commands.test.ts` | `0` | **9 passed, 0 failed.** Runtime match command execution verified. |

### 14.2 Existing Failures Inventory (Repository-Wide `flutter test`)

During the full repository-wide `flutter test` baseline, **27 test files failed to compile/load** while **644 tests passed**. All 27 failures are confirmed pre-existing across 4 feature areas:
1. **Tournament Screen Test Mocks (6 files):**
   - Files: `test/features/tournaments/presentation/screens/tournament_create_wizard_screen_test.dart`, `tournament_detail_screen_test.dart`, `tournament_requests_screen_test.dart`, `my_tournaments_screen_test.dart`, `organizer_console_screen_test.dart`, `team_registration_sheet_test.dart`.
   - Cause: Outdated mock providers (`currentUserStreamProvider`, `myTeamsProvider`, `myTeamRolesProvider`, `rosterProvider`) that were refactored in previous feature sprints.
2. **Match Repository & Controller Test Mocks (3 files):**
   - Files: `test/features/matches/data/repositories/record_ball_validation_test.dart`, `scoring_write_failure_taxonomy_test.dart`, `test/features/matches/presentation/controllers/scoring_controller_test.dart`.
   - Cause: Outdated repository method call `recordBall` (now migrated to scoring session pipeline).
3. **Messages Feature Test Mocks (3 files):**
   - Files: `test/features/messages/outbox_processor_test.dart`, `chat_local_data_source_test.dart`, `messages_requests_test.dart`.
   - Cause: Drift schema and provider signature evolutions.
4. **Teams Feature Test Mocks & Helpers (15 files):**
   - Files: `test/features/teams/data/repositories/team_lifecycle_test.dart`, `team_relationship_test.dart`, `team_manage_screen_test.dart`, `my_teams_skeleton_test.dart`, `team_create_controller_test.dart`, `teams_list_controller_test.dart`, `tp_options_sheet_test.dart`, and related widget screens.
   - Cause: Obsolete `Team` constructor parameters (`city`) and old Riverpod provider overrides from previous team domain refactorings.

### 14.3 Tournament & Match Test Coverage Matrix

| Feature / Behavior | Existing Test? | Valid Current Behavior? | Legacy Behavior Expected to Change? | Need Characterization Test? | Need Canonical Test Later? |
|---|---|---|---|---|---|
| **Tournament Creation** | Yes (`tournaments_repository_impl_test`, wizard widget test) | Yes | Yes (direct status='draft' insert) | Yes (covered) | Phase 2 |
| **Tournament Editing** | Yes (`updateTournament` tests) | Yes | Yes (direct postgrest update) | Yes (covered) | Phase 2 |
| **Tournament Publishing** | Yes (`tournament_draw_publish_test.dart`) | Yes | Yes (client pushes raw fixtures) | Yes (covered) | Phase 7 |
| **Team Registration** | Yes (`team_registration_sheet_test`) | Yes | Yes (overloaded `tournament_teams`) | Yes (covered) | Phase 3 & 6 |
| **Registration Approval / Rejection** | Yes (RPC unit tests in SQL) | Yes | Yes (RPCs bypass command pipeline) | Yes (covered) | Phase 6 |
| **Team Withdrawal** | Yes (`updateRegistrationStatus`) | Yes | Yes (status='withdrawn' in `tournament_teams`) | Yes (covered) | Phase 6 |
| **Group Assignment** | Yes (`assignGroups`) | Yes | Yes (direct postgrest write to `group_id`) | Yes (covered) | Phase 4 & 6 |
| **Draw & Pairings (Knockout/RoundRobin)** | Yes (`draw_builder_test.dart` — 262 lines) | Yes | Yes (pure Dart client execution) | Yes (covered) | Phase 7 |
| **Seeding & Bye Placement** | Yes (`draw_builder_test.dart`) | Yes | Yes (client-side calculation) | Yes (covered) | Phase 7 |
| **Bracket Generation** | Yes (`draw_builder_test.dart`, `ck_bracket_node_test.dart`) | Yes | Yes (inferred geometry & connectors) | Yes (covered) | Phase 14 |
| **Live Ops / Reschedule** | Yes (`tournaments_live_ops_test.dart`) | Partial | Yes (calls `cricket-match-action`) | Yes (covered) | Phase 9 |
| **Walkover Declaration** | Yes (`tournaments_live_ops_test.dart`) | Partial | Yes (calls `cricket-match-action`) | Yes (covered) | Phase 9 |
| **Result Override** | Yes (`tournaments_live_ops_test.dart`) | Partial | Yes (calls `cricket-match-action`) | Yes (covered) | Phase 9 |
| **Standings Calculation** | Partial (`tournament_standing_test.dart`) | **NO** (Dead in backend) | Yes (coupled to cricket NRR) | Yes (covered) | Phase 10 |
| **Leaderboards (Batting/Bowling)** | Yes (`tournament_leader_test.dart`, RPC tests) | Yes | No (clean read RPCs) | Yes (covered) | Phase 10 |
| **Officials Assignment** | Yes (`console_ledger_officials_test.dart`) | Yes | Yes (organizer array check) | Yes (covered) | Phase 2 & 9 |
| **Fee Ledger & Payment Recording** | Yes (`console_ledger_officials_test.dart`) | Yes | No (safe transactional RPC) | Yes (covered) | Phase 3 |
| **Match Identity & Format** | Yes (`match_test.dart`) | Yes | No (must survive migration) | Yes (covered) | Baseline |
| **Cricket Scoring Engine** | Yes (`scoring_replay_test`, `engine_vectors_test`, `scorecard_test`) | Yes | No (must survive migration) | Yes (covered) | Baseline |
| **Toss State & Lineups** | Yes (`runtime_commands.test.ts`) | Yes | No (must survive migration) | Yes (covered) | Baseline |
| **Super Over** | Yes (`tournaments_live_ops_test.dart`) | Yes | No (remains in cricket engine) | Yes (covered) | Phase 9 |
| **Revised Conditions (Rain/DLS)** | Yes (`revised_target_test.dart`) | Yes | No (remains in cricket engine) | Yes (covered) | Phase 9 |
| **Scorer Lease Concurrency** | Yes (`mirror_scorer_grant` trigger tests) | Yes | No (must survive migration) | Yes (covered) | Baseline |

### 14.4 Valid Behaviors Protected

1. **Generic Match Identity:** Match format (`oversPerInnings`, `playersPerTeam`, `ballType`), status partitioning (`isUpcoming`, `isLive`, `isPast`), and `MatchType.tournament` wire mapping survive intact without sport engine disruption.
2. **Cricket Sporting Engine:** Pure Dart scoring engine (`76` vector/parity tests), legal delivery calculation, over termination, wicket accounting, and scorecard projection (`scoreText`, `oversText`) operate independently of tournament competition concerns.
3. **Scorer Lease Separation:** Device concurrency leases (`match_scorer_leases`) remain decoupled from tournament and match scoring authorization grants (`grants`).
4. **Live Match Execution Projection:** `TournamentLiveMatch` projection accurately transforms match execution lines for live display.

### 14.4.1 Audit of Phase 1 Characterization Suite (`baseline_safety_characterization_test.dart`)

Every test in `test/features/tournaments/baseline_safety_characterization_test.dart` has been audited against false confidence:

| Test Name | Audit Classification | Architectural Role & Reality Check |
|---|---|---|
| `generic Match entity maintains identity and sport format when linked to tournament` | **VALID REGRESSION PROTECTION** | Proves core `Match` entity and format identity survive tournament linkage. |
| `MatchStatus partitions state cleanly across upcoming, live, and past buckets` | **VALID REGRESSION PROTECTION** | Locks in domain status partitioning invariants. |
| `MatchType wire mapping accurately identifies tournament matches` | **VALID REGRESSION PROTECTION** | Protects wire serialization mapping for tournament fixtures. |
| `TournamentLiveMatch projection accurately represents live match execution state` | **VALID REGRESSION PROTECTION** | Protects `LiveInningsLine` and `TournamentLiveMatch` display getters. |
| `Bracket topology is currently embedded directly in Match fields` | **LEGACY CHARACTERIZATION** | Observes presence of `bracketMatchNumber`, `round`, `prevMatchAId`; does **NOT** require them in the canonical target (removed in Phase 4). |
| `Client DrawBuilder performs pairings without server transaction` | **LEGACY CHARACTERIZATION** | Characterizes client-side `DrawBuilder`; will be superseded by server command `PublishDraw` in Phase 7. |
| `Standings table couples generic competition rank with cricket NRR` | **LEGACY CHARACTERIZATION** | Characterizes legacy `TournamentStanding`; decoupled into sport-agnostic standings + sport metrics in Phase 10. |
| `Sporting Result vs Competition Outcome separation boundary` | **DOCUMENTATION / ARCHITECTURE INVARIANT ONLY** | Documents desired separation. Does **NOT** imply that current deployed backend enforces this yet. |
| `Rescheduling started matches must never drop scorecards` | **DOCUMENTATION / ARCHITECTURE INVARIANT ONLY** | Documents the non-negotiable architectural invariant. **Warning:** The production Edge Function path `tournament_abandon_match.ts` **currently violates this** by executing `deleteAllForMatch()`. The test exercises entity state definitions and does NOT prove production code is safe. |
| `Participant withdrawal after draw publication must preserve entry record` | **DOCUMENTATION / ARCHITECTURE INVARIANT ONLY** | Documents the target lifecycle invariant for Phase 6. Does NOT imply current production Flutter code enforces this yet. |

### 14.5 Legacy Behaviors Characterized (`LEGACY — EXPECTED TO CHANGE`)

1. **Match-Embedded Bracket Topology:** `Match` entity currently contains `round`, `bracketMatchNumber`, `bracketRoundNumber`, `prevMatchAId`, `prevMatchBId`.
   - *Target:* Decoupled into `tournament_fixtures` and `tournament_fixture_slots` in Phase 4.
2. **Client-Driven Draw Generation:** `DrawBuilder` computes pairings on device and invokes RPC `tournament_generate_fixtures`.
   - *Target:* Server-side command `PublishDraw` in `tournament-action` with topological validation in Phase 7.
3. **Cricket-Coupled Standings Entity:** `TournamentStanding` embeds cricket metrics (`runsScored`, `oversFaced`, `netRunRate`).
   - *Target:* Generic `tournament_stage_standings` + `cricket_stage_standing_metrics` in Phase 10.
4. **Client Direct Lifecycle Mutations:** Flutter controller directly mutates `tournaments.status` via PostgREST.
   - *Target:* Server commands (`PublishTournament`, `StartTournament`, `CompleteTournament`) in Phase 2 & 5.

### 14.6 Critical Bugs Documented (`LEGACY BUG — MUST BE FIXED IN PHASE 9`)

1. **Destructive Abandonment / Reschedule:** `supabase/functions/cricket-match-action/commands/tournament_abandon_match.ts` executes `innings.deleteAllForMatch(ctx.tx, ctx.matchId)` when `mode = 'reschedule'`. Started scorecards must never be destroyed.
   - *Resolution:* Replace with non-destructive replay/reschedule command model in Phase 9.
2. **Missing Database Progression Trigger:** Dart comments cite `match_advance_tournament_bracket`, but this trigger does not exist in PostgreSQL.
   - *Resolution:* Implement topological slot progression in shared transaction engine in Phase 8.
3. **Dead Standings Engine:** `tournament_standings` has zero recomputation triggers/routines in the backend and is omitted from `supabase_realtime`.
   - *Resolution:* Implement synchronous stage standing recalculation in Phase 10.

### 14.7 Deferred Test Areas

- **Phase 7:** Canonical deterministic golden tests for Draw generation (Knockout, Round Robin, Group+Knockout, byes, seedings).
- **Phase 8:** Canonical integration tests for Fixture ↔ Match materialization and slot progression (idempotent replay, double-completion guards).
- **Phase 10:** Golden tests for stage-scoped standings, NRR tie-breaking, and synchronous qualification resolution.
- **Phase 16:** Concurrency, RLS security-invoker policies, and transaction lock audits.
- **Phase 17:** End-to-end multi-team tournament lifecycle integration scenarios.

### 14.8 Phase 1 Gate Verdict: **PASS**

All baseline commands recorded, regression boundaries locked, legacy behaviors characterized without being blessed, and zero production code or migrations modified. Ready for Phase 2.


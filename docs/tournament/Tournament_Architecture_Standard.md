Yes. Your clarification changes an important part of the standard: **a tournament-linked match and a standalone 1-to-1 match must not share the same authority policy**, even though both ultimately use the same cricket match/scoring engine.

So we should settle this first before moving to tournament structure terminology.

# Step 1 — Match ownership and authority

The first thing I want us to stop doing is using the word **owner** for several different concepts.

For a match, there are really four separate questions:

```text
1. Who caused this match to exist?
        → provenance

2. Who governs this match?
        → authority root

3. Who currently has permission to perform an action?
        → authorization

4. Who is actively entering the score right now?
        → operational control / scorer lease
```

These are not the same thing.

That distinction is especially important for Matchday.

---

## A. Two fundamentally different match contexts

I would define them as:

```text
MATCH
│
├── Tournament-managed match
│      tournament_id != null
│
└── Standalone match
       tournament_id == null
       ├── 1-to-1 friendly/challenge
       └── practice
```

I would **not** create two completely different match engines.

Both should continue using:

```text
Match
   ↓
Sport match state
   ↓
Cricket match
   ↓
Toss
   ↓
Lineup/Openers
   ↓
Scoring
   ↓
Result
```

The difference is:

> **Where does authorization come from?**

---

# Tournament match

For a tournament fixture:

```text
Tournament
      │
      │ governs
      ▼
Tournament Fixture / Match
      │
      ▼
Cricket Match Engine
```

The authority root is the **Tournament**.

Not Team A.

Not Team B.

Not whoever happened to create the `matches` row.

That gives us the first major invariant:

> **When `tournament_id` exists, team membership alone must never grant tournament match operational authority.**

That is the rule I think matches what you just explained.

---

# Standalone 1-to-1 match

For your normal team-vs-team flow:

```text
Team A ───────┐
              │
              ▼
            Match
              ▲
              │
Team B ───────┘
```

There is no tournament above it.

Therefore match authority has to come from:

```text
participating teams
+
match-specific grants
+
current workflow stage
```

And this is very close to what you have already implemented.

---

# The current implementation actually has a good foundation

I checked the current `main` implementation again.

Your `Match` entity already makes an important distinction:

```dart
createdBy
```

is separate from:

```dart
setupTeamId
```

and the comments explicitly say:

> `setupTeamId` is not the same thing as `createdBy`.

That is correct.

You also already have:

```text
cricket.match.setup
match.score
match.official.assign
match.cancel
```

as capabilities.

And your standalone Match Start flow already changes operational authority according to the match phase:

```text
Before toss
   ↓
setup_side controls setup

Toss recorded
   ↓
batting side becomes setup authority

Match becomes live
   ↓
match.score controls scoring
```

That model makes sense for the standalone match.

**The mistake would be applying the same authority derivation to tournament matches.**

---

# The authority matrix should therefore look like this

| Concern | Standalone 1-to-1 | Tournament match |
|---|---|---|
| Parent authority | Participating teams | Tournament |
| `created_by` | Audit/provenance | Audit/provenance |
| Toss authority | Authorized setup-side team / match grant | Tournament owner/manager or assigned scorer |
| Match Start | Phase-based team authority | Tournament operational authority |
| Scoring | Batting-team authorized member or assigned scorer | Tournament owner/manager or assigned scorer |
| Team captain automatically scores | Potentially yes | **No** |
| Team manager automatically scores | Potentially yes | **No** |
| Assigned scorer | Match-scoped | Match-scoped |
| Assign scorer | Authorized team/host policy | Tournament authority |
| Reschedule | Standalone match policy | Tournament authority |
| Cancel | Standalone match policy | Tournament authority |
| Walkover | Generally not ordinary team action | Tournament authority |
| Result override | Very restricted standalone authority | Tournament authority + audit |
| Tournament progression | None | Tournament engine consumes result |

This is the distinction I recommend we freeze.

---

# Tournament owner and manager

Your other important point is:

> The tournament owner/manager should be able to do everything, including scoring.

I agree with that product model.

But I would represent this as **capabilities**, not as dozens of special checks such as:

```dart
if (isTournamentOwner) ...
```

Conceptually:

```text
Tournament Owner
        │
        ├── tournament.manage
        ├── tournament.registration.manage
        ├── tournament.draw.manage
        ├── tournament.fixture.manage
        ├── tournament.official.assign
        ├── tournament.result.override
        ├── tournament.complete
        │
        └── operational authority over tournament matches
```

The owner is the root administrator.

Then:

```text
Tournament Manager
```

gets a configurable/default bundle of tournament capabilities.

Perhaps v1 simply gives the manager nearly everything except things like:

```text
transfer ownership
delete tournament permanently
remove original owner
```

We can settle the precise capability matrix when we reach the **Authority Model** step.

---

# But here's an important distinction: permission to score ≠ active scorer

Suppose the tournament owner and three managers all technically have permission to score.

We absolutely do **not** want four phones recording balls simultaneously.

Therefore:

```text
AUTHORIZATION

Owner ───────┐
Manager ─────┼──► May score this match
Scorer ──────┘


OPERATIONAL CONTROL

              ┌────────────────────┐
              │ Active scorer lease │
              │     ONE device      │
              └────────────────────┘
```

This fits beautifully with the `match_scorer_leases` system you already have.

So:

> **Many people may be authorized; only one scorer session should actively write at a time.**

That gives the tournament owner emergency control without sacrificing consistency.

For example:

```text
Assigned scorer loses internet / leaves
             ↓
Tournament manager opens match
             ↓
"Take over scoring"
             ↓
Existing scorer lease is handed over
             ↓
Audit event recorded
             ↓
Manager continues
```

Much better than saying only the assigned scorer can ever touch it.

---

# Who should perform the toss in a tournament?

Based on the workflow you've described, I think tournament matches should work differently from standalone matches here too.

### Standalone

Your existing idea is:

```text
Host/setup authority
      ↓
records physical toss
      ↓
winner chooses bat/bowl
      ↓
batting side becomes relevant setup authority
```

Fine.

### Tournament

I would make it:

```text
Tournament scorer / tournament manager
             ↓
         Record toss
             ↓
Tournament scorer / manager
             ↓
Confirm batting/bowling
             ↓
Select/confirm opening players
             ↓
Start match
             ↓
Score both innings
```

The scorer is neutral operational authority.

Team A doesn't suddenly receive backend scoring authority because Team A is batting.

Team B doesn't receive it when Team B bats.

That would be wrong for your tournament model.

---

# What should teams do then?

Teams still have important responsibilities.

But participation is different from match administration.

For example, later we might allow:

```text
Team Manager
      ↓
submit playing XI

Captain
      ↓
confirm players / captain / keeper
```

Then:

```text
Tournament Scorer
      ↓
uses submitted XI
      ↓
records toss
      ↓
selects openers
      ↓
starts/scorers match
```

The team can provide **input** without receiving **operational control**.

That's an important boundary.

We may eventually need separate capabilities such as:

```text
match.lineup.submit
match.lineup.confirm
```

instead of abusing:

```text
cricket.match.setup
```

for everything.

But that is something we can decide when we model tournament match-day operations.

---

# There is one conflict in the current backend

This matters because we now know the intended product rule.

Your current deployed:

```text
_can_score_innings(...)
```

allows scoring when any of these are true:

```text
practice match creator

OR captain of batting side

OR batting team's match.score permission

OR match-scoped match.score grant
```

There is currently no first branch saying:

```text
IF tournament match
    use tournament scoring authority
ELSE
    use team/standalone scoring authority
```

So today a tournament-linked match can still inherit scoring permission from the batting team's captain/manager/owner.

That is contrary to what you've just defined.

We should **not fix it yet**, because we're still writing the standard.

But we've now identified the expected rule.

The good news is that your current architecture already has the other half of what we need:

```text
match_officials
        │
        │ role = scorer
        ▼
mirror_scorer_grant()
        │
        ▼
match-scoped match.score
```

So assigning a tournament scorer already maps nicely into match-scoped scoring permission.

We mainly need to make the **authority resolution context-aware**.

---

# The conceptual authorization algorithm

Eventually, I think the server-side reasoning should effectively be:

```text
authorizeMatchAction(user, match, action)

             │
             ▼
Does match have tournament_id?
       /                 \
     YES                 NO
      │                   │
      ▼                   ▼
TOURNAMENT POLICY     STANDALONE POLICY
      │                   │
      │                   ├── team capability
      │                   ├── setup_side
      │                   ├── batting-side authority
      │                   └── match grant
      │
      ├── tournament capability
      └── match-specific grant
```

The important part is what is deliberately absent from the left side:

```text
TOURNAMENT POLICY

❌ team_can(teamA, match.score)
❌ team_can(teamB, match.score)
```

They should not accidentally leak into tournament authority.

---

# Owner should still be able to score without being assigned as scorer

There are two reasonable designs here.

One is:

```text
Tournament owner must assign themselves as scorer first.
```

The other is:

```text
Tournament owner/manager already has permission to score,
but must acquire the active scorer lease.
```

For Matchday, I favor the second.

Why?

Imagine three grounds:

```text
Ground 1      Ground 2      Ground 3
Scorer A      Scorer B      Scorer C
```

One scorer disappears.

The tournament owner is standing at Ground 2.

They should be able to open that fixture and:

```text
Take over scoring
```

without first navigating through several administration screens merely to assign themselves.

The match still records:

```text
who entered every action
who held the scorer lease
who took over
when the takeover happened
```

So operational accountability remains.

---

# What `created_by` should mean

This is worth freezing too.

I don't want:

```text
matches.created_by
```

to mean:

> This person owns this match.

It should mean:

> This person/process originated the match record.

For tournament fixtures the creator could be:

```text
tournament fixture generator
tournament organizer
server command
```

but authorization shouldn't depend on it.

Similarly:

```text
toss_recorded_by
```

means:

> Who recorded the toss.

It does **not** mean:

> Who owns the match.

And:

```text
setup_side
```

means:

> Workflow authority for a standalone match setup stage.

It does **not** mean:

> Match owner.

Those semantics should stay clean.

---

# Tournament result finalization is also different

For standalone:

```text
Match Completed
      ↓
Result finalized
      ↓
Match becomes historical
```

Tournament:

```text
Tournament Match Completed
          ↓
Authoritative result finalized
          ↓
Tournament Engine receives result
          ↓
   ┌──────┼────────┐
   ▼      ▼        ▼
Standings Bracket Stats
   │      │
   │      └── next fixture participant
   │
   └── qualification position
```

So the tournament match isn't merely a match with a badge saying tournament.

Its result has downstream consequences.

That means tournament result correction also needs to be more restricted.

Changing a semifinal result may affect:

```text
final participant
tournament standings
player statistics
champion
awards
notifications
```

Hence later we'll define a proper audited **result amendment** model rather than just `UPDATE winner_side`.

---

# There is precedent for making this competition-controlled

PlayHQ explicitly allows competition administrators to configure whether clubs can enter scores or use electronic scoring. In other words, team-side scoring is a competition policy rather than something that inherently follows from being a participating team. :chatgpt-content-reference{index="0"}

For Matchday we can initially be stricter:

```text
Standalone Match
    Team-scoring model

Tournament Match
    Tournament-scoring model
```

We don't need to expose a toggle yet.

Later, if tournament organizers ever ask for:

> Let participating clubs score their own matches

we could add that deliberately as a tournament policy.

We should **not** accidentally support it because `team_can()` happened to return true.

---

# So these are the Step-1 rules I recommend freezing

1. **A match has an authority root, not a universal “owner.”** Tournament-linked matches inherit governance from the tournament; standalone matches inherit governance from participating teams and match-specific grants.

2. **`created_by` is provenance, never authorization.**

3. **`tournament_id != null` switches the match into tournament authority policy.** The tournament relationship should be the authoritative signal, rather than relying only on a duplicated label such as `match_type = tournament`.

4. **Tournament teams do not automatically receive `cricket.match.setup` or `match.score`.** Captain/manager/owner status inside Team A or Team B does not authorize tournament scoring.

5. **Tournament owner and authorized tournament managers may operate any tournament match.** This includes setup, toss, scoring and operational recovery, subject to lifecycle constraints.

6. **An assigned scorer receives match-scoped operational authority.** They do not automatically receive tournament-management powers.

7. **Exactly one scorer/device actively writes at a time.** Authorization and scorer lease are separate concepts.

8. **Teams may eventually submit or confirm their lineup without controlling scoring.** Participation capabilities and operational capabilities remain separate.

9. **Standalone 1-to-1 matches keep the phase-based authority system you already built.** `setup_side`, batting-side setup authority, team capabilities and match grants remain meaningful there.

10. **A tournament result becomes an input to the Tournament Engine.** Standings, qualification and bracket progression are tournament responsibilities; ball-by-ball scoring and sport-specific result calculation remain Match Engine responsibilities.

That gives us a very strong boundary.

And importantly, it means we **do not need two cricket engines**. We need **one cricket engine with two authority policies around it**.

---

## The next step should be Tournament Structure Terminology

Now that the parent/child relationship is becoming clear, the next discussion should establish exact meanings for:

```text
Tournament
Competition
Stage
Group / Pool
Round
Fixture
Match
Bracket
Seed
Slot
Bye
Qualifier
Standing / Ladder
Finals
```

And there is one particularly important ambiguity we need to solve there:

```text
Round Robin
vs
League
```

because the current system treats both as `tournament_type` values, but mathematically/product-wise they are not necessarily the same kind of concept.

Challonge's current model is useful evidence here: it treats formats such as single elimination and round robin as **stage formats**, and supports multi-stage competitions where one stage feeds another—for example, round-robin groups feeding a single-elimination final stage. :chatgpt-content-reference{index="1"}

That is very close to where I think Matchday's structure model should go.

So I would make **Tournament Structure Terminology** our Step 2 and settle those words and relationships before touching the lifecycle or database.



Yes. Step 2 should give us a **canonical language** before we touch lifecycle or schema. After comparing the current Matchday model with established competition systems, I think our hierarchy should become:

```text
TOURNAMENT
   │
   ├── Stage 1
   │     ├── Group A (optional)
   │     │     ├── Round 1
   │     │     │     ├── Fixture
   │     │     │     └── Fixture
   │     │     └── Round 2
   │     │
   │     └── Group B (optional)
   │
   └── Stage 2
         ├── Quarter-final Round
         │     ├── Fixture
         │     └── Fixture
         ├── Semi-final Round
         └── Final Round
```

A **Match** is then the sport contest attached to a playable fixture.

That distinction will solve several ambiguities in the current implementation.

---

# 2.1 Tournament

The root entity should remain:

> **Tournament = one organized competitive event managed inside Matchday.**

Examples:

```text
Lahore Champions Cup 2027
Kasur Ramadan Cricket Cup
Punjab Corporate League 2027
Matchday Summer Championship
```

A tournament owns things such as:

```text
identity
sport
participants
registration
organizers
competition structure
stages
fixtures
venues
schedule
standings
qualification
champion
awards
```

A tournament does **not** directly define things such as:

```text
toss
innings
balls
wickets
goals
sets
sport-specific scoring
```

Those remain Match/Sport Engine responsibilities.

### Tournament is the container, not the format

This means I do **not** want:

```text
Tournament = Knockout
```

as the fundamental model.

Instead:

```text
Tournament
    ↓
Stage
    ↓
Single Elimination
```

That difference becomes extremely useful once we support:

```text
Group Stage
     ↓
Knockout Stage
```

under the same tournament.

---

# 2.2 Competition

This word needs special treatment because it can easily create another unnecessary entity.

I recommend:

> **Competition is a generic business/domain word, not a separate Matchday entity in v1.**

So we can say:

> “Tournament competition structure”

or:

> “This tournament is a competition between eight teams.”

But we do not need:

```text
competitions table
      ↓
tournaments table
```

right now.

PlayHQ uses a larger hierarchy of Competition → Season → Grade → Teams because it manages long-running sporting associations. :chatgpt-content-reference{index="0"}

Matchday does not need that complexity yet.

Our root remains simply:

```text
Tournament
```

Later, if Matchday supports:

```text
Lahore Premier League
   ├── Season 2027
   ├── Season 2028
   └── Season 2029
```

then we can introduce something above Tournament/Season deliberately.

But not now.

---

# 2.3 Stage — this should become first-class

This is perhaps the most important structural concept missing from the current model.

> **Stage = one phase of competition governed by one competition format.**

Examples:

```text
Stage 1 — Group Stage
Format: Round Robin

Stage 2 — Playoffs
Format: Single Elimination
```

or simply:

```text
Stage 1 — Knockout
Format: Single Elimination
```

for an 8-team weekend cup.

This pattern is also how mature tournament systems model multi-phase competitions. Challonge supports stages such as round-robin groups feeding an elimination stage, while Toornament explicitly models tournaments as one or more stages/phases. :chatgpt-content-reference{index="1"}

## Stage owns a format

For example:

```text
Tournament
└── Stage: Group Stage
      format = round_robin
```

or:

```text
Tournament
└── Stage: Finals
      format = single_elimination
```

Possible stage formats over time:

```text
single_elimination
round_robin
double_elimination
swiss             future
```

Potentially others later.

---

# 2.4 This solves our current `tournament_type`

Today the database has:

```text
tournament_type

knockout
round_robin
league
group_knockout
double_elimination
```

There are actually three different kinds of concepts mixed together here.

### `knockout`

This is really:

```text
Stage format:
single_elimination
```

### `round_robin`

This is genuinely a stage format:

```text
Stage format:
round_robin
```

### `double_elimination`

Also a stage format:

```text
Stage format:
double_elimination
```

### `group_knockout`

This is **not a format**.

It is a structure composed of multiple stages:

```text
Tournament
│
├── Group Stage
│     format = round_robin
│
└── Knockout Stage
      format = single_elimination
```

That is a major distinction.

### `league`

This one deserves special treatment.

---

# 2.5 Round Robin vs League

You specifically had both in the current model:

```text
round_robin
league
```

I don't think those should both remain structural primitives.

## Round Robin is mathematical

Round robin means every participant plays every other participant a configured number of times.

### Single round robin

Four teams:

```text
A vs B
A vs C
A vs D
B vs C
B vs D
C vs D
```

Each pairing occurs once.

### Double round robin

Each pairing happens twice:

```text
A vs B
B vs A
```

etc.

Challonge similarly describes Round Robin as every participant meeting the others, with 2x or 3x variants possible. :chatgpt-content-reference{index="2"}

Therefore our stage can simply have something like:

```text
format = round_robin

cycles / legs = 1
```

or:

```text
cycles / legs = 2
```

---

# League is a product concept

“League” generally communicates:

```text
longer-running competition
points table
scheduled rounds
standings
winner determined from table
possibly home/away fixtures
possibly playoffs afterwards
```

But structurally its regular season may simply be:

```text
Round Robin × 2
```

Therefore I recommend:

> **League should not be a core stage format.**

Instead it can become either a **user-facing tournament template** or a **competition style**.

Example:

```text
User chooses:

"League"
```

Matchday can create:

```text
Tournament
└── Regular Season
      format = round_robin
      cycles = 2
      ranking = points_table
```

And a league with playoffs becomes:

```text
Tournament
│
├── Regular Season
│     format = round_robin
│     cycles = 2
│
└── Playoffs
      format = single_elimination
```

Now everything is mathematically precise.

---

# 2.6 Templates vs structure

This separation is very useful for UX.

The organizer does **not** need to understand our internal stage engine.

The Create Tournament screen could offer:

```text
QUICK SETUPS

Knockout Cup
8/16 teams · Lose once and you're out

Round Robin
Everyone plays everyone

League
Points table across scheduled rounds

Groups + Knockout
Groups first, then qualifiers enter playoffs
```

But internally:

```text
Knockout Cup
        ↓
1 × single_elimination stage


Round Robin
        ↓
1 × round_robin stage


League
        ↓
1 × round_robin stage
+ league defaults


Groups + Knockout
        ↓
Stage 1 round_robin
Stage 2 single_elimination
```

That gives users simple choices without corrupting the domain model.

This is one of the strongest changes I would make to the current standard.

---

# 2.7 Group

A **Group** is:

> A subset of tournament participants competing together inside a stage.

For example:

```text
Group Stage
│
├── Group A
│     Pakistan Lions
│     Lahore Stars
│     Kasur Kings
│     Falcon XI
│
└── Group B
      ...
```

The important relation is:

```text
Group belongs to Stage
```

not directly:

```text
Group belongs only to Tournament
```

because potentially a tournament could have groups in more than one stage.

---

# Group vs Pool

I recommend that Matchday uses **Group** exclusively inside tournaments.

Do not use the terms interchangeably in our code.

Why?

Because Matchday already has another concept called:

```text
Match Pool
```

for open challenges/matches.

Using:

```text
Tournament Pool
Match Pool
Pool Request
```

would become confusing very quickly.

Therefore:

```text
Tournament → Group
```

always.

UI:

```text
GROUP A
GROUP B
GROUP C
```

Domain:

```text
TournamentGroup
```

No tournament `Pool`.

---

# 2.8 Round

This is another area where the current database mixes concepts.

A **Round** should mean:

> A logical progression or scheduling unit inside a stage or group.

For a round robin:

```text
Stage: Regular Season

Round 1
  Lahore vs Kasur
  Falcon vs Titans

Round 2
  Lahore vs Falcon
  Kasur vs Titans
```

For knockout:

```text
Stage: Playoffs

Round 1 — Quarter-finals
Round 2 — Semi-finals
Round 3 — Final
```

So:

```text
Quarter-final
Semi-final
Final
```

are **round names**.

They are not fundamentally different stages.

---

# This exposes a current terminology issue

Your current database has:

```text
match_stage

group
quarter_final
semi_final
final
playoff
```

This mixes two hierarchical levels.

`group` can describe a stage context.

But:

```text
quarter_final
semi_final
final
```

are rounds within a knockout stage.

So today:

```text
stage = semi_final
```

is conceptually misleading.

The cleaner model is:

```text
stage:
    Playoffs

round:
    Semi-final

round_number:
    2
```

or:

```text
stage_id = playoff_stage_id
round_number = 2
round_label = "Semi-final"
```

We are not changing the schema yet, but this is something our eventual schema review should address.

---

# 2.9 Fixture

This is another very important distinction.

I define:

> **Fixture = a scheduled or structurally defined contest within a tournament.**

A fixture belongs to the tournament structure.

Example:

```text
Semi-final 1

Winner of QF1
        vs
Winner of QF2

Saturday · 4:00 PM
Ground 1
```

Notice something important.

At the moment that fixture is created, we may **not know the teams yet**.

And that's okay.

The fixture still exists.

---

# 2.10 Match

A **Match** is:

> The actual sport contest executed through Matchday's Match Engine.

So conceptually:

```text
Fixture
   │
   │ becomes playable
   ▼
Match
   │
   └── Cricket Engine
```

For example:

```text
FIXTURE

Semi-final 1
Winner QF1 vs Winner QF2
4 PM · Ground 1
```

Later QF1/QF2 complete:

```text
FIXTURE

Semi-final 1
Kasur Kings vs Lahore Lions
4 PM · Ground 1
```

Now the cricket match operates:

```text
toss
lineups
innings
balls
result
```

---

# Why Fixture and Match should be separate concepts

Today the implementation creates `matches` even for unresolved future bracket slots.

I checked `tournament_generate_fixtures()`.

It currently creates all match shells first and uses:

```text
prev_match_a_id
prev_match_b_id
```

to represent feeder relationships.

That works technically.

But conceptually it is combining:

```text
Tournament Fixture
+
Sport Match
```

into one record.

There are advantages and disadvantages to that.

I am **not yet recommending we create a new table**, but our domain terminology should remain separate.

Because these are different questions:

### Fixture asks

```text
Where in the competition is this contest?
Who feeds into it?
When is it scheduled?
Where is it played?
What round is it?
```

### Match asks

```text
Who is playing?
What are the rules?
Has toss happened?
Who is batting?
What's the score?
What is the result?
```

That distinction will matter massively when we introduce other sports.

---

# 2.11 Slot

A **Slot** is:

> One participant position inside a fixture.

Every normal head-to-head fixture has:

```text
Slot A
Slot B
```

A slot's source can be different.

### Direct team

```text
Slot A = Lahore Lions
```

### Winner feeder

```text
Slot A = Winner of QF1
```

### Loser feeder

For third-place matches:

```text
Slot A = Loser of SF1
```

### Qualification source

```text
Slot A = Group A Position 1
```

### Seed

```text
Slot A = Seed #1
```

This gives us a very general model.

For example:

```text
FINAL

Slot A:
    source = winner(SF1)

Slot B:
    source = winner(SF2)
```

Then the tournament engine resolves those sources.

This is much cleaner than hardcoding every possible progression rule.

---

# 2.12 Seed

Seed should mean only:

> The initial competitive ordering assigned to participants before placement into a structured stage.

For example:

```text
Seed 1 — Lahore Lions
Seed 2 — Kasur Kings
Seed 3 — Falcons
Seed 4 — Titans
```

It should not mean current ranking.

This distinction matters.

```text
SEED
pre-competition placement

RANK
current/final position based on results
```

These are completely different concepts.

---

# 2.13 Bracket

A **Bracket** is not the tournament itself.

It is:

> A visual/logical representation of an elimination stage and its progression paths.

For:

```text
Stage
format = single_elimination
```

we can derive:

```text
Bracket
```

from:

```text
Rounds
Fixtures
Slots
Feeder relationships
```

So ideally the bracket is not the canonical source of truth.

The canonical data is:

```text
Stage
  → Round
     → Fixture
        → Slots
           → Sources
```

and:

```text
Bracket = projection / visualization
```

That is a very important architectural principle.

---

# 2.14 Bye

A **Bye** means:

> A participant advances through a competition position without playing an opponent.

Example with six teams in an eight-team knockout:

```text
Seed 1 ─────┐
            ├── BYE → Semi-final
EMPTY ──────┘
```

A bye is **not**:

```text
walkover
cancelled match
no-result
abandoned match
```

Those are completely different.

### Bye

Known at draw construction time.

No contest occurs.

### Walkover

A contest was expected, but one side receives progression/result because the opponent did not compete or was ruled unable to compete.

We should keep those strictly separate.

---

# 2.15 Walkover

A walkover is:

> An administrative match outcome where a participant is awarded the fixture without normal sporting completion.

Example:

```text
Team B fails to appear.

Organizer:
Declare Walkover

Winner:
Team A
```

It is an actual tournament operational decision.

It may affect:

```text
progression
points
standings
statistics policy
audit history
```

depending on the sport/rules.

---

# 2.16 Qualification

Qualification means:

> A participant earns entry into another stage or round according to defined progression criteria.

Examples:

```text
Top 2 from Group A
Top 2 from Group B
```

feed:

```text
Semi-finals
```

For example:

```text
SF1
Group A #1
vs
Group B #2

SF2
Group B #1
vs
Group A #2
```

Notice how our Slot Source model handles this beautifully:

```text
slot_a.source =
group_position(Group A, 1)

slot_b.source =
group_position(Group B, 2)
```

---

# 2.17 Standing

A **Standing** is:

> The computed competitive record of a participant inside a standings-based stage or group.

Examples:

```text
P
W
L
T
NR
Pts
NRR
Rank
```

for cricket.

But this needs a multi-sport boundary.

The tournament core should understand:

```text
rank
points
played
position
qualification status
```

while sport-specific ranking metrics may include:

```text
Cricket:
NRR

Football:
goal difference

Other sport:
set ratio
point difference
```

We'll handle that more deeply in Step 3: Multi-Sport Boundary.

---

# 2.18 Ladder vs Standings

I recommend Matchday use:

```text
Standings
```

as the canonical term.

Some systems such as PlayHQ use **Ladder** for the ranked table. :chatgpt-content-reference{index="3"}

But internationally and across multiple sports:

```text
Standings
```

is easier to understand.

So:

```text
Domain:
TournamentStanding

UI:
Standings
```

No need for both `ladder` and `standings`.

---

# 2.19 Ranking

Rank means:

> A participant's ordered position inside a standings context.

Example:

```text
1 Lahore Lions
2 Falcons
3 Kings
4 Titans
```

Rank is calculated.

Seed is assigned.

Again:

```text
seed != rank
```

Very important.

---

# 2.20 Finals vs Final

These should also be standardized.

### Final

One championship-deciding fixture:

```text
Final
Lahore vs Kasur
```

### Finals / Playoffs

A set of elimination rounds:

```text
Playoffs
├── Quarter-finals
├── Semi-finals
└── Final
```

I prefer the canonical structural term:

```text
Playoffs Stage
```

because “Finals” can mean different things in different countries/sports.

UI can still say:

```text
Finals
```

where culturally appropriate.

But internally:

```text
stage_kind = playoffs
```

would be clearer.

---

# 2.21 Third-place match

This should not require its own tournament type or stage.

It is simply an optional fixture within the elimination stage.

Its slots are:

```text
Loser SF1
vs
Loser SF2
```

This again shows why slot sources are powerful.

---

# 2.22 Structure vs Format

We need two separate terms.

### Stage Format

Defines how participants compete inside a stage:

```text
single_elimination
round_robin
double_elimination
swiss
```

### Tournament Structure

Describes the composition of stages:

```text
Single-stage knockout

Single-stage round robin

Group stage → knockout stage

League stage → playoffs
```

Therefore:

```text
FORMAT = behavior of one stage

STRUCTURE = arrangement of stages
```

This is the vocabulary I want us to use going forward.

---

# 2.23 Match Format is something completely different

Because cricket already uses the word format:

```text
T20
ODI
10-over
custom
```

we have to be extremely careful.

I suggest these exact terms:

```text
Competition Format
    single_elimination
    round_robin

Sport Match Format
    T20
    T10
    ODI
```

Not simply:

```text
format
```

when speaking across domains.

Otherwise we'll end up with:

```dart
tournament.format
stage.format
match.format
```

all meaning unrelated things.

Toornament explicitly has this same hierarchy problem and allows match-format configuration at tournament, stage, group, round and match levels. :chatgpt-content-reference{index="4"}

For Matchday I would be more explicit in naming.

---

# 2.24 Default sport match format vs fixture override

This is worth putting into the terminology standard now.

Tournament can define:

```text
default match rules
```

For example:

```text
Tournament default:
T20
20 overs
4 overs per bowler
```

Stages can override:

```text
Group Stage:
T20
```

and perhaps later:

```text
Final:
25 overs
```

Therefore the conceptual inheritance becomes:

```text
Tournament sport defaults
        ↓
Stage override
        ↓
Round override (rare)
        ↓
Fixture/Match override
```

I would probably keep v1 UI much simpler than this, but the domain shouldn't block it.

---

# 2.25 Participant

One additional term we should establish.

At tournament-core level:

> **Participant = entity competing in the tournament.**

Today Matchday tournaments are team-based:

```text
Participant = Team
```

But using the generic term inside the competition engine helps us later support:

```text
individual tennis
chess
badminton singles
racing
```

without redesigning the entire structure engine.

However, don't over-abstract the current DB prematurely.

For Matchday v1:

```text
TournamentEntry
    → Team
```

is perfectly fine.

The structural engine can conceptually call it a participant.

---

# 2.26 Tournament Entry

This comes from our previous discussion and belongs in the vocabulary too.

> **Tournament Entry = an accepted participant's membership in a tournament.**

So:

```text
Team
```

is a global Matchday entity.

But:

```text
Lahore Lions participating in Tournament X
```

is a:

```text
TournamentEntry
```

That entry can own:

```text
seed
group assignment
squad
registration metadata
payment status
entry status
qualification status
```

This is cleaner than attaching tournament-specific state directly to the global Team.

---

# The canonical hierarchy

Putting all of that together:

```text
Tournament
│
├── Tournament Entries
│     ├── Team A
│     ├── Team B
│     ├── Team C
│     └── Team D
│
└── Stages
      │
      ├── Stage 1
      │     format: round_robin
      │
      │     ├── Group A
      │     │     ├── Round 1
      │     │     │     ├── Fixture
      │     │     │     └── Fixture
      │     │     └── Round 2
      │     │
      │     └── Group B
      │
      └── Stage 2
            format: single_elimination
            │
            ├── Round 1: Semi-finals
            │     ├── Fixture
            │     └── Fixture
            │
            └── Round 2: Final
                  └── Fixture
```

And below the fixture:

```text
Fixture
│
├── Slot A
│     source:
│     Group A position 1
│
├── Slot B
│     source:
│     Group B position 2
│
└── Match
      │
      └── Cricket Match
            ├── Toss
            ├── Players
            ├── Innings
            ├── Deliveries
            └── Result
```

That is the model I think we should build toward.

---

# What this means for current Matchday terminology

Without changing anything yet, I'd classify the existing model like this:

| Current | Canonical meaning |
|---|---|
| `tournaments` | Keep: Tournament |
| `tournament_type=knockout` | Better represented by single-elimination Stage |
| `tournament_type=round_robin` | Better represented by round-robin Stage |
| `tournament_type=league` | Tournament template/style, not structural primitive |
| `tournament_type=group_knockout` | Multi-stage structure/template |
| `tournament_type=double_elimination` | Stage format |
| `matches.stage=group` | Really Stage context |
| `matches.stage=quarter_final` | Really Round |
| `matches.stage=semi_final` | Really Round |
| `matches.stage=final` | Really Round |
| `matches.round` | Correct idea, but currently too free-form |
| `group_id` | Correct concept, but should belong structurally to a Stage |
| `seed_number` | Correct concept |
| `prev_match_a_id/b_id` | Existing feeder representation; conceptually Fixture Slot Source |
| `bracket_round_number` | Round order inside elimination stage |
| `bracket_match_number` | Fixture order within that round |

So the existing system isn't completely wrong.

In fact, it already contains many of the pieces.

The problem is that they're currently **flattened into tournaments and matches instead of being represented as a clear competition hierarchy**.

---

# The big structural outcome of Step 2

I would freeze these principles:

1. **Tournament is the root competitive event.**
2. **Competition is descriptive language for now, not another entity.**
3. **A Tournament contains one or more Stages.**
4. **Each Stage has exactly one Competition Format.**
5. **Single elimination, round robin and double elimination are Stage Formats.**
6. **Group + Knockout is a multi-stage Tournament Structure, not a format.**
7. **League is primarily a user-facing template/style, usually implemented with round-robin stages and optionally playoffs.**
8. **Groups belong to Stages.**
9. **Use `Group`, not `Pool`, because Matchday already has Match Pools.**
10. **Rounds belong to Stages/Groups; quarter-final, semi-final and final are round labels.**
11. **Fixtures belong to the tournament structure; Matches belong to the sport engine.**
12. **Fixture and Match remain conceptually separate even if v1 physically stores them together.**
13. **Fixture Slots describe how participants enter a fixture.**
14. **Bracket is a projection of elimination-stage fixtures, not the source of truth.**
15. **Seed is assigned pre-competition ordering; Rank is calculated competitive position.**
16. **Bye and Walkover are completely different concepts.**
17. **Qualification describes movement between stages/rounds.**
18. **Standings is our canonical ranked-table term.**
19. **Competition Format and Sport Match Format are separate concepts.**
20. **Tournament Entry represents a Team participating in one specific tournament.**

And the most important transformation is:

```text
OLD THINKING

Tournament Type
    = group_knockout


NEW THINKING

Tournament Structure
    │
    ├── Stage 1
    │     Round Robin
    │
    └── Stage 2
          Single Elimination
```

That structure is much more scalable, much easier to reason about, and considerably better suited to the multi-sport direction of Matchday. :chatgpt-content-reference{index="5"}

The next step in our sequence should be **Step 3 — Multi-Sport Boundary**. That is where we decide exactly which of these concepts belong to the universal Tournament Core and which belong to Cricket specifically—especially standings metrics, result semantics, match formats, ties/no-results, progression rules, and statistics.



Yes. Step 3 is where we make Matchday genuinely multi-sport rather than “Cricket with a `sport_id` column.”

The boundary I recommend is:

```text
TOURNAMENT CORE
      │
      │ asks sport layer questions
      ▼
SPORT COMPETITION ADAPTER
      │
      │ delegates gameplay
      ▼
SPORT MATCH ENGINE
```

The tournament core should understand **competition**. It should never need to understand what a wicket, over, goal, set, foul, super over, DLS target, or run rate is.

That becomes our central Step-3 rule.

---

# Step 3 — Multi-Sport Boundary

## 3.1 The three layers

I would formalize Matchday into three conceptual layers rather than only Tournament vs Match.

```text
┌───────────────────────────────────────────┐
│              TOURNAMENT CORE              │
│                                           │
│ Entries · Stages · Groups · Rounds        │
│ Fixtures · Scheduling · Qualification     │
│ Authority · Draw · Progression · Awards   │
│ Registration · Venues · Publishing        │
└──────────────────────┬────────────────────┘
                       │
                       │ generic contracts
                       ▼
┌───────────────────────────────────────────┐
│          SPORT COMPETITION ADAPTER        │
│                                           │
│ Result interpretation                     │
│ Points rules                              │
│ Ranking / tie-break rules                 │
│ Sport match configuration                 │
│ Competition statistics                    │
│ Sport-specific official roles             │
└──────────────────────┬────────────────────┘
                       │
                       ▼
┌───────────────────────────────────────────┐
│             SPORT MATCH ENGINE            │
│                                           │
│ Toss / Kickoff / Serve                    │
│ Lineup                                    │
│ Live scoring                              │
│ Cricket innings / Football goals / etc.   │
│ Sport rules                               │
│ Final sport result                        │
└───────────────────────────────────────────┘
```

This middle layer — the **Sport Competition Adapter** — is important.

Otherwise we end up putting things like NRR inside Tournament Core simply because NRR affects tournament standings.

NRR does affect the tournament, but it is still **Cricket knowledge**.

---

# 3.2 Tournament Core

The Tournament Core should be able to run a tournament without knowing which sport is being played.

For example, it understands:

| Tournament Core understands | Example |
|---|---|
| Tournament | Kasur Champions Cup |
| Tournament Entry | Team A entered |
| Stage | Group Stage |
| Competition format | Round Robin |
| Group | Group A |
| Round | Round 3 |
| Fixture | Team A vs Team B |
| Venue | Ground/Court/Stadium |
| Schedule | 8:00 PM |
| Seed | #3 |
| Qualification | Top 2 advance |
| Progression | Winner → Semi-final |
| Rank | Participant currently #1 |
| Match state | Scheduled / Live / Final |
| Winner | Entry A |
| Draw/tie existence | Result was tied |
| Administrative result | Walkover / cancelled / abandoned |
| Official assignment | Someone has role X |
| Authority | Organizer can perform action |
| Audit | Who changed what and when |

It should **not** understand why Team A won.

That's the sport engine's responsibility.

---

# 3.3 What Cricket owns

Cricket should own:

```text
T20
T10
ODI
20 overs
6 balls per over
4 overs per bowler
Leather / Tape / Tennis ball

Toss
Bat / Bowl
Playing XI
Striker
Non-striker
Bowler

Runs
Wickets
Extras
Overs
Innings

All out
Target
Required run rate
DLS/revised target

Super Over

Net Run Rate

Batting statistics
Bowling statistics
Orange/Purple-cap-like leaderboards
```

None of these should appear as concepts in the universal tournament domain.

That includes **Net Run Rate** even though tournaments use it heavily.

---

# 3.4 The current Matchday implementation already demonstrates the correct pattern in Matches

Your live Supabase schema currently has a shared:

```text
matches
match_teams
match_players
```

and then Cricket extends it:

```text
cricket_matches
cricket_match_players
cricket_match_innings
cricket_match_innings_state
```

That is a strong architecture.

Conceptually:

```text
MATCH CORE

matches
match_teams
match_players
      │
      │ sport_id = cricket
      ▼
CRICKET EXTENSION

cricket_matches
cricket_match_players
cricket_match_innings
balls
wickets
...
```

Football could eventually become:

```text
matches
match_teams
match_players
      │
      ▼
football_matches
football_match_players
football_events
```

without touching the universal match identity.

That is precisely the pattern I would extend into tournaments.

---

# 3.5 Where Tournament currently violates that boundary

There are several examples in today's code.

Your current:

`lib/features/tournaments/domain/entities/tournament.dart`

contains:

```dart
int get maxOvers => ...
String get ballType => ...
```

Those properties do not belong to `Tournament`.

They belong somewhere conceptually like:

```text
CricketTournamentConfiguration
```

or:

```text
CricketMatchRules
```

Likewise the current:

`TournamentStanding`

contains:

```text
runsScored
oversFaced
runsConceded
oversBowled
netRunRate
```

That makes `TournamentStanding` a Cricket standing despite its generic name.

And your current `TournamentsRepository` includes:

```text
reviseMatchConditions(...)
triggerSuperOver(...)
getLeaderboards(...)
```

with DLS/run-rate logic and Cricket-specific batting/bowling leaderboards.

Those are useful features.

The problem is only **where they live architecturally**.

They should eventually belong below the sport boundary rather than making `TournamentsRepository` itself Cricket-specific.

---

# 3.6 PlayHQ has reached essentially the same architectural problem

PlayHQ supports multiple sports and explicitly separates common competition configuration from sport-specific configuration. Its generic competition model includes things such as outcome points and ladder/ranking configuration, while Cricket gets additional concepts such as game type, overs and Super Over. :chatgpt-content-reference{index="0"}

That is exactly the kind of distinction Matchday needs.

We don't need to reproduce their architecture, but it validates this principle:

> **Competition management can be shared while sporting rules remain sport-specific.**

---

# 3.7 The most important contract: Match → Tournament

Now we need to decide how the Match Engine communicates completion to Tournament Core.

Tournament Core should **not receive the cricket scorecard and calculate things itself**.

Bad:

```text
Cricket Match finishes
        ↓
Tournament Core reads:
243 runs
19.4 overs
8 wickets
201 runs
20 overs
        ↓
Tournament Core calculates winner + NRR
```

That leaks Cricket upward.

Instead:

```text
Cricket Match Engine
        ↓
determines authoritative sport result
        ↓
Cricket Competition Adapter
        ↓
produces Tournament Result
        ↓
Tournament Core
```

Conceptually:

```text
MatchFinalized

matchId
fixtureId
sportId

status = final

participantA
participantB

winner = participantA
loser = participantB

outcome = win

sportResultReference = cricket result
revision = 1
```

And Cricket separately knows:

```text
Lahore Lions 184/7
Kasur Kings 177/9

Lahore won by 7 runs
```

The Tournament Core only needs:

```text
Winner = Lahore
Loser = Kasur
Result = Final
```

until it asks Cricket to update standings.

---

# 3.8 Do not reduce every sport result to only `winner_id`

There is an important nuance here.

The generic result must support more than:

```text
winner = Team A
```

because sports have:

```text
win
loss
draw
tie
no result
walkover
abandoned
disqualification
```

and potentially placements later.

So conceptually, the Tournament Core should understand a small universal result vocabulary.

Something like:

```text
competitive result
administrative result
non-result
```

with participant outcomes.

For example:

```text
Team A → WIN
Team B → LOSS
```

or:

```text
Team A → DRAW
Team B → DRAW
```

or:

```text
Team A → NO_RESULT
Team B → NO_RESULT
```

But the sport layer determines **what those states mean under that sport's rules**.

---

# 3.9 Cricket tie vs football draw illustrates why this matters

Suppose Cricket finishes level.

Depending on tournament rules:

```text
Tie
   ↓
Super Over
```

or:

```text
Tie remains tie
```

or possibly another tie-breaking rule.

Football could finish:

```text
1–1
```

In a league stage, that may simply be a valid draw.

In a knockout stage:

```text
1–1
 ↓
extra time
 ↓
penalties
```

Same Tournament Core.

Different Sport Adapter.

Tournament should merely say:

> “This fixture requires a decisive participant because the next fixture needs a winner.”

Then Football decides how a winner is produced.

Cricket decides how a winner is produced.

That is a much cleaner relationship.

---

# 3.10 Tournament structure can impose requirements; sport decides how to satisfy them

This is subtle but important.

Suppose:

```text
Stage
format = single_elimination
```

Tournament Core knows:

> This fixture must produce an advancing participant.

But Tournament Core should not say:

```text
if tied:
    play Super Over
```

because that is Cricket.

Instead:

```text
Tournament Core
      ↓
"This fixture requires a decisive result."
      ↓
Sport Adapter
```

Cricket may answer:

```text
Super Over
```

Football may answer:

```text
Extra time + penalties
```

Basketball may answer:

```text
Overtime
```

Volleyball already naturally ends decisively under ordinary match rules.

That gives us true multi-sport behavior.

---

# 3.11 Standings need the same boundary

This is where the current system is most Cricket-coupled.

Today:

```text
tournament_standings
```

has:

```text
matches_played
wins
losses
ties
no_results
points

runs_scored
overs_faced
runs_conceded
overs_bowled
net_run_rate
```

The top section can potentially be shared.

The bottom section cannot.

Compare several sports:

| Concept | Cricket | Football | Basketball | Volleyball |
|---|---:|---:|---:|---:|
| Played | ✓ | ✓ | ✓ | ✓ |
| Wins | ✓ | ✓ | ✓ | ✓ |
| Losses | ✓ | ✓ | ✓ | ✓ |
| Draws/Ties | possible | ✓ | uncommon | generally no |
| Points | ✓ | ✓ | configurable | configurable |
| Runs | ✓ | — | — | — |
| NRR | ✓ | — | — | — |
| Goals For | — | ✓ | — | — |
| Goal Difference | — | ✓ | — | — |
| Points For/Against | — | — | ✓ | sometimes |
| Sets Won/Lost | — | — | — | ✓ |
| Set Ratio | — | — | — | ✓ |

Therefore a universal standings entity must not permanently contain:

```text
runs_scored
overs_faced
net_run_rate
```

---

# 3.12 What Tournament Core needs from standings

Tournament Core really needs:

```text
Tournament Entry
Stage
Group

Played
Competition Points

Rank / Position

Qualified?
Eliminated?
```

and perhaps universal outcome counts where appropriate.

Everything else can come from the Sport Competition Adapter.

For Cricket, the adapter can expose:

```text
W
L
T
NR
Pts
NRR
```

For football:

```text
P
W
D
L
GF
GA
GD
Pts
```

For basketball:

```text
P
W
L
PF
PA
Diff
Pts
```

Tournament UI can render whichever columns that sport says are relevant.

This means the UI eventually should not hard-code:

```dart
Text(standing.netRunRate)
```

inside a supposedly generic Tournament widget.

Instead, conceptually:

```text
SportAdapter.standingsColumns()
```

might tell UI:

```text
[
  P,
  W,
  L,
  NR,
  PTS,
  NRR
]
```

for Cricket.

We don't need to design that Dart interface yet. The important thing is the boundary.

---

# 3.13 Ranking is partly generic and partly sport-specific

Tournament Core understands:

```text
Rank 1
Rank 2
Rank 3
```

But it should not independently determine why Rank 1 is above Rank 2.

For example:

### Cricket

```text
Points
↓
NRR
↓
Head-to-head
...
```

### Football

```text
Points
↓
Goal Difference
↓
Goals Scored
↓
Head-to-head
...
```

PlayHQ similarly supports configurable ladder ranking criteria and notes that Cricket has its own sport-specific ladder calculations. :chatgpt-content-reference{index="1"}

So:

```text
SPORT ADAPTER
determines ordered standings

TOURNAMENT CORE
consumes the resulting positions
```

This is extremely important.

---

# 3.14 Qualification then becomes generic

Once the Sport Adapter returns:

```text
Group A

1. Lahore Lions
2. Falcons
3. Kings
4. Titans
```

Tournament Core doesn't need to know NRR.

It simply applies:

```text
qualification rule:
Top 2
```

Therefore:

```text
Group A #1
    ↓
Semi-final Slot A

Group A #2
    ↓
Semi-final Slot B
```

So we get this separation:

```text
Sport Adapter
    ↓
calculates ranking

Tournament Core
    ↓
applies qualification rules

Tournament Core
    ↓
resolves fixture slots
```

Beautiful separation of concerns.

---

# 3.15 Sport Match Format belongs below Tournament Core

From Step 2 we established:

```text
Competition Format
≠
Sport Match Format
```

Now we can place them properly.

Tournament Core owns:

```text
Stage format:
round_robin
single_elimination
double_elimination
```

Sport Adapter owns:

```text
Cricket:
T20
T10
ODI
Custom 15-over

Football:
90 minute
7-a-side
5-a-side
Futsal rules

Basketball:
4 × 10 min
4 × 12 min
...
```

Tournament may store a reference/configuration to those rules, but the **meaning and validation** belong to the sport.

---

# 3.16 Rules inheritance

The hierarchy we discussed in Step 2 can remain:

```text
Tournament sport defaults
        ↓
Stage override
        ↓
Round override
        ↓
Fixture override
```

For Cricket:

```text
Tournament default
20 overs

Group Stage
20 overs

Semi-finals
20 overs

Final
25 overs
```

For another sport:

```text
Tournament default
Football 2 × 45

Youth stage
2 × 30
```

Toornament uses a similar inheritance model where match format can be configured at tournament, stage, group, round or individual match levels, with lower levels overriding inherited settings. :chatgpt-content-reference{index="2"}

That is a useful model for us conceptually.

But the Tournament Core still treats the configuration as:

```text
sport rules configuration
```

without understanding the actual values.

---

# 3.17 Tournament squad vs Match lineup

Another boundary we should freeze now.

Tournament Core can own:

```text
Tournament Entry
        ↓
registered squad
```

because eligibility is a competition concept.

Example:

```text
Lahore Lions registered 18 players
```

Tournament can enforce:

```text
only registered players may participate
squad frozen after deadline
replacement requires organizer approval
```

But the sport layer owns:

```text
playing XI
wicketkeeper
captain
substitute
opening batsmen
```

For football it might own:

```text
starting XI
substitutes
goalkeeper
```

So:

```text
TOURNAMENT
Who is eligible?

SPORT MATCH
Who is playing this match and in what role?
```

That distinction is excellent for Matchday.

---

# 3.18 Tournament officials vs sport official roles

Tournament Core should understand:

> “A person can be assigned an official responsibility to a fixture.”

But roles themselves may be sport-specific.

Cricket:

```text
Scorer
Main Umpire
Leg Umpire
Third Umpire
Match Referee
```

Football:

```text
Referee
Assistant Referee
Fourth Official
```

Basketball:

```text
Referee
Umpire
Table Official
Scorekeeper
```

Therefore I would not hard-code all those roles into Tournament Core.

Conceptually:

```text
Tournament Core
    OfficialAssignment

Sport Adapter
    AllowedOfficialRoles
```

Authority to assign them remains a Tournament capability.

The meaning of the roles belongs to the sport.

---

# 3.19 Scorer is slightly special

Scoring has two aspects.

The Tournament Core understands:

```text
this user has been appointed
to operate this fixture
```

The Sport Match Engine understands:

```text
what actions scoring actually allows
```

For Cricket:

```text
record ball
wicket
extras
end innings
super over
```

For football:

```text
goal
card
substitution
period state
```

So the scorer/official is assigned at tournament level, while their actual scoring command set lives in the sport engine.

This fits Step 1 perfectly.

---

# 3.20 Walkover is generic; its sporting effect is not

We discussed walkovers in Step 2.

Now we can place the boundary.

Tournament Core understands:

```text
Fixture resolved administratively.
Participant A advances.
Reason recorded.
Actor recorded.
```

But Sport Adapter decides what this means for standings/statistics.

For Cricket, maybe tournament rules say:

```text
2 points
no NRR impact
```

Another Cricket competition might use a different rule.

Football may record:

```text
3–0 awarded result
```

depending on competition rules.

Therefore:

```text
Tournament Core:
walkover occurred

Sport Adapter:
standing/statistical consequence
```

---

# 3.21 Same for abandoned and no-result

Tournament Core should understand:

```text
match did not finish normally
```

But Cricket determines:

```text
No Result
1 point each
NRR treatment
```

Football might have completely different regulations.

So the comment currently living in your generic tournament repository:

```text
noResult splits the points and leaves NRR untouched
```

is a good example of something that should ultimately move under the Cricket tournament adapter.

The functionality is valid.

Its architectural location isn't.

---

# 3.22 DLS clearly belongs completely below the boundary

Your:

```text
RevisedTargetCalculator
TargetMethod.dls
runRate
revisedOvers
bowlerQuota
```

is pure Cricket competition/match operation.

Tournament Core should never import it.

The organizer may reach it from the Tournament Console because that's where they operate.

But UI navigation location does **not** define domain ownership.

This is an important Clean Architecture principle:

```text
"Shown inside Tournament screen"
            ≠
"belongs to Tournament domain"
```

The Tournament Console can compose functionality from:

```text
Tournament Core
Cricket Tournament Adapter
Cricket Match Engine
```

without those domains being the same.

---

# 3.23 Same for Super Over

Current repository:

```text
TournamentsRepository.triggerSuperOver(...)
```

Conceptually that's misplaced.

Super Over belongs to:

```text
Cricket Match Engine
```

The tournament can require:

```text
decisive result required
```

Cricket decides:

```text
Super Over
```

So eventually the interaction is closer to:

```text
Tournament structure:
"This fixture cannot end tied."

              ↓

Cricket rules:
"Tied after regulation.
Apply configured tie breaker."

              ↓

Cricket Match:
"Enter Super Over."
```

Tournament Core doesn't even need the phrase **Super Over**.

---

# 3.24 Player statistics and leaderboards

This requires another clean distinction.

Tournament Core can understand the generic concept:

```text
Tournament Award
```

such as:

```text
Champion
Runner-up
Fair Play Award
MVP / Player of Tournament
```

But statistical leaderboards are sport-specific.

Cricket:

```text
Top Runs
Top Wickets
Highest Score
Best Bowling
Most Sixes
```

Football:

```text
Top Goals
Assists
Clean Sheets
```

Basketball:

```text
Points
Assists
Rebounds
```

So:

```text
Tournament Core
    awards framework

Sport Adapter
    statistical categories
    calculations
    candidate generation
```

This lets Matchday eventually show very rich tournament pages without corrupting the core domain.

---

# 3.25 Public Tournament UI should also follow this boundary

The generic Tournament Detail screen can contain:

```text
Overview
Teams
Fixtures
Standings
Bracket
Stats
```

But what appears *inside* `Stats` should come from the sport.

For Cricket:

```text
Batting
Bowling
Top Performers
```

Football:

```text
Goals
Assists
Cards
```

Similarly Standings columns come from the sport.

Therefore the presentation layer becomes compositional rather than filled with:

```dart
if (sport == cricket)
...
else if (sport == football)
...
else if ...
```

throughout every widget.

Eventually each sport should provide the appropriate presentation/configuration adapter.

---

# 3.26 We should not over-generalize Matchday yet

This is something I want to be careful about.

“Multi-sport” does **not** mean we have to build a theoretical tournament engine capable of Formula 1, golf, swimming, Battle Royale, boxing, chess, tennis doubles, athletics and cricket tomorrow.

That would be overengineering.

For the first architectural boundary I would explicitly optimize for:

```text
HEAD-TO-HEAD TEAM SPORTS
```

which covers a very large part of Matchday's intended direction:

```text
Cricket
Football
Futsal
Basketball
Hockey
Volleyball
...
```

They share:

```text
Team A
Team B
Fixture
Result
Winner / loser / draw
Standings
Rounds
Knockouts
Groups
```

Later we can introduce another competition family for:

```text
Individual head-to-head
```

and eventually:

```text
multi-participant / race / free-for-all
```

Toornament itself distinguishes duel structures from free-for-all structures rather than pretending one model naturally represents both. :chatgpt-content-reference{index="3"}

That is useful guidance.

So I do **not** want us to destroy a clean team-sports architecture merely to claim theoretical “all sports” support.

---

# 3.27 The boundary for Matchday v1 should therefore be

```text
                    MATCHDAY

          ┌───────────────────────┐
          │    Tournament Core    │
          │   Team competition    │
          └───────────┬───────────┘
                      │
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
   Cricket        Football      Basketball
   Adapter         Adapter         Adapter
       │              │              │
       ▼              ▼              ▼
   Cricket         Football       Basketball
   Engine          Engine          Engine
```

Today only this path really exists:

```text
Tournament Core
      ↓
Cricket
```

That's completely fine.

The purpose of the architecture is that adding Football should **extend**, not rewrite, Tournament Core.

---

# 3.28 What I would preserve from the current design

I would absolutely preserve the idea represented by:

```text
matches
    +
cricket_matches
```

and:

```text
match_players
    +
cricket_match_players
```

because that is already pointing toward the right architecture.

I would eventually apply the same logic higher up:

```text
Tournament Core
       +
Cricket Tournament Rules/Projection
```

rather than expanding `Tournament` itself with more Cricket concepts.

---

# 3.29 What should eventually move out of Tournament Core

Not implementing this yet, but now our audit criteria become very clear.

| Current concept | Correct future boundary |
|---|---|
| Tournament identity | Tournament Core |
| Sport ID | Tournament Core reference |
| Registration | Tournament Core |
| Tournament Entries | Tournament Core |
| Stages | Tournament Core |
| Groups | Tournament Core |
| Rounds | Tournament Core |
| Fixtures | Tournament Core |
| Seeding | Tournament Core |
| Qualification | Tournament Core |
| Schedule | Tournament Core |
| Grounds/Venues | Tournament Core |
| Organizer authority | Tournament Core |
| `maxOvers` | Cricket |
| `ballType` | Cricket |
| T20/T10 | Cricket |
| Playing XI | Cricket Match |
| Toss | Cricket Match |
| NRR | Cricket competition adapter |
| Runs/overs standings | Cricket competition adapter |
| Super Over | Cricket Match |
| DLS | Cricket Match/competition rules |
| Revised overs | Cricket |
| Batting leaderboard | Cricket stats |
| Bowling leaderboard | Cricket stats |
| Cricket official roles | Cricket adapter |
| Generic official assignment | Tournament Core |
| Generic award | Tournament Core |
| Cricket award calculation | Cricket adapter |

That becomes an extremely useful standard for our later review.

---

# 3.30 The result/progression pipeline I would freeze

This is probably the most important architecture from Step 3:

```text
               SPORT MATCH ENGINE

                    Cricket
                      │
                      │ finalizes match
                      ▼
             Cricket Result
         184/7 vs 177/9, 7-run win
                      │
                      ▼
          SPORT COMPETITION ADAPTER
                      │
          ┌───────────┴────────────┐
          │                        │
          ▼                        ▼
   Generic Outcome         Standing Projection
     Team A WIN           +2 points / NRR etc.
          │                        │
          └───────────┬────────────┘
                      ▼
               TOURNAMENT CORE
                      │
          ┌───────────┼──────────────┐
          ▼           ▼              ▼
      Progress      Qualify       Resolve slots
      bracket       top N         next fixture
```

That means:

> **The Sport Engine determines what happened.**

> **The Sport Competition Adapter determines what that sporting result means for competition statistics/rankings.**

> **The Tournament Core determines where the participants go next.**

I would freeze those three sentences into the Matchday standard.

---

# 3.31 One more critical rule: Tournament Core must not recalculate sport truth

Suppose Cricket says:

```text
Winner: Lahore Lions
```

Tournament Core must not re-read deliveries and independently decide whether Lahore actually won.

Likewise, Tournament Core should not independently calculate NRR.

There must be **one authoritative calculation owner**.

Otherwise we eventually get:

```text
Cricket scorecard says Lahore won
Tournament code says Kasur won
Standings calculation says tie
```

That is exactly the kind of architectural drift we want to prevent.

So:

```text
Sport Engine
= source of truth for sporting result

Sport Competition Adapter
= source of truth for sport-specific standings/statistics

Tournament Core
= source of truth for competition structure/progression
```

---

# The Step-3 standard I recommend freezing

1. **Tournament Core must remain sport-agnostic.** It owns competition structure, entries, fixtures, scheduling, progression, authority and qualification.

2. **Sport Match Engine owns gameplay truth.** Cricket owns toss, innings, deliveries, lineups, T20 rules, Super Overs, revised targets and the authoritative Cricket result.

3. **A Sport Competition Adapter sits between them.** It translates sport results into points, standings, rankings, tie-break criteria and sport-specific tournament statistics.

4. **Tournament Core consumes outcomes and rankings; it does not calculate them from sport data.**

5. **Qualification is generic.** “Top 2 advance” belongs to Tournament Core; determining who is first and second belongs to the Sport Adapter.

6. **Competition Format and Sport Match Format stay separate.** Round-robin/knockout are Tournament concepts; T20/ODI/etc. are Cricket concepts.

7. **Tournament Squad eligibility belongs to Tournament Core; per-match lineup and player roles belong to the Sport Match Engine.**

8. **Official assignment is generic, but official role definitions may be sport-specific.**

9. **Walkover/abandonment are generic operational concepts, while their points/statistical consequences are sport-specific.**

10. **The current `matches + cricket_matches` pattern is the model we want to preserve and extend.**

11. **Current Cricket properties embedded inside `Tournament`, `TournamentStanding`, and `TournamentsRepository` should later be classified as boundary violations during the implementation audit—not removed yet.**

12. **Matchday's first multi-sport architecture should target head-to-head team sports rather than trying to solve every possible sport category prematurely.**

With Steps 1–3 combined, we now have a very strong foundation:

```text
STEP 1
Who controls a match?
→ Authority boundary

STEP 2
How is a competition structurally represented?
→ Tournament hierarchy

STEP 3
Who understands sporting rules?
→ Multi-sport boundary
```

The next part, **Step 4 — Lifecycle Model**, is where these three start working together. There we need to be especially careful because the current single `tournament_status` — `draft → registration → upcoming → live → completed` — is probably trying to represent several independent state machines at once. We should separate **publication, registration, draw/fixtures, competition execution, and completion** conceptually before deciding what should actually be stored in the database.



Yes. Step 4 is where we decide **how a tournament actually moves through time**.

The biggest conclusion is this:

> `Draft → Registration → Upcoming → Live → Completed` is useful as a **public-facing tournament phase**, but it is too coarse to be the only state machine in the backend.

A tournament can be published while registration has not opened yet. Registration can close while some applications are still pending. Fixtures can be drafted but not published. A tournament can be “Upcoming” while its draw is already public. And a tournament can have some matches completed without the whole tournament being “Completed.”

So I would keep a simple public lifecycle while modeling the important processes separately.

# Step 4 — Lifecycle Model

The public journey should remain very understandable:

```text
DRAFT
  │
  │ Publish
  ▼
REGISTRATION
  │
  │ Registration closes
  │ Entries finalized
  │ Structure/draw prepared
  ▼
UPCOMING
  │
  │ First tournament match actually starts
  ▼
LIVE
  │
  │ Final required fixture resolved
  │ Champion/outcome finalized
  ▼
COMPLETED
```

With terminal exits:

```text
DRAFT ──────────────► CANCELLED
REGISTRATION ───────► CANCELLED
UPCOMING ───────────► CANCELLED
LIVE ───────────────► ABANDONED   ← exceptional

COMPLETED = historical final state
```

That basic UX is good.

But underneath it, I recommend several coordinated state machines.

---

## 4.1 Why one `tournament_status` is not enough

Consider this tournament:

```text
Lahore Champions Cup

Published publicly        ✓
Registration              Closed
Teams                     8 finalized
Draw                      Created
Fixtures                  Not published yet
Tournament start          Tomorrow
Matches played            0
```

What is its status?

`registration`? No, registration is closed.

`upcoming`? Yes publicly.

But we still need to know:

```text
draw = draft
fixtures = unpublished
entries = locked
```

A single enum cannot explain all of this safely.

Another example:

```text
Tournament status = live

Match 1 completed
Match 2 live
Match 3 scheduled tomorrow
```

The tournament is live, but each match has its own independent state.

This is why I recommend:

```text
Tournament Aggregate
│
├── Publication State
├── Registration State
├── Entry/Participant State
├── Draw / Fixture State
└── Competition State
```

And then derive the simple status shown to users.

---

# 4.2 State machine A — Publication

This answers only:

> **Can people outside the organizer team see this tournament?**

Conceptually:

```text
DRAFT
  │
  │ publish
  ▼
PUBLISHED
```

Potential future:

```text
PUBLISHED
   │
   └── archived after historical completion
```

I would **not** use `registration` to mean “published.”

Those are different concepts.

For example:

```text
publication = published
registration = not_open
```

is completely valid.

That gives you:

> “Tournament announced — registrations open October 1.”

Toornament similarly separates publishing a tournament from registration configuration; publishing makes the tournament publicly visible rather than inherently defining every other competition phase. :chatgpt-content-reference{index="0"}

---

# 4.3 What Draft should mean

`Draft` should be very permissive.

Organizer can change:

```text
Name
Sport
Tournament structure
Stages
Rules
Dates
Grounds
Entry fee
Registration dates
Team limits
Artwork
Privacy
Sport match defaults
Awards configuration
```

And importantly:

```text
No public competitive promise has been made yet.
```

That means destructive edits are cheap.

If organizer changes:

```text
8 teams → 16 teams
Knockout → Groups + Knockout
T20 → T10
```

while the tournament is a draft, that is fine.

There should be almost no migration/revision complexity at this point.

---

# 4.4 Publishing does NOT mean registration must instantly open

This is an important improvement over today's behavior.

Currently your Flutter code does essentially:

```dart
publishTournament()
→ status = registration
```

So publication and opening registration are coupled.

I would separate them.

An organizer might create:

```text
September 27:
Tournament published

October 1:
Registration opens

October 10:
Registration closes

October 15:
Tournament begins
```

Between September 27 and October 1:

```text
Publication = Published
Registration = Not Open
Competition = Not Started
```

UI:

```text
REGISTRATION OPENS
Oct 1
```

Not:

```text
Registration Open
```

---

# 4.5 State machine B — Registration

Registration should have its own lifecycle.

I recommend conceptually:

```text
NOT_OPEN
    │
    │ open
    ▼
OPEN
    │
    │ deadline / organizer closes
    ▼
CLOSED
```

Potentially:

```text
CLOSED
  │
  │ exceptional organizer action
  ▼
OPEN
```

for a deliberate reopening.

But reopening should become more restricted after competition structure is locked.

---

# 4.6 Registration `OPEN`

This is when team managers can:

```text
Apply/register team
Submit requested squad information
Provide message/details
Handle entry-fee process
Withdraw pending application
```

Organizer can:

```text
Approve
Reject
Review
Record offline payment
Communicate with applicant
```

The public tournament may display:

```text
Registration Open
6 / 8 teams approved
Closes Oct 10
```

---

# 4.7 Registration deadline should close new applications, not magically finalize the field

This is subtle.

Suppose deadline passes with:

```text
6 approved
2 pending
3 rejected
```

The system should not immediately assume the final participant set is six.

Instead:

```text
Registration
    CLOSED
```

means:

> **No new applications are accepted.**

But organizers can still resolve applications that were submitted before the deadline.

So we need a separate concept:

```text
Entry Set
    EDITABLE
       ↓
    LOCKED
```

This is one of the most useful distinctions.

---

# 4.8 Registration vs Tournament Entry

Remember Step 2:

```text
Registration/Application
≠
Tournament Entry
```

Application lifecycle:

```text
PENDING
  ├── APPROVED
  ├── REJECTED
  └── WITHDRAWN
```

Once approved, conceptually it becomes a tournament entry.

Then that tournament entry might have its own lifecycle:

```text
ACTIVE
  ├── WITHDRAWN
  ├── DISQUALIFIED
  └── COMPLETED
```

We do not necessarily need all these tables immediately.

But lifecycle semantics should distinguish them.

---

# 4.9 Entry Set locking

After registration closes and pending applications are resolved, organizer reaches:

```text
FINAL PARTICIPANTS

✓ Lahore Lions
✓ Kasur Kings
✓ Falcons
✓ Warriors
...
```

Then performs:

```text
Lock Entries
```

Conceptually:

```text
ENTRY SET

EDITABLE
   ↓
LOCKED
```

Once locked:

```text
team additions       restricted
team removals        audited exception
seeding              meaningful
group allocation     meaningful
draw generation      allowed
fixtures             can be published
```

This is the real transition from **recruitment** to **competition preparation**.

Not merely `registration_deadline < now()`.

---

# 4.10 Why we should not automatically move to Upcoming at the registration deadline

Imagine eight teams are needed.

Deadline passes with only five approved.

Automatically doing:

```text
Registration
     ↓
Upcoming
```

would be wrong.

Organizer may need to:

```text
extend registration
reduce minimum teams
cancel tournament
invite teams manually
approve pending teams
change structure
```

Therefore time can trigger:

```text
registration = CLOSED
```

but not necessarily:

```text
tournament = UPCOMING
```

The latter should depend on readiness.

---

# 4.11 Readiness gate before Upcoming

I would introduce the concept of **competition readiness**, even if it is only computed rather than stored.

Before tournament is operationally ready, validate:

```text
✓ enough approved/active entries
✓ no unresolved participant blockers
✓ entry set locked
✓ tournament structure valid
✓ stages configured
✓ required draw generated
✓ required fixtures exist
✓ sport rules valid
✓ tournament dates valid
```

Potential warnings:

```text
! some fixtures have no ground yet
! scorers not assigned yet
! squads incomplete
```

Some should block.

Some should only warn.

This gives the organizer a proper:

```text
Prepare Tournament
      ↓
Ready for Competition
```

workflow.

---

# 4.12 Draw/fixture lifecycle

This deserves its own state too.

I recommend conceptually:

```text
NOT_CREATED
      ↓
DRAFT
      ↓
PUBLISHED
```

After publication:

```text
PUBLISHED
      ↓
REVISED
```

But `REVISED` should probably be represented by revision history rather than a permanent state.

For example:

```text
Draw Revision 1
Published Sep 29

Draw Revision 2
Published Sep 30
Reason: Team withdrew
```

The currently active draw is still:

```text
PUBLISHED
```

with:

```text
revision = 2
```

---

# 4.13 Draft draw

Before publishing fixtures, organizer should be free to regenerate.

Example:

```text
8 teams
↓
Generate Knockout Draw
↓
Preview
↓
Regenerate
↓
Change seeds
↓
Regenerate
```

No one outside tournament operations should depend on those fixtures yet.

So those are draft competitive structures.

---

# 4.14 Published fixtures are a commitment

Once organizer clicks:

```text
Publish Fixtures
```

teams may receive:

```text
Opponent
Ground
Date/time
Round
```

People start planning around that information.

So after publication, changing:

```text
participant
draw position
round structure
qualification source
```

must become controlled and audited.

Changing:

```text
time
ground
scorer
official
```

can remain normal operational edits.

This creates an important distinction:

```text
STRUCTURAL EDIT
vs
SCHEDULING EDIT
```

Changing venue:

```text
Ground A → Ground B
```

does not change tournament topology.

Changing:

```text
Team A → Team C
```

does.

---

# 4.15 What “Upcoming” should actually mean

Now we can define `Upcoming` precisely.

A tournament is publicly **Upcoming** when:

```text
published = true

AND

registration is no longer the primary public activity

AND

competition has not started
```

Typically:

```text
registration = CLOSED
entries = LOCKED
competition = NOT_STARTED
```

and usually:

```text
fixtures = PUBLISHED
```

UI might show:

```text
UPCOMING

Starts in 3 days
8 teams
12 matches

Fixtures
Teams
Groups
Standings (empty)
```

---

# 4.16 Can fixtures be published while registration is still open?

This is a good edge case.

Normally:

```text
No final draw
until entries are locked.
```

Because adding/removing teams affects structure.

However, organizers might publish generic schedule slots:

```text
Match 1 — 9 AM
Match 2 — 12 PM
Match 3 — 3 PM
```

without participants.

I would distinguish:

```text
Schedule Planning
```

from:

```text
Competition Draw Publication
```

For v1, I would keep it simple:

> **Final competitive fixtures cannot be published until participating entries are locked.**

That prevents a lot of complexity.

---

# 4.17 State machine C — Competition

This is the important one.

I recommend:

```text
NOT_STARTED
     │
     │ first actual match starts
     ▼
IN_PROGRESS
     │
     │ competition resolved
     ▼
COMPLETED
```

Exceptional:

```text
NOT_STARTED ─────► CANCELLED

IN_PROGRESS ─────► ABANDONED
```

You could call `IN_PROGRESS` publicly:

```text
LIVE
```

That's fine.

---

# 4.18 Upcoming → Live should happen from reality, not from clock time

Suppose tournament start date is:

```text
October 15 — 9:00 AM
```

At 9:00 AM no match has started because of rain.

Should tournament become Live?

I say **no**.

The tournament should become Live when the first tournament match actually enters its live sport state.

For Cricket:

```text
first fixture reaches MatchStatus.live
```

Then:

```text
competition_state:
NOT_STARTED → IN_PROGRESS
```

and public status becomes:

```text
LIVE
```

This is much more trustworthy.

---

# 4.19 Tournament Live does not mean every fixture is live

Very important.

Example:

```text
Tournament = LIVE

Match 1 = COMPLETED
Match 2 = LIVE
Match 3 = SCHEDULED
Match 4 = SCHEDULED
```

Tournament Live simply means:

> Competition has begun and has not yet reached its terminal resolution.

It can last:

```text
one afternoon
three days
six weeks
```

depending on the tournament.

---

# 4.20 Live operations

Once Live, organizer should generally be able to:

```text
Assign/reassign scorers
Assign officials
Reschedule future fixtures
Move grounds
Handle interruptions
Record walkovers
Handle abandoned matches
Resolve exceptional results
Send announcements
Operate ongoing matches
```

But structural configuration should become highly restricted.

For example:

```text
Change tournament sport
❌

Change round-robin into knockout
❌

Delete an already-played stage
❌

Regenerate whole draw
❌
```

Because actual sporting history now exists.

---

# 4.21 Stage lifecycle

Because Step 2 introduced Stages, stages also have their own execution lifecycle.

Conceptually:

```text
PENDING
   ↓
ACTIVE
   ↓
COMPLETED
```

Example:

```text
Tournament = LIVE

Group Stage = COMPLETED
Playoffs    = ACTIVE
```

This is important for Group + Knockout.

Tournament does **not** leave Live between stages.

It remains:

```text
LIVE
```

while progression moves:

```text
Stage 1 completed
      ↓
qualification resolved
      ↓
Stage 2 activated
```

---

# 4.22 When a stage completes

For a round-robin stage:

```text
All required fixtures terminal
      ↓
Sport Adapter calculates final standings
      ↓
Ranking finalized
      ↓
Qualification rules applied
      ↓
Stage completed
```

Then Tournament Core resolves:

```text
Group A #1
Group B #2
etc.
```

into the next stage's fixture slots.

Notice Step 3 again:

```text
Cricket Adapter:
Who ranked #1?

Tournament Core:
Where does #1 go?
```

---

# 4.23 Knockout stage progression

For knockout:

```text
Quarter-final completed
     ↓
winner resolved
     ↓
Semi-final slot resolved
```

You do not wait for the entire stage to finish before progressing individual winners where possible.

So fixture progression is event-driven:

```text
Match Finalized
      ↓
Fixture Finalized
      ↓
Resolve dependent slots
```

while stage completion happens only when its terminal fixture(s) are resolved.

---

# 4.24 What “Completed” should mean

We need a strong definition.

Tournament should become `Completed` only when:

```text
all required competitive paths are terminal

AND

final tournament outcome is resolved
```

For single elimination:

```text
Final completed
↓
Champion known
```

For round robin:

```text
All required matches completed
↓
Final standings computed
↓
Champion/placement determined
```

For Groups + Knockout:

```text
Final knockout fixture completed
↓
Champion known
```

Then:

```text
competition_state = COMPLETED
```

Public:

```text
COMPLETED
```

---

# 4.25 Do awards have to be complete before tournament completion?

I would say **no**.

This distinction matters.

The competition may be officially complete:

```text
Champion known
Runner-up known
All fixtures final
```

while organizer is still choosing:

```text
Player of Tournament
Best Batter
Best Bowler
Fair Play
```

So:

```text
Competition Completed
```

should not wait for ceremonial/admin wrap-up.

UI can show:

```text
Completed
Awards pending
```

or simply allow awards to be published afterward.

---

# 4.26 Completed should be effectively immutable sporting history

Once completed:

```text
structure                  locked
entries                    locked
normal fixture scheduling  closed
new matches                restricted
competition result         final
```

But correction workflows still need to exist.

For example:

```text
Scorecard correction
Result appeal
Administrative reversal
```

These should not mean:

```text
set tournament back to live
```

casually.

Instead:

```text
Audited amendment
```

with controlled downstream recalculation.

We'll need to design that under exception handling later.

---

# 4.27 Cancelled vs Abandoned

These should have precise meanings.

## Cancelled

Use when competition does not meaningfully proceed.

Usually:

```text
before first match starts
```

Examples:

```text
not enough teams
venue unavailable
organizer cancels event
weather forecast makes event impossible
```

So:

```text
DRAFT/REGISTRATION/UPCOMING
          ↓
       CANCELLED
```

---

# 4.28 Abandoned

Use when tournament started but cannot be completed.

Example:

```text
Tournament starts
8 of 15 matches played
extreme weather / safety issue
competition terminated
```

Then:

```text
LIVE
  ↓
ABANDONED
```

This should be rare.

And it is different from an individual **match being abandoned**.

We must use precise language:

```text
Match abandoned
≠
Tournament abandoned
```

A tournament can remain Live while one fixture is abandoned/rescheduled/no-result.

---

# 4.29 A cancelled match doesn't cancel the tournament either

Likewise:

```text
Tournament
   LIVE

Fixture 12
   CANCELLED / WALKOVER / ABANDONED
```

does not mean Tournament is cancelled.

Tournament lifecycle and Match lifecycle are separate aggregates.

This is crucial.

---

# 4.30 Reopening registration

Let's handle this explicitly.

### While registration closed but entries not locked

Organizer may:

```text
Reopen Registration
```

fairly safely.

For example:

```text
5 teams received
minimum = 8
```

So:

```text
CLOSED → OPEN
```

is acceptable.

---

# 4.31 Reopening after entries locked

This should be much more serious.

If:

```text
entries = LOCKED
draw = DRAFT
```

we might allow:

```text
Unlock entries
```

with confirmation because no public draw exists yet.

But after:

```text
draw = PUBLISHED
```

adding a team can change the competition structure.

Therefore:

```text
Reopen registration
```

should not casually happen.

You would need a structural revision workflow.

---

# 4.32 Team withdrawal lifecycle

Another major edge case.

### Before entry lock

Easy:

```text
Approved team withdraws
↓
Entry removed/withdrawn
```

### After entry lock, before draw publication

Manageable:

```text
Withdraw
↓
unlock/recalculate seeds
↓
regenerate draft draw
```

### After draw published but before tournament starts

Now it's a structural amendment.

Possible outcomes:

```text
replace team
grant bye
redraw affected structure
```

but must be audited.

### After tournament starts

This becomes competition operations:

```text
withdraw/disqualify
↓
Sport/tournament rules determine consequences
↓
walkovers / table treatment / bracket progression
```

You should never simply delete that team.

Historical records must remain.

---

# 4.33 Squad lifecycle is also separate

Eventually:

```text
SQUAD

EDITABLE
   ↓
FROZEN
```

Maybe:

```text
FROZEN
   ↓
AMENDMENT_APPROVED
```

depending on tournament rules.

Registration closing does not necessarily have to freeze squads at the exact same moment.

You may want:

```text
Registration closes Oct 10
Squads lock Oct 14
Tournament starts Oct 15
```

Again, orthogonal states are useful.

---

# 4.34 Date vs state

A general rule we should freeze:

> **Dates may trigger eligibility for transitions, but dates are not the authoritative state themselves.**

Examples:

```text
registration_deadline reached
→ registration can/should close
```

but:

```text
start_date reached
≠ tournament automatically live
```

because Live means competition actually started.

Likewise:

```text
end_date reached
≠ tournament automatically completed
```

because unresolved fixtures may remain.

So:

```text
Clock
provides conditions

Domain events
perform transitions
```

---

# 4.35 Automatic vs explicit transitions

I recommend this split.

### Automatic

System can perform:

```text
registration open time reached
→ OPEN

registration deadline reached
→ CLOSED

first tournament match actually becomes live
→ tournament IN_PROGRESS

final required competition outcome finalized
→ tournament COMPLETED
```

### Explicit organizer action

Organizer performs:

```text
Publish tournament
Lock entries
Publish draw/fixtures
Cancel tournament
Abandon tournament
Reopen registration
Approve structural revision
```

This prevents the system from making destructive assumptions.

---

# 4.36 Public status can still remain simple

Despite all the internal complexity, users should not see twelve statuses.

We can derive something like:

| Internal situation | Public badge |
|---|---|
| Unpublished | Draft — organizer only |
| Published, registration not open | Upcoming |
| Registration open | Registration Open |
| Registration closed, competition not started | Upcoming |
| Any stage in progress | Live |
| Competition successfully resolved | Completed |
| Cancelled before start | Cancelled |
| Started but permanently terminated | Abandoned |

So your current public vocabulary can mostly survive.

The architectural change is:

> **The public badge becomes a projection of richer state, not the entire domain state.**

---

# 4.37 Organizer console should show more detail

Public:

```text
UPCOMING
```

Organizer:

```text
Tournament Preparation

Registration      Closed
Entries           8 locked
Draw              Published
Fixtures          12 published
Scorers           9 / 12 assigned
Squads            7 / 8 finalized
Competition       Not started
```

This gives the organizer actionable information instead of pretending one word describes everything.

---

# 4.38 Current implementation issue

Today the backend/Flutter model has:

```text
tournament_status

draft
registration
upcoming
live
completed
cancelled
abandoned
```

and `publishTournament()` directly performs:

```text
draft → registration
```

That's simple but conflates:

```text
publication
+
registration
```

Your fixture publishing also currently checks whether tournament fixtures already exist, but it doesn't represent a first-class draw publication lifecycle/revision model.

So Step 4 gives us a clear future audit target.

We should not change it yet, but we now know why the existing model will become restrictive.

---

# 4.39 Proposed canonical lifecycle

Putting the entire model together:

```text
                    ┌─────────────────┐
                    │      DRAFT      │
                    │   unpublished   │
                    └────────┬────────┘
                             │ publish
                             ▼
                   ┌──────────────────┐
                   │    PUBLISHED     │
                   │ reg not open yet │
                   └────────┬─────────┘
                            │ open registration
                            ▼
                   ┌──────────────────┐
                   │   REGISTRATION   │
                   │       OPEN       │
                   └────────┬─────────┘
                            │ deadline/close
                            ▼
                   ┌──────────────────┐
                   │ REGISTRATION     │
                   │      CLOSED      │
                   └────────┬─────────┘
                            │ resolve pending
                            │ lock entries
                            ▼
                   ┌──────────────────┐
                   │   PREPARATION    │
                   │ draw + fixtures  │
                   └────────┬─────────┘
                            │ publish draw
                            ▼
                   ┌──────────────────┐
                   │     UPCOMING     │
                   │ ready/not begun  │
                   └────────┬─────────┘
                            │ first match starts
                            ▼
                   ┌──────────────────┐
                   │       LIVE       │
                   │  stage progress  │
                   └────────┬─────────┘
                            │ final outcome resolved
                            ▼
                   ┌──────────────────┐
                   │    COMPLETED     │
                   │ historical event │
                   └──────────────────┘
```

But importantly, **Preparation does not necessarily have to become a public `tournament_status`**.

It is an organizer workflow/state derived from:

```text
registration = closed
entries = locked
draw != published
competition = not_started
```

Publicly it can simply say:

```text
Upcoming
```

if already published.

---

# 4.40 The actual state-machine model I recommend freezing

Conceptually:

```text
Tournament
│
├── publication_state
│      draft
│      published
│
├── registration_state
│      not_open
│      open
│      closed
│
├── entry_state
│      editable
│      locked
│
├── draw_state
│      not_created
│      draft
│      published
│
├── competition_state
│      not_started
│      in_progress
│      completed
│
└── termination
       none
       cancelled
       abandoned
```

I am deliberately saying **conceptually**.

We have not yet decided whether those become:

```text
5 columns
```

or:

```text
some stored + some derived
```

or dedicated tables/events.

That comes during implementation design.

For now the domain semantics matter.

---

# 4.41 Transition guards

These are the rules I would want the server eventually to own:

```text
Publish Tournament
requires:
  valid tournament configuration
```

```text
Open Registration
requires:
  published
  registration period valid
```

```text
Lock Entries
requires:
  registration closed
  no unresolved blocking applications
  minimum participants satisfied
```

```text
Publish Draw
requires:
  entries locked
  valid stage structure
  valid participant placement
```

```text
Start Tournament / first match
requires:
  fixture belongs to active stage
  participants resolved
  sport configuration valid
```

```text
Complete Stage
requires:
  all required fixtures terminal
  rankings/progression resolved
```

```text
Complete Tournament
requires:
  terminal competition condition reached
  champion/final placement resolved
```

Those rules should eventually be server-authoritative rather than merely Flutter button conditions.

---

# 4.42 One rule I strongly recommend

Do **not** give the organizer a button that simply says:

```text
Mark Tournament Live
```

or:

```text
Mark Tournament Completed
```

under ordinary flow.

Those should follow domain truth.

Live:

```text
first actual fixture starts
```

Completed:

```text
competition result resolves
```

Administrative override may exist for recovery, but it should be exceptional and audited.

That prevents impossible states such as:

```text
Tournament = Completed
Final = Scheduled
```

or:

```text
Tournament = Live
No match has ever started
```

---

# 4.43 And this aligns all four steps

We now have:

```text
STEP 1 — AUTHORITY

Tournament governs tournament-linked matches.
```

```text
STEP 2 — STRUCTURE

Tournament
→ Stages
→ Groups
→ Rounds
→ Fixtures
→ Match
```

```text
STEP 3 — MULTI-SPORT

Sport Engine determines sporting truth.
Tournament Core handles competition progression.
```

```text
STEP 4 — LIFECYCLE

Tournament progresses through controlled domain events,
not through one manually edited status string.
```

That is now becoming a proper tournament platform rather than a collection of tournament screens.

The next Step 5 should be the **Authority Model**, where we can define exactly what **Tournament Owner, Tournament Manager, Scorer, Official, Team Manager/Captain, Player, and Spectator** may do at every lifecycle stage—and convert that into the capability model such as `tournament.edit`, `registration.review`, `draw.publish`, `fixture.reschedule`, `match.score`, `result.override`, etc. That will connect directly back to the tournament-vs-match ownership rule we established in Step 1.




Yes. Step 5 should answer one precise question:

> **Who may execute a tournament action, from which authority source, on which entity, and under which lifecycle conditions?**

The model I recommend is:

```text
ROLE
  ↓ provides defaults
CAPABILITY
  ↓ checked at a scope
AUTHORITY RESOLVER
  ↓ identifies where authority comes from
LIFECYCLE / DOMAIN GUARD
  ↓ verifies action is currently legal
COMMAND EXECUTES
```

That distinction matters. A user can have permission to manage fixtures but still be prevented from changing a fixture after the tournament has completed.

# Step 5 — Authority Model

## 5.1 Roles must not be authorization

We should never write business rules such as:

```dart
if (user.role == 'manager') {
  allow();
}
```

Instead:

```text
Tournament Manager
        ↓
default capability bundle
        ↓
tournament.fixture.reschedule
```

and the actual check is conceptually:

```text
can(
  user,
  tournamentId,
  "tournament.fixture.reschedule"
)
```

So:

> **Roles describe people. Capabilities authorize actions.**

This follows the same direction you already chose for Matchday teams and matches.

---

# 5.2 Three authority scopes

For the current Matchday architecture, I would keep only three principal operational scopes:

```text
TEAM
TOURNAMENT
MATCH
```

I would **not** introduce Stage-level RBAC yet.

A future tournament might eventually have a dedicated Stage Manager, but that is not required for the current product and would complicate the authorization system unnecessarily.

So:

```text
TEAM SCOPE
Team owner / manager / captain permissions

TOURNAMENT SCOPE
Tournament owner / tournament manager permissions

MATCH SCOPE
Assigned scorer / assigned operational grants
```

This is enough for the tournament system we have designed.

---

# 5.3 The authority hierarchy

For a tournament match:

```text
Tournament
   │
   ├── Tournament Owner
   ├── Tournament Managers
   │
   └── Fixtures
          │
          └── Match
                ├── Assigned Scorer
                ├── Assigned Officials
                │
                ├── Team A
                └── Team B
```

But the arrows do **not** mean everybody below inherits authority.

In particular:

```text
Team A authority
     ✕
Tournament match scoring
```

and:

```text
Team B authority
     ✕
Tournament match scoring
```

Teams are participants.

Tournament management governs the competition.

---

# 5.4 The core resolver rule

This should eventually become one of our strongest backend invariants.

Conceptually:

```text
authorizeMatchAction(user, match, action)
```

does this:

```text
                    match
                      │
              tournament_id?
               /            \
             YES             NO
              │               │
              ▼               ▼
    TOURNAMENT AUTHORITY   STANDALONE
           POLICY         MATCH POLICY
              │               │
              │               ├── team authority
              │               ├── setup_side
              │               ├── batting-side policy
              │               └── match grants
              │
              ├── tournament capability
              └── match-specific grant
```

And critically:

```text
Tournament match
    ↓
DO NOT check
team_can(teamA, match.score)

DO NOT check
team_can(teamB, match.score)
```

That is the leak we identified in Step 1.

---

# 5.5 Tournament Owner

There should be exactly one authoritative tournament owner.

The owner is the tournament's root authority.

Conceptually:

```text
Tournament
created by Saran
     ↓
Tournament Owner = Saran
```

The owner should receive all tournament capabilities automatically.

That should not mean every database operation bypasses security. It means the capability resolver recognizes ownership as the root entitlement.

The owner can manage the tournament, registration, draw, fixtures, officials, scoring, results, managers, communication, completion, and exceptional recovery.

But I would reserve a small set of **ownership-level actions** that even ordinary managers cannot perform:

| Action | Owner | Manager |
|---|---:|---:|
| Manage normal tournament configuration | ✓ | ✓ |
| Manage registrations | ✓ | ✓ |
| Manage draw | ✓ | ✓ |
| Manage fixtures | ✓ | ✓ |
| Score tournament matches | ✓ | ✓ |
| Assign scorer/official | ✓ | ✓ |
| Result correction | ✓ | capability-based |
| Cancel tournament | ✓ | possibly capability-based |
| Abandon tournament | ✓ | possibly restricted |
| Add/remove managers | ✓ | possibly limited |
| Transfer tournament ownership | ✓ | ✗ |
| Remove original owner | through transfer only | ✗ |
| Permanently delete draft tournament | ✓ | ✗ |

This protects the root account from accidentally being locked out.

---

# 5.6 Tournament Manager

I would make `Tournament Manager` a powerful operational role.

Not a glorified viewer.

By default, a tournament manager should be able to run the tournament in the owner's absence.

For example:

```text
Tournament Owner
      ↓
appoints
      ↓
Tournament Manager
```

Manager can then:

```text
review teams
lock entries
prepare draw
publish fixtures
reschedule fixtures
assign scorers
record tournament match toss
start matches
score matches
resolve operational incidents
post tournament announcements
```

That matches how real grassroots tournaments work: multiple people frequently operate different grounds.

But ownership/security actions stay with the owner.

---

# 5.7 Tournament Owner/Manager scoring authority

This is the point you made at the beginning.

Suppose:

```text
Match 12
Lahore Lions vs Kasur Kings

Assigned scorer: Ahmed
```

Ahmed has match-scoped:

```text
match.score
```

But Tournament Owner also has tournament-derived authority.

Therefore:

```text
Ahmed
    ↓ match scope
match.score

Tournament Owner
    ↓ tournament scope
tournament.match.score
```

Both are authorized.

Then the scorer lease decides who is actually entering balls.

```text
AUTHORIZED TO SCORE

Owner     ✓
Manager   ✓
Scorer    ✓


ACTIVELY SCORING

Ahmed's phone only
```

If the owner takes over:

```text
Ahmed lease
    ↓ handover/revoke
Owner lease
```

This is a concurrency question, not an authorization question.

---

# 5.8 Tournament capabilities should be explicit

I recommend a capability vocabulary roughly like this:

| Capability | Meaning |
|---|---|
| `tournament.profile.edit` | Name, artwork, description, public metadata |
| `tournament.settings.edit` | Competition-level settings |
| `tournament.publish` | Publish tournament |
| `tournament.registration.manage` | Open/close registration |
| `tournament.registration.review` | Approve/reject applications |
| `tournament.payment.manage` | Record tournament entry payments |
| `tournament.entries.manage` | Manage accepted entries before lock |
| `tournament.entries.lock` | Freeze competitive field |
| `tournament.squad.review` | Approve/manage squad eligibility |
| `tournament.structure.manage` | Configure stages/groups/progression |
| `tournament.draw.manage` | Create/regenerate draft draw |
| `tournament.draw.publish` | Publish authoritative draw |
| `tournament.fixture.schedule` | Set schedule/ground |
| `tournament.fixture.reschedule` | Change schedule after publication |
| `tournament.match.setup` | Operate tournament Match Start |
| `tournament.match.score` | Score tournament matches |
| `tournament.official.assign` | Assign scorers/officials |
| `tournament.result.override` | Correct/override authoritative match result |
| `tournament.announcement.send` | Send organizer communication |
| `tournament.awards.manage` | Publish awards |
| `tournament.complete` | Exceptional administrative completion action |
| `tournament.cancel` | Cancel before competition |
| `tournament.abandon` | Terminate started tournament |
| `tournament.staff.manage` | Appoint/remove tournament managers |
| `tournament.ownership.transfer` | Transfer root ownership |

The names can be refined later, but the **separation of powers** is what matters.

---

# 5.9 Why not simply give managers `match.score`?

Because scope matters.

If we simply grant:

```text
match.score
```

globally to a tournament manager, what does that mean?

Potentially:

> Score every match in Matchday.

Obviously wrong.

Instead:

```text
Tournament Manager
   │
   │ tournament scope
   ▼
tournament.match.score
```

means:

> This person may score matches whose authoritative parent is this tournament.

Then:

```text
Assigned Scorer
   │
   │ match scope
   ▼
match.score
```

means:

> This person may score this exact match.

That is much cleaner.

---

# 5.10 Derived child authority

This gives us an important concept:

> **Tournament capabilities may authorize actions on child fixtures and matches.**

Example:

```text
User:
Tournament Manager of Tournament T1

Capability:
tournament.fixture.reschedule on T1
```

Then they can reschedule:

```text
Match M25
```

only if:

```text
M25.tournament_id == T1
```

Likewise:

```text
tournament.match.score(T1)
```

authorizes scoring:

```text
M25
```

because M25 belongs to T1.

It does not authorize scoring:

```text
M88
```

from another tournament.

This is hierarchical authorization without having to physically create thousands of duplicate grants.

---

# 5.11 Match-scoped grants remain important

Tournament scope doesn't replace match scope.

Match-specific authority is perfect for:

```text
Scorer
Umpire
Temporary operator
Emergency replacement
```

Example:

```text
Tournament Match M20

Ali
assigned as scorer
```

Backend creates:

```text
scope = match
entity = M20
permission = match.score
subject = Ali
```

Your existing system already effectively does this.

I checked the live project again: `mirror_scorer_grant()` currently creates a match-scoped `match.score` grant when someone receives the `scorer` role.

That's a good mechanism to preserve conceptually.

---

# 5.12 Assigned Scorer

An assigned scorer should have a deliberately narrow authority surface.

They should be allowed to operate their fixture, not manage the tournament.

Conceptually:

| Capability | Assigned scorer |
|---|---:|
| View tournament operations | limited/relevant |
| Record tournament toss | ✓ |
| Configure match-start state | ✓ |
| Start assigned match | ✓ |
| Score match | ✓ |
| End innings | ✓ |
| Finalize normal sporting result | through sport engine |
| Reschedule match | ✗ |
| Change draw | ✗ |
| Approve teams | ✗ |
| Assign another scorer | ✗ |
| Override finalized result | ✗ |
| Cancel tournament | ✗ |

For Cricket, the scorer likely needs:

```text
cricket.match.setup
match.score
```

for their assigned match.

The important part is that this comes from a **match assignment**, not from their team relationship.

---

# 5.13 Official

Officials should have even narrower authority.

For example:

```text
Main umpire
Leg umpire
Third umpire
Match referee
```

Being assigned as an official does not automatically grant:

```text
match.score
```

unless the product explicitly says that official also acts as scorer.

Therefore:

```text
Official Assignment
≠
Scoring Assignment
```

One person could hold both roles only if tournament policy permits it, but those authorities should remain independently represented.

---

# 5.14 Team Owner / Team Manager

Now we cross into participating-team authority.

Their scope is their **Team**, not the tournament itself.

They can:

```text
register team for tournament
withdraw application where allowed
manage registration information
submit eligible squad
manage their team's players
respond to organizer requests
```

And potentially:

```text
submit playing lineup
```

for a tournament fixture.

They cannot automatically:

```text
score tournament match
record tournament toss
reschedule tournament fixture
change tournament draw
assign tournament scorer
override result
```

This separation is extremely important.

---

# 5.15 Team Captain

Captain is more interesting.

In standalone matches, captain currently has substantial Match Start/scoring authority.

That makes sense for your 1-to-1 system.

But:

```text
CAPTAIN
```

must mean something different inside a tournament authority context.

For tournament fixtures, captain may have participant-side operations:

```text
confirm XI
confirm captain/keeper
view toss result
receive operational notifications
communicate with scorer/organizer
```

Potentially they could submit:

```text
playing XI
```

if we decide that product workflow.

But:

```text
captain
    ≠
tournament scorer
```

That should be explicit.

---

# 5.16 Current backend mismatch

This is one place where our new standard will materially change the audit later.

Today the generic team role matrix gives:

```text
owner   → match.score
manager → match.score
captain → match.score
```

and also:

```text
owner   → cricket.match.setup
manager → cricket.match.setup
captain → cricket.match.setup
```

That's valid for standalone matches.

The current problem is `_can_score_innings()` does not first separate tournament matches from standalone matches.

So the current reasoning is effectively:

```text
Is user batting-side captain?
        OR
Does batting team give match.score?
        OR
Does user have match grant?
```

What we need later is:

```text
IF tournament-linked:
    tournament capability
    OR match grant
ELSE:
    standalone team policy
    OR match grant
```

Again, no implementation yet—but Step 5 makes the expected behavior unambiguous.

---

# 5.17 Player

A normal player should not have administrative authority merely because they are registered in the tournament.

They should have participant access such as:

```text
view their team's tournament information
view schedule
view squad status
view match room
receive relevant notifications
participate in tournament chat if that is the product rule
```

But no tournament mutation capability by default.

This is where we should distinguish:

```text
ACCESS
```

from:

```text
AUTHORITY
```

A player may be entitled to see private participant information without having the right to modify tournament state.

---

# 5.18 Spectator

Spectator authority is effectively:

```text
READ PUBLIC DATA
```

They can view:

```text
public tournament profile
teams
fixtures
live scores
standings
bracket
stats
results
```

subject to privacy settings.

No operational capabilities.

If a tournament is private/invite-only, spectator visibility follows tournament visibility rules rather than role authorization.

We'll probably need to revisit public/private/unlisted semantics later.

---

# 5.19 Owner vs Manager vs capability

There is another architectural choice worth freezing:

I would make:

```text
Owner
```

a special root relationship.

But:

```text
Manager
```

should simply be a role bundle.

That means in the future the owner could create something like:

```text
Operations Manager
```

who receives:

```text
fixture.schedule
fixture.reschedule
official.assign
announcement.send
```

but not:

```text
registration.review
draw.publish
result.override
```

Or:

```text
Registration Manager
```

with a different bundle.

We do **not** have to expose custom tournament roles in v1.

But capability-based internals make that future possible.

---

# 5.20 Lifecycle and authority are independent

This is one of the most important points in Step 5.

Suppose Manager has:

```text
tournament.draw.manage
```

Does that mean they can regenerate the draw while the final is being played?

No.

Authorization consists of two questions:

```text
QUESTION 1
May this user perform this class of action?

QUESTION 2
Is this action legal in the tournament's current state?
```

So:

```text
AUTHORIZED
=
Capability
AND
Domain Guard
```

Example:

```text
Manager
has tournament.draw.manage
```

but:

```text
draw_state = published
competition_state = in_progress
```

therefore:

```text
regenerate draw
DENIED BY DOMAIN STATE
```

Not because the manager lost permission.

Because that transition is no longer legal.

---

# 5.21 Example: Registration Review

User has:

```text
tournament.registration.review
```

During:

```text
registration = OPEN
```

they can approve/reject.

After:

```text
entries = LOCKED
```

an ordinary approval command should fail even though they still possess the capability.

This avoids stuffing lifecycle logic into RBAC.

---

# 5.22 Example: Fixture reschedule

Manager has:

```text
tournament.fixture.reschedule
```

If fixture is:

```text
scheduled
```

allow.

If fixture is:

```text
live
```

ordinary reschedule:

```text
DENY
```

Maybe an interruption/recovery command exists instead.

If match is:

```text
completed
```

deny.

Again:

```text
capability
+
resource state
```

---

# 5.23 Example: Tournament Result Override

This should be one of the most privileged capabilities:

```text
tournament.result.override
```

And even with it:

```text
result override
```

should require:

```text
reason
actor
timestamp
previous result
replacement result
affected downstream objects
```

Because changing:

```text
Semi-final winner
```

may affect:

```text
Final participants
Champion
Standings
Stats
Notifications
```

So capability alone isn't sufficient.

The command itself must perform consistency checks.

---

# 5.24 Authority inheritance must only go downward through known relationships

Allowed:

```text
Tournament capability
       ↓
Tournament's own fixtures
       ↓
Tournament's own matches
```

Not allowed:

```text
Tournament capability
       ↓
Participant Team administration
```

A tournament manager should **not** suddenly receive:

```text
team.roster.write
team.staff.appoint
team.profile.write
```

over participating teams.

Tournament authority controls tournament participation.

Team authority controls the team itself.

For example, tournament manager may:

```text
remove player from tournament eligibility
```

if rules permit.

But they should not:

```text
remove player from Lahore Lions globally
```

Very important boundary.

---

# 5.25 Likewise Team authority does not go upward

Team manager may manage:

```text
Lahore Lions
```

but they do not thereby gain:

```text
tournament.draw.manage
tournament.fixture.reschedule
tournament.result.override
```

just because Lahore Lions participates.

So the relationship is:

```text
Tournament
     ↕ participation contract
Team
```

not:

```text
Tournament owns Team
```

or:

```text
Team owns tournament match
```

---

# 5.26 Registration authorization

This should use the team's existing authority model.

You already have:

```text
team.tournament.enter
```

and in the live role matrix it is currently granted by default to:

```text
Owner
Manager
```

but not Captain.

I think that is a sensible default.

A captain can be important on the field without automatically being allowed to commit the organization to entry fees, registration, and tournament participation.

If a specific team wants captains to register it later, the team permission matrix can allow that intentionally.

That's exactly why capability-based RBAC is useful.

---

# 5.27 Tournament staff membership

Conceptually, I would move toward something like:

```text
TournamentMembership

user_id
tournament_id
role
status
```

with:

```text
Owner
Manager
```

and perhaps future custom roles.

Today the database instead has:

```text
created_by
organizers[]
```

and:

```text
is_tournament_organizer()
```

returns true if the user is either one.

That means today:

```text
Owner
Manager
```

are effectively collapsed into:

```text
Organizer = true
```

which is too coarse for the authority model we've now designed.

I would classify that later as:

```text
REFACTOR
```

not because it is inherently broken, but because it cannot represent the permissions we now need cleanly.

---

# 5.28 We should not use `organizers[]` as the long-term authorization model

Arrays are fine for lightweight metadata.

They're poor authorization relations once we need:

```text
who added manager?
when?
what role?
what capabilities?
active/suspended?
removed when?
audit?
```

The moment those questions matter, a normalized membership relation becomes more appropriate.

Again: implementation later.

But our canonical domain should assume **Tournament Membership**, not simply `uuid[]`.

---

# 5.29 Direct grants

Your current RBAC already has a useful concept:

```text
grants
```

with:

```text
subject
scope
entity
permission
expiry
granted_by
```

That is very useful for operational exceptions.

Example:

```text
Saran appoints Ali to score Match 123
```

No need to make Ali a Tournament Manager.

Just grant:

```text
scope = match
entity = Match123
permission = match.score
```

possibly with expiry.

Likewise temporary operational access can be narrow rather than role escalation.

This is a design I would preserve.

---

# 5.30 Avoid giving direct tournament grants for everything initially

There's a balance here.

I wouldn't start by letting owners individually grant every one of twenty tournament capabilities to arbitrary people.

That UI would be too complex.

V1 can expose:

```text
Owner
Manager
Scorer
Official
```

while the backend remains capability-driven.

So:

```text
Simple UX
+
Flexible domain model
```

rather than:

```text
Simple domain model
+
hardcoded roles everywhere
```

---

# 5.31 Capability categories

The authority model can be thought of as:

```text
TOURNAMENT ADMINISTRATION
profile/edit/publish/staff

PARTICIPATION
registration/entries/squads

COMPETITION DESIGN
structure/draw/qualification

OPERATIONS
fixtures/grounds/officials/announcements

MATCH OPERATIONS
setup/scoring

INTEGRITY / EXCEPTIONS
result override/cancel/abandon

OWNERSHIP
transfer/delete
```

This grouping will later help design the organizer management UI.

---

# 5.32 Lifecycle authority matrix

Here is how authority tightens as the tournament advances:

| Area | Draft | Registration | Upcoming | Live | Completed |
|---|---|---|---|---|---|
| Profile metadata | broad edit | edit | limited | limited | very limited |
| Sport | changeable | effectively locked | locked | locked | locked |
| Structure | editable | limited | locked after draw | locked | locked |
| Registration | configure | manage | closed | closed | closed |
| Entries | editable | manage | locked | exceptional only | historical |
| Draw | draft | prepare | published/revision only | highly restricted | historical |
| Schedule | prepare | prepare | reschedule | operational reschedule | historical |
| Scorers | prepare | prepare | assign | assign/handover | historical |
| Scoring | unavailable | unavailable | unavailable until fixture starts | ✓ | no normal scoring |
| Result override | none | none | none | privileged | audited correction |
| Cancel | ✓ | ✓ | ✓ | normally use abandon | no |
| Abandon tournament | no | no | no | ✓ | no |
| Ownership transfer | ✓ | ✓ | ✓ | ✓ with caution | possible administrative |

Notice that roles haven't changed.

The **legal actions** changed because the domain state changed.

---

# 5.33 Server must be authoritative

Flutter should absolutely use capability checks to decide:

```text
show button?
enable action?
```

But Flutter is only UX.

The server must independently check:

```text
authentication
capability
scope
parent relationship
resource state
lifecycle
command invariants
```

For example:

```text
Hide "Publish Draw" button
```

in Flutter.

Fine.

But someone calling the RPC manually must still be rejected if they lack:

```text
tournament.draw.publish
```

or if:

```text
entries != locked
```

UI is never security.

---

# 5.34 RLS versus command authorization

Another distinction we should keep when we eventually implement this in Supabase.

RLS answers questions such as:

```text
May this user read this row?
May this user update this row?
```

But complex tournament commands should generally not be modeled as:

```text
client updates five tables directly
```

For example:

```text
Publish Draw
```

may affect:

```text
draw revision
fixtures
slots
match shells
notifications
audit
```

That's a domain command.

Likewise:

```text
Override Result
```

is not a generic row update.

So our eventual architecture should treat:

```text
RLS
```

as data-access protection, while:

```text
server command / RPC
```

enforces complex business authorization and transitions.

Your existing tournament code has already moved several complex operations into RPCs. That direction is correct.

---

# 5.35 One security concern for the eventual audit

Many of the current tournament RPCs are `SECURITY DEFINER`.

That's not automatically wrong, especially when an atomic command needs controlled privileged access.

But it means every such command has to verify its caller itself because `SECURITY DEFINER` can bypass RLS.

The Supabase security guidance explicitly warns about this.

So during the later implementation audit, every tournament mutation function should be reviewed for:

```text
authentication
capability check
entity ownership/scope
lifecycle validation
search_path
EXECUTE privileges
audit behavior
```

We're not auditing them yet, but Step 5 gives us the checklist.

---

# 5.36 Canonical authority model

Putting everything together:

```text
                         USER
                          │
            ┌─────────────┼──────────────┐
            │             │              │
            ▼             ▼              ▼
       TEAM ROLE     TOURNAMENT ROLE   MATCH GRANT
            │             │              │
            ▼             ▼              ▼
      Team capability  Tournament      Match capability
                       capability
            │             │              │
            └─────────────┼──────────────┘
                          ▼
                 AUTHORITY RESOLVER
                          │
                    resource scope
                          │
                          ▼
                   DOMAIN GUARDS
                          │
                   lifecycle/state
                          │
                          ▼
                       COMMAND
```

And for a tournament match specifically:

```text
Tournament Match
      │
      ├── Tournament Owner
      │       tournament.match.*
      │
      ├── Tournament Manager
      │       tournament.match.*
      │
      ├── Assigned Scorer
      │       match-scoped setup/score
      │
      ├── Assigned Official
      │       official-specific authority
      │
      ├── Team Manager/Captain
      │       participant-side capabilities only
      │
      └── Player
              participation/read access
```

That is the authority hierarchy I would freeze.

---

## Step-5 standard

The principles I would now put into our Tournament Standard are:

1. **Roles never directly authorize operations; capabilities do.** Roles provide default capability bundles.
2. **Team, Tournament and Match are separate authorization scopes.**
3. **Tournament Owner is the root authority and cannot accidentally be stripped of ownership powers.**
4. **Tournament Manager is a powerful operational role but does not automatically receive ownership-transfer/destructive powers.**
5. **Tournament capabilities may authorize actions on child fixtures and matches belonging to that tournament.**
6. **Tournament-linked matches use Tournament authority + Match-specific grants only; participating-team match capabilities do not leak into tournament scoring.**
7. **Assigned Scorer receives narrow match-scoped setup/scoring authority.**
8. **Officials and scorers are separate assignments.**
9. **Team managers/captains retain participant-side authority but do not govern tournament matches.**
10. **Authorization and lifecycle legality are separate checks: `capability AND domain guard`.**
11. **Tournament authority never grants administration over the participating Team entity itself.**
12. **Team authority never grants Tournament administration merely because that team participates.**
13. **Direct match grants remain the mechanism for temporary/narrow operational delegation.**
14. **The server is authoritative; Flutter capability checks are UX only.**
15. **Complex tournament mutations are domain commands, not unrestricted client row updates.**

This also exposes the biggest structural gap in the current system: **Teams and Matches already have a real capability engine, while Tournaments still mostly have `is_tournament_organizer()`**. Later, when we audit implementation, that will be one of the central refactors.

The next logical step is **Step 6 — Registration → Tournament Entry → Squad Model**. That is where we define the full journey from a team clicking “Join Tournament,” through pending/approved/rejected states, fees, entry locking, squad eligibility, withdrawal/replacement, squad freezing, and what happens when a team or player changes after the draw has been published.




Yes. Step 6 is the point where we stop treating `tournament_teams` as “one row that means everything about a team in a tournament.”

Right now that row carries application state, approved participation, squad, seed, group, and payment information together. That is workable for an early implementation, but conceptually these are **different lifecycles**.

The standard I would freeze is:

```text
TEAM
 │
 │ applies / invited
 ▼
REGISTRATION
 │
 │ approved
 ▼
TOURNAMENT ENTRY
 │
 ├── eligibility / payment
 │
 ├── tournament squad
 │
 ├── seed
 │
 └── stage/group assignment
       │
       ▼
COMPETITION PARTICIPANT
```

The most important rule is:

> **A registration is a request to participate. A Tournament Entry is the accepted competitive participant. A Tournament Squad is the set of players eligible to represent that entry.**

Those three things should no longer be treated as synonyms.

---

# Step 6 — Registration → Entry → Squad

## 6.1 The three concepts

### Registration

A registration answers:

> “Does this team want to enter this tournament, and what is the organizer's decision?”

For example:

```text
Lahore Lions
applies to
Kasur Champions Cup
```

That's a registration.

---

### Tournament Entry

Once approved:

```text
Lahore Lions
     ↓
accepted
     ↓
Tournament Entry
```

The entry answers:

> “Which participant officially occupies a place in this tournament?”

This is what should later receive:

```text
seed
group
qualification status
fixture positions
payments
entry status
```

---

### Tournament Squad

The squad answers:

> “Which players are eligible to represent this tournament entry?”

For example:

```text
Lahore Lions Tournament Entry
        │
        └── Tournament Squad
              ├── Player A
              ├── Player B
              ├── Player C
              └── ...
```

That is separate from the global Lahore Lions roster.

---

# 6.2 Why the distinction matters

Imagine:

```text
Lahore Lions team roster:
25 players
```

but the tournament allows:

```text
Maximum tournament squad:
16 players
```

Then:

```text
Team roster != Tournament squad
```

And when Match 4 begins:

```text
Tournament squad:
16 eligible players

Playing XI:
11 selected for Match 4
```

Therefore:

```text
TEAM ROSTER
   ↓
TOURNAMENT SQUAD
   ↓
MATCH LINEUP
```

Three different levels.

This is a very important boundary.

---

# 6.3 Complete participant journey

I would define the normal flow as:

```text
Registration Opens
       │
       ▼
Team Applies
       │
       ▼
PENDING
       │
       ├── REJECTED
       │
       ├── WITHDRAWN
       │
       └── APPROVED
              │
              ▼
      Tournament Entry
              │
              ▼
         ACTIVE ENTRY
              │
              ├── Squad prepared
              ├── Payment handled
              ├── Seed assigned
              └── Group assigned
                      │
                      ▼
                Entries Locked
                      │
                      ▼
               Draw / Fixtures
                      │
                      ▼
                  Competition
```

This gives every transition a clear meaning.

---

# 6.4 Registration states

Your current states are:

```text
pending
approved
rejected
withdrawn
```

These are good **application** states.

I would keep that conceptual model, with one potential extension:

```text
PENDING
WAITLISTED     optional future
APPROVED
REJECTED
WITHDRAWN
```

I would not introduce waitlist unless we actually want the product flow.

For v1:

```text
PENDING
APPROVED
REJECTED
WITHDRAWN
```

is enough.

---

# 6.5 Pending

`PENDING` means:

> The team has applied, but it has not yet been granted a tournament place.

A pending application should **not**:

```text
consume a seed
appear in draw
appear in standings
receive group assignment
be treated as tournament participant
```

It can appear in:

```text
Organizer → Registration Requests
```

and:

```text
Team → Application Status
```

---

# 6.6 Approved

Approval should mean something stronger than simply:

```text
status = approved
```

Conceptually:

> **Approval creates/activates a Tournament Entry.**

Therefore:

```text
Registration
PENDING
    ↓ approve
APPROVED

and

TournamentEntry
ACTIVE
```

This matters because later the application may remain useful as historical evidence:

```text
who applied
when
who approved
approval message
decision reason
```

while the entry becomes the competitive object.

---

# 6.7 Rejected

A rejected registration:

```text
registration = REJECTED
```

should never create an active tournament entry.

It should retain:

```text
registered_by
registered_at
decided_by
decided_at
reason
```

for organizer/team history.

Whether rejected teams can reapply should be a tournament policy.

For v1 I would allow:

```text
Organizer reopens/reconsiders application
```

through a deliberate action rather than creating duplicate registrations.

---

# 6.8 Withdrawn application

Before approval:

```text
Team applies
     ↓
Pending
     ↓
Withdraw Application
     ↓
WITHDRAWN
```

This is simple.

But after approval we should stop calling it merely “withdraw registration.”

Once approved, the team is no longer merely an applicant.

They have an Entry.

Therefore:

```text
Pending application withdrawal
≠
Tournament entry withdrawal
```

That distinction becomes critical after the draw.

---

# 6.9 Registration uniqueness

A team should have only one active registration relationship to a tournament.

You don't want:

```text
Lahore Lions
Pending
Pending
Approved
Withdrawn
```

four independent current rows because somebody tapped twice.

Conceptually:

```text
unique active registration per:
tournament + team
```

Retries should be idempotent.

Historical transitions should be captured through audit/history, not duplicate logical applications.

---

# 6.10 Registration authorization

From Step 5:

```text
team.tournament.enter
```

should control whether someone may register a team.

Today your default roles give that capability to:

```text
Team Owner
Team Manager
```

not Captain.

I think that is a good default.

Registration can involve:

```text
entry fees
squad commitments
competition dates
organizational commitments
```

so captain shouldn't automatically be able to enter the whole team unless the team explicitly grants it.

---

# 6.11 Registration preconditions

A team should be able to apply only when all of these are true:

```text
user has team.tournament.enter
registration_state = OPEN
team sport == tournament sport
team not already actively registered
team satisfies basic tournament restrictions
capacity policy allows application
```

Potential tournament restrictions later:

```text
location
age category
gender/category
club affiliation
ranking
invitation
```

Those should be tournament eligibility policy, not hard-coded into generic registration logic.

---

# 6.12 Public vs private tournament registration

We need two entry paths.

### Public tournament

```text
Team
  ↓
Apply
  ↓
Pending
```

### Invite-only tournament

Organizer may:

```text
Invite Team
```

then:

```text
Invitation
    ↓
Team Accepts
    ↓
Tournament Entry
```

or, if the product is simpler:

```text
Organizer Directly Adds Team
```

with acceptance/notification rules.

This means there are potentially different **entry sources**:

```text
application
invitation
organizer_add
```

I would preserve that concept even if v1 only implements applications.

---

# 6.13 Invitation is not the same thing as approval

This distinction matters.

Imagine:

```text
Tournament Organizer
invites Lahore Lions
```

That should not necessarily mean:

> Lahore Lions has accepted the dates, rules and entry fee.

A safer flow is:

```text
INVITED
   ↓ team accepts
ACTIVE ENTRY
```

For grassroots tournaments, however, organizers may sometimes directly add known teams.

So later product design can support both:

```text
Invite
Direct Add
```

But we shouldn't confuse those semantics.

---

# 6.14 Tournament capacity

Suppose:

```text
maxTeams = 8
```

What consumes one of those eight spots?

I recommend:

```text
Active Tournament Entry
```

not:

```text
Pending Registration
```

So:

```text
5 pending
7 approved
max 8
```

means:

```text
7 / 8 confirmed
```

not 12/8.

Once the eighth entry is accepted:

```text
capacity = full
```

new applications can be blocked or perhaps placed on a future waitlist.

---

# 6.15 Payment is a separate state

This is very important.

Current `tournament_teams` contains both:

```text
status
payment_status
amount_paid
payment_channel
...
```

That's already hinting at the correct separation.

We should formally say:

```text
Registration Decision
≠
Payment State
```

A team could be:

```text
APPROVED
UNPAID
```

or:

```text
APPROVED
PARTIALLY_PAID
```

or:

```text
APPROVED
PAID
```

depending on tournament rules.

So do **not** invent statuses like:

```text
approved_paid
approved_unpaid
```

Keep the state dimensions separate.

---

# 6.16 Payment lifecycle

Conceptually:

```text
NOT_REQUIRED
```

or:

```text
UNPAID
   ↓
PARTIAL
   ↓
PAID
```

with corrections possible.

And since your product currently records offline payments rather than processing payments, payment information is an organizer ledger:

```text
amount
channel
reference
recorded_by
recorded_at
```

This is not a payment gateway state machine.

---

# 6.17 Does payment block approval?

This should be tournament policy.

Two reasonable flows:

### Flow A

```text
Approve team
    ↓
Team gets confirmed slot
    ↓
Payment due later
```

### Flow B

```text
Conditional acceptance
    ↓
Payment received
    ↓
Confirmed entry
```

For Matchday v1, I would keep the domain simple:

> Approval and payment remain independent, but **Entry Lock** can require payment completion if the tournament's rules say payment is mandatory.

So:

```text
Approved + unpaid
```

can exist.

But:

```text
Lock Entries
```

may warn or block:

> “2 approved teams have unpaid required fees.”

That's cleaner than coupling payment to registration state.

---

# 6.18 Tournament Entry lifecycle

Once approved, I would define the entry state conceptually as:

```text
ACTIVE
   ├── WITHDRAWN
   └── DISQUALIFIED
```

I would **not** add `completed` to each entry merely because the tournament completed.

The tournament itself becoming completed already gives the historical context.

Potential future:

```text
REPLACED
```

but I think replacement should be represented explicitly through an amendment/replacement relationship rather than merely a status label.

---

# 6.19 Active Entry

`ACTIVE` means:

> This team currently occupies a competitive place in this tournament.

Only active entries may:

```text
receive seed
receive group
appear in draw
appear in standings
appear in tournament fixtures
qualify
win tournament
```

This is the object Tournament Core should reason about.

---

# 6.20 Entry withdrawal before lock

This is straightforward.

```text
Entry = ACTIVE
Entries = EDITABLE
      ↓
Team Withdraws
      ↓
Entry = WITHDRAWN
```

Remove it from active participant count.

No competition history exists yet.

Safe.

---

# 6.21 Withdrawal after entry lock but before draw publication

Still manageable, but now organizer should be involved.

```text
Entries = LOCKED
Draw = DRAFT/NOT_CREATED
```

If Team B withdraws:

```text
unlock/revise entry set
remove Team B
revalidate minimum participants
reseed
regenerate draft
lock again
```

This is no longer just a team-side “Withdraw” button.

The organizer needs to accept the structural consequence.

---

# 6.22 Withdrawal after draw publication

Now it's an **administrative competition event**.

You cannot simply:

```text
DELETE tournament_entry
```

because published fixtures may reference it.

Possible treatments:

```text
replace team
award bye
award walkovers
redraw
```

depending on whether any match has started and tournament policy.

So:

> **After draw publication, Tournament Entries become historical structural references and should never simply disappear.**

This should be a frozen rule.

---

# 6.23 Withdrawal after tournament starts

Now it is even stronger.

Suppose:

```text
Lahore Lions
played 2 group matches
then withdraws
```

You must preserve:

```text
past matches
scores
statistics
standings history
```

Then the competition policy determines future consequences.

Possibilities:

```text
future walkovers
entry disqualification
results retained
results voided
```

That is sport/tournament policy territory.

The system should never delete history.

---

# 6.24 Disqualification

A tournament organizer may need:

```text
Disqualify Team
```

This is different from voluntary withdrawal.

Conceptually:

```text
ACTIVE
   ↓ organizer/rules action
DISQUALIFIED
```

Requires:

```text
reason
actor
timestamp
```

and potentially consequences:

```text
future fixtures
previous results
standings
qualification
```

Those should be handled by a dedicated command.

---

# 6.25 Replacement team

Replacement is another major edge case.

Imagine an 8-team knockout:

```text
Entry set locked
Draw published
Tournament not started
```

One team drops out.

Organizer finds another team.

A replacement should be modeled as:

```text
Entry A
withdrawn
     │
     │ replaced by
     ▼
Entry B
```

with an audit relationship.

The new team may inherit:

```text
the same bracket slot
schedule
seed position
```

only if organizer explicitly approves that.

It should not pretend the new team was the original entry.

This preserves history.

---

# 6.26 Now the Tournament Squad

This is where the current `squad uuid[]` becomes conceptually insufficient.

A plain array answers:

```text
Which UUIDs?
```

but not:

```text
who added player?
when?
was player eligible?
was player later removed?
was player replaced?
what was squad at lock time?
why was amendment approved?
```

For a serious tournament system, the squad is a first-class relation.

Conceptually:

```text
TournamentEntry
       │
       └── TournamentSquadMember
              player identity
              status
              added_at
              added_by
              eligibility
              amendment history
```

Again, we're not deciding schema yet.

But the domain must treat squad membership as more than `uuid[]`.

---

# 6.27 Squad source

The squad should normally be selected from the team's global roster.

```text
Team Roster
   │
   ├── Player A
   ├── Player B
   ├── Player C
   ├── Player D
   └── ...
        ↓ choose eligible players
Tournament Squad
```

If Matchday supports unclaimed players, that same identity system should continue to work.

Tournament should not invent an unrelated player identity model.

---

# 6.28 Team roster changes should not automatically mutate tournament squad

This is important.

Suppose Player A is in the tournament squad.

Later someone removes Player A from the team's general roster.

Should that silently remove them from the tournament history?

No.

The tournament needs a stable participation record.

Likewise, adding a player to the team's global roster after squad lock should not automatically make them tournament-eligible.

So:

```text
Team Roster = current organization roster

Tournament Squad = competition eligibility snapshot/relation
```

They are linked but not identical.

---

# 6.29 Squad lifecycle

I would define:

```text
EDITABLE
    ↓
FROZEN
```

Potentially with:

```text
FROZEN
    ↓ approved amendment
FROZEN (new revision)
```

The squad remains frozen conceptually; an authorized exception modifies it through an audited amendment.

---

# 6.30 When should squad freeze?

Not necessarily at registration close.

For example:

```text
Oct 1    Registration opens
Oct 10   Registration closes
Oct 11   Entries finalized
Oct 13   Draw published
Oct 14   Squad deadline
Oct 15   Tournament begins
```

This can be perfectly valid.

Therefore:

```text
registration deadline
≠
entry lock
≠
squad lock
```

Three different concepts.

That's exactly why the lifecycle model needed multiple state dimensions.

---

# 6.31 Could squad lock happen before draw publication?

Yes.

Some tournaments require final squad first.

Others allow squad submission after fixtures.

So the dependency should be policy-driven.

But before a player is used in a match:

```text
player must be tournament-eligible
```

unless a tournament manager approves an exception.

That is the hard invariant.

---

# 6.32 Squad limits

The sport/tournament configuration may define:

```text
minimum squad size
maximum squad size
```

For cricket:

```text
11–18
```

as an example depending on local rules.

Tournament Core can understand:

```text
minimum participants
maximum participants
```

but Cricket/sport configuration may provide recommended/default values.

The same multi-sport boundary from Step 3 applies.

---

# 6.33 Squad eligibility

Before adding a player, check things such as:

```text
belongs to/authorized for this team
not duplicated
sport-specific eligibility
not already conflicting with tournament rules
within squad-size limit
```

Potential future rules:

```text
age
gender/category
foreign-player limit
club registration
transfer deadline
```

These belong to configurable eligibility policy rather than generic Flutter checks.

---

# 6.34 Player cannot casually play for two teams in the same tournament

This should be a tournament policy we decide deliberately.

For most team competitions I would default to:

> **One person may represent only one active Tournament Entry within the same tournament.**

So:

```text
Player X
Lahore Lions squad ✓

Player X
Kasur Kings squad ✗
```

unless a future sport/tournament explicitly allows something else.

The server should enforce this rather than simply trusting UI.

---

# 6.35 Squad vs Playing XI

Once we reach a fixture:

```text
Tournament Squad
       ↓
Eligible players
       ↓
Match lineup
```

For Cricket:

```text
Tournament Squad: 16

Match 1 XI: 11
Match 2 XI: maybe different 11
```

The sport match engine chooses the match participants from tournament-eligible players.

This keeps the boundaries clean:

```text
Tournament:
Who CAN play?

Match:
Who IS playing?
```

---

# 6.36 Tournament organizer's authority over squad

Tournament manager should not manipulate the team's general roster.

But they may have tournament-level authority to:

```text
approve/reject squad amendment
mark player ineligible
approve replacement
freeze/unfreeze tournament eligibility
```

Again:

```text
Tournament authority
controls tournament eligibility

Team authority
controls team membership
```

Do not cross those boundaries.

---

# 6.37 Team-side squad authority

Team managers should normally be able to:

```text
submit initial squad
edit while squad is editable
request amendment after freeze
```

but not simply bypass tournament rules.

So a later capability might be:

```text
team.tournament.squad.manage
```

or we may initially derive this from `team.tournament.enter`.

I would prefer a distinct capability eventually because entering a tournament and managing a squad are separate actions.

---

# 6.38 Squad amendments after freeze

Suppose a player is injured after squads freeze.

The flow should be:

```text
Team Manager
     ↓
Request Replacement

Player A OUT
Player B IN
Reason: injury
     ↓
Tournament Manager
     ↓
Approve / Reject
```

If approved:

```text
Squad Revision 2
```

not:

```text
silently mutate array
```

Audit should retain:

```text
old member
new member
reason
requested_by
approved_by
approved_at
```

This will matter in disputes.

---

# 6.39 Match lineup eligibility validation

When Cricket Match Start selects playing XI:

```text
Match Player
```

should be accepted only if:

```text
player belongs to active tournament entry squad
```

for tournament matches.

Standalone matches follow their own roster rules.

So:

```text
IF match.tournament_id != null:
    validate tournament eligibility
ELSE:
    standalone roster logic
```

This is another example of context-sensitive match policy.

---

# 6.40 Entry lock and draw generation

From Step 4:

```text
Registration Closed
        ↓
Resolve pending registrations
        ↓
Active Entries finalized
        ↓
LOCK ENTRIES
        ↓
Seed / Groups
        ↓
Generate Draw
```

So the draw must use:

```text
Tournament Entries
```

not raw registration rows.

That is a major conceptual correction.

The draw should never contain:

```text
Pending registration
Rejected application
Withdrawn application
```

Only:

```text
ACTIVE ENTRY
```

---

# 6.41 Seed belongs to Entry

Today `seed_number` sits in `tournament_teams`.

Conceptually the idea is correct, but it belongs to the **Entry**, not the application.

Likewise:

```text
group assignment
```

belongs to an Entry's participation in a Stage.

Actually, after Step 2 we can be even more precise:

```text
seed
```

might be stage-specific.

And:

```text
group
```

definitely belongs to stage participation.

For v1 we can keep them simpler, but our domain terminology should recognize this.

---

# 6.42 Group assignment is not registration data

Current row contains:

```text
group_id
```

beside:

```text
registered_by
status
payment
```

Conceptually those are unrelated stages of the lifecycle.

`group_id` exists only after:

```text
accepted entry
competition structure
stage/group allocation
```

So in the future audit I would classify that row as **overloaded**.

Again, not necessarily “wrong database,” but one table is currently representing too many distinct aggregates.

---

# 6.43 Registration chat behavior

Your live backend currently adds members of an approved team to the tournament chat when the registration becomes approved.

That implies:

```text
Approval
   ↓
participant communication access
```

That may be a reasonable rule.

But we should make it explicit.

For example:

```text
Pending team:
No tournament participant chat

Approved/active entry:
Participant chat access

Withdrawn/disqualified:
Access revoked or read-only?
```

The product decision belongs to Communication/Social rules, but Entry status should drive membership—not raw team identity.

---

# 6.44 Privacy of registration/payment/squad data

There is another important conceptual rule.

Public users may need to see:

```text
Participating teams
maybe public squad
```

but they should not automatically see:

```text
payment reference
payment channel
application message
organizer decision notes
internal registration metadata
```

Today those concepts coexist on `tournament_teams`.

So later we need to ensure public participant views do not accidentally expose administrative columns.

This is part of the eventual security/data-boundary audit.

---

# 6.45 Organizer registration screen should therefore separate concepts

Instead of one giant row:

```text
Lahore Lions
Pending
12 players
Rs 5,000
Group A
Seed #3
```

the organizer UX should reflect lifecycle.

### Applications

```text
PENDING REQUESTS

Lahore Lions
Applied Sep 27
Squad draft: 14
Message...
[Reject] [Approve]
```

### Confirmed Teams

```text
CONFIRMED ENTRIES

Lahore Lions
Fee: Paid
Squad: 14/16
Entry: Active
```

### Competition Preparation

```text
DRAW / SEEDING

#1 Lahore Lions
Group A
```

Different operational contexts.

---

# 6.46 What happens when organizer rejects?

A rejection should not destroy submitted information immediately.

Keep enough history for:

```text
audit
reconsideration
team status display
```

But public users don't need to see it.

If organizer reconsiders before entries lock:

```text
Rejected
    ↓
Approve
```

we can either allow state reversal with audit or provide a dedicated reconsider command.

I favor explicit transition history rather than destructive replacement.

---

# 6.47 What if approved team later fails payment?

Do not silently change:

```text
APPROVED → REJECTED
```

because approval happened historically.

Instead organizer performs an entry action:

```text
Remove/Withdraw Entry
Reason: payment not completed
```

before entry lock.

After entry lock it becomes a structural amendment.

Again:

```text
Registration decision
≠
current entry participation
```

This separation solves a lot of awkward state changes.

---

# 6.48 What if team changes owner/manager?

No problem.

Tournament Entry belongs to:

```text
team_id
```

not to the person who originally registered it.

`registered_by` remains audit metadata.

Current active team authorities determine who can manage the team's tournament participation now.

So if:

```text
Ali registered Lahore Lions
```

and later Ali leaves the team:

```text
Lahore Lions remains entered.
```

Correct.

---

# 6.49 What if team itself is disbanded?

Before tournament start:

```text
Organizer intervention required
```

probably withdraw/replace entry.

After competition starts:

```text
Preserve historical team snapshot/reference
apply withdrawal/disqualification policy
```

Again, tournament history cannot depend entirely on current mutable Team state.

---

# 6.50 Identity snapshots

This leads to another subtle point.

For historical tournament data, you may eventually want to preserve some display snapshots:

```text
team name at competition time
team logo
player display name
jersey number
```

because global profiles can change later.

Your match system already uses some snapshots such as `match_teams.team_name`.

That's a good pattern.

But this is implementation detail for later.

The core principle is:

> Tournament history should remain intelligible even if Team/Profile data changes later.

---

# 6.51 Entry readiness

Before Lock Entries, each approved Entry can have a readiness summary.

For example:

```text
Lahore Lions

✓ Approved
✓ Required fee paid
✓ Minimum squad submitted
✓ Team still active
! Missing captain declaration
```

Organizer can then see:

```text
7 / 8 entries ready
```

This is much better than blindly locking whatever happens to have `status = approved`.

---

# 6.52 Hard blockers vs warnings

For `Lock Entries`, classify requirements.

### Hard blockers

```text
minimum tournament teams not met
unresolved required registration decision
duplicate active entry
invalid sport
invalid tournament structure
required eligibility failure
```

### Tournament-policy blockers

```text
mandatory fee unpaid
minimum squad not submitted
```

### Warnings

```text
team logo missing
some contact detail missing
optional payment reference missing
```

This keeps preparation predictable.

---

# 6.53 What should be immutable after entry lock?

Normally:

```text
participant identity
```

becomes structurally locked.

Things like:

```text
payment metadata
contact info
squad (until its own deadline)
```

may still change.

So don't interpret:

```text
Entries Locked
```

as:

> Entire registration row is immutable.

It means:

> **The set of competitive participants is frozen.**

Very different.

---

# 6.54 What should be immutable after squad freeze?

Eligibility membership should become locked except through amendment.

But player display/profile information can still be updated where appropriate.

Again, freeze semantic decisions, not every byte.

---

# 6.55 Canonical model

Putting all of Step 6 together:

```text
TEAM
 │
 │ team.tournament.enter
 ▼
REGISTRATION
 │
 ├── pending
 ├── rejected
 └── withdrawn
 │
 │ approve
 ▼
TOURNAMENT ENTRY
 │
 ├── active
 ├── withdrawn
 └── disqualified
 │
 ├── Payment State
 │      unpaid / partial / paid
 │
 ├── Entry Readiness
 │
 ├── TOURNAMENT SQUAD
 │      │
 │      ├── editable
 │      └── frozen
 │
 └── Stage Participation
        │
        ├── seed
        ├── group
        ├── rank
        └── qualification
```

Then:

```text
Tournament Squad
      ↓
eligible players

Match Lineup
      ↓
actual players for one fixture
```

---

# 6.56 How the current implementation maps

The current `tournament_teams` row has:

```text
registration_id
tournament_id
team_id
registered_by
status
squad[]
seed_number
group_id

payment_status
amount_paid
payment_channel
payment_reference

decision metadata
```

That means one row currently acts as:

```text
Registration
+
Tournament Entry
+
Tournament Squad
+
Payment Ledger
+
Seed Assignment
+
Group Assignment
```

This is the biggest Step-6 architectural finding.

It doesn't mean we immediately split it into six tables.

It means when we audit implementation, we should classify each responsibility and decide what deserves a first-class relation.

---

# 6.57 There's also a current lifecycle mismatch

The current RLS permits team registration when tournament status is either:

```text
registration
OR
draft
```

Under the lifecycle standard we just defined, a normal team should not be able to submit a registration simply because the tournament is a draft.

A draft is an organizer workspace.

So later I would expect registration admission to depend on:

```text
registration_state = open
```

rather than:

```text
tournament.status in (draft, registration)
```

That's a concrete future audit issue.

---

# 6.58 Current update authority is also too broad conceptually

The current `tournament_teams` UPDATE policy allows either:

```text
team manager
OR
tournament organizer
```

to update the row.

But because that row currently contains many responsibilities, a single broad UPDATE authority risks mixing domains.

Conceptually, Team Manager should control:

```text
application message
squad while editable
withdrawal request
```

while Tournament Manager controls:

```text
approval
decision reason
payment ledger
seed
group
entry status
```

Those are not the same permissions.

This is another reason one overloaded mutable row becomes difficult to secure.

We will inspect exact exposure and command paths during the implementation audit.

---

# 6.59 Step-6 standard to freeze

I would now add these rules to the Tournament Standard:

1. **Registration, Tournament Entry, and Tournament Squad are three separate domain concepts.**
2. **Registration represents intent/application; approval creates or activates a Tournament Entry.**
3. **Only active Tournament Entries participate in the competition structure.**
4. **Pending/rejected/withdrawn registrations never enter the draw.**
5. **Payment state is independent from registration decision state.**
6. **Tournament capacity is consumed by confirmed active Entries, not pending applications.**
7. **Entries become structurally locked before authoritative draw publication.**
8. **Before Entry Lock, participant changes are cheap; after Draw Publication they require structural amendment.**
9. **An Entry must never simply be deleted after it has become part of published or played competition history.**
10. **Voluntary withdrawal and organizer disqualification are separate events.**
11. **Team replacement must preserve the identity/history of the replaced Entry.**
12. **Tournament Squad represents competition eligibility and is distinct from the global Team roster.**
13. **Team roster changes do not silently rewrite the historical/frozen tournament squad.**
14. **Tournament Squad and Match Lineup are different: `who may play` vs `who is playing this match`.**
15. **Squad lifecycle is independent from registration lifecycle: Editable → Frozen → audited amendments.**
16. **Tournament matches must validate lineups against tournament eligibility.**
17. **Seed/group assignment belong to competitive participation, not to the application itself.**
18. **Organizer authority over tournament eligibility must not become authority over the team's global roster.**
19. **Registration/admin/payment information must be separable from public participant data.**
20. **Draw generation must operate on finalized Tournament Entries, never directly on raw registration rows.**

At this point our standard has a very coherent chain:

```text
Step 1  Match/Tournament Ownership
Step 2  Tournament Structure
Step 3  Multi-Sport Boundary
Step 4  Lifecycle
Step 5  Authority
Step 6  Registration → Entry → Squad
```

The logical **Step 7 is Draw, Seeding, Fixture Generation & Progression**. That is where we can define exactly how Knockout, Round Robin, Groups + Knockout and eventually Double Elimination generate fixtures, how seeds/slots/qualifiers work, when a draw becomes authoritative, how revisions work, and how a completed match advances the correct participant without corrupting downstream fixtures.



Yes. Step 7 is where the tournament engine becomes **deterministic**. Once we freeze this part, a fixture should never exist just because some UI happened to create a `matches` row. Every fixture should exist because the competition graph says it belongs there.

The core principle for Step 7 is:

> **Entries determine placement. Placement creates fixture slots. Slot sources determine participants. Match results resolve those sources. Tournament progression follows the graph.**

That gives us this pipeline:

```text
Active Tournament Entries
          ↓
      Entry Lock
          ↓
     Seeding / Placement
          ↓
       Draw Draft
          ↓
     Draw Publication
          ↓
      Fixture Graph
          ↓
      Matches Played
          ↓
 Authoritative Results
          ↓
   Resolve Next Slots
          ↓
 Stage / Tournament Progression
```

# Step 7 — Draw, Seeding, Fixture Generation & Progression

## 7.1 Start with one vocabulary correction

We have been using the word **draw**, but there are really several concepts.

I would define them as:

| Term | Exact meaning |
|---|---|
| **Seeding** | Competitive ordering of entries before placement |
| **Placement** | Assigning entries/qualification sources into structural positions |
| **Draw Plan** | Draft description of the competition graph before publication |
| **Fixture** | One contest position in that graph |
| **Fixture Slot** | One participant position within a fixture |
| **Slot Source** | Rule that resolves who occupies a slot |
| **Draw Publication** | Making one revision of that graph authoritative |
| **Progression** | Resolving future slots from completed competition outcomes |
| **Bracket** | Visual projection of elimination fixtures and feeder paths |

This distinction is very important.

---

# 7.2 Seeding does not mean the same thing for every stage

For knockout, seeding affects **who can meet whom and when**.

For example:

```text
Seed 1
Seed 2
Seed 3
Seed 4
Seed 5
Seed 6
Seed 7
Seed 8
```

A traditional balanced bracket may place them so:

```text
QF1   Seed 1 vs Seed 8
QF2   Seed 4 vs Seed 5
QF3   Seed 2 vs Seed 7
QF4   Seed 3 vs Seed 6
```

The purpose is normally to prevent the strongest seeds from meeting too early.

Toornament likewise models bracket opponents using seed positions and feeder relationships such as previous-match winners or losers. :chatgpt-content-reference{index="0"}

For round robin, however:

```text
Seed #1
```

doesn't normally determine an elimination path.

Instead it may influence:

```text
group allocation
schedule order
home/away order
balanced group distribution
```

So the generic term should still be **Seeding**, but each Stage Format decides how seeding affects placement.

---

# 7.3 Seeding source

The tournament system should not assume seeding always comes from one algorithm.

Conceptually, the organizer should be able to choose a method such as:

```text
Manual
Random
Previous-stage ranking
Historical/rating-based
```

Your existing Flutter seeding screen already has:

```text
Manual
Random
Past form
```

which is a good product direction.

But I would change the internal meaning slightly.

The output of any method should simply be:

```text
Seed 1 → Entry A
Seed 2 → Entry B
Seed 3 → Entry C
...
```

The draw engine should not care how those seeds were decided.

This keeps:

```text
Seeding Logic
```

separate from:

```text
Placement Logic
```

---

# 7.4 Previous-stage ranking is especially important

Once we support:

```text
Group Stage
     ↓
Playoffs
```

playoff seeding should commonly come from Stage 1.

Example:

```text
Group A #1
Group A #2
Group B #1
Group B #2
```

The next stage could place:

```text
SF1
A1 vs B2

SF2
B1 vs A2
```

Notice that these are **not teams yet** when the tournament is originally designed.

They are qualification sources:

```text
group_position(A, 1)
group_position(B, 2)
```

This is why Fixture Slot Sources matter so much.

---

# 7.5 The Fixture Slot Source model

I think this should become one of the most important abstractions in Matchday's Tournament Core.

A fixture:

```text
Fixture X
 ├── Slot A
 └── Slot B
```

Each slot has a source.

Conceptually, the source can be:

| Source | Example |
|---|---|
| Direct Entry | Lahore Lions |
| Seed | Seed #1 |
| Previous Fixture Winner | Winner of QF1 |
| Previous Fixture Loser | Loser of SF1 |
| Group Position | Group A #1 |
| Stage Position | Regular Season #3 |
| Bye | automatic advancement |
| Administrative replacement | replacement entry |

Toornament's custom-bracket system uses essentially the same idea: a match participant can come from a seed, the winner of an earlier match, or the loser of an earlier match. :chatgpt-content-reference{index="1"}

That's strong external confirmation that our Step-2 slot model is the right abstraction.

---

# 7.6 Direct entry vs source rule

This distinction matters.

Round-one knockout:

```text
QF1

Slot A:
direct Entry A

Slot B:
direct Entry H
```

Semi-final:

```text
SF1

Slot A:
winner(QF1)

Slot B:
winner(QF2)
```

Third-place fixture:

```text
3rd Place

Slot A:
loser(SF1)

Slot B:
loser(SF2)
```

Group-to-knockout:

```text
SF1

Slot A:
group_position(A, 1)

Slot B:
group_position(B, 2)
```

So future participants are not represented with fake null team IDs.

They are unresolved **sources**.

That is a much more precise domain model.

---

# 7.7 Fixture identity must exist before participant resolution

This is important.

A semi-final can exist before we know who plays it.

For example:

```text
Fixture:
SF1

Scheduled:
Saturday 4 PM

Ground:
Main Ground

Slot A:
Winner QF1

Slot B:
Winner QF2
```

This is a perfectly valid fixture.

Therefore:

> **Participant resolution is not required for Fixture existence.**

But:

> **Both required participant slots must resolve before the actual sporting match can start.**

That boundary will help enormously later.

---

# 7.8 Fixture vs Match again

From Step 2:

```text
Fixture
= competition position

Match
= sporting execution
```

For Matchday v1, they may still physically share records.

That's okay.

But the domain should behave as though:

```text
Fixture determines:
who should play
where
when
what stage/round
what feeds afterward

Match determines:
what actually happened
```

If we keep that separation, database evolution becomes much easier.

---

# 7.9 Draw Plan

Before publication, the organizer needs a pure draft representation.

Conceptually:

```text
DrawPlan

stage
revision candidate
seed ordering
groups
rounds
fixtures
slot sources
schedule
grounds
validation result
```

Your existing `DrawPlan` is actually a strong start.

It already has:

```text
DrawFixture
DrawBye
roundCount
```

and unresolved future rounds point to:

```text
prevSlotAId
prevSlotBId
```

That's the correct general idea.

---

# 7.10 One thing I like in your current implementation

Your code explicitly uses the **same `DrawPlan` object for preview and publishing**.

The comment says, essentially:

> what the organizer sees is what gets published.

That is exactly right.

We should preserve that principle.

Never have:

```text
UI Preview Algorithm
```

and separately:

```text
Backend Draw Algorithm
```

producing potentially different structures.

The ideal model is:

```text
Server or canonical domain engine
        ↓
Draw Plan
   ↙          ↘
Preview      Publish
```

or, if the client constructs it:

```text
one deterministic canonical plan
        ↓
validated server-side
        ↓
persisted exactly
```

The key is **one definition of the structure**.

---

# 7.11 Current knockout generator

Your current generator already does several sensible things:

```text
next power-of-two bracket
standard seed placement
strong seeds receive byes
complete later-round fixture graph
winner feeder links
```

For example, 6 teams:

```text
Bracket size = 8

Seeds 1–6 occupy bracket positions
2 empty positions
       ↓
2 byes
```

That is a sensible single-elimination approach.

---

# 7.12 Bye must not become a fake match

Your current `DrawBuilder` makes another good architectural choice.

When one side of a first-round pairing is empty:

```text
Seed 1 vs EMPTY
```

it does not create a real match with one team.

Instead:

```text
Seed 1
   ↓ BYE
next round
```

That's correct.

Because:

> **A bye is structural advancement, not a match result.**

There should be:

```text
no score
no scorer
no toss
no winner calculation
```

The Tournament Engine simply resolves the next slot.

---

# 7.13 Bye placement

By default, if we use competitive seeding, the highest seeds should normally receive available byes.

Example:

```text
6 teams
8-slot bracket
```

gives two byes to higher seeds under the selected placement algorithm.

But we should not hard-code the philosophical rule:

> “Top seed always deserves bye.”

The Stage Placement Policy should decide.

Possible future options:

```text
Seeded
Random
Manual
```

Again:

```text
Draw structure
```

doesn't need to know why a particular entry occupies a slot.

---

# 7.14 Draw publication

This needs to become a first-class domain event.

Before publication:

```text
Draw Revision Candidate
```

can be regenerated repeatedly.

Example:

```text
Generate
Shuffle
Swap seed
Change group
Regenerate
```

No historical complexity.

Then organizer clicks:

```text
Publish Draw
```

At that moment:

```text
revision = 1
status = published
published_by
published_at
```

and fixtures become authoritative.

Teams can now rely on:

```text
opponents
qualification paths
schedule
grounds
```

---

# 7.15 Published draw should be immutable as a revision

This is subtle.

I do **not** mean the tournament can never change.

I mean:

> Published revision 1 should never silently mutate into something else.

Instead:

```text
Draw Revision 1
published
        ↓
structural change required
        ↓
Draw Revision 2
published
```

with audit information.

So:

```text
revision 1
```

remains historical truth about what was originally announced.

---

# 7.16 Why revisions matter

Suppose:

```text
QF1
A vs H

QF2
D vs E
```

was published.

Then H withdraws before play.

Organizer decides to replace H with Team X.

If we simply modify:

```text
QF1
A vs X
```

there's no record that H was originally there.

Instead:

```text
Draw Revision 1
A vs H

Draw Revision 2
A vs X

Reason:
H withdrew

Changed by:
Tournament Manager
```

Now disputes are understandable.

---

# 7.17 Structural change vs schedule change

This should become an explicit distinction.

### Structural revision

Changes:

```text
participant
slot source
seed
group
round relationship
qualification route
fixture existence
```

Requires a new draw revision after publication.

### Operational scheduling change

Changes:

```text
date
time
ground
scorer
official
```

does not necessarily require a new structural draw revision.

Instead it is:

```text
Fixture Schedule Revision
```

or simply audited operational changes.

This distinction keeps the competition graph stable.

---

# 7.18 Fixture generation should be stage-driven

Today the implementation takes:

```text
TournamentType
```

and generates the whole tournament.

After Step 2, I would want:

```text
Tournament
   ↓
Stages
   ↓
each Stage has Competition Format
```

Therefore generation becomes:

```text
generateStageFixtures(stage)
```

rather than:

```text
generateTournamentFixtures(tournamentType)
```

For example:

```text
Stage 1
Round Robin

Stage 2
Single Elimination
```

Each has its own generator.

That is much more scalable.

---

# 7.19 Single elimination generation

Conceptually:

```text
Active Stage Entries
       ↓
Seed Order
       ↓
Bracket Placement
       ↓
Round 1 Fixtures
       ↓
Winner Sources
       ↓
Round 2 Fixtures
       ↓
...
       ↓
Final
```

The complete graph should exist from publication.

That means don't create the semi-final only after the quarter-final finishes.

Create:

```text
SF1:
winner(QF1) vs winner(QF2)
```

in advance.

This allows:

```text
schedule
ground assignment
official planning
public bracket
```

before participants resolve.

Your current DrawPlan already follows this principle.

Good.

---

# 7.20 Round Robin generation

Round robin is different.

For `N` entries, single round-robin generates each pair once.

For even `N`:

```text
rounds = N - 1
matches per round = N / 2
```

For odd `N`, conceptually add a phantom bye participant so one real team rests each round.

Your current implementation uses the circle method and already handles this.

That is a good algorithmic foundation.

---

# 7.21 Double round robin

Do not create a separate Stage Format.

From Step 2:

```text
format = round_robin
cycles = 2
```

Then:

```text
Cycle 1
A vs B

Cycle 2
B vs A
```

For sports without home/away semantics, it still means every pair plays twice.

The Sport Adapter may decide whether side ordering matters.

---

# 7.22 Group stage generation

Groups should be decided before group fixtures are generated.

Example:

```text
16 teams
4 groups
4 teams per group
```

Then:

```text
Group A
4 entries
→ round robin

Group B
4 entries
→ round robin

...
```

Each group runs the Stage's configured competition format.

This means:

```text
Group
```

is essentially a participant partition within a Stage.

---

# 7.23 Group placement strategies

Group assignment should support at least:

```text
Manual
Random
Seed-balanced
```

Seed-balanced usually means avoiding putting all top seeds into one group.

A serpentine-type assignment is commonly used by tournament systems; Challonge's current group management supports automatic group assignment using a serpentine system while also allowing manual changes. :chatgpt-content-reference{index="2"}

Conceptually:

```text
Seeds:
1 2 3 4 5 6 7 8
```

into two groups could distribute:

```text
Group A:
1,4,5,8

Group B:
2,3,6,7
```

depending on the chosen snake placement.

The exact algorithm is policy.

The domain needs only a deterministic placement result.

---

# 7.24 Group → Knockout progression

This is where our Slot Sources really pay off.

Imagine:

```text
2 groups
Top 2 qualify
```

Knockout stage can be preconfigured:

```text
SF1
Slot A = Group A #1
Slot B = Group B #2

SF2
Slot A = Group B #1
Slot B = Group A #2
```

At draw publication those slots remain unresolved.

Then once group standings are finalized:

```text
Group A #1 = Lahore
Group A #2 = Falcons

Group B #1 = Kings
Group B #2 = Warriors
```

Tournament Core resolves:

```text
SF1
Lahore vs Warriors

SF2
Kings vs Falcons
```

No new competition topology is generated.

Only previously defined slot sources resolve.

That's exactly what we want.

---

# 7.25 Stage progression should be explicit

When Stage 1 completes:

```text
Sport Adapter
      ↓
Final Rankings

Tournament Core
      ↓
Qualification Rules

Tournament Core
      ↓
Resolve Stage 2 slot sources

Stage 2
      ↓
ACTIVE
```

This should be a transactional/server operation.

We do not want Flutter doing:

```text
read standings
calculate qualifiers
update next matches
```

because two devices could disagree or race.

---

# 7.26 Result-driven progression

For knockout, progression should occur from an **authoritative finalized result**.

Not from:

```text
score happens to look complete
```

and not merely from:

```text
winner_side was changed manually
```

The flow should be:

```text
Sport Match Engine
     ↓
Finalizes Result
     ↓
MatchResultFinalized event/command
     ↓
Tournament Core verifies fixture relationship
     ↓
Resolve winner-dependent slot(s)
     ↓
Persist progression
```

Exactly once.

---

# 7.27 Idempotency is essential

Suppose a completion event is delivered twice.

Bad system:

```text
Event 1:
Lahore inserted into semifinal

Event 2:
Lahore inserted again
duplicate / corruption
```

Correct system:

```text
resolve source:
winner(QF1)
```

is idempotent.

After it is already resolved to Lahore:

```text
same result
→ no-op
```

This needs to be designed from the beginning.

---

# 7.28 Source resolution, not copying winners around blindly

Instead of thinking:

```text
QF1 completes
↓
update SF1.team_a = winner
```

think:

```text
SF1 Slot A
source = winner(QF1)

QF1 result finalized
       ↓
resolve source
       ↓
resolved_entry = Lahore
```

That distinction becomes extremely useful for revisions and auditing.

We can always answer:

> Why is Lahore in this semifinal?

Because:

```text
source = winner(QF1)
QF1 winner = Lahore
```

Excellent traceability.

---

# 7.29 Results changing after progression

This is one of the hardest tournament problems.

Suppose:

```text
QF1
Lahore beats Kasur

SF1
Lahore vs Falcons
```

Then organizer corrects QF1:

```text
Actually Kasur won.
```

What happens?

It depends on downstream state.

---

# 7.30 Safe correction: downstream match not started

If:

```text
SF1 = scheduled
not live
```

then we can potentially recalculate:

```text
SF1 Slot A
winner(QF1)
       ↓
Kasur
```

and replace Lahore automatically.

But:

```text
audit
notification
schedule implications
```

must happen.

---

# 7.31 Dangerous correction: downstream match already started

Suppose:

```text
SF1
Lahore vs Falcons
already LIVE
```

and then QF1 is overturned.

We cannot silently replace Lahore with Kasur in a match already underway.

That would corrupt competition history.

So:

> **A result override must analyze all downstream dependents before it commits.**

Possible response:

```text
Result cannot be automatically changed because
dependent fixture SF1 has already started.
```

Then organizer needs a dedicated administrative recovery workflow.

This is why Step 5 made `tournament.result.override` highly privileged.

---

# 7.32 Downstream dependency graph

The system needs to know:

```text
QF1
 ↓ winner
SF1
 ↓ winner
FINAL
```

Therefore correcting QF1 can identify:

```text
affected fixtures:
SF1
Final potentially
```

This is another reason a graph model is stronger than scattered `team_a/team_b` updates.

---

# 7.33 Published graph should not have cycles

A fixture cannot eventually feed itself.

Bad:

```text
Match A winner
  ↓
Match B

Match B winner
  ↓
Match A
```

So Draw Validation must prove the graph is acyclic.

For our current head-to-head structures, this should be a directed acyclic graph:

```text
DAG
```

except that more advanced formats like bracket reset still need controlled conditional edges, not arbitrary cycles.

---

# 7.34 Draw validation before publication

Before a plan becomes authoritative, server should validate things such as:

| Validation | Purpose |
|---|---|
| All source references valid | no broken feeders |
| No cycles | valid progression graph |
| No fixture references itself | obvious corruption prevention |
| Every active entry placed correctly | no team forgotten unintentionally |
| No duplicate entry where format forbids it | integrity |
| Stage participant count valid | format requirement |
| Slot source type valid | structural consistency |
| Qualification source exists | group/stage progression |
| Seeds unique | deterministic placement |
| Required final path exists | competition can finish |
| No impossible participant collision | structural safety |

This should not live only in Flutter.

---

# 7.35 Draw publication should be atomic

You don't want:

```text
QF1 created
QF2 created
network failure
SF1 missing
Final missing
```

Draw publication is one domain command.

It should either:

```text
publish entire graph
```

or:

```text
publish nothing
```

Your existing `tournament_generate_fixtures()` RPC already moves in this direction by inserting the full plan in one database transaction.

That's good.

---

# 7.36 But fixture generation should not trust arbitrary client topology forever

Today Flutter sends:

```text
p_slots JSON
```

containing things such as:

```text
slot_id
team_a_id
team_b_id
prev_slot_a
prev_slot_b
round
schedule
venue
```

The RPC verifies some things, especially that direct teams are approved entries.

But long-term, once structure becomes core infrastructure, I would want server-side validation of:

```text
allowed stage format
expected fixture count
valid feeder topology
entry lock
draw state
capability
revision
```

not simply “the submitted JSON references approved teams.”

Again, implementation later.

---

# 7.37 Draw scheduling should not be tightly coupled to topology generation

Your current `_Scheduler` does both:

```text
generate bracket
+
assign dates/grounds
```

That is convenient, but these are conceptually separate.

I would define:

```text
COMPETITION GRAPH
Who plays whom / how progression works
```

and:

```text
SCHEDULE
When and where fixtures happen
```

Why?

Because organizers frequently know:

```text
bracket now
```

but schedule later.

Or:

```text
we have two grounds today,
three grounds tomorrow.
```

Topology should not change because a ground became unavailable.

---

# 7.38 Therefore generation can become two phases

Conceptually:

```text
Stage Placement
       ↓
Fixture Graph
       ↓
Scheduling Engine / Organizer
       ↓
dates + grounds
```

UI can still offer:

```text
Auto Schedule
```

which produces a schedule automatically.

But we should not make:

```text
9 AM / Ground 1
```

part of the mathematical bracket itself.

---

# 7.39 Scheduling constraints

Eventually auto-scheduling should consider:

```text
ground availability
team rest time
previous feeder completion
official availability
scorer conflicts
day boundaries
tournament hours
```

Your current scheduler already makes one good assumption:

> a later knockout round begins on a new day.

But that is a product assumption, not universal competition logic.

Some local tournaments play:

```text
Quarterfinal 9 AM
Semifinal 1 PM
Final 6 PM
```

on the same day.

So future scheduling must be configurable rather than tied to bracket generation.

---

# 7.40 A fixture can be structurally ready but not schedule-ready

Example:

```text
SF1
Winner QF1 vs Winner QF2
```

Topology valid.

But:

```text
date = TBD
ground = TBD
```

This should be allowed.

So we need to distinguish:

```text
STRUCTURALLY DEFINED
```

from:

```text
SCHEDULED
```

Again, different dimensions.

---

# 7.41 Round-robin standings progression

Round robin doesn't resolve:

```text
winner → next match
```

after every fixture.

Instead:

```text
Match result
      ↓
Sport Adapter updates standings
      ↓
rankings change
```

Only at a qualification checkpoint does Tournament Core resolve stage positions.

So there are two types of progression:

```text
FIXTURE-DEPENDENT

winner(QF1)
→ SF1
```

and:

```text
RANKING-DEPENDENT

Group A #1
→ SF1
```

Both should use the same Slot Source abstraction.

---

# 7.42 Qualification should not be resolved too early

Suppose:

```text
Group A
```

still has two matches remaining.

Current table says:

```text
1 Lahore
2 Kasur
3 Falcons
```

We should not prematurely assign:

```text
SF1 = Lahore
```

unless Lahore's position is mathematically locked *and* we intentionally support early resolution.

For v1, simpler rule:

> **Resolve ranking-based qualification when the relevant Stage/Group is finalized.**

This avoids edge cases.

---

# 7.43 Group qualification rules

Tournament Core should own rules such as:

```text
Top 2 from each group
Best 2 third-place teams
Group winners only
Top 4 overall
```

But it should consume rankings produced by the Sport Adapter.

Example:

```text
qualification_rule:
top_n_per_group = 2
```

Tournament Core knows:

```text
position 1 qualifies
position 2 qualifies
```

It does not know how NRR determined position 2.

---

# 7.44 Cross-group qualification

Future example:

```text
4 groups
Top 2 each
+
2 best third-place teams
```

This introduces:

```text
cross-group ranking
```

Again the Tournament Core can define:

```text
select best N from rank position 3
```

while the Sport Adapter supplies comparison/tie-break logic.

We don't need this in v1 immediately, but our model shouldn't block it.

---

# 7.45 Re-seeding between knockout rounds

Some competitions don't use a static bracket.

Instead:

```text
after each round
highest remaining seed
plays
lowest remaining seed
```

That's **re-seeding**.

Our initial Matchday format should probably use:

```text
fixed bracket
```

because it's much simpler and expected for grassroots cups.

But the Stage Format configuration can later define:

```text
progression_mode = fixed_bracket
```

versus:

```text
progression_mode = reseed_each_round
```

Do not build the latter yet.

---

# 7.46 Double elimination

We should now place double elimination correctly.

It is a Stage Format with:

```text
Winners Bracket
Losers Bracket
Grand Final
```

A participant generally isn't eliminated until the configured second loss.

Progression sources need both:

```text
winner(previous fixture)
```

and:

```text
loser(previous fixture)
```

which our Slot Source model already supports conceptually.

Toornament explicitly models double elimination with an upper and lower bracket and loser progression; it also supports different Grand Final/reset configurations. :chatgpt-content-reference{index="3"}

Your current enum already contains:

```text
double_elimination
```

but the current `DrawBuilder` intentionally returns it as unsupported.

That is actually better than generating an incorrect single-elimination bracket.

Keep it unsupported until the correct graph engine exists.

---

# 7.47 Group + Knockout

Likewise, your current:

```text
group_knockout
```

returns unsupported.

After Step 2, this should eventually disappear as a Stage Format anyway.

Instead:

```text
Stage 1:
round_robin

Stage 2:
single_elimination
```

with qualification sources.

That makes the implementation cleaner than writing a special:

```text
_generateGroupKnockoutTournament()
```

function.

---

# 7.48 League

Same principle.

No special league generator needed at structural level if:

```text
Regular Season
format = round_robin
cycles = 1 or 2
```

then optional:

```text
Playoffs
format = single_elimination
```

This is why Step 2 mattered before Step 7.

---

# 7.49 Third-place playoff

Third-place should be optional configuration on an elimination Stage.

Conceptually:

```text
Third Place Fixture

Slot A:
loser(SF1)

Slot B:
loser(SF2)
```

No special `tournament_type`.

No weird detached manually-created match.

Just another fixture whose Slot Sources come from the two semifinals.

---

# 7.50 Match cancellation inside a bracket

This is tricky.

Once a bracket fixture exists, simply setting:

```text
cancelled
```

leaves progression unresolved.

Tournament operations need to specify the consequence.

For example:

```text
cancelled + no replacement
```

is not enough.

We need something such as:

```text
reschedule
walkover to A
walkover to B
competition abandoned
```

because the graph needs a result or administrative resolution.

So:

> **Every terminal fixture in a progression path must provide a progression outcome or explicitly terminate the path.**

That's a strong rule.

---

# 7.51 Walkover progression

Suppose:

```text
QF2

Team B doesn't appear.
```

Organizer records:

```text
Walkover winner = Team A
```

Then from Tournament Core's perspective:

```text
fixture outcome:
ADVANCER = Team A
```

The same progression engine resolves:

```text
winner(QF2)
```

into the semifinal.

No special manual update is required.

This is why a generic authoritative outcome is valuable.

---

# 7.52 No Result inside elimination

This cannot just remain unresolved forever.

If Stage requires decisive progression and Sport Engine returns:

```text
NO_RESULT
```

Tournament Core should detect:

```text
this fixture requires an advancer
```

and require a tournament/sport-specific resolution:

```text
replay
reschedule
tie-break procedure
administrative advancement
```

Tournament Core does not invent the sport rule.

But it understands:

> progression requirement remains unsatisfied.

---

# 7.53 Versioning and concurrency

Imagine two tournament managers editing the draw simultaneously.

Manager A publishes revision based on:

```text
entries_version = 8
```

Meanwhile Manager B removes a team.

A should not publish a stale draw.

So draw publication should eventually use optimistic concurrency:

```text
expected entry revision
expected draw revision
```

If changed:

```text
Conflict:
Tournament entries changed.
Regenerate the draw.
```

This is especially important once multiple managers operate the same tournament.

---

# 7.54 Entry lock version

I would conceptually attach a revision to the competitive field.

For example:

```text
Entry Set Revision 4
```

Draw Revision 1 is created from:

```text
Entry Set Revision 4
```

Then we can prove:

```text
these fixtures were created from these exact entries
```

If entries later change:

```text
Entry Set Revision 5
```

existing draft plan becomes stale.

That's extremely useful for consistency.

---

# 7.55 Event trail

The Tournament Engine should be able to record events such as:

```text
entries_locked
draw_generated
draw_published
fixture_rescheduled
fixture_result_finalized
slot_resolved
stage_completed
stage_activated
draw_revised
```

We don't necessarily need a full event-sourced architecture.

But these are useful audit events.

The important point is:

> tournament progression should be explainable.

---

# 7.56 Progression source of truth

This should be:

```text
Tournament Competition Graph
```

not:

```text
Flutter bracket widget
```

The bracket widget merely reads the graph.

Similarly:

```text
prev_match_a_id
prev_match_b_id
```

are currently backend feeder metadata.

The UI should never infer tournament progression simply based on visual position.

---

# 7.57 Current backend finding

Your deployed `tournament_generate_fixtures()` currently creates:

```text
matches
```

and then assigns:

```text
prev_match_a_id
prev_match_b_id
```

in a second pass.

That correctly creates a feeder graph for winner-based elimination.

However, I searched the live database for code referencing:

```text
prev_match_a_id
prev_match_b_id
bracket_round_number
```

and at the moment the only function I found is:

```text
tournament_generate_fixtures()
```

I did **not** find the `match_advance_tournament_bracket` trigger referred to by your Dart comments.

That means the current repository and deployed progression mechanism need careful verification during the audit.

It could be:

```text
renamed
moved into another service/edge function
removed during refactor
never deployed
```

We should not guess.

But this makes progression a **high-priority audit item** later.

---

# 7.58 The current fixture generator also exposes our Step-2 limitation

`tournament_generate_fixtures()` currently inserts:

```text
round
bracket_round_number
bracket_match_number
prev_match_a_id
prev_match_b_id
```

directly into `matches`.

There is no first-class:

```text
stage
fixture slot
source type
source reference
draw revision
```

model yet.

That's enough for a single-elimination bracket.

It becomes much harder for:

```text
Group A #1
Group B #2
Loser SF1
Stage 1 #3
double elimination
draw revision history
```

So this is likely an architectural area we will refactor after the standard is frozen.

---

# 7.59 The DrawPlan itself needs to evolve conceptually

Current `DrawFixture` has:

```text
teamAId
teamBId
prevSlotAId
prevSlotBId
```

That supports:

```text
direct team
winner of previous fixture
```

But our final standard needs a generalized representation conceptually like:

```text
FixtureSlotSource

type:
  entry
  seed
  fixture_winner
  fixture_loser
  group_rank
  stage_rank
  bye

reference:
  ...
```

Again, we don't need to implement that yet.

But this is the design direction.

---

# 7.60 Draw publication state

From Step 4:

```text
NOT_CREATED
     ↓
DRAFT
     ↓
PUBLISHED
```

After publication:

```text
revision 1
```

Then structural changes:

```text
revision 2
```

rather than reverting to a meaningless generic `draft`.

That is the lifecycle Step 7 should use.

---

# 7.61 Authority

From Step 5:

```text
tournament.draw.manage
```

allows:

```text
generate
shuffle
seed
group assignment
draft modifications
```

while:

```text
tournament.draw.publish
```

allows making it authoritative.

I would separate those two.

A manager might be allowed to prepare the bracket while only the owner/head organizer publishes it.

V1 can grant both to ordinary tournament managers by default.

The capability distinction is still useful.

---

# 7.62 After publication

Who can alter it?

Ordinary:

```text
draw.manage
```

should no longer mean:

> freely mutate published topology.

Instead:

```text
structural amendment command
```

should require:

```text
higher capability
reason
impact analysis
new revision
```

Especially after any fixture starts.

---

# 7.63 Lock levels

There are effectively three increasingly strict moments:

```text
ENTRY LOCK
    ↓
DRAW PUBLICATION
    ↓
COMPETITION START
```

### Before Entry Lock

Almost everything is editable.

### After Entry Lock

Competitive field should not casually change.

### After Draw Publication

Competition topology should not silently change.

### After Competition Start

Played history must never be rewritten casually.

This is an extremely clean mental model.

---

# 7.64 Public bracket states

The UI should distinguish:

### No draw

```text
Draw not published yet
```

not:

```text
No matches
```

### Published but unresolved

```text
Semi-final 1

Winner QF1
vs
Winner QF2
```

not:

```text
TBD
vs
TBD
```

if we can explain the sources.

### Partially resolved

```text
Lahore Lions
vs
Winner QF2
```

### Fully resolved

```text
Lahore Lions
vs
Kasur Kings
```

This is much more informative.

---

# 7.65 Never confuse `TBD` with missing data

This matters to UX.

There are two fundamentally different cases:

```text
EXPECTED UNRESOLVED
Winner QF1
```

and:

```text
BROKEN DATA
No participant/source defined
```

The UI should never render both as generic:

```text
TBD
```

The first is healthy tournament progression.

The second is a configuration problem.

---

# 7.66 Stage completion

For elimination stage:

```text
terminal fixture finalized
      ↓
stage champion resolved
      ↓
Stage Completed
```

For round robin:

```text
all required fixtures terminal
      ↓
Sport Adapter final ranking
      ↓
Stage Completed
```

Then Tournament Core activates/resolves next Stage.

---

# 7.67 Tournament completion

If Stage is the last Stage:

```text
Stage Completed
       ↓
Tournament terminal placement rule
       ↓
Champion resolved
       ↓
Tournament Completed
```

Again, Match Engine doesn't complete the Tournament directly.

It completes the sporting Match.

Tournament Engine reacts.

---

# 7.68 Server transaction boundaries

For a result-finalization progression operation, I want conceptually:

```text
BEGIN

lock match/fixture progression state

verify result revision

finalize outcome

resolve dependent slots

update standings/projection if required

activate eligible downstream fixture

check stage completion

possibly activate next stage

possibly complete tournament

append audit information

COMMIT
```

Either all of that succeeds or none of it should partially apply.

That's the reliability standard.

---

# 7.69 Transport should not matter

Whether this eventually runs through:

```text
Supabase RPC
Edge Function
NestJS command service
```

should not change the domain behavior.

Given your current discussion about moving more workloads to your own NestJS server, this is especially important.

Define a command such as:

```text
FinalizeTournamentMatchResult
```

with deterministic behavior.

Then transport can change later.

---

# 7.70 What I would support initially

We shouldn't implement every exotic tournament structure immediately.

I would make the architecture support stages generically, but the first production generators should be:

| Structure | Initial support |
|---|---|
| Single Elimination | Full |
| Round Robin ×1 | Full |
| Round Robin ×2 | Good next addition |
| Groups → Single Elimination | Full after Stage model exists |
| Third-place playoff | Optional |
| Double Elimination | Defer until proper loser-source graph |
| Swiss | Future |
| Reseeding playoffs | Future |
| Custom bracket | Future |

This keeps Matchday ambitious without implementing half-correct competition formats.

Challonge and Toornament both expose much broader structure catalogs, but the complexity rises materially once loser brackets, Swiss pairings, multi-stage qualification, or custom structures enter the picture. :chatgpt-content-reference{index="4"}

---

# 7.71 Canonical competition graph

Putting everything together:

```text
Tournament
│
└── Stage 1: Groups
      │
      ├── Group A
      │     ├── Round 1
      │     │     └── Fixture A1
      │     └── ...
      │
      └── Group B
            └── ...

           results
              ↓
      Sport Adapter Rankings
              ↓
       Qualification Rules
              ↓

Stage 2: Playoffs
│
├── SF1
│    ├── Slot A = Group A #1
│    └── Slot B = Group B #2
│
├── SF2
│    ├── Slot A = Group B #1
│    └── Slot B = Group A #2
│
└── Final
     ├── Slot A = Winner SF1
     └── Slot B = Winner SF2
```

Matches simply execute those Fixtures.

That is the Tournament Core we want.

---

# Step-7 standard to freeze

I would now freeze the following as part of the Matchday Tournament Standard:

1. **Draw generation operates only on finalized active Tournament Entries.**
2. **Seeding determines competitive order; Placement determines structural position.**
3. **A Draw Plan is a draft competition graph, not yet authoritative.**
4. **Fixtures may exist while their participants are unresolved.**
5. **Every fixture participant position is a Slot with an explicit Source.**
6. **Supported source types conceptually include direct entry, seed, fixture winner, fixture loser, group rank, stage rank and bye.**
7. **A Bye is structural advancement, never a fake Match.**
8. **Bracket is a projection of the fixture graph, not its source of truth.**
9. **The complete fixed elimination graph should normally be created when the draw is published, including unresolved future rounds.**
10. **Group-to-knockout progression uses ranking-based Slot Sources rather than generating ad-hoc fixtures later.**
11. **Stage Format controls fixture generation; Tournament Type should not.**
12. **Competition topology and fixture scheduling are separate concerns.**
13. **Draw publication is an atomic server-authoritative command.**
14. **A published draw is immutable as a revision; structural changes create a new revision rather than silently rewriting history.**
15. **Schedule/ground/scorer changes are operational changes and do not inherently create a new structural draw revision.**
16. **Progression occurs from finalized authoritative Match results, never from client-side inference.**
17. **Progression must be idempotent.**
18. **Tournament Core resolves downstream Slot Sources; Sport Engine remains the authority on sporting results.**
19. **Ranking-dependent qualification should resolve after the relevant stage/group standings are finalized.**
20. **Result corrections must perform downstream-impact analysis before changing previously resolved progression.**
21. **Once a dependent fixture has started, upstream result correction cannot silently replace its participant.**
22. **Every published competition graph must be validated for broken references, invalid participants and cycles before publication.**
23. **Double elimination must remain unsupported until winner and loser feeder paths are modeled correctly.**
24. **Groups + Knockout becomes multiple Stages, not a special monolithic tournament generator.**
25. **The public UI must distinguish an intentionally unresolved slot such as `Winner QF1` from genuinely missing/broken data.**

And there is one concrete issue we now know to investigate once we enter the audit phase: the **current Flutter DrawPlan expects automatic bracket advancement, but I could not find the referenced advancement trigger in the live database**. We should verify exactly where progression currently happens before trusting the existing knockout implementation.

With Step 7, we now have the entire competition skeleton.

The logical **Step 8 is Tournament Operations & Exception Handling**: rescheduling, rain/interruption, no-result, walkover, scorer failure/handover, official conflicts, venue failure, team withdrawal after draw, disqualification, upstream result correction, fixture replay, tournament cancellation/abandonment, recovery from partially applied operations, and exactly what the organizer can do from the Live Ops console.




Yes. Step 8 is where the system needs to behave correctly when the tournament is already operational and something goes wrong.

The central rule I would freeze is:

> **After a tournament becomes operational, problems are resolved through explicit commands and recorded outcomes—not by editing or deleting history until the database looks convenient.**

That distinction becomes especially important once matches have started.

# Step 8 — Tournament Operations & Exception Handling

## 8.1 Three kinds of tournament operations

I would classify every Live Ops action into three categories:

| Category | Examples | Risk |
|---|---|---|
| Routine operation | assign scorer, change ground, change start time | Low |
| Competition resolution | walkover, no-result, replay, disqualification | Medium/high |
| Historical repair | result correction, progression repair, completed-match correction | Very high |

They should not all use the same generic:

```text
Update Match
```

operation.

Instead:

```text
RescheduleFixture
AssignScorer
DeclareWalkover
ResolveNoResult
OrderReplay
DisqualifyEntry
CorrectMatchResult
AbandonTournament
```

should be explicit domain commands.

That gives each operation its own authorization, lifecycle guards, audit information and downstream effects.

---

# 8.2 The Live Ops console

The organizer's Live Ops screen should essentially be the tournament's operational control room.

It should answer:

```text
What is happening now?
What is about to happen?
What requires intervention?
```

A useful conceptual board is:

```text
LIVE OPS

LIVE NOW
Ground 1 · Match 7
Lahore vs Falcons
Scorer: Ali
Last scoring event: 18 sec ago

NEEDS ATTENTION
Match 8 · No scorer assigned
Match 10 · Ground unavailable
Match 12 · Previous fixture unresolved

UPCOMING
13:00 · Ground 1
13:00 · Ground 2
15:30 · Ground 1

COMPLETED
Match 1
Match 2
...
```

So Live Ops should primarily be **exception-driven**, rather than making the organizer inspect every match manually.

---

# 8.3 A fixture should have operational readiness

Before a fixture begins, the system should be able to derive something conceptually like:

```text
Fixture Readiness

✓ participants resolved
✓ sport rules valid
✓ schedule present
✓ ground assigned
✓ scorer assigned
✓ required officials assigned
✓ eligible players available
```

Some of those may be hard requirements and others warnings depending on tournament rules.

Then the organizer sees:

```text
READY
```

or:

```text
NEEDS ACTION
Scorer missing
```

instead of finding out at match time.

---

# 8.4 Rescheduling before a match starts

This is a routine operation.

For:

```text
Fixture
Saturday 1 PM
Ground A
```

organizer changes:

```text
Saturday 3 PM
Ground B
```

The competition topology has not changed.

Therefore:

```text
same fixture
same participants
same draw revision
new schedule
```

We do not need a new Draw Revision.

But we should preserve:

```text
previous time
new time
previous ground
new ground
changed_by
changed_at
reason (optional/required depending proximity)
```

Toornament similarly treats match scheduling as changing date/time information independently of competition structure. :chatgpt-content-reference{index="0"}

---

# 8.5 Scheduling conflict validation

A reschedule command should eventually verify more than:

```text
newTime != null
```

It should check for conflicts such as:

```text
same ground occupied
same team already playing
required rest window
same scorer assigned elsewhere
same official assigned elsewhere
feeder fixture may not finish in time
venue opening constraints
```

Some conflicts can block.

Others can warn.

For example:

```text
Ground 1 occupied
→ BLOCK
```

while:

```text
Only 45 minutes between Team A fixtures
→ WARNING or BLOCK depending tournament policy
```

The organizer should not need to detect these manually.

---

# 8.6 Venue failure during the tournament

Suppose:

```text
Ground A becomes unusable
```

because of weather, lighting, power or another issue.

That should not require changing the tournament structure.

The organizer can perform:

```text
MoveFixture
```

or bulk:

```text
MoveRemainingFixtures
Ground A → Ground B
```

The system then needs to re-run scheduling conflict checks.

The competition graph remains untouched.

---

# 8.7 Scorer assignment

From Step 5, tournament management should assign:

```text
Assigned Scorer
        ↓
match-scoped authority
        ↓
cricket.match.setup
match.score
```

for that tournament match.

Changing scorer should not modify tournament ownership.

It should simply revoke/deactivate one match assignment and establish another.

Your current system already conceptually moves in this direction through `match_officials` and a match-scoped scoring grant.

---

# 8.8 Authorization vs active scorer

We established this earlier, but Live Ops makes it operationally important.

Suppose:

```text
Tournament Owner
Tournament Manager
Assigned Scorer Ali
```

all have authority to score.

That does **not** mean all three devices should simultaneously record deliveries.

We need:

```text
AUTHORIZATION
Who is allowed?

LEASE
Who currently controls the scoring session?
```

So:

```text
Authorized:
Owner ✓
Manager ✓
Ali ✓

Active Scorer Lease:
Ali's device
```

This avoids duplicate scoring commands and race conditions.

---

# 8.9 Scorer disappears during a live match

This is a normal recovery scenario, not a match failure.

Example:

```text
Ali's phone dies.
```

Organizer should be able to perform:

```text
Take Over Scoring
```

or:

```text
Handover to Ahmed
```

The flow should be:

```text
existing lease
      ↓
revoke/expire
      ↓
new authorized scorer
      ↓
new lease
      ↓
continue from canonical server state
```

No innings reset.

No new match.

No duplicated ball.

---

# 8.10 Scorer handover must be server-controlled

This connects to something I noticed in your current UI.

`organizer_console_screen.dart` currently generates the displayed 4-digit scorer code locally using the match hash/time.

If that is supposed to be a real security credential, that would not be safe.

A proper handover token would need to be:

```text
server generated
random
short-lived
single-use
bound to match
bound to intended action
revocable
audited
```

and exchanging it should result in a real match-scoped grant/session.

If the current 4-digit code is only visual/prototype UX, that's fine.

But it should not be considered authorization until we verify a server-side redemption mechanism.

---

# 8.11 Official conflicts

Officials are operational assignments too.

Before assigning:

```text
Umpire X
```

the server can check:

```text
already officiating another fixture?
same time?
same venue impossible?
team affiliation conflict?
```

Your current backend already tries to surface scorer/official schedule conflicts using a four-hour window.

That's a useful start, although later the conflict duration should come from actual fixture/sport scheduling policy rather than one hardcoded window.

---

# 8.12 Temporary interruption vs match abandonment

This distinction is extremely important.

Suppose Cricket stops because of rain.

That does **not** immediately mean:

```text
Match Abandoned
```

First it is:

```text
MATCH INTERRUPTED
```

Conceptually:

```text
LIVE
  ↓ interruption
SUSPENDED / INTERRUPTED
  ↓
  ├── Resume
  ├── Revised conditions
  ├── Reschedule/replay decision
  └── Terminal no-result/abandonment
```

Even if we don't add a `suspended` DB status immediately, our domain terminology should distinguish temporary interruption from terminal resolution.

---

# 8.13 Sport-specific interruption belongs below Tournament Core

For Cricket:

```text
rain
overs reduction
revised target
DLS/custom method
bowler quota changes
```

belong to Cricket.

Tournament Core merely sees:

```text
fixture still unresolved
```

until Cricket produces a terminal outcome.

For Football another sport adapter may handle:

```text
match suspended
resume from minute 63
restart
awarded result
```

according to that sport's rules.

This is exactly why Step 3 introduced the Sport Competition Adapter.

---

# 8.14 Revised Cricket conditions

Your current system already supports concepts such as:

```text
revised overs
revised target
DLS
run-rate method
custom target
```

Those should stay inside Cricket match operations.

The organizer may access them from the Tournament Live Ops UI because that's operationally convenient.

But architecturally:

```text
Live Ops screen
        ↓
Cricket command
```

not:

```text
Tournament Core calculates DLS
```

---

# 8.15 Match abandonment vs No Result

These must not be synonyms.

I would define:

### Abandoned match

The match cannot continue normally.

That describes what happened operationally.

### No Result

A terminal competitive outcome produced under the applicable sport/tournament rules.

So an interrupted/abandoned Cricket match may eventually resolve as:

```text
No Result
```

but the concepts are still different.

---

# 8.16 Current `AbandonMode` is too Cricket-specific for the tournament domain

Your current Dart model has:

```text
AbandonMode.reschedule
AbandonMode.noResult
```

and comments that `noResult`:

```text
splits points 1–1
leaves NRR untouched
```

That is Cricket competition policy.

It should eventually move under:

```text
Cricket Competition Adapter
```

rather than a generic tournament operation.

Tournament Core should ask:

```text
What is this fixture's terminal outcome?
```

The Cricket adapter determines:

```text
No Result
points effect
NRR effect
```

---

# 8.17 Never “discard the scorecard” after a match has started

This is one area where I would change the conceptual standard from the current code comments.

Your current `AbandonMode.reschedule` says roughly:

```text
discard scorecard
return fixture to upcoming
```

I would **not** make that our long-term behavior.

Once a sporting match has started, its events are historical facts.

Even if the tournament orders a replay, we should preserve:

```text
Original Attempt
Started
Interrupted
Abandoned
```

and then:

```text
Replay / Replacement Match
```

rather than pretending the original attempt never existed.

This is another place where Fixture vs Match becomes very useful.

---

# 8.18 Reschedule vs Replay

These should be different commands.

### Reschedule

Used before sporting execution begins.

```text
Fixture exists
Match not started
      ↓
change time/venue
```

Same fixture and same match execution can remain.

### Replay

Used after sporting execution has begun but the tournament rules require a new contest.

```text
Fixture
   │
   ├── Match Attempt 1
   │      abandoned
   │
   └── Match Attempt 2
          scheduled
```

The Fixture still represents the competition position.

The new Match represents a new sporting execution.

This is much cleaner than resetting Match Attempt 1.

---

# 8.19 Do we need `MatchAttempt` immediately?

Not necessarily.

We are still defining the standard.

But conceptually we should preserve:

> **A started match should never be made “unstarted” through destructive reset.**

Whether v1 later implements that through:

```text
replacement_match_id
```

or:

```text
fixture executions
```

or another relation is an implementation decision.

---

# 8.20 Walkover / Forfeit

A walkover is an administrative resolution.

Example:

```text
Lahore Lions appear.
Kasur Kings do not.
```

Organizer decides:

```text
Walkover
Winner = Lahore Lions
Reason = opponent did not appear
```

The fixture becomes terminal.

Then Tournament Core can progress:

```text
winner(fixture) = Lahore Lions
```

Toornament also treats forfeit as a match-level result rather than merely a score; the opponent receives the win, and the competition can apply separate standing-point rules. :chatgpt-content-reference{index="1"}

That aligns very well with our model.

---

# 8.21 Walkover should not generate a fake score

Unless a sport/tournament rule explicitly defines an awarded score.

Bad generic behavior:

```text
Cricket walkover
Score = 100/0
```

or:

```text
Football walkover
Score = 3–0
```

hard-coded by Tournament Core.

Instead:

```text
Administrative Outcome:
WIN = Team A
LOSS = Team B
Reason = walkover
```

Then the Sport Competition Adapter can decide whether an awarded score is required for standings.

---

# 8.22 Bye vs Walkover again

The Live Ops system must keep these separate.

```text
BYE
known from competition structure
no contest expected
```

versus:

```text
WALKOVER / FORFEIT
contest expected
administrative resolution occurred
```

A bye should never appear as an operational failure.

---

# 8.23 Double forfeit

Another edge case:

```text
Neither team appears.
```

Then there may be no natural winner.

In an elimination stage, however, Tournament Core may still require an advancer.

External tournament systems face exactly this problem; Toornament notes that a double forfeit cannot simply produce a normal bracket winner. :chatgpt-content-reference{index="2"}

For Matchday the correct architecture is:

```text
Fixture:
no sporting winner
```

then tournament policy requires:

```text
administrative advancement
replacement
stage/path termination
```

rather than inventing a winner silently.

---

# 8.24 Team withdrawal after published draw

From Step 6:

```text
withdraw before draw
= participant management

withdraw after draw
= tournament operations
```

The organizer should execute something like:

```text
WithdrawTournamentEntry
```

and the command must calculate impact.

For example:

```text
Upcoming QF
Team withdraws
```

possible policy:

```text
opponent receives walkover
```

But for round robin:

```text
3 matches already played
2 still scheduled
```

the consequences may involve:

```text
future forfeits
past results preserved
past results voided
standings recalculation
```

Those policies must be explicit.

---

# 8.25 Never delete a withdrawn team from the competition graph

If a team has appeared in:

```text
draw
fixtures
scores
standings
```

its Tournament Entry remains historical.

Its state becomes:

```text
WITHDRAWN
```

or:

```text
DISQUALIFIED
```

but the entry itself remains.

Otherwise public history becomes impossible to understand.

---

# 8.26 Disqualification

Disqualification is organizer/rules-driven rather than voluntary.

The command should require:

```text
reason
actor
effective time
```

and calculate competition impact.

Example:

```text
Disqualify Entry
```

may need to determine:

```text
future fixtures
past fixtures
current standings
qualification positions
downstream bracket participants
```

This should never be:

```text
UPDATE tournament_teams
SET status = ...
```

alone.

It's a domain operation.

---

# 8.27 Result correction has multiple levels

We need to distinguish at least three situations.

| Correction | Example | Handling |
|---|---|---|
| Score detail correction | delivery recorded as 4 instead of 6 | Sport Match Engine |
| Result recomputation | corrected score changes winner | Sport + Tournament impact |
| Administrative result override | organizer awards another outcome | Highly privileged tournament command |

These are very different.

---

# 8.28 Scorecard correction

Suppose a scorer entered:

```text
Ball 12.4 = 4 runs
```

but it should be:

```text
6 runs
```

If the match is still live, Cricket Engine should support correcting/undoing that scoring event through its own rules.

Tournament Core doesn't care yet.

---

# 8.29 Correction after match completion

Suppose the match is completed and the correction changes:

```text
182 → 184
```

but winner stays the same.

Tournament Core may only need:

```text
statistics/standings projection refresh
```

depending on NRR or other sport-specific metrics.

The bracket doesn't change.

This is an important example where:

```text
winner unchanged
```

does not necessarily mean:

```text
tournament unaffected
```

because ranking metrics may change.

---

# 8.30 Winner-changing correction

Now suppose correction changes the winner.

Then:

```text
Match Result
   ↓
Tournament progression
```

has changed.

Before committing that correction, Tournament Engine should compute:

```text
What depends on this result?
```

For example:

```text
QF1
  ↓
SF1
  ↓
Final
```

---

# 8.31 Downstream impact levels

I would conceptually classify result-repair impact like this:

| Downstream state | Can automate? |
|---|---|
| No dependent fixture | Yes |
| Dependent fixture unresolved/not started | Usually yes |
| Dependent fixture scheduled with resolved participant | Yes, but notify/audit |
| Dependent fixture already live | No silent repair |
| Dependent fixture completed | Major recovery workflow |
| Tournament completed | Administrative correction/reopening workflow |

This allows the server to decide whether a correction is safe.

---

# 8.32 Result correction should not blindly cascade through played history

Consider:

```text
QF1 winner originally Lahore
SF1 Lahore beats Falcons
Final Lahore beats Kings
Tournament completed
```

Then someone says:

```text
QF1 winner should have been Kasur.
```

You cannot simply recompute:

```text
Kasur → SF1
```

because Kasur did not play the semifinal that historically happened.

That requires an administrative governance decision, not automatic database recalculation.

So:

> **Tournament propagation is automatic only while downstream sporting execution has not begun.**

Once downstream matches are played, corrections become explicit recovery cases.

---

# 8.33 Result override should preserve both versions

If organizer changes:

```text
Original result:
Lahore won
```

to:

```text
Administrative result:
Kasur advances
```

we should retain:

```text
original sporting result
administrative override
reason
actor
timestamp
```

rather than overwriting history.

So future viewers/admins can understand:

```text
Sporting result:
Lahore won by 5 runs

Tournament ruling:
Kasur advanced
Reason: ...
```

where the sport permits such an administrative outcome.

That's much safer than pretending Lahore never won.

---

# 8.34 Distinguish Sporting Result from Competition Outcome

This is an extremely useful refinement.

A match might have:

```text
SPORTING RESULT
Team A won on field
```

and later:

```text
COMPETITION OUTCOME
Team B awarded progression
```

because of:

```text
eligibility violation
disqualification
appeal
administrative ruling
```

Tournament Core should progress using the authoritative **competition outcome**, while preserving the underlying sport result.

That model is much more robust.

---

# 8.35 Appeal/review state

Eventually we may need:

```text
Result under review
```

but I would not build a full appeals tribunal system now.

However, the domain can accommodate:

```text
result_finality = provisional / final
```

or a similar concept later.

For v1, the normal scorer result can become final immediately, while a privileged correction command exists.

No need to over-engineer appeals yet.

---

# 8.36 Tournament cancellation

From Step 4:

```text
CANCELLED
```

should generally mean the competition never meaningfully began.

Examples:

```text
not enough teams
venue unavailable
organizer cancellation
event cannot take place
```

The command should:

```text
prevent future tournament operation
mark unplayed fixtures void/cancelled
preserve applications/entries/history
notify participants
record reason
```

Completed matches would normally indicate we should consider abandonment rather than cancellation.

---

# 8.37 Tournament abandonment

Tournament `ABANDONED` means:

> The competition started but will not be completed.

Example:

```text
5 of 12 matches completed
major weather incident
event permanently terminated
```

Then:

```text
played matches remain historical
unplayed fixtures become non-playable
no automatic champion unless tournament policy/ruling explicitly determines one
```

This is very different from:

```text
one match abandoned
```

---

# 8.38 Completing an abandoned tournament should not happen automatically

If organizers choose to award a champion based on current standings after termination, that should be an explicit administrative ruling.

For example:

```text
Tournament abandoned
Champion awarded from standings
```

should retain:

```text
normal completion? no
administrative champion ruling? yes
reason
```

instead of disguising it as an ordinary completed competition.

---

# 8.39 Cancelled and abandoned should be terminal

Normal operations should stop.

A cancelled tournament should not later:

```text
start a match
```

and an abandoned tournament should not normally:

```text
publish new fixtures
```

If Matchday ever supports reopening, that should be an explicit extraordinary recovery operation—not `status = live`.

---

# 8.40 Partial failure recovery

This is a serious backend concern.

Suppose:

```text
Declare Walkover
```

needs to:

```text
finalize fixture
record outcome
advance winner
update standings
send notifications
write audit record
```

and the process fails halfway.

We cannot end with:

```text
Match = walkover
but next round still TBC
```

The core database mutation should be transactional.

Conceptually:

```text
BEGIN

authorize
lock fixture
validate state

record terminal outcome
resolve progression
update standings/projection
update stage/tournament state
append audit event/outbox

COMMIT
```

Notifications/realtime can happen after commit.

---

# 8.41 Your Cricket command boundary already follows a good transactional pattern

The current `cricket-match-action` Edge Function explicitly:

```text
BEGIN
↓
authenticate
lock/read
authorize
validate
write
load canonical snapshot
COMMIT
↓
publish realtime
```

and publishes realtime only after commit.

That is a very good principle.

We should extend the same philosophy to Tournament Operations.

Even if we later move those commands into NestJS, the principle remains:

> **Commit truth first; publish side effects afterward.**

---

# 8.42 Idempotency

Every serious operational command should be safe to retry.

Mobile networks fail.

A user may tap twice.

A request may succeed server-side while the client times out.

For example:

```text
DeclareWalkover(
    fixture=QF2,
    winner=TeamA,
    commandId=xyz
)
```

If sent twice:

```text
first → success
second → returns same outcome/no-op
```

not:

```text
duplicate progression
duplicate notifications
duplicate points
```

This should be a general command standard.

---

# 8.43 Optimistic concurrency

We also need revision checks.

Suppose Manager A opens:

```text
Match 7
revision 41
```

Manager B records a result, making:

```text
revision 42
```

Manager A then submits an old:

```text
Reschedule Match
expectedRevision = 41
```

Server should respond:

```text
Conflict.
Match changed since you opened it.
Reload current state.
```

rather than overwriting revision 42.

This will matter a lot once multiple tournament managers operate simultaneously.

---

# 8.44 Audit log

Every exceptional action should be explainable.

Conceptually:

```text
TournamentOperation

operation_id
tournament_id
fixture_id?
match_id?
actor_id
command
reason
before
after
occurred_at
```

We don't need to store massive JSON snapshots for everything.

But enough information should exist to answer:

```text
Who changed this?
Why?
When?
What was it before?
```

For ordinary scoring events, the sport engine already has its own audit/event mechanisms.

Tournament Operations needs the administrative layer.

---

# 8.45 Reason should be mandatory for destructive/exceptional actions

For example:

| Action | Reason |
|---|---|
| Normal scorer assignment | optional |
| Routine reschedule | optional or recommended |
| Reschedule after start time | required |
| Walkover | required |
| Disqualification | required |
| Result override | required |
| Tournament cancellation | required |
| Tournament abandonment | required |
| Published draw structural revision | required |

This creates useful history without annoying organizers for every normal action.

---

# 8.46 Notifications must follow committed operations

Examples:

```text
Fixture rescheduled
→ notify both teams + scorer + officials
```

```text
Scorer reassigned
→ old scorer + new scorer + organizer
```

```text
Walkover declared
→ both teams + tournament participants if publicly relevant
```

```text
Tournament cancelled
→ all active entries
```

But notification dispatch must not be the source of truth.

If push fails:

```text
operation still committed
```

and the notification can be retried.

---

# 8.47 Operations should emit events

A good conceptual event model:

```text
FixtureRescheduled
ScorerAssigned
ScorerHandover
FixtureInterrupted
FixtureReplayed
WalkoverDeclared
EntryWithdrawn
EntryDisqualified
ResultCorrected
TournamentCancelled
TournamentAbandoned
```

Other parts of Matchday can react:

```text
notification service
chat
feed
realtime
audit
analytics
```

without embedding all side effects into the original command.

This will also make a future NestJS event-driven architecture much cleaner.

---

# 8.48 Live Ops should surface stale scoring

Your existing `TournamentLiveMatch` already tracks:

```text
lastBallAt
```

which is useful.

For example:

```text
LIVE
Last ball 30 seconds ago
```

normal.

But:

```text
LIVE
Last ball 17 minutes ago
```

could show:

```text
SCORING MAY BE STALLED
```

That doesn't automatically change anything.

It simply alerts the organizer.

This is exactly what Live Ops should do: surface anomalies.

---

# 8.49 But “stale” thresholds must be sport-aware

In Cricket, ten minutes without a ball may be meaningful.

In another sport, scoring events naturally happen less frequently.

So:

```text
stale detection
```

should either come from the sport adapter or from operational heartbeat, not one universal “last scoring event” rule.

A scorer/device heartbeat may actually be more reliable:

```text
scorer connected?
lease alive?
last command?
```

---

# 8.50 Live Ops should separate technical problems from competition problems

For example:

```text
SCORER OFFLINE
```

is technical/operational.

```text
MATCH INTERRUPTED BY RAIN
```

is sporting operation.

```text
TEAM WITHDREW
```

is competition administration.

```text
RESULT UNDER CORRECTION
```

is integrity/recovery.

Those should not all become:

```text
Match Error
```

The console needs actionable categories.

---

# 8.51 Public UI should not expose internal recovery mechanics

If the organizer is repairing a result, public users do not need to see:

```text
RPC retry
lease conflict
projection rebuild
```

Public UI should display meaningful competition state:

```text
Result under review
Fixture rescheduled
Walkover
No result
Abandoned
```

Internal implementation remains hidden.

Same principle as your posting pipeline discussion: users should see product state, not infrastructure mechanics.

---

# 8.52 Current Live Ops architecture is Cricket-coupled

Your current:

```text
TournamentLiveMatch
```

contains:

```text
LiveInningsLine
runs
wickets
legalBalls
```

So despite the generic class name, it is really:

```text
CricketTournamentLiveMatch
```

or a generic fixture plus Cricket presentation details.

During the later audit, we should separate:

```text
Tournament Live Ops summary
```

from:

```text
Cricket live score projection
```

This follows Step 3.

---

# 8.53 Current operation methods are also mixed

The current tournament repository exposes:

```text
assignScorer
rescheduleMatch
abandonMatch
declareWalkover
overrideResult
reviseMatchConditions
triggerSuperOver
```

Some are truly tournament operations:

```text
assignScorer
reschedule
walkover
result override
```

while others are Cricket operations:

```text
revised conditions
Super Over
```

Again, functionality is fine.

Boundary placement is what needs refactoring.

---

# 8.54 The scorer PIN UI needs special attention later

As mentioned above, the current Flutter sheet says:

> scorer enters a four-digit code to unlock scoring.

But the displayed code is locally generated.

So in the audit we need to determine whether:

```text
server redemption exists elsewhere
```

If not, I would remove the claim that it “unlocks” anything until we implement a real secure handover flow.

The actual scoring authorization today should continue to rely on the proper backend grant/lease mechanism.

---

# 8.55 Operation hierarchy

The operational model now becomes:

```text
TOURNAMENT OWNER/MANAGER
          │
          ▼
      LIVE OPS
          │
          ├── Scheduling
          │     reschedule
          │     move ground
          │
          ├── Staffing
          │     scorer assignment
          │     scorer takeover
          │     officials
          │
          ├── Sporting Operations
          │     delegated to sport engine
          │     rain revision
          │     super over
          │     etc.
          │
          ├── Competition Resolution
          │     walkover
          │     withdrawal
          │     disqualification
          │     replay
          │
          └── Integrity / Recovery
                result correction
                progression repair
                tournament cancel/abandon
```

That is a much cleaner control surface.

---

# 8.56 What Live Ops should *not* provide

I would not allow Live Ops to casually:

```text
change sport
change tournament structure
change stage format
delete played fixture
remove scorecard
swap teams inside live match
manually type next-round team
mark tournament completed
```

Those actions either belong elsewhere or require a dedicated recovery workflow.

Live Ops should operate the competition—not bypass its rules.

---

# 8.57 Tournament Core should remain deterministic

Even under exceptional cases, Tournament Core should receive explicit outcomes.

For example:

```text
Walkover
      ↓
CompetitionOutcome
winner = Team A
reason = walkover
      ↓
Progression Engine
```

or:

```text
No Result
      ↓
Sport Competition Adapter
standings effects
      ↓
Tournament Core
```

or:

```text
Replay Ordered
      ↓
existing execution terminal
new execution created
fixture still unresolved
```

Everything remains explainable.

---

# 8.58 The Step-8 standard I would freeze

1. **Tournament operations must use explicit domain commands rather than generic row editing.**
2. **Routine operations, competition resolutions, and historical repairs are separate classes of action.**
3. **Live Ops is the organizer's operational control plane and should prioritize fixtures requiring attention.**
4. **Fixture readiness should be derived before start and should expose missing participants, scorer, officials, venue or other required conditions.**
5. **Rescheduling an unstarted fixture changes schedule, not competition topology.**
6. **Schedule changes must run ground/team/scorer/official conflict checks.**
7. **Authorization to score and active scorer control are separate; only one active scorer lease should control writes.**
8. **Scorer handover/takeover must occur through server-authoritative grants and leases.**
9. **Any PIN/QR handover credential must be server-generated, short-lived, single-use and auditable; a locally generated code is not authorization.**
10. **Temporary interruption, match abandonment and No Result are separate concepts.**
11. **Sport-specific interruption handling belongs to the Sport Engine/Adapter.**
12. **A started match must not be destructively reset to an unstarted state.**
13. **Reschedule applies before play; Replay is a new sporting execution after play has begun.**
14. **Walkover/forfeit is an administrative competition outcome and should not invent a fake score unless sport rules explicitly require one.**
15. **Withdrawn/disqualified Tournament Entries remain historical and are never deleted from already-published competition history.**
16. **Score correction, winner-changing correction and administrative result override are different operations.**
17. **Sporting Result and Competition Outcome should be conceptually separable.**
18. **Automatic result propagation is safe only while downstream sporting execution has not begun.**
19. **Corrections affecting live/completed downstream matches require a dedicated recovery workflow rather than silent cascade.**
20. **Tournament cancellation means the competition did not meaningfully proceed; Tournament abandonment means it started but will not finish.**
21. **Cancelled/abandoned tournament history and completed matches must be preserved.**
22. **Operational commands affecting multiple competition objects must be transactional and idempotent.**
23. **Concurrency-sensitive commands should use revisions/optimistic locking.**
24. **Exceptional operations require audit records and, where appropriate, mandatory reasons.**
25. **Realtime, notifications and chat effects occur after authoritative state commits and must never define truth themselves.**
26. **Live Ops UI may compose Tournament Core and sport-specific controls, but sport-specific logic must not migrate into Tournament Core merely because it appears on that screen.**

That gives us a very solid operational model.

At this point Steps 1–8 cover the major **domain behavior**. The next logical step should be **Step 9 — Standings, Ranking, Tie-breakers, Qualification & Statistics**, because that is the remaining major mechanism connecting match results to group tables, qualification and awards. It will also let us cleanly solve the current Cricket-specific `tournament_standings` model with NRR without weakening the multi-sport architecture.




Yes. Step 9 is the piece that connects **sporting results to competition meaning**.

The central rule I would freeze is:

> **The Match Engine decides what happened in the match. The Sport Competition Adapter converts that result into points, metrics, and ranking. The Tournament Core consumes the ordered ranking to decide qualification and progression.**

So the flow becomes:

```text
SPORT MATCH
   │
   │ finalized sporting result
   ▼
SPORT COMPETITION ADAPTER
   │
   ├── outcome points
   ├── standings metrics
   ├── tie-breakers
   └── ordered ranking
          │
          ▼
TOURNAMENT CORE
   │
   ├── qualification
   ├── next-stage slots
   ├── elimination/advancement
   └── tournament placement
```

That is the foundation of Step 9.

---

# 9.1 Standings belong to a Stage, not simply a Tournament

This is the first major correction I would make conceptually.

Today you have:

```text
tournament_standings
```

with:

```text
tournament_id
team_id
group_id
...
```

But after Step 2, the correct context is really:

```text
Tournament
   ↓
Stage
   ↓
Group (optional)
   ↓
Standings
```

Consider:

```text
Tournament

Stage 1: Group Stage
    Group A standings
    Group B standings

Stage 2: Knockout
    no traditional points table
```

So the canonical concept should be closer to:

```text
StageStanding
```

or:

```text
CompetitionStanding
```

rather than one global tournament table.

The public UI can still simply say:

> **Standings**

but internally the scope matters.

---

# 9.2 Standings are a projection

A standing should not itself be the authoritative sporting history.

The authoritative chain should be:

```text
Finalized Matches
      ↓
Competition Result Interpretation
      ↓
Standing Projection
```

If standings became corrupted, we should theoretically be able to rebuild them from authoritative match outcomes.

That is an important architectural principle:

> **Matches/results are source facts. Standings are derived competition state.**

This means we should avoid making tournament progression depend on manually editable `points = 12` rows.

---

# 9.3 Generic Standing vs sport-specific metrics

Tournament Core needs very little.

Conceptually:

```text
Standing

entry
stage
group?

played
competition_points
rank

qualification_status
```

Potentially it can also expose common outcome counts:

```text
wins
losses
draws/ties
no_results
```

because Matchday is initially targeting head-to-head team sports.

But it should **not inherently know**:

```text
runs
overs
NRR
goals for
goal difference
sets won
point differential
```

Those belong to the Sport Competition Adapter.

---

# 9.4 Current Matchday standings are actually Cricket standings

Your current `TournamentStanding` contains:

```text
matchesPlayed
wins
losses
ties
noResults
points

runsScored
oversFaced
runsConceded
oversBowled
netRunRate
```

The first section can potentially be generic.

The second section is clearly Cricket.

So the current class is better described conceptually as:

```text
CricketTournamentStanding
```

even though it currently has the generic name `TournamentStanding`.

That's one of the Step-9 audit findings we should later address.

---

# 9.5 Points policy

We should separate:

```text
RESULT
```

from:

```text
POINTS AWARDED FOR THAT RESULT
```

For example, Cricket Tournament A could define:

```text
Win        → 2
Tie        → 1
No Result  → 1
Loss       → 0
```

while another competition could use different values.

Football might use:

```text
Win  → 3
Draw → 1
Loss → 0
```

Therefore:

> **Competition points are configurable competition policy interpreted by the Sport Competition Adapter.**

This is also how mature competition systems operate. PlayHQ allows administrators to configure game-outcome points rather than hard-coding one points model for every competition. :chatgpt-content-reference{index="0"}

---

# 9.6 Points rules should normally belong to the Stage

Suppose Matchday eventually has:

```text
Stage 1
Round Robin

Stage 2
Knockout
```

Stage 1 needs a points policy.

Stage 2 usually does not.

Therefore the scope should conceptually be:

```text
Stage
    competition format = round_robin
    points policy = ...
```

rather than only:

```text
Tournament.rules.points
```

We can inherit tournament defaults, but Stage should be the competition unit that consumes them.

---

# 9.7 Points and ranking are different

This is extremely important.

Suppose:

```text
Lahore   8 pts
Kasur    8 pts
Falcons  6 pts
```

Points alone do not produce a unique ranking.

We then need a **Tie-breaker Policy**.

So:

```text
POINTS
   ↓
primary ordering

TIE-BREAKERS
   ↓
resolve equal ordering

FINAL RANK
```

These should be separate concepts.

---

# 9.8 Tie-breakers are an ordered pipeline

This is the cleanest model.

For example, a Cricket group could configure:

```text
1. Competition Points
2. Net Run Rate
3. Head-to-Head
4. Wins
5. Organizer Resolution
```

The algorithm becomes:

```text
compare points

if equal:
    compare NRR

if still equal:
    compare head-to-head

if still equal:
    compare wins

if still equal:
    unresolved tie
```

Toornament uses this same general idea: multiple tie-breakers are configured in priority order and applied from top to bottom until the tie is resolved. It also distinguishes overall metrics from head-to-head metrics among the tied participants. :chatgpt-content-reference{index="1"}

That's the model I would use.

---

# 9.9 Tie-breakers must be configurable per sport/competition

We should not globally decide:

```text
Points
then NRR
```

because that is Cricket-specific.

Instead:

```text
Sport Adapter
    provides supported ranking criteria

Tournament/Stage configuration
    selects ordered criteria
```

For Cricket the adapter might support:

```text
competition_points
wins
net_run_rate
head_to_head_points
head_to_head_nrr
```

For Football:

```text
competition_points
goal_difference
goals_for
head_to_head_points
head_to_head_goal_difference
```

For Basketball:

```text
wins
point_difference
points_for
head_to_head
```

The Tournament Core doesn't implement those calculations.

---

# 9.10 Ranking criteria should have scope

This is another very useful distinction from systems such as Toornament.

A tie-breaker may use:

```text
OVERALL
```

meaning all stage matches.

Or:

```text
HEAD_TO_HEAD
```

meaning only matches between the tied participants. :chatgpt-content-reference{index="2"}

Example:

```text
Lahore  8 pts
Kasur   8 pts
```

If head-to-head is the next criterion:

```text
Lahore beat Kasur
```

then Lahore ranks higher.

But with three tied teams:

```text
Lahore
Kasur
Falcons
```

the system needs to evaluate the defined mini-table/tied-participant logic correctly, not simply ask:

> “Who beat whom?”

That's why tie-breaking belongs in a proper adapter/calculator.

---

# 9.11 Do not use random ranking as an invisible fallback

If every configured metric still ties, the system should not quietly do:

```text
ORDER BY team_id
```

or:

```text
random()
```

just to get positions.

That creates fake sporting certainty.

Instead:

```text
1 Lahore
1 Kasur

Tie unresolved
```

until the tournament's final tie-resolution policy executes.

Possible configured final policies could eventually be:

```text
head-to-head playoff
organizer ruling
drawing of lots
sport-specific tiebreak match
```

but it must be explicit.

---

# 9.12 Manual tie-breaker must be visible and audited

Sometimes grassroots tournaments need an administrative decision.

If so:

```text
Organizer resolves ranking
```

must record:

```text
affected entries
previous tie state
chosen ordering
reason
actor
time
```

It must not simply become:

```text
rank = 1
```

with no explanation.

Toornament also supports manual tie-break inputs as an explicit mechanism rather than pretending they were automatically calculated. :chatgpt-content-reference{index="3"}

---

# 9.13 Live Standings vs Final Standings

This is another important distinction.

During the group stage:

```text
Match 1 complete
Match 2 live
Match 3 scheduled
```

we can show:

```text
LIVE / PROVISIONAL STANDINGS
```

Those are useful.

But they are not necessarily final qualification standings.

Conceptually:

```text
PROVISIONAL
     ↓
stage fixtures reach terminal state
     ↓
ranking calculated
     ↓
validation/finalization
     ↓
FINAL
```

This prevents downstream qualification from accidentally using a table that is still changing.

---

# 9.14 Standings finalization should be a competition event

Suppose all Group A matches finish.

Do we immediately push Group A #1 into the semifinal?

We could.

But I prefer a slight integrity checkpoint:

```text
all required fixtures terminal
       ↓
Sport Adapter recalculates standings
       ↓
ties resolved
       ↓
standing becomes FINAL
       ↓
Tournament Core applies qualification
```

This can happen automatically when there are no unresolved problems.

If the group remains tied according to configured criteria:

```text
Group cannot finalize
```

until the tie-resolution procedure completes.

Toornament similarly distinguishes completed match results from validating a group/round for outgoing participant placement. :chatgpt-content-reference{index="4"}

---

# 9.15 Qualification must only consume Final ranking

This is a strong rule.

Suppose:

```text
Top 2 Group A qualify.
```

Then Tournament Core should resolve:

```text
Group A #1
Group A #2
```

only from:

```text
FINAL Group A standings
```

not arbitrary current ranking.

So:

```text
Live Standings
     ✕
Progression

Finalized Standings
     ✓
Progression
```

That prevents semifinal participants changing while the group stage is still active.

---

# 9.16 Qualification rules are Tournament Core

Once ranking is final, the sport boundary ends.

Sport Adapter returns:

```text
1 Lahore
2 Kasur
3 Falcons
4 Warriors
```

Tournament Core applies:

```text
Top 2 qualify
```

and produces:

```text
Qualifier #1 = Lahore
Qualifier #2 = Kasur
```

Then Step 7's Slot Source resolution handles the rest.

This is our clean boundary again:

```text
Sport Adapter
"Who is #1?"

Tournament Core
"Where does #1 go?"
```

---

# 9.17 Qualification status should be explicit

For public UX we eventually want entries to show concepts such as:

```text
Qualified
Eliminated
Still in contention
```

But these should be derived carefully.

At minimum after standings finalization:

```text
QUALIFIED
ELIMINATED
```

are safe.

During a live stage:

```text
clinched qualification
mathematically eliminated
```

requires considerably more competition-specific mathematics.

I would **not build that in v1**.

Use simple provisional ranks during play.

Resolve qualification when standings finalize.

---

# 9.18 Knockout stages usually do not need standings

This is an important simplification.

For:

```text
single_elimination
```

we don't need a points table.

Progression comes directly from:

```text
fixture winner
```

But we may still eventually want:

```text
Final Tournament Placement
```

such as:

```text
Champion
Runner-up
3rd
4th
```

That is **placement**, not standings.

We should distinguish:

```text
STANDINGS
ranking within standings-based Stage

PLACEMENT
final tournament finishing position
```

---

# 9.19 Final Tournament Placement

At tournament completion we may produce:

```text
1 Champion
2 Runner-up
3 Third Place
4 Fourth Place
```

depending on structure.

For a round-robin-only tournament:

```text
final standings
```

can determine placement directly.

For knockout:

```text
Champion = Final winner
Runner-up = Final loser
```

Third place only exists deterministically if:

```text
third-place fixture exists
```

or tournament rules define another method.

Do not pretend semifinal losers are uniquely #3 and #4 without a rule.

---

# 9.20 Sport-specific standings metrics

For Cricket, our adapter might produce something conceptually like:

```text
CricketStandingMetrics

matches
wins
losses
ties
noResults

runsFor
ballsFaced
runsAgainst
ballsBowled

netRunRate
```

Tournament Core doesn't need to understand the formulas.

It just receives ranking values.

---

# 9.21 NRR must have exactly one authoritative implementation

This is especially important.

We should never have:

```text
Flutter NRR calculation
SQL NRR calculation
NestJS NRR calculation
```

independently implemented.

That almost guarantees divergence.

Instead:

```text
Cricket Competition Adapter
        ↓
authoritative NRR calculator
```

and everyone reads the projection.

The same principle applies to any sport-specific tiebreak metric.

---

# 9.22 NRR is not just `(runs scored / overs) - ...` in naive decimal overs

This matters technically.

Cricket notation:

```text
19.4 overs
```

does **not** mean:

```text
19.4 decimal overs
```

It means:

```text
19 overs + 4 legal balls
```

So ranking calculations should fundamentally work from:

```text
legal balls
```

rather than decimal display notation.

Your Cricket Match Engine already stores legal-ball counts, which is the right underlying representation.

When we audit NRR implementation later, this is something we should verify carefully against the tournament's chosen Cricket rules.

---

# 9.23 Different Cricket competitions may use different ranking policy

This is important because we shouldn't hard-code “NRR always second.”

PlayHQ, for example, allows administrators to choose ranking priorities and Cricket-specific ladder configurations; it also supports total points versus points average and other ranking concepts depending on competition configuration. :chatgpt-content-reference{index="5"}

So Matchday should eventually let tournament presets supply defaults while allowing competition policy to control the actual ranking order.

For the first Cricket implementation, we can establish a sensible Matchday default.

But the architecture should not turn it into universal law.

---

# 9.24 Bonus points

Cricket competitions sometimes use bonus points.

Other sports can too.

So points should conceptually be:

```text
Outcome Points
+
Bonus Points
+
Administrative Adjustments
=
Competition Points
```

PlayHQ supports configurable Cricket bonus points alongside game-outcome points, which is a useful real-world example of why a standing cannot always be represented as just “wins × 2.” :chatgpt-content-reference{index="6"}

We don't necessarily need bonus points in Matchday v1.

But our standings architecture shouldn't make them impossible.

---

# 9.25 Administrative point adjustments

Another future need:

```text
Team penalized 1 point
```

for an eligibility violation.

This should not modify a historical match result just to achieve the desired standings.

Instead conceptually:

```text
Calculated Points     8
Adjustment           -1
Final Competition Pts 7
```

with:

```text
reason
actor
timestamp
```

This is cleaner and auditable.

---

# 9.26 Standing recomputation

I strongly prefer:

```text
RECALCULATE FROM AUTHORITATIVE INPUT
```

over:

```text
standing.points += 2
standing.wins += 1
```

where practical.

Why?

Consider a completed result being corrected.

With incremental mutations you need:

```text
subtract old result
then add new result
```

perfectly.

That's error-prone.

A stronger model is:

```text
authoritative finalized fixture outcomes
             ↓
rebuild stage/group projection
```

For the scale Matchday grassroots tournaments will initially have, recomputing a small group table is cheap.

---

# 9.27 We don't need to recalculate the entire platform

This doesn't mean:

```text
one score correction
→ recalculate every tournament ever
```

Scope it:

```text
affected Stage / Group
```

For example:

```text
Group A match corrected
        ↓
recompute Group A standings
        ↓
if standings final:
    recalculate qualification impact
```

That's deterministic and manageable.

---

# 9.28 Standings updates should be atomic with result finalization where required

Conceptually:

```text
BEGIN

finalize competition outcome

recompute affected standing projection

check ranking/ties

resolve qualification if stage final

resolve downstream slots

COMMIT
```

The public should not briefly see:

```text
Match completed
but table still old
```

if the standing calculation is core to that command.

Realtime notification comes afterward.

---

# 9.29 Current live database finding

I checked the deployed project.

`tournament_standings` currently has triggers for:

```text
updated_at
```

and:

```text
Realtime broadcast
```

but I did **not** find a deployed public-schema trigger/function responsible for actually recalculating the standings themselves.

That does not necessarily mean the functionality is absent—it could live in another service or command path—but the live DB itself is not currently showing me an obvious authoritative standings calculator.

So later this becomes a priority audit question:

> **Where exactly is `tournament_standings` populated and recalculated today?**

We should answer that before trusting qualification or points behavior.

---

# 9.30 Realtime standings

Your existing:

```text
broadcast_standings_change()
```

is conceptually fine as an output mechanism.

The important architecture should be:

```text
Authoritative command
       ↓
Standing projection changes
       ↓ COMMIT
Realtime event
       ↓
Flutter refreshes
```

Realtime must never be responsible for computing standings.

That's consistent with Step 8.

---

# 9.31 Public table columns should come from the sport adapter

Instead of generic tournament Flutter hard-coding:

```text
P
W
L
T
NR
Pts
NRR
```

we should eventually support something like:

```text
Sport Standings Definition
```

that describes the display.

For Cricket:

| Key | Label |
|---|---|
| played | P |
| wins | W |
| losses | L |
| ties | T |
| no_results | NR |
| points | PTS |
| net_run_rate | NRR |

Football could instead render:

| Key | Label |
|---|---|
| played | P |
| wins | W |
| draws | D |
| losses | L |
| goals_for | GF |
| goals_against | GA |
| goal_difference | GD |
| points | PTS |

The same Tournament Standings UI shell can render both.

---

# 9.32 Ranking and display columns are not necessarily identical

This is subtle.

UI may display:

```text
P W L PTS NRR
```

while ranking policy might be:

```text
Points
Head-to-head
NRR
```

So we need separate concepts:

```text
Standing Display Metrics
```

and:

```text
Ranking Criteria
```

Do not determine sort order based on whichever UI columns happen to be visible.

---

# 9.33 Hidden metrics

A tie-break criterion may not even need to be shown as a main table column.

For example:

```text
Head-to-head
```

may be calculated only when required.

That's fine.

The UI could show:

> “Lahore ranks above Kasur on head-to-head.”

This would be a very good user experience.

---

# 9.34 Explainability matters

When two teams have equal points, users will ask:

> Why is Lahore above Kasur?

Matchday should eventually be able to answer:

```text
Both have 8 points.
Lahore ranks higher on NRR:
+1.324 vs +0.817
```

or:

```text
Equal on points and NRR.
Lahore ranks higher on head-to-head.
```

The ranking engine should therefore produce not only:

```text
rank = 1
```

but conceptually enough information to explain the deciding criterion.

This reduces tournament disputes dramatically.

---

# 9.35 Ties that remain unresolved

Suppose:

```text
Points equal
NRR equal
Head-to-head tied
Wins equal
```

Then don't fake unique ranks.

Conceptually:

```text
rank group:
Lahore
Kasur

status:
UNRESOLVED_TIE
```

Qualification cannot finalize if the tie affects:

```text
qualifying cutoff
```

For example, if positions #2 and #3 are tied and only #2 qualifies.

But if positions #5/#6 are tied and neither qualifies, tournament policy might allow the stage to finalize without resolving their exact ordering if final placement doesn't matter.

That's a useful sophistication.

---

# 9.36 Qualification-critical tie

We can define conceptually:

```text
Tie affects progression?
```

If no:

```text
stage may potentially finalize
```

depending on placement requirements.

If yes:

```text
tie resolution required
```

Example:

```text
Top 2 qualify

#1 Lahore
#2 Kasur
#2 Falcons
```

We cannot resolve:

```text
Group A #2
```

until Kasur/Falcons are ordered.

That should become a visible organizer action:

```text
Qualification blocked:
unresolved tie for 2nd place
```

Excellent Live Ops/organizer UX.

---

# 9.37 Head-to-head mini-table

For a multi-team tie:

```text
A, B, C all have 8 points
```

a head-to-head rule should typically consider the relevant results among those tied teams according to the configured sport policy.

The ranking engine should support a **tie group**, not only pairwise compare functions.

This matters because naive:

```dart
sort((a,b) => headToHead(a,b))
```

can become non-transitive and produce unstable ordering.

So:

> Tie-breakers operate on tied sets/groups, not simply arbitrary pair comparisons.

That's an important implementation standard.

---

# 9.38 Determinism

Given the same:

```text
match results
points policy
tie-break policy
administrative adjustments
```

the ranking engine must always return exactly the same ordering.

No dependence on:

```text
query row order
device locale
map iteration order
current time
random fallback
```

unless the tournament explicitly uses a recorded random/draw-lots tiebreak decision.

This is particularly important if we later move calculations between Supabase and NestJS.

---

# 9.39 Ranking revision

Standings should conceptually have a revision.

Example:

```text
Standing Revision 19
```

Match 5 completion:

```text
revision 20
```

Result correction:

```text
revision 21
```

Then clients can reason about ordering updates and stale state.

We don't need a full revision history table for every live table snapshot, but the concept fits our concurrency model.

---

# 9.40 Statistics

Now we should separate **Standings** from **Statistics**.

Standings answer:

> How is the team/entry performing competitively?

Statistics answer:

> What happened across players and matches?

Cricket examples:

```text
Runs
Wickets
Strike rate
Economy
Sixes
High score
Best bowling
```

These do not determine Tournament Core progression unless explicitly configured as ranking metrics.

So:

```text
Standings
≠
Player Leaderboards
```

---

# 9.41 Current Cricket leaderboards

Your live backend currently has:

```text
tournament_batting_leaderboard()
tournament_bowling_leaderboard()
```

They aggregate directly from Cricket deliveries across tournament matches.

That is exactly sport-specific functionality, which is fine.

Architecturally they belong under:

```text
Cricket Tournament Statistics
```

rather than generic Tournament Core.

---

# 9.42 Live leaderboards vs Final leaderboards

The current leaderboard queries include matches whose statuses are:

```text
live
completed
```

That means these are effectively **live tournament leaderboards**.

That's a good feature.

UI could display:

```text
Top Run Scorers
Live
```

and values update during matches.

But final awards should not necessarily consume live/provisional statistics.

When Tournament is completed:

```text
Final Stats
```

should be based on finalized eligible sporting events.

---

# 9.43 Corrections must update stats too

If a scorer undoes a wicket or corrects runs:

```text
Player leaderboard
```

should eventually update from the corrected authoritative deliveries.

That's another reason leaderboards should be derived projections rather than mutable manual totals.

---

# 9.44 Player identity stability

Your current leaderboard functions cleverly use either:

```text
user_id
```

or:

```text
unclaimed_id
```

to create a player key.

That is useful given Matchday's claimed/unclaimed player system.

When we later review tournament statistics, we need to ensure claiming an unclaimed profile does not split one player's tournament stats into two unrelated identities.

That's a player-identity concern worth auditing later.

---

# 9.45 Tournament Awards

Awards are yet another layer.

I would separate:

```text
STATISTICAL LEADERBOARD
```

from:

```text
TOURNAMENT AWARD
```

Example:

```text
Most Runs
```

is statistical.

But:

```text
Player of the Tournament
```

may be organizer-selected.

Similarly:

```text
Best Bowler
```

could be automatically suggested from wickets/economy but still organizer-confirmed.

---

# 9.46 Suggested vs Confirmed Awards

This gives us a clean model:

```text
Sport Statistics
      ↓
Award Suggestions
      ↓
Tournament Organizer Review
      ↓
Confirmed Awards
```

For example:

```text
Suggested Best Batter:
Ali — 347 runs

Organizer:
Confirm
```

or choose someone else if tournament rules permit.

Then:

```text
Confirmed Award
```

becomes public tournament history.

Your existing API already has this conceptual distinction in:

```text
getSuggestedAwards()
confirmAwards()
```

although the current implementation will need deeper review later.

---

# 9.47 Champion is not an award in the same sense

This distinction matters.

```text
Champion
Runner-up
```

should be derived directly from competition outcome.

The organizer should not manually choose them like ceremonial awards.

So:

```text
COMPETITION PLACEMENT
Champion
Runner-up
Third place
```

is Tournament Core.

While:

```text
CEREMONIAL / SPORT AWARDS
Player of Tournament
Top Batter
Top Bowler
Fair Play
```

belong to awards/statistics.

---

# 9.48 Public tournament page composition

After Step 9 the public tournament page can cleanly have:

```text
Overview

Teams

Fixtures

Standings
    sport-defined columns

Bracket
    where applicable

Stats
    sport-specific leaderboards

Awards
    confirmed results

Champion / Placement
```

No Cricket assumptions need to leak into the generic page shell.

---

# 9.49 Historical standings

When a stage completes, I would want its final ranking to remain stable as historical output.

For example:

```text
Group A — Final

1 Lahore
2 Kasur
3 Falcons
4 Warriors
```

Even after:

```text
Playoffs begin
```

we should not replace that with one global table.

Each stage/group has its own historical standing.

That makes the tournament timeline comprehensible.

---

# 9.50 Result correction after stage qualification

This ties Step 9 back to Step 8.

Suppose Group A finalized:

```text
1 Lahore
2 Kasur
```

and semifinals were populated.

Later a Group A result is corrected, producing:

```text
1 Lahore
2 Falcons
3 Kasur
```

Before applying the correction:

```text
Tournament Core
```

must check downstream progression.

If semifinal has not started:

```text
qualification may be repaired
```

with audit/notifications.

If semifinal already began:

```text
no silent automatic change
```

and we enter the recovery workflow from Step 8.

---

# 9.51 Current `TournamentStanding` sorting

Your Flutter datasource currently sorts:

```text
points DESC
net_run_rate DESC
```

That is effectively hard-coded:

```text
Tie-breaker #1 = NRR
```

for all tournaments using that generic repository.

That's exactly the kind of coupling Step 9 tells us to remove later.

The eventual ranking should come from an authoritative ranked projection.

Flutter should not be deciding:

```text
ORDER BY points, NRR
```

as the universal ranking law.

---

# 9.52 Flutter should receive rank, not invent rank

Today `TournamentStanding` has:

```text
rank = 0
```

and supports:

```text
copyWithRank(...)
```

Conceptually I would prefer:

```text
Backend/Sport Adapter:
rank = authoritative
```

Flutter then renders it.

Otherwise:

```text
Android
iOS
web
```

could theoretically calculate tie ordering differently.

Ranking is business truth, not presentation formatting.

---

# 9.53 Canonical Step-9 model

Putting all of this together:

```text
                 FINALIZED MATCH RESULT
                           │
                           ▼
              SPORT COMPETITION ADAPTER
                           │
                ┌──────────┴──────────┐
                ▼                     ▼
         POINT CALCULATION      SPORT METRICS
                │              NRR / GD / etc.
                └──────────┬──────────┘
                           ▼
                    RANKING ENGINE
                           │
                   ordered criteria
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
          PROVISIONAL TABLE     FINAL TABLE
                                     │
                                     ▼
                            TOURNAMENT CORE
                                     │
                         Qualification Rules
                                     │
                                     ▼
                            Fixture Slot Sources
```

And separately:

```text
Sport Match Events
       ↓
Sport Statistics
       ↓
Live Leaderboards
       ↓
Final Statistics
       ↓
Award Suggestions
       ↓
Confirmed Awards
```

That gives us a very clean separation.

---

# 9.54 What I would freeze as the Step-9 standard

The Tournament Standard should now say that standings are **Stage/Group-scoped derived projections**, not the primary source of sporting truth. Result points and ranking criteria are separate policies; tie-breakers form an explicitly ordered, deterministic pipeline; ranking calculations belong to the Sport Competition Adapter; and Tournament Core consumes only finalized rankings when resolving qualification.

It should also establish that provisional/live standings are distinct from finalized standings, unresolved qualification-critical ties block progression, knockout placement is different from standings, player statistics are different from competitive standings, live statistical leaderboards can remain provisional, and confirmed tournament awards are separate from automatically derived Champion/Runner-up placement.

For the later implementation audit, Step 9 has exposed four concrete areas already: the current generic `TournamentStanding` is Cricket-specific, the datasource hard-codes `points DESC → NRR DESC`, the live database does not currently reveal an obvious public-schema standings recalculation path, and the Cricket batting/bowling leaderboard layer is correctly sport-specific in behavior but currently exposed through the generic tournament repository.

At this stage we have defined almost the entire competitive domain:

```text
Step 1  Authority root for matches
Step 2  Tournament hierarchy
Step 3  Multi-sport boundary
Step 4  Lifecycle
Step 5  Authority/capabilities
Step 6  Registration, Entry & Squad
Step 7  Draw & progression
Step 8  Operations & exceptions
Step 9  Standings, qualification & statistics
```

The natural **Step 10 is Communication, Notifications, Public Presentation & Tournament Social Layer**: who joins tournament chat, what gets announced automatically, tournament posts/feed integration, public/private visibility, participant notifications, match/fixture changes, registration notifications, live-score surfaces, and how we keep communication driven by domain events instead of embedding chat/push behavior inside tournament business logic.





Yes. Step 10 is where we make the tournament feel like a real Matchday product rather than only a competition database.

The central rule I would freeze is:

> **Tournament Core produces facts. Communication systems decide who should hear about those facts and through which channel.**

So:

```text
Tournament Command
       ↓
Authoritative state committed
       ↓
Domain Event
       ↓
 ┌─────┼─────────┬──────────┐
 ▼     ▼         ▼          ▼
Push   Chat   Activity    Feed/Post
            / Inbox
```

Tournament logic should never depend on whether a push notification, chat message, or social post succeeds.

# Step 10 — Communication, Notifications, Public Presentation & Social Layer

## 10.1 Four completely different concepts

I would not treat all tournament communication as “notifications.”

There are four separate surfaces:

| Surface | Purpose | Audience |
|---|---|---|
| Tournament communication | Organizer ↔ participants | Tournament participants |
| Notifications | Alert someone to relevant change | Targeted users |
| Public tournament presentation | Show competition truth | Public/followers/participants |
| Social layer | Posts, comments, likes, shares | Matchday social graph |

They can react to the same event but they serve very different purposes.

For example:

```text
FixtureRescheduled
```

could produce:

```text
Tournament page:
new time displayed

Affected teams:
important notification

Assigned scorer:
important notification

Tournament participant channel:
optional system message

Public feed:
usually nothing
```

That is much better than automatically blasting the same thing everywhere.

---

# 10.2 Domain events are the bridge

Steps 1–9 have already given us good events.

Examples:

```text
TournamentPublished
RegistrationOpened
RegistrationClosed

RegistrationSubmitted
RegistrationApproved
RegistrationRejected

EntriesLocked
DrawPublished
DrawRevised

FixtureScheduled
FixtureRescheduled
FixtureParticipantsResolved

ScorerAssigned
OfficialAssigned

MatchStarted
MatchCompleted
WalkoverDeclared
ResultCorrected

StageCompleted
EntryQualified
EntryEliminated

TournamentCompleted
TournamentCancelled
TournamentAbandoned

AwardPublished
```

Tournament Core owns the fact:

```text
FixtureRescheduled
```

It should **not** contain:

```text
send FCM to these 17 users
post this chat text
create feed card
```

Those are consumers of the event.

---

# 10.3 Commit first, communicate afterward

This needs to remain consistent with Step 8.

Correct:

```text
BEGIN

authorize
validate
reschedule fixture
record audit/outbox event

COMMIT

      ↓

notification worker
chat consumer
realtime
feed projection
```

Wrong:

```text
send push
send chat message
then try to update fixture
```

because if the database update fails, users have been informed about something that never happened.

So:

> **Truth commits first. Communication follows committed truth.**

---

# 10.4 Use an Outbox-style boundary

Eventually I would strongly prefer the transaction to write something conceptually like:

```text
domain_event

event_id
event_type
aggregate_type
aggregate_id
payload/reference
occurred_at
actor_id
```

in the same transaction as the domain change.

Then consumers process it.

This gives us:

```text
Tournament Core
       ↓
       Event
       ↓
 ┌───────────────┐
 │ Notification  │
 │ Chat          │
 │ Feed          │
 │ Realtime      │
 │ Analytics     │
 └───────────────┘
```

and if a notification provider temporarily fails, the tournament does not fail.

This model will work equally well whether the command later lives in Supabase or NestJS.

---

# 10.5 Tournament chat

This needs a clearer definition than simply:

> every tournament gets a group chat.

We should decide **who the chat is for**.

I would define the primary Tournament Participant Channel as:

> A coordination space for tournament organizers and authorized representatives of active Tournament Entries.

That normally means:

```text
Tournament Owner
Tournament Managers

+
representatives of each active team:
    Team Owner
    Team Manager
    Captain
```

depending on your chosen representative policy.

I would **not automatically include every player from every team** by default.

---

# 10.6 Why adding every team member is problematic

Imagine:

```text
16 teams
20 roster members each
```

That's:

```text
320 players
```

plus organizers.

The tournament coordination channel becomes noisy and operationally useless.

More importantly, many players do not need access to:

```text
registration discussions
venue changes
organizer instructions
captain coordination
administrative announcements
```

So I would separate:

```text
Tournament Representative Communication
```

from:

```text
Public/player community discussion
```

If later we want a large community chat, that can be a separate optional product.

---

# 10.7 Current backend behavior

Your current backend does two things automatically.

When a tournament is inserted:

```text
tournaments_after_insert_create_chat
```

creates a private tournament `main` chat and adds the creator as owner.

Then when a `tournament_teams` row becomes approved:

```text
trg_sync_tournament_team_chat
```

adds active members of that team into the tournament chat.

The architecture is understandable, but after the standards we have defined, I would change the **meaning** later.

The ideal membership source should be:

```text
Active Tournament Entry
        ↓
Tournament communication policy
        ↓
authorized representatives
```

not simply:

```text
all current team members
```

---

# 10.8 Draft tournament should not necessarily create participant chat

Today chat is created as soon as the Tournament row is inserted.

But:

```text
Tournament = DRAFT
```

may never be published.

Conceptually there are two possibilities.

We could create an organizer-only communication channel at draft creation, or create the tournament participant channel only when needed.

I favor:

```text
DRAFT
→ no participant channel necessary
```

then:

```text
Tournament Published / first active entry
→ provision participant channel
```

unless you specifically want organizer internal chat from day one.

There is no reason to fill the chat system with unused tournament channels for abandoned drafts.

---

# 10.9 Participant chat membership must follow Entry lifecycle

From Step 6:

```text
Registration
≠
Tournament Entry
```

therefore chat membership should follow:

```text
ACTIVE ENTRY
```

not merely:

```text
application submitted
```

A pending team should not enter participant chat.

Approved:

```text
Entry ACTIVE
→ representatives join
```

Withdrawn/disqualified:

```text
Entry leaves active competition
```

then communication policy should decide:

```text
remove immediately
or
retain read-only historical access
```

For v1, I would probably remove active posting access while retaining existing message history.

---

# 10.10 Organizer announcements are not ordinary chat messages

This distinction is very important.

Suppose organizer announces:

```text
"Tomorrow's matches start at 8:00 AM instead of 9:00 AM."
```

That is important operational information.

It should not disappear among:

```text
"ok bro"
"coming"
"thanks"
```

in group chat.

So we need:

```text
Tournament Announcement
```

as a first-class communication concept.

It can appear inside the tournament UI and optionally create a system message in chat.

But it is not merely a normal chat message.

---

# 10.11 Tournament Announcement

Conceptually:

```text
Announcement

tournament
author
title/message
audience
published_at
priority
```

Possible audiences:

```text
All active entries
All team representatives
Specific team
Specific fixture participants
Officials/scorers
Everyone following tournament
```

For v1 we can expose simpler audience options.

---

# 10.12 Announcement delivery

One announcement can fan out to:

```text
Tournament activity/inbox
Push notification
Tournament announcement screen
Optional chat system card
```

without creating four different pieces of business truth.

The announcement itself is authoritative.

Delivery is a projection.

---

# 10.13 Chat system messages

System messages are useful when they represent committed events.

Example:

```text
Match 7 rescheduled
15:00 → 17:00
Ground 2
```

inside participant chat.

But these should be generated from:

```text
FixtureRescheduled
```

rather than typed manually by Flutter.

That allows all clients to see the same event representation.

---

# 10.14 Do not generate a chat message for every domain event

Otherwise chat becomes:

```text
Registration approved
Payment updated
Squad edited
Seed changed
Scorer assigned
Umpire assigned
Match started
Wicket
Run
Run
Run
...
```

which is unusable.

Use chat only for meaningful coordination events.

Ball-by-ball belongs to the live-match experience, not tournament chat.

---

# 10.15 Notification audiences

Notifications should be resolved based on **relationship to the event**.

For example:

### Registration approved

Notify:

```text
registered_by
current team managers/owners
```

not:

```text
every tournament follower
```

### Fixture rescheduled

Notify:

```text
both participating teams' representatives
assigned scorer
assigned officials
tournament organizers
```

Potentially players if your product policy wants that.

### Tournament completed

Notify:

```text
active participant teams
followers
```

with different message content if appropriate.

---

# 10.16 Notification importance levels

I would classify notifications conceptually.

| Level | Examples | Expected behavior |
|---|---|---|
| Critical operational | Fixture moved, match cancelled, scorer assignment | Strong push |
| Competition | Registration approved, qualified, result finalized | Push/inbox |
| Informational | Draw published, standings updated | Preference-based |
| Social | Tournament post/comment/like | Social preference rules |

This prevents people receiving 40 pushes during a one-day tournament.

---

# 10.17 Not every score update is a push notification

Public live followers may want:

```text
Match started
Final result
```

but probably not:

```text
Every Cricket delivery
```

as system push notifications.

Live scoring should arrive through:

```text
Realtime/live match UI
```

not push fanout.

Potential optional future notifications:

```text
Wicket
Milestone
Half-time
Goal
```

could be user-configurable sport-specific alerts.

But don't couple Tournament Core to them.

---

# 10.18 Notification preferences

Users should eventually be able to decide whether they want:

```text
Tournament announcements
Fixture reminders
Match results
Standings updates
Social activity
```

Critical obligations are slightly different.

For example, an assigned scorer probably should receive operational assignment changes even if they have turned off general tournament news.

So notification policy needs:

```text
preference
+
relationship
+
event importance
```

not simply one global `notifications_enabled`.

---

# 10.19 In-app activity should remain available even if push is disabled

Push is delivery.

It should not be the only record.

For meaningful competition updates, users can have an in-app activity/inbox item even if:

```text
push disabled
```

That gives reliable history.

Example:

```text
Tournament Updates

✓ Registration approved
  Sep 28

⚠ Match moved to Ground B
  Sep 30

✓ Qualified for Semi-final
  Oct 1
```

Much better than relying solely on ephemeral OS notifications.

---

# 10.20 Chat notifications use the Chat subsystem

This is another boundary worth freezing.

Tournament Core should not understand:

```text
user currently viewing thread?
notification grouping?
clear notifications after opening?
typing?
unread counts?
```

Those are Chat subsystem concerns.

Your existing chat notification architecture already addresses things like suppressing heads-up notifications while the user is inside the active thread.

Tournament chat should simply be another channel/context handled through the same chat infrastructure.

Do not create a separate tournament-chat notification system.

---

# 10.21 Tournament event notifications are different from chat notifications

Important distinction:

```text
Organizer sends chat:
"Come early tomorrow."
```

That generates a chat notification.

But:

```text
FixtureRescheduled
```

generates a Tournament Operations notification.

Even if we also mirror it as a system chat card, its source remains:

```text
Tournament Event
```

This allows notification history and critical alerts to remain reliable independent of chat.

---

# 10.22 Followers

Your product already has the concept of following tournaments.

A follower is:

```text
interested observer
```

not:

```text
participant
```

Therefore:

```text
Follow Tournament
```

may grant:

```text
updates
feed relevance
result notifications
```

but never:

```text
participant chat access
private operational information
squad management
entry information
```

Very important distinction.

---

# 10.23 Public tournament presentation

The public page should be a read model/projection of the Tournament domain.

It could show:

```text
Identity
Description
Sport

Tournament phase
Registration status

Teams

Stages / Groups

Fixtures

Live matches

Standings

Bracket

Statistics

Awards

Champion / results
```

But the public page should never become the place where competition truth is computed.

For example:

```text
Bracket widget
```

reads Fixture Slot Sources.

It does not calculate progression.

---

# 10.24 Public vs participant vs organizer data

Even a public tournament does **not** mean every tournament field is public.

We should have three conceptual data surfaces:

```text
PUBLIC

PARTICIPANT

ORGANIZER
```

Examples:

| Information | Public | Participant | Organizer |
|---|---:|---:|---:|
| Tournament name | ✓ | ✓ | ✓ |
| Fixtures/results | ✓ | ✓ | ✓ |
| Public standings | ✓ | ✓ | ✓ |
| Registration application message | ✗ | own | ✓ |
| Payment details | ✗ | own team | ✓ |
| Internal decision notes | ✗ | maybe decision outcome | ✓ |
| Scorer contact information | ✗ | limited | ✓ |
| Administrative audit log | ✗ | ✗ | ✓ |

This should eventually influence API/view design.

---

# 10.25 Current `public/private` is too broad as a full visibility model

Your current tournament has:

```text
public
private
```

That's fine for v1 discovery.

But conceptually, privacy involves multiple things:

```text
Discoverability
Who can view?
Who can register?
Who can follow?
Who can see squads?
```

A future model might support:

```text
Public
Invite-only
Unlisted
```

But I would not implement more states unless product requirements demand them.

For now:

```text
public
private/invite-only
```

is enough.

Just don't let one enum determine every field-level visibility decision.

---

# 10.26 Private tournament

Private/invite-only should mean something like:

```text
not open public registration
participant access controlled
```

We need to decide separately whether it is:

```text
completely invisible
```

or:

```text
publicly visible but participation invite-only
```

Those are actually different product concepts.

For Matchday I would eventually prefer explicit configuration:

```text
visibility
registration_policy
```

rather than overloading `privacy`.

Example:

```text
visibility = public
registration = invite_only
```

is a perfectly valid tournament.

---

# 10.27 Tournament posting identity

Matchday allows:

```text
user posts
team posts
tournament posts
```

That means Tournament is a social publisher.

Good.

But posting as a Tournament should require:

```text
tournament.post
```

or an equivalent capability.

Not simply:

```text
is tournament organizer?
```

once Step 5's capabilities are implemented.

This allows future roles like:

```text
Content Manager
```

without giving them draw/result powers.

---

# 10.28 Tournament posts are editorial content

Examples:

```text
Registrations are open!
Fixtures are out.
Semi-finals today.
Congratulations to the champions.
Photos from today's matches.
```

These are social/editorial.

They should not be confused with system-generated competition state.

For example:

```text
Final result
```

exists in Tournament Core whether or not anyone creates a celebratory post.

---

# 10.29 Automatic feed posts should be conservative

I would **not** automatically create a feed post for:

```text
every registration
every match start
every result
every standings change
```

That would flood Matchday's home feed.

Instead, automatic social publishing should be limited or optional.

Potential good candidates later:

```text
Tournament published
Draw published
Final completed / Champion crowned
```

Even those could be organizer-configurable.

For v1 I would rather keep social posts intentional.

---

# 10.30 Structured tournament cards in the feed

A better pattern than auto-generated prose posts is:

```text
Structured Matchday Activity Card
```

Example:

```text
Kasur Champions Cup
FINAL

Lahore Lions 184/7
Kasur Kings 177/9

Lahore Lions won by 7 runs
```

This can appear in discovery/activity surfaces without creating a permanent social post object every time.

Then users can:

```text
open match
open tournament
share card
```

This separates product activity from user-generated feed content.

---

# 10.31 Shareable objects

Tournament, Fixture, Result and Standings should be inherently shareable.

For example:

```text
Share Tournament
Share Fixture
Share Result
Share Bracket
Share Standings
```

The shared object should link to canonical state.

Not create copied screenshots/data that become stale internally.

---

# 10.32 Realtime public updates

Live tournament pages may subscribe to:

```text
fixture status
score projections
standings projection
bracket resolution
```

But again:

```text
Realtime
=
delivery of committed state
```

not:

```text
source of truth
```

If realtime is lost:

```text
refresh API
```

should recover everything.

That's the same architecture you have been aiming for in chat.

---

# 10.33 Participant-specific operational surfaces

Team participants may need information public spectators do not.

Example:

```text
Your next match
Arrive by 14:30
Ground B
Scorer: assigned
Lineup deadline
```

This can be derived into a:

```text
My Tournament
```

participant view.

That's much better UX than forcing teams to inspect a huge general tournament page.

---

# 10.34 Organizer communication should be targeted

Suppose organizer needs to contact only:

```text
Team A and Team B
```

for a disputed fixture.

They should not have to send it to all 16 teams.

So Tournament communication should eventually support audiences such as:

```text
whole tournament
specific entry/team
fixture participants
officials/scorers
```

This does not necessarily mean separate chat groups for every combination.

A targeted announcement/activity mechanism may be better.

---

# 10.35 Match chat vs Tournament chat

We need a clean distinction.

### Tournament chat

Purpose:

```text
competition-wide coordination
```

### Team chat

Purpose:

```text
internal team communication
```

### Direct chat

Purpose:

```text
person-to-person
```

Potential future Fixture chat:

```text
two teams + officials + organizer
```

might be useful, but I would **not add it automatically yet**.

You already have a complex chat system. We should avoid creating hundreds of channels unless the product actually needs them.

---

# 10.36 Tournament chat should not replace official announcements

This principle is worth repeating because it's important.

```text
CHAT
ephemeral conversation

ANNOUNCEMENT
official tournament communication
```

A reschedule should remain discoverable even if someone sends 300 chat messages afterward.

---

# 10.37 Communication membership should be projection-based

Instead of Tournament Core directly managing:

```text
channel_members
```

conceptually:

```text
TournamentEntryActivated
        ↓
Communication Membership Projector
        ↓
add representatives
```

and:

```text
TournamentEntryWithdrawn
        ↓
Communication Membership Projector
        ↓
remove/deactivate access
```

This prevents your competition domain from depending on the structure of your chat database.

---

# 10.38 Current DB triggers are tightly coupled

Today:

```text
Tournament inserted
        ↓ trigger
create chat
```

and:

```text
Tournament team approved
        ↓ trigger
sync team chat members
```

This works.

But it couples:

```text
Tournament tables
```

directly to:

```text
Chat tables
```

inside database triggers.

For the long-term architecture, I would prefer:

```text
Tournament domain event
     ↓
Chat integration handler
```

especially since you're considering moving substantial realtime/application logic to your own NestJS server.

We do not need to change it immediately, but it is a clear audit item.

---

# 10.39 Chat failure must never fail registration approval

This is a key consequence.

Imagine:

```text
Approve Registration
```

succeeds competitively but:

```text
chat membership insert
```

fails because chat infrastructure has a problem.

We do not want:

```text
registration approval rollback
```

because Chat is unavailable.

The Tournament Entry is more important than the chat projection.

Therefore:

> **Core tournament correctness must not depend on optional communication infrastructure.**

The integration can retry.

---

# 10.40 Notifications should be deduplicated

Imagine result finalization causes:

```text
MatchCompleted
StandingUpdated
EntryQualified
StageCompleted
```

A team should not receive four nearly identical pushes:

```text
You won!
Standings updated!
You qualified!
Stage completed!
```

The communication layer should understand aggregation or notification policy.

Potentially:

```text
Qualified for the Semi-finals
Lahore Lions finished 2nd in Group A.
```

One useful notification instead of four noisy ones.

This belongs to the communication layer, not Tournament Core.

---

# 10.41 Notifications need idempotency too

The same event may be delivered twice.

Notification system should use:

```text
event_id
+
recipient
+
notification_type
```

or equivalent idempotency.

Otherwise retries create duplicate pushes.

Same applies to system chat cards and activity items.

---

# 10.42 Time-based reminders are different from domain-event notifications

Examples:

```text
Match starts in 2 hours
Registration closes tomorrow
Squad deadline in 24 hours
```

These are not caused by a new domain event at that exact moment.

They are scheduled communication policies based on authoritative dates.

So conceptually we have:

```text
EVENT-DRIVEN
FixtureRescheduled
RegistrationApproved
MatchCompleted
```

and:

```text
TIME-DRIVEN
FixtureReminder
RegistrationClosingReminder
SquadDeadlineReminder
```

Both consume Tournament data but remain communication concerns.

---

# 10.43 Reschedule invalidates old reminders

Important edge case.

If:

```text
Match 7
3 PM
```

has a scheduled:

```text
1 PM reminder
```

then organizer moves match to:

```text
6 PM
```

the old reminder must be cancelled/replaced.

That means reminder scheduling should track:

```text
fixture revision / schedule revision
```

not simply enqueue one immutable timer and forget about it.

---

# 10.44 Notification destinations

A tournament event could fan out differently:

```text
Organizer:
operational dashboard + push

Team Manager:
participant inbox + push

Player:
in-app update, maybe push

Follower:
public update, preference-dependent

Spectator:
no direct notification unless following
```

Same event, different relationship policy.

---

# 10.45 Tournament cancellation communication

This is a critical one.

When:

```text
TournamentCancelled
```

commits, communication service should notify:

```text
active entries
pending applicants
scorers/officials
possibly followers
```

with context appropriate to each.

For example, a pending applicant needs:

> Tournament cancelled.

not:

> Your entry has been rejected.

The semantic source matters.

---

# 10.46 Result corrections need correction notifications

If public result changes after initial publication:

```text
Original:
Lahore won

Corrected:
Kasur advances
```

we should not silently change the UI.

Affected participants should receive:

```text
Result corrected
```

and the public match page should ideally indicate an administrative correction where appropriate.

Transparency helps prevent disputes.

---

# 10.47 Public history should preserve important administrative states

For example:

```text
Walkover
No Result
Abandoned
Result corrected
Tournament abandoned
```

should not be normalized into generic:

```text
Completed
```

on public-facing pages.

Users should understand what actually happened.

But internal reasons may remain private if sensitive.

---

# 10.48 Reason visibility

An operation may record:

```text
internal reason
```

that should not necessarily be public.

So administrative commands could conceptually support:

```text
internal_reason
public_note
```

For example:

```text
Internal:
Team breached eligibility rule X after investigation.

Public:
Match awarded by tournament ruling.
```

We don't need this complexity for every action, but the domain should not assume every audit reason belongs on the public page.

---

# 10.49 Feed and tournament pages should link rather than duplicate truth

Suppose Tournament posts:

```text
Fixtures are live!
```

The post should link to:

```text
Tournament → Fixtures
```

rather than embedding a copied fixture list into post data as the authoritative version.

If fixtures change:

```text
canonical tournament page updates
```

while the historical post remains a social message.

This prevents social data from becoming stale competition state.

---

# 10.50 Public presentation is eventually consistent; competitive commands are strongly consistent

This distinction matters.

When a result commits:

```text
Competition Core
```

needs correct progression immediately.

But:

```text
Feed card
search indexing
analytics
follower notifications
```

can update shortly afterward.

So:

```text
Strong consistency:
results
standings finalization
qualification
progression

Eventual consistency:
feed
search
analytics
notifications
chat projections
```

That's the right tradeoff.

---

# 10.51 Tournament search/discovery

A published public tournament can appear in:

```text
Discover
Search
Nearby
Following
```

based on its public projection.

Draft tournament:

```text
never discoverable
```

Private tournament:

```text
not ordinary discovery
```

unless you later introduce invite/unlisted flows.

Again, search is a projection of published tournament state.

---

# 10.52 Completed tournaments should remain social objects

When tournament completes:

```text
Completed
```

should not mean its social identity disappears.

People can still:

```text
view results
view bracket
view standings
view stats
view awards
share
follow historical page
see tournament posts
```

Only operational mutation closes.

That's important for Matchday's long-term sports history.

---

# 10.53 Archived communication

Tournament participant chat can remain readable after completion.

But we may change permissions:

```text
Completed Tournament

chat:
read-only after X days
```

or leave it active.

I would not automatically delete the channel.

History has social value.

For v1, keeping it readable is safer than deleting it.

---

# 10.54 Current architecture findings from Step 10

The present system has several good foundations:

```text
Tournament already has social identity.
Tournament can be followed.
Tournament can have a chat context.
Approved teams can be synced into chat.
Posts can link to tournaments.
Standings can broadcast realtime updates.
```

The main architectural issues are boundaries:

```text
DB tournament triggers directly mutate chat membership.
Tournament chat currently appears to include all active team members.
Tournament creation provisions chat even for drafts.
Tournament authorization for publishing still uses organizer-style checks rather than the capability model.
```

These are not reasons to rewrite everything immediately.

They are precise audit targets once the standard is complete.

---

# 10.55 Canonical communication architecture

The model I would freeze is:

```text
                 TOURNAMENT DOMAIN
                        │
                     COMMIT
                        │
                   DOMAIN EVENT
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
 PUBLIC PROJECTION   COMMUNICATION     SOCIAL
        │               │                │
 fixtures/results   announcements      posts
 standings          notifications      comments
 bracket            reminders          likes
 stats              participant chat   shares
        │               │                │
        └───────────────┼────────────────┘
                        │
                     USERS
```

None of the lower systems owns competition truth.

---

# Step-10 standard to freeze

1. **Tournament Core produces authoritative facts; communication systems consume those facts.**
2. **Chat, notifications, public projections and social posts are separate product surfaces.**
3. **All external communication should follow committed state, never precede it.**
4. **Domain events/outbox should become the integration boundary between Tournament and communication systems.**
5. **Communication failure must not invalidate an otherwise successful tournament command.**
6. **Tournament participant chat should serve organizers and authorized representatives of active Tournament Entries, not automatically every team member by default.**
7. **Tournament chat membership follows Tournament Entry lifecycle rather than raw registration rows.**
8. **Tournament announcements are first-class official communication and are distinct from ordinary chat messages.**
9. **Important tournament events can appear as chat system messages, but not every domain event belongs in chat.**
10. **Tournament-event notifications and chat-message notifications use separate semantic sources.**
11. **Followers receive public-interest updates but gain no participant authority or private communication access.**
12. **Public, participant and organizer data projections must remain separate even for public tournaments.**
13. **Tournament visibility and registration policy are conceptually separate; public does not necessarily mean open registration.**
14. **Posting as a Tournament should eventually use a dedicated capability rather than generic organizer identity.**
15. **Social posts are editorial content and must never become sources of tournament truth.**
16. **Automatic feed publishing should be conservative; structured activity cards are preferable for routine sporting events.**
17. **Live scoring updates use realtime/live-match delivery rather than push notifications for every event.**
18. **Notification policy considers audience relationship, importance and user preferences.**
19. **Critical operational updates remain accessible in-app even if push delivery is unavailable.**
20. **Scheduled reminders and event-driven notifications are different mechanisms.**
21. **Schedule revisions must invalidate or replace stale reminders.**
22. **Notification/system-message consumers must be idempotent and avoid duplicate fanout.**
23. **Result corrections, walkovers, abandonment and similar meaningful administrative outcomes should remain visible in appropriate public history.**
24. **Audit reasons and public explanations may require different visibility.**
25. **Tournament completion closes operations, not the historical/social identity of the tournament.**
26. **Chat history should not be destructively removed when a tournament completes.**

With Step 10 complete, the **domain/product architecture is now almost fully defined**.

The next step I recommend is **Step 11 — Data Model & Aggregate Boundaries**. That is where we stop discussing behavior abstractly and map Steps 1–10 into the canonical entities and ownership boundaries—`Tournament`, `TournamentStage`, `TournamentEntry`, `TournamentSquadMember`, `Group`, `Round`, `Fixture`, `FixtureSlot`, `DrawRevision`, standings projections, memberships, operations/audit, and their relationship with the existing `matches`/sport tables—**still before writing migrations**. This is the step that will tell us which parts of your current Supabase schema can stay, which need renaming/refactoring, and which new first-class tables are actually justified.




Yes. Step 11 is where the architecture becomes concrete enough that we can later refactor the database without guessing.

The most important conclusion is this:

> **We should not model the whole tournament as one giant aggregate.**

A tournament can have hundreds of fixtures, entries, players, score events, standings updates, managers and messages. If all of that belongs to one transactional `Tournament` aggregate, every operation becomes coupled to everything else.

Instead, Matchday should have several small aggregates connected by stable IDs.

# Step 11 — Data Model & Aggregate Boundaries

## 11.1 First: aggregate is not the same thing as table

This distinction matters before designing SQL.

An **Aggregate Root** answers:

> “Which object controls consistency and mutation for this group of data?”

A table answers:

> “How is some data physically stored?”

For example:

```text id="t03wgg"
Fixture
├── Fixture Slot A
├── Fixture Slot B
└── Competition Outcome
```

can conceptually be one aggregate:

```text id="96rgpk"
Fixture = Aggregate Root
```

while physically using:

```text id="hcf2l4"
tournament_fixtures
tournament_fixture_slots
tournament_fixture_outcomes
```

Likewise:

```text id="iiilrz"
tournament_stage_standings
```

may be a table but it is **not** an aggregate root because it is only a derived projection.

That distinction will keep Clean Architecture much cleaner.

---

# 11.2 The canonical top-level model

I would organize Matchday Tournament around these boundaries:

```text id="g3m090"
TOURNAMENT
│
├── Tournament Memberships
│
├── Registrations
│      ↓ approved
│   Tournament Entries
│      ├── Squad
│      └── Payment history
│
├── Stages
│      ├── Stage Entries
│      ├── Groups
│      ├── Rounds
│      └── Draw Revisions
│             ↓ publish
│          Fixtures
│             ├── Slots
│             ├── Competition Outcome
│             └── Match Execution(s)
│                    ↓
│                  MATCH
│                    ↓
│             SPORT MATCH ENGINE
│
├── Standings Projections
├── Statistics Projections
├── Awards
│
└── Audit / Domain Events
```

Communication, notifications and chat remain outside this aggregate tree as integrations.

---

# 11.3 Aggregate Root 1 — Tournament

`Tournament` remains the root identity of the competitive event.

But it should become **smaller and cleaner** than today's entity.

Conceptually it owns:

```text id="q2ic9v"
Tournament

id
name
sport_id

description
branding

owner_user_id
created_by

visibility
registration policy

publication state
registration state
entry lock state
competition state
termination state

start/end planning dates

participant limits
entry fee policy

default sport configuration

created_at
updated_at
```

Notice what is **not** inside it:

```text id="6n3fcj"
teams[]
squad[]
standings[]
fixtures[]
matches[]
organizers[]
NRR
overs
groups
bracket links
```

Those belong elsewhere.

---

# 11.4 `created_by` and `owner_user_id` must become different concepts

This comes directly from Step 1 and Step 5.

Today:

```text id="p99qxq"
tournaments.created_by
```

is used partly as provenance and partly as authority.

Canonical:

```text id="c9woya"
created_by
= who originally created it

owner_user_id
= who currently owns it
```

Example:

```text id="0n35me"
Saran creates tournament
created_by = Saran
owner = Saran

Later transfers ownership to Ali

created_by = Saran
owner = Ali
```

Historical provenance remains true.

Authority changes.

That is much cleaner.

---

# 11.5 Tournament lifecycle stays on Tournament

The lifecycle states from Step 4 do **not** justify five separate tables.

They are state of the Tournament aggregate.

Conceptually:

```text id="m2jgnf"
publication_state
    draft / published

registration_state
    not_open / open / closed

entry_state
    editable / locked

competition_state
    not_started / in_progress / completed

termination_state
    none / cancelled / abandoned
```

Then public:

```text id="g578hf"
Draft
Registration Open
Upcoming
Live
Completed
Cancelled
Abandoned
```

is derived.

I would not store one authoritative overloaded `status` long-term.

---

# 11.6 Current `tournament_type` should stop being structural truth

Today Tournament owns:

```text id="o6b3id"
knockout
round_robin
league
group_knockout
double_elimination
```

After Step 2 this becomes wrong as the primary domain model.

Canonical competition structure lives in:

```text id="jhi1q4"
TournamentStage.format
```

So tournament-level type should become at most:

```text id="bfqwxv"
creation_template
```

Example:

```text id="ll3cwu"
template = group_knockout
```

materializes:

```text id="01nn4q"
Stage 1 = round_robin
Stage 2 = single_elimination
```

After materialization, the Stages are authoritative.

The template is just how the organizer started.

---

# 11.7 Current `format` and `rules` are also overloaded

Today:

```text id="42r7l5"
tournaments.format
tournaments.rules
```

contain Cricket information.

The current Flutter entity even exposes:

```text id="cvektq"
Tournament.maxOvers
Tournament.ballType
```

That violates Step 3.

Canonical separation:

```text id="2og4gp"
Tournament Core
    competition/lifecycle configuration

Sport Adapter
    sport defaults

Stage
    optional sport override

Fixture
    optional sport override

Match
    immutable rules snapshot
```

We can still physically use JSONB for sport configuration.

The key is that Tournament Core must treat it as opaque sport configuration.

---

# 11.8 A current Flutter drift I would flag

The live database has:

```text id="akjfsl"
tournaments.sport_id
```

but the current `Tournament` domain entity you have in Flutter does not expose `sportId`.

That's important.

After Step 3:

```text id="4gjgkz"
Tournament has exactly one sport
```

is a fundamental domain invariant.

So `sportId` must eventually become a first-class Tournament domain field rather than something only the DTO/database knows.

---

# 11.9 Aggregate Root 2 — Tournament Membership

Today:

```text id="4fl4g8"
tournaments.organizers uuid[]
```

plus:

```text id="d7jxx9"
created_by
```

answer authority.

Step 5 showed this won't scale.

Canonical relation:

```text id="io1j1r"
TournamentMembership

membership_id
tournament_id
user_id

role_key
status

appointed_by
appointed_at

removed_by?
removed_at?
```

Example:

```text id="dpr1ea"
Ali
Tournament 123
role = manager
status = active
```

The owner can remain directly on Tournament as:

```text id="xwy7sq"
owner_user_id
```

while memberships model delegated staff.

---

# 11.10 Reuse your capability engine

I would **not** build an unrelated Tournament RBAC implementation.

Your existing:

```text id="plru2g"
permissions
permission_scopes
role_permissions
grants
can(...)
```

is already the right direction.

We should extend it so:

```text id="mzrx5r"
scope = tournament
```

works with:

```text id="krkzy8"
TournamentMembership
```

the same way team scope works with `team_members`.

This is much cleaner than retaining:

```text id="s9vec6"
is_tournament_organizer()
```

as the long-term authority mechanism.

---

# 11.11 Aggregate Root 3 — Tournament Registration

Registration should finally get its own identity.

Something conceptually like:

```text id="n4w5da"
TournamentRegistration

registration_id
tournament_id
team_id

submitted_by
submitted_at

status
message

decided_by
decided_at
decision_reason
```

That's it.

Notice what disappears:

```text id="1vifm7"
seed
group
payment
squad
```

because those do not describe an application.

This would make the entity very clean.

---

# 11.12 Aggregate Root 4 — Tournament Entry

Once Registration is approved:

```text id="gicfbi"
TournamentRegistration
       ↓
    approval
       ↓
TournamentEntry
```

Conceptually:

```text id="uxpv2e"
TournamentEntry

entry_id
tournament_id
team_id

source_registration_id?

status
    active
    withdrawn
    disqualified

accepted_at
accepted_by

withdrawn_at?
disqualified_at?

replacement_for_entry_id?

created_at
updated_at
```

And this becomes the object competition structure references.

Not:

```text id="41k39e"
team_id
```

directly.

---

# 11.13 This is a very important ID change

Today fixture generation works with:

```text id="0r38yi"
team_id
```

Canonical Tournament Core should work with:

```text id="24vuhk"
entry_id
```

Why?

Because:

```text id="je5s9i"
Team
```

is a global organization.

But:

```text id="yc0n2c"
TournamentEntry
```

is that organization's participation in one competition.

This gives us:

```text id="e687qo"
Seed
Group
Qualification
Withdrawal
Disqualification
Replacement
```

without mutating global Team identity.

---

# 11.14 Keep the physical model team-only initially

We discussed not over-generalizing multi-sport architecture.

So although the domain term is:

```text id="rezdai"
TournamentEntry
```

the first physical model can absolutely have:

```text id="43g4ce"
team_id NOT NULL
```

We don't need:

```text id="47jx6a"
participant_type
participant_id
```

polymorphism yet.

If Matchday later supports singles sports, that can evolve deliberately.

For now:

> generic domain terminology, team-based physical implementation.

That's the right balance.

---

# 11.15 Tournament Entry should preserve enough historical identity

Suppose global Team later changes:

```text id="a9a92l"
name
logo
colors
```

The historical tournament should remain understandable.

So eventually Tournament Entry may preserve lightweight snapshots such as:

```text id="hc459u"
team_name_snapshot
team_logo_snapshot
```

or we can use a general historical projection.

Your existing `match_teams.team_name` snapshot pattern already demonstrates the value of this.

---

# 11.16 Squad belongs under Tournament Entry

Canonical:

```text id="m3qek7"
TournamentEntry
      │
      └── TournamentSquadMember
```

Conceptually:

```text id="kgoxan"
TournamentSquadMember

entry_id

user_id?
unclaimed_id?

display_name_snapshot

status
added_by
added_at

removed_by?
removed_at?
reason?
```

Use the same identity philosophy as `match_players`:

```text id="cpjm2j"
claimed profile XOR unclaimed player
```

rather than creating a third player identity system.

---

# 11.17 Squad state can live on Entry

We do not necessarily need:

```text id="kqlq93"
tournament_squads
```

as a separate root table.

There is one tournament squad per entry.

So Entry can hold:

```text id="629ay3"
squad_state
    editable / frozen

squad_revision

squad_frozen_at
```

while:

```text id="6t6c1g"
tournament_squad_members
```

contains the membership rows.

That is sufficiently normalized without adding a useless 1:1 header table.

---

# 11.18 Payment should not remain embedded in Registration

The current `tournament_teams` has:

```text id="8nhd5h"
payment_status
amount_paid
payment_channel
payment_reference
payment_recorded_at
payment_recorded_by
```

but Step 6 allows:

```text id="yj5qmg"
unpaid
partial
paid
```

Potentially multiple payment records.

Canonical model is better as:

```text id="r6fzuq"
TournamentEntryPayment

payment_id
entry_id

amount
channel
reference

recorded_by
recorded_at

status / voided_at if necessary
```

Then:

```text id="txeqh3"
entry.amount_paid
payment_status
```

can be projections/summary values.

This also provides proper history.

---

# 11.19 Aggregate Root 5 — Tournament Stage

This is the main structural aggregate.

Conceptually:

```text id="ewj2fx"
TournamentStage

stage_id
tournament_id

sequence
name

competition_format
    round_robin
    single_elimination
    double_elimination

state
    pending
    active
    completed

competition_config
sport_rules_override?

created_at
updated_at
```

For example:

```text id="i7vplg"
Stage 1
Group Stage
format = round_robin

Stage 2
Playoffs
format = single_elimination
```

This is the core Step-2 hierarchy finally becoming first-class data.

---

# 11.20 Stage configuration

`competition_config` could hold things such as:

```text id="ps2wnj"
cycles = 1
group_count = 4
qualifiers_per_group = 2
third_place_playoff = true
progression_mode = fixed_bracket
```

These are Tournament competition concepts.

Then:

```text id="0ncnkm"
sport_rules_override
```

contains opaque Cricket/Football/etc. configuration validated by the Sport Adapter.

Do not mix those two JSON objects.

---

# 11.21 Stage Entry

We also need an explicit relationship:

```text id="o8f9u9"
TournamentStageEntry
```

because not every Tournament Entry necessarily participates in every Stage.

For example:

```text id="zg3kr6"
16 Tournament Entries

Stage 1
16 participants

Stage 2
8 qualified participants
```

Conceptually:

```text id="x9fclc"
stage_id
entry_id
status
entered_at
source_stage_id?
qualification_source?
```

This gives us:

```text id="8kb9le"
Tournament Entry
→ participation in Stage 1
→ qualification to Stage 2
```

without duplicating the underlying team.

---

# 11.22 Seed should be Stage-scoped

This corrects another current design issue.

Today:

```text id="67nm59"
tournament_teams.seed_number
```

implies one seed for the entire tournament.

But:

```text id="dg6yqe"
Stage 1 seed
```

may differ from:

```text id="yn9bnf"
Playoff seed
```

if rankings determine playoff seeding.

So seed belongs in:

```text id="cclonf"
Stage participation / draw placement
```

not Tournament Registration.

---

# 11.23 Aggregate child — Tournament Group

Groups belong to Stage.

Canonical:

```text id="82zb2g"
TournamentGroup

group_id UUID
stage_id

name
sequence
```

For example:

```text id="ksih7r"
Group A
Group B
```

No more:

```text id="977kkp"
group_id = "A"
```

floating text across several tables.

Use a stable UUID.

Display name can change without breaking relationships.

---

# 11.24 Current group model has weak referential integrity

Today:

```text id="it6v1z"
tournament_teams.group_id text
matches.group_id text
tournament_standings.group_id text
```

There is no actual Group entity in the current live schema.

That means:

```text id="vnpfc8"
"A"
"Group A"
"group_a"
```

can theoretically become three different representations of the same concept.

A first-class `tournament_groups` table fixes this cleanly.

---

# 11.25 Aggregate child — Tournament Round

Canonical:

```text id="ovmy7k"
TournamentRound

round_id
stage_id
group_id?

round_number
label

state?
```

Examples:

```text id="j4gm14"
Round 1
Round 2
Quarter-final
Semi-final
Final
```

And from Step 2:

```text id="g7r34d"
Quarter-final
Semi-final
Final
```

are round labels, not tournament stages.

This removes the current ambiguity around:

```text id="azoaqu"
matches.stage
matches.round
bracket_round_number
```

---

# 11.26 Aggregate child — Draw Revision

A Stage can have:

```text id="i9m5v0"
DrawRevision
```

Conceptually:

```text id="p3rlo0"
draw_revision_id
stage_id

revision_number

status
    draft
    published
    superseded

based_on_entry_revision

plan_snapshot

created_by
created_at

published_by?
published_at?

revision_reason?
```

I intentionally included:

```text id="oxj8ov"
plan_snapshot
```

even if the active structure is normalized.

Why?

Because Step 7 says a published revision should remain historically inspectable.

An immutable snapshot of the exact published plan is a cheap, reliable audit artifact.

---

# 11.27 We do not need to normalize every historical revision

This is an important practicality decision.

The **active competition graph** should be relational.

Historical superseded Draw Revisions can retain an immutable structured snapshot.

We do not necessarily need to maintain complete duplicate normalized fixture graphs forever just so someone can inspect Draw Revision 1.

That would add substantial complexity.

So:

```text id="c4inpe"
Active structure:
normalized

Historical revision:
immutable snapshot + audit
```

is a pragmatic approach.

---

# 11.28 Aggregate Root 6 — Fixture

This is probably the most important new aggregate.

Canonical:

```text id="6qowvv"
TournamentFixture

fixture_id

tournament_id? derived
stage_id
round_id

draw_revision_id

fixture_number / code

state
    unresolved
    ready
    in_progress
    resolved
    voided

scheduled_start_time
venue_id?

created_at
updated_at
```

Fixture owns:

```text id="t59ow9"
competition position
schedule
participant sources
competition resolution
```

It does **not** own Cricket scoring.

---

# 11.29 Fixture should be the tournament parent of Match

This is the biggest structural shift from the current database.

Today:

```text id="2f7mof"
matches.tournament_id
matches.stage
matches.round
matches.bracket_round_number
matches.prev_match_a_id
...
```

means Match is doing two jobs:

```text id="p6m3cy"
Tournament Fixture
+
Sport Match
```

Canonical:

```text id="od7fvr"
Fixture
    ↓
Match
```

So Match knows:

```text id="snz7t3"
fixture_id
```

and Fixture knows tournament structure.

---

# 11.30 Tournament topology should leave `matches`

Eventually these current fields should belong to Tournament structure rather than Match:

```text id="5q1mga"
stage
round
bracket_round_number
bracket_match_number
prev_match_a_id
prev_match_b_id
group_id
```

Those are not sport-match properties.

They answer:

> Where does this contest exist in the competition?

That is Fixture.

This is a major Step-11 conclusion.

---

# 11.31 What should remain on Match

The shared Match aggregate should keep things like:

```text id="7l37xr"
match_id
sport_id
fixture_id? nullable

scheduled/actual execution timestamps
match execution state
team snapshots
created_by/provenance
```

Then sport-specific tables extend it:

```text id="pqi48z"
matches
    ↓
cricket_matches
```

just as they do today.

---

# 11.32 Your current Match architecture is largely worth preserving

These tables are conceptually strong:

```text id="8cgexx"
matches
match_teams
match_players

cricket_matches
cricket_match_players

match_officials
match_scorer_leases
```

I would preserve that overall shape.

It already follows:

```text id="tua4e7"
generic core
+
sport extension
```

which is exactly what Step 3 wants.

The main change is removing Tournament topology from the Match aggregate.

---

# 11.33 Fixture Slots

Canonical:

```text id="710xcq"
TournamentFixtureSlot

fixture_id
side
    A / B

source_type

source reference

resolved_entry_id?

resolved_at?
resolution_reason?
```

Example:

```text id="a521js"
SF1 Slot A
source = fixture_winner
source_fixture = QF1
resolved_entry = Lahore Lions Entry
```

---

# 11.34 Avoid weak polymorphic `source_id` if possible

A simple model like:

```text id="39qcb7"
source_type
source_id
```

is flexible but destroys referential integrity because `source_id` might refer to:

```text id="gykyze"
Entry
Fixture
Group
Stage
```

depending on a string.

I'd prefer typed fields or a constrained source model.

Conceptually:

```text id="ylm4y0"
source_type

source_entry_id?
source_fixture_id?
source_group_id?
source_stage_id?

source_rank?
source_outcome?
```

with a constraint based on `source_type`.

That lets PostgreSQL actually protect the graph.

---

# 11.35 Example Fixture Slot sources

A direct first-round slot:

```text id="se61e8"
source_type = entry
source_entry_id = Entry A
```

Semi-final:

```text id="n0cql8"
source_type = fixture_outcome
source_fixture_id = QF1
source_outcome = winner
```

Third place:

```text id="14coz1"
source_type = fixture_outcome
source_fixture_id = SF1
source_outcome = loser
```

Group qualification:

```text id="m0qs0i"
source_type = group_rank
source_group_id = Group A
source_rank = 1
```

That directly implements Step 7.

---

# 11.36 Bye should not require a fake Fixture

Still preserving our earlier rule:

```text id="dgf5jf"
BYE ≠ MATCH
```

If Seed 1 advances automatically, Draw/Progression records:

```text id="jdz9ni"
Entry A advanced by bye
```

and resolves the target fixture slot.

There is no fake scorecard.

No fake Match.

No scorer.

No `completed` row pretending sport happened.

---

# 11.37 Fixture Competition Outcome

Step 8 established:

```text id="mpz35k"
Sporting Result
≠
Competition Outcome
```

So Fixture should have an authoritative competition resolution.

Conceptually:

```text id="11q5r3"
FixtureOutcome

fixture_id

outcome_type
    sporting
    walkover
    forfeit
    administrative
    no_contest
    etc.

winner_entry_id?
loser_entry_id?

source_match_id?

finalized_by?
finalized_at

reason?
revision
```

Tournament progression should consume this.

Not `cricket_matches.result` directly.

---

# 11.38 Why we need that separation

Suppose Cricket says:

```text id="j5rj1o"
Lahore won on field
```

but tournament later rules:

```text id="qkpf2i"
Kasur advances
```

We preserve:

```text id="i1q78b"
Cricket Match Result:
Lahore won

Fixture Competition Outcome:
Kasur advances
```

without falsifying the Cricket scorecard.

That is an extremely powerful integrity model.

---

# 11.39 Fixture → Match should support more than one execution

This comes directly from Step 8's Replay concept.

Canonical relationship:

```text id="8q3jjc"
Fixture
   ├── Match Execution 1
   │      abandoned
   │
   └── Match Execution 2
          completed
```

So I would conceptually introduce:

```text id="274woo"
TournamentFixtureMatch

fixture_id
match_id
attempt_number
status / role
```

rather than assuming:

```text id="u2y40o"
Fixture has exactly one Match forever.
```

V1 usually has one execution.

The data model still handles replay correctly later.

---

# 11.40 Therefore `matches.fixture_id` alone may not be enough

We have two options.

Simpler:

```text id="e4g2bt"
matches.fixture_id
attempt_number
```

or a joining relation:

```text id="0iaygj"
tournament_fixture_matches
```

I prefer the joining relation conceptually because:

```text id="eeb5yu"
Match
```

can remain a sport execution object without tournament-specific attempt semantics.

But either representation can work.

The important domain cardinality is:

```text id="fvu978"
Fixture 1 → 0..N Match executions
```

not hard-coded 1:1.

---

# 11.41 Match Teams remain snapshots

When a fixture's participants resolve:

```text id="of3x3f"
Fixture Slot A → Entry A
Fixture Slot B → Entry B
```

and sport execution materializes:

```text id="1v6j1u"
Match
```

then:

```text id="zst2ct"
match_teams
```

captures the actual teams for that execution.

This is a good current pattern.

No reason to remove it.

---

# 11.42 Tournament Squad → Match Players

For tournament matches, match player materialization should come from:

```text id="1d7fj4"
Tournament Squad
```

not simply the current Team roster.

Conceptually:

```text id="p3xw4g"
Tournament Squad
    ↓ eligibility
Match Players
    ↓
Cricket Playing XI
```

Then:

```text id="mm7ilr"
match_players.source
```

could eventually distinguish:

```text id="oww8ip"
team_snapshot
tournament_squad
manual
```

or similar.

The exact enum can come later.

---

# 11.43 Match Officials stay where they are

Current:

```text id="057qnu"
match_officials
```

belongs to Match/fixture operations.

That's appropriate.

Tournament managers assign them, but the assignment targets:

```text id="d6zq5p"
one Match execution
```

or potentially a Fixture if assigned before execution materializes.

We may eventually decide whether pre-match official assignment attaches to Fixture and then transfers to Match, but the current Match assignment is workable.

---

# 11.44 Scorer Lease definitely stays Match-level

Current:

```text id="obatnp"
match_scorer_leases
```

is exactly where it belongs.

It answers:

> Which user/device currently controls scoring writes for this Match execution?

That is not Tournament state.

It should remain:

```text id="utpa6o"
Match Operations
```

and separate from:

```text id="hx9vem"
Tournament authorization
```

Excellent boundary.

---

# 11.45 Stage standings are projections, not aggregates

Canonical:

```text id="mgzl8n"
TournamentStageStanding

stage_id
group_id?
entry_id

rank
played
competition_points

qualification_status

finality
    provisional / final

revision
updated_at
```

But this remains a projection.

It should be rebuildable.

---

# 11.46 Do not make generic Standings Cricket-shaped

Then follow the same pattern as Match:

```text id="m2lmg1"
Generic Stage Standing
        +
Cricket Standing Metrics
```

For example:

```text id="gdvs6q"
cricket_stage_standing_metrics

stage_id
group_id?
entry_id

wins
losses
ties
no_results

runs_for
legal_balls_faced

runs_against
legal_balls_bowled

net_run_rate
```

Future:

```text id="iderrb"
football_stage_standing_metrics
```

could contain:

```text id="4z9587"
goals_for
goals_against
goal_difference
```

That's much cleaner than adding every future sport's columns into one giant table.

---

# 11.47 Use legal balls, not decimal overs, as stored calculation facts

Current standings store:

```text id="x4g8kn"
overs_faced numeric
overs_bowled numeric
```

For Cricket calculations I would rather canonicalize:

```text id="l7gx0t"
legal_balls_faced
legal_balls_bowled
```

because:

```text id="oac2ii"
19.4 overs
```

is display notation, not a decimal number.

Then:

```text id="kjz8kd"
oversText
```

is derived.

That prevents NRR arithmetic mistakes.

---

# 11.48 Rank should be server-side

Current Flutter:

```text id="iy34ti"
TournamentStanding.rank = 0
copyWithRank(...)
```

suggests rank can be attached in presentation.

Canonical:

```text id="sepfqq"
rank
```

is part of the authoritative standings projection produced by the Sport Competition Adapter.

Flutter only renders it.

This is business truth, not presentation logic.

---

# 11.49 Awards deserve a proper relation once they become real history

Today:

```text id="y6xi8s"
tournaments.awards jsonb
```

is okay for prototyping.

Canonical long-term:

```text id="6itjvb"
TournamentAward

award_id
tournament_id

award_type
title

recipient_entry_id?
recipient_player_identity?

source
    automatic suggestion
    organizer selected

confirmed_by
confirmed_at
```

Then:

```text id="jc1czp"
Champion
```

still does not belong here—it is competition placement.

Awards are ceremonial/statistical.

---

# 11.50 Venue model

Current:

```text id="0ngg0p"
tournament_grounds
grounds
```

is structurally good as a many-to-many association.

But terminology is Cricket-oriented.

Tournament Core should conceptually use:

```text id="10x2u3"
Venue
```

because Football may use a pitch/stadium and Basketball a court.

I would not rush to rename the database immediately.

For now:

```text id="z6po3x"
Ground
```

can be the concrete current venue resource.

But Domain APIs should increasingly say:

```text id="jlyb8l"
venue
```

rather than make every future sport understand “ground.”

---

# 11.51 Audit Event

Step 8 requires durable administrative history.

Conceptually:

```text id="zd8tgp"
TournamentAuditEvent

event_id
tournament_id

entity_type
entity_id?

operation
actor_id
reason?

before_summary?
after_summary?

occurred_at
```

Examples:

```text id="2ct5oc"
draw_published
fixture_rescheduled
walkover_declared
entry_disqualified
result_overridden
tournament_cancelled
```

This is **not** event sourcing.

Current database state remains authoritative.

Audit Event explains important changes.

---

# 11.52 Domain Outbox is different

From Step 10:

```text id="8crv91"
OutboxEvent

event_id
event_type
aggregate_type
aggregate_id

payload
created_at
processed_at?
attempt_count
```

Purpose:

```text id="t4dd1j"
notifications
chat projection
feed activity
search
analytics
realtime integrations
```

The difference is critical:

```text id="j04adm"
Audit Log
= permanent human/history record

Outbox
= reliable integration delivery mechanism
```

Do not use one table to pretend it is both.

Outbox records can eventually be archived/pruned.

Audit usually should not be.

---

# 11.53 Communication data remains outside Tournament Core

I would **not** add:

```text id="atke4t"
chat_channel_id
```

to every Tournament entity merely because it has chat.

Communication can maintain its own association:

```text id="6i4cx7"
channel.context_type = tournament
channel.context_id = tournament_id
```

or equivalent.

Tournament emits:

```text id="ezp9m5"
EntryActivated
EntryWithdrawn
TournamentCompleted
```

and the Chat integration reacts.

This is cleaner than Tournament aggregate mutating channel membership itself.

---

# 11.54 Current `tournament_teams` is the biggest overloaded table

Today it simultaneously represents:

```text id="reaz1h"
Registration
Tournament Entry
Squad
Seed
Group Assignment
Payment Ledger
Decision History
```

This is the clearest table that should eventually be split.

Canonical destinations:

| Current `tournament_teams` field | Future owner |
|---|---|
| registration_id | TournamentRegistration |
| tournament_id | Registration / Entry |
| team_id | Registration / Entry |
| registered_by/at | Registration |
| status pending/approved/rejected | Registration |
| message | Registration |
| decided_by/at/reason | Registration |
| squad[] | TournamentSquadMember |
| seed_number | Stage placement |
| group_id | Stage placement |
| payment_* | Entry Payment |
| approved participation | TournamentEntry |

This is not cosmetic normalization.

Each of these concepts has a different lifecycle and different authorization rules.

---

# 11.55 Current `tournament_standings` is the second major split

Today it mixes:

```text id="mwo8z5"
generic competitive standing
+
Cricket calculation
```

Canonical:

```text id="3fgprt"
tournament_stage_standings
```

for generic ranking.

Plus:

```text id="u44bh6"
cricket_stage_standing_metrics
```

for Cricket.

And scope changes from:

```text id="6ycr9n"
tournament_id + team_id
```

to:

```text id="6epfu4"
stage_id + entry_id
(+ group_id where applicable)
```

That directly implements Step 9.

---

# 11.56 Current `matches` is the third major split

Today:

```text id="bfl12v"
matches
```

owns both:

```text id="6w041i"
Sport Match
```

and:

```text id="oa7n2e"
Tournament Fixture topology
```

Canonical:

```text id="pw6wz9"
TournamentFixture
→ competition structure
```

and:

```text id="1kr3p5"
Match
→ sporting execution
```

Fields such as:

```text id="soacra"
prev_match_a_id
prev_match_b_id
bracket_round_number
bracket_match_number
round
group_id
```

should eventually leave the generic Match aggregate.

---

# 11.57 What stays strong in the current schema

Several things should not be thrown away.

| Current structure | Step-11 verdict |
|---|---|
| `tournaments` | **Keep as root, slim/refactor** |
| `tournament_grounds` | **Keep concept, generalize terminology later** |
| `tournament_teams` | **Split** |
| `tournament_standings` | **Replace with stage projection + sport extension** |
| `matches` | **Keep as Match root; remove tournament topology eventually** |
| `match_teams` | **Keep** |
| `match_players` | **Keep** |
| `cricket_matches` | **Keep** |
| `cricket_match_players` | **Keep** |
| `match_officials` | **Keep** |
| `match_scorer_leases` | **Keep** |
| `organizers[]` | **Replace with memberships** |
| `tournament_type` | **Demote to template/preset** |
| `format/rules` | **Separate competition config from sport config** |
| bracket feeder columns on `matches` | **Move to Fixture Slots** |

This is not a rewrite-everything conclusion.

A large part of your Match domain can remain.

The bigger redesign is the **Tournament structural layer above Match**.

---

# 11.58 New first-class structural entities are justified

I checked the current live schema: there are currently no first-class tables for:

```text id="z6tl8s"
Tournament Stage
Tournament Group
Tournament Round
Draw Revision
Tournament Fixture
Fixture Slot
Tournament Membership
Tournament Entry
Tournament Squad Member
Tournament Audit Event
```

Today those concepts are represented indirectly through enums, text fields, arrays, JSON, and Match columns.

After Steps 1–10, they are no longer incidental details.

They now have their own:

```text id="upag57"
identity
lifecycle
authorization
invariants
history
```

which means first-class representation is justified.

---

# 11.59 Proposed canonical relational picture

The database eventually looks conceptually like this:

```text id="c5wcp8"
tournaments
    │
    ├── tournament_memberships
    │
    ├── tournament_registrations
    │
    ├── tournament_entries
    │       │
    │       ├── tournament_squad_members
    │       └── tournament_entry_payments
    │
    ├── tournament_stages
    │       │
    │       ├── tournament_stage_entries
    │       ├── tournament_groups
    │       ├── tournament_rounds
    │       ├── tournament_draw_revisions
    │       │
    │       └── tournament_fixtures
    │               │
    │               ├── tournament_fixture_slots
    │               ├── tournament_fixture_outcome
    │               └── tournament_fixture_matches
    │                           │
    │                           └── matches
    │                                │
    │                                ├── match_teams
    │                                ├── match_players
    │                                ├── match_officials
    │                                ├── match_scorer_leases
    │                                │
    │                                └── cricket_matches
    │                                     └── ...
    │
    ├── tournament_stage_standings
    │       └── cricket_stage_standing_metrics
    │
    ├── tournament_awards
    │
    └── tournament_audit_events

generic_outbox_events
    ↓
notifications / chat / feed / search / analytics
```

That is the architecture I would use as our reference model.

---

# 11.60 Important: this does not mean 18 tables in one migration

We should not make the mistake of taking the canonical model and immediately creating everything at once.

The model defines:

> **Where each responsibility belongs.**

Migration can be staged.

For example, a first structural refactor could introduce only:

```text id="msf28u"
tournament_memberships

tournament_registrations
tournament_entries
tournament_squad_members

tournament_stages
tournament_groups
tournament_rounds

tournament_fixtures
tournament_fixture_slots
```

while temporarily retaining compatibility projections for old Flutter code.

Then DrawRevision, payments, audit, projections, etc. can be migrated deliberately.

We will decide migration order later.

---

# 11.61 Aggregate boundaries

This is how I would define the actual consistency boundaries:

| Aggregate Root | Owns |
|---|---|
| **Tournament** | identity, owner, sport, policies, high-level lifecycle |
| **TournamentMembership** | one user's delegated tournament authority |
| **TournamentRegistration** | application and organizer decision |
| **TournamentEntry** | accepted participation, squad lifecycle, participation status |
| **TournamentStage** | format, groups, rounds, stage participation, qualification configuration |
| **DrawRevision** | immutable structural publication version |
| **Fixture** | slots, schedule, resolution, competition outcome |
| **Match** | actual sport execution |
| **Cricket Match** | Cricket extension of Match |

And these are **not aggregate roots**:

```text id="3d5s68"
Standings
Stats
Leaderboards
Public tournament page
Bracket UI
Live Ops board
Search results
```

Those are projections/read models.

That is an essential Clean Architecture distinction.

---

# 11.62 Command boundaries now become much clearer

Example:

```text id="ccw0fc"
ApproveRegistration
```

mutates:

```text id="79gdej"
Registration
+
creates TournamentEntry
```

as one atomic domain command.

---

```text id="vk6a5h"
PublishDraw
```

mutates:

```text id="u13l80"
Stage
DrawRevision
Fixtures
Slots
```

transactionally.

---

```text id="o03gxj"
RecordBall
```

mutates:

```text id="jm4o9t"
Match / Cricket Match
```

not Tournament structure.

---

```text id="nxl0lb"
FinalizeMatch
```

coordinates:

```text id="qir0bk"
Match result
Fixture competition outcome
Standings projection
Progression
```

through an application/domain service.

That is much cleaner than a repository that does every tournament operation.

---

# 11.63 Repository boundaries should follow aggregates

This has a direct implication for Flutter/Backend Clean Architecture.

Today:

```text id="5ezp3v"
TournamentsRepository
```

is huge and includes:

```text id="c8hmsa"
registration
draw
standings
fees
officials
DLS
Super Over
leaderboards
awards
live ops
```

That is effectively becoming a god repository.

After Step 11 I would expect boundaries more like:

```text id="6tk013"
TournamentRepository

TournamentRegistrationRepository

TournamentEntryRepository

TournamentCompetitionRepository
    stages/draw/fixtures

TournamentOperationsRepository

TournamentStandingsRepository
```

with Cricket operations remaining under Cricket Match/Competition services.

We don't necessarily need six Dart files just because I wrote six names.

But **domain responsibilities should be separated along these boundaries**.

---

# 11.64 Queries don't need to obey aggregate boundaries

One important Clean Architecture point:

Commands should respect aggregate ownership.

But reads can join anything.

For example:

```text id="i6yko1"
Tournament Detail Read Model
```

can join:

```text id="ma5wxc"
Tournament
Entries
Teams
Fixtures
Live scores
Standings
Stats
```

into one efficient query/view.

That does **not** mean they belong to one aggregate.

CQRS-style thinking helps here:

```text id="a7z7w7"
WRITE MODEL
strict domain boundaries

READ MODEL
optimized for screens
```

We don't need full CQRS infrastructure.

Just don't force screen shape to dictate domain shape.

---

# 11.65 Organizer Console is a read model composition

For example:

```text id="wwfucw"
Organizer Console
```

may need:

```text id="xq270e"
Tournament lifecycle
Registration requests
Entries
Squad readiness
Draw state
Fixtures
Scorers
Live matches
Warnings
```

That's a composite read model.

It does not justify creating:

```text id="3gl7ko"
TournamentEverythingEntity
```

in the domain.

This is precisely where the current feature is beginning to get overloaded.

---

# 11.66 IDs should always be stable; labels are display values

For new structural entities I strongly recommend UUID identifiers:

```text id="gecziq"
stage_id
group_id
round_id
entry_id
fixture_id
draw_revision_id
```

Do not use:

```text id="ykh85p"
"Group A"
"Semi-Final"
"r2m1"
```

as database identity.

Those are useful:

```text id="z9jvi7"
codes
labels
display keys
```

but not relational identity.

Your current DrawPlan's:

```text id="073xsl"
r2m1
```

is perfectly fine as a temporary plan-local identifier before persistence.

The database should mint stable UUIDs when published.

---

# 11.67 One final boundary: sport configuration snapshot

Tournament sport defaults may change before competition.

But once a Match execution materializes:

```text id="hffpkn"
Sport Match
```

it should receive an immutable rules snapshot.

Your existing:

```text id="xc40b6"
cricket_matches.rules_snapshot
```

is already a very good idea.

I would preserve this.

The inheritance becomes:

```text id="81urxp"
Tournament sport default
        ↓
Stage override
        ↓
Fixture override
        ↓
MATCH MATERIALIZATION
        ↓
Immutable cricket_matches.rules_snapshot
```

Then changing future tournament defaults does not rewrite an existing scorecard.

Excellent boundary.

---

# 11.68 The canonical ownership map

The cleanest way to remember Step 11 is:

```text id="h9c7i8"
TOURNAMENT
"What competition is this?"

ENTRY
"Who is participating?"

STAGE
"How is this phase structured?"

FIXTURE
"Who should meet here, and where does the result go?"

MATCH
"What actually happened on the field?"

SPORT ENGINE
"What does this sport mean?"

STANDINGS
"What is the derived competitive ranking?"

COMMUNICATION
"Who needs to hear about it?"
```

No one object should answer all seven questions.

---

# Step-11 standard to freeze

1. **Tournament remains the root competitive event, but must not contain its entire competition graph or participant data.**
2. **`created_by` is provenance; `owner_user_id` is current root authority.**
3. **Tournament public status is derived from orthogonal lifecycle states rather than one overloaded status enum.**
4. **Tournament `type` becomes an authoring template/preset; Stages are structural truth.**
5. **A Tournament owns one immutable sport identity; sport configuration remains separate from competition structure.**
6. **Tournament Membership becomes a normalized relation and integrates with the existing capability engine.**
7. **Registration and Tournament Entry are separate aggregates.**
8. **Competition structure references `entry_id`, not global `team_id`, as its participant identity.**
9. **Tournament Squad belongs to Entry and uses the same claimed/unclaimed player identity philosophy as Match Players.**
10. **Payment history should be modeled independently of Registration when multiple/partial payments are supported.**
11. **Tournament Stage becomes first-class and owns competition format.**
12. **Stage participation becomes first-class because later stages contain qualified subsets of Tournament Entries.**
13. **Groups belong to Stages and use stable IDs rather than text identifiers.**
14. **Rounds belong to Stages/Groups; QF/SF/Final are Round labels.**
15. **Draw Revision is an immutable publication record; active structure is relational while historical revisions may retain snapshots.**
16. **Fixture becomes the tournament-side contest aggregate.**
17. **Fixture Slots own participant-source logic and progression dependencies.**
18. **Tournament topology must move out of the generic Match aggregate.**
19. **Fixture and Match have a 1→0..N relationship conceptually so replay can preserve historical executions.**
20. **Sporting Result and Fixture Competition Outcome remain separate records of truth.**
21. **The existing `matches + sport extension` design should be preserved.**
22. **Match Officials and Scorer Leases remain Match-level concerns.**
23. **Standings are Stage/Group-scoped derived projections, not aggregates or source-of-truth data.**
24. **Sport-specific standing metrics should extend generic standings in the same way `cricket_matches` extends `matches`.**
25. **Audit history and integration outbox are separate infrastructure concerns.**
26. **Communication/chat remains outside Tournament Core and reacts to domain events.**
27. **Write boundaries follow aggregates; read models are free to join across aggregates for efficient UI.**
28. **Stable UUIDs identify structural entities; human labels/codes never serve as relational identity.**
29. **Sport Match rules are snapshotted at Match materialization so future tournament edits cannot rewrite sporting history.**

With Step 11, we have now moved from **product behavior** into a coherent **domain/data architecture**.

The next step I would make **Step 12 — Command Model, Application Services & Transaction Boundaries**. That is where we define the actual server commands such as `CreateTournament`, `PublishTournament`, `ApproveRegistration`, `LockEntries`, `PublishDraw`, `RescheduleFixture`, `FinalizeMatchResult`, `DeclareWalkover`, `CorrectResult`, etc.; which aggregate each command may touch; what must happen in one transaction; what becomes an outbox event; and which logic belongs in NestJS/application services versus PostgreSQL constraints versus the Cricket Match Engine.



> **CANONICAL ARCHITECTURE UPDATE (Phase 5, 2026-10-02)**
> The text below originally assumed Supabase Edge Functions for all commands.
> As implemented in Phase 5, **the canonical Tournament write path is NestJS + PostgreSQL (Supabase)**:
>
> ```text
> Flutter
>     │
>     ├── Read queries
>     │      ↓
>     │   Supabase Data API / PostgREST / RPC read models
>     │
>     └── Tournament domain commands
>            ↓
>         NestJS Tournament HTTP API
>            ↓
>         TournamentCommandExecutor (withCommandTransaction)
>            ↓
>         PostgreSQL
> ```
>
> `cricket-match-action` remains the Sport Match command authority in Supabase Edge Functions.
> No `supabase/functions/tournament-action` exists or will be created.
> The architectural principles below (Command vs Query separation, lifecycle validation, advisory locking, idempotency, revision-based concurrency, explicit authorization, audit, outbox) remain valid and are implemented in NestJS — not in an Edge Function.

# Step 12 — Command Model, Application Services & Transaction Boundaries

The core rule should be:

> **Reads ask what is true. Commands attempt to change truth.**

And:

> **Every meaningful Tournament state change should have one explicit server-authoritative command.**

So instead of:

```text
Flutter
→ update random table
→ update another table
→ invoke RPC
→ maybe trigger something
```

we move toward:

```text
Flutter
    ↓
COMMAND
    ↓
Authenticate
    ↓
Authorize
    ↓
Lock relevant state
    ↓
Validate lifecycle + invariants
    ↓
Apply complete state transition
    ↓
Audit + domain event/outbox
    ↓
COMMIT
    ↓
Realtime / notifications / chat
```

---

# 12.1 Command vs Query

This is the first distinction to freeze.

## Query

A query:

```text
get tournament
get registrations
get fixtures
get standings
get live board
get leaderboard
```

does not change business state.

Queries can continue using:

```text
Flutter
   ↓
PostgREST
Views
Read RPCs
Realtime projections
```

with appropriate RLS.

---

## Command

A command means:

> “Attempt this business action.”

Examples:

```text
PublishTournament
ApproveRegistration
LockEntries
PublishDraw
RescheduleFixture
AssignScorer
DeclareWalkover
CorrectResult
CancelTournament
```

A command is not:

```text
update tournaments
set status = ...
```

even if the resulting SQL eventually looks that simple.

The **meaning** of the command is more important than the physical update.

---

# 12.2 Recommended server command boundary

You already have a strong pattern in:

```text
supabase/functions/cricket-match-action/
```

> **HISTORICAL NOTE — superseded before Phase 5 implementation.**
> The sections below originally proposed `supabase/functions/tournament-action` as the Tournament command authority. This was **never implemented**. Phase 5 delivered a NestJS command execution layer instead:

```text
backend/libs/modules/tournaments/src/
├── tournaments.module.ts
├── application/
│   ├── command-executor/
│   │   ├── tournament-command-executor.ts
│   │   └── tournament-command-handler.ts
│   ├── commands/
│   └── handlers/
├── domain/
│   ├── command/
│   │   ├── tournament-command.ts
│   │   └── json-result.ts
│   ├── ports/
│   │   ├── tournament-root.repository.ts
│   │   └── tournament-authorization.repository.ts
│   └── errors/
└── infrastructure/
    └── persistence/
        ├── postgres-tournament-root.repository.ts
        └── postgres-tournament-authorization.repository.ts
```

This is the NestJS-resident command layer — not a Supabase Edge Function.

---

# 12.3 Application Services in the NestJS architecture

In the implemented architecture, the Application Service layer lives in NestJS:
- `TournamentCommandExecutor` orchestrates execution, advisory locking, idempotency, revision checks, capability authorization, transaction lifecycle, and receipt recording.
- Individual command handlers implement `TournamentCommandHandler<C, R>` to coordinate domain logic for specific commands.
- All transactional work runs inside `withCommandTransaction`.

For example:

```text
ApproveRegistrationHandler
```

coordinates:

```text
Registration
Tournament Entry
Audit
Outbox
```

inside one PostgreSQL transaction managed by `withCommandTransaction`.

---

# 12.4 NestJS TournamentsModule command routing

Rather than 25 independent endpoints or functions, Tournament commands are coordinated through one modular NestJS boundary:

```text
one NestJS TournamentsModule
+
one TournamentCommandExecutor
+
many TournamentCommandHandler<C, R> implementations
```

This centralizes:
- JWT authentication and actor claim extraction
- Transaction-local PostgreSQL claims (`request.jwt.claim.*`)
- Transactional advisory locking
- Idempotency receipts in `private.tournament_command_receipts`
- Concurrency checks (`tournaments.revision`, `tournaments.entry_revision`)
- Explicit capability authorization via `public.can()`
- Canonical JSON-domain result normalization

---

# 12.5 Keep Cricket and Tournament command boundaries separate

This is also important.

We should retain:

```text
cricket-match-action
```

for:

```text
record toss
configure lineup
start innings
record/undo scoring
revised Cricket conditions
Super Over
complete Cricket sporting result
```

And use:

```text
NestJS Tournament API
```

for:

```text
registration
entries
draw
fixtures
scorer assignment
walkover
competition outcome
qualification
tournament lifecycle
```

Today those boundaries are mixed.

Your current:

```text
cricket-match-action/command_router.ts
```

contains both:

```text
record_toss
start_match
start_innings
undo_last_ball
```

and:

```text
tournament_reschedule_match
tournament_declare_walkover
tournament_override_result
```

while:

```text
tournament_revise_match_conditions
tournament_trigger_super_over
```

are genuinely Cricket operations despite their names.

So later I would separate them like this:

```text
NESTJS TOURNAMENT API

reschedule_fixture
declare_walkover
override_competition_outcome
assign_scorer
```

versus:

```text
CRICKET MATCH ACTION

revise_conditions
trigger_super_over
record_toss
start_innings
```

That's the Step-3 boundary applied to command architecture.

---

# 12.6 Direct PostgREST writes need a strict rule

I would not say:

> “Never write directly through PostgREST.”

That would be unnecessarily rigid.

Instead:

### Direct client write is acceptable when

The operation is:

```text
single-resource
non-lifecycle
non-structural
no cross-aggregate side effects
no complex invariant
properly protected by RLS
```

Example:

```text
edit draft tournament description
```

could potentially remain direct.

But even then, using the command endpoint can improve consistency.

---

### Command endpoint is mandatory when

The operation:

```text
changes lifecycle
changes authority
creates/deletes structural entities
affects multiple records
affects progression
requires audit
requires idempotency
requires locking
has downstream effects
```

Then it must go through:

```text
NestJS Tournament API
```

or the relevant sport command function.

---

# 12.7 Current direct writes that should eventually become commands

Your current `TournamentsRemoteDataSource` shows several examples.

### `publishTournament()`

Currently:

```dart
update({
  'status': 'registration',
})
```

This should become:

```text
PublishTournament
```

because Step 4 established that:

```text
publish
≠
open registration
```

and publication needs lifecycle validation.

---

### `registerTeam()`

Currently it directly inserts:

```text
tournament_id
team_id
registered_by
squad
status = pending
```

But Step 6 gives registration many invariants:

```text
registration open?
same sport?
already registered?
capacity?
team permission?
```

Therefore:

```text
SubmitTournamentRegistration
```

should become a command.

---

### `withdrawRegistration()`

Currently:

```text
status = withdrawn
```

directly.

But:

```text
pending application withdrawal
```

and:

```text
approved Tournament Entry withdrawal
```

are now two different domain operations.

So this also becomes command-driven.

---

# 12.8 `setTournamentGrounds()` currently has an atomicity problem

Today Flutter effectively does:

```text
DELETE tournament_grounds
```

then:

```text
INSERT tournament_grounds
```

as separate requests.

Suppose:

```text
DELETE succeeds
network fails
INSERT never happens
```

Now the tournament unexpectedly has no grounds.

Canonical command:

```text
SetTournamentVenues
```

should perform:

```text
BEGIN

authorize
validate venues
delete/replace relation
insert new relation
audit if necessary

COMMIT
```

all or nothing.

---

# 12.9 `createTournament()` has a similar boundary

Today:

```text
INSERT tournament
```

returns successfully, then Flutter separately calls:

```text
setTournamentGrounds()
```

If step 2 fails:

```text
Tournament exists
Ground configuration incomplete
```

For draft creation this may not be catastrophic, but it's still a partial workflow.

Canonical:

```text
CreateTournament
```

can atomically create:

```text
Tournament
Owner relationship
default stage template if required
venue relations
```

in one command.

---

# 12.10 Auto group distribution is another good example

Today Flutter:

```text
fetch approved registrations
for each registration:
    update group_id
```

That's multiple network operations.

If operation #5 fails:

```text
Team 1 Group A
Team 2 Group B
Team 3 Group A
Team 4 Group B
Team 5 unassigned
...
```

Canonical:

```text
AssignStageGroups
```

should generate and persist the entire group assignment transactionally.

This becomes even more important once Group is a real Stage entity.

---

# 12.11 PostgreSQL's responsibility

Postgres should remain very powerful.

But we need a clean boundary.

Postgres should own **integrity**.

Examples:

```text
PRIMARY KEY
FOREIGN KEY
UNIQUE
CHECK
NOT NULL
exclusion/conflict constraints where appropriate
```

plus:

```text
transactions
row locking
indexes
RLS
stable authorization lookup helpers
```

It should ensure impossible data cannot exist.

---

# 12.12 NestJS command handler responsibility

NestJS command handlers own **behavior**:

Examples:

```text
Can this tournament be published?
Can this registration be approved?
Can entries be locked?
What happens when a fixture result changes?
Which downstream slots need resolving?
Should the tournament now become live?
```

This division remains our fundamental architectural rule:

```text
PostgreSQL = integrity (constraints, triggers, RLS, audit, receipts)
NestJS     = behavior (domain rules, lifecycle, authorization via public.can())
```

---

# 12.13 Database functions / RPCs still have a place

We should not remove all RPCs.

Supabase's current guidance explicitly says database functions are suitable for data-intensive operations that run close to the data. :chatgpt-content-reference{index="1"}

Good candidates include:

```text
complex read queries
leaderboard aggregations
standings calculation primitives
search
bulk set-based operations
authorization helper queries
```

For example, these are reasonable database-oriented functions:

```text
tournament_batting_leaderboard
tournament_bowling_leaderboard
tournament_live_board
search_grounds
```

because they are predominantly query/aggregation operations.

---

# 12.14 What should move away from public workflow RPCs

Today many Tournament mutations are implemented as:

```text
public.approve_tournament_registration()
public.reject_tournament_registration()
public.tournament_record_payment()
...
```

with:

```text
SECURITY DEFINER
```

and manual authorization inside each function.

They do check authentication/organizer status, so they are not inherently unsafe.

But long-term I would prefer workflow behavior to live behind our NestJS command boundary.

Supabase currently recommends `SECURITY INVOKER` by default for database functions, and warns that `SECURITY DEFINER` functions run with the creator's privileges and need careful exposure/security handling. :chatgpt-content-reference{index="2"}

So:

```text
public SECURITY DEFINER workflow RPC
```

should become the exception rather than the default architecture.

---

# 12.15 Read RPC versus Command RPC

Useful distinction:

```text
READ RPC
```

Example:

```text
tournament_live_board()
```

Fine.

---

```text
MUTATION RPC
```

Example:

```text
approve_tournament_registration()
```

might remain temporarily during migration.

But canonical architecture should become:

```text
Flutter
↓
NestJS Tournament HTTP API
↓
Application Command
↓
withCommandTransaction
↓
PostgreSQL
```

rather than having business behavior split unpredictably between TypeScript and PL/pgSQL.

---

# 12.16 Command envelope

I recommend every Tournament command eventually follows a common request format conceptually:

```text
commandId
action

tournamentId?
registrationId?
entryId?
stageId?
fixtureId?

expectedRevision?

payload
```

For example:

```text
action = publish_draw

stageId = ...
commandId = ...

expectedRevision = 7

payload:
    drawPlan...
```

The authenticated user ID should **never** come from the payload.

Your existing Cricket function correctly derives the actor from the authenticated request.

Keep that.

---

# 12.17 `commandId`

Every important command should have a client-generated unique ID.

Example:

```text
command_id = e8b1...
```

The purpose:

```text
mobile sends request
server commits
network response is lost
mobile retries
```

Server recognizes:

```text
I've already executed command e8b1.
```

and returns the same result.

No duplicate:

```text
registration
payment
walkover
notifications
progression
```

This gives us true command idempotency.

---

# 12.18 `expectedRevision`

For concurrency-sensitive entities:

```text
expectedRevision
```

should also be supplied.

Example:

```text
Fixture revision = 12
```

Manager opens it.

Another manager reschedules it:

```text
revision = 13
```

First manager sends:

```text
expectedRevision = 12
```

Server responds:

```text
STALE_REVISION
```

rather than overwriting newer state.

This applies especially to:

```text
Tournament
Entry Set
Draw
Fixture
Match
Standings finalization
```

---

# 12.19 Standard command transaction

Every meaningful command should conceptually follow this order:

```text
1. Authenticate request

2. Parse + validate command shape

3. BEGIN

4. Attach authenticated actor context

5. Lock aggregate root(s)

6. Authorize capability

7. Validate lifecycle/state

8. Validate domain invariants

9. Check expected revision

10. Check idempotency

11. Apply mutation

12. Recompute synchronous projections
    where competition correctness requires it

13. Record audit event

14. Record domain/outbox events

15. Load canonical result snapshot

16. COMMIT

17. Publish realtime / notifications asynchronously

18. Return canonical result
```

That's essentially the strong part of your existing Cricket architecture generalized to Tournament.

---

# 12.20 Authentication happens before transaction

Your current:

```text
cricket-match-action/index.ts
```

does:

```text
authenticate request
↓
parse envelope
↓
begin transaction
```

Good.

We should use the same Tournament pattern.

Invalid/unauthenticated requests should not even acquire competition row locks.

---

# 12.21 Row locking

Once we're inside a domain-changing command, lock the authoritative root before evaluating its state.

For example:

```text
ApproveRegistration
```

locks:

```text
Registration
Tournament
```

as appropriate.

Then two managers cannot simultaneously perform inconsistent state transitions.

---

# 12.22 Authorization comes after loading authoritative state

Do not trust:

```text
tournamentId sent by client
```

alone.

If command is:

```text
ApproveRegistration(registrationId)
```

then:

```text
registration
   ↓
authoritative tournament_id
```

should determine authorization scope.

Otherwise a malicious client can send:

```text
registration_id from Tournament B
+
tournament_id from Tournament A
```

where they are manager of A.

Always derive parent relationships from server data.

---

# 12.23 Capability check then lifecycle check

From Step 5:

```text
AUTHORIZED
=
capability
+
domain guard
```

So:

```text
Tournament Manager
has draw.publish
```

but:

```text
entries = unlocked
```

means:

```text
PublishDraw
→ INVALID_STATE
```

Not:

```text
FORBIDDEN
```

Those are different errors.

That distinction will make Flutter UX much better.

---

# 12.24 Standard command errors

I would establish stable error codes such as:

```text
UNAUTHENTICATED
FORBIDDEN
NOT_FOUND

VALIDATION_ERROR
INVALID_STATE

CONFLICT
STALE_REVISION

CAPACITY_REACHED
ENTRY_NOT_READY
DRAW_STALE

DEPENDENT_FIXTURE_STARTED

IDEMPOTENCY_CONFLICT
```

Flutter should react to codes rather than parsing text such as:

```text
"Only tournament organizers can..."
```

Human messages can evolve.

Machine semantics should stay stable.

---

# 12.25 Command responses

A successful response should usually return:

```text
ok
result
revision
canonical snapshot
```

instead of only:

```text
void
```

For example:

```text
ApproveRegistration
```

returns:

```text
registration
tournamentEntry
entryCount
revision
```

Then Flutter doesn't need:

```text
command succeeded
↓
wait
↓
query 4 tables
```

just to understand what happened.

Realtime can still reconcile other screens.

---

# 12.26 Tournament Root commands

The Tournament aggregate command set should eventually include:

```text
CreateTournament
UpdateDraftTournament

PublishTournament

OpenRegistration
CloseRegistration
ReopenRegistration

LockEntries
UnlockEntries

CancelTournament
AbandonTournament

TransferTournamentOwnership

AddTournamentManager
RemoveTournamentManager
```

Notice:

```text
SetTournamentStatus
```

does **not** exist.

That's deliberate.

---

# 12.27 Registration and Entry commands

Canonical:

```text
SubmitRegistration
WithdrawPendingRegistration

ApproveRegistration
RejectRegistration

WithdrawTournamentEntry
DisqualifyTournamentEntry
ReplaceTournamentEntry

SubmitTournamentSquad
FreezeTournamentSquad
RequestSquadAmendment
ApproveSquadAmendment

RecordEntryPayment
VoidEntryPayment
```

Again:

```text
UpdateTournamentTeamRow
```

does not exist.

---

# 12.28 Stage/Draw commands

Canonical:

```text
CreateStage
UpdateStage
DeleteDraftStage

AssignStageEntries

GenerateDrawDraft
UpdateDrawDraft

PublishDraw
RevisePublishedDraw

AssignSeed
AssignGroups

FinalizeStageStandings
ActivateNextStage
```

Some may eventually be internal application operations rather than Flutter-callable commands.

For example:

```text
ActivateNextStage
```

will normally happen automatically.

That's fine.

A command model includes internal commands too.

---

# 12.29 Fixture operations

Canonical:

```text
ScheduleFixture
RescheduleFixture
MoveFixtureVenue

AssignScorer
RemoveScorer
AssignOfficial
RemoveOfficial

DeclareWalkover
OrderReplay

VoidFixture
```

Not all fixture operations should necessarily be exposed to every tournament role.

Capability rules from Step 5 apply.

---

# 12.30 Cricket operations remain Cricket commands

These stay in:

```text
cricket-match-action
```

such as:

```text
RecordToss
SubmitPlayingXI
SubmitOpeners

StartCricketMatch
StartInnings

RecordBall
UndoBall

ReviseCricketConditions
StartSuperOver

CompleteCricketMatch
```

Tournament Core should not understand their internal rules.

---

# 12.31 The hardest transaction: completing a tournament match

This is the most important Step-12 transaction.

Imagine Cricket finalizes:

```text
QF1
Lahore defeats Kasur
```

The system needs:

```text
Cricket sporting result
      ↓
Fixture competition outcome
      ↓
standing effects if relevant
      ↓
resolve downstream slot
      ↓
potential stage completion
      ↓
potential next stage activation
      ↓
potential tournament completion
```

These are competition-critical changes.

I would **not** make that:

```text
Cricket transaction commits
↓
later another HTTP request updates Tournament
```

because the second request could fail.

---

# 12.32 Finalization should be one transaction

For a tournament-linked Cricket Match:

```text
BEGIN
```

First:

```text
Cricket Match Engine
finalizes sporting result
```

Then, still inside the same transaction:

```text
Tournament Competition Coordinator

resolve FixtureOutcome
recalculate affected standings
resolve slot sources
activate dependent fixture
check stage completion
check tournament completion
write outbox
```

Then:

```text
COMMIT
```

This preserves strong competition consistency.

---

# 12.33 How do we achieve that with NestJS?

> **HISTORICAL NOTE — superseded before Phase 5 implementation.**
> This section originally addressed how to achieve atomic finalization within Supabase Edge Functions without NestJS. The atomic finalization problem it describes remains valid; the actual cross-subsystem coordination architecture is deferred to Phase 8 / Phase 10.

Through shared domain logic and coordinated transactions.

For example:
- Cricket match finalization completes the sporting result in `cricket-match-action`.
- Tournament progression (standings, bracket advancement, qualification) must coordinate atomically.
- Cross-boundary synchronous HTTP calls between Edge Functions and NestJS are forbidden.

---

# 12.34 Don't call NestJS HTTP synchronously from `cricket-match-action`

That would produce:

```text
Transaction A
  completes Cricket

HTTP call

Transaction B
  updates tournament
```

which loses atomicity.

Cross-subsystem coordination between Cricket match completion and Tournament progression must not rely on uncoordinated synchronous HTTP calls between Edge Functions and NestJS. Atomic finalization and progression coordination is deferred to Phase 8 / Phase 10.

---

# 12.35 Current `advanceWinner()` is a prototype of this idea

Today your:

```text
MatchTeamRepository.advanceWinner()
```

does:

```text
completed source match
↓
find matches whose prev_match_* references it
↓
set downstream match team
```

and importantly refuses to change a downstream match after it has started.

That is a good invariant.

But after Step 11, this behavior belongs conceptually to:

```text
TournamentCompetitionCoordinator
```

using:

```text
Fixture
FixtureSlot
FixtureOutcome
```

not:

```text
MatchTeamRepository
```

using:

```text
prev_match_a_id
prev_match_b_id
```

So the current logic is valuable, but its boundary will move.

---

# 12.36 Current result override shows the same coupling

Today:

```text
tournament_override_result.ts
```

does:

```text
update Cricket result
update Match
advanceWinner()
```

all together.

The atomic transaction idea is correct.

But long-term:

```text
Tournament Result Override
```

should not rewrite the Cricket sporting result as though it were sport truth.

From Step 8:

```text
Sporting Result
≠
Competition Outcome
```

So future flow:

```text
OverrideCompetitionOutcome
```

operates on:

```text
FixtureOutcome
```

and only updates Cricket result if the sport scorecard itself is genuinely being corrected.

That's an important distinction.

---

# 12.37 ApproveRegistration transaction

Canonical:

```text
ApproveRegistration
```

should do something like:

```text
BEGIN

lock Registration
lock Tournament

authorize:
  tournament.registration.review

validate:
  Registration = pending
  Tournament accepts decisions
  capacity available
  team still eligible

update:
  Registration = approved

create:
  TournamentEntry = active

write:
  audit

emit:
  TournamentEntryActivated

COMMIT
```

Then after commit:

```text
notification handler
chat membership projector
realtime
```

Communication failure cannot undo approval.

---

# 12.38 PublishTournament transaction

Canonical:

```text
PublishTournament
```

does:

```text
BEGIN

lock Tournament

authorize tournament.publish

validate:
  draft
  name valid
  sport valid
  public fields valid
  dates coherent
  structure minimally coherent

publication_state = published
published_at = now

audit
outbox TournamentPublished

COMMIT
```

Notice:

```text
registration_state
```

doesn't automatically become `open`.

That requires:

```text
OpenRegistration
```

unless explicit creation settings define an immediate automatic transition.

---

# 12.39 LockEntries transaction

```text
BEGIN

lock Tournament
lock active Entries

authorize tournament.entries.lock

validate:
  registration closed
  minimum participants satisfied
  required applications resolved
  mandatory payment/squad conditions met

entry_state = locked
entry_revision += 1

audit
outbox EntriesLocked

COMMIT
```

Now any DrawPlan generated afterward can reference:

```text
entry_revision
```

and detect stale plans.

---

# 12.40 PublishDraw transaction

This should be one of the strongest commands.

```text
BEGIN

lock Tournament
lock Stage
lock entry set / revision
lock current draw state

authorize tournament.draw.publish

validate:
  entries locked
  expected entry revision
  draw not stale
  stage structure valid
  no cycles
  sources valid
  seeds unique
  participant placement valid

create DrawRevision

create/update:
  Rounds
  Fixtures
  FixtureSlots

set published revision

audit
outbox DrawPublished

COMMIT
```

Nothing partial.

---

# 12.41 RescheduleFixture transaction

```text
BEGIN

lock Fixture

authorize tournament.fixture.reschedule

validate:
  Fixture not started
  Tournament operational
  venue available
  teams not conflicting
  scorer not conflicting
  officials not conflicting

update schedule
revision++

audit
outbox FixtureRescheduled

COMMIT
```

After commit:

```text
new reminders
push notifications
chat system card
```

---

# 12.42 DeclareWalkover transaction

```text
BEGIN

lock Fixture
lock active Match if any
lock downstream dependent FixtureSlots

authorize appropriate capability

validate:
  Fixture unresolved
  winner is participant
  dependent execution constraints

create FixtureOutcome:
  administrative / walkover

apply sport standing effect
resolve downstream slots
check stage completion

audit
outbox WalkoverDeclared

COMMIT
```

No fake score.

---

# 12.43 Result correction transaction

For an unstarted downstream dependency:

```text
BEGIN

lock source Fixture
lock dependent graph

authorize result override

validate reason
validate correction

calculate impact

if downstream execution started:
    reject normal correction
    → DEPENDENT_FIXTURE_STARTED

otherwise:

record corrected outcome
recompute standings
re-resolve downstream slots

audit
outbox ResultCorrected

COMMIT
```

This is why generic `UPDATE winner_id` is unacceptable.

---

# 12.44 Realtime publishing after commit

Your current Cricket Edge Function already does this correctly:

```text
transaction commits
↓
publish snapshot
```

Keep that pattern.

Realtime is delivery.

Not transaction truth.

Supabase Edge Functions are suitable for this sort of authenticated server-side coordination, but their current guidance also emphasizes designing them as short-lived/idempotent operations and treating database connectivity appropriately for edge/serverless environments. :chatgpt-content-reference{index="3"}

---

# 12.45 Notifications should not run inside the competition transaction

Bad:

```text
BEGIN

approve registration

call FCM
wait for push
chat insert
send email

COMMIT
```

If FCM hangs:

```text
Registration locked for no good reason
```

Instead:

```text
BEGIN

approve registration
write outbox

COMMIT
```

then:

```text
worker/function
↓
push/chat/feed
```

Step 10 again.

---

# 12.46 Audit is different

The audit record describing the business mutation **should** generally be in the same transaction.

Because:

```text
Result override committed
```

without:

```text
who/why
```

is unacceptable.

So:

```text
mutation
+
audit record
```

should succeed/fail together for privileged operations.

---

# 12.47 Outbox belongs in the same transaction too

If:

```text
TournamentPublished
```

commits but the outbox event doesn't, integrations may never know about it.

Therefore:

```text
state transition
+
outbox event
```

should be atomic.

Then after commit, processing may retry safely.

---

# 12.48 RLS remains essential

For Flutter directly accessing the Supabase Data API, RLS remains the security boundary. Supabase's current documentation recommends enabling RLS and controlling both table grants and row policies for exposed tables. :chatgpt-content-reference{index="4"}

So:

```text
READS
```

still need RLS.

Any permitted simple direct writes also need RLS.

---

# 12.49 But Edge Function authorization cannot just say “RLS will handle it”

Your current Cricket Edge Function uses a direct PostgreSQL transaction connection and explicitly injects verified actor context.

That's good.

When a trusted server connection has elevated database privileges, you must not assume RLS alone will enforce user-level business authorization.

Each command handler should explicitly perform:

```text
requireCapability(...)
```

based on the verified authenticated actor.

Supabase's own documentation notes that server-side/admin access can bypass RLS, which is exactly why explicit authorization matters on privileged server paths. :chatgpt-content-reference{index="5"}

---

# 12.50 Flutter's responsibility

Flutter should handle:

```text
render state
collect input
perform client-side validation for UX
call typed command
handle command errors
refresh/reconcile canonical state
```

It should not decide:

```text
Can tournament move from registration to upcoming?
Who qualifies?
Can this result be overridden?
Which team advances?
How should points change?
```

Those are server domain rules.

---

# 12.51 Flutter capability checks remain UX only

Example:

```text
canPublishDraw = false
```

so Flutter hides the button.

Good.

But:

```text
PublishDraw
```

still rechecks server-side.

Never:

```text
button hidden
= security
```

---

# 12.52 Repository cleanup after Step 12

Today:

```text
TournamentsRemoteDataSource
```

handles almost everything.

Eventually I would split its conceptual responsibilities.

For example:

```text
TournamentQueriesDataSource
```

for:

```text
getTournament
getFixtures
getStandings
getLiveBoard
leaderboards
```

and:

```text
TournamentCommandDataSource
```

for:

```text
call NestJS Tournament HTTP API
```

That alone would make the client architecture much easier to reason about.

Then domain repositories can expose meaningful methods.

---

# 12.53 Typed command client

Rather than Flutter repeatedly doing:

```dart
// HTTP POST to NestJS Tournament API
await _httpClient.post(
  '/tournaments/commands',
  body: {
    'commandId': commandId,
    'action': '...',
    ...
  },
);
```

all over the project, create one reusable command client:

```text
TournamentCommandClient
```

responsible for:

```text
invoke
auth/network error mapping
command envelope
commandId
expectedRevision
response parsing
```

Then repositories call that.

Exactly as `_matchAction()` has started doing for Cricket/Tournament match operations.

---

# 12.54 Current architecture classification

Based on the current repo and live Supabase system, I would classify the existing mutation paths like this:

| Current behavior | Step-12 direction |
|---|---|
| Direct draft reads | Keep |
| Direct public/read queries | Keep with RLS |
| `createTournament` direct insert + grounds call | Move to command |
| `publishTournament` raw status update | Replace with command |
| `registerTeam` direct insert | Move to command |
| approve/reject RPC | Eventually command handler |
| withdraw raw update | Replace with explicit registration/entry command |
| group assignment raw updates | Move to stage/group command |
| draw generation RPC | Good atomic pattern; evolve behind `PublishDraw` command |
| payment RPC | Can migrate to command |
| officials RPC | Command boundary |
| `cricket-match-action` | Keep |
| Tournament reschedule/walkover inside Cricket router | Move to Tournament command domain |
| revised target/Super Over | Keep Cricket-side |
| `advanceWinner()` in match repository | Move to Tournament progression coordinator |
| Realtime after Cricket commit | Keep |
| direct chat DB triggers | Eventually replace with outbox/integration consumer |

This is the first point where our target architecture is becoming very concrete.

---

# 12.55 Canonical current deployment architecture

> **UPDATED (Phase 5, 2026-10-02)** — replaces the historical "no NestJS" diagram below.

The actual implemented architecture:

```text
                    FLUTTER
                       │
          ┌────────────┴────────────┐
          │                         │
       QUERIES                   COMMANDS
          │                         │
          ▼                         ▼
    PostgREST / Views       NestJS Tournament HTTP API
    Read RPCs               ┌──────────────────────────┐
    Realtime                │ TournamentCommandExecutor│
                            │ withCommandTransaction   │
                            └──────────┬───────────────┘
                                       │
                                       │ (trusted role, JWT claims injected)
                                       ▼
                               ┌───────────────┐
                               │ cricket-match │  ← Sport commands only
                               │ -action (EF)  │
                               └───────┬───────┘
                                       │
                                       ▼
                                  PostgreSQL
                         ┌──────────────────────────┐
                         │ constraints              │
                         │ FK / UNIQUE / CHECK      │
                         │ advisory locks           │
                         │ RLS                      │
                         │ public.can() helper      │
                         │ private.tournament_      │
                         │   command_receipts       │
                         │ projections/read SQL     │
                         └──────────┬───────────────┘
                                    │
                               COMMITTED EVENT
                                    │
                     ┌──────────────┼──────────────┐
                     ▼              ▼              ▼
                  Realtime     Notification       Chat
                                / Outbox          / Feed
```

This is enough infrastructure for a serious Tournament platform.

---

# Step-12 standard to freeze

> **UPDATED (Phase 5, 2026-10-02)** — Items 1, 4, 8, 10, 11, 12, 13, 14, 16, 18, and 22 have been revised to reflect the NestJS command authority that was implemented in Phase 5. All other items remain valid.

1. **Current Matchday Tournament write architecture is NestJS + PostgreSQL (Supabase).** Tournament mutations go through the NestJS `TournamentCommandExecutor`, which executes under a trusted database role with transaction-local JWT claim injection. No `tournament-action` Supabase Edge Function exists or will be created.
2. **Reads and commands are separate concerns.**
3. **Complex Tournament mutations go through an explicit server command boundary.**
4. **The NestJS Tournament HTTP API is the Tournament command authority**, equivalent to how `cricket-match-action` is the Sport Match command authority. Cricket sport commands remain separated from Tournament competition commands.
5. **Cricket sport commands remain separated from Tournament competition commands.**
6. **Direct PostgREST mutations are only appropriate for genuinely simple non-lifecycle operations protected by correct RLS/invariants.**
7. **Lifecycle, authority, entry, structure, fixture, progression and result mutations require commands.**
8. **PostgreSQL owns persistence integrity; NestJS command handlers own domain behavior/orchestration.**
9. **Database functions/RPCs remain appropriate for database-local queries, aggregations and specialized primitives, but should not become a second competing workflow layer.**
10. **Every command derives actor identity from authenticated server context (verified JWT claims injected transaction-locally), never from the request payload.**
11. **Commands support idempotency via `commandId` backed by `private.tournament_command_receipts`.**
12. **Concurrency-sensitive commands support expected revisions (`tournaments.revision`, `tournaments.entry_revision`).**
13. **The server acquires a transaction-scoped advisory lock (`pg_advisory_xact_lock`) before applying critical transitions.**
14. **Capability authorization (`public.can()`) and lifecycle/domain validation are separate steps.**
15. **Stable error codes replace UI parsing of exception messages.**
16. **Successful commands return a canonical JSON-domain result that is identical on first execution and idempotent replay.**
17. **Tournament match result finalization and required Tournament progression should occur atomically in the same PostgreSQL transaction.**
18. **`cricket-match-action` must NOT issue uncoordinated HTTP calls to NestJS for tournament progression.** Cross-subsystem atomicity between cricket match finalization and tournament progression is explicitly deferred to Phase 8 / 10.
19. **Fixture outcome/progression replaces direct `prev_match_*` manipulation as the canonical future model.**
20. **Audit records and outbox events are written transactionally with important mutations.**
21. **Realtime, notifications, chat and feed processing happen after commit and can retry independently.**
22. **RLS remains mandatory for Data API access; NestJS command paths must also explicitly authorize the authenticated actor via `public.can('tournament', id, permission)`.**
23. **Flutter handles UX and typed command invocation; business transitions remain server-owned.**
24. **Client repository architecture should eventually separate read/query access from command invocation.**

The next logical **Step 13 is Read Models, Realtime & Client State Architecture**. That would define exactly what Flutter should query/watch for the Tournament Detail page, Organizer Console, Registration inbox, Fixture list, Bracket, Standings, Live Ops and participant dashboard; which data should come from views/read RPCs versus tables; how Realtime invalidates Riverpod state; and how we avoid turning the new normalized domain model into 20 client round-trips.




Yes. Step 13 is where we make sure the clean normalized architecture from Steps 1–12 does **not** make the Flutter app slower, harder to maintain, or dependent on dozens of queries.

The central rule should be:

> **Write models follow domain boundaries. Read models follow user screens.**

Those are intentionally different.

```text
WRITE SIDE
Tournament
Entry
Stage
Fixture
Match
Standing projection
...

READ SIDE
Tournament Detail Screen
Organizer Console
Bracket Screen
Registration Inbox
My Tournament Dashboard
Live Ops Board
```

Flutter should not reconstruct the normalized domain graph one table at a time.

# Step 13 — Read Models, Realtime & Flutter State Architecture

## 13.1 The normalized database is not the Flutter API

After Step 11, we may have:

```text
tournaments
tournament_memberships
tournament_registrations
tournament_entries
tournament_squad_members
tournament_stages
tournament_stage_entries
tournament_groups
tournament_rounds
tournament_fixtures
tournament_fixture_slots
tournament_fixture_matches
tournament_stage_standings
cricket_stage_standing_metrics
...
```

Flutter should **not** do this:

```text
GET tournament
GET stages
GET groups
GET rounds
GET entries
GET teams
GET fixtures
GET slots
GET matches
GET standings
GET cricket metrics
...
```

just to display one screen.

That would technically be normalized and architecturally terrible for a mobile client.

Instead:

```text
Normalized write model
        ↓
Database read projection
        ↓
Flutter-specific Read Model
```

---

# 13.2 Read models are not domain entities

This is another distinction I want to freeze.

Today Flutter frequently uses entities such as:

```text
Tournament
TournamentRegistration
TournamentStanding
Match
```

directly as screen data.

That works when the feature is small.

As the model gets richer, the screen should consume something like:

```text
TournamentDetailReadModel
```

containing exactly what the screen needs.

For example:

```text
TournamentDetailReadModel
├── tournament summary
├── current public phase
├── sport
├── stage summaries
├── participating entry count
├── next/live fixture summary
├── viewer relationship
├── available tabs/sections
└── public capabilities/status
```

That is not an aggregate.

It is a projection.

---

# 13.3 CQRS-lite, not CQRS infrastructure

I am **not** proposing Kafka, event stores, separate databases, or a heavyweight CQRS framework.

We only need this idea:

```text
COMMAND MODEL
optimized for correctness

READ MODEL
optimized for screens
```

Both can remain inside the same Supabase PostgreSQL database.

That is enough.

---

# 13.4 Three ways to expose read models

For Matchday, I would use three mechanisms.

| Mechanism | Best use |
|---|---|
| `security_invoker` View | Stable row-shaped read projection |
| Read RPC/function | Complex/parameterized composite read |
| Direct table read | Simple resource where table already matches screen need |

This is much better than one rule such as:

> Everything must be a view.

or:

> Flutter should query every table directly.

---

# 13.5 Views

Views are ideal for reusable relational projections.

For example:

```text
public.tournament_public_summary
```

could join:

```text
Tournament
Sport
Owner profile
Entry count
Lifecycle projection
```

into one row per tournament.

Then discovery and tournament headers use the same definition.

Supabase's current documentation explicitly recommends `security_invoker=true` when a view should respect the querying user's permissions and the RLS policies of its underlying tables. :chatgpt-content-reference{index="0"}

You are already doing this correctly with:

```text
cricket_match_details
security_invoker = true
```

I checked the live database.

That pattern should be retained.

---

# 13.6 Read RPCs

A read RPC is better when the response is:

```text
parameterized
hierarchical
computed
viewer-specific
or joins many unrelated projections
```

The Organizer Console is a perfect example.

Instead of Flutter executing:

```text
Tournament
Registrations
Entries
Payments
Fixtures
Missing scorers
Live matches
Ground conflicts
Squad readiness
```

separately, it could call:

```text
get_tournament_organizer_console(tournament_id)
```

and receive one structured snapshot.

Not the entire tournament database.

Only the operational information required by that screen.

---

# 13.7 Don't create one gigantic Tournament JSON endpoint either

The opposite extreme is also wrong.

I would **not** create:

```text
get_everything_about_tournament()
```

returning 3 MB of:

```text
all matches
all players
all deliveries
all stats
all registrations
all payments
all chat
all audit events
```

every time someone opens the Tournament page.

Instead, use:

```text
SHELL
+
LAZY TAB READ MODELS
```

---

# 13.8 Tournament Detail Shell

When the public Tournament Detail route opens, fetch one small shell.

Conceptually:

```text
TournamentDetailShell

Tournament identity
Public phase
Sport
Dates
Location
Branding

Stage summaries

Current live/highlight fixture
Entry/team count

Viewer state
    following?
    participant?
    organizer?
```

And perhaps:

```text
available_sections
```

such as:

```text
Overview
Fixtures
Groups
Standings
Bracket
Teams
Stats
```

Then load expensive tabs only when needed.

---

# 13.9 Stage structure should determine the tabs

This exposes an important current issue.

Your current `TournamentDetailScreen` does:

```dart
final isKnockout =
    tournament.type == TournamentType.knockout;

final isHybrid =
    tournament.type == TournamentType.groupKnockout;
```

and builds completely different tab arrays from the old tournament type.

After Step 2 that is no longer canonical.

The UI should instead read:

```text
Stage 1
round_robin
groups = true

Stage 2
single_elimination
```

and decide:

```text
Overview
Groups
Playoffs
Stats
```

from the actual structure.

Not:

```text
type == group_knockout
```

This is a concrete later refactor.

---

# 13.10 The client currently contains competition logic

There is an even more important current problem in `tournament_detail_screen.dart`.

Right now `_cutRankFor()` decides:

```text
league with >= 6 teams
→ top 4

otherwise
→ top 2

group knockout
→ top 2
```

Then Flutter displays:

```text
Top 2 advance to semi-finals
```

or:

```text
Top 4 advance to semi-finals
```

That violates Steps 7 and 9.

Flutter has effectively invented a qualification policy.

Qualification must come from:

```text
Stage configuration
        ↓
Tournament Core
```

So the read model should contain:

```text
qualificationSummary:
    qualifyingPositions: 2
    label: "Top 2 advance"
```

or a structured equivalent.

Flutter renders it.

Flutter never guesses it.

---

# 13.11 Public screen read models

I would eventually have roughly these read surfaces:

| Screen/tab | Read model |
|---|---|
| Tournament route/header | `TournamentDetailShell` |
| Overview | `TournamentOverviewReadModel` |
| Teams | `TournamentEntriesReadModel` |
| Fixtures | `TournamentFixturesReadModel` |
| Group | `TournamentGroupReadModel` |
| Standings | `StageStandingsReadModel` |
| Bracket | `TournamentBracketReadModel` |
| Stats | Sport-specific statistics projection |
| Awards | `TournamentAwardsReadModel` |

This does **not** mean nine requests immediately.

Some cheap models can be bundled into the shell.

But they should remain conceptually separate.

---

# 13.12 Bracket should have its own read projection

The Bracket widget should not reconstruct graph relationships from raw matches.

Canonical read:

```text
TournamentBracketReadModel
```

might contain:

```text
Stage
Rounds
Fixtures
    slot A display
    slot B display
    source labels
    resolved entry
    status
    result
```

For unresolved slots:

```text
Winner QF1
```

is already returned by the server projection.

Flutter does not inspect:

```text
prev_match_a_id
```

and invent the label.

---

# 13.13 Standings read model

Step 9 gives us something like:

```text
StageStandingsReadModel

stage
group?

finality:
    provisional / final

qualification rule summary

rows:
    rank
    entry
    display metrics
    qualification state
    deciding tie-break reason?
```

For Cricket, a row might expose:

```text
P
W
L
T
NR
PTS
NRR
```

Football later gets different metrics.

Flutter's generic standings widget renders the supplied column definition.

It should no longer know:

```text
netRunRate
```

as a universal tournament field.

---

# 13.14 Form and next match are also projections

Your current tournament page calculates team form from the Live Ops board:

```dart
W
L
T
N
```

and then searches the board to find the next opponent.

This is display logic, not dangerous domain logic, but it forces the Standings tab to load the whole Live Ops board.

A better standings read model can include:

```text
recent_form
next_fixture_summary
```

if we want those columns.

Then:

```text
Standings screen
```

does not depend on:

```text
Organizer Live Ops model
```

Public presentation and organizer operations stay separate.

---

# 13.15 Organizer Console should be one high-value composite read model

This is where we should aggressively prevent N+1 queries.

Conceptually:

```text
OrganizerConsoleReadModel

Tournament
    phase
    readiness

Registration
    pending count
    unresolved blockers

Entries
    confirmed count
    squad readiness
    payment readiness

Draw
    state
    revision
    warnings

Fixtures
    total
    scheduled
    live
    completed
    unresolved

Staffing
    missing scorers
    missing officials

Live Ops
    active fixtures
    stale scoring warnings
    venue conflicts

Actionable Alerts
```

The organizer should get this from one server-side read operation.

Then drill-down screens fetch detailed rows only when opened.

---

# 13.16 Registration Inbox

The organizer's registration screen should query a registration-specific model.

Not the entire Entry/Payment/Stage model.

Something like:

```text
TournamentRegistrationInbox

pending:
    team
    submitted_by
    submitted_at
    message
    squad summary

processed:
    status
    decision
```

Approved participants belong primarily to the Entry screens after approval.

This follows Step 6.

---

# 13.17 Participant dashboard

A team manager should not need to navigate the organizer/public data graph just to understand their obligations.

A useful read model is:

```text
MyTournamentParticipation

Tournament
Entry status

Payment status
Squad status

Next fixture
Ground
Start time

Lineup deadline

Recent result
Qualification status
```

That can power something like:

```text
My Tournaments → Playing
```

very efficiently.

---

# 13.18 Viewer capabilities should be returned once

Today UI often derives role relationships independently.

Long-term the Tournament shell should include something like:

```text
viewerContext

relationship:
    spectator
    follower
    team_participant
    manager
    owner

capabilities:
    tournament.edit
    registration.review
    draw.publish
    fixture.reschedule
    match.score
    ...
```

Then Flutter can render actions without making a database call for every button.

But remember Step 5:

> Client capability data is UX, not security.

The command still reauthorizes server-side.

---

# 13.19 Permission changes invalidate viewer context

Suppose Saran removes Ali as Tournament Manager.

Ali's current shell may still say:

```text
draw.publish = true
```

for a moment.

That is acceptable for UI caching because:

```text
PublishDraw
```

will still fail server-side.

But we should broadcast:

```text
tournament_access_changed
```

so Ali's viewer context refetches quickly.

---

# 13.20 Realtime should notify that truth changed

I do **not** want Flutter maintaining the entire Tournament graph by replaying arbitrary database row changes.

For tournament-level UI, the better model is:

```text
Server commits authoritative state
          ↓
Realtime event:
"fixtures changed"
          ↓
Flutter invalidates fixture read model
          ↓
refetch canonical projection
```

rather than:

```text
UPDATE tournament_fixture_slots
      ↓
Flutter locally mutates bracket
      ↓
UPDATE standings
      ↓
Flutter locally recalculates table
      ↓
...
```

That recreates server domain logic on the phone.

---

# 13.21 Broadcast should become the default tournament invalidation mechanism

Supabase currently describes two database-change approaches: Broadcast and Postgres Changes, and now recommends Broadcast for most use cases because it scales better; Postgres Changes remains simpler but does not scale as well. :chatgpt-content-reference{index="1"}

That fits Matchday very well.

Tournament state changes are generally:

```text
low-frequency
high-value
multi-row
semantic
```

Exactly where a domain event is better than listening to ten raw tables.

---

# 13.22 Tournament Realtime event

A public event can be tiny.

For example:

```json
{
  "event_id": "...",
  "event_type": "fixture.rescheduled",
  "tournament_id": "...",
  "entity_id": "...",
  "revision": 42,
  "areas": [
    "overview",
    "fixtures",
    "live_ops"
  ]
}
```

Notice what is **not** included:

```text
all fixture rows
all tournament state
all private organizer data
```

It's an invalidation/event hint.

Canonical data comes from the read API.

---

# 13.23 Use semantic events, not table names

Bad:

```text
tournament_fixtures row UPDATE
```

Better:

```text
FixtureRescheduled
```

Bad:

```text
tournament_stage_standings UPDATE
```

Better:

```text
StandingsChanged
```

The client should know product semantics.

It should not be coupled to physical database table names.

That will make future schema refactors far less painful.

---

# 13.24 Public and organizer realtime should be separate

Because their data sensitivity differs, I would conceptually separate topics:

```text
tournament:<id>:public
```

for things like:

```text
fixture changed
result finalized
standings changed
draw published
stage completed
```

and:

```text
tournament:<id>:ops
```

for organizer-only events such as:

```text
registration submitted
payment updated
missing scorer alert
squad amendment request
internal result review
```

Then:

```text
match:<matchId>
```

remains the high-frequency sporting channel.

This is much safer than broadcasting organizer operational information into one public channel.

---

# 13.25 Do not send every Cricket delivery to the Tournament channel

Important scaling rule.

```text
Ball recorded
```

should go to:

```text
match:<id>
```

or the Match realtime architecture.

The Tournament page may render a live score card from a match-specific live projection.

But:

```text
tournament:<id>
```

does not need:

```text
ball 1
ball 2
ball 3
ball 4
...
```

That would turn one tournament channel into an unnecessary high-frequency firehose.

---

# 13.26 Tournament event frequency

Tournament Broadcast should carry events such as:

```text
MatchStarted
MatchCompleted
FixtureRescheduled
StandingsChanged
QualifierResolved
DrawPublished
```

not every low-level sport event.

That keeps tournament detail pages cheap.

---

# 13.27 One Realtime coordinator per tournament route

This is where Riverpod comes in.

I do **not** want:

```text
Overview tab
→ WebSocket

Fixtures tab
→ WebSocket

Standings tab
→ WebSocket

Bracket tab
→ WebSocket

Stats tab
→ WebSocket
```

all subscribing independently.

Instead:

```text
TournamentRealtimeCoordinator(tournamentId)
```

owns one public Tournament subscription while that Tournament route is alive.

It receives:

```text
event.areas
```

and centrally invalidates the appropriate read models.

---

# 13.28 Central invalidation map

Conceptually:

| Event | Refresh |
|---|---|
| TournamentPublished | shell, overview |
| RegistrationChanged | entries, organizer console |
| DrawPublished | shell, fixtures, bracket |
| FixtureRescheduled | fixtures, overview, live ops |
| MatchStarted | fixtures, overview, live ops |
| MatchCompleted | fixtures, standings, bracket, stats |
| StandingsChanged | standings |
| QualificationResolved | standings, bracket |
| ScorerAssigned | live ops |
| AwardsPublished | awards, overview |

This mapping should exist **once**.

Not be repeated across every command handler.

---

# 13.29 This directly fixes the current manual invalidation problem

Today `TournamentsController` does things like:

```dart
ref.invalidate(
  tournamentDetailProvider(tournamentId),
);

ref.invalidate(
  tournamentFixturesProvider(tournamentId),
);

ref.invalidate(
  tournamentLiveBoardProvider(tournamentId),
);

ref.invalidate(
  myTournamentsProvider,
);
```

Different operations have different manually maintained combinations.

This becomes fragile as the feature grows.

Imagine later:

```text
PublishDraw
```

also affects:

```text
bracketProvider
stageProvider
participantDashboardProvider
```

and someone forgets to invalidate one.

Now two tabs disagree.

The better model is:

```text
Command commits
↓
DrawPublished event
↓
central event → read-model invalidation mapping
```

---

# 13.30 Immediate command UX still shouldn't wait for Realtime

However, we should not make the user wait for their own Broadcast event to see that their command worked.

Example:

```text
Manager reschedules Fixture
```

The command response can contain:

```text
new schedule
revision
```

The initiating screen can immediately show success/update or refresh that primary model.

Realtime handles **other screens and other devices**.

So:

```text
Command response
= immediate local confirmation

Broadcast
= distributed reconciliation
```

Both are useful.

---

# 13.31 Realtime is not a guaranteed historical event log

Suppose a user's phone disconnects for ten minutes.

We do not need to replay every:

```text
FixtureRescheduled
StandingsChanged
DrawPublished
```

event they missed.

On reconnect:

```text
REFETCH CANONICAL READ MODEL
```

and they are correct again.

Therefore:

> Tournament Realtime exists to reduce staleness, not to reconstruct truth.

This dramatically simplifies the architecture.

---

# 13.32 Reconnect strategy

When:

```text
WebSocket reconnects
App returns from background
User revisits Tournament route
Auth token changes
```

the Tournament coordinator should refresh high-value read models.

At minimum:

```text
shell
visible tab
```

If organizer console:

```text
console snapshot
live board
```

No need to refetch every possible tab.

---

# 13.33 Revision-aware Realtime

Events should contain a revision where useful.

Suppose client has:

```text
fixtureRevision = 24
```

and receives:

```text
FixtureRescheduled revision 25
```

Refresh.

If later it receives delayed:

```text
revision 24
```

ignore it.

If it somehow receives:

```text
revision 28
```

while current is 24:

```text
gap detected
→ refetch canonical state
```

This gives us robust out-of-order handling without complex event replay.

---

# 13.34 Current Standings Realtime has a concrete mismatch

This is worth highlighting.

Your Flutter provider currently uses:

```dart
_supabase
    .from('tournament_standings')
    .stream(
      primaryKey: [
        'tournament_id',
        'team_id',
      ],
    )
```

The Supabase Dart `stream()` API combines an initial read with Realtime table changes.

But Postgres Changes requires the table to be part of the `supabase_realtime` publication. Supabase documents that requirement explicitly. :chatgpt-content-reference{index="2"}

I checked your **live project publication**.

Of the Tournament/Match tables we inspected, the publication currently contains:

```text
matches
```

but not:

```text
tournament_standings
```

So the current `tournamentStandingsStream()` architecture deserves a specific audit.

You also have a database broadcast trigger for standings changes, but the current Flutter standings provider is using `stream()`, not that Broadcast channel.

Those two realtime mechanisms currently do not line up.

I would not simply add `tournament_standings` to the publication as our long-term fix.

Given the new architecture, I would move standings to:

```text
Standing projection changes
      ↓
StandingsChanged Broadcast
      ↓
invalidate StageStandingsReadModel
      ↓
refetch authoritative ranking
```

which also aligns with Supabase's current preference for Broadcast at scale. :chatgpt-content-reference{index="3"}

---

# 13.35 We should reduce raw Postgres Changes usage

This does not mean Postgres Changes is bad.

It is perfectly useful for:

```text
development
small low-frequency tables
simple direct reactive screens
```

Supabase still supports it.

But for a growing social/sports application, listening directly to many normalized Tournament tables means every client becomes coupled to persistence details, and Supabase notes that Postgres Changes performs per-subscriber authorization work and can become a bottleneck as subscriber counts grow. :chatgpt-content-reference{index="4"}

So for Tournament:

```text
Domain Broadcast
```

is the better long-term boundary.

---

# 13.36 Materialized views: mostly no

I would **not** use materialized views for:

```text
live standings
fixtures
bracket
live ops
```

because they require refreshes and can be stale.

Supabase's documentation specifically describes materialized views as useful when stale results are tolerable, especially analytics-like queries. :chatgpt-content-reference{index="5"}

Potential future use:

```text
popular tournament discovery
historical analytics
organizer career statistics
season-wide aggregated stats
```

But not competition truth.

---

# 13.37 Flutter provider structure

Conceptually, I would move toward:

```text
Tournament Queries
│
├── tournamentShellProvider(id)
├── tournamentOverviewProvider(id)
├── tournamentEntriesProvider(id)
├── tournamentFixturesProvider(id)
├── stageStandingsProvider(stageId, groupId?)
├── tournamentBracketProvider(stageId)
├── tournamentStatsProvider(id)
├── tournamentAwardsProvider(id)
└── organizerConsoleProvider(id)

Tournament Realtime
└── tournamentRealtimeCoordinatorProvider(id)

Tournament Commands
└── tournamentCommandClientProvider
```

That is much easier to understand than one feature provider file containing every concept forever.

---

# 13.38 Provider lifecycle

Most screen-level read providers should remain:

```text
autoDispose
```

so leaving the Tournament route releases memory.

But the Realtime coordinator should remain alive for as long as the route/scope is active.

For example:

```text
TournamentDetailScreen
    watches
TournamentRealtimeCoordinator(id)
```

and each visible tab watches its read model.

When route disappears:

```text
all dispose
channel unsubscribes
```

That's clean.

---

# 13.39 Avoid one global mutation loading state

Your current:

```text
TournamentsController
```

has one:

```text
AsyncValue<void> state
```

for operations such as:

```text
register
approve
reject
publish
reschedule
assign scorer
record payment
assign official
...
```

This already required special `ref.mounted` guards because the notifier can be disposed while a write is running.

There is another issue too:

> One state cannot accurately represent several simultaneous mutations.

Imagine:

```text
Manager assigns scorer for Match 1
```

while another UI operation is:

```text
rescheduling Match 2
```

One global `AsyncLoading` doesn't identify which action is pending.

I would eventually separate:

```text
Command service
```

from:

```text
mutation UI state
```

---

# 13.40 Command state should be local/keyed

For example:

```text
assignScorerMutation(matchId)
rescheduleFixtureMutation(fixtureId)
approveRegistrationMutation(registrationId)
```

or the widget maintains the short-lived pending state while using a stateless command client.

This lets:

```text
Approve Lahore
```

show a spinner only on Lahore's row.

Not freeze the entire Tournament controller.

---

# 13.41 Riverpod is cache, not database

For Tournament v1, I would **not** build another persistent local database/local-first engine like your chat architecture.

Chat genuinely benefits from local-first messaging.

Tournament competition state has much lower write frequency and much harder conflict semantics.

For now:

```text
Supabase = authoritative
Riverpod = in-memory state/cache
Realtime = invalidation/reconciliation
```

is enough.

If Matchday later needs offline tournament operation at grounds with unreliable internet, that becomes a separate deliberate architecture problem.

Do not accidentally build offline tournament writes now.

---

# 13.42 Stale-while-revalidate

For a good UX, when a read model is invalidated we don't necessarily need to blank the entire screen and show:

```text
CircularProgressIndicator
```

again.

Where practical:

```text
old snapshot remains visible
+
small refreshing state
+
new snapshot replaces it
```

This is especially important for:

```text
standings
fixtures
organizer console
```

during a live tournament.

Riverpod can support this behavior without inventing local domain truth.

---

# 13.43 Pagination and lazy loading

Not every tournament will stay eight teams forever.

We should design read queries with sensible scope.

For example:

```text
Fixtures
→ stage/round paging or date window

Entries
→ usually small enough to return all initially

Registration history
→ pageable if large

Stats
→ top N initially

Audit
→ definitely paginated

Announcements
→ paginated
```

Do not return 500 historical administrative events with every Organizer Console refresh.

---

# 13.44 Read permissions need their own projections

Remember Step 10:

```text
PUBLIC
PARTICIPANT
ORGANIZER
```

should not all query the same giant model and rely on Flutter to hide sensitive fields.

Prefer read surfaces such as:

```text
tournament_public_detail
```

versus organizer RPC:

```text
get_tournament_organizer_console(...)
```

The public projection does not even contain:

```text
payment references
internal decision reason
private audit details
```

Security by data minimization is stronger than:

```text
Flutter received it but didn't render it.
```

---

# 13.45 `security_invoker` needs to be standard for public views

Your current `cricket_match_details` already has:

```text
security_invoker=true
```

which is good.

Every future API-exposed projection view should go through the same security review.

Supabase explicitly warns that views use the owner's permissions by default and recommends `security_invoker` when the querying user's underlying RLS should apply. :chatgpt-content-reference{index="6"}

This should become part of our migration checklist.

---

# 13.46 Public bracket realtime

Example:

```text
User watching Final bracket
```

and semifinal finishes.

Sequence:

```text
CompleteCricketMatch
        ↓ transaction
FixtureOutcome finalized
        ↓
Final slot resolved
        ↓
COMMIT

Broadcast:
BracketChanged

Flutter TournamentRealtimeCoordinator
        ↓
invalidate bracketProvider(stageId)

GET canonical bracket projection
        ↓
Final now shows:
Lahore Lions vs Kasur Kings
```

Flutter never manually moves Lahore into Final.

Exactly what we want.

---

# 13.47 Standings realtime

Likewise:

```text
Match Complete
    ↓
standing projection recomputed
    ↓
COMMIT

Broadcast:
StandingsChanged(
    stage = ...
    group = ...
)

Flutter:
refresh only that standing
```

No client sorting:

```text
points → NRR
```

No client calculating rank.

No client calculating qualifier.

---

# 13.48 Organizer Live Ops realtime

Live Ops needs faster operational refresh than a static public page.

Use:

```text
tournament:<id>:ops
```

events such as:

```text
ScorerAssigned
FixtureStarted
FixtureCompleted
FixtureNeedsAttention
ScheduleChanged
```

to refresh:

```text
OrganizerConsoleReadModel
```

or a smaller:

```text
TournamentLiveOpsReadModel
```

depending on the event.

We shouldn't poll the full console every few seconds if nothing changed.

---

# 13.49 Polling may still exist as recovery, not architecture

A low-frequency safety refresh can be acceptable for a live control room.

For example:

```text
on screen resume
on Realtime reconnect
occasional health refresh
```

But it should not be:

```text
every 2 seconds
fetch entire tournament
```

because that's compensating for a poor realtime design.

Realtime event → targeted refresh should be the primary mechanism.

---

# 13.50 Search and discovery have different read needs

Tournament Discover should never query the full Tournament aggregate.

It wants cards:

```text
TournamentDiscoveryCard

id
name
sport
logo
city
public phase
date
entry count / capacity
following
live indicator
```

That can be a purpose-built security-invoker projection.

No:

```text
rules JSON
draw graph
payment data
squad
```

needed.

---

# 13.51 My Tournaments also deserves one query

Today `getMyTournaments()` fetches:

```text
organized tournaments
```

then:

```text
followed target IDs
```

then:

```text
followed tournaments
```

and combines/deduplicates them client-side.

That is functional, but as the relationship types grow:

```text
Owned
Managing
Playing
Following
```

the client logic will become more complicated.

A future:

```text
my_tournament_hub()
```

read RPC can return:

```text
relationship = owner
relationship = manager
relationship = participant
relationship = follower
```

and one card shape.

The server is much better positioned to determine this relationship.

---

# 13.52 Read models should have revisions

A useful read response might contain:

```text
TournamentShell
revision = 17
```

or:

```text
Bracket
drawRevision = 3
competitionRevision = 91
```

and:

```text
Standings
revision = 42
```

This gives Riverpod/realtime reconciliation a stable notion of freshness.

We don't need one giant global Tournament revision.

Different projections can use relevant revisions.

---

# 13.53 Current implementation: what stays

Several existing pieces are good:

```text
Riverpod family providers keyed by tournamentId
```

Good.

```text
autoDispose read providers
```

Generally good.

```text
Repository abstraction
```

Good.

```text
security_invoker cricket_match_details
```

Good.

```text
specific read RPCs such as tournament_live_board
```

Good direction.

We should build on those rather than replace Riverpod.

---

# 13.54 Current implementation: what changes

The biggest read-side refactors later are:

| Current | Direction |
|---|---|
| UI determines tabs from `TournamentType` | derive from actual Stage structure |
| UI calculates qualification cut | server read model |
| UI sorts generic standings by Points + NRR | authoritative server rank |
| Standings uses raw table `stream()` | semantic Broadcast + refetch |
| Live Ops model leaks Cricket fields into generic Tournament domain | generic ops read model + Cricket projection |
| One huge `TournamentsRepository` | split query responsibilities |
| Controller manually invalidates provider lists | central Realtime/read invalidation coordinator |
| one mutation state for all commands | keyed/local mutation state |
| public detail depends on Live Ops board for form | public/team-context projection |
| My Tournaments assembles relationships client-side | purpose-built hub projection |

These are important, but they are evolutionary refactors rather than grounds for rewriting Flutter.

---

# 13.55 Canonical runtime flow

The final picture should look like:

```text
                     FLUTTER
                        │
             ┌──────────┴───────────┐
             │                      │
          COMMANDS                QUERIES
             │                      │
             ▼                      ▼
      Edge Command Layer      Read Models
             │               Views / Read RPCs
             │                      │
             └─────────┬────────────┘
                       ▼
                    POSTGRES
                       │
                    COMMIT
                       │
                 Domain Broadcast
                       │
        ┌──────────────┴──────────────┐
        ▼                             ▼
TournamentRealtimeCoordinator     Match Realtime
        │                             │
        ▼                             ▼
invalidate targeted            live score state
Riverpod read models
        │
        ▼
refetch canonical
read projection
```

This gives us server-authoritative state without making Flutter feel slow.

---

# Step-13 standard to freeze

1. **Write models follow aggregate boundaries; read models follow screen/use-case boundaries.**
2. **Flutter must not reconstruct the normalized Tournament graph through many independent table reads.**
3. **Views are appropriate for stable reusable row projections; complex/viewer-specific composite reads use read RPCs.**
4. **Every exposed view must receive an explicit security review; `security_invoker=true` is the standard when underlying RLS should apply.**
5. **Tournament Detail should load a compact shell first and lazily load expensive tab content.**
6. **UI structure derives from first-class Stages rather than the old `TournamentType`.**
7. **Flutter must never calculate qualification rules, rankings, progression or other competition truth.**
8. **Bracket, standings and fixture screens consume authoritative server projections.**
9. **Organizer Console should use a purpose-built composite read model rather than many cross-table requests.**
10. **Participant, public and organizer read surfaces must remain distinct to avoid leaking administrative data.**
11. **Viewer capability context may be included in read models for UX but never replaces server command authorization.**
12. **Tournament Realtime should communicate semantic domain changes, not raw physical table changes.**
13. **Supabase Broadcast should be the long-term default for Tournament-domain invalidation; Postgres Changes can remain for simpler low-scale cases.**
14. **Tournament realtime payloads should be small invalidation hints, while canonical state is refetched from read models.**
15. **Public and organizer operational events should use different authorization scopes/topics.**
16. **High-frequency sport events remain Match-level Realtime; they must not flood the Tournament channel.**
17. **One route-scoped Tournament Realtime coordinator should own subscriptions and centrally map events to Riverpod refreshes.**
18. **Provider invalidation mapping should be centralized rather than duplicated in every mutation handler.**
19. **Command responses provide immediate initiating-device feedback; Realtime reconciles other consumers/devices.**
20. **Reconnect/app-resume should refetch canonical state rather than attempting to replay every missed event.**
21. **Realtime events/read models should use revisions to detect stale or out-of-order updates where useful.**
22. **The current `tournament_standings.stream()` path needs auditing because `tournament_standings` is not currently in the live project's `supabase_realtime` publication.**
23. **Materialized views are not appropriate for live competition truth; reserve them for stale-tolerant analytics/discovery if needed later.**
24. **Riverpod remains the in-memory presentation/cache layer; we do not need a local-first Tournament database at this stage.**
25. **Mutation state should eventually be operation/entity-specific rather than one global `TournamentsController` loading state.**
26. **Existing good patterns—Riverpod families, read RPCs, repository abstraction, `security_invoker` views—should be retained and refined rather than replaced.**

The next logical **Step 14 should be Testing, Invariants & Failure-Recovery Standard**. Before we touch migrations, we should define what must be proven automatically: tournament lifecycle transition tests, capability tests, Entry/Draw invariants, deterministic fixture-generation tests, progression/idempotency tests, result-correction downstream tests, standings/tie-break golden tests, RLS security tests, command concurrency tests, and full integration scenarios such as “8 teams → knockout → scorer completes QF → semifinal slot resolves exactly once.” That will give us a safety net before the existing schema begins moving toward the Step-11 model.





Yes. I think this should become the next formal step **before migrations and testing** because the tournament data model we designed should also support a very strong **mobile organizer experience**.

For Matchday, I would call this:

# Step 14 — Tournament UX, Bracket Visualization & Flutter Interaction Architecture

The important thing is that we should **not copy a desktop tournament website into Flutter**. A local tournament organizer will often be standing beside a ground with one phone in one hand. The UI has to let them understand the competition in a few seconds, make one action, and return to the field. Score7 describes essentially this mobile-first organizer scenario: participant management, schedule generation, score entry, and advancement all being operable directly from a phone at the venue. :chatgpt-content-reference{index="0"}

These are useful visual references for the kind of interaction language I mean:



---

## 14.1 First conclusion: the bracket should not be the only interface

This is probably the most important UX decision.

A full tournament bracket is excellent for understanding:

```text
Where am I?
Who feeds whom?
Who can reach the final?
```

But it is **not always the best way to operate a tournament from a phone**.

Even Toornament's own bracket display guidance says a bracket is fundamentally a graph, and when it becomes too large or complicated to remain readable, a simplified match list is preferable to forcing an unreadable graph. :chatgpt-content-reference{index="2"}

Therefore Matchday should offer both:

```text
VISUAL MODE
Bracket / competition graph

and

OPERATION MODE
Round / fixture list
```

They represent the same underlying fixtures.

They are just different projections.

---

# 14.2 Three viewing levels

I would design the Tournament UI around three levels.

```text
LEVEL 1
Tournament overview
"What needs attention?"

        ↓ tap

LEVEL 2
Stage / round
"What matches are happening here?"

        ↓ expand

LEVEL 3
Full competition canvas
"How does the whole bracket connect?"
```

This is much easier on mobile than immediately opening an enormous 32-team tree.

---

# 14.3 Public bracket vs organizer bracket

These should use the same underlying renderer but have different interaction modes.

### Spectator / participant

The bracket is primarily:

```text
view
pan
zoom
select match
follow path
open match
```

### Organizer

The bracket additionally exposes:

```text
schedule
ground
scorer
officials
operational status
warnings
```

But even the organizer should **not edit every property directly on the canvas**.

The canvas should remain visually clean.

Tap a match → open the operational sheet.

---

# 14.4 Flutter is now very capable of this natively

Flutter's current `InteractiveViewer` already provides pan, pinch zoom, transformation control and trackpad/mouse behavior. More importantly, `InteractiveViewer.builder` receives the currently visible viewport, allowing a large scene to build only what is relevant around the visible region. :chatgpt-content-reference{index="3"}

Its `TransformationController` lets us programmatically:

```text
Fit bracket
Focus match
Jump to round
Reset zoom
Center live match
```

rather than relying only on finger gestures. :chatgpt-content-reference{index="4"}

So I would absolutely use:

```text
InteractiveViewer.builder
+
TransformationController
+
CustomPainter
```

for Matchday's long-term bracket renderer.

---

# 14.5 Don't require the user to know pinch-to-zoom

Pinch zoom is useful.

It should not be the only navigation mechanism.

The bracket toolbar should give obvious controls:

```text
QF   SF   FINAL

[ Fit ] [ − ] [ + ] [ Live ]
```

And potentially:

```text
My Team
```

for participants.

Tap:

```text
SF
```

and animate to the semi-final column.

Tap:

```text
Live
```

and animate to the currently live fixture.

Tap:

```text
My Team
```

and focus its current path.

The user should never need to hunt around a huge canvas manually.

---

# 14.6 Mobile bracket mode

On a normal phone, I would initially show approximately:

```text
1.0–1.5 rounds
```

rather than trying to scale a 16-team bracket so the entire thing fits.

For example:

```text
QUARTER FINAL             SEMI FINAL

┌ Lahore Lions ────────┐
│ 184/7                │
│                      ├── Lahore Lions
│ Kasur Kings          │
└ 177/9 ───────────────┘
                       │
                       │
┌ Falcons ─────────────┤
│                      │
│ Warriors             │
└──────────────────────┘
```

Swipe/pan to the next round.

This keeps team names and scores readable.

---

# 14.7 Full-screen bracket

Add:

```text
Expand
```

to open:

```text
FullScreenBracketScreen
```

where we allow:

```text
2D pan
pinch zoom
fit entire bracket
focus round
focus match
```

On tablets and landscape screens, we can display substantially more of the graph.

We should not force phone portrait and tablet landscape to use exactly the same layout.

---

# 14.8 Responsive behavior

Conceptually:

| Available width | Presentation |
|---|---|
| Phone portrait | focused round canvas |
| Phone landscape | 2–3 rounds |
| Tablet | full multi-column bracket |
| Desktop/web | complete bracket + side inspection pane |

Same data.

Same graph.

Different viewport policy.

---

# 14.9 Match cards must stay widgets

I would **not paint the match cards entirely with Canvas**.

Keep match cards as real Flutter widgets.

Why?

Because we need:

```text
tap
semantics
team logo
live indicator
animations
status badges
text wrapping
accessibility
```

and widgets handle those very naturally.

Use:

```text
CustomPainter
```

only for:

```text
connector lines
path highlighting
background graph decoration
```

This gives us the best of both worlds.

---

# 14.10 Proposed bracket rendering architecture

```text
TournamentBracketReadModel
           │
           ▼
BracketLayoutEngine
           │
     ┌─────┴─────┐
     ▼           ▼
Node Rects     Connector Paths
     │           │
     │           ▼
     │      CustomPainter
     ▼
Match Widgets
     │
     └──────┬────────┘
            ▼
 InteractiveViewer.builder
            │
            ▼
TransformationController
```

This should be its own UI engine.

Not a pile of calculations inside `TournamentBracketView.build()`.

---

# 14.11 `BracketLayoutEngine` must be deterministic

It takes:

```text
Rounds
Fixtures
FixtureSlots
SlotSources
```

and produces:

```text
node rectangles
round bounds
connector geometry
canvas dimensions
```

It should have **no Flutter state**, network calls or Riverpod dependencies.

Pure input:

```text
BracketGraph
```

Pure output:

```text
BracketLayout
```

That means we can unit-test:

```text
8-team bracket
6-team bracket with byes
16-team bracket
third-place playoff
double elimination later
```

without rendering a single widget.

---

# 14.12 This is better than a generic graph algorithm

There are established Flutter graph libraries such as `graphview`, including layered/Sugiyama and tree layouts. :chatgpt-content-reference{index="5"}

I **wouldn't use a generic automatic graph layout for Matchday's normal knockout bracket**.

Why?

Tournament brackets have strict visual grammar:

```text
Round 1
    ↓
Quarter-final
    ↓
Semi-final
    ↓
Final
```

and users expect specific symmetrical placement.

A physics/layout algorithm deciding where QF2 should sit makes the result less predictable.

Use our deterministic Tournament layout engine.

---

# 14.13 I also would not depend on a new bracket package right now

There are actually promising Flutter packages now.

`tournament_bracket_kit` supports custom cards, pan/zoom, round navigation, elbow connectors and mirrored layouts. :chatgpt-content-reference{index="6"}

There is also a new `flutter_bracket` renderer advertising explicit winner/loser progression, zoom/pan, BYEs/TBD, double elimination and viewport virtualization. :chatgpt-content-reference{index="7"}

But there is an important maturity problem.

`tournament_bracket_kit 1.0.2` was published only days ago and currently has very little adoption. :chatgpt-content-reference{index="8"}

And `flutter_bracket 0.1.0` is essentially brand-new—the publisher/package was only newly registered when I checked. :chatgpt-content-reference{index="9"}

For a core Matchday experience, I would **study these packages, not depend on them yet**.

Your bracket is too central to:

```text
Single elimination
Groups → knockout
Double elimination later
Byes
Walkovers
Explicit slot sources
Result corrections
Matchday branding
```

to base the product on a very young dependency.

---

# 14.14 Your existing bracket implementation has a good foundation

I reviewed the current:

```text
tournament_bracket_view.dart
```

and there are several design choices I would keep.

You already have:

```text
round navigation chips
animated round navigation
orthogonal connector lines
distinct resolved/unresolved visual states
third-place section
compact bracket cards
Matchday paper/ink visual language
```

That's a better starting point than replacing everything with a package.

But architecturally it needs to evolve significantly.

---

# 14.15 Current problem: it is horizontal scroll, not a true bracket viewport

Currently:

```text
SingleChildScrollView(horizontal)
```

provides navigation.

That gives us:

```text
left/right
```

but not:

```text
pinch zoom
2D navigation
fit-to-view
focus match
focus path
center final
overview
```

For a 4- or 8-team bracket, that is fine.

For:

```text
16
32
64 teams
```

it becomes uncomfortable.

This is where `InteractiveViewer.builder` should replace the horizontal-only model. Flutter explicitly supports building a child based on the visible transformed viewport, which is useful for large interactive scenes. :chatgpt-content-reference{index="10"}

---

# 14.16 Current problem: feeder lines are inferred visually

This is more serious.

Current `_FeederPainter` essentially says:

```text
take child N

connect it to:
previous-column item N×2
previous-column item N×2+1
```

That works for a perfectly ordered standard bracket.

But after Steps 7 and 11, we already know the real graph should say:

```text
Final Slot A
source = Winner SF1

Final Slot B
source = Winner SF2
```

The UI should draw:

```text
source fixture → target slot
```

from the **actual FixtureSlotSource**.

It should never infer the competition topology from screen order.

---

# 14.17 Current problem: fixtures are sorted by schedule time

The current code orders fixtures inside a round by:

```text
scheduledStartTime
```

That can be wrong for bracket visualization.

Imagine QF3 gets rescheduled earlier than QF1.

The bracket could suddenly visually reorder.

That's unacceptable.

The visual tree must use:

```text
bracket position
fixture position
round position
```

from Tournament structure.

Schedule time is metadata shown on the card.

It does not determine bracket position.

---

# 14.18 Current problem: `shouldRepaint`

Current feeder painter has:

```dart
shouldRepaint =>
    old.placed.length != placed.length;
```

That means if:

```text
QF1 gets a winner
```

but the number of nodes stays the same, the connector style may not repaint correctly.

The new painter should compare:

```text
graph revision
layout revision
selected path
resolution state
```

or receive immutable render-state objects with proper equality.

Flutter also explicitly notes that expensive custom painting should use correct `shouldRepaint` decisions and can benefit from a `RepaintBoundary` when appropriate. :chatgpt-content-reference{index="11"}

---

# 14.19 Current problem: walkover and bye semantics are mixed

Your current painter can visually interpret a `walkover` as a bye-style feeder.

But from our tournament standard:

```text
BYE
=
no contest was expected

WALKOVER
=
contest was expected,
administratively resolved
```

They must look different.

Maybe:

```text
BYE
small "BYE" chip
muted dashed structural route

WALKOVER
match card stays present
"WO" result badge
resolved normal progression line
```

This tells the true story of the competition.

---

# 14.20 Current problem: unresolved slot vs bye

Currently if:

```text
teamA != null
teamB == null
```

the node can be treated as a bye.

But future Tournament structure may mean:

```text
Lahore Lions
vs
Winner QF2
```

where Slot B is intentionally unresolved.

That's **not a bye**.

Our bracket read model should explicitly provide:

```text
slotA.kind
slotB.kind
fixture.isBye
```

so the UI never guesses.

---

# 14.21 Better unresolved participant UX

Instead of:

```text
TBD
```

everywhere, show:

```text
Winner QF2
```

or:

```text
Group A · 1st
```

or:

```text
Loser SF1
```

This is dramatically easier to understand.

Toornament models this exact concept with bracket opponents supplied by seed, previous-match winner or previous-match loser. :chatgpt-content-reference{index="12"}

---

# 14.22 Path highlighting

This can make the bracket feel excellent.

Tap:

```text
Lahore Lions
```

and dim unrelated paths.

Highlight:

```text
Lahore
   QF ✓
      └── SF ✓
             └── Final
```

Similarly, tap an unresolved Final slot:

```text
Winner SF1
```

and highlight:

```text
QF1 → SF1
QF2 → SF1
         ↓
       Final
```

The bracket becomes explanatory, not decorative.

---

# 14.23 Match card interaction

On tap, don't immediately navigate away in organizer mode.

Open a bottom sheet first:

```text
SEMI-FINAL · MATCH 12

Lahore Lions
vs
Kasur Kings

Today · 17:00
Main Ground

Status: Upcoming
Scorer: Ali
Officials: 2 assigned

[Open Match]
[Reschedule]
[Change Scorer]
```

For public mode:

```text
[View Match]
```

only.

This keeps the organizer within the bracket context.

---

# 14.24 Live state

A live bracket match should be easy to find.

Not a huge pulsing red card.

Use your existing visual language:

```text
red live dot
LIVE chip
slightly stronger card border
```

and one global:

```text
LIVE 2
```

button at the top.

Tap it to cycle through active fixtures.

---

# 14.25 Do not overload the connector lines

Your current distinction between:

```text
resolved
unresolved
bye
```

is thoughtful.

But the user shouldn't need a permanent long legend just to read the graph.

Prefer lines plus meaningful card content:

```text
Winner QF1
BYE
WO
```

The legend can be:

```text
? How this bracket works
```

rather than occupying large vertical space every time.

For local organizers, screen space matters.

---

# 14.26 Seeding UI should not happen on the bracket itself

This is another major recommendation.

Don't make organizers drag small match cards around a zoomed bracket to seed teams.

That's a desktop-style interaction and is frustrating on mobile.

Use:

```text
SEEDING

1  Lahore Lions      ☰
2  Kasur Kings       ☰
3  Falcons           ☰
4  Warriors          ☰
5  Titans            ☰
```

Flutter's `ReorderableListView` is designed exactly for drag-based reordering; on mobile it supports long-press drag and can also use explicit custom drag handles. :chatgpt-content-reference{index="13"}

Then:

```text
[Randomize]
[Seeded]
[Manual]

        ↓

Preview Bracket
```

This is much easier.

---

# 14.27 Add lightweight haptic feedback

When:

```text
seed picked up
team dropped
group assignment succeeds
fixture position snaps
```

use a small haptic.

Flutter provides native haptic feedback APIs such as `HapticFeedback.lightImpact()`. :chatgpt-content-reference{index="14"}

It makes the interaction feel much more physical without visual clutter.

---

# 14.28 Group assignment

For groups, we can use:

```text
UNASSIGNED

Lahore Lions
Kasur Kings
Falcons
Warriors

GROUP A          GROUP B

Lahore           Kasur
Falcons           Warriors
```

On a tablet:

```text
drag team → Group A/B
```

Flutter's `Draggable` and `DragTarget` natively support this interaction. :chatgpt-content-reference{index="15"}

But on a narrow phone, dragging between multiple columns can be awkward.

So every team should also support:

```text
tap team
↓
Move to:
○ Group A
○ Group B
○ Group C
```

**Drag is a shortcut, never the only control.**

---

# 14.29 Group balancing UX

For seeded groups, show a small balance indicator:

```text
GROUP A       GROUP B

#1 Lahore     #2 Kasur
#4 Falcons    #3 Warriors
#5 Titans     #6 Stars
```

Then:

```text
Balanced by seed
```

The organizer should understand what the algorithm did.

Don't just say:

```text
Auto distribute complete
```

and hide the reasoning.

---

# 14.30 Round Robin should not use a bracket

For Round Robin, the strongest mobile UI is:

```text
Schedule | Standings
```

The schedule becomes:

```text
ROUND 1

09:00 · Ground A
Lahore Lions
vs
Kasur Kings

09:00 · Ground B
Falcons
vs
Warriors
```

then:

```text
ROUND 2
...
```

not a graph.

---

# 14.31 Round navigation

At the top:

```text
R1  R2  R3  R4  R5  R6  R7
```

horizontal chips.

And filters:

```text
All
Live
Upcoming
Completed
Ground 1
Ground 2
```

This lets a local organizer find:

> “What should be happening on Ground 2 now?”

within seconds.

---

# 14.32 Round Robin preview before publishing

For fixture generation:

```text
16 teams
15 rounds
120 matches
```

do not dump 120 cards and ask:

> Publish?

Instead:

```text
SCHEDULE PREVIEW

15 rounds
120 matches
4 grounds
Estimated duration: 3 days

No team conflicts
2 short rest warnings

Preview:
R1
R2
R3

[Review Warnings]
[Publish Schedule]
```

Then allow deeper inspection.

A recent tournament scheduling UI example uses exactly this pattern of previewing generated round-robin schedules and then moving into a matchday/calendar view. 

---

# 14.33 Standings: use Flutter's official 2D table capability

Flutter's official `two_dimensional_scrollables` package is particularly interesting for Matchday.

Current `TableView` supports:

```text
horizontal + vertical scrolling
lazy cell creation
pinned rows
pinned columns
merged cells
```

and is published by `flutter.dev`. :chatgpt-content-reference{index="17"}

This is a strong fit for tournament standings.

For example:

```text
TEAM       P   W   L   NR   PTS   NRR
--------------------------------------
Lahore     4   4   0    0     8  +1.84
Kasur      4   3   1    0     6  +0.72
...
```

Keep:

```text
Team
```

pinned while the metrics scroll horizontally.

Very useful on small phones.

---

# 14.34 But don't put too many columns on the normal screen

Default Cricket table:

```text
Team | P | Pts | NRR
```

possibly W/L depending available width.

Then:

```text
Show details
```

for:

```text
W
L
T
NR
Runs
etc.
```

User-friendly means prioritizing information, not displaying every field just because TableView can.

---

# 14.35 Group + Knockout needs a stage switcher

For:

```text
Group Stage
→ Playoffs
```

don't create a special confusing page.

Use:

```text
GROUP STAGE     PLAYOFFS
```

as a stage-level switch.

During Group Stage:

```text
Groups
Fixtures
Standings
```

During Playoffs:

```text
Bracket
Fixtures
```

After qualification resolves, show:

```text
PLAYOFFS READY

Group A #1 → Lahore Lions
Group B #2 → Kasur Kings
```

then allow the user to open the bracket.

---

# 14.36 Visual transition into playoffs

This can be very effective:

```text
GROUP A                     PLAYOFFS
1 Lahore ✓ ───────────────► SF1
2 Falcons ✓ ──────────────► SF2
3 Warriors
4 Kings
```

But don't create a huge graph connecting every standings row.

A compact qualification card is enough.

---

# 14.37 Double elimination

Double elimination is exactly where one giant phone canvas becomes dangerous.

For future support, use:

```text
Winners
Losers
Finals
Full bracket
```

as segmented modes.

The full bracket remains available for power users.

But normal users can inspect each branch independently.

Battlefy and Toornament both treat elimination brackets as navigation tools and support distinct progression structures rather than treating them merely as decoration. :chatgpt-content-reference{index="18"}

---

# 14.38 Organizer dashboard should be action-first

Instead of opening with:

```text
Tournament details
description
banner
rules
...
```

an active tournament manager should see:

```text
TODAY

2 LIVE
3 READY
1 NEEDS SCORER

NEXT
13:30 · Ground A
Lahore vs Kasur

ATTENTION
Ground B fixture has no scorer

[Open Live Ops]
```

Then the structural tabs sit below.

During tournament day, operations are more important than the tournament description.

---

# 14.39 Create/edit flow

The creation experience should be a clear stepper:

```text
Basics
  ↓
Teams
  ↓
Competition
  ↓
Seeding / Groups
  ↓
Schedule
  ↓
Preview
  ↓
Publish
```

Not one enormous form.

And critically:

```text
Preview
```

should look very close to what teams will actually see.

---

# 14.40 Progressive disclosure

Local organizers often won't understand terms like:

```text
Stage
Slot source
Fixture graph
Competition adapter
```

Those are our internal architecture terms.

UI says:

```text
Tournament Format
Groups
Knockout
Round
Match
Who advances?
```

The system can be sophisticated internally without exposing implementation vocabulary.

---

# 14.41 "Advanced" options stay hidden by default

For example:

```text
Knockout

Teams: 8
Third-place match: Off

[Generate Bracket]
```

then:

```text
Advanced
```

could expose:

```text
Seeding method
Bye placement
Third-place playoff
Match-format overrides
```

Most local tournament organizers should never need to touch them.

---

# 14.42 Touch targets and accessibility

The bracket should not turn into tiny 24px targets after zooming out.

At low zoom:

```text
cards can visually simplify
```

but users should be encouraged/focused to zoom before interacting.

At normal zoom, each fixture remains an accessible widget.

Flutter's `Semantics` API lets us give match cards meaningful accessibility descriptions rather than exposing disconnected text elements. :chatgpt-content-reference{index="19"}

For example:

```text
"Semi-final 1.
Lahore Lions versus Kasur Kings.
Lahore won by seven runs.
Double tap for match details."
```

---

# 14.43 Rendering performance

Flutter is capable of rendering this very smoothly if we structure it correctly.

Impeller is Flutter's default modern renderer on current supported mobile platforms, designed for predictable shader/rendering behavior. :chatgpt-content-reference{index="20"}

But we still need to avoid building 500 expensive widgets every frame.

For a large bracket:

```text
InteractiveViewer.builder
```

tells us what part of the scene is visible.

We can render:

```text
visible nodes
+
small overscan
```

instead of all nodes.

Connector paths can remain cheap CustomPainter geometry.

---

# 14.44 Use repaint isolation

Conceptually:

```text
BracketCanvas
    ├── RepaintBoundary
    │     ConnectorPainter
    │
    └── Match cards
```

When one live score card changes, we should not unnecessarily repaint the entire Tournament screen.

Flutter's performance guidance recommends controlling rebuild cost, and `RepaintBoundary` can isolate expensive painting regions when appropriate. :chatgpt-content-reference{index="21"}

---

# 14.45 Zoom-level detail

This is one interaction I think would make Matchday look especially polished.

At:

```text
0.4×
```

show:

```text
team abbreviated names
winner state
score
```

At:

```text
0.8×+
```

show:

```text
full team names
logos
score
status
```

At:

```text
1.2×+
```

show:

```text
venue/time/live details
```

So zooming out doesn't leave microscopic unreadable text.

It becomes a **semantic zoom**.

---

# 14.46 Focus animation

A `TransformationController` can animate to:

```text
round bounds
fixture bounds
team path
live match
final
```

This is important because a graph feels much better when tapping:

```text
Final
```

smoothly moves the camera there rather than snapping.

Your current code already animates horizontal round navigation.

We should preserve that feeling, just upgrade it to a 2D camera.

---

# 14.47 Mini-map: only for large brackets

For:

```text
4/8 teams
```

don't show it.

For:

```text
32/64+
```

a small bottom-corner overview can show:

```text
[ entire bracket ]
      ▣ current viewport
```

This is a power-user feature.

Not necessary in the first renderer release.

---

# 14.48 Public list fallback

Always include:

```text
Bracket | Matches
```

for elimination stages.

Why?

Some users simply want:

> Who plays at 5 PM?

They don't care about visual progression.

And users with accessibility needs may find a normal list easier.

This also follows the mature tournament-platform principle that the bracket is a navigation tool, not the only representation. :chatgpt-content-reference{index="22"}

---

# 14.49 Matchday visual language

I would keep your existing:

```text
Paper
Ink
Cream
Muted
Red
```

design language.

For competition states:

| Meaning | Treatment |
|---|---|
| Live | Matchday red accent |
| Winner | stronger ink + subtle success cue |
| Loser | muted |
| Unresolved | soft/muted |
| Qualification | thin accent/chip |
| Bye | cream/neutral |
| Walkover | explicit `WO` badge |
| Error/attention | red surface, not same as Live |
| Selected path | ink/accent connector |

Do not rely on color alone.

Use:

```text
LIVE
WO
BYE
Winner QF1
```

textual cues too.

---

# 14.50 My recommendation for Matchday's Flutter stack

I would use:

| Need | Technology |
|---|---|
| Knockout graph viewport | `InteractiveViewer.builder` |
| Camera/focus/fit | `TransformationController` |
| Connector rendering | `CustomPainter` |
| Fixture cards | normal Flutter widgets |
| Large-bracket optimization | viewport culling + `RepaintBoundary` |
| Seed reorder | `ReorderableListView` |
| Group drag/drop | `Draggable` / `DragTarget` |
| Standings | official `two_dimensional_scrollables/TableView` |
| Round schedule | `CustomScrollView` / slivers |
| State | Riverpod read models from Step 13 |
| Realtime | semantic Tournament Broadcast |
| Accessibility | `Semantics` |
| tactile feedback | `HapticFeedback` |

I would **not add a generic graph package or immature bracket library as a core dependency** at this point.

---

# 14.51 Target UI architecture

I would structure the Flutter code conceptually like:

```text
features/tournaments/
│
├── presentation/
│   │
│   ├── competition/
│   │   ├── bracket/
│   │   │   ├── bracket_view.dart
│   │   │   ├── bracket_canvas.dart
│   │   │   ├── bracket_match_card.dart
│   │   │   ├── bracket_toolbar.dart
│   │   │   ├── bracket_round_strip.dart
│   │   │   └── bracket_match_sheet.dart
│   │   │
│   │   ├── standings/
│   │   ├── groups/
│   │   ├── schedule/
│   │   └── seeding/
│   │
│   └── organizer/
│       ├── live_ops/
│       ├── draw_editor/
│       └── schedule_editor/
│
└── ui_models/
    └── bracket/
        ├── bracket_graph.dart
        ├── bracket_layout.dart
        └── bracket_layout_engine.dart
```

And importantly:

```text
BracketLayoutEngine
```

is presentation-domain geometry.

It is **not** Tournament business logic.

---

# 14.52 The organizer flow I would aim for

```text
8 confirmed teams

        ↓

SEEDING
Drag / random / automatic

        ↓

PREVIEW DRAW
Interactive bracket

        ↓

SCHEDULE
Auto schedule or set later

        ↓

VALIDATION
✓ no structural problem
✓ no team duplication
! 1 scorer missing

        ↓

PUBLISH

        ↓

LIVE OPS

        ↓

Tap fixture
Score / reschedule / staff

        ↓

Winner automatically progresses

        ↓

Bracket animates updated path
```

That should feel almost effortless.

---

# 14.53 What I would keep from your current bracket

I would definitely preserve the ideas of:

```text
round chips
orthogonal lines
clean paper background
compact cards
tap-through to match
explicit unresolved states
third-place presentation
animated navigation
```

Your current renderer already understands that a bracket must **read clearly**, not merely draw boxes.

We're upgrading the mechanics and domain correctness underneath it.

---

# 14.54 What I would remove/refactor from the current bracket

The current implementation should eventually stop relying on:

```text
TournamentType
TournamentLiveMatch as bracket structure
schedule-time ordering
previous-column visual inference
horizontal-only SingleChildScrollView
implicit teamB-null = bye
walkover-as-bye rendering
client-generated round relationship
long always-visible feeder legend
```

and move toward:

```text
TournamentBracketReadModel
explicit FixtureSlotSource
round_position
fixture_position
InteractiveViewer
true slot labels
semantic statuses
```

---

# Step-14 UX standard to freeze

The Matchday Tournament UI should be **mobile-first and action-first**, with the full bracket treated as one representation of the competition rather than the only one. Knockout stages should have both Bracket and Match-list views; round robin should primarily use Round/Schedule plus Standings; group-to-knockout should expose first-class Stage navigation.

For Flutter, the long-term bracket renderer should be custom and deterministic, built from `InteractiveViewer.builder`, `TransformationController`, widget-based fixture nodes and `CustomPainter` connectors. Its geometry must come from explicit Fixture/Slot-source relationships and never be inferred from visual position or schedule time. The renderer should support pan, pinch zoom, round navigation, fit-to-view, focus-match, semantic zoom and later viewport virtualization.

For organizer editing, **do not make the bracket itself the main editing form**. Seeding should use a reorderable mobile list, grouping should use drag/drop plus an accessible tap-based alternative, scheduling should use chronological rounds/matchday cards, and operational changes should happen from concise bottom sheets. The canvas remains for understanding structure.

And I would not introduce one of the newly published bracket packages as a core dependency yet. Flutter's native primitives are already sufficient, your current renderer provides a valuable Matchday-specific foundation, and the domain model we have designed is more sophisticated than the assumptions of most bracket packages.

The most important immediate design change is this:

```text
CURRENT

TournamentLiveMatch[]
      ↓
infer rounds/parents
      ↓
draw bracket
```

should become:

```text
TARGET

TournamentBracketReadModel
      │
      ├── Rounds
      ├── Fixtures
      ├── Explicit Slot Sources
      └── Resolved Entries
             ↓
      BracketLayoutEngine
             ↓
   Interactive Matchday Canvas
```

That would give Matchday the kind of polished bracket experience you're describing **without sacrificing the architecture we spent Steps 1–13 defining**.
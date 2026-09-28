I searched specifically for mature chat/offline systems and Flutter implementations that are close to your stack. I did **not** find a strong production reference using the exact combination `Flutter + Riverpod + Drift + Supabase + Ably`, but the individual pieces line up remarkably well with how Stream Chat, Sendbird, Matrix/Element X, PowerSync/Supabase and Ably solve the same problems.

The strongest conclusion from the research is that we should stop thinking of Matchday chat as one synchronization problem. Mature systems effectively treat your **Chats screen** and your **Chat Thread screen** as two different local-first projections, backed by the same local database and runtime engine.

---

# 1. The strongest direct comparison: Stream Chat Flutter

Stream is particularly valuable for us because its Flutter SDK uses **Drift/SQLite for offline persistence**. It persists chat data locally and stores offline actions so they can be retried when connectivity returns. It can also run the Drift persistence layer on a dedicated background isolate specifically to avoid blocking Flutter rendering during large syncs or reconnections. ([Stream][1])

Its architecture also separates the same two screens you have:

```text id="4sdoqw"
StreamChannelListController
        │
        ▼
   CHANNEL LIST

StreamMessageListController
        │
        ▼
   MESSAGE THREAD
```

The channel-list component handles querying, sorting, pagination and realtime updates independently from the message-list component. Channel rows resolve last message, unread count, timestamps and drafts without making the entire thread UI responsible for them. ([Stream][2])

That is a very strong signal for Matchday.

We should have:

```text id="98ajyj"
             Matchday Local-First Engine

                ┌───────────────┐
                │     Drift     │
                └───────┬───────┘
                        │
           ┌────────────┴────────────┐
           │                         │
           ▼                         ▼
      Inbox Projection        Thread Projection
           │                         │
           ▼                         ▼
      CHATS SCREEN             CHAT THREAD
```

Not:

```text id="709m4k"
One giant ChatProvider
       │
       ├── chat list
       ├── messages
       ├── sync
       ├── Ably
       ├── receipts
       └── pagination
```

That distinction is probably the biggest architectural improvement from this research.

---

# 2. Sendbird follows almost exactly the same separation

Sendbird Flutter has:

```text id="ei6oxz"
GroupChannelCollection
        ↓
channel list

MessageCollection
        ↓
specific conversation
```

Its local caching documentation explicitly says those collections exist to build the **channel-list view and chat view separately**, and its event controller only routes relevant events to the appropriate collection. ([Sendbird Docs][3])

That's very relevant to your architecture.

Imagine Ali sends you a message while you're looking at the Chats screen.

We don't need to activate the entire:

```text id="pucm4v"
MessageThreadEngine(channelId)
```

for every conversation.

The Chats screen only needs:

```text id="qx4r38"
channel_id
last message
last activity
unread count
sender
mute state
draft
etc.
```

That is a different projection.

---

# 3. Therefore Matchday needs two synchronization scopes

I would evolve the architecture into:

```text id="4munan"
ChatLocalFirstEngine
│
├── InboxSyncEngine
│      └── all conversations / Chats screen
│
└── ThreadSyncSession(channelId)
       └── currently opened conversation
```

This is much cleaner than attaching every chat room in Ably.

---

# 4. Scope 1 — `InboxSyncEngine`

This engine is application-level.

It starts after authentication and remains alive regardless of whether the user is currently on:

```text id="a1xmje"
Feed
Matches
Teams
Chats
Profile
```

because the application still needs to know:

```text id="99bw23"
Ali sent you a message
Team chat has 3 unread
DM moved to top of list
Group avatar changed
Channel was removed
Channel was muted
```

The local source should be a Drift query:

```text id="qbp9q6"
watchChatInbox(userId)
```

and the UI becomes:

```text id="c6o811"
ChatsScreen
     │
     ▼
Riverpod StreamProvider
     │
     ▼
ChatRepository.watchInbox()
     │
     ▼
Drift
```

No Supabase fetch inside the Chats screen.

No Ably listener inside the Chats screen.

---

# 5. The Chats screen should render immediately from Drift

Stream's offline persistence follows exactly this philosophy: its local database stores messages/channels so views can continue to operate without connectivity. ([Stream][1])

So opening Matchday Chats should look like:

```text id="hxz3oi"
Tap Chats
   │
   ▼
Drift query
   │
   ▼
Chats visible immediately

Meanwhile:

InboxSyncEngine
   │
   ├── reconcile with Supabase
   └── consume Ably updates
```

Not:

```text id="xh3l9l"
Tap Chats
   │
   ▼
loading spinner
   │
   ▼
Supabase
   │
   ▼
render
```

Even if the user has no internet:

```text id="hh0l4e"
ChatsScreen
     ↓
cached inbox
```

still works.

---

# 6. The local Chats projection needs slightly different data than the server channel table

I would maintain something close to:

```text id="4q48bo"
local_channels

channel_id
channel_key

kind
context_type
context_id

title
avatar_url

last_message_id
last_message_seq
last_message_preview
last_message_type
last_message_sender_id
last_message_at

unread_count

last_read_seq
last_delivered_seq

pinned_at
archived_at
muted_until

draft_preview

sync_version
last_synced_at
last_accessed_at
```

Some of these are canonical server data.

Others are **local projections** optimized for the Chats screen.

---

# 7. `unread_count` deserves special treatment

This research helped reveal something important.

Because your live architecture uses a **global** message sequence:

```text id="9ml7ri"
Channel A → 100, 105, 110
Channel B → 101, 102, 107
```

we cannot calculate:

```text id="z7jdo7"
unread =
last_message_seq - last_read_seq
```

That would be wrong.

And we also cannot rely entirely on:

```text id="m12qod"
COUNT(local_messages > lastRead)
```

because an unopened conversation may not have every latest message cached locally.

Therefore the Chats projection should keep an authoritative/reconciled:

```text id="gctaa6"
unread_count
```

provided by the inbox synchronization protocol.

Your existing server-side `list_my_chats()` idea is therefore useful.

On reconciliation:

```text id="rqcb1h"
Supabase inbox state
         ↓
channel A unread = 7
channel B unread = 0
channel C unread = 13
         ↓
Drift local_channels
```

Then Ably events adjust it optimistically between reconciliations.

---

# 8. What Ably should do for the Chats screen

I would **not subscribe Flutter to every `chat:<channelId>` room**.

Imagine:

```text id="cr52et"
500 conversations
```

You don't need 500 active Ably chat subscriptions just to render the inbox.

Instead, keep:

```text id="15u4nt"
user:<userId>:chat
```

attached while Matchday is foregrounded.

Your server already has this pattern.

That event stream is essentially:

```text id="5px44d"
My inbox changed.
```

Examples:

```text id="5u84mc"
channel.updated
channel.membership_changed
channel.removed
channel.policy_changed
```

---

# 9. This matches Sendbird's GroupChannelCollection idea

Sendbird keeps its channel collection synchronized independently from the message collection. Its channel collection supports its own pagination and event updates and retrieves data from local cache/server as necessary. ([Sendbird Docs][3])

Our equivalent becomes:

```text id="fyelzd"
Sendbird                    Matchday

GroupChannelCollection  →   InboxSyncEngine
MessageCollection       →   ThreadSyncSession
Local cache             →   Drift
WebSocket               →   Ably
Backend                 →   Supabase
```

This is probably the closest conceptual mapping I found.

---

# 10. Scope 2 — `ThreadSyncSession`

Now suppose the user taps:

```text id="iosr1p"
Ali
"Match tomorrow?"
```

We create:

```text id="wbw39m"
ThreadSyncSession(channelId)
```

This is **screen-specific**.

Its responsibilities are completely different from the inbox engine:

```text id="csraqo"
full messages
attachments
reactions
members
read receipts
delivery receipts
edits
deletes
pagination
scroll anchor
unread boundary
typing
presence
```

---

# 11. Thread screen should also render from Drift first

Suppose you've previously opened Ali's conversation.

You tap it again.

Do:

```text id="hsliwu"
Chat row tapped
     │
     ▼
Navigate immediately
     │
     ▼
Drift cached messages
     │
     ▼
render
```

Meanwhile:

```text id="zd69dl"
ThreadSyncSession
     │
     ├── attach Ably
     ├── reconcile Supabase delta
     └── repair local cache
```

This pattern is extremely close to Sendbird's local caching policy: cached messages can appear immediately and server synchronization subsequently brings the collection current. ([Sendbird][4])

---

# 12. Sendbird has a very useful concept: `startingPoint`

Sendbird's `MessageCollection` doesn't conceptually say:

> Give me the entire conversation.

It initializes around a **starting point** and loads previous/next data as necessary. ([Sendbird Docs][3])

We should copy the concept, not necessarily their API.

For Matchday:

```text id="d5f7tc"
ThreadAnchor
```

could be:

```text id="gjcqqv"
latest
firstUnread
specificMessage
searchResult
notificationTarget
replyTarget
```

This becomes extremely useful.

---

# 13. Opening a chat with unread messages

Suppose:

```text id="1fhn9e"
last_read = message 500

new messages:
510
515
520
530
```

Don't automatically dump the user at:

```text id="9h0s8c"
530
```

and immediately mark everything read.

We can initialize:

```text id="9y6qec"
around first unread
```

like:

```text id="0tzz64"
490
495
500
──────── NEW MESSAGES ────────
510
515
520
530
```

That provides the proper unread boundary.

---

# 14. Stream gives us another important UX rule

Stream Flutter's message list deliberately **does not force the user to the newest message when they're reading older history**. It auto-scrolls for your own new message, or for an incoming message when you're already at the bottom. If you're scrolled back, the view remains where it is. ([Stream][5])

We should copy that.

So:

```text id="vws614"
Thread open
User at bottom
Incoming message
      ↓
show normally
possibly auto-scroll
```

But:

```text id="9rh9uv"
Thread open
User reading 50 messages above bottom
Incoming message
      ↓
DON'T move user
```

Instead:

```text id="13a38g"
       ↓
┌─────────────────┐
│ 3 new messages ↓│
└─────────────────┘
```

This also affects read receipts.

Those new messages are:

```text id="hqzbxb"
delivered ✅

read ❌
```

until actually exposed.

---

# 15. Read state therefore belongs to the viewport, not route opening

This confirms the conclusion from our previous audit.

Stream even exposes behavior such as `markReadWhenAtTheBottom` in its Flutter message-list configuration. ([Stream][6])

So Matchday should have:

```text id="7y61xb"
MessageVisibilityTracker
```

feeding:

```text id="720zw6"
highestConsumedMessageSeq
```

into:

```text id="tq6zh4"
ReceiptCoordinator
```

not:

```text id="04fj18"
ChatScreen.initState()
    ↓
markEverythingRead()
```

---

# 16. One Thread session should have four separate states

I'd model it internally as:

```text id="n8qe8q"
ThreadSessionState

CACHE STATE
    loaded window
    oldest cached
    newest cached

SYNC STATE
    synchronizing
    current
    gap detected

REALTIME STATE
    attaching
    attached
    recovering

VIEW STATE
    scroll anchor
    at latest?
    highest visible
    unread boundary
```

Do not combine those into:

```text id="t1z4jc"
AsyncValue<List<Message>>
```

That is not rich enough for a real messenger.

---

# 17. Message pagination should be local-first too

When user scrolls upward:

```text id="8rz5wh"
Scroll reaches top
      ↓
query older messages from Drift
```

If Drift has more:

```text id="5pxj4t"
display instantly
```

If local history is exhausted:

```text id="1ao8s8"
fetch older server page
      ↓
insert Drift
      ↓
Drift stream updates UI
```

The UI still never directly renders the network response.

Sendbird's MessageCollection follows essentially this two-directional local/server pagination model through `hasPrevious`, `hasNext`, `loadPrevious()` and `loadNext()`. ([Sendbird Docs][3])

---

# 18. Sendbird's gap handling is particularly useful

Sendbird explicitly distinguishes:

```text id="4s3jus"
normal gap
vs
huge gap
```

When connectivity causes a small gap, it synchronizes missing changes. If more than 300 messages are missing, Sendbird considers it a huge gap and recreates the message collection rather than trying to patch everything individually. ([Sendbird Docs][3])

I would borrow the pattern but **not copy the number 300**.

Our server should be able to say:

```text id="m9vzrp"
delta available
```

or:

```text id="7nnzn7"
cursor too old
reset_required
```

Then:

### Normal gap

```text id="dj0sn5"
cursor = 1000

changes:
1001
1002
1003
...
1025

apply incrementally
```

### Huge/expired gap

```text id="33k59v"
cursor no longer valid

       ↓

preserve:
pending messages
outbox
drafts

       ↓

re-bootstrap canonical thread window
```

Crucially, **never delete pending local work** during a reset.

---

# 19. Matrix confirms the delta-sync approach

Matrix's client-server protocol is explicitly designed to support clients that maintain a **full persistent local copy of state**, and its sync protocol provides an initial state followed by incremental deltas. ([Matrix Specification][7])

Modern Matrix/Element X also moved toward Sliding Sync specifically so the client can request only the data needed to render visible parts of the UI instead of downloading everything. ([matrix.org][8])

That reinforces our two scopes:

```text id="ho6lfu"
Inbox:
sync enough to display chat list

Thread:
sync enough to display active timeline
```

Not:

```text id="nmdnss"
Every app resume
→ download every channel
→ download every message
→ recreate entire world
```

---

# 20. This suggests two independent cursors

I would therefore have:

```text id="pmnetb"
local_inbox_sync_state

user_id
last_change_seq
last_full_sync_at
```

and:

```text id="ey9202"
local_thread_sync_state

channel_id
last_change_seq

oldest_loaded_message_seq
newest_loaded_message_seq

has_more_before
has_more_after

last_full_sync_at
last_accessed_at
```

These solve different problems.

---

# 21. Ably recovery fits neatly into this

Ably already handles brief realtime interruptions automatically. Its documentation says disruptions of less than roughly two minutes can be recovered with reattachment and missed-message replay; longer discontinuities need application-level recovery. ([Ably Realtime][9])

That's exactly why our architecture should be:

```text id="qdlv8u"
Short interruption

Ably recovery
      ↓
fast path
```

but:

```text id="vdzfnp"
Long interruption
App killed
Token expired
History unavailable
OS suspended process

      ↓

Supabase delta sync
```

So:

> Ably recovery improves latency. Supabase reconciliation provides correctness.

---

# 22. Chats screen Ably subscription vs Thread subscription

I would now formalize:

```text id="ywldar"
APP FOREGROUND

user:<uid>:chat
       ATTACHED
```

Then:

```text id="5wfxej"
CHATS SCREEN

no additional channel subscription required
```

When opening Channel A:

```text id="u7glat"
user:<uid>:chat
       +
chat:<channelA>
```

When leaving Channel A:

```text id="hwtefz"
detach chat:<channelA>

keep user:<uid>:chat
```

This gives a clean resource model.

---

# 23. Should the personal inbox Ably event contain the full new message?

There are two valid designs.

### Lightweight approach

```text id="70d1g0"
user:<uid>:chat

channel.updated {
   channel_id
   last_message_seq
   preview
   sender
   time
   unread_delta
}
```

This updates only the Chats screen.

Full message arrives when the thread synchronizes.

This is closest to a separate channel-collection/message-collection model.

### Rich local-first approach

The personal inbox event can contain enough normalized message data to also upsert:

```text id="dsr1aa"
local_messages
```

even when the user isn't inside the thread.

That improves offline availability: if the phone loses internet immediately afterward, the newest message can still be opened offline.

Because you already fan out a personal inbox event to every participant, I would lean toward **including a normalized new-message payload**, at least for ordinary private/team chats.

Then:

```text id="z1zg6c"
user event
     │
     ├── update local_channels
     └── upsert local_messages
```

If later scalability for very large channels becomes important, that behavior can differ by channel type.

---

# 24. Stream also validates our per-user database idea

Stream's persistence implementation names local database storage by user and warns about proper disconnect behavior during user switching. ([Stream][1])

So our earlier design:

```text id="78t45v"
matchday_chat_<userId>.sqlite
```

is a very sensible choice.

It prevents:

```text id="guuy4f"
User A logs out
User B logs in
User B sees A's cached chats
```

---

# 25. Stream also uses Drift on a background isolate

This is another direct validation.

Their persistence client has:

```text id="lo9522"
ConnectionMode.background
```

which moves SQLite work to a dedicated isolate to avoid competition with Flutter rendering during large writes and reconnect synchronization. ([Stream][1])

So for Matchday:

```text id="wh39j4"
UI isolate
     │
     ▼
Drift API
     │
     ▼
background database isolate
```

is not speculative architecture. A major Flutter chat SDK uses exactly that model.

---

# 26. Riverpod should not become our local database

Riverpod 3 now has offline persistence, but Riverpod itself marks the feature as **experimental**. ([riverpod.dev][10])

For Matchday I would not persist:

```text id="ydwgbc"
messagesProvider
chatListProvider
threadProvider
```

through Riverpod persistence.

We already have a proper relational database.

Use Riverpod for:

```text id="ihy2to"
binding
lifecycle
controllers
ephemeral UI state
```

and Drift for:

```text id="uh6hja"
messages
channels
receipts
attachments
outbox
drafts
sync cursors
```

Drift's own documentation explicitly notes that watched queries can be consumed through Riverpod `StreamProvider`. ([drift.simonbinder.eu][11])

So the relationship should be:

```text id="8xg4t2"
             DRIFT
               │
             watch()
               │
               ▼
         StreamProvider
               │
               ▼
           Flutter UI
```

---

# 27. This gives us very simple Riverpod providers

Conceptually:

```dart id="04k3fv"
final chatInboxProvider =
    StreamProvider<List<ChatSummary>>((ref) {
  return ref.watch(chatRepositoryProvider).watchInbox();
});
```

And:

```dart id="6e3es9"
final threadMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>(
  (ref, channelId) {
    return ref
        .watch(chatRepositoryProvider)
        .watchThread(channelId);
  },
);
```

These providers shouldn't know:

```text id="lm0fhr"
Ably
Supabase
connectivity
FCM
Outbox
```

They only expose local state.

---

# 28. But the thread Drift query must actually watch all relevant tables

Drift can watch queries across multiple tables; when a watched table changes, the query reruns. ([drift.simonbinder.eu][11])

Therefore don't repeat the earlier pattern:

```text id="yp4qh1"
watch messages
then manually get reactions
then manually get members
```

Instead build a reactive thread projection aware of:

```text id="rs8hro"
local_messages
local_attachments
local_reactions
local_members
local_receipts
```

Then:

```text id="9a0f1o"
Ali reads message
      ↓
local_members changes
      ↓
Drift query emits
      ↓
tick turns blue
```

without any message row changing.

---

# 29. We can even have separate projections

For high performance, I would not necessarily create one monster SQL join.

You can have:

```text id="j7hq8s"
messageStream
receiptStream
reactionStream
attachmentStream
```

and compose them in the repository.

The important invariant is:

> Every durable local change capable of changing the UI must cause the Riverpod-facing state to emit.

---

# 30. Supabase itself acknowledges this local-first architecture pattern

Supabase's PowerSync integration describes essentially:

```text id="vp6qam"
Postgres
   ↕
sync
   ↕
local SQLite

App reads local DB
App writes local DB
Offline writes enter upload queue
```

rather than requiring application UI to query Supabase directly. ([Supabase][12])

Supabase also published a Flutter offline-first example with Brick describing the goal as data parity where the app behaves similarly with or without connectivity. ([Supabase][13])

We're effectively implementing those primitives ourselves because Matchday has custom:

```text id="h9kece"
Ably
message ordering
DM requests
permissions
read receipts
delivery receipts
moderation
```

which make a custom sync layer reasonable.

---

# 31. Another important lesson: background WebSocket behavior

Stream's Flutter core keeps its websocket alive briefly when the application backgrounds—by default about 15 seconds—and then closes it; it reconnects when foregrounded. Its controllers refresh on recovered connections. ([Stream][14])

Ably similarly says mobile operating systems may terminate background connections and recommends explicitly closing when the app no longer needs connectivity and reconnecting on foreground if appropriate. ([Ably Realtime][15])

That tells us not to fight Android/iOS.

I would have:

```text id="sr3e67"
resumed
   ↓
Ably connected

inactive
   ↓
keep connection

paused
   ↓
short grace
   ↓
close / allow suspension
```

Then:

```text id="wh51v5"
resumed again
   ↓
connect
   ↓
attach personal inbox
   ↓
attach active thread if any
   ↓
delta sync
```

Correctness never depends on the background socket surviving.

---

# 32. Notifications: Stream gives us a very useful precedent

Stream's push model sends pushes for new messages to channel members and suppresses them for muted channels/users. For foreground notifications, their Flutter documentation explicitly recommends checking whether the message belongs to the channel already in the foreground before showing a notification. ([Stream][16])

That maps directly to Matchday:

```text id="q2kgcj"
incoming message
      │
      ▼
Server notification engine
      │
      ├── recipient?
      ├── member active?
      ├── blocked?
      ├── channel muted?
      └── notifications enabled?
             │
             ▼
            FCM
```

Then Flutter:

```text id="3r0yol"
FCM foreground
      │
      ├── currentChannel == message.channel
      │       → no notification
      │
      └── different channel
              → in-app/local notification
```

---

# 33. Local cache retention is also something we should design

Sendbird's local cache has a bounded size and can evict messages based on how recently the message collection was accessed. ([Sendbird][4])

We should eventually do similar.

Store all:

```text id="h98sdt"
channel summaries
```

because they're cheap.

But message history can be managed according to:

```text id="op98lm"
recently accessed channels
pinned channels
pending operations
unread messages
draft-referenced messages
```

Never evict:

```text id="5qzg6p"
pending message
failed message
outbox dependency
pending attachment
```

Older synchronized history can safely be removed locally because Supabase remains canonical.

---

# 34. The full architecture after this research

I would now make the Flutter design:

```text id="y5vwqc"
                         APP
                          │
                          ▼
                ChatLocalFirstEngine
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
      InboxSyncEngine           ThreadSessionManager
             │                         │
             │                    open channel A
             │                         │
             ▼                         ▼
 user:<uid>:chat Ably       chat:<channelA> Ably
             │                         │
             └────────────┬────────────┘
                          ▼
                  Realtime Ingestor
                          │
                          ▼
                        DRIFT
            ┌─────────────┴─────────────┐
            │                           │
            ▼                           ▼
       Inbox Query                 Thread Query
            │                           │
            ▼                           ▼
       Riverpod                    Riverpod
            │                           │
            ▼                           ▼
      CHATS SCREEN                 CHAT THREAD
```

And separately:

```text id="xg11er"
                    OutboxProcessor
                          │
                          ▼
                       Supabase
                          │
                          ▼
                      Postgres
                          │
             ┌────────────┴─────────────┐
             │                          │
             ▼                          ▼
           Ably                    Notification job
                                        │
                                        ▼
                                       FCM
```

---

# 35. Chats screen lifecycle

The behavior should be:

| Event                   | Chats screen behavior                                  |
| ----------------------- | ------------------------------------------------------ |
| App launches offline    | Render Drift immediately                               |
| App launches online     | Drift immediately, then inbox sync                     |
| New message in any chat | Personal Ably event updates local channel summary      |
| User already on Chats   | Row moves/rebuilds reactively                          |
| User on Feed            | Drift still updates through engine                     |
| Network drops           | Existing list remains unchanged/usable                 |
| Network returns         | Inbox reconciliation repairs gaps                      |
| User pulls refresh      | Force reconciliation, not bypass Drift                 |
| Pagination              | Local rows first, then fetch older summaries if needed |
| Chat muted              | Persist/update local summary                           |
| User logs out           | Stop engine and close user DB                          |

---

# 36. Thread lifecycle

And:

| Event                         | Thread behavior                                   |
| ----------------------------- | ------------------------------------------------- |
| Tap conversation              | Render cached messages immediately                |
| Thread starts                 | Attach room + reconcile                           |
| Cached unread exists          | Position around unread boundary                   |
| No unread                     | Position at latest                                |
| Scroll upward                 | Page local history first                          |
| Local history exhausted       | Fetch server history → Drift                      |
| Incoming at bottom            | Insert; optionally auto-scroll                    |
| Incoming while scrolled up    | Don't move viewport; show new-message indicator   |
| Incoming while thread visible | Delivered immediately; read only after visibility |
| User sends offline            | Pending local bubble immediately                  |
| Reconnect                     | Outbox retries + reconciliation                   |
| Edit/delete missed            | Delta sync repairs                                |
| Leave screen                  | Flush receipts; detach room                       |
| App backgrounds               | stop read eligibility; retain Drift               |
| App returns                   | attach + reconcile                                |
| Process killed                | local state/outbox survive                        |

This two-screen separation is the most valuable thing the other platforms confirm.

---

# 37. What I would change from our earlier architecture

Earlier we had:

```text id="olymzm"
one ChatSyncCoordinator
```

which was conceptually correct but too broad.

I'd now explicitly split it:

```text id="u00690"
ChatLocalFirstEngine
│
├── InboxSyncEngine
├── ThreadSessionManager
├── OutboxProcessor
├── RealtimeConnectionManager
├── ReceiptCoordinator
├── NotificationCoordinator
└── CacheManager
```

With:

```text id="sqb62f"
InboxSyncEngine
      → long-lived

ThreadSyncSession
      → ephemeral per opened channel

OutboxProcessor
      → long-lived

Drift
      → long-lived

Riverpod screen providers
      → UI lifecycle
```

That is much closer to how mature SDKs separate their internal responsibilities.

---

# The biggest lesson from the research

Stream and Sendbird both independently converge on essentially the same concept:

```text id="fv522u"
CHANNEL COLLECTION
        ≠
MESSAGE COLLECTION
```

Matrix independently converges on:

```text id="0o8mrc"
persistent local state
+
incremental sync cursor
+
only sync what UI needs
```

PowerSync converges on:

```text id="ytrme4"
local SQLite
+
upload queue
+
server reconciliation
```

Ably converges on:

```text id="8gg9dx"
realtime recovery is excellent
but long discontinuities still require application recovery
```

And Stream's Flutter implementation confirms:

```text id="aycp2p"
Drift + background isolate
```

is a legitimate production chat architecture. ([Stream][1])

So I would now define Matchday's frontend around **two local-first read models: Inbox and Thread**, coordinated by one application-level engine. That is more precise than the architecture we had before, and it gives us a very clear basis for implementing the Flutter lifecycle correctly.

[1]: https://getstream.io/chat/docs/sdk/flutter/basics/offline-support/?utm_source=chatgpt.com "Offline Support - Flutter Chat Messaging Docs"
[2]: https://getstream.io/chat/docs/sdk/flutter/stream-chat-flutter/channel-list/stream-channel-list-view/?utm_source=chatgpt.com "StreamChannelListView - Flutter Chat Messaging Docs"
[3]: https://docs.sendbird.com/docs/chat/sdk/v4/flutter/local-caching/overview-local-caching?utm_source=chatgpt.com "Local caching | Chat Flutter SDK | Sendbird Docs"
[4]: https://sendbird.com/docs/chat/sdk/v4/javascript/local-caching/overview-local-caching?utm_source=chatgpt.com "Local caching | Chat JavaScript SDK | Sendbird Docs"
[5]: https://getstream.io/chat/docs/sdk/flutter/stream-chat-flutter/message-list/stream-message-list-view/?utm_source=chatgpt.com "StreamMessageListView - Flutter Chat Messaging Docs"
[6]: https://getstream.io/chat/docs/sdk/flutter/guides/migration-guide-10-0/?utm_source=chatgpt.com "v10.0 - Flutter Chat Messaging Docs"
[7]: https://spec.matrix.org/unstable/client-server-api/?utm_source=chatgpt.com "Client-Server API | Matrix Specification"
[8]: https://matrix.org/blog/2024/10/29/matrix-2.0-is-here/?utm_source=chatgpt.com "Matrix.org - Matrix 2.0 Is Here!"
[9]: https://ably.com/docs/chat/connect?utm_source=chatgpt.com "Ably Chat | Connections"
[10]: https://riverpod.dev/docs/whats_new?utm_source=chatgpt.com "What's new in Riverpod 3.0 | Riverpod"
[11]: https://drift.simonbinder.eu/dart_api/streams/?utm_source=chatgpt.com "Stream queries"
[12]: https://supabase.com/partners/integrations/powersync?utm_source=chatgpt.com "PowerSync | Works With Supabase"
[13]: https://supabase.com/blog/offline-first-flutter-apps?utm_source=chatgpt.com "Building offline-first mobile apps with Supabase, Flutter and Brick"
[14]: https://getstream.io/chat/docs/sdk/flutter/stream-chat-flutter-core/stream-chat-core/?utm_source=chatgpt.com "Chat Client - Flutter Chat Messaging Docs"
[15]: https://ably.com/docs/connect/states?lang=python&utm_source=chatgpt.com "Ably Pub/Sub | Connection state and recovery"
[16]: https://getstream.io/chat/docs/sdk/flutter/guides/push-notifications/?utm_source=chatgpt.com "Push Notifications - Flutter Chat Messaging Docs"


Yes. After checking Meta's own WhatsApp engineering material, I would **not interpret WhatsApp as having two separate local persistence engines for “Chats” and “Chat Thread.”**

What Meta publicly confirms is that each WhatsApp device maintains its **own local database** for message history. When a companion device is linked, recent encrypted message history is transferred to it, decrypted and stored locally; from then on, that device accesses message history from its own local database. ([Engineering at Meta][1])

Meta also says WhatsApp synchronizes other application state independently—things such as archived chats, starred messages, contacts, mute-related state, and similar metadata—across devices. ([Engineering at Meta][1])

So the best-supported picture is:

```text
                 WhatsApp Device

                 LOCAL DATABASE
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
     Chats projection          Thread projection

     chat summaries            messages
     last message              reactions/state
     archived                  receipts
     unread info               attachments
     mute state                etc.
```

What WhatsApp has **not publicly documented** is something like:

```text
ChatsLocalEngine
ThreadLocalEngine
```

as two independent persistence engines.

That distinction is important.

## What I meant earlier by “two engines”

My earlier wording could make it sound like I was proposing:

```text
Inbox database/engine

+

Thread database/engine
```

I am **not** recommending that.

For Matchday, I would use:

```text
                    ONE DRIFT DATABASE
                           │
                           │
               ONE LOCAL-FIRST RUNTIME
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       Inbox Sync Scope          Thread Sync Scope
              │                         │
              ▼                         ▼
         Chats screen             Chat thread
```

So physically:

> **one persistence engine**

but logically:

> **multiple synchronization/read scopes**

That is a much better description.

---

## Why WhatsApp needs different logic even with one database

Consider the WhatsApp Chats screen:

```text
Ali
Hey, are you coming?       10:22     3

Cricket Team
Match tomorrow             09:10     18

Ahmed
Okay                       Yesterday
```

WhatsApp does not need to load thousands of messages from all three conversations to show that.

It only needs something conceptually like:

```text
conversation_id
title
avatar
last_message
last_message_at
unread_count
archived
muted
```

Then you tap Ali.

Now the application needs:

```text
message history
pagination
receipts
attachments
replies
reactions
typing
```

Same underlying local persistence, but a completely different query and synchronization workload.

That's what I mean by **Inbox Scope vs Thread Scope**.

---

# WhatsApp multi-device makes this even clearer

WhatsApp's modern multi-device architecture allows each companion device to connect independently. The phone is no longer required to remain the live source of truth for companion-device operation. Each device receives encrypted messages for itself and keeps synchronized application state. ([Engineering at Meta][1])

Conceptually:

```text
                WhatsApp Servers
                     │
             synchronization
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
      Phone        Desktop      Tablet
        │            │            │
        ▼            ▼            ▼
    Local DB      Local DB      Local DB
```

Not:

```text
Phone
   ↓
all other devices merely query phone DB
```

That was closer to WhatsApp's old architecture; Meta specifically describes moving away from the phone being required as the source for companion-device operation. ([Engineering at Meta][1])

That actually supports our Matchday local-first direction very strongly.

---

# There are multiple sync mechanisms, though

This is where we need nuance.

WhatsApp may have **one local persistence world**, while still having different synchronization pipelines.

Meta explicitly describes at least two categories.

Message-history synchronization:

```text
encrypted recent history
       ↓
new device
       ↓
local message database
```

And application-state synchronization:

```text
archive chat
star message
mute
contacts
etc.
       ↓
encrypted state synchronization
       ↓
other devices
```

([Engineering at Meta][1])

So:

```text
one local store
≠
one synchronization algorithm
```

That's exactly how I want Matchday to work.

---

# Matchday equivalent

You should have:

```text
                   Drift
             ONE LOCAL DATABASE
                    │
       ┌────────────┼────────────┐
       │            │            │
       ▼            ▼            ▼
    Channels     Messages     Members/Receipts
       │            │            │
       └────────────┼────────────┘
                    │
                    ▼
            ChatLocalFirstEngine
                    │
         ┌──────────┴───────────┐
         │                      │
         ▼                      ▼
 InboxSyncCoordinator     ThreadSyncSession
```

These two are **not databases**.

They're coordinators.

---

## `InboxSyncCoordinator`

Application-scoped:

```text
starts after login
stays alive in foreground
```

It handles:

```text
Chats screen summaries
last message
unread count
channel ordering
archived
mute
membership changes
new-conversation appearance
```

Using mostly:

```text
user:<uid>:chat
```

plus Supabase reconciliation.

---

## `ThreadSyncSession(channelId)`

Created when:

```text
user opens Channel A
```

It handles:

```text
message timeline
pagination
typing
read receipts
delivery receipts
reactions
attachments
edits
deletes
```

and attaches:

```text
chat:<channelId>
```

When the user leaves the thread:

```text
ThreadSyncSession disposed
```

but the database remains.

Inbox synchronization remains alive.

---

# The database is shared

Suppose Ali sends:

```text
"Match at 5?"
```

while you're on the Feed.

Your Inbox coordinator receives it and may write:

```text
local_channels
    last_message = "Match at 5?"
    unread = 1
```

and ideally:

```text
local_messages
    M500 = "Match at 5?"
```

Now later you open Ali.

The Thread session does **not create another storage system**.

It queries:

```text
local_messages
WHERE channel_id = Ali
```

and the message is already there.

That is the architecture we want.

---

# One reason two persistence engines would actually hurt us

Imagine this:

```text
ChatsEngine DB

Ali
last_message = "Hello"
unread = 1
```

while:

```text
ThreadEngine DB

Ali
latest = "Match tomorrow?"
```

Now you need synchronization **between your own two local databases**.

That's needless complexity.

With Drift:

```text
ONE transaction
```

can update:

```text
local_messages

AND

local_channels
```

atomically.

For example:

```text
BEGIN LOCAL TRANSACTION

UPSERT message M500

UPDATE channel
SET
    last_message_id = M500,
    last_message_preview = "Match tomorrow?",
    last_message_seq = 500

COMMIT
```

Then both screens automatically observe the same truth.

That's much stronger.

---

# A useful Meta precedent

This next point is **Messenger rather than WhatsApp**, so I wouldn't use it as proof of WhatsApp's exact implementation, but it's useful architectural evidence from the same company.

When Meta rebuilt Messenger in Project LightSpeed, they explicitly described replacing many separate feature caches with **SQLite as a universal local system** supporting different application features and queries. ([Engineering at Meta][2])

Their reasoning was essentially:

```text
don't create independent caches everywhere

use one transactional local database
```

That principle aligns almost perfectly with what we're designing for Matchday.

Again, that's Messenger, not confirmation of WhatsApp's internal DB implementation—but it's a strong architecture precedent.

---

# Therefore I would slightly rename our components

Instead of saying:

```text
InboxSyncEngine

ThreadSyncEngine
```

because “engine” makes them sound independent, I'd use:

```text
ChatLocalFirstEngine
│
├── InboxCoordinator
│
├── ThreadSessionManager
│
├── RealtimeCoordinator
│
├── SyncCoordinator
│
├── OutboxProcessor
│
├── ReceiptCoordinator
│
└── NotificationCoordinator
```

Then:

```text
ThreadSessionManager
    ├── Channel A session
    └── maybe Channel B session briefly during navigation
```

while everything writes into:

```text
ONE Drift database
```

That terminology better reflects the architecture.

---

# So for Matchday

The model I now recommend is:

```text
                         MATCHDAY

                ChatLocalFirstEngine
                         │
                         │
                  ONE DRIFT DB
                         │
               ┌─────────┴─────────┐
               │                   │
               ▼                   ▼
          Chats Query         Thread Query
               │                   │
               ▼                   ▼
        ChatsScreen          ChatThreadScreen


     synchronization coordinators around the DB

               ┌──────────────────────┐
               │ InboxCoordinator     │
               │ ThreadSessionManager │
               │ OutboxProcessor      │
               │ RealtimeCoordinator  │
               │ ReceiptCoordinator   │
               └──────────────────────┘
```

So the answer to your question is:

> **No public WhatsApp source I found says it uses two independent local persistence engines for Chats and Chat Thread. Meta explicitly says a device accesses WhatsApp message history from its own local database. The stronger architectural interpretation is one device-local persistence layer with several synchronization/state mechanisms and different projections for different screens.** ([Engineering at Meta][1])

And that's also what I would do for Matchday: **one Drift database + one application-level local-first engine; Chats and Chat Thread get separate coordinators/read models, not separate persistence engines.**

[1]: https://engineering.fb.com/2021/07/14/security/whatsapp-multi-device/?utm_source=chatgpt.com "How WhatsApp enables multi-device capability - Engineering at Meta"
[2]: https://engineering.fb.com/2020/03/02/data-infrastructure/messenger/?utm_source=chatgpt.com "Project LightSpeed: Rewriting Messenger to be faster, smaller, and simpler"

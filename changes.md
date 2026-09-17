You are working on the Matchday Flutter application.

Repository:
MuhammadSaranKhalid/matchday

Branch:
feat/chat-local-first-runtime

STACK
- Flutter
- Riverpod
- Drift / SQLite
- Supabase
- Ably
- FCM
- Clean Architecture

IMPORTANT WORKING RULES

Do NOT blindly implement this prompt.

Before changing anything:
1. Read the current implementation end-to-end.
2. Inspect the exact database schema, Drift migrations, Supabase RPCs, Ably publishers/events, Riverpod lifecycle, app lifecycle, and tests.
3. Compare this specification against the live code.
4. If an assumption in this specification is no longer true, adapt the implementation rather than forcing the old assumption.
5. Search current official documentation for Drift/Riverpod/Ably APIs if uncertain.
6. Preserve existing working behavior.
7. Do not replace the architecture with a simpler online-only implementation.
8. Use TDD for behavioral changes.
9. Run code generation, flutter analyze, and relevant tests after changes.
10. Do not make unrelated refactors.

The architectural invariant is:

Flutter UI
    ↓
Riverpod
    ↓
Repository
    ↓
Drift

The UI must NEVER use Supabase or Ably as a durable read source.

Supabase = canonical durable server authority.
Drift = canonical device-side durable UI source.
Ably = realtime transport/invalidation.
FCM = wake/attention mechanism.
Outbox = durable local write intent.

We want ONE Drift database and ONE application-level chat runtime.
Do NOT build separate persistence engines for Inbox and Thread.

======================================================================
TARGET ARCHITECTURE
======================================================================

Create an application-scoped:

ChatLocalFirstEngine

with responsibilities coordinated through focused components:

ChatLocalFirstEngine
├── InboxCoordinator / existing syncInbox flow
├── CatchUpScheduler
├── Thread session/openChannel flow
├── RealtimeIngestor
├── OutboxProcessor
├── ReceiptCoordinator
└── local Drift database

The Chats screen must become a passive Drift projection.

The Thread screen must also remain a Drift projection.

Opening the Chats screen must NOT be what starts the chat subsystem.

ChatLocalFirstEngine must start automatically for an authenticated user
at app scope.

======================================================================
1. FIX THE LOCAL INBOX PROJECTION
======================================================================

Current problem:

LocalChannels only contains fields such as:

- lastMessageSeq
- lastMessageAt

and ChatLocalDataSource.watchInbox() queries LocalMessages per channel to
derive:

- latest message body
- latest sender
- unread count

This is wrong for a partial-cache architecture because unopened channels
may not have all messages locally.

It also creates N+1 SQLite queries.

Modify LocalChannels so it contains the authoritative inbox projection.

Add at minimum:

lastMessagePreview      TextColumn nullable
lastMessageSenderId     TextColumn nullable
lastMessageFromMe       BoolColumn default false
unreadCount             IntColumn default 0

Preserve any additional metadata needed by ChatChannel/Chat UI.

Increment Drift schema version from 11 to 12.

Do NOT recreate all chat tables for this migration.

Use addColumn for safe additive migration where possible.

Run Drift generation afterward.

Update:

lib/core/database/tables.dart
lib/core/database/app_database.dart
generated Drift files

Update ChatLocalDataSource.upsertChannelsFromDto() so list_my_chats values
are persisted directly:

dto.lastMessageSeq
dto.lastMessageAt
dto.lastMessageBody
dto.lastMessageSenderId
dto.lastMessageFromMe
dto.unreadCount

Then rewrite watchInbox() so Inbox does NOT query LocalMessages once per
channel to reconstruct summary/unread state.

Inbox should primarily be:

LocalChannels
LEFT JOIN current LocalChannelMember

and build ChatChannel using the projection stored in LocalChannels.

LocalMessages may still be used by Thread, but Inbox correctness must NOT
depend on LocalMessages being complete.

======================================================================
2. REMOVE THE INVALID GLOBAL-SEQUENCE UNREAD CALCULATION
======================================================================

There is currently logic equivalent to:

lastReadSeq = lastMessageSeq - unreadCount

REMOVE THIS COMPLETELY.

Matchday uses a GLOBAL message_seq.

Example:

channel messages:

900
925
970

unread_count = 2

970 - 2 = 968

968 is NOT the read horizon.

Global sequence gaps are expected.

Never derive a read/delivered horizon from a count.

If list_my_chats currently does not expose exact membership horizons,
inspect the Supabase RPC and extend it to return:

last_read_message_seq
last_read_at
last_delivered_message_seq
last_delivered_at

These values already belong conceptually to channel_members.

Update ChatChannelDto accordingly.

Persist exact values into LocalChannelMembers.

Authoritative inbox unread_count remains an independent value.

If backend changes are required, add a migration that updates the RPC
without breaking existing consumers.

Do not estimate horizons.

======================================================================
3. ACTUALLY USE ChannelSyncStates
======================================================================

ChannelSyncStates already exists:

channelId
newestSyncedMessageSeq
oldestCachedMessageSeq
hasMoreHistory
lastMemberSyncAt
lastFullSyncAt
syncStatus
lastSyncError

Currently openChannel() finds MAX(LocalMessages.messageSeq).

Stop using LocalMessages as the synchronization cursor.

Cache eviction and synchronization knowledge are different concepts.

Use:

ChannelSyncStates.newestSyncedMessageSeq

as the forward-sync cursor.

Add focused ChatLocalDataSource APIs similar to:

Future<ChannelSyncStateRow?> getChannelSyncState(String channelId)

Future<void> markChannelSyncStarted(String channelId)

Future<void> markChannelSyncSucceeded(
  String channelId, {
  required int newestSeq,
  int? oldestSeq,
})

Future<void> markChannelSyncFailed(
  String channelId,
  Object error,
)

When server messages are committed into Drift, updating the sync cursor
must happen in the SAME Drift transaction.

Rule:

server messages persisted successfully
    THEN cursor advances

Never:

cursor advances
    THEN messages are written

Cursor advancement must be monotonic:

newest = max(oldNewest, newNewest)

Old-history hydration should maintain:

oldestCachedMessageSeq = min(oldOldest, fetchedOldest)

Global message_seq values do NOT need to be consecutive.

======================================================================
4. ADD A BOUNDED CatchUpScheduler
======================================================================

Create a focused file, preferably:

lib/features/messages/data/sync/catch_up_scheduler.dart

It must hydrate recent/missing messages for conversations WITHOUT
requiring the user to open them.

Do NOT preload complete history.

Do NOT implement:

top 15 chats only

as the architectural guarantee.

All active conversations should eventually be eligible.

Priorities:

1. current/notification-target channel
2. channels with unreadCount > 0
3. pinned channels
4. recently active channels
5. remaining active non-archived channels

Use bounded concurrency.

Target:
3 concurrent channel catch-ups

Make this configurable as a small constant.

Each channel itself must be synchronized serially.

Do not start multiple simultaneous catch-ups for the same channel.

The scheduler must be single-flight/idempotent.

======================================================================
5. INITIAL CHANNEL BOOTSTRAP MUST NOT DOWNLOAD ENTIRE HISTORY
======================================================================

A channel with no ChannelSyncState must NOT call:

fetchDeltaMessages(channelId, 0)

if that means downloading years of history.

For a never-synced channel:

fetch a recent window only.

Recommended initial window:

50 messages

Implement a remote method such as:

fetchRecentMessages(
  String channelId, {
  int limit = 50,
})

Server query:

channel_id = target
ORDER BY message_seq DESC
LIMIT 50

then reverse to chronological order locally.

Persist those rows and initialize:

newestSyncedMessageSeq = max fetched seq
oldestCachedMessageSeq = min fetched seq
hasMoreHistory = fetchedCount == limit

For an already initialized channel:

fetch only:

message_seq > newestSyncedMessageSeq

======================================================================
6. PAGINATE FORWARD DELTA CATCH-UP
======================================================================

Current fetchDeltaMessages has no explicit page bound.

Change it to support a limit, e.g.:

fetchDeltaMessages(
  channelId,
  afterSeq, {
  int limit = 100,
})

Process long offline gaps page-by-page.

Example:

cursor = 1000

fetch > 1000 LIMIT 100
persist transaction
advance cursor
fetch > newCursor LIMIT 100
...

Stop when:

- returned page < page size
OR
- cursor reaches/exceeds server lastMessageSeq

Do not require sequence numbers to be consecutive.

Do not use OFFSET pagination.

======================================================================
7. CHANGE syncInbox() RESPONSIBILITY
======================================================================

syncInbox() should remain lightweight.

Its responsibility is:

Supabase list_my_chats
    ↓
authoritative channel metadata / projection
    ↓
Drift LocalChannels / LocalChannelMembers

It should NOT download complete message histories.

After syncInbox completes, CatchUpScheduler decides which message gaps need
hydration.

syncInbox must remain safe to call on:

- authenticated startup
- app resume
- offline → online
- manual pull-to-refresh
- notification target bootstrap
- recovery after realtime disconnection

======================================================================
8. CREATE APPLICATION-LEVEL ChatLocalFirstEngine
======================================================================

Create something similar to:

lib/features/messages/data/sync/chat_local_first_engine.dart

or another location consistent with the repo's architecture.

Expose it through a keepAlive Riverpod provider.

Activate it from MatchdayApp, similar to how PushRegistrar is already
activated globally.

Currently app.dart watches pushRegistrarProvider.

Also activate:

chatLocalFirstEngineProvider

Do not make InboxScreen responsible for bootstrapping chat.

ChatLocalFirstEngine should observe:

- authenticated user
- app lifecycle/resume
- connectivity
- Ably lifecycle where needed

Existing providers already include:

currentUserStreamProvider
isOnlineProvider
app resume/lifecycle infrastructure

Use them instead of introducing duplicate lifecycle systems.

On authenticated session startup:

1. start user-level Ably inbox subscription
2. recover stale Outbox processing rows
3. syncInbox()
4. run catch-up scheduling
5. drain Outbox

Ordering note:

attach the personal realtime channel BEFORE the network reconciliation,
so this race cannot occur:

fetch snapshot
message arrives
subscribe later
message missed

Preferred:

attach user realtime
then reconcile

Any event received during reconciliation must be idempotently upserted.

======================================================================
9. REMOVE CHAT BOOTSTRAP SIDE EFFECTS FROM ChatRepositoryImpl
======================================================================

Current ChatRepositoryImpl constructor:

- starts Outbox
- subscribes user inbox

Move application lifecycle ownership into ChatLocalFirstEngine.

Repository construction should not start a session.

Also remove the need for watchInbox() to call syncInbox() just because a UI
consumer subscribed.

watchInbox() should become essentially:

return local.watchInbox(currentUserId)

The app engine performs background synchronization.

watchMessages() may still initiate/open a thread-specific session because
opening a Thread raises that channel's priority and attaches its hot
chat:<channelId> subscription.

But the thread must render cached Drift data immediately.

======================================================================
10. FIX USER-LEVEL ABLY INBOX HANDLING
======================================================================

Current user:<userId>:chat handling calls updateChannelSummaryFromRealtime()
and can insert a partial/stub row into LocalMessages.

Do NOT insert incomplete message stubs into LocalMessages.

A partial message row can later be mistaken for a complete canonical
message.

Change behavior:

user-level event
    ↓
update LocalChannels inbox projection
    ↓
schedule targeted catch-up(channelId)

Only upsert directly into LocalMessages if the user-level event contains a
COMPLETE normalized ChatMessageDto payload.

Otherwise LocalMessages must be filled through:

- channel realtime full message event
or
- Supabase reconciliation

The user's Ably inbox subscription also needs:

unsubscribeFromUserInbox()

and it should track which user owns the current subscription.

This is required for logout/account switching.

Do not let a previous user's user:<id>:chat subscription survive logout.

======================================================================
11. STOP CALLING syncInbox() AFTER EVERY NORMAL ABLY EVENT
======================================================================

Current repository wiring effectively causes:

user inbox event
    ↓
syncInbox()
    ↓
list_my_chats()

for normal realtime updates.

Do not perform a full inbox RPC after every message event.

Normal event path:

Ably channel.updated
    ↓
update local inbox projection
    ↓
targeted CatchUpScheduler.enqueue(channelId)

Full syncInbox should be reserved for reconciliation lifecycle events or an
event whose payload cannot be trusted/understood.

If the server's user-specific channel.updated event can easily include:

unread_count
last_message_seq
last_message_at
last_message_body
last_message_sender_id
last_message_from_me
counts_as_unread

then add those fields to the server event.

Prefer recipient-specific authoritative unread_count.

If the event cannot provide unread_count, update local unread count
idempotently only when a strictly newer unread incoming message arrives,
then allow the next syncInbox reconciliation to correct it.

Never derive unread count from partial LocalMessages.

======================================================================
12. OPEN THREAD SHOULD USE THE SAME SYNC PRIMITIVE
======================================================================

Do not maintain one synchronization algorithm for background catch-up and
another for openChannel.

Create/reuse a common method conceptually like:

syncChannelForward(
  channelId,
  currentUserId, {
  priority,
})

openChannel should:

1. set/raise current thread priority
2. subscribe chat:<channelId>
3. run syncChannelForward()
4. drain relevant Outbox lane if needed

Closing the thread should:

unsubscribe chat:<channelId>

but MUST NOT remove messages from Drift or disable global catch-up.

Chats and Thread are two projections over the same local store.

======================================================================
13. DELIVERY ACKNOWLEDGEMENTS MUST USE THE OUTBOX
======================================================================

This is critical.

Current RealtimeIngestor:

message.created
    ↓
persist in Drift
    ↓
update local delivered horizon
    ↓
onMessageDelivered
    ↓
remote.markChannelDelivered()

That direct RPC is not durable.

If internet disappears after persistence, the server may never receive the
delivery acknowledgement.

Create a ReceiptCoordinator or equivalent focused abstraction.

Recommended file:

lib/features/messages/data/sync/receipt_coordinator.dart

Required behavior:

markDelivered(channelId, userId, seq)

must:

1. monotonically update LocalChannelMembers.lastDeliveredMessageSeq
2. enqueue Outbox operation:
   operation_type = mark_delivered
   coalesce_key = delivered:<channelId>
   payload = {through_seq: maxSeq}
3. notify OutboxProcessor

All in durable local state before relying on network.

Same rule for messages downloaded during catch-up:

Supabase delta
    ↓
Drift transaction succeeds
    ↓
queue delivered(maxReceivedSeq)
    ↓
Outbox retries until server accepts

Ably publish ACK is NOT message delivery.

Delivery semantic remains:

recipient device successfully persisted the message locally.

======================================================================
14. READ RECEIPTS MUST ALSO FLOW THROUGH ReceiptCoordinator
======================================================================

Move repository read/delivered write mechanics into ReceiptCoordinator
where practical.

markRead must:

- be monotonic
- update local read horizon
- also guarantee delivered horizon >= read horizon
- enqueue a coalesced mark_read Outbox op
- not call network directly

Do not update timestamp/horizon when sequence does not advance.

If read through LocalChannels.lastMessageSeq, local inbox unreadCount can
safely become zero.

If read only through part of a channel, decrement unread based only on
newly consumed locally known incoming messages; never fabricate a horizon
from unreadCount.

The next server inbox reconciliation remains authoritative.

======================================================================
15. FIX OUTBOX CRASH RECOVERY
======================================================================

Current OutboxProcessor changes an operation to:

processing

before network execution.

If the OS kills the process at that moment, getPendingOperations() ignores
the row forever.

Add a recovery API to ChatLocalDataSource, e.g.:

recoverStaleProcessingOperations(
  Duration lease,
)

Use updatedAt.

Example lease:

2 minutes

Any:

status = processing
AND updated_at < now - lease

becomes:

status = pending
next_attempt_at = null

Do this on ChatLocalFirstEngine startup before the first drain.

It may also be run on resume safely with the age threshold.

Do not reset a genuinely active recent operation.

======================================================================
16. CONNECTIVITY RESTORATION MUST TRIGGER RECONCILIATION
======================================================================

isOnlineProvider already exists.

Use it.

When:

offline → online

ChatLocalFirstEngine should single-flight:

syncInbox()
catchUpScheduler.run()
outbox.drain()

Do not rely only on:

- screen opening
- Ably reconnect
- retry timer

Those are not the same as durable reconciliation.

======================================================================
17. APP RESUME MUST TRIGGER ONE RECONCILIATION PIPELINE
======================================================================

There is currently resume logic in AblyService / ChatSyncCoordinator.

Avoid two or three independent resume implementations.

Consolidate chat reconciliation under ChatLocalFirstEngine.

On resume:

ensure realtime reconnect
sync inbox
catch up missing deltas
recover stale outbox if appropriate
drain outbox

If an active thread exists, give it highest catch-up priority.

Make the operation single-flight.

If resume/network/auth triggers arrive simultaneously, they should collapse
into one reconciliation pass rather than performing duplicate full syncs.

======================================================================
18. FIX editMessage DOUBLE NETWORK PATH
======================================================================

Current ChatRepositoryImpl.editMessage():

queues an edit Outbox operation

AND then immediately calls:

_remote.editChannelMessage(...)

This violates the single durable write path.

Fix it.

Required model:

UI
    ↓
optimistic Drift update
    ↓
Outbox edit operation
    ↓
OutboxProcessor
    ↓
Supabase
    ↓
server confirmation / realtime
    ↓
Drift

Do not issue the same edit from both repository and Outbox.

Also do not use:

channelId = ''

for an edit operation if the message's channel is known.

Read the message's local channelId and preserve the correct Outbox lane.

Per-channel FIFO must include edits/deletes/reactions where possible.

======================================================================
19. FIX RETRY MESSAGE BEHAVIOR
======================================================================

Inspect retryMessage() carefully.

Currently changing LocalMessage.syncStatus back to pending is not enough if
its Outbox operation is still:

status = failed

because getPendingOperations() does not process failed rows.

Retry must atomically:

message.syncStatus = pending
failed send Outbox operation.status = pending
attemptCount reset appropriately
last error cleared
nextAttemptAt cleared

Then notify Outbox.

Add a regression test.

======================================================================
20. OUTBOX COALESCING
======================================================================

Preserve/use coalescing semantics.

For delivery:

delivered:<channelId>

only the maximum through_seq matters.

For read:

read:<channelId>

only the maximum through_seq matters.

When replacing a pending/retry receipt operation, never replace a larger
through_seq with a smaller one.

Current generic coalescing deletes the old operation and inserts the new
one.

Improve receipt coalescing so:

max(oldThroughSeq, newThroughSeq)

wins.

Do not let an out-of-order callback move receipt intent backwards.

======================================================================
21. DO NOT PRELOAD COMPLETE MESSAGE HISTORY
======================================================================

This is a hard constraint.

The autonomous engine should make recent conversations feel instant, not
mirror the complete server archive.

Target local behavior:

- recent window locally
- all newly arriving messages from then onward
- unread/missed deltas
- user-loaded older pages

Older history stays server-paginated and is inserted into Drift on demand.

Do not implement "download every message from every channel".

======================================================================
22. OLDER MESSAGE PAGINATION
======================================================================

loadOlderMessages should use ChannelSyncStates.oldestCachedMessageSeq when
available rather than rediscovering it from the table every time.

Fetch:

message_seq < oldestCachedMessageSeq
ORDER BY message_seq DESC
LIMIT 50

Insert into Drift.

Update:

oldestCachedMessageSeq

and:

hasMoreHistory = fetchedCount == 50

No OFFSET.

Do not alter newestSyncedMessageSeq while loading older history.

======================================================================
23. THREAD READ TRACKING MUST NOT MEAN “ROUTE OPEN = READ”
======================================================================

Current MessageThreadScreen marks read when initial messages appear and the
scroll position is near the bottom.

Replace that approximation.

Read requires:

- app lifecycle = resumed
- thread route actually visible
- message region actually visible/consumed
- incoming server-confirmed message
- advance only through the highest actually visible message seq

Introduce a focused ThreadReadTracker/viewport mechanism.

Do NOT mark all messages read merely because:

- provider loaded
- route was constructed
- network response completed

If the user is reading older history and new messages arrive:

do not autoscroll
do not mark those new messages read

continue showing the existing “N new messages” behavior.

When the user scrolls to and actually sees them, advance the read horizon.

Avoid marking read while app is inactive/paused/covered.

If an additional Flutter visibility package is required, check the latest
compatible package/API before adding it. Prefer a small focused solution.

======================================================================
24. PRESERVE NEW-MESSAGE SCROLL BEHAVIOR
======================================================================

Keep:

if user is near latest messages:
    new message can remain in normal latest flow

if user is scrolled into history:
    do NOT snap them to bottom
    increment N new messages indicator

Only consumption/visibility should advance read.

======================================================================
25. FIX DURABILITY OF OFFLINE IMAGE FILES
======================================================================

Current ChatRepositoryImpl stores an outgoing image in:

getTemporaryDirectory()

That is unsafe for a durable Outbox because the OS may purge temporary
files.

Use a persistent application-support/documents location for unsent chat
attachments.

Suggested structure:

<app-support>/chat_outbox/<userId>/<channelId>/<attachmentId>.<ext>

AttachmentId/messageId should make the path deterministic.

When upload is confirmed and local retention is no longer required, clean
up the outbox file intentionally.

Do not rely on OS temporary storage for pending durable operations.

======================================================================
26. DO NOT USE THE PUBLIC avatars BUCKET FOR CHAT MEDIA
======================================================================

Current chat media upload uses the public:

avatars

bucket.

That must not be the final chat-media architecture.

Inspect existing Supabase storage setup first.

Create/use a dedicated private bucket such as:

chat-media

Store storage_path, not a permanent public URL.

Path pattern should be deterministic and authorization-friendly, e.g.:

channels/<channelId>/<messageId>/<attachmentId>.<ext>

Provide signed URLs only when rendering/downloading authorized media.

Add appropriate Storage RLS/policies based on channel visibility/membership.

Do not blindly expose private team/DM media publicly.

If this backend change is large, implement it in a separate commit but keep
it in this branch after the runtime is stable.

======================================================================
27. FCM MUST REMAIN NON-CANONICAL
======================================================================

Do not insert FCM payloads directly as canonical messages.

FCM remains:

wake / attention / navigation

On notification tap:

initialize auth
initialize Drift
initialize ChatLocalFirstEngine
prioritize target channel
reconcile target
navigate/render from Drift

If the user is already viewing that same visible thread in foreground,
suppress the redundant foreground notification banner where practical.

======================================================================
28. ACCOUNT SWITCHING / LOGOUT
======================================================================

The app already clears local DB state on logout.

Ensure ChatLocalFirstEngine additionally:

- unsubscribes user Ably inbox
- unsubscribes active chat room
- stops session-specific callbacks/timers
- prevents old user's catch-up from writing after logout
- stops/invalidates current reconciliation token

Any async response from user A must not be allowed to populate the database
after user B signs in.

Use a session generation/token if necessary.

======================================================================
29. KEEP THE UI LOCAL-FIRST
======================================================================

After this work:

InboxScreen must NOT manually fetch messages.

MessageThreadScreen must NOT render a Supabase result directly.

Expected paths:

INBOX

Supabase / Ably
      ↓
ChatLocalFirstEngine
      ↓
Drift
      ↓
Riverpod
      ↓
InboxScreen

THREAD

Supabase / Ably
      ↓
sync / realtime ingestor
      ↓
Drift
      ↓
Riverpod
      ↓
MessageThreadScreen

Typing/presence are allowed to stay ephemeral and do not need Drift.

======================================================================
30. REALTIME IDEMPOTENCY
======================================================================

The following must all be safe:

HTTP RPC response arrives first
Ably echo arrives later

or:

Ably echo arrives first
HTTP response arrives later

or:

same Ably event delivered twice

or:

reconciliation fetch contains a message already ingested through Ably

Use message_id UUID as identity.

Never duplicate a message.

Server message_seq remains authoritative ordering.

Use monotonic message versioning for mutable events.

Do not allow an older edit/delete/reaction event to overwrite newer local
state.

======================================================================
31. TESTS REQUIRED
======================================================================

Do not consider implementation complete without automated tests.

At minimum add/modify tests for these behaviors:

A. Inbox projection works with ZERO LocalMessages:
   list_my_chats DTO has:
   last body = "hello"
   unread_count = 4

   LocalMessages empty.

   watchInbox must still show:
   preview "hello"
   unread = 4

B. Global sparse sequence:
   last_message_seq = 970
   unread_count = 2

   code must NOT create read horizon 968.

C. Existing sync cursor:
   newestSyncedMessageSeq = 100

   catch-up calls delta > 100.

D. Fresh unsynced channel:
   does NOT fetch delta > 0 without limit/full history.
   fetches recent bounded bootstrap page.

E. Multi-page forward catch-up:
   cursor advances only after each page is persisted.

F. Duplicate message:
   realtime + delta same message_id => one local row.

G. Stale Outbox:
   processing row older than lease becomes pending.

H. Fresh processing Outbox:
   does NOT get reset.

I. Delivered receipt:
   incoming persisted message creates/coalesces mark_delivered Outbox op.
   remote RPC is not required at ingestion time.

J. Receipt monotonicity:
   delivered 500 followed by delivered 450 keeps 500.

K. Read monotonicity:
   read horizon never decreases.

L. Network restoration:
   offline → online triggers one reconciliation pass.

M. Multiple triggers:
   resume + online transition at same time do not create two concurrent
   full sync passes.

N. Repository watchInbox:
   local subscription does not require network call.

O. Failed send retry:
   resets/requeues failed Outbox operation.

P. editMessage:
   only one server write path exists.

Q. account switch:
   old-user async work cannot write into new-user session.

R. older pagination:
   updates oldestCachedMessageSeq but does not move newest cursor backward.

S. read tracking:
   route open alone does not mark latest unread message read.

T. app background:
   visible thread does not advance read while app is not resumed.

======================================================================
32. EXISTING TESTS MUST CONTINUE TO PASS
======================================================================

At minimum run:

flutter pub get

dart run build_runner build --delete-conflicting-outputs

flutter analyze

flutter test test/features/messages

and ideally the full:

flutter test

Do not modify generated files manually.

Regenerate:

*.g.dart
*.freezed.dart

with build_runner.

======================================================================
33. IMPLEMENTATION ORDER
======================================================================

Implement in this order so failures remain understandable:

Phase 1
- LocalChannels authoritative inbox projection
- schema v12
- remove lastSeq - unreadCount
- exact horizon DTO/RPC if needed
- inbox tests

Phase 2
- ChannelSyncStates integration
- bounded recent bootstrap
- paginated forward delta
- CatchUpScheduler
- catch-up tests

Phase 3
- ChatLocalFirstEngine
- auth startup
- user Ably attach-before-reconcile
- connectivity restoration
- app resume
- single-flight reconciliation
- app bootstrap tests

Phase 4
- ReceiptCoordinator
- durable delivered/read Outbox
- remove direct delivery RPC path
- receipt tests

Phase 5
- stale Outbox recovery
- retryMessage repair
- editMessage single-path fix
- tests

Phase 6
- realtime inbox targeted catch-up
- remove partial LocalMessages stubs
- avoid list_my_chats on every Ably event
- tests

Phase 7
- viewport-driven Thread read tracking
- lifecycle gating
- tests

Phase 8
- durable attachment local path
- private chat-media storage
- signed URLs / policies
- tests where practical

Do NOT begin a later phase while the previous phase is failing.

======================================================================
34. DEFINITION OF DONE
======================================================================

The architecture is complete only when these scenarios work:

1. Launch app offline:
   cached Inbox renders immediately.

2. Open cached Thread offline:
   cached messages render immediately.

3. User stays away from a conversation:
   new messages still become locally available through user realtime +
   autonomous catch-up.

4. App is offline for hours:
   on resume/network return, missed messages are progressively reconciled.

5. Conversation #50 is eventually caught up too.
   No permanent top-15 rule.

6. Full history of all conversations is NOT automatically downloaded.

7. Opening a warmed conversation usually requires no initial network wait.

8. Sending offline:
   pending bubble + Outbox survive process restart.

9. Process dies while Outbox operation = processing:
   operation is recoverable.

10. Ably event + HTTP response:
    no duplicate.

11. Realtime gap:
    Supabase catch-up repairs it.

12. Incoming message persisted:
    delivered acknowledgement survives offline/network failure.

13. App receives message while another screen is open:
    delivered but not read.

14. Thread route exists but app goes background:
    messages are not marked read.

15. User reads older history:
    new incoming messages do not force autoscroll/read.

16. Inbox unread count is correct even when full local message history is not
    present.

17. Logout/login as another user:
    no previous account data/subscriptions leak.

18. UI durable state always comes from Drift.

======================================================================
35. IMPORTANT NON-GOALS
======================================================================

Do NOT:

- create separate Inbox and Thread databases
- use Ably as durable storage
- use FCM as canonical message storage
- subscribe to every chat room permanently
- download all message history
- calculate read horizon from unread count
- calculate unread count from an incomplete local message cache
- let Screens own synchronization lifecycle
- use OFFSET for message pagination
- mark a thread read merely because it opened
- make realtime the only recovery mechanism
- bypass the Outbox for durable mutations
- add a second direct network path for an Outbox operation
- silently change Supabase security/RLS without reviewing it

======================================================================
FINAL DELIVERABLE FROM YOU
======================================================================

After implementation provide:

1. Exact files changed.
2. Any Supabase migration/RPC/storage changes.
3. Updated architecture flow.
4. Tests added.
5. Commands executed.
6. Test/analyze results.
7. Any assumptions or unresolved risks.
8. Any deliberate deviations from this specification and why.
9. A concise before/after explanation of Inbox sync, Thread sync, Outbox,
   receipts, Ably, connectivity, and lifecycle behavior.

Do not simply say “implemented successfully.”
Show evidence.
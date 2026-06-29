---
name: push-notifications
description: The end-to-end push/notification pipeline for MatchDay (FCM + device_tokens + send-push edge function + in-app notifications + deep-link-on-tap). Use whenever adding a NEW notification type (e.g. the match-pool's response/selection notifications), modifying push delivery, or debugging notifications not arriving.
---

# Push & notifications pipeline

The pipeline spans four layers; a new notification type touches ALL of them in this order. Skipping a step is the usual cause of "notification never arrives".

## The pipeline
1. **Token capture** (`lib/core/push/`): FCM token registered into the `device_tokens` table on sign-in/refresh. Don't re-architect this; it exists.
2. **Trigger**: whatever creates the notification (RPC, edge function, trigger) inserts the in-app notification row AND invokes/feeds the `send-push` edge function.
3. **Delivery** (`supabase/functions/send-push/`): reads recipient tokens, sends via FCM, handles dead-token cleanup. Read it before changing payload shape.
4. **Receive + route** (Flutter): foreground/background handlers; tapping a notification deep-links to the right screen via go_router paths (e.g. a challenge -> `/challenges/:requestId`).

## Adding a NEW notification type - checklist
1. Define the type identifier consistently with existing types (read the notifications migrations + `lib/features/notifications/` to copy the enum/shape).
2. Server side: create the notification row + push payload at the trigger point. Pool precedent: notification types ride the existing broadcast (see docs/match-pool-feature-design.md).
3. Payload carries enough to route: type + entity id(s). Keep it minimal; the app fetches details itself.
4. Flutter: render the new type in the notifications screen (icon/copy), and map tap -> the correct go_router route. An unmapped type must fail SOFT (open the notifications screen, not crash).
5. Badge/unread: `unreadNotificationsCountProvider` drives the V2Header bell - confirm the new type counts (or deliberately doesn't).
6. Test on a REAL device: foreground, background, and killed states behave differently; all three matter.

## Debugging "no notification"
Walk the pipeline in order: token row exists for the device? -> trigger actually fired (check the notification row exists in-app)? -> send-push logs show FCM accept? -> device handler registered for that state (fg/bg/killed)? -> OS-level permission granted (Android 13+ runtime permission)?

## Don'ts
- Don't send user content beyond what's needed (payloads transit Google's servers).
- Don't invoke FCM from the Flutter client - delivery is server-side only (send-push).
- Don't add a notification type without its tap-route mapping.

---
name: release-readiness
description: Play Store (and later App Store) release preparation for MatchDay. Use when the user mentions releasing, deploying, publishing, signing, versioning for release, store listing, or "preparing for the Play Store". Walks the full pre-submission checklist for this specific app.
---

# Release readiness - MatchDay

App identity: matchday / joinmatchday.com, Firebase project `matchday-44ed4`. The app is currently UNRELEASED; "v2" in code names refers to the second DESIGN iteration, not a release version.

## Versioning
- Source of truth: `pubspec.yaml` `version: X.Y.Z+N` -> Android versionName (X.Y.Z) + versionCode (N).
- First public release: set deliberately (e.g. `1.0.0+1`). Every Play upload needs a strictly higher versionCode.

## Android build & signing
1. Create an upload keystore (NEVER commit it); reference via `android/key.properties` (gitignored) and the signing config in `android/app/build.gradle`.
2. Verify `applicationId` is final - it can NEVER change after first publish.
3. Build: `flutter build appbundle --release --dart-define-from-file=dart_define.json` (.aab, not .apk, for Play).
4. **Target SDK (verified 2026-06)**: new apps must currently target Android 15 (API 35); from **Aug 31, 2026** new apps/updates must target **Android 16 (API 36)**. Target 36 now to avoid a forced bump right after launch. (Play's rolling rule: target within one year of the latest major Android release.)

## Play account gate - PLAN FOR THIS FIRST (verified 2026-06)
Personal developer accounts created after 2023-11-13 must complete a **closed test with >=12 opted-in testers for 14 consecutive days** before they can even APPLY for production access (Google then reviews tester engagement). Organization accounts are exempt. Practical implications:
- Add ~3-5 weeks to the launch timeline (recruit testers, 14 days, production-access review).
- Testers must be real, engaged users on real devices - inactive testers get the application rejected. Hassaan's classmates/peers are a natural tester pool.
- Track order: internal testing (fast, no review) -> closed testing (the 12/14 gate) -> production.

## Secrets & config audit
- `dart_define.json` is gitignored? (`dart_define.example.json` is the committed template.) Confirm no secrets in source.
- `--dart-define` values are compiled into the binary as plain strings - only PUBLIC config belongs there (Supabase URL + anon key are fine; anything privileged is not).
- Service-role keys exist ONLY in edge function env, never in the app.
- `google-services.json` for the RELEASE applicationId present; release SHA-1/SHA-256 fingerprints added in Firebase (Google sign-in breaks in release builds without them - the #1 release-day surprise).

## Deep links - must ship WITH the release
- `/u/:username` share links require `https://joinmatchday.com/.well-known/assetlinks.json` (Android, with the RELEASE signing fingerprint) and `apple-app-site-association` (iOS) hosted on the domain. Without them, OS handoff fails and links open the browser.
- Verify intent filters in AndroidManifest match the hosted files.

## Push notifications in release
- FCM works with the release google-services.json; test a real `send-push` round trip on a release build before submitting.

## Store listing inputs (prepare in parallel)
Privacy policy URL (required - FCM tokens + location data make the Data Safety form non-trivial: declare location, user content, device IDs), app icon, feature graphic, screenshots (phone required), content rating questionnaire, target audience. Location permission needs a clear in-listing justification.

## Final gate (run in order)
1. `flutter analyze` clean; `flutter test` green.
2. Release build installs and runs on a REAL device (not just debug).
3. Smoke path on the release build: sign in (Google + OTP) -> five tabs -> create team -> score a few balls -> post -> push received -> share link opens in-app.
4. Sentry/crash reporting decision made (currently none configured - flag this explicitly; releasing blind is a choice the user must make consciously).
5. Tag the release commit; note the version in the repo.

## Don'ts
- Don't commit keystores, key.properties, or dart_define.json.
- Don't bump versionCode in a dirty working tree.
- Don't change applicationId, signing key, or package name after first publish.

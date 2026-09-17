# Matchday Google Play readiness

Updated 2026-09-15. Matchday has not been uploaded or published on Google Play.

## Completed

- Accessed the owner’s Play Console account and prepared the new-app form. `com.matchday.app` is already in use; `com.joinmatchday.app` was available at inspection. App created successfully after the owner explicitly approved both declarations. Play app ID: `4972204041620198341`.
- Configured a protected, ignored upload keystore and release signing. Keep an independent secure backup of `android/upload-keystore.jks` and `android/key.properties`; never commit or share them publicly.
- Registered the new Firebase Android app and upload SHA-1/SHA-256 certificates. Created its Android OAuth client; production web client matches existing Google Cloud configuration.
- Built `build/app/outputs/bundle/release/app-release.aab` from `config/prod.json`, version `0.4.2+3` (79.4 MB, SHA256 `df0f444a389eec8d209b951a140f73f7f84ac92c9d8a2b0c50a8b20d37473a3e`), updated 2026-09-16 with latest Stitch UI and realtime chat integration.
- Merged release manifest confirms package `com.joinmatchday.app`, min SDK 24 and target SDK 36. Main activity correctly resolves to namespace `com.matchday.app.MainActivity`.
- Inspected 15 bundled native libraries. All 64-bit ELF load segments meet 16 KB alignment. APK packaging and actual 16 KB device operation remain to be validated by Play/device testing.
- JAR signature verification passes with the upload certificate. The tool emits expected self-signed/no-timestamp warnings plus Gradle bundle streaming-manifest ordering warnings; Play upload validation is still required.
- Added Settings, offline-readable legal policies, working sign-in policy links, account deletion, reporting and blocking UI.
- Deployed report/block enforcement and account deletion database changes, plus the authenticated deletion Edge Function, to hosted Supabase.
- Published privacy, community/child safety and external account-deletion pages at https://matchday-support.muhammadsarankhalid.chatgpt.site (including extensionless paths).
- Prepared listing text, icon, feature graphic and two phone screenshots. See `play-store-listing.md`.

## Verification

- Application static analysis: no issues on the new release code at last run.
- Full Flutter suite: 652 passing, 10 failing. The failures are the existing scoring repository/controller tests referencing removed APIs, plus tournament detail/registration widget tests. They remain unresolved and must not be presented as passing.
- New settings/deletion guard tests: 2 passing.
- Screenshot renderer: passing, actual production screens with local fictional fixtures.
- Migration layout: 3 passing.
- SQL functional test in a disposable local database: transaction rolled back after verifying block isolation, reciprocal message/comment blocking, report privacy, unblock and deletion/anonymization. No real account deleted.
- New tables have explicit restricted grants; anonymous deletion RPC access and authenticated TRUNCATE privileges were removed and checked on hosted backend.

## Outstanding before launch

1. App creation and the two authorized declarations are complete. Dashboard: https://play.google.com/console/u/0/developers/6830117639480351252/app/4972204041620198341/app-dashboard . Public privacy URL saved in Console, pending review submission.
2. Upload assets and bundle to testing. Browser upload failed because the ChatGPT Chrome extension lacks “Allow access to file URLs”; the owner has been given the required setting. Enable Play App Signing, register the Play signing certificates with Firebase/Google OAuth, and resolve Console validation/pre-launch findings.
3. Resolve Google OAuth test-user restriction and verify Google sign-in on a Play-installed build.
4. Establish reviewer access that does not depend on the owner’s private inbox; complete app-access instructions.
5. Complete accurate Data safety, content rating, target audience, ads and distribution declarations. Proposed defaults: Pakistan, adults 18+, free, no ads; public support/safety Gmail.
6. Resolve pre-existing failed tests and complete physical Android tests for sign-in, invitations, scoring/recovery, uploads, push and deletion.
7. Console confirms production access requires a closed test: at least 12 testers continuously opted in for at least 14 days, then a production-access application. Current count: 0.
8. Register Android App Links at `joinmatchday.com` using the Play signing certificate, or remove unsupported link claims. Domain control has not been verified.
9. Complete moderation operations: monitor `content_reports`, review reports, act on abusive content/accounts, and process external deletion requests after verifying ownership. No recurring monitor or outbound messages have been configured.
10. Complete clean migration replay and remaining security review. Existing Supabase advisor findings remain, including extension exposure and authenticated security-definer helpers; the new changes do not establish that the entire backend is secure. Shared chat previews from `list_my_chats` also need review against blocked-user visibility.

## Official references

- Target API: https://developer.android.com/google/play/requirements/target-sdk
- Release process: https://support.google.com/googleplay/android-developer/answer/9859348
- App review declarations: https://support.google.com/googleplay/android-developer/answer/9859455
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Account deletion: https://support.google.com/googleplay/android-developer/answer/13327111
- User-generated content: https://support.google.com/googleplay/android-developer/answer/9876937
- Store assets: https://support.google.com/googleplay/android-developer/answer/9866151
- Personal-account testing: https://support.google.com/googleplay/android-developer/answer/14151465
- Native page sizes: https://developer.android.com/guide/practices/page-sizes

## Console progress — September 15

Dashboard verified 6 of 11 setup tasks complete: privacy policy, no ads, not a government app, no financial features, no health features, and Sports category/contact details. Public support email and HTTPS website saved. Target audience is blocked by incomplete Sign in details. Google requires reusable review credentials, will not create accounts or contact the owner for OTPs. No fabricated access details have been submitted.

Content rating reached IARC category form. Contact and All Other App Types selected; separate IARC Terms of Use approval requested, not accepted. Current source now includes ably_flutter and Ably-backed messaging/scoring changes from other work; the September 14 bundle predates these changes. Re-audit privacy/data safety and rebuild from the finalized source before upload.

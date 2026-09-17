# Matchday listing draft

Prepared 14 September 2026. Not submitted to Google Play.

## Listing text

**Name:** Matchday

**Short description:** Score cricket matches, manage your team and follow every innings together.

**Full description:**

Bring your cricket community together with Matchday.

Record matches ball by ball, keep the scorecard clear and give every innings a lasting record. Whether you are playing with friends or organizing your club, Matchday brings teams, matches and cricket conversations into one place.

SCORE EVERY DELIVERY
Record runs, wickets and extras with a dedicated scoring pad. Follow the innings, batting and bowling figures, and delivery history. Scoring changes are queued on the scoring device when connectivity drops and synchronized when service returns.

BUILD YOUR TEAM
Create a team, manage your roster and invitations, and keep your cricket group connected.

FOLLOW YOUR CRICKET
Browse matches and tournaments, view player profiles and share cricket updates with your community.

STAY CONNECTED
Use team conversations and direct messages, manage notifications and follow the people you play with.

CONTROL YOUR EXPERIENCE
Report inappropriate content, block users, read the privacy policy and request account deletion from Settings.

Matchday is free and has no advertisements or paid features. An account and internet connection are required for most features. Matchday is intended for adults aged 18 and over.

Support: muhammadsarankhalid@gmail.com

## Proposed Console choices

User delegated routine launch choices: initial Pakistan availability, free, no ads, adults 18+, English (US), Sports category. Complete the content-rating questionnaire from actual functionality; do not invent a rating. Do not select child-directed or gambling classifications. Cricket scoring is not wagering.

- Package: `com.joinmatchday.app` (available in Console at inspection, not yet reserved).
- Privacy: https://matchday-support.muhammadsarankhalid.chatgpt.site/privacy
- Account deletion: https://matchday-support.muhammadsarankhalid.chatgpt.site/delete-account
- Community and child safety standards: https://matchday-support.muhammadsarankhalid.chatgpt.site/terms
- Support and safety contact: muhammadsarankhalid@gmail.com

## Assets

`play-store-assets/icon-512.png`: opaque 512×512 PNG, existing vector brand.
`play-store-assets/feature-graphic-1024x500.png`: opaque 1024×500 PNG.
`play-store-assets/phone-01-scoring.png` and `phone-02-settings.png`: 1080×1920 production Flutter widgets rendered with fictional local fixtures. No real user's account or private content appears. Regenerate with `flutter test tool/store_assets/render_screenshots_test.dart`.

## Data safety preparation — verify before submission

Actual app features include account name/email/user ID, optional profile information and photos, location, posts/comments, messages, team/match records, report/block records, and notification device tokens. Optional location and media must be declared according to their actual use. Uploaded files are currently URL-accessible; messages are not end-to-end encrypted. Transport encryption is distinct from end-to-end encryption.

Declare account deletion available, with shared match records retained in anonymized form and provider backup/log retention as explained in the privacy policy. Do not claim no collection merely because data is hosted by Supabase. Confirm SDK telemetry, diagnostics, sharing exceptions, collection purposes, and whether each item is optional against the final binary and backend before submitting the form.

## Review access and launch gates

The app uses Google sign-in/email OTP. A tested reviewer-access arrangement is still needed, without exposing the owner's inbox or using production personal credentials. Google OAuth currently reports access restricted to test users; inspect the audience and publish its sign-in configuration as appropriate before wider testing. Google Play's signing certificate still needs registration after bundle upload. The upload certificate is already registered.

If this personal account requires production eligibility testing, recruit at least 12 genuine testers and maintain continuous opt-in for 14 days, then apply for production access. Do not substitute simulated users or fabricated testing evidence.

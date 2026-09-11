# Teams and team creation: design review

Reviewed on 9 September 2026 in the running Android emulator (1080 × 2400). The walkthrough used the existing Gulberg Gladiators draft: Village, Public, navy/gold colors, Lahore / Gulberg III, and Shield crest. No application code was changed.

**Outcome: creation is blocked.** The app showed “permission denied for table teams.” My Teams remained empty after the initial attempts. The draft was saved and successfully reopened at step 5. The final retry reproduced the permission error. A successful creation, confirmation screen, and saved team page could not be verified.

[Open the screenshot gallery](gallery.html). All 18 screenshots are original emulator captures.

The warm background, strong headings, consistent rounded controls, prominent Continue button, and visible step count give the flow a coherent visual identity. The main improvements concern trustworthy feedback, consistent previews, and reducing the amount of work before a team exists.

## Fix first

### 1. Team creation fails and the error disappears — blocker

Evidence: [permission error](screenshots/18-create-permission-error.png), [loading state](screenshots/14-create-feedback.png), [empty My Teams afterward](screenshots/16-teams-after-attempt.png).

Tapping Create team changes the button to Creating…, then returns it to Create team. A short-lived snackbar says “permission denied for table teams” and covers the footer. Once it disappears, the screen gives no indication of what went wrong. Earlier captures missed the error entirely; a short capture sequence caught it.

Resolve the underlying permission failure. The message alone does not establish which grant, policy, or session condition caused it. Keep a persistent, plain-language error above the action: “We couldn’t create your team. Your draft is saved.” Provide an appropriate next action and retain the technical details in diagnostics. Do not offer endless retries for an unchanged permissions failure. Use a spinner during submission rather than retaining the success-like checkmark.

Acceptance: an authorized user can create exactly one team, receives an unambiguous success confirmation, and sees it in My Teams. On failure, the draft and recovery action remain visible.

### 2. The selected crest and final preview disagree — high priority

Evidence: [identity](screenshots/04-identity.png), [selected shield](screenshots/08-crest.png), [review](screenshots/10-review.png).

The crest step shows a navy shield with white GG, but the review hero shows a yellow rounded square with GG while its Crest row still says “Shield style.” Users cannot tell which identity they will get. The identity preview also uses the yellow square.

Use the same crest renderer and selected data in the editor, review, success screen, team list, and team page. Preserve both the selected style and custom initials when saving. In the inspected creation controller, the create call does not pass the generated crest kind; this needs verification in the eventual saved-team behavior. Persistence could not be tested because creation failed.

Acceptance: changing any crest style or uploading a logo produces the same result in every preview and after reopening the saved team.

### 3. Privacy help does not describe the current selection — high priority

Evidence: [step 1, lower fields](screenshots/03-basics-lower.png).

Public is selected, but the explanation only describes Private. It is not explicitly claiming that Public is private, but it leaves the consequences of the actual choice unexplained. The source confirms the explanation is fixed text even though it receives the selected privacy value.

Show selection-specific copy explaining discoverability, roster visibility, and how players join. Confirm the wording against actual behavior. For example, explain public visibility when Public is selected and invitation requirements when Private is selected. Keep this explanation close to the control and readable without excessive scrolling.

### 4. Location confirmation is misleading — high priority

Evidence: [home](screenshots/05-home.png), [location fallback](screenshots/07-location-suggestions.png).

The striped box is labeled “MAP PREVIEW” with a pin and address, but it is a placeholder rather than a map. Re-entering Lahore produced no visible suggestions in this session and showed a fallback warning that the team would not appear in nearby searches. The map-like placeholder still looked unchanged. The initial explanatory text promises nearby discovery without distinguishing a typed label from a resolved place.

Use a real location preview only after resolution, or replace the box with a compact location summary. Make the states explicit: searching, selected location, no results, service unavailable, and typed location without nearby discovery. Give “Use Lahore anyway” a visible action style rather than burying the fallback in subdued text. Keep the nearby-discovery status visible in review.

The failed lookup's cause was not diagnosed; the observed issue is the unclear feedback and contradictory presentation.

## Make the flow easier

### 5. Reduce the five-step setup — medium priority

Evidence: [basics](screenshots/02-create-basics-restored.png), [identity](screenshots/04-identity.png), [crest](screenshots/08-crest.png).

Colors and crest are separate steps for one visual identity. Basics asks for a name, six-way team classification, tagline, founding year, and privacy; location comes only after a full branding step. This creates a lot of decisions before a team exists. Optional identity customization has no clearly labeled skip action.

Proposed flow: **Team details → Look & location → Review & create.** Keep name, team type, location, and visibility straightforward; group optional colors, initials, logo, tagline, and founding year behind clear optional controls. Offer sensible defaults and “Use default look.” An even faster variant could create from essential details and offer branding afterward, but that should be tested with users.

### 6. Rebalance space and type sizes — medium priority

Evidence: [team types](screenshots/02-create-basics-restored.png), [colors](screenshots/04-identity.png), [home](screenshots/05-home.png).

The six team-type tiles have substantial unused space, making Basics much denser than Home. The header repeats step information in the top bar, progress bars, and step label. Several important labels and descriptions are small and subdued; the source uses 10–11 logical pixels for many of them. Full-resolution captures can disguise how small that feels on a handset.

Shorten the type cards, use a compact two-column selector or a readable list, and reduce redundant header height. Raise important labels and helper copy to a more comfortable reading size with stronger contrast. Keep the large touchable primary action. Test smaller screens and increased text size before claiming accessibility compliance; those were not tested in this walkthrough.

### 7. Make drafts visible in My Teams — medium priority

Evidence: [initial My Teams](screenshots/01-teams.png), [save dialog](screenshots/12-save-exit.png), [My Teams after saving](screenshots/16-teams-after-attempt.png), [restored draft](screenshots/17-draft-resumed.png).

My Teams says “No teams yet” and offers Create a team, although an existing draft is restored when that action is tapped. After saving, the page still offers no explicit Resume draft action. The save dialog directs people to Pavilion → Drafts, creating a detour from the place where the task started.

Show “Continue Gulberg Gladiators — Review, step 5 of 5” on My Teams with clear resume and discard actions. Keep completed teams and drafts visually distinct. “Create a team” should communicate whether it starts fresh or resumes work. The save-and-resume behavior itself worked in this session.

### 8. Make review edits quick and the summary clearer — medium priority

Evidence: [review](screenshots/10-review.png).

The Basics row compresses name, type, privacy, and an absent founding year into one string ending in “est. —”. Identity and Crest use overlapping terminology. The page asks users to accept community guidelines without a visible link.

Separate the key facts into readable rows, omit absent optional values or say “Not added,” label the initials field plainly, and make guidelines accessible. When editing from review, return directly to review after saving the change. The inspected navigation moves to the selected wizard step and then uses the ordinary sequential Continue behavior, so there is no dedicated return-to-review action in that path.

### 9. Match upload promises to the picker — medium priority

Evidence: [crest instructions](screenshots/08-crest.png), [Android photo picker](screenshots/09-logo-picker.png).

The UI advertises PNG, JPG, or SVG, but opens a photo gallery. SVG selection was not verified. There is no visible crop or positioning step in the inspected picker handler, although the oversized-file message tells users to crop or compress externally.

Verify each advertised format end to end; provide a file picker if SVG is supported, or adjust the copy. Offer a clear crop/fit preview for uploaded logos and automatic size handling where practical. File upload completion was not tested; the picker was opened and dismissed without choosing a file.

### 10. Use simpler, more consistent language — polish

Evidence: [basics](screenshots/02-create-basics-restored.png), [home](screenshots/05-home.png), [crest](screenshots/08-crest.png), [ownership sheet](screenshots/11-ownership.png).

“Disambiguates,” “monogram,” “crest,” “secondary / accent,” and “auto-syncs” ask more of users than necessary. “Village” includes a mohalla/community description, which may confuse urban teams. The crest introduction says “your club” even for the selected Village type. The owner avatar says YO without showing the actual account name.

Prefer “Helps players find the right team,” “Team initials,” “Team logo,” “Accent color,” and “Matches your team colors.” Consider “Community / mohalla” if that better matches the intended category. Use “team” consistently and identify the owner by their actual display name. The ownership sheet's permission comparison is useful; preserve that clear structure.

## Suggested order of work

1. Unblock creation and provide persistent, actionable failure feedback.
2. Make crest previews and saved data consistent.
3. Correct privacy and location explanations.
4. Shorten setup, improve review editing, and expose drafts.
5. Refine typography, upload handling, and terminology.

## Coverage and limits

Captured: empty My Teams; all five creation steps; lower Basics fields; focused location entry and fallback; logo picker; ownership sheet; Save & Exit; loading and failure states; My Teams after attempts; draft resume. The Android input accessory visible in two location captures belongs to the emulator keyboard and is not treated as an app design defect.

Not verified: successful creation, saved-team appearance, success actions, player invitations, uploaded-logo completion, GPS permissions, accessibility semantics, large-text layout, or other device sizes. No backend permissions or application code were modified. The source observations above supplement the live screenshots and are labeled separately from observed runtime outcomes.

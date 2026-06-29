---
name: pre-flight-qa
description: The verification checklist to run before declaring any MatchDay code change done, before commits, and when diagnosing build/analyzer failures. Encodes this repo's tooling quirks (drift pin, disabled lints, codegen rules, run command).
---

# Pre-flight QA for MatchDay

## Always
1. `flutter analyze` - must be clean. Never declare done with errors.
2. `flutter test test/architecture_test.dart` - the layer rules as tests (dart_arch_test): domain imports nothing from data/presentation, no use-case folders, no import cycles, frozen cross-feature baseline. A NEW violation fails the suite; fix the code, don't loosen the rule. (Refresh a freeze baseline only after deliberate fixes: `DART_ARCH_TEST_UPDATE_FREEZE=1 flutter test test/architecture_test.dart`.)
3. Run the app with the project's required flag:
   `flutter run --dart-define-from-file=dart_define.json`
   (a plain `flutter run` produces auth/config failures - not a code bug).

Note: a PostToolUse hook in `.claude/settings.json` also greps for framework imports in `lib/features/*/domain` after every edit - if it fires, the edit violated domain purity; fix immediately.

## Codegen - only when needed
Run `dart run build_runner build --delete-conflicting-outputs` ONLY if you touched files containing `@riverpod`, `@freezed`/`@Freezed`, `@JsonSerializable`, or drift table definitions. Pure widget/logic edits never need it.

## Known repo quirks (don't "fix" these)
- **drift is pinned to 2.31** and **riverpod_lint / custom_lint are disabled** due to a three-way analyzer version conflict under Flutter 3.41.x. Do not upgrade drift, do not re-enable those lints, do not bump analyzer to chase a warning. Consequence: REVIEW PROVIDER RULES MANUALLY (ref.watch in build / ref.read in handlers / DAG) - the linter won't catch them.
- Fonts are bundled (Inter, Inter Tight, JetBrains Mono); adding google_fonts is a regression.
- Architecture amendments: NO use-case layer; ONLINE-ONLY (drift exists only for WizardDrafts + the messages read-through cache).

## Manual provider audit (because riverpod_lint is off)
- `ref.watch` only in build methods; `ref.read` in callbacks/handlers; `ref.listen` for side effects.
- No provider cycles; repository/datasource providers keepAlive: true; repository providers return abstract types.

## Freezed gotcha
A Freezed DTO with any custom method (e.g. `toEntity()`) MUST declare `const X._();` - omitting it makes the method invisible to the analyzer and fails silently at the call site.

## Smoke test path (after UI/nav changes)
Sign in -> all five tabs render (Home - Search - Matches - Messages - Pavilion) -> swipe between tabs -> header bell opens Notifications -> header avatar opens own profile -> system back returns.

## Tests
`flutter test` for affected feature folders; new repos/controllers get at least a happy-path test (delegate breadth to the test-writer agent).

# Typography

Matchday uses two complementary typographic families plus a specialized tabular monospace font:

1. **Inter Tight**: Display and structural headings (wordmark, screen titles, section headlines).
2. **Inter**: Body text, labels, and form inputs.
3. **JetBrains Mono**: Tabular figures, overs, run rates, timestamps, and section eyebrows.

---

## Standard TextTheme Roles

Feature code accesses standard typography via `context.theme.textTheme`:

| TextTheme Role | Font Family | Size | Weight | Line Height |
|---|---|---|---|---|
| `displaySmall` | Inter Tight | 26 | w700 | 1.08 |
| `headlineSmall` | Inter Tight | 22 | w700 | 1.15 |
| `titleLarge` | Inter Tight | 20 | w700 | Standard |
| `titleMedium` | Inter Tight | 16 | w600 | Standard |
| `titleSmall` | Inter Tight | 14 | w600 | Standard |
| `bodyLarge` | Inter | 16 | w400 | 1.45 |
| `bodyMedium` | Inter | 14 | w400 | 1.45 |
| `bodySmall` | Inter | 13 | w400 | 1.40 |
| `labelLarge` | Inter | 14 | w700 | Standard |
| `labelMedium` | Inter | 12 | w600 | Standard |
| `labelSmall` | Inter | 11 | w600 | Standard |

---

## Matchday TextTokens (Cricket & Tabular Typography)

Accessed via `context.textTokens`:

| Token | Family | Size | Weight | Tracking | Usage |
|---|---|---|---|---|---|
| `metadata` | JetBrains Mono | 10 | w600 | 0.7 | Overs, timestamps, small stats |
| `eyebrow` | JetBrains Mono | 10 | w700 | 1.0 | Uppercase section badges / eyebrows |
| `metric` | JetBrains Mono | 13 | w700 | Normal | Tabular numbers (scores, economy) |
| `score` | JetBrains Mono | 18 | w700 | Normal | Scoreboard numbers |

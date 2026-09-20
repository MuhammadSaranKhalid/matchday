import type {
  MatchBundle,
  TeamSide,
} from "../types.ts";
import { unprocessable } from "./errors.ts";

export function teamSideFor(
  match: MatchBundle,
  teamId: string,
): TeamSide {
  if (teamId === match.teamAId) return "team_a";
  if (teamId === match.teamBId) return "team_b";
  unprocessable("Team is not part of this match");
}

export function oppositeSide(side: TeamSide): TeamSide {
  return side === "team_a" ? "team_b" : "team_a";
}

// Cricket batting side is a pure domain rule.
//
// Odd innings -> side that bats first.
// Even innings -> the other side.
//
// For normal 1-innings-per-side cricket this maps innings 1/2. It also keeps
// the existing 3/4 behavior used by multi-innings formats.
export function battingTeamForInnings(
  match: MatchBundle,
  inningsNumber: number,
): string {
  if (!match.teamAId || !match.teamBId) {
    unprocessable("Both teams must be known before an innings can start");
  }

  let batsFirst: string;

  if (!match.tossWonBy || !match.tossDecision) {
    // Defensive fallback retained from the old DB helper. Normal command flow
    // will not reach scoring before the toss is decided.
    batsFirst = match.teamAId;
  } else if (match.tossDecision === "bat") {
    batsFirst = match.tossWonBy;
  } else {
    batsFirst =
      match.tossWonBy === match.teamAId
        ? match.teamBId
        : match.teamAId;
  }

  if (inningsNumber % 2 === 1) return batsFirst;
  return batsFirst === match.teamAId
    ? match.teamBId
    : match.teamAId;
}

export function numberRule(
  rules: Record<string, unknown>,
  key: string,
  fallback: number,
): number {
  const value = rules[key];

  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }

  return fallback;
}

export function booleanRule(
  rules: Record<string, unknown>,
  key: string,
  fallback: boolean,
): boolean {
  const value = rules[key];
  if (typeof value === "boolean") return value;
  if (value === "true") return true;
  if (value === "false") return false;
  return fallback;
}

// TypeScript replacement for _normalize_cricket_match_rules(jsonb).
//
// Keeping normalization in TypeScript means changing a Cricket rule shape no
// longer requires replacing a PL/pgSQL/SQL business helper migration.
export function normalizeCricketRules(
  input: Record<string, unknown> | null | undefined,
): Record<string, unknown> {
  const f = input ?? {};

  const normalized: Record<string, unknown> = {
    overs_per_innings:
      integerOr(
        f.overs_per_innings,
        f.max_overs,
        20,
      ),
    players_per_team:
      integerOr(f.players_per_team, 11),
    balls_per_over:
      integerOr(f.balls_per_over, 6),
    max_overs_per_bowler:
      integerOr(f.max_overs_per_bowler, 4),
    innings_per_side:
      integerOr(f.innings_per_side, 1),
    ball_type:
      nonEmptyString(f.ball_type) ?? "leather",
    super_over_enabled:
      booleanOr(f.super_over_enabled, true),
    dls_enabled:
      booleanOr(f.dls_enabled, true),
  };

  const wickets = nullableInteger(f.wickets_to_all_out);
  if (wickets != null) {
    normalized.wickets_to_all_out = wickets;
  }

  const endChange = nullableInteger(f.end_change_balls);
  if (endChange != null) {
    normalized.end_change_balls = endChange;
  }

  return normalized;
}

function integerOr(...values: unknown[]): number {
  for (const value of values) {
    const parsed = nullableInteger(value);
    if (parsed != null) return parsed;
  }
  return 0;
}

function nullableInteger(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }

  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    if (Number.isInteger(parsed)) return parsed;
  }

  return null;
}

function booleanOr(value: unknown, fallback: boolean): boolean {
  if (typeof value === "boolean") return value;
  if (value === "true") return true;
  if (value === "false") return false;
  return fallback;
}

function nonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed;
}

export function jsonObject(
  value: unknown,
): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as Record<string, unknown>;
}

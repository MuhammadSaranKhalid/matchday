import type {
  MatchBundle,
  TeamSide,
} from "../types.ts";
import { unprocessable } from "./errors.ts";

export function teamIdForSide(
  match: MatchBundle,
  side: TeamSide,
): string {
  const teamId =
    side === "team_a"
      ? match.teamAId
      : match.teamBId;

  if (!teamId) {
    unprocessable(
      `${side} has not been resolved to a team yet`,
    );
  }

  return teamId;
}

export function teamSideFor(
  match: MatchBundle,
  teamId: string,
): TeamSide {
  if (teamId === match.teamAId) {
    return "team_a";
  }

  if (teamId === match.teamBId) {
    return "team_b";
  }

  unprocessable(
    "Team is not part of this match",
  );
}

export function oppositeSide(
  side: TeamSide,
): TeamSide {
  return side === "team_a"
    ? "team_b"
    : "team_a";
}

// Cricket rules should reason in stable side identities.
//
// Example:
//   toss_won_by = team_a
//   decision    = bowl
//
// Then team_b bats first, regardless of what UUID currently occupies team_a.
export function battingSideForInnings(
  match: MatchBundle,
  inningsNumber: number,
): TeamSide {
  let firstBattingSide: TeamSide;

  if (
    !match.tossWonBy ||
    !match.tossDecision
  ) {
    // Defensive fallback. Normal start flow completes the toss first.
    firstBattingSide = "team_a";
  } else if (
    match.tossDecision === "bat"
  ) {
    firstBattingSide =
      match.tossWonBy;
  } else {
    firstBattingSide =
      oppositeSide(match.tossWonBy);
  }

  return inningsNumber % 2 === 1
    ? firstBattingSide
    : oppositeSide(firstBattingSide);
}

export function battingTeamForInnings(
  match: MatchBundle,
  inningsNumber: number,
): string {
  return teamIdForSide(
    match,
    battingSideForInnings(
      match,
      inningsNumber,
    ),
  );
}

export function numberRule(
  rules: Record<string, unknown>,
  key: string,
  fallback: number,
): number {
  const value = rules[key];

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  if (
    typeof value === "string" &&
    value.trim() !== ""
  ) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return fallback;
}

export function booleanRule(
  rules: Record<string, unknown>,
  key: string,
  fallback: boolean,
): boolean {
  const value = rules[key];

  if (typeof value === "boolean") {
    return value;
  }

  if (value === "true") return true;
  if (value === "false") return false;

  return fallback;
}

export function normalizeCricketRules(
  input:
    | Record<string, unknown>
    | null
    | undefined,
): Record<string, unknown> {
  const f = input ?? {};

  const normalized:
    Record<string, unknown> = {
      overs_per_innings:
        integerOr(
          f.overs_per_innings,
          f.max_overs,
          20,
        ),
      players_per_team:
        integerOr(
          f.players_per_team,
          11,
        ),
      balls_per_over:
        integerOr(
          f.balls_per_over,
          6,
        ),
      max_overs_per_bowler:
        integerOr(
          f.max_overs_per_bowler,
          4,
        ),
      innings_per_side:
        integerOr(
          f.innings_per_side,
          1,
        ),
      ball_type:
        nonEmptyString(
          f.ball_type,
        ) ?? "leather",
      super_over_enabled:
        booleanOr(
          f.super_over_enabled,
          true,
        ),
      dls_enabled:
        booleanOr(
          f.dls_enabled,
          true,
        ),
    };

  const wickets =
    nullableInteger(
      f.wickets_to_all_out,
    );

  if (wickets != null) {
    normalized.wickets_to_all_out =
      wickets;
  }

  const endChange =
    nullableInteger(
      f.end_change_balls,
    );

  if (endChange != null) {
    normalized.end_change_balls =
      endChange;
  }

  return normalized;
}

function integerOr(
  ...values: unknown[]
): number {
  for (const value of values) {
    const parsed =
      nullableInteger(value);

    if (parsed != null) {
      return parsed;
    }
  }

  return 0;
}

function nullableInteger(
  value: unknown,
): number | null {
  if (
    typeof value === "number" &&
    Number.isInteger(value)
  ) {
    return value;
  }

  if (
    typeof value === "string" &&
    value.trim() !== ""
  ) {
    const parsed = Number(value);

    if (Number.isInteger(parsed)) {
      return parsed;
    }
  }

  return null;
}

function booleanOr(
  value: unknown,
  fallback: boolean,
): boolean {
  if (typeof value === "boolean") {
    return value;
  }

  if (value === "true") return true;
  if (value === "false") return false;

  return fallback;
}

function nonEmptyString(
  value: unknown,
): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed === ""
    ? null
    : trimmed;
}

export function jsonObject(
  value: unknown,
): Record<string, unknown> {
  if (
    !value ||
    typeof value !== "object" ||
    Array.isArray(value)
  ) {
    return {};
  }

  return value as
    Record<string, unknown>;
}

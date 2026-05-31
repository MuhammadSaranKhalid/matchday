// Match result computation — the "who won, by how much" brains.
//
// computeResult() is a PURE function. The edge orchestrator builds the
// `InningsLine[]` from the completed `match_innings_state` rows + the
// toss/batting mapping, and persists the returned shape into `matches.result`
// via `submit_match_result`. No I/O here.

import type { MatchFormat } from "./types.ts";

/** One innings reduced to its result-relevant numbers. */
export interface InningsLine {
  inningsNumber: number;
  battingTeamId: string;
  runs: number;
  wickets: number;
  legalBalls: number;
  isAllOut: boolean;
}

export type WinType = "runs" | "wickets" | "tie" | "draw";

export interface MatchResult {
  winnerTeamId: string | null; // null for tie / draw / no-result
  winType: WinType | null;
  winMargin: number | null; // runs or wickets; null for tie / draw
  /** Human phrasing WITHOUT the team name (the UI prepends the winner's name).
   * e.g. "Won by 23 runs", "Won by 4 wickets", "Match tied", "Match drawn". */
  description: string;
}

export function computeResult(
  innings: InningsLine[],
  format: MatchFormat,
  opts: { drawn?: boolean } = {},
): MatchResult {
  if (opts.drawn) {
    return noWin("draw", "Match drawn");
  }

  const completed = innings.filter((i): i is InningsLine => i != null);
  if (completed.length < 2) {
    return { winnerTeamId: null, winType: null, winMargin: null, description: "No result" };
  }

  const wicketsToAllOut = format.wicketsToAllOut ?? (format.playersPerTeam - 1);

  // Aggregate runs per team across all of that team's innings (covers Test's 2).
  const teamRuns = new Map<string, number>();
  for (const i of completed) {
    teamRuns.set(i.battingTeamId, (teamRuns.get(i.battingTeamId) ?? 0) + i.runs);
  }

  // The team batting in the FINAL innings is the chasing side.
  const lastInns = completed[completed.length - 1];
  const chasingTeam = lastInns.battingTeamId;
  const otherTeam = [...teamRuns.keys()].find((t) => t !== chasingTeam) ??
    chasingTeam;

  const chasingRuns = teamRuns.get(chasingTeam) ?? 0;
  const otherRuns = teamRuns.get(otherTeam) ?? 0;

  if (chasingRuns === otherRuns) {
    return noWin("tie", "Match tied");
  }

  if (chasingRuns > otherRuns) {
    // Team batting last passed the total while batting → won by wickets in hand.
    const margin = wicketsToAllOut - lastInns.wickets;
    return {
      winnerTeamId: chasingTeam,
      winType: "wickets",
      winMargin: margin,
      description: `Won by ${margin} ${plural(margin, "wicket")}`,
    };
  }

  // Team batting last fell short → the side that batted first/most won by runs.
  const margin = otherRuns - chasingRuns;
  return {
    winnerTeamId: otherTeam,
    winType: "runs",
    winMargin: margin,
    description: `Won by ${margin} ${plural(margin, "run")}`,
  };
}

function noWin(winType: WinType, description: string): MatchResult {
  return { winnerTeamId: null, winType, winMargin: null, description };
}

function plural(n: number, word: string): string {
  return n === 1 ? word : `${word}s`;
}

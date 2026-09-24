// Server-side format validation for Match Day cricket challenges.
// Spec: docs/database/CRICKET_FORMATS.md

import { badRequest, unprocessable } from "./errors.ts";

export interface ValidatedCricketFormat {
  code: string;
  rules: {
    overs_per_innings: number;
    players_per_team: number;
    balls_per_over: number;
    innings_per_side: number;
    max_overs_per_bowler: number;
    ball_type: "leather" | "tape" | "tennis";
    wickets_to_all_out?: number;
  };
}

interface SystemPresetDef {
  overs: number;
  maxBowler: number;
  ballsPerOver: number;
  inningsPerSide: number;
}

const SYSTEM_PRESETS: Record<string, SystemPresetDef> = {
  t20: { overs: 20, maxBowler: 4, ballsPerOver: 6, inningsPerSide: 1 },
  t10: { overs: 10, maxBowler: 2, ballsPerOver: 6, inningsPerSide: 1 },
  quick_6: { overs: 6, maxBowler: 2, ballsPerOver: 6, inningsPerSide: 1 },
  quick_8: { overs: 8, maxBowler: 2, ballsPerOver: 6, inningsPerSide: 1 },
  over_30: { overs: 30, maxBowler: 6, ballsPerOver: 6, inningsPerSide: 1 },
  over_40: { overs: 40, maxBowler: 8, ballsPerOver: 6, inningsPerSide: 1 },
  over_45: { overs: 45, maxBowler: 9, ballsPerOver: 6, inningsPerSide: 1 },
  over_50: { overs: 50, maxBowler: 10, ballsPerOver: 6, inningsPerSide: 1 },
};

const VALID_BALL_TYPES = new Set(["leather", "tape", "tennis"]);

export function validateChallengeFormat(
  code: string | null | undefined,
  rawRules: Record<string, unknown> | null | undefined,
): ValidatedCricketFormat {
  if (!code || typeof code !== "string" || code.trim() === "") {
    badRequest("format_code is required");
  }
  const cleanCode = code.trim().toLowerCase();

  if (!rawRules || typeof rawRules !== "object" || Array.isArray(rawRules)) {
    badRequest("format rules must be an object");
  }

  // 1. Validate Ball Type
  const ballTypeRaw = rawRules["ball_type"];
  if (typeof ballTypeRaw !== "string" || !VALID_BALL_TYPES.has(ballTypeRaw)) {
    unprocessable("ball_type must be 'leather', 'tape', or 'tennis'");
  }
  const ballType = ballTypeRaw as "leather" | "tape" | "tennis";

  // 2. Validate Players per team (applies to all formats)
  const playersRaw = Number(rawRules["players_per_team"] ?? rawRules["players_per_side"]);
  if (!Number.isInteger(playersRaw) || playersRaw < 5 || playersRaw > 15) {
    unprocessable("players_per_team must be an integer between 5 and 15");
  }
  const playersPerTeam = playersRaw;

  // 3. Optional wickets to all out
  let wicketsToAllOut: number | undefined;
  if (rawRules["wickets_to_all_out"] != null) {
    const w = Number(rawRules["wickets_to_all_out"]);
    if (!Number.isInteger(w) || w < 0 || w >= playersPerTeam) {
      unprocessable(`wickets_to_all_out must be between 0 and ${playersPerTeam - 1}`);
    }
    wicketsToAllOut = w;
  }

  // 4. System Preset vs Custom
  if (cleanCode === "custom") {
    const overs = Number(rawRules["overs_per_innings"] ?? rawRules["overs"]);
    if (!Number.isInteger(overs) || overs < 1 || overs > 50) {
      unprocessable("overs_per_innings for custom matches must be between 1 and 50");
    }

    const ballsPerOver = Number(rawRules["balls_per_over"] ?? 6);
    if (!Number.isInteger(ballsPerOver) || ballsPerOver < 1 || ballsPerOver > 12) {
      unprocessable("balls_per_over must be between 1 and 12");
    }

    const inningsPerSide = Number(rawRules["innings_per_side"] ?? 1);
    if (inningsPerSide !== 1) {
      unprocessable("innings_per_side must be 1 for limited-overs matches");
    }

    const maxBowler = Number(
      rawRules["max_overs_per_bowler"] ?? Math.ceil(overs / 5),
    );
    if (!Number.isInteger(maxBowler) || maxBowler < 0 || maxBowler > overs) {
      unprocessable("max_overs_per_bowler must be between 0 and overs_per_innings");
    }

    return {
      code: "custom",
      rules: {
        overs_per_innings: overs,
        players_per_team: playersPerTeam,
        balls_per_over: ballsPerOver,
        innings_per_side: 1,
        max_overs_per_bowler: maxBowler,
        ball_type: ballType,
        ...(wicketsToAllOut != null ? { wickets_to_all_out: wicketsToAllOut } : {}),
      },
    };
  }

  const preset = SYSTEM_PRESETS[cleanCode];
  if (!preset) {
    unprocessable(`FORMAT_NOT_AVAILABLE: Format preset '${cleanCode}' is not supported`);
  }

  // Enforce invariant preset rules — reject tampered proposals
  const overs = Number(rawRules["overs_per_innings"] ?? rawRules["overs"] ?? preset.overs);
  if (overs !== preset.overs) {
    unprocessable(
      `Format '${cleanCode}' requires exactly ${preset.overs} overs (got ${overs})`,
    );
  }

  const ballsPerOver = Number(rawRules["balls_per_over"] ?? preset.ballsPerOver);
  if (ballsPerOver !== preset.ballsPerOver) {
    unprocessable(
      `Format '${cleanCode}' requires exactly ${preset.ballsPerOver} balls per over`,
    );
  }

  const inningsPerSide = Number(rawRules["innings_per_side"] ?? preset.inningsPerSide);
  if (inningsPerSide !== preset.inningsPerSide) {
    unprocessable("innings_per_side must be 1");
  }

  const maxBowler = Number(rawRules["max_overs_per_bowler"] ?? preset.maxBowler);
  if (maxBowler !== preset.maxBowler) {
    unprocessable(
      `Format '${cleanCode}' requires max_overs_per_bowler of ${preset.maxBowler} (got ${maxBowler})`,
    );
  }

  return {
    code: cleanCode,
    rules: {
      overs_per_innings: preset.overs,
      players_per_team: playersPerTeam,
      balls_per_over: preset.ballsPerOver,
      innings_per_side: preset.inningsPerSide,
      max_overs_per_bowler: preset.maxBowler,
      ball_type: ballType,
      ...(wicketsToAllOut != null ? { wickets_to_all_out: wicketsToAllOut } : {}),
    },
  };
}

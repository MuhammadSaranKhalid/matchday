import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import {
  validateChallengeFormat,
} from "./format_validation.ts";
import { CommandError } from "./errors.ts";

Deno.test("format_validation: accepts valid T20 preset with custom playing conditions", () => {
  const result = validateChallengeFormat("t20", {
    overs_per_innings: 20,
    players_per_team: 8,
    ball_type: "tape",
  });

  assertEquals(result.code, "t20");
  assertEquals(result.rules.overs_per_innings, 20);
  assertEquals(result.rules.players_per_team, 8);
  assertEquals(result.rules.ball_type, "tape");
  assertEquals(result.rules.max_overs_per_bowler, 4);
  assertEquals(result.rules.balls_per_over, 6);
  assertEquals(result.rules.innings_per_side, 1);
});

Deno.test("format_validation: accepts Tennis ball type", () => {
  const result = validateChallengeFormat("t10", {
    overs_per_innings: 10,
    players_per_team: 11,
    ball_type: "tennis",
  });

  assertEquals(result.code, "t10");
  assertEquals(result.rules.ball_type, "tennis");
});

Deno.test("format_validation: rejects tampered preset overs", () => {
  assertThrows(
    () =>
      validateChallengeFormat("t20", {
        overs_per_innings: 18,
        players_per_team: 11,
        ball_type: "tape",
      }),
    CommandError,
    "Format 't20' requires exactly 20 overs",
  );
});

Deno.test("format_validation: rejects tampered preset bowler quota", () => {
  assertThrows(
    () =>
      validateChallengeFormat("t20", {
        overs_per_innings: 20,
        max_overs_per_bowler: 5,
        players_per_team: 11,
        ball_type: "leather",
      }),
    CommandError,
    "Format 't20' requires max_overs_per_bowler of 4",
  );
});

Deno.test("format_validation: rejects discontinued formats", () => {
  assertThrows(
    () =>
      validateChallengeFormat("hundred", {
        overs_per_innings: 20,
        players_per_team: 11,
        ball_type: "leather",
      }),
    CommandError,
    "FORMAT_NOT_AVAILABLE",
  );
});

Deno.test("format_validation: validates custom format in valid range", () => {
  const result = validateChallengeFormat("custom", {
    overs_per_innings: 18,
    players_per_team: 9,
    balls_per_over: 6,
    max_overs_per_bowler: 4,
    ball_type: "tape",
  });

  assertEquals(result.code, "custom");
  assertEquals(result.rules.overs_per_innings, 18);
  assertEquals(result.rules.players_per_team, 9);
  assertEquals(result.rules.max_overs_per_bowler, 4);
});

Deno.test("format_validation: custom bowler limit derives from suggestedBowlerLimit if omitted", () => {
  const result = validateChallengeFormat("custom", {
    overs_per_innings: 18,
    players_per_team: 11,
    ball_type: "leather",
  });

  assertEquals(result.rules.max_overs_per_bowler, 4); // ceil(18/5) = 4
});

Deno.test("format_validation: rejects invalid custom bowler quota > overs", () => {
  assertThrows(
    () =>
      validateChallengeFormat("custom", {
        overs_per_innings: 10,
        max_overs_per_bowler: 12,
        players_per_team: 11,
        ball_type: "tape",
      }),
    CommandError,
    "max_overs_per_bowler must be between 0 and overs_per_innings",
  );
});

Deno.test("format_validation: rejects invalid ball type", () => {
  assertThrows(
    () =>
      validateChallengeFormat("t20", {
        overs_per_innings: 20,
        players_per_team: 11,
        ball_type: "plastic",
      }),
    CommandError,
    "ball_type must be 'leather', 'tape', or 'tennis'",
  );
});

Deno.test("format_validation: rejects players per team < 5 or > 15", () => {
  assertThrows(
    () =>
      validateChallengeFormat("t20", {
        overs_per_innings: 20,
        players_per_team: 4,
        ball_type: "tape",
      }),
    CommandError,
    "players_per_team must be an integer between 5 and 15",
  );
});

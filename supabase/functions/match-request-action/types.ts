// Canonical match-request-action types.
//
// Action envelope:
//   action: "accept_challenge" | "accept_pool_application"
//   body: Record<string, unknown>

// deno-lint-ignore no-explicit-any
export type Tx = any;

export type Action = "accept_challenge" | "accept_pool_application";

export interface RequestEnvelope {
  action: Action;
  body: Record<string, unknown>;
}

export interface AcceptChallengeInput {
  requestId: string;
  decisionNote: string | null;
  toTeamId: string | null;
}

export interface AcceptPoolApplicationInput {
  applicationId: string;
  decisionNote: string | null;
}

export interface CommandContext {
  tx: Tx;
  actorId: string;
  body: Record<string, unknown>;
}

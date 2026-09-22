// Command router for match-request-action.
// Parses the typed input from the envelope body and dispatches to the
// appropriate command, returning { matchId }.

import type { Action, Tx } from "./types.ts";
import { parseAcceptChallenge, parseAcceptPoolApplication } from "./domain/validation.ts";
import {
  acceptChallenge,
} from "./commands/accept_challenge.ts";
import {
  acceptPoolApplication,
} from "./commands/accept_pool_application.ts";

export async function routeCommand(
  tx: Tx,
  action: Action,
  actorId: string,
  body: Record<string, unknown>,
): Promise<{ matchId: string }> {
  switch (action) {
    case "accept_challenge": {
      const input = parseAcceptChallenge(body);
      return await acceptChallenge({ tx, actorId, input });
    }

    case "accept_pool_application": {
      const input = parseAcceptPoolApplication(body);
      return await acceptPoolApplication({ tx, actorId, input });
    }
  }
}

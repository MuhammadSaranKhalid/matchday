// Auth Service: JWT token verification and transaction-local claim injection.
// Standard @supabase/server implementation (https://supabase.com/docs/guides/functions/auth)

import { createSupabaseContext } from "npm:@supabase/server";

export interface AuthResult {
  actorId?: string;
  error?: {
    status: number;
    code: string;
    message: string;
  };
}

export async function authenticateRequest(req: Request): Promise<AuthResult> {
  const { data: ctx, error } = await createSupabaseContext(req, { auth: "user" });

  if (error || !ctx) {
    return {
      error: {
        status: error?.status ?? 401,
        code: error?.code ?? "UNAUTHENTICATED",
        message: error?.message ?? "Invalid or missing session token",
      },
    };
  }

  const actorId = ctx.userClaims?.id ?? (ctx.jwtClaims?.sub as string | undefined);
  if (!actorId) {
    return {
      error: {
        status: 401,
        code: "UNAUTHENTICATED",
        message: "No user identity found in session claims",
      },
    };
  }

  return { actorId };
}

// Injects verified identity into the postgres transaction for RLS & _can_score_innings
// deno-lint-ignore no-explicit-any
export async function setTransactionJwtClaims(tx: any, actorId: string): Promise<void> {
  await tx`
    select set_config(
      'request.jwt.claims',
      ${JSON.stringify({ sub: actorId, role: "authenticated" })},
      true
    )`;
}

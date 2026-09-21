export class CommandError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "CommandError";
  }
}

export function badRequest(message: string): never {
  throw new CommandError(400, "BAD_REQUEST", message);
}

export function forbidden(message: string): never {
  throw new CommandError(403, "FORBIDDEN", message);
}

export function notFound(message: string): never {
  throw new CommandError(404, "NOT_FOUND", message);
}

export function conflict(message: string): never {
  throw new CommandError(409, "CONFLICT", message);
}

export function unprocessable(message: string): never {
  throw new CommandError(422, "RULE_VIOLATION", message);
}

export function normalizeUnexpectedError(error: unknown): {
  status: number;
  code: string;
  message: string;
} {
  if (error instanceof CommandError) {
    return {
      status: error.status,
      code: error.code,
      message: error.message,
    };
  }

  const raw = error as {
    code?: string;
    message?: string;
    detail?: string;
  };

  const pgCode = raw?.code;
  const message =
    raw?.message ??
    raw?.detail ??
    (error instanceof Error
      ? error.message
      : String(error));

  if (pgCode === "42501" || pgCode === "28000") {
    return {
      status: 403,
      code: pgCode,
      message,
    };
  }

  if (pgCode === "22P02" || pgCode === "22023") {
    return {
      status: 400,
      code: pgCode,
      message,
    };
  }

  if (
    pgCode === "23502" ||
    pgCode === "23503" ||
    pgCode === "23514"
  ) {
    return {
      status: 422,
      code: pgCode,
      message,
    };
  }

  if (pgCode === "23505") {
    return {
      status: 409,
      code: pgCode,
      message,
    };
  }

  return {
    status: 500,
    code: pgCode ?? "INTERNAL_ERROR",
    message,
  };
}

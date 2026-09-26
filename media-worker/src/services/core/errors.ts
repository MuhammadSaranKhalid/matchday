export class TransientMediaError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'TransientMediaError';
  }
}

export class PermanentMediaError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'PermanentMediaError';
  }
}

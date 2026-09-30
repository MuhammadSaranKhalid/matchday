export const MEDIA_RUNTIME = Symbol('MEDIA_RUNTIME');

export interface MediaRuntime {
  waitUntilReady(): Promise<void>;
}

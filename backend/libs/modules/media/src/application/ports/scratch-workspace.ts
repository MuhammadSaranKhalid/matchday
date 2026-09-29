export const SCRATCH_WORKSPACE = Symbol('SCRATCH_WORKSPACE');

export interface ScratchWorkspace {
  use<T>(work: (workspace: string) => Promise<T>): Promise<T>;
}

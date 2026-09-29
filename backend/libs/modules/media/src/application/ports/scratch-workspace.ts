export interface ScratchWorkspace {
  use<T>(work: (workspace: string) => Promise<T>): Promise<T>;
}

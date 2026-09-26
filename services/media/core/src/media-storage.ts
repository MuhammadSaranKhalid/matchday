export interface MediaStorage {
  downloadStaging(stagingPath: string): Promise<Buffer>;
  uploadFinal(path: string, bytes: Buffer): Promise<void>;
  deleteStaging(stagingPath: string): Promise<void>;
}

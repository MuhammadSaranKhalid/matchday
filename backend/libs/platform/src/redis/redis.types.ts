import type { Redis } from 'ioredis';

export interface RedisConnections {
  readonly command: Redis;
  duplicate(purpose: string): Redis;
  key(unqualifiedKey: string): string;
}

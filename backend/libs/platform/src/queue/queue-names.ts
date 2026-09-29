export const QUEUE_NAMES = Object.freeze([
  'notifications',
  'media',
  'maintenance',
] as const);

export type QueueName = (typeof QUEUE_NAMES)[number];

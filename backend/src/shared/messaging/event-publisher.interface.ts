// backend/src/shared/messaging/event-publisher.interface.ts
export interface IEventPublisher {
  publish(routingKey: string, payload: unknown): Promise<void>
}

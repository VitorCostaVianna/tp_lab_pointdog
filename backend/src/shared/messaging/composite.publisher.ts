import { IEventPublisher } from './event-publisher.interface'

export class CompositePublisher implements IEventPublisher {
  constructor(private readonly publishers: IEventPublisher[]) {}

  async publish(routingKey: string, payload: unknown): Promise<void> {
    await Promise.all(this.publishers.map((p) => p.publish(routingKey, payload)))
  }
}

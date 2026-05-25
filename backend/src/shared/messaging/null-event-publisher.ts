// backend/src/shared/messaging/null-event-publisher.ts
import { IEventPublisher } from './event-publisher.interface'

export class NullEventPublisher implements IEventPublisher {
  async publish(_routingKey: string, _payload: unknown): Promise<void> {
    // no-op: usado em testes e quando mensageria está desabilitada
  }
}

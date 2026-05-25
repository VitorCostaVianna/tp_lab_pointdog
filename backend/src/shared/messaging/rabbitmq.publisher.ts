// backend/src/shared/messaging/rabbitmq.publisher.ts
import amqp, { Channel, ChannelModel } from 'amqplib'
import { IEventPublisher } from './event-publisher.interface'

const EXCHANGE = 'pointdog.events'

export class RabbitMQPublisher implements IEventPublisher {
  private connection: ChannelModel | null = null
  private channel: Channel | null = null

  async connect(url: string): Promise<void> {
    this.connection = await amqp.connect(url)
    this.channel = await this.connection.createChannel()
    await this.channel.assertExchange(EXCHANGE, 'topic', { durable: true })
    console.log('[RabbitMQ] Conectado. Exchange "pointdog.events" declarado.')
  }

  async publish(routingKey: string, payload: unknown): Promise<void> {
    if (!this.channel) throw new Error('RabbitMQ não conectado. Chame connect() antes.')
    const buffer = Buffer.from(JSON.stringify(payload))
    const sent = this.channel.publish(EXCHANGE, routingKey, buffer, { persistent: true })
    if (!sent) throw new Error('RabbitMQ: buffer do canal cheio, mensagem não enviada')
  }

  async close(): Promise<void> {
    await this.channel?.close()
    await this.connection?.close()
  }
}

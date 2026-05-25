// backend/src/shared/messaging/rabbitmq.consumer.ts
import amqp from 'amqplib'

export async function startConsumer(
  url: string,
  exchange: string,
  queue: string,
  bindingPattern: string,
  handler: (routingKey: string, payload: unknown) => Promise<void>,
): Promise<void> {
  const connection = await amqp.connect(url)
  const channel = await connection.createChannel()

  await channel.assertExchange(exchange, 'topic', { durable: true })
  await channel.assertQueue(queue, { durable: true })
  await channel.bindQueue(queue, exchange, bindingPattern)
  channel.prefetch(1)

  console.log(`[Consumer] Fila "${queue}" pronta. Binding: "${bindingPattern}" → "${exchange}"`)
  console.log(`[Consumer] Aguardando mensagens...`)

  channel.consume(queue, async (msg) => {
    if (!msg) return
    try {
      const payload = JSON.parse(msg.content.toString()) as unknown
      await handler(msg.fields.routingKey, payload)
      channel.ack(msg)
    } catch (err) {
      console.error('[Consumer] Erro ao processar mensagem:', err)
      channel.nack(msg, false, false)
    }
  })
}

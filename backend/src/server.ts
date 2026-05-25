import 'dotenv/config'
import { createApp } from './app'
import { createPrismaClient } from './shared/prisma'
import { RabbitMQPublisher } from './shared/messaging/rabbitmq.publisher'

async function start(): Promise<void> {
  const prisma = createPrismaClient()
  const publisher = new RabbitMQPublisher()

  const rabbitmqUrl = process.env.RABBITMQ_URL ?? 'amqp://guest:guest@localhost:5672'
  await publisher.connect(rabbitmqUrl)

  const port = process.env.PORT ?? 3000
  const app = createApp(prisma, publisher)

  app.listen(port, () => {
    console.log(`[API] Servidor na porta ${port}`)
  })
}

start().catch((err) => {
  console.error('[API] Falha ao iniciar:', err)
  process.exit(1)
})

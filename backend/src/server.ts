import 'dotenv/config'
import http from 'http'
import { createApp } from './app'
import { createPrismaClient } from './shared/prisma'
import { RabbitMQPublisher } from './shared/messaging/rabbitmq.publisher'
import { WebSocketEventPublisher } from './shared/messaging/websocket.server'
import { CompositePublisher } from './shared/messaging/composite.publisher'
import { JwtService } from './shared/services/jwt.service'

async function start(): Promise<void> {
  const prisma = createPrismaClient()
  const jwtService = new JwtService()

  const rabbitMQ = new RabbitMQPublisher()
  const rabbitmqUrl = process.env.RABBITMQ_URL ?? 'amqp://guest:guest@localhost:5672'
  await rabbitMQ.connect(rabbitmqUrl)

  // Cria HTTP server antes do app para poder anexar o WS server
  const server = http.createServer()
  const wsPublisher = new WebSocketEventPublisher(server, jwtService)
  const publisher = new CompositePublisher([rabbitMQ, wsPublisher])

  const app = createApp(prisma, publisher)
  server.on('request', app)

  const port = process.env.PORT ?? 3000
  server.listen(port, () => {
    console.log(`[API] Servidor na porta ${port}`)
    console.log(`[WS]  WebSocket disponível em ws://localhost:${port}/ws`)
  })
}

start().catch((err) => {
  console.error('[API] Falha ao iniciar:', err)
  process.exit(1)
})

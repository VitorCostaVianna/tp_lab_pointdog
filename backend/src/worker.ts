import 'dotenv/config'
import { startConsumer } from './shared/messaging/rabbitmq.consumer'
import { handleAppointmentEvent } from './workers/appointment.worker'

const RABBITMQ_URL = process.env.RABBITMQ_URL ?? 'amqp://guest:guest@localhost:5672'
const EXCHANGE = 'pointdog.events'
const QUEUE = 'pointdog.notifications'
const BINDING = 'appointment.*'

async function start(): Promise<void> {
  console.log('[Worker] Iniciando PointDog Event Worker...')
  await startConsumer(RABBITMQ_URL, EXCHANGE, QUEUE, BINDING, handleAppointmentEvent)
  console.log('[Worker] Pronto para receber eventos.')
}

start().catch((err) => {
  console.error('[Worker] Falha ao iniciar:', err)
  process.exit(1)
})

import http from 'http'
import { WebSocket } from 'ws'
import { WebSocketEventPublisher } from './websocket.server'
import { JwtService } from '../services/jwt.service'

function fakeWs(): { ws: WebSocket; sent: string[] } {
  const sent: string[] = []
  const ws = {
    readyState: WebSocket.OPEN,
    send: (msg: string) => sent.push(msg),
  } as unknown as WebSocket
  return { ws, sent }
}

describe('WebSocketEventPublisher', () => {
  let server: http.Server
  let publisher: WebSocketEventPublisher

  beforeEach(() => {
    server = http.createServer()
    const jwt = new JwtService()
    publisher = new WebSocketEventPublisher(server, jwt)
  })

  afterEach(() => {
    server.close()
  })

  function register(publisher: WebSocketEventPublisher, userId: string, ws: WebSocket): void {
    const clients = (publisher as any).clients as Map<string, Set<WebSocket>>
    if (!clients.has(userId)) clients.set(userId, new Set())
    clients.get(userId)!.add(ws)
  }

  it('routes appointment.status_changed to the clientId', async () => {
    const client = fakeWs()
    register(publisher, 'client-1', client.ws)

    const event = {
      eventType: 'appointment.status_changed',
      timestamp: new Date().toISOString(),
      payload: {
        appointmentId: 'apt-1',
        clientId: 'client-1',
        providerId: 'provider-1',
        previousStatus: 'PENDENTE',
        newStatus: 'CONFIRMADO',
        changedBy: 'provider-1',
      },
    }

    await publisher.publish('appointment.status_changed', event)

    expect(client.sent).toHaveLength(1)
    expect(JSON.parse(client.sent[0]).payload.newStatus).toBe('CONFIRMADO')
  })

  it('routes appointment.created to BOTH providerId and clientId', async () => {
    const client = fakeWs()
    const provider = fakeWs()
    register(publisher, 'client-1', client.ws)
    register(publisher, 'provider-1', provider.ws)

    const event = {
      eventType: 'appointment.created',
      timestamp: new Date().toISOString(),
      payload: {
        appointmentId: 'apt-1',
        clientId: 'client-1',
        petId: 'pet-1',
        providerId: 'provider-1',
        serviceId: 'svc-1',
        scheduledAt: new Date().toISOString(),
        status: 'PENDENTE',
      },
    }

    await publisher.publish('appointment.created', event)

    expect(provider.sent).toHaveLength(1)
    expect(JSON.parse(provider.sent[0]).payload.appointmentId).toBe('apt-1')
    expect(client.sent).toHaveLength(1)
  })

  it('does not send to a provider with no connections', async () => {
    const client = fakeWs()
    register(publisher, 'client-1', client.ws)

    const event = {
      eventType: 'appointment.created',
      timestamp: new Date().toISOString(),
      payload: {
        appointmentId: 'apt-1',
        clientId: 'client-1',
        providerId: 'provider-unknown',
        petId: 'pet-1',
        serviceId: 'svc-1',
        scheduledAt: new Date().toISOString(),
        status: 'PENDENTE',
      },
    }

    await publisher.publish('appointment.created', event)

    expect(client.sent).toHaveLength(1)
  })

  it('does nothing when payload has neither clientId nor providerId', async () => {
    const client = fakeWs()
    register(publisher, 'client-1', client.ws)

    await publisher.publish('noise', { eventType: 'noise', payload: {} })

    expect(client.sent).toHaveLength(0)
  })
})

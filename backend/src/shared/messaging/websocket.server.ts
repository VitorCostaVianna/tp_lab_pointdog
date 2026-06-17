import { WebSocketServer, WebSocket } from 'ws'
import http from 'http'
import { JwtService } from '../services/jwt.service'
import { IEventPublisher } from './event-publisher.interface'

interface RoutableEvent {
  eventType?: string
  payload?: {
    clientId?: string
    providerId?: string
  }
}

export class WebSocketEventPublisher implements IEventPublisher {
  private readonly wss: WebSocketServer
  private readonly clients = new Map<string, Set<WebSocket>>()

  constructor(server: http.Server, private readonly jwtService: JwtService) {
    this.wss = new WebSocketServer({ server, path: '/ws' })
    this.wss.on('connection', (ws, req) => this.handleConnection(ws, req))
  }

  private handleConnection(ws: WebSocket, req: http.IncomingMessage): void {
    const url = new URL(req.url ?? '', 'ws://localhost')
    const token = url.searchParams.get('token')

    if (!token) {
      ws.close(1008, 'Missing token')
      return
    }

    let clientId: string
    try {
      const payload = this.jwtService.verify(token)
      clientId = payload.sub
    } catch {
      ws.close(1008, 'Invalid token')
      return
    }

    if (!this.clients.has(clientId)) {
      this.clients.set(clientId, new Set())
    }
    this.clients.get(clientId)!.add(ws)
    console.log(`[WS] Cliente conectado: ${clientId} (total: ${this.clients.get(clientId)!.size})`)

    ws.on('close', () => {
      this.clients.get(clientId)?.delete(ws)
      console.log(`[WS] Cliente desconectado: ${clientId}`)
    })
  }

  async publish(_routingKey: string, payload: unknown): Promise<void> {
    const event = payload as RoutableEvent
    const message = JSON.stringify(payload)

    const targets = new Set<string>()
    if (event?.payload?.clientId) targets.add(event.payload.clientId)
    if (event?.payload?.providerId) targets.add(event.payload.providerId)

    for (const userId of targets) {
      this.sendToUser(userId, message)
    }
  }

  private sendToUser(userId: string, message: string): void {
    const connections = this.clients.get(userId)
    if (!connections?.size) return

    for (const ws of connections) {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message)
      }
    }
  }
}

// backend/src/workers/appointment.worker.ts

interface AppointmentCreatedPayload {
  appointmentId: string
  clientId: string
  petId: string
  providerId: string
  serviceId: string
  scheduledAt: string
  status: string
}

interface AppointmentStatusChangedPayload {
  appointmentId: string
  clientId: string
  providerId: string
  previousStatus: string
  newStatus: string
  changedBy: string
}

interface DomainEvent {
  eventType: string
  timestamp: string
  payload: AppointmentCreatedPayload | AppointmentStatusChangedPayload
}

export async function handleAppointmentEvent(
  routingKey: string,
  event: unknown,
): Promise<void> {
  const { eventType, timestamp, payload } = event as DomainEvent
  console.log(`\n[WORKER] ─── Evento recebido ───────────────────────`)
  console.log(`[WORKER] Tipo: ${eventType}`)
  console.log(`[WORKER] Timestamp: ${timestamp}`)

  if (eventType === 'appointment.created') {
    const p = payload as AppointmentCreatedPayload
    console.log(`[WORKER] Novo agendamento criado: ${p.appointmentId}`)
    console.log(`[WORKER] Cliente: ${p.clientId} | Pet: ${p.petId}`)
    console.log(`[WORKER] Prestador: ${p.providerId} | Serviço: ${p.serviceId}`)
    console.log(`[WORKER] Agendado para: ${p.scheduledAt}`)
    console.log(`[WORKER] → Simulando notificação ao prestador ${p.providerId}...`)
    console.log(`[WORKER] ✓ Notificação enviada.`)
  } else if (eventType === 'appointment.status_changed') {
    const p = payload as AppointmentStatusChangedPayload
    console.log(`[WORKER] Agendamento: ${p.appointmentId}`)
    console.log(`[WORKER] Status: ${p.previousStatus} → ${p.newStatus}`)
    console.log(`[WORKER] Alterado por: ${p.changedBy}`)
    console.log(`[WORKER] → Simulando notificação ao cliente ${p.clientId}...`)
    console.log(`[WORKER] ✓ Notificação enviada.`)
  } else {
    console.log(`[WORKER] Evento desconhecido ignorado: ${eventType}`)
  }

  console.log(`[WORKER] ────────────────────────────────────────────`)
}

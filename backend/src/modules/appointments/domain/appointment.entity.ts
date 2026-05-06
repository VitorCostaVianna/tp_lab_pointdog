export type AppointmentStatus = 'PENDENTE' | 'CONFIRMADO' | 'CANCELADO' | 'CONCLUIDO'

export interface Appointment {
  id: string
  scheduledAt: Date
  status: AppointmentStatus
  notes?: string
  clientId: string
  petId: string
  providerId: string
  serviceId: string
}

import { Appointment } from './appointment.entity'

export interface IAppointmentRepository {
  create(data: Omit<Appointment, 'id' | 'status'>): Promise<Appointment>
  findAllByClient(clientId: string): Promise<Appointment[]>
  findAllByProvider(providerId: string): Promise<Appointment[]>
  findById(id: string): Promise<Appointment | null>
  updateStatus(id: string, status: string): Promise<Appointment>
}

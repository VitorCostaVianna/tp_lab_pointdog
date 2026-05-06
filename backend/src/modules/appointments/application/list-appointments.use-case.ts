import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'

interface ListAppointmentsInput {
  userId: string
  role: 'CLIENTE' | 'PRESTADOR'
}

export class ListAppointmentsUseCase {
  constructor(private readonly repository: IAppointmentRepository) {}

  async execute(input: ListAppointmentsInput): Promise<Appointment[]> {
    if (input.role === 'CLIENTE') {
      return this.repository.findAllByClient(input.userId)
    }
    return this.repository.findAllByProvider(input.userId)
  }
}

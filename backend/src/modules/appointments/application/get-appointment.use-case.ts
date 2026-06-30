import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'
import { assertAppointmentAccess } from '../domain/appointment.access'
import { AppError } from '../../../shared/errors/app-error'

interface GetAppointmentInput {
  id: string
  requestingUserId: string
  requestingRole: 'CLIENTE' | 'PRESTADOR'
}

export class GetAppointmentUseCase {
  constructor(private readonly repository: IAppointmentRepository) {}

  async execute(input: GetAppointmentInput): Promise<Appointment> {
    const appointment = await this.repository.findById(input.id)

    if (!appointment) {
      throw new AppError('Agendamento não encontrado', 404)
    }

    assertAppointmentAccess(appointment, input.requestingUserId, input.requestingRole)

    return appointment
  }
}

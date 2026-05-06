import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'
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

    if (input.requestingRole === 'CLIENTE' && appointment.clientId !== input.requestingUserId) {
      throw new AppError('Acesso negado', 403)
    }

    if (input.requestingRole === 'PRESTADOR' && appointment.providerId !== input.requestingUserId) {
      throw new AppError('Acesso negado', 403)
    }

    return appointment
  }
}

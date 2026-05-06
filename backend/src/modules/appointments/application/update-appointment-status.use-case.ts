import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'
import { AppError } from '../../../shared/errors/app-error'

interface UpdateAppointmentStatusInput {
  id: string
  requestingUserId: string
  requestingRole: 'CLIENTE' | 'PRESTADOR'
  newStatus: string
}

const validTransitions: Record<string, { to: string; allowedRoles: string[] }[]> = {
  PENDENTE: [
    { to: 'CONFIRMADO', allowedRoles: ['PRESTADOR'] },
    { to: 'CANCELADO', allowedRoles: ['CLIENTE', 'PRESTADOR'] },
  ],
  CONFIRMADO: [
    { to: 'CANCELADO', allowedRoles: ['CLIENTE', 'PRESTADOR'] },
    { to: 'CONCLUIDO', allowedRoles: ['PRESTADOR'] },
  ],
}

export class UpdateAppointmentStatusUseCase {
  constructor(private readonly repository: IAppointmentRepository) {}

  async execute(input: UpdateAppointmentStatusInput): Promise<Appointment> {
    const appointment = await this.repository.findById(input.id)

    if (!appointment) {
      throw new AppError('Agendamento não encontrado', 404)
    }

    // Check ownership
    if (input.requestingRole === 'CLIENTE' && appointment.clientId !== input.requestingUserId) {
      throw new AppError('Acesso negado', 403)
    }

    if (input.requestingRole === 'PRESTADOR' && appointment.providerId !== input.requestingUserId) {
      throw new AppError('Acesso negado', 403)
    }

    const currentStatus = appointment.status

    // Check if appointment is already finalized
    if (currentStatus === 'CANCELADO' || currentStatus === 'CONCLUIDO') {
      throw new AppError('Agendamento já finalizado', 400)
    }

    const transitions = validTransitions[currentStatus] ?? []
    const transition = transitions.find((t) => t.to === input.newStatus)

    if (!transition) {
      throw new AppError('Transição de status inválida', 400)
    }

    if (!transition.allowedRoles.includes(input.requestingRole)) {
      throw new AppError('Sem permissão para esta transição', 403)
    }

    return this.repository.updateStatus(input.id, input.newStatus)
  }
}

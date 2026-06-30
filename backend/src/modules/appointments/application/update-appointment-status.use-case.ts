import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'
import { assertAppointmentAccess } from '../domain/appointment.access'
import { IEventPublisher } from '../../../shared/messaging/event-publisher.interface'
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
  constructor(
    private readonly repository: IAppointmentRepository,
    private readonly eventPublisher: IEventPublisher,
  ) {}

  async execute(input: UpdateAppointmentStatusInput): Promise<Appointment> {
    const appointment = await this.repository.findById(input.id)

    if (!appointment) {
      throw new AppError('Agendamento não encontrado', 404)
    }

    assertAppointmentAccess(appointment, input.requestingUserId, input.requestingRole)

    const currentStatus = appointment.status

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

    const updated = await this.repository.updateStatus(input.id, input.newStatus)

    await this.eventPublisher.publish('appointment.status_changed', {
      eventType: 'appointment.status_changed',
      timestamp: new Date().toISOString(),
      payload: {
        appointmentId: updated.id,
        clientId: updated.clientId,
        providerId: updated.providerId,
        previousStatus: currentStatus,
        newStatus: input.newStatus,
        changedBy: input.requestingUserId,
      },
    })

    return updated
  }
}

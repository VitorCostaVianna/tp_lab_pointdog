import { Appointment } from './appointment.entity'
import { AppError } from '../../../shared/errors/app-error'

type RequestingRole = 'CLIENTE' | 'PRESTADOR'

/**
 * Regra de autorização de acesso a um agendamento:
 * - CLIENTE só acessa agendamentos onde é o cliente
 * - PRESTADOR só acessa agendamentos onde é o prestador
 *
 * Extraída para evitar duplicação entre GetAppointmentUseCase e
 * UpdateAppointmentStatusUseCase (DRY).
 */
export function assertAppointmentAccess(
  appointment: Appointment,
  requestingUserId: string,
  requestingRole: RequestingRole,
): void {
  if (requestingRole === 'CLIENTE' && appointment.clientId !== requestingUserId) {
    throw new AppError('Acesso negado', 403)
  }
  if (requestingRole === 'PRESTADOR' && appointment.providerId !== requestingUserId) {
    throw new AppError('Acesso negado', 403)
  }
}

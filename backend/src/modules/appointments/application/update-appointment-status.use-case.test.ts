import { UpdateAppointmentStatusUseCase } from './update-appointment-status.use-case'
import { IAppointmentRepository } from '../domain/appointment.repository'
import { IEventPublisher } from '../../../shared/messaging/event-publisher.interface'
import { Appointment } from '../domain/appointment.entity'
import { AppError } from '../../../shared/errors/app-error'

function makeMockRepo(): jest.Mocked<IAppointmentRepository> {
  return {
    create: jest.fn(),
    findAllByClient: jest.fn(),
    findAllByProvider: jest.fn(),
    findById: jest.fn(),
    updateStatus: jest.fn(),
  }
}

function makeMockPublisher(): jest.Mocked<IEventPublisher> {
  return { publish: jest.fn() }
}

const baseAppointment: Appointment = {
  id: 'appt-1',
  scheduledAt: new Date('2030-01-01'),
  status: 'PENDENTE',
  clientId: 'client-1',
  petId: 'pet-1',
  providerId: 'provider-1',
  serviceId: 'svc-1',
}

describe('UpdateAppointmentStatusUseCase', () => {
  it('atualiza status e publica evento appointment.status_changed', async () => {
    const repo = makeMockRepo()
    const publisher = makeMockPublisher()

    const updatedAppointment: Appointment = { ...baseAppointment, status: 'CONFIRMADO' }
    repo.findById.mockResolvedValue(baseAppointment)
    repo.updateStatus.mockResolvedValue(updatedAppointment)
    publisher.publish.mockResolvedValue(undefined)

    const useCase = new UpdateAppointmentStatusUseCase(repo, publisher)
    const result = await useCase.execute({
      id: 'appt-1',
      requestingUserId: 'provider-1',
      requestingRole: 'PRESTADOR',
      newStatus: 'CONFIRMADO',
    })

    expect(result.status).toBe('CONFIRMADO')
    expect(publisher.publish).toHaveBeenCalledWith(
      'appointment.status_changed',
      expect.objectContaining({
        eventType: 'appointment.status_changed',
        payload: expect.objectContaining({
          appointmentId: 'appt-1',
          previousStatus: 'PENDENTE',
          newStatus: 'CONFIRMADO',
          changedBy: 'provider-1',
        }),
      }),
    )
  })

  it('lança AppError 400 para transição inválida e não publica evento', async () => {
    const repo = makeMockRepo()
    const publisher = makeMockPublisher()

    repo.findById.mockResolvedValue(baseAppointment)

    const useCase = new UpdateAppointmentStatusUseCase(repo, publisher)
    await expect(
      useCase.execute({
        id: 'appt-1',
        requestingUserId: 'provider-1',
        requestingRole: 'PRESTADOR',
        newStatus: 'CONCLUIDO',
      }),
    ).rejects.toThrow(new AppError('Transição de status inválida', 400))

    expect(publisher.publish).not.toHaveBeenCalled()
  })

  it('lança AppError 404 quando agendamento não existe', async () => {
    const repo = makeMockRepo()
    repo.findById.mockResolvedValue(null)

    const useCase = new UpdateAppointmentStatusUseCase(repo, makeMockPublisher())
    await expect(
      useCase.execute({
        id: 'nao-existe',
        requestingUserId: 'provider-1',
        requestingRole: 'PRESTADOR',
        newStatus: 'CONFIRMADO',
      }),
    ).rejects.toThrow(new AppError('Agendamento não encontrado', 404))
  })
})

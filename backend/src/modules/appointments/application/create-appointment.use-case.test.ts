import { CreateAppointmentUseCase } from './create-appointment.use-case'
import { IAppointmentRepository } from '../domain/appointment.repository'
import { IPetRepository } from '../../pets/domain/pet.repository'
import { IServiceRepository } from '../../services/domain/service.repository'
import { IEventPublisher } from '../../../shared/messaging/event-publisher.interface'
import { Appointment } from '../domain/appointment.entity'
import { AppError } from '../../../shared/errors/app-error'

function makeMockAppointmentRepo(): jest.Mocked<IAppointmentRepository> {
  return {
    create: jest.fn(),
    findAllByClient: jest.fn(),
    findAllByProvider: jest.fn(),
    findById: jest.fn(),
    updateStatus: jest.fn(),
  }
}

function makeMockPetRepo(): jest.Mocked<IPetRepository> {
  return {
    create: jest.fn(),
    findAllByOwner: jest.fn(),
    findById: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  }
}

function makeMockServiceRepo(): jest.Mocked<IServiceRepository> {
  return {
    create: jest.fn(),
    findAll: jest.fn(),
    findAllByProvider: jest.fn(),
    findById: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  }
}

function makeMockPublisher(): jest.Mocked<IEventPublisher> {
  return { publish: jest.fn() }
}

const tomorrow = new Date(Date.now() + 86_400_000)

describe('CreateAppointmentUseCase', () => {
  it('cria agendamento e publica evento appointment.created', async () => {
    const appointmentRepo = makeMockAppointmentRepo()
    const petRepo = makeMockPetRepo()
    const serviceRepo = makeMockServiceRepo()
    const publisher = makeMockPublisher()

    petRepo.findById.mockResolvedValue({
      id: 'pet-1', name: 'Rex', breed: 'Lab', size: 'GRANDE', ownerId: 'client-1',
    })
    serviceRepo.findById.mockResolvedValue({
      id: 'svc-1', name: 'Banho', description: '', price: 50, durationMinutes: 60, providerId: 'provider-1',
    })
    const mockAppointment: Appointment = {
      id: 'appt-1',
      scheduledAt: tomorrow,
      status: 'PENDENTE',
      clientId: 'client-1',
      petId: 'pet-1',
      providerId: 'provider-1',
      serviceId: 'svc-1',
    }
    appointmentRepo.create.mockResolvedValue(mockAppointment)
    publisher.publish.mockResolvedValue(undefined)

    const useCase = new CreateAppointmentUseCase(appointmentRepo, petRepo, serviceRepo, publisher)
    const result = await useCase.execute({
      scheduledAt: tomorrow,
      clientId: 'client-1',
      petId: 'pet-1',
      providerId: 'provider-1',
      serviceId: 'svc-1',
    })

    expect(result).toEqual(mockAppointment)
    expect(publisher.publish).toHaveBeenCalledWith(
      'appointment.created',
      expect.objectContaining({
        eventType: 'appointment.created',
        payload: expect.objectContaining({
          appointmentId: 'appt-1',
          status: 'PENDENTE',
          clientId: 'client-1',
        }),
      }),
    )
  })

  it('lança AppError 400 quando scheduledAt está no passado', async () => {
    const useCase = new CreateAppointmentUseCase(
      makeMockAppointmentRepo(),
      makeMockPetRepo(),
      makeMockServiceRepo(),
      makeMockPublisher(),
    )
    await expect(
      useCase.execute({
        scheduledAt: new Date('2000-01-01'),
        clientId: 'c1',
        petId: 'p1',
        providerId: 'pr1',
        serviceId: 's1',
      }),
    ).rejects.toThrow(new AppError('Data deve ser futura', 400))
  })

  it('não publica evento quando pet não é encontrado', async () => {
    const petRepo = makeMockPetRepo()
    const publisher = makeMockPublisher()
    petRepo.findById.mockResolvedValue(null)

    const useCase = new CreateAppointmentUseCase(
      makeMockAppointmentRepo(),
      petRepo,
      makeMockServiceRepo(),
      publisher,
    )
    await expect(
      useCase.execute({
        scheduledAt: tomorrow,
        clientId: 'c1',
        petId: 'p1',
        providerId: 'pr1',
        serviceId: 's1',
      }),
    ).rejects.toThrow()

    expect(publisher.publish).not.toHaveBeenCalled()
  })
})

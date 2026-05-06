import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'
import { IPetRepository } from '../../pets/domain/pet.repository'
import { IServiceRepository } from '../../services/domain/service.repository'
import { AppError } from '../../../shared/errors/app-error'

interface CreateAppointmentInput {
  scheduledAt: Date
  notes?: string
  clientId: string
  petId: string
  providerId: string
  serviceId: string
}

export class CreateAppointmentUseCase {
  constructor(
    private readonly appointmentRepo: IAppointmentRepository,
    private readonly petRepo: IPetRepository,
    private readonly serviceRepo: IServiceRepository,
  ) {}

  async execute(input: CreateAppointmentInput): Promise<Appointment> {
    if (input.scheduledAt <= new Date()) {
      throw new AppError('Data deve ser futura', 400)
    }

    // Verify pet exists and belongs to the client
    const pet = await this.petRepo.findById(input.petId)
    if (!pet) throw new AppError('Pet não encontrado', 404)
    if (pet.ownerId !== input.clientId) throw new AppError('Pet não pertence ao cliente', 403)

    // Verify service exists
    const service = await this.serviceRepo.findById(input.serviceId)
    if (!service) throw new AppError('Serviço não encontrado', 404)

    return this.appointmentRepo.create(input)
  }
}

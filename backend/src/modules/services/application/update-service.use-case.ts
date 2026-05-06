import { Service } from '../domain/service.entity'
import { IServiceRepository } from '../domain/service.repository'
import { AppError } from '../../../shared/errors/app-error'

export interface UpdateServiceInput {
  id: string
  requestingUserId: string
  data: Partial<Omit<Service, 'id' | 'providerId'>>
}

export class UpdateServiceUseCase {
  constructor(private readonly repository: IServiceRepository) {}

  async execute(input: UpdateServiceInput): Promise<Service> {
    const service = await this.repository.findById(input.id)
    if (!service) throw new AppError('Serviço não encontrado', 404)
    if (service.providerId !== input.requestingUserId) throw new AppError('Acesso negado', 403)
    if (input.data.price !== undefined && input.data.price <= 0) {
      throw new AppError('Preço deve ser positivo', 400)
    }
    if (input.data.durationMinutes !== undefined && input.data.durationMinutes <= 0) {
      throw new AppError('Duração deve ser positiva', 400)
    }
    return this.repository.update(input.id, input.data)
  }
}

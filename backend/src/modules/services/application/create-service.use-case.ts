import { Service } from '../domain/service.entity'
import { IServiceRepository } from '../domain/service.repository'
import { AppError } from '../../../shared/errors/app-error'

export interface CreateServiceInput {
  name: string
  description: string
  price: number
  durationMinutes: number
  providerId: string
}

export class CreateServiceUseCase {
  constructor(private readonly repository: IServiceRepository) {}

  async execute(input: CreateServiceInput): Promise<Service> {
    if (input.price <= 0) {
      throw new AppError('Preço deve ser positivo', 400)
    }
    if (input.durationMinutes <= 0) {
      throw new AppError('Duração deve ser positiva', 400)
    }
    return this.repository.create(input)
  }
}

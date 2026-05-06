import { Service } from '../domain/service.entity'
import { IServiceRepository } from '../domain/service.repository'
import { AppError } from '../../../shared/errors/app-error'

export interface GetServiceInput {
  id: string
}

export class GetServiceUseCase {
  constructor(private readonly repository: IServiceRepository) {}

  async execute(input: GetServiceInput): Promise<Service> {
    const service = await this.repository.findById(input.id)
    if (!service) throw new AppError('Serviço não encontrado', 404)
    return service
  }
}

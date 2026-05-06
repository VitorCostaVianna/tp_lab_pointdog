import { Service } from '../domain/service.entity'
import { IServiceRepository } from '../domain/service.repository'

export interface ListServicesInput {
  providerId?: string
}

export class ListServicesUseCase {
  constructor(private readonly repository: IServiceRepository) {}

  async execute(input: ListServicesInput): Promise<Service[]> {
    if (input.providerId) {
      return this.repository.findAllByProvider(input.providerId)
    }
    return this.repository.findAll()
  }
}

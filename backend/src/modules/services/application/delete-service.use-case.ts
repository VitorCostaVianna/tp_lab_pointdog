import { IServiceRepository } from '../domain/service.repository'
import { AppError } from '../../../shared/errors/app-error'

export interface DeleteServiceInput {
  id: string
  requestingUserId: string
}

export class DeleteServiceUseCase {
  constructor(private readonly repository: IServiceRepository) {}

  async execute(input: DeleteServiceInput): Promise<void> {
    const service = await this.repository.findById(input.id)
    if (!service) throw new AppError('Serviço não encontrado', 404)
    if (service.providerId !== input.requestingUserId) throw new AppError('Acesso negado', 403)
    await this.repository.delete(input.id)
  }
}

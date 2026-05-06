import { IPetRepository } from '../domain/pet.repository'
import { AppError } from '../../../shared/errors/app-error'

export interface DeletePetInput {
  id: string
  requestingUserId: string
}

export class DeletePetUseCase {
  constructor(private readonly repository: IPetRepository) {}

  async execute(input: DeletePetInput): Promise<void> {
    const pet = await this.repository.findById(input.id)
    if (!pet) throw new AppError('Pet não encontrado', 404)
    if (pet.ownerId !== input.requestingUserId) throw new AppError('Acesso negado', 403)
    await this.repository.delete(input.id)
  }
}

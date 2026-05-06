import { Pet } from '../domain/pet.entity'
import { IPetRepository } from '../domain/pet.repository'
import { AppError } from '../../../shared/errors/app-error'

export interface GetPetInput {
  id: string
  requestingUserId: string
}

export class GetPetUseCase {
  constructor(private readonly repository: IPetRepository) {}

  async execute(input: GetPetInput): Promise<Pet> {
    const pet = await this.repository.findById(input.id)
    if (!pet) throw new AppError('Pet não encontrado', 404)
    if (pet.ownerId !== input.requestingUserId) throw new AppError('Acesso negado', 403)
    return pet
  }
}

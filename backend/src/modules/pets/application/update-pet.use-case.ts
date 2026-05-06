import { Pet, PetSize } from '../domain/pet.entity'
import { IPetRepository } from '../domain/pet.repository'
import { AppError } from '../../../shared/errors/app-error'

const VALID_SIZES: PetSize[] = ['PEQUENO', 'MEDIO', 'GRANDE']

export interface UpdatePetInput {
  id: string
  requestingUserId: string
  data: Partial<Omit<Pet, 'id' | 'ownerId'>>
}

export class UpdatePetUseCase {
  constructor(private readonly repository: IPetRepository) {}

  async execute(input: UpdatePetInput): Promise<Pet> {
    const pet = await this.repository.findById(input.id)
    if (!pet) throw new AppError('Pet não encontrado', 404)
    if (pet.ownerId !== input.requestingUserId) throw new AppError('Acesso negado', 403)
    if (input.data.size !== undefined && !VALID_SIZES.includes(input.data.size)) {
      throw new AppError('Tamanho inválido', 400)
    }
    return this.repository.update(input.id, input.data)
  }
}

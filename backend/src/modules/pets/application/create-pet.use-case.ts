import { Pet, PetSize } from '../domain/pet.entity'
import { IPetRepository } from '../domain/pet.repository'
import { AppError } from '../../../shared/errors/app-error'

const VALID_SIZES: PetSize[] = ['PEQUENO', 'MEDIO', 'GRANDE']

export interface CreatePetInput {
  name: string
  breed: string
  size: PetSize
  notes?: string
  ownerId: string
}

export class CreatePetUseCase {
  constructor(private readonly repository: IPetRepository) {}

  async execute(input: CreatePetInput): Promise<Pet> {
    if (!VALID_SIZES.includes(input.size)) {
      throw new AppError('Tamanho inválido', 400)
    }
    return this.repository.create(input)
  }
}

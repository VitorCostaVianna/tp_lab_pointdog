import { Pet } from '../domain/pet.entity'
import { IPetRepository } from '../domain/pet.repository'

export interface ListPetsInput {
  ownerId: string
}

export class ListPetsUseCase {
  constructor(private readonly repository: IPetRepository) {}

  async execute(input: ListPetsInput): Promise<Pet[]> {
    return this.repository.findAllByOwner(input.ownerId)
  }
}

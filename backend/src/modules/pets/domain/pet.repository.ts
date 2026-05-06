import { Pet } from './pet.entity'

export interface IPetRepository {
  create(data: Omit<Pet, 'id'>): Promise<Pet>
  findAllByOwner(ownerId: string): Promise<Pet[]>
  findById(id: string): Promise<Pet | null>
  update(id: string, data: Partial<Omit<Pet, 'id' | 'ownerId'>>): Promise<Pet>
  delete(id: string): Promise<void>
}

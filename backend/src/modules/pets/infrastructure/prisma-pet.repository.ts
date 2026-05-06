import { PrismaClient } from '@prisma/client'
import { Pet } from '../domain/pet.entity'
import { IPetRepository } from '../domain/pet.repository'

export class PrismaPetRepository implements IPetRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: Omit<Pet, 'id'>): Promise<Pet> {
    const pet = await this.prisma.pet.create({ data })
    return pet as Pet
  }

  async findAllByOwner(ownerId: string): Promise<Pet[]> {
    const pets = await this.prisma.pet.findMany({ where: { ownerId } })
    return pets as Pet[]
  }

  async findById(id: string): Promise<Pet | null> {
    const pet = await this.prisma.pet.findUnique({ where: { id } })
    return pet as Pet | null
  }

  async update(id: string, data: Partial<Omit<Pet, 'id' | 'ownerId'>>): Promise<Pet> {
    const pet = await this.prisma.pet.update({ where: { id }, data })
    return pet as Pet
  }

  async delete(id: string): Promise<void> {
    await this.prisma.pet.delete({ where: { id } })
  }
}

import { PrismaClient } from '@prisma/client'
import { Service } from '../domain/service.entity'
import { IServiceRepository } from '../domain/service.repository'

export class PrismaServiceRepository implements IServiceRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: Omit<Service, 'id'>): Promise<Service> {
    const service = await this.prisma.service.create({ data })
    return service as Service
  }

  async findAll(): Promise<Service[]> {
    const results = await this.prisma.service.findMany({
      include: { provider: { select: { id: true, name: true } } },
    })
    return results as unknown as Service[]
  }

  async findAllByProvider(providerId: string): Promise<Service[]> {
    const services = await this.prisma.service.findMany({ where: { providerId } })
    return services as Service[]
  }

  async findById(id: string): Promise<Service | null> {
    const result = await this.prisma.service.findUnique({
      where: { id },
      include: { provider: { select: { id: true, name: true } } },
    })
    return result as unknown as Service | null
  }

  async update(id: string, data: Partial<Omit<Service, 'id' | 'providerId'>>): Promise<Service> {
    const service = await this.prisma.service.update({ where: { id }, data })
    return service as Service
  }

  async delete(id: string): Promise<void> {
    await this.prisma.service.delete({ where: { id } })
  }
}

import { Service } from './service.entity'

export interface IServiceRepository {
  create(data: Omit<Service, 'id'>): Promise<Service>
  findAll(): Promise<Service[]>
  findAllByProvider(providerId: string): Promise<Service[]>
  findById(id: string): Promise<Service | null>
  update(id: string, data: Partial<Omit<Service, 'id' | 'providerId'>>): Promise<Service>
  delete(id: string): Promise<void>
}

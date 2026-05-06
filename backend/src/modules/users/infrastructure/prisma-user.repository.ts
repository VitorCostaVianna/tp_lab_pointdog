import { PrismaClient } from '@prisma/client'
import { IUserRepository } from '../domain/user.repository'
import { User } from '../domain/user.entity'

export class PrismaUserRepository implements IUserRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: Omit<User, 'id' | 'createdAt' | 'updatedAt'>): Promise<User> {
    return this.prisma.user.create({ data }) as Promise<User>
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } }) as Promise<User | null>
  }

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } }) as Promise<User | null>
  }
}

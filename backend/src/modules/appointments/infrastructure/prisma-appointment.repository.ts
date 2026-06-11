import { PrismaClient } from '@prisma/client'
import { Appointment } from '../domain/appointment.entity'
import { IAppointmentRepository } from '../domain/appointment.repository'

export class PrismaAppointmentRepository implements IAppointmentRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: Omit<Appointment, 'id' | 'status'>): Promise<Appointment> {
    const result = await this.prisma.appointment.create({
      data: {
        scheduledAt: data.scheduledAt,
        notes: data.notes,
        clientId: data.clientId,
        petId: data.petId,
        providerId: data.providerId,
        serviceId: data.serviceId,
        status: 'PENDENTE',
      },
    })
    return result as Appointment
  }

  async findAllByClient(clientId: string): Promise<Appointment[]> {
    const results = await this.prisma.appointment.findMany({
      where: { clientId },
      include: { pet: true, service: { include: { provider: { select: { id: true, name: true } } } } },
      orderBy: { scheduledAt: 'desc' },
    })
    return results as unknown as Appointment[]
  }

  async findAllByProvider(providerId: string): Promise<Appointment[]> {
    const results = await this.prisma.appointment.findMany({
      where: { providerId },
    })
    return results as Appointment[]
  }

  async findById(id: string): Promise<Appointment | null> {
    const result = await this.prisma.appointment.findUnique({
      where: { id },
      include: { pet: true, service: { include: { provider: { select: { id: true, name: true } } } } },
    })
    return result as unknown as Appointment | null
  }

  async updateStatus(id: string, status: string): Promise<Appointment> {
    const result = await this.prisma.appointment.update({
      where: { id },
      data: { status },
    })
    return result as Appointment
  }
}

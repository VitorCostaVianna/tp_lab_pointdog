import { Router } from 'express'
import { PrismaClient } from '@prisma/client'
import { PrismaAppointmentRepository } from './infrastructure/prisma-appointment.repository'
import { CreateAppointmentUseCase } from './application/create-appointment.use-case'
import { ListAppointmentsUseCase } from './application/list-appointments.use-case'
import { GetAppointmentUseCase } from './application/get-appointment.use-case'
import { UpdateAppointmentStatusUseCase } from './application/update-appointment-status.use-case'
import { makeAppointmentController } from './presentation/appointment.controller'
import { PrismaPetRepository } from '../pets/infrastructure/prisma-pet.repository'
import { PrismaServiceRepository } from '../services/infrastructure/prisma-service.repository'

export function makeAppointmentsModule(prisma: PrismaClient): Router {
  const appointmentRepo = new PrismaAppointmentRepository(prisma)
  const petRepo = new PrismaPetRepository(prisma)
  const serviceRepo = new PrismaServiceRepository(prisma)
  const createAppointment = new CreateAppointmentUseCase(appointmentRepo, petRepo, serviceRepo)
  const listAppointments = new ListAppointmentsUseCase(appointmentRepo)
  const getAppointment = new GetAppointmentUseCase(appointmentRepo)
  const updateAppointmentStatus = new UpdateAppointmentStatusUseCase(appointmentRepo)
  return makeAppointmentController({ createAppointment, listAppointments, getAppointment, updateAppointmentStatus })
}

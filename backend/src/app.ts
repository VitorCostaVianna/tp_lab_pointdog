import express, { NextFunction, Request, Response } from 'express'
import { PrismaClient } from '@prisma/client'
import { AppError } from './shared/errors/app-error'
import { makeAuthModule } from './modules/users'
import { makePetsModule } from './modules/pets'
import { makeServicesModule } from './modules/services'
import { makeAppointmentsModule } from './modules/appointments'

export function createApp(prisma: PrismaClient) {
  const app = express()
  app.use(express.json())

  app.get('/health', (_req, res) => res.json({ status: 'ok' }))

  app.use('/auth', makeAuthModule(prisma))
  app.use('/pets', makePetsModule(prisma))
  app.use('/services', makeServicesModule(prisma))
  app.use('/appointments', makeAppointmentsModule(prisma))

  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    if (err instanceof AppError) {
      return res.status(err.statusCode).json({ message: err.message })
    }
    console.error(err)
    return res.status(500).json({ message: 'Internal server error' })
  })

  return app
}

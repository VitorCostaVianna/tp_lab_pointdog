import { Router, Request, Response, NextFunction } from 'express'
import { authenticate } from '../../../shared/middlewares/auth.middleware'
import { requireRole } from '../../../shared/middlewares/role.middleware'
import { CreateAppointmentUseCase } from '../application/create-appointment.use-case'
import { ListAppointmentsUseCase } from '../application/list-appointments.use-case'
import { GetAppointmentUseCase } from '../application/get-appointment.use-case'
import { UpdateAppointmentStatusUseCase } from '../application/update-appointment-status.use-case'

interface AppointmentControllerDeps {
  createAppointment: CreateAppointmentUseCase
  listAppointments: ListAppointmentsUseCase
  getAppointment: GetAppointmentUseCase
  updateAppointmentStatus: UpdateAppointmentStatusUseCase
}

export function makeAppointmentController(deps: AppointmentControllerDeps): Router {
  const router = Router()

  // POST /appointments — CLIENTE only
  router.post(
    '/',
    authenticate,
    requireRole('CLIENTE'),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const { scheduledAt, notes, petId, providerId, serviceId } = req.body
        const clientId = req.user!.sub
        const appointment = await deps.createAppointment.execute({
          scheduledAt: new Date(scheduledAt),
          notes,
          clientId,
          petId,
          providerId,
          serviceId,
        })
        res.status(201).json(appointment)
      } catch (err) {
        next(err)
      }
    },
  )

  // GET /appointments — any authenticated role
  router.get('/', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user!.sub
      const role = req.user!.role
      const appointments = await deps.listAppointments.execute({ userId, role })
      res.status(200).json(appointments)
    } catch (err) {
      next(err)
    }
  })

  // GET /appointments/:id — any authenticated role
  router.get('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      const requestingRole = req.user!.role
      const appointment = await deps.getAppointment.execute({ id, requestingUserId, requestingRole })
      res.status(200).json(appointment)
    } catch (err) {
      next(err)
    }
  })

  // PATCH /appointments/:id/status — any authenticated role
  router.patch('/:id/status', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      const requestingRole = req.user!.role
      const newStatus = req.body.status
      const appointment = await deps.updateAppointmentStatus.execute({
        id,
        requestingUserId,
        requestingRole,
        newStatus,
      })
      res.status(200).json(appointment)
    } catch (err) {
      next(err)
    }
  })

  return router
}

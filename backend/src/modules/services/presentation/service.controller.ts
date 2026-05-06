import { Router, Request, Response, NextFunction } from 'express'
import { authenticate } from '../../../shared/middlewares/auth.middleware'
import { requireRole } from '../../../shared/middlewares/role.middleware'
import { CreateServiceUseCase } from '../application/create-service.use-case'
import { ListServicesUseCase } from '../application/list-services.use-case'
import { GetServiceUseCase } from '../application/get-service.use-case'
import { UpdateServiceUseCase } from '../application/update-service.use-case'
import { DeleteServiceUseCase } from '../application/delete-service.use-case'
import { Service } from '../domain/service.entity'

interface ServiceControllerDeps {
  createService: CreateServiceUseCase
  listServices: ListServicesUseCase
  getService: GetServiceUseCase
  updateService: UpdateServiceUseCase
  deleteService: DeleteServiceUseCase
}

export function makeServiceController(deps: ServiceControllerDeps): Router {
  const router = Router()

  router.post('/', authenticate, requireRole('PRESTADOR'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { name, description, price, durationMinutes } = req.body as {
        name: string; description: string; price: number; durationMinutes: number
      }
      const providerId = req.user!.sub
      const service = await deps.createService.execute({ name, description, price, durationMinutes, providerId })
      res.status(201).json(service)
    } catch (err) {
      next(err)
    }
  })

  router.get('/', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const providerId = req.query.providerId as string | undefined
      const services = await deps.listServices.execute({ providerId })
      res.status(200).json(services)
    } catch (err) {
      next(err)
    }
  })

  router.get('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const service = await deps.getService.execute({ id })
      res.status(200).json(service)
    } catch (err) {
      next(err)
    }
  })

  router.put('/:id', authenticate, requireRole('PRESTADOR'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      const data = req.body as Partial<Omit<Service, 'id' | 'providerId'>>
      const service = await deps.updateService.execute({ id, requestingUserId, data })
      res.status(200).json(service)
    } catch (err) {
      next(err)
    }
  })

  router.delete('/:id', authenticate, requireRole('PRESTADOR'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      await deps.deleteService.execute({ id, requestingUserId })
      res.status(204).send()
    } catch (err) {
      next(err)
    }
  })

  return router
}

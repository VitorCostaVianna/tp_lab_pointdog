import { Router, Request, Response, NextFunction } from 'express'
import { authenticate } from '../../../shared/middlewares/auth.middleware'
import { requireRole } from '../../../shared/middlewares/role.middleware'
import { CreatePetUseCase } from '../application/create-pet.use-case'
import { ListPetsUseCase } from '../application/list-pets.use-case'
import { GetPetUseCase } from '../application/get-pet.use-case'
import { UpdatePetUseCase } from '../application/update-pet.use-case'
import { DeletePetUseCase } from '../application/delete-pet.use-case'
import { PetSize } from '../domain/pet.entity'

interface PetControllerDeps {
  createPet: CreatePetUseCase
  listPets: ListPetsUseCase
  getPet: GetPetUseCase
  updatePet: UpdatePetUseCase
  deletePet: DeletePetUseCase
}

export function makePetController(deps: PetControllerDeps): Router {
  const router = Router()

  router.use(authenticate)
  router.use(requireRole('CLIENTE'))

  router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { name, breed, size, notes } = req.body as {
        name: string; breed: string; size: PetSize; notes?: string
      }
      const ownerId = req.user!.sub
      const pet = await deps.createPet.execute({ name, breed, size, notes, ownerId })
      res.status(201).json(pet)
    } catch (err) {
      next(err)
    }
  })

  router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
      const ownerId = req.user!.sub
      const pets = await deps.listPets.execute({ ownerId })
      res.status(200).json(pets)
    } catch (err) {
      next(err)
    }
  })

  router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      const pet = await deps.getPet.execute({ id, requestingUserId })
      res.status(200).json(pet)
    } catch (err) {
      next(err)
    }
  })

  router.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      const data = req.body as Partial<{ name: string; breed: string; size: PetSize; notes: string }>
      const pet = await deps.updatePet.execute({ id, requestingUserId, data })
      res.status(200).json(pet)
    } catch (err) {
      next(err)
    }
  })

  router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string
      const requestingUserId = req.user!.sub
      await deps.deletePet.execute({ id, requestingUserId })
      res.status(204).send()
    } catch (err) {
      next(err)
    }
  })

  return router
}

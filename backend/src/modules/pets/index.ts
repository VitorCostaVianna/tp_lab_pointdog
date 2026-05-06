import { Router } from 'express'
import { PrismaClient } from '@prisma/client'
import { PrismaPetRepository } from './infrastructure/prisma-pet.repository'
import { CreatePetUseCase } from './application/create-pet.use-case'
import { ListPetsUseCase } from './application/list-pets.use-case'
import { GetPetUseCase } from './application/get-pet.use-case'
import { UpdatePetUseCase } from './application/update-pet.use-case'
import { DeletePetUseCase } from './application/delete-pet.use-case'
import { makePetController } from './presentation/pet.controller'

export function makePetsModule(prisma: PrismaClient): Router {
  const repo = new PrismaPetRepository(prisma)
  const createPet = new CreatePetUseCase(repo)
  const listPets = new ListPetsUseCase(repo)
  const getPet = new GetPetUseCase(repo)
  const updatePet = new UpdatePetUseCase(repo)
  const deletePet = new DeletePetUseCase(repo)
  return makePetController({ createPet, listPets, getPet, updatePet, deletePet })
}

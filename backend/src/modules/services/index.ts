import { Router } from 'express'
import { PrismaClient } from '@prisma/client'
import { PrismaServiceRepository } from './infrastructure/prisma-service.repository'
import { CreateServiceUseCase } from './application/create-service.use-case'
import { ListServicesUseCase } from './application/list-services.use-case'
import { GetServiceUseCase } from './application/get-service.use-case'
import { UpdateServiceUseCase } from './application/update-service.use-case'
import { DeleteServiceUseCase } from './application/delete-service.use-case'
import { makeServiceController } from './presentation/service.controller'

export function makeServicesModule(prisma: PrismaClient): Router {
  const repo = new PrismaServiceRepository(prisma)
  const createService = new CreateServiceUseCase(repo)
  const listServices = new ListServicesUseCase(repo)
  const getService = new GetServiceUseCase(repo)
  const updateService = new UpdateServiceUseCase(repo)
  const deleteService = new DeleteServiceUseCase(repo)
  return makeServiceController({ createService, listServices, getService, updateService, deleteService })
}

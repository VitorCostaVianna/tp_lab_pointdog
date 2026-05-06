import { Router } from 'express'
import { PrismaClient } from '@prisma/client'
import { PrismaUserRepository } from './infrastructure/prisma-user.repository'
import { RegisterUserUseCase } from './application/use-cases/register-user.usecase'
import { LoginUserUseCase } from './application/use-cases/login-user.usecase'
import { JwtService } from '../../shared/services/jwt.service'
import { AuthController } from './presentation/user.controller'
import { makeAuthRouter } from './presentation/user.routes'

export function makeAuthModule(prisma: PrismaClient): Router {
  const userRepo = new PrismaUserRepository(prisma)
  const jwtService = new JwtService()
  const registerUseCase = new RegisterUserUseCase(userRepo)
  const loginUseCase = new LoginUserUseCase(userRepo, jwtService)
  const controller = new AuthController(registerUseCase, loginUseCase)
  return makeAuthRouter(controller)
}

import { Request, Response, NextFunction } from 'express'
import { RegisterUserUseCase } from '../application/use-cases/register-user.usecase'
import { LoginUserUseCase } from '../application/use-cases/login-user.usecase'
import { Role } from '../domain/user.entity'
import { AppError } from '../../../shared/errors/app-error'

export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUserUseCase,
    private readonly loginUseCase: LoginUserUseCase,
  ) {}

  register = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { name, email, password, role } = req.body as {
        name: string; email: string; password: string; role: Role
      }
      if (!name || !email || !password || !role) {
        throw new AppError('name, email, password and role are required', 400)
      }
      if (!['CLIENTE', 'PRESTADOR'].includes(role)) {
        throw new AppError('role must be CLIENTE or PRESTADOR', 400)
      }
      const user = await this.registerUseCase.execute({ name, email, password, role })
      res.status(201).json(user)
    } catch (err) {
      next(err)
    }
  }

  login = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, password } = req.body as { email: string; password: string }
      if (!email || !password) throw new AppError('email and password are required', 400)
      const result = await this.loginUseCase.execute({ email, password })
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}

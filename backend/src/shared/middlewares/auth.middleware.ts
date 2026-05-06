import { Request, Response, NextFunction } from 'express'
import { JwtService } from '../services/jwt.service'
import { AppError } from '../errors/app-error'

const jwtService = new JwtService()

export function authenticate(req: Request, res: Response, next: NextFunction) {
  try {
    const header = req.headers.authorization
    if (!header?.startsWith('Bearer ')) throw new AppError('Missing token', 401)

    const token = header.split(' ')[1]
    req.user = jwtService.verify(token)
    next()
  } catch (err) {
    if (err instanceof AppError) return next(err)
    next(new AppError('Invalid or expired token', 401))
  }
}

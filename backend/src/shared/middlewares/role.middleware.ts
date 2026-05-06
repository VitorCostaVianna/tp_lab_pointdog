import { Request, Response, NextFunction } from 'express'
import { Role } from '../../modules/users/domain/user.entity'
import { AppError } from '../errors/app-error'

export function requireRole(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(new AppError('Forbidden', 403))
    }
    next()
  }
}

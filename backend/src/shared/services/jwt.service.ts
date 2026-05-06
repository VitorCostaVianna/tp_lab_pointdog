import jwt from 'jsonwebtoken'
import { Role } from '../../modules/users/domain/user.entity'

export interface JwtPayload {
  sub: string
  email: string
  role: Role
  iat?: number
  exp?: number
}

export class JwtService {
  private readonly secret: string
  private readonly expiresIn: string

  constructor() {
    const secret = process.env.JWT_SECRET
    if (!secret) throw new Error('JWT_SECRET env var is required')
    this.secret = secret
    this.expiresIn = process.env.JWT_EXPIRES_IN ?? '24h'
  }

  sign(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, this.secret, { expiresIn: this.expiresIn } as jwt.SignOptions)
  }

  verify(token: string): JwtPayload {
    return jwt.verify(token, this.secret) as JwtPayload
  }
}

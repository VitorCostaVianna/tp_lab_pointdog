import bcrypt from 'bcryptjs'
import { IUserRepository } from '../../domain/user.repository'
import { PublicUser, Role } from '../../domain/user.entity'
import { AppError } from '../../../../shared/errors/app-error'

interface RegisterInput {
  name: string
  email: string
  password: string
  role: Role
}

export class RegisterUserUseCase {
  constructor(private readonly userRepo: IUserRepository) {}

  async execute(input: RegisterInput): Promise<PublicUser> {
    const existing = await this.userRepo.findByEmail(input.email)
    if (existing) throw new AppError('Email already in use', 409)

    const hashed = await bcrypt.hash(input.password, 10)
    const user = await this.userRepo.create({ ...input, password: hashed })

    const { password: _pw, ...publicUser } = user
    return publicUser
  }
}

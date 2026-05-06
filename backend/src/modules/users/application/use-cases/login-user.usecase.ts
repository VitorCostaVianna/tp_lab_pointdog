import bcrypt from 'bcryptjs'
import { IUserRepository } from '../../domain/user.repository'
import { PublicUser } from '../../domain/user.entity'
import { JwtService } from '../../../../shared/services/jwt.service'
import { AppError } from '../../../../shared/errors/app-error'

interface LoginInput {
  email: string
  password: string
}

interface LoginOutput {
  token: string
  user: PublicUser
}

export class LoginUserUseCase {
  constructor(
    private readonly userRepo: IUserRepository,
    private readonly jwtService: JwtService,
  ) {}

  async execute(input: LoginInput): Promise<LoginOutput> {
    const user = await this.userRepo.findByEmail(input.email)
    if (!user) throw new AppError('Invalid credentials', 401)

    const passwordMatch = await bcrypt.compare(input.password, user.password)
    if (!passwordMatch) throw new AppError('Invalid credentials', 401)

    const token = this.jwtService.sign({ sub: user.id, email: user.email, role: user.role })

    const { password: _pw, ...publicUser } = user
    return { token, user: publicUser }
  }
}

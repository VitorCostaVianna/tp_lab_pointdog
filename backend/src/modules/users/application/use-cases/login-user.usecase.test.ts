import bcrypt from 'bcryptjs'
import { LoginUserUseCase } from './login-user.usecase'
import { IUserRepository } from '../../domain/user.repository'
import { User } from '../../domain/user.entity'
import { JwtService } from '../../../../shared/services/jwt.service'
import { AppError } from '../../../../shared/errors/app-error'

process.env.JWT_SECRET = 'test-secret'
process.env.JWT_EXPIRES_IN = '1h'

const mockRepo: jest.Mocked<IUserRepository> = {
  create: jest.fn(),
  findByEmail: jest.fn(),
  findById: jest.fn(),
}

const jwtService = new JwtService()
const useCase = new LoginUserUseCase(mockRepo, jwtService)

beforeEach(() => jest.clearAllMocks())

describe('LoginUserUseCase', () => {
  it('returns a token and public user on valid credentials', async () => {
    const hashed = await bcrypt.hash('123456', 10)
    mockRepo.findByEmail.mockResolvedValue({
      id: 'uuid-1', name: 'João', email: 'joao@email.com',
      password: hashed, role: 'CLIENTE',
      createdAt: new Date(), updatedAt: new Date(),
    } as User)

    const result = await useCase.execute({ email: 'joao@email.com', password: '123456' })

    expect(result.token).toBeDefined()
    expect(result.user.email).toBe('joao@email.com')
    expect(result.user).not.toHaveProperty('password')
  })

  it('throws 401 when email not found', async () => {
    mockRepo.findByEmail.mockResolvedValue(null)
    await expect(useCase.execute({ email: 'x@x.com', password: '123' }))
      .rejects.toThrow(new AppError('Invalid credentials', 401))
  })

  it('throws 401 when password is wrong', async () => {
    const hashed = await bcrypt.hash('correct', 10)
    mockRepo.findByEmail.mockResolvedValue({
      id: 'uuid-1', name: 'João', email: 'joao@email.com',
      password: hashed, role: 'CLIENTE',
      createdAt: new Date(), updatedAt: new Date(),
    } as User)

    await expect(useCase.execute({ email: 'joao@email.com', password: 'wrong' }))
      .rejects.toThrow(new AppError('Invalid credentials', 401))
  })
})

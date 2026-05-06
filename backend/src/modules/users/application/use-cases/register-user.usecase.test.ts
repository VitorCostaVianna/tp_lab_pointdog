import { RegisterUserUseCase } from './register-user.usecase'
import { IUserRepository } from '../../domain/user.repository'
import { User } from '../../domain/user.entity'
import { AppError } from '../../../../shared/errors/app-error'

const mockRepo: jest.Mocked<IUserRepository> = {
  create: jest.fn(),
  findByEmail: jest.fn(),
  findById: jest.fn(),
}

const useCase = new RegisterUserUseCase(mockRepo)

beforeEach(() => jest.clearAllMocks())

describe('RegisterUserUseCase', () => {
  it('creates a user and returns public data (no password)', async () => {
    mockRepo.findByEmail.mockResolvedValue(null)
    mockRepo.create.mockResolvedValue({
      id: 'uuid-1', name: 'João', email: 'joao@email.com',
      password: 'hashed', role: 'CLIENTE',
      createdAt: new Date(), updatedAt: new Date(),
    } as User)

    const result = await useCase.execute({
      name: 'João', email: 'joao@email.com', password: '123456', role: 'CLIENTE',
    })

    expect(result).not.toHaveProperty('password')
    expect(result.email).toBe('joao@email.com')
  })

  it('throws 409 when email already exists', async () => {
    mockRepo.findByEmail.mockResolvedValue({
      id: 'uuid-1', name: 'Existing', email: 'joao@email.com',
      password: 'hashed', role: 'CLIENTE',
      createdAt: new Date(), updatedAt: new Date(),
    } as User)

    await expect(
      useCase.execute({ name: 'João', email: 'joao@email.com', password: '123456', role: 'CLIENTE' }),
    ).rejects.toThrow(new AppError('Email already in use', 409))
  })
})

import { CreatePetUseCase } from './create-pet.use-case'
import { IPetRepository } from '../domain/pet.repository'
import { Pet } from '../domain/pet.entity'
import { AppError } from '../../../shared/errors/app-error'

function makeMockRepository(): jest.Mocked<IPetRepository> {
  return {
    create: jest.fn(),
    findAllByOwner: jest.fn(),
    findById: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  }
}

describe('CreatePetUseCase', () => {
  it('creates and returns a pet with valid input', async () => {
    const repo = makeMockRepository()
    const expectedPet: Pet = {
      id: 'uuid-123',
      name: 'Rex',
      breed: 'Labrador',
      size: 'GRANDE',
      ownerId: 'owner-uuid',
    }
    repo.create.mockResolvedValue(expectedPet)

    const useCase = new CreatePetUseCase(repo)
    const result = await useCase.execute({
      name: 'Rex',
      breed: 'Labrador',
      size: 'GRANDE',
      ownerId: 'owner-uuid',
    })

    expect(result).toEqual(expectedPet)
    expect(repo.create).toHaveBeenCalledWith({
      name: 'Rex',
      breed: 'Labrador',
      size: 'GRANDE',
      ownerId: 'owner-uuid',
    })
  })

  it('throws AppError with 400 for invalid size', async () => {
    const repo = makeMockRepository()
    const useCase = new CreatePetUseCase(repo)

    await expect(
      useCase.execute({
        name: 'Rex',
        breed: 'Labrador',
        size: 'GIGANTE' as any,
        ownerId: 'owner-uuid',
      }),
    ).rejects.toThrow(new AppError('Tamanho inválido', 400))

    expect(repo.create).not.toHaveBeenCalled()
  })
})

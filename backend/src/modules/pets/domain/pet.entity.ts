export type PetSize = 'PEQUENO' | 'MEDIO' | 'GRANDE'

export interface Pet {
  id: string
  name: string
  breed: string
  size: PetSize
  notes?: string
  ownerId: string
}

export type Role = 'CLIENTE' | 'PRESTADOR'

export interface User {
  id: string
  name: string
  email: string
  password: string
  role: Role
  createdAt: Date
  updatedAt: Date
}

export type PublicUser = Omit<User, 'password'>

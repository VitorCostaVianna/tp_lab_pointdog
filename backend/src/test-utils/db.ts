import { createPrismaClient } from '../shared/prisma'

export const testPrisma = createPrismaClient('file:./test.db')

export async function cleanDatabase() {
  await testPrisma.appointment.deleteMany()
  await testPrisma.pet.deleteMany()
  await testPrisma.service.deleteMany()
  await testPrisma.user.deleteMany()
}

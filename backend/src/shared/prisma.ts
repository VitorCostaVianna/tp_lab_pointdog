import { PrismaClient } from '@prisma/client'
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3'

export function createPrismaClient(databaseUrl?: string): PrismaClient {
  const url = databaseUrl ?? process.env.DATABASE_URL ?? 'file:./dev.db'
  const adapter = new PrismaBetterSqlite3({ url })
  return new PrismaClient({ adapter })
}

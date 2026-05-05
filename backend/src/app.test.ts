import request from 'supertest'
import { createApp } from './app'
import { testPrisma, cleanDatabase } from './test-utils/db'

const app = createApp(testPrisma)

beforeEach(cleanDatabase)
afterAll(() => testPrisma.$disconnect())

describe('GET /health', () => {
  it('returns ok', async () => {
    const res = await request(app).get('/health')
    expect(res.status).toBe(200)
    expect(res.body).toEqual({ status: 'ok' })
  })
})

import request from 'supertest'
import { createApp } from '../../../app'
import { testPrisma, cleanDatabase } from '../../../test-utils/db'

const app = createApp(testPrisma)

beforeEach(cleanDatabase)
afterAll(() => testPrisma.$disconnect())

describe('POST /auth/register', () => {
  it('creates a new CLIENTE user and returns 201', async () => {
    const res = await request(app).post('/auth/register').send({
      name: 'João Silva', email: 'joao@email.com', password: '123456', role: 'CLIENTE',
    })
    expect(res.status).toBe(201)
    expect(res.body.email).toBe('joao@email.com')
    expect(res.body).not.toHaveProperty('password')
    expect(res.body.role).toBe('CLIENTE')
  })

  it('returns 409 when email already registered', async () => {
    await request(app).post('/auth/register').send({
      name: 'João', email: 'joao@email.com', password: '123456', role: 'CLIENTE',
    })
    const res = await request(app).post('/auth/register').send({
      name: 'João2', email: 'joao@email.com', password: 'abc', role: 'CLIENTE',
    })
    expect(res.status).toBe(409)
  })

  it('returns 400 when role is missing', async () => {
    const res = await request(app).post('/auth/register').send({
      name: 'João', email: 'joao@email.com', password: '123456',
    })
    expect(res.status).toBe(400)
  })
})

describe('POST /auth/login', () => {
  beforeEach(async () => {
    await request(app).post('/auth/register').send({
      name: 'João', email: 'joao@email.com', password: '123456', role: 'CLIENTE',
    })
  })

  it('returns token and user on valid credentials', async () => {
    const res = await request(app).post('/auth/login').send({
      email: 'joao@email.com', password: '123456',
    })
    expect(res.status).toBe(200)
    expect(res.body.token).toBeDefined()
    expect(res.body.user.email).toBe('joao@email.com')
  })

  it('returns 401 on wrong password', async () => {
    const res = await request(app).post('/auth/login').send({
      email: 'joao@email.com', password: 'wrong',
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 when email does not exist', async () => {
    const res = await request(app).post('/auth/login').send({
      email: 'nao@existe.com', password: '123456',
    })
    expect(res.status).toBe(401)
  })
})

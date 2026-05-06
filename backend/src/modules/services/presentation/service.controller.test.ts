import request from 'supertest'
import { createApp } from '../../../app'
import { testPrisma, cleanDatabase } from '../../../test-utils/db'

const app = createApp(testPrisma)

beforeEach(cleanDatabase)
afterAll(() => testPrisma.$disconnect())

async function registerAndLogin(
  email: string,
  password: string = '123456',
  name: string = 'Test User',
  role: 'CLIENTE' | 'PRESTADOR' = 'CLIENTE',
): Promise<{ token: string; userId: string }> {
  const registerRes = await request(app).post('/auth/register').send({ name, email, password, role })
  const userId = registerRes.body.id as string
  const loginRes = await request(app).post('/auth/login').send({ email, password })
  return { token: loginRes.body.token as string, userId }
}

describe('POST /services', () => {
  it('creates a service for authenticated PRESTADOR and returns 201', async () => {
    const { token } = await registerAndLogin('prestador@email.com', '123456', 'Prestador User', 'PRESTADOR')
    const res = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    expect(res.status).toBe(201)
    expect(res.body.id).toBeDefined()
    expect(res.body.name).toBe('Banho')
    expect(res.body.price).toBe(50)
    expect(res.body.providerId).toBeDefined()
  })

  it('rejects CLIENTE role with 403', async () => {
    const { token } = await registerAndLogin('cliente@email.com', '123456', 'Cliente User', 'CLIENTE')
    const res = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    expect(res.status).toBe(403)
  })

  it('rejects negative price with 400', async () => {
    const { token } = await registerAndLogin('prestador2@email.com', '123456', 'Prestador 2', 'PRESTADOR')
    const res = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Banho', description: 'Banho completo', price: -10, durationMinutes: 60 })

    expect(res.status).toBe(400)
    expect(res.body.message).toBe('Preço deve ser positivo')
  })
})

describe('GET /services', () => {
  it('returns all services and CLIENTE can view', async () => {
    const { token: prestadorToken1 } = await registerAndLogin('prestador1@email.com', '123456', 'Prestador 1', 'PRESTADOR')
    const { token: prestadorToken2 } = await registerAndLogin('prestador2@email.com', '123456', 'Prestador 2', 'PRESTADOR')
    const { token: clienteToken } = await registerAndLogin('cliente@email.com', '123456', 'Cliente', 'CLIENTE')

    await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${prestadorToken1}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${prestadorToken2}`)
      .send({ name: 'Tosa', description: 'Tosa completa', price: 70, durationMinutes: 90 })

    const res = await request(app)
      .get('/services')
      .set('Authorization', `Bearer ${clienteToken}`)

    expect(res.status).toBe(200)
    expect(res.body).toHaveLength(2)
  })

  it('filters by providerId', async () => {
    const { token: prestadorToken1, userId: providerId1 } = await registerAndLogin('prestador3@email.com', '123456', 'Prestador 3', 'PRESTADOR')
    const { token: prestadorToken2 } = await registerAndLogin('prestador4@email.com', '123456', 'Prestador 4', 'PRESTADOR')
    const { token: clienteToken } = await registerAndLogin('cliente2@email.com', '123456', 'Cliente 2', 'CLIENTE')

    await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${prestadorToken1}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${prestadorToken2}`)
      .send({ name: 'Tosa', description: 'Tosa completa', price: 70, durationMinutes: 90 })

    const res = await request(app)
      .get(`/services?providerId=${providerId1}`)
      .set('Authorization', `Bearer ${clienteToken}`)

    expect(res.status).toBe(200)
    expect(res.body).toHaveLength(1)
    expect(res.body[0].name).toBe('Banho')
  })
})

describe('GET /services/:id', () => {
  it('returns service with 200', async () => {
    const { token } = await registerAndLogin('prestador5@email.com', '123456', 'Prestador 5', 'PRESTADOR')
    const createRes = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    const serviceId = createRes.body.id as string
    const res = await request(app)
      .get(`/services/${serviceId}`)
      .set('Authorization', `Bearer ${token}`)

    expect(res.status).toBe(200)
    expect(res.body.id).toBe(serviceId)
  })
})

describe('PUT /services/:id', () => {
  it('updates own service and returns 200 with updated data', async () => {
    const { token } = await registerAndLogin('prestador6@email.com', '123456', 'Prestador 6', 'PRESTADOR')
    const createRes = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    const serviceId = createRes.body.id as string
    const res = await request(app)
      .put(`/services/${serviceId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ price: 75 })

    expect(res.status).toBe(200)
    expect(res.body.price).toBe(75)
  })

  it('returns 403 when updating another provider\'s service', async () => {
    const { token: token1 } = await registerAndLogin('prestador7@email.com', '123456', 'Prestador 7', 'PRESTADOR')
    const { token: token2 } = await registerAndLogin('prestador8@email.com', '123456', 'Prestador 8', 'PRESTADOR')

    const createRes = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token1}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    const serviceId = createRes.body.id as string
    const res = await request(app)
      .put(`/services/${serviceId}`)
      .set('Authorization', `Bearer ${token2}`)
      .send({ price: 75 })

    expect(res.status).toBe(403)
  })
})

describe('DELETE /services/:id', () => {
  it('deletes own service and returns 204, then GET returns 404', async () => {
    const { token } = await registerAndLogin('prestador9@email.com', '123456', 'Prestador 9', 'PRESTADOR')
    const createRes = await request(app)
      .post('/services')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Banho', description: 'Banho completo', price: 50, durationMinutes: 60 })

    const serviceId = createRes.body.id as string

    const deleteRes = await request(app)
      .delete(`/services/${serviceId}`)
      .set('Authorization', `Bearer ${token}`)

    expect(deleteRes.status).toBe(204)

    const getRes = await request(app)
      .get(`/services/${serviceId}`)
      .set('Authorization', `Bearer ${token}`)

    expect(getRes.status).toBe(404)
  })
})

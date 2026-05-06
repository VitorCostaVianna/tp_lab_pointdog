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
): Promise<string> {
  await request(app).post('/auth/register').send({ name, email, password, role: 'CLIENTE' })
  const res = await request(app).post('/auth/login').send({ email, password })
  return res.body.token as string
}

describe('POST /pets', () => {
  it('creates a pet for authenticated CLIENTE and returns 201', async () => {
    const token = await registerAndLogin('cliente@email.com')
    const res = await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rex', breed: 'Labrador', size: 'GRANDE' })

    expect(res.status).toBe(201)
    expect(res.body.id).toBeDefined()
    expect(res.body.name).toBe('Rex')
    expect(res.body.breed).toBe('Labrador')
    expect(res.body.size).toBe('GRANDE')
    expect(res.body.ownerId).toBeDefined()
  })

  it('rejects invalid size with 400', async () => {
    const token = await registerAndLogin('cliente2@email.com')
    const res = await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rex', breed: 'Labrador', size: 'GIGANTE' })

    expect(res.status).toBe(400)
    expect(res.body.message).toBe('Tamanho inválido')
  })

  it('rejects unauthenticated request with 401', async () => {
    const res = await request(app)
      .post('/pets')
      .send({ name: 'Rex', breed: 'Labrador', size: 'GRANDE' })

    expect(res.status).toBe(401)
  })
})

describe('GET /pets', () => {
  it('returns only own pets', async () => {
    const token1 = await registerAndLogin('user1@email.com', '123456', 'User One')
    const token2 = await registerAndLogin('user2@email.com', '123456', 'User Two')

    await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token1}`)
      .send({ name: 'PetDeUser1', breed: 'Bulldog', size: 'MEDIO' })

    await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token2}`)
      .send({ name: 'PetDeUser2', breed: 'Poodle', size: 'PEQUENO' })

    const res = await request(app)
      .get('/pets')
      .set('Authorization', `Bearer ${token1}`)

    expect(res.status).toBe(200)
    expect(res.body).toHaveLength(1)
    expect(res.body[0].name).toBe('PetDeUser1')
  })
})

describe('GET /pets/:id', () => {
  it('returns own pet with 200', async () => {
    const token = await registerAndLogin('owner@email.com')
    const createRes = await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Fido', breed: 'Beagle', size: 'PEQUENO' })

    const petId = createRes.body.id
    const res = await request(app)
      .get(`/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)

    expect(res.status).toBe(200)
    expect(res.body.id).toBe(petId)
  })

  it('returns 403 when accessing another user\'s pet', async () => {
    const token1 = await registerAndLogin('owner1@email.com', '123456', 'Owner One')
    const token2 = await registerAndLogin('other@email.com', '123456', 'Other User')

    const createRes = await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token1}`)
      .send({ name: 'Fido', breed: 'Beagle', size: 'PEQUENO' })

    const petId = createRes.body.id
    const res = await request(app)
      .get(`/pets/${petId}`)
      .set('Authorization', `Bearer ${token2}`)

    expect(res.status).toBe(403)
  })
})

describe('PUT /pets/:id', () => {
  it('updates own pet and returns 200 with updated data', async () => {
    const token = await registerAndLogin('updater@email.com')
    const createRes = await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'OldName', breed: 'Poodle', size: 'PEQUENO' })

    const petId = createRes.body.id
    const res = await request(app)
      .put(`/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Max' })

    expect(res.status).toBe(200)
    expect(res.body.name).toBe('Max')
    expect(res.body.breed).toBe('Poodle')
  })
})

describe('DELETE /pets/:id', () => {
  it('deletes own pet and returns 204, then GET returns 404', async () => {
    const token = await registerAndLogin('deleter@email.com')
    const createRes = await request(app)
      .post('/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Buddy', breed: 'Golden', size: 'GRANDE' })

    const petId = createRes.body.id

    const deleteRes = await request(app)
      .delete(`/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)

    expect(deleteRes.status).toBe(204)

    const getRes = await request(app)
      .get(`/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)

    expect(getRes.status).toBe(404)
  })
})

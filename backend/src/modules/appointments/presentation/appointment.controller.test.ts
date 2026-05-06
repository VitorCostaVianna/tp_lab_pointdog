import request from 'supertest'
import { createApp } from '../../../app'
import { testPrisma, cleanDatabase } from '../../../test-utils/db'

const app = createApp(testPrisma)

async function setupEntities() {
  // Register CLIENTE
  const clientRes = await request(app)
    .post('/auth/register')
    .send({ name: 'Cliente', email: 'c@test.com', password: 'pass123', role: 'CLIENTE' })
  const clientLogin = await request(app)
    .post('/auth/login')
    .send({ email: 'c@test.com', password: 'pass123' })
  const clientToken = clientLogin.body.token
  const clientId = clientRes.body.id

  // Register PRESTADOR
  const providerRes = await request(app)
    .post('/auth/register')
    .send({ name: 'Provider', email: 'p@test.com', password: 'pass123', role: 'PRESTADOR' })
  const providerLogin = await request(app)
    .post('/auth/login')
    .send({ email: 'p@test.com', password: 'pass123' })
  const providerToken = providerLogin.body.token
  const providerId = providerRes.body.id

  // Create pet via API
  const petRes = await request(app)
    .post('/pets')
    .set('Authorization', `Bearer ${clientToken}`)
    .send({ name: 'Rex', breed: 'Lab', size: 'GRANDE' })
  const petId = petRes.body.id

  // Create service via API
  const serviceRes = await request(app)
    .post('/services')
    .set('Authorization', `Bearer ${providerToken}`)
    .send({ name: 'Banho', description: 'desc', price: 50, durationMinutes: 60 })
  const serviceId = serviceRes.body.id

  return { clientToken, clientId, providerToken, providerId, petId, serviceId }
}

describe('Appointments', () => {
  beforeEach(async () => {
    await cleanDatabase()
  })

  describe('POST /appointments', () => {
    it('CLIENTE creates appointment successfully', async () => {
      const { clientToken, clientId, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const res = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      expect(res.status).toBe(201)
      expect(res.body).toMatchObject({
        id: expect.any(String),
        status: 'PENDENTE',
        clientId,
        petId,
        serviceId,
      })
    })

    it('rejects past date', async () => {
      const { clientToken, petId, providerId, serviceId } = await setupEntities()

      const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()

      const res = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: pastDate, petId, providerId, serviceId })

      expect(res.status).toBe(400)
      expect(res.body).toEqual({ message: 'Data deve ser futura' })
    })

    it('PRESTADOR cannot create appointment', async () => {
      const { providerToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const res = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      expect(res.status).toBe(403)
    })

    it('rejects appointment with pet that does not belong to client', async () => {
      // Setup client1 (from setupEntities), and a separate client2 who owns a different pet
      const { clientToken, providerId, serviceId } = await setupEntities()

      // Register a second CLIENTE
      await request(app)
        .post('/auth/register')
        .send({ name: 'Cliente2', email: 'c2@test.com', password: 'pass123', role: 'CLIENTE' })
      const client2Login = await request(app)
        .post('/auth/login')
        .send({ email: 'c2@test.com', password: 'pass123' })
      const client2Token = client2Login.body.token

      // Create a pet as client2
      const petRes = await request(app)
        .post('/pets')
        .set('Authorization', `Bearer ${client2Token}`)
        .send({ name: 'Bolinha', breed: 'Poodle', size: 'PEQUENO' })
      const client2PetId = petRes.body.id

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      // client1 tries to book an appointment using client2's pet
      const res = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId: client2PetId, providerId, serviceId })

      expect(res.status).toBe(403)
      expect(res.body).toEqual({ message: 'Pet não pertence ao cliente' })
    })

    it('rejects appointment with non-existent service', async () => {
      const { clientToken, petId, providerId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const res = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId: 'non-existent-uuid' })

      expect(res.status).toBe(404)
      expect(res.body).toEqual({ message: 'Serviço não encontrado' })
    })
  })

  describe('GET /appointments', () => {
    it('CLIENTE sees own appointments', async () => {
      const { clientToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const res = await request(app)
        .get('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)

      expect(res.status).toBe(200)
      expect(res.body).toHaveLength(1)
      expect(res.body[0]).toMatchObject({ status: 'PENDENTE' })
    })
  })

  describe('GET /appointments/:id', () => {
    it('returns 403 for wrong user (PRESTADOR who is not the provider)', async () => {
      const { clientToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const createRes = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const appointmentId = createRes.body.id

      // Register a second PRESTADOR who is not the provider
      await request(app)
        .post('/auth/register')
        .send({ name: 'Other Provider', email: 'op@test.com', password: 'pass123', role: 'PRESTADOR' })
      const otherProviderLogin = await request(app)
        .post('/auth/login')
        .send({ email: 'op@test.com', password: 'pass123' })
      const otherProviderToken = otherProviderLogin.body.token

      const res = await request(app)
        .get(`/appointments/${appointmentId}`)
        .set('Authorization', `Bearer ${otherProviderToken}`)

      expect(res.status).toBe(403)
    })
  })

  describe('PATCH /appointments/:id/status', () => {
    it('PRESTADOR can confirm PENDENTE appointment', async () => {
      const { clientToken, providerToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const createRes = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const appointmentId = createRes.body.id

      const res = await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'CONFIRMADO' })

      expect(res.status).toBe(200)
      expect(res.body).toMatchObject({ status: 'CONFIRMADO' })
    })

    it('CLIENTE cannot confirm appointment (must be PRESTADOR)', async () => {
      const { clientToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const createRes = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const appointmentId = createRes.body.id

      const res = await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'CONFIRMADO' })

      expect(res.status).toBe(403)
      expect(res.body).toEqual({ message: 'Sem permissão para esta transição' })
    })

    it('CLIENTE can cancel PENDENTE appointment', async () => {
      const { clientToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const createRes = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const appointmentId = createRes.body.id

      const res = await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'CANCELADO' })

      expect(res.status).toBe(200)
      expect(res.body).toMatchObject({ status: 'CANCELADO' })
    })

    it('invalid transition — already finalized (CANCELADO)', async () => {
      const { clientToken, providerToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const createRes = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const appointmentId = createRes.body.id

      // Cancel first
      await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'CANCELADO' })

      // Try to confirm a cancelled appointment
      const res = await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'CONFIRMADO' })

      expect(res.status).toBe(400)
      expect(res.body).toEqual({ message: 'Agendamento já finalizado' })
    })

    it('PRESTADOR can conclude CONFIRMADO appointment', async () => {
      const { clientToken, providerToken, petId, providerId, serviceId } = await setupEntities()

      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()

      const createRes = await request(app)
        .post('/appointments')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ scheduledAt: futureDate, petId, providerId, serviceId })

      const appointmentId = createRes.body.id

      // Confirm first
      await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'CONFIRMADO' })

      // Then conclude
      const res = await request(app)
        .patch(`/appointments/${appointmentId}/status`)
        .set('Authorization', `Bearer ${providerToken}`)
        .send({ status: 'CONCLUIDO' })

      expect(res.status).toBe(200)
      expect(res.body).toMatchObject({ status: 'CONCLUIDO' })
    })
  })
})

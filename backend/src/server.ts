import 'dotenv/config'
import { createApp } from './app'
import { createPrismaClient } from './shared/prisma'

const prisma = createPrismaClient()
const port = process.env.PORT ?? 3000
const app = createApp(prisma)

app.listen(port, () => {
  console.log(`Server running on port ${port}`)
})

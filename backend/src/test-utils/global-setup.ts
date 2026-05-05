import { execSync } from 'child_process'
import path from 'path'

export default async function globalSetup() {
  execSync('npx prisma migrate deploy', {
    env: { ...process.env, DATABASE_URL: 'file:./test.db' },
    stdio: 'inherit',
    cwd: path.resolve(__dirname, '..', '..'),
  })
}

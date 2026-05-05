import type { Config } from 'jest'

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/*.test.ts'],
  globalSetup: './src/test-utils/global-setup.ts',
  setupFiles: ['./src/test-utils/setup-env.ts'],
  forceExit: true,
}

export default config

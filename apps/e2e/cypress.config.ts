import { defineConfig } from 'cypress'
import { nxE2EPreset } from '@nrwl/cypress/plugins/cypress-preset'

export default defineConfig({
    e2e: {
        ...nxE2EPreset(__dirname),
        video: false,
        screenshotsFolder: '../../dist/cypress/apps/e2e/screenshots',
        viewportWidth: 1280,
        viewportHeight: 720,
        baseUrl: 'http://localhost:4200',
        env: {
            API_URL: 'http://localhost:3333/v1',
            AUTH0_ID: 'REPLACE_THIS',
            AUTH0_CLIENT_ID: 'REPLACE_THIS',
            AUTH0_NAME: 'Engineering CI',
            AUTH0_EMAIL: 'REPLACE_THIS',
            AUTH0_PASSWORD: 'REPLACE_THIS',
            AUTH0_DOMAIN: 'REPLACE_THIS',
            STRIPE_WEBHOOK_SECRET:
                'REPLACE_THIS',
            STRIPE_CUSTOMER_ID: 'REPLACE_THIS',
            STRIPE_SUBSCRIPTION_ID: 'REPLACE_THIS',
        },
        specPattern: 'src/e2e/**/*.cy.{js,jsx,ts,tsx}',
        supportFile: 'src/support/e2e.ts',
        fixturesFolder: './src/fixtures',
        setupNodeEvents(on, config) {
            on('task', {
                log(message) {
                    console.log(message)
                    return null
                },
            })
        },
    },
})

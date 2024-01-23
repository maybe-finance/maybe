import { checkoutSessionCompleted, customerSubscriptionCreated } from '../fixtures/stripe'
import Stripe from 'stripe'
import { customerSubscriptionDeleted } from '../fixtures/stripe/customerSubscriptionDeleted'

const stripe = new Stripe('sk_test_12345', { apiVersion: '2022-08-01' })

function getAuth0Id(): string {
    const keys = Object.keys(localStorage)
    const auth0Key = keys.find((key) => key.startsWith('@@auth0spajs@@'))
    const data = JSON.parse(localStorage.getItem(auth0Key))
    return data.body.decodedToken.user.sub
}

function sendWebhook(payload: Record<string, any>) {
    const payloadString = JSON.stringify(payload)
    const signature = stripe.webhooks.generateTestHeaderString({
        payload: payloadString,
        secret: Cypress.env('STRIPE_WEBHOOK_SECRET'),
    })

    return cy
        .apiRequest({
            method: 'POST',
            url: '/stripe/webhook',
            headers: {
                ['stripe-signature']: signature,
            },
            body: payload,
        })
        .its('status')
        .should('equal', 200)
}

describe('Subscriptions', () => {
    it.skip('should recognize a trialing user', () => {
        cy.visit('/')

        cy.visit('/settings?tab=billing')

        // Trial is recognized
        cy.contains('14 days left in your free trial', { timeout: 10000 })

        // Subscriber features are accessible
        cy.visit('/')
        cy.contains('h4', 'No accounts yet')
    })

    it.skip('should recognize a lapsed trial', () => {
        // Reset user to lapsed trial
        cy.apiRequest({
            method: 'POST',
            url: 'e2e/reset',
            body: {
                trialLapsed: true,
            },
        }).then((response) => {
            expect(response.status).to.equal(200)
        })

        cy.visit('/')

        cy.contains('Choose annual or monthly billing to start', { timeout: 10000 })
    })

    it.skip('should recognize a canceled user', () => {
        sendWebhook(checkoutSessionCompleted(getAuth0Id()))
        sendWebhook(customerSubscriptionCreated())
        sendWebhook(customerSubscriptionDeleted())

        cy.visit('/')

        cy.contains('Choose annual or monthly billing to start', { timeout: 10000 })
    })
})

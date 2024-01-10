import './commands'

beforeEach(() => {
    // Login
    // Rate limit 30 / min - https://auth0.com/docs/troubleshoot/customer-support/operational-policies/rate-limit-policy#limits-for-non-production-tenants-of-paying-customers-and-all-tenants-of-free-customers
    cy.login(Cypress.env('AUTH0_EMAIL'), Cypress.env('AUTH0_PASSWORD'))

    // Delete the current user to wipe all data before test
    cy.apiRequest({
        method: 'POST',
        url: 'e2e/reset',
        body: {},
    }).then((response) => {
        expect(response.status).to.equal(200)
    })

    // Re-login (JWT should still be valid)
    cy.visit('/')
})

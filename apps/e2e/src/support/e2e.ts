import './commands'

beforeEach(() => {
    // Login
    cy.login()

    // Delete the current user to wipe all data before test
    cy.apiRequest({
        method: 'POST',
        url: 'e2e/reset',
        body: {},
    }).then((response) => {
        expect(response.status).to.equal(200)
    })

    // Go back to dashboard
    cy.visit('/')
})

import './commands'

beforeEach(() => {
    cy.request({
        method: 'GET',
        url: 'api/auth/csrf',
    }).then((response) => {
        let csrfCookies = response.headers['set-cookie']
        if (Array.isArray(csrfCookies) && csrfCookies.length > 1) {
            csrfCookies = csrfCookies.map((cookie) => cookie.split(';')[0]).join('; ')
        }
        const csrfToken = response.body.csrfToken.trim()

        cy.request({
            method: 'POST',
            form: true,
            headers: {
                Cookie: `${csrfCookies}`,
            },
            url: `api/auth/callback/credentials`,
            body: {
                email: 'test@test.com',
                firstName: 'Test',
                lastName: 'User',
                password: 'TestPassword123',
                role: 'ci',
                csrfToken: csrfToken,
                json: 'true',
            },
        }).then((response) => {
            expect(response.status).to.equal(200)
        })
    })
    cy.apiRequest({
        method: 'POST',
        url: 'e2e/reset',
        body: {},
    }).then((response) => {
        expect(response.status).to.equal(200)
    })
    cy.visit('/')
})

after(() => {
    cy.apiRequest({
        method: 'POST',
        url: 'e2e/clean',
        body: {},
    }).then((response) => {
        expect(response.status).to.equal(200)
    })
})

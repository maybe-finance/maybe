import jwtDecode from 'jwt-decode'

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace Cypress {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        interface Chainable<Subject> {
            login(username: string, password: string): Chainable<any>
            apiRequest(...params: Parameters<typeof cy.request>): Chainable<any>
            getByTestId(...parameters: Parameters<typeof cy.get>): Chainable<any>
            selectDate(date: Date): Chainable<any>
            preserveAccessToken(): Chainable<any>
            restoreAccessToken(): Chainable<any>
        }
    }
}

Cypress.Commands.add('getByTestId', (testId, ...rest) => {
    return cy.get(`[data-testid="${testId}"]`, ...rest)
})

Cypress.Commands.add('apiRequest', ({ url, headers = {}, ...options }, ...rest) => {
    const accessToken = window.localStorage.getItem('token')

    return cy.request(
        {
            url: `${Cypress.env('API_URL')}/${url}`,
            headers: {
                Authorization: `Bearer ${accessToken}`,
                ...headers,
            },
            ...options,
        },
        ...rest
    )
})

/**
 * Logs in with the engineering CI account
 */
Cypress.Commands.add('login', (username, password) => {
    // Preserves login across tests
    cy.session('login-session-key', login, {
        validate() {
            cy.apiRequest({ url: 'e2e' }).its('status').should('eq', 200)
        },
    })

    function login() {
        const client_id = Cypress.env('AUTH0_CLIENT_ID')
        const audience = 'https://maybe-finance-api/v1'
        const scope = 'openid profile email offline_access'
        const accessTokenStorageKey = `@@auth0spajs@@::${client_id}::${audience}::${scope}`
        const AUTH_DOMAIN = Cypress.env('AUTH0_DOMAIN')

        cy.log(`Logging in as ${username}`)

        /**
         * Uses the official Cypress Auth0 strategy for testing with Auth0
         * https://docs.cypress.io/guides/testing-strategies/auth0-authentication#Auth0-Application-Setup
         *
         * Relevant Auth0 endpoint
         * https://auth0.com/docs/api/authentication?javascript#resource-owner-password
         */
        cy.request({
            method: 'POST',
            url: `https://${AUTH_DOMAIN}/oauth/token`,
            body: {
                grant_type: 'password',
                username,
                password,
                audience,
                scope,
                client_id,
            },
        }).then(({ body }) => {
            const claims = jwtDecode<any>(body.id_token)

            const { nickname, name, picture, updated_at, email, email_verified, sub, exp } = claims

            const item = {
                body: {
                    ...body,
                    decodedToken: {
                        claims,
                        user: {
                            nickname,
                            name,
                            picture,
                            updated_at,
                            email,
                            email_verified,
                            sub,
                        },
                        audience,
                        client_id,
                    },
                },
                expiresAt: exp,
            }

            window.localStorage.setItem(accessTokenStorageKey, JSON.stringify(item))
            window.localStorage.setItem('token', body.access_token)

            cy.visit('/')
        })
    }
})

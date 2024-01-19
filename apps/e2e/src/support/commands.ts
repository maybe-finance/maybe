// eslint-disable-next-line @typescript-eslint/no-namespace
declare namespace Cypress {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    interface Chainable<Subject> {
        login(): Chainable<any>
        apiRequest(...params: Parameters<typeof cy.request>): Chainable<any>
        getByTestId(...parameters: Parameters<typeof cy.get>): Chainable<any>
        selectDate(date: Date): Chainable<any>
        preserveAccessToken(): Chainable<any>
        restoreAccessToken(): Chainable<any>
    }
}

Cypress.Commands.add('getByTestId', (testId, ...rest) => {
    return cy.get(`[data-testid="${testId}"]`, ...rest)
})

Cypress.Commands.add('apiRequest', ({ url, headers = {}, ...options }, ...rest) => {
    return cy.request(
        {
            url: `${Cypress.env('API_URL')}/${url}`,
            headers: {
                ...headers,
            },
            ...options,
        },
        ...rest
    )
})

Cypress.Commands.add('login', () => {
    cy.visit('/login')
    cy.get('input[name="email"]').type('bond@007.com')
    cy.get('input[name="password"]').type('TestPassword123')
    cy.get('button[type="submit"]').click()
    //eslint-disable-next-line cypress/no-unnecessary-waiting
    cy.wait(1000)
})

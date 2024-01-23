describe('Auth', () => {
    beforeEach(() => cy.visit('/'))

    describe('Logging in', () => {
        it('should show the home page of an authenticated user', () => {
            cy.contains('h5', 'Assets & Debts')
        })
    })
})

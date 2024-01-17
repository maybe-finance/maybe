import { DateTime } from 'luxon'

const assertSidebarAccounts = (expectedRows: [string, string][]) => {
    cy.getByTestId('account-accordion-row', { timeout: 60000 }).each((row, index) => {
        cy.wrap(row)
            .find('[data-testid="account-accordion-row-name"]', { timeout: 60000 })
            .should('contain.text', expectedRows[index][0])
        cy.wrap(row)
            .find('[data-testid="account-accordion-row-balance"]', { timeout: 60000 })
            .should('contain.text', expectedRows[index][1])
    })
}

function openEditAccountModal() {
    cy.getByTestId('account-menu').within(() => {
        cy.getByTestId('account-menu-btn').click()
        cy.contains('Edit').click()
    })
}

describe('Accounts', () => {
    it('should sync and edit a plaid connection', () => {
        cy.apiRequest({
            method: 'POST',
            url: 'e2e/plaid/connect',
        }).then((response) => {
            expect(response.status).to.eql(200)

            // The only time we need to manually send a Plaid webhook is in Github actions when testing a PR
            if (Cypress.env('WEBHOOK_TYPE') === 'mock') {
                const { plaidItemId } = response.body.data.json

                cy.request({
                    method: 'POST',
                    url: `${Cypress.env('API_URL')}/plaid/webhook`,
                    body: {
                        webhook_type: 'TRANSACTIONS',
                        webhook_code: 'HISTORICAL_UPDATE',
                        item_id: plaidItemId,
                    },
                })
                    .its('status')
                    .should('equal', 200)
            }
        })

        // Check account sidebar names and balances
        cy.visit('/accounts')
        cy.getByTestId('account-group', { timeout: 20_000 })

        assertSidebarAccounts([
            ['Assets', '$20,000'],
            ['Cash', '$20,000'],
            ['Sandbox Savings', '$15,000'],
            ['Sandbox Checking', '$5,000'],
            ['Debts', '$950'],
            ['Credit Cards', '$950'],
            ['Sandbox CC', '$950'],
        ])

        // Check current net worth
        cy.visit('/')
        cy.getByTestId('current-data-value').should('contain.text', '$19,050.00')

        // Visit each account page, edit details, re-validate amounts
        cy.contains('a', 'Sandbox Checking').click()
        cy.getByTestId('current-data-value').should('contain.text', '$5,000.00')

        cy.contains('a', 'Sandbox Savings').click()
        cy.getByTestId('current-data-value').should('contain.text', '$15,000.00')

        cy.contains('a', 'Sandbox CC').click()
        cy.getByTestId('current-data-value').should('contain.text', '$950.00')

        openEditAccountModal()

        cy.getByTestId('connected-account-form').within(() => {
            cy.get('input[name="name"]')
                .should('have.value', 'Sandbox CC')
                .clear()
                .type('Credit Credit')
            cy.get('input[name="categoryUser"]').should('have.value', 'credit')
            cy.get('input[name="startDate"]')
                .should('have.value', '')
                .type(DateTime.now().minus({ months: 1 }).toFormat('MMddyyyy'))
            cy.root().submit()
        })

        // Should be able to submit empty start date on connected account
        openEditAccountModal()
        cy.getByTestId('connected-account-form').within(() => {
            cy.get('input[name="startDate"]').clear()
            cy.root().submit()
        })
    })

    it('should interpolate and display manual vehicle account data', () => {
        cy.getByTestId('add-account-button').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('vehicle-form-add-account').click()
        cy.contains('h4', 'Add vehicle')

        // Details
        cy.get('input[name="make"]').type('Tesla')
        cy.get('input[name="model"]').type('Model 3')
        cy.get('input[name="year"]').type('2022')

        // Purchase date
        cy.get('input[name="startDate"]')
            .clear()
            .type(DateTime.now().minus({ months: 1 }).toFormat('MMddyyyy'))

        // Valuation
        cy.get('input[name="originalBalance"]').type('60000')
        cy.get('input[name="currentBalance"]').type('50000')

        // Add account
        cy.getByTestId('vehicle-form-submit').click()

        // Check account sidebar names and balances
        assertSidebarAccounts([
            ['Assets', '$50,000'],
            ['Vehicles', '$50,000'],
            ['Tesla Model 3', '$50,000'],
        ])

        cy.visit('/')

        cy.getByTestId('current-data-value', { timeout: 30000 }).should('contain.text', '$50,000')

        // Visit individual account page
        cy.contains('a', 'Tesla Model 3').click()
        cy.getByTestId('current-data-value').should('contain.text', '$50,000.00')

        openEditAccountModal()

        cy.getByTestId('vehicle-form').within(() => {
            cy.get('input[name="make"]').should('have.value', 'Tesla').clear().type('Honda')
            cy.get('input[name="model"]').should('have.value', 'Model 3').clear().type('Civic')
            cy.get('input[name="year"]').should('have.value', '2022').clear().type('2020')
            cy.root().submit()
        })
    })

    it('should interpolate and display manual property account data', () => {
        cy.getByTestId('add-account-button').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('property-form-add-account').click()
        cy.contains('h4', 'Add real estate')

        // Details
        cy.get('input[name="country"]').select('GB')
        cy.get('input[name="line1"]').focus().type('123 Example St')
        cy.get('input[name="city"]').type('New York')
        cy.get('input[name="state"]').type('NY')
        cy.get('input[name="zip"]').type('12345')

        // Purchase date
        cy.get('input[name="startDate"]')
            .clear()
            .type(DateTime.now().minus({ months: 1 }).toFormat('MMddyyyy'))

        // Valuation
        cy.get('input[name="originalBalance"]').type('900000')
        cy.get('input[name="currentBalance"]').type('1000000')

        // Add account
        cy.getByTestId('property-form-submit').click()

        // Check account sidebar names and balances
        assertSidebarAccounts([
            ['Assets', '$1,000,000'],
            ['Real Estate', '$1,000,000'],
            ['123 Example St', '$1,000,000'],
        ])

        cy.visit('/')

        cy.getByTestId('current-data-value', { timeout: 30000 }).should(
            'contain.text',
            '$1,000,000'
        )

        // Visit individual account page
        cy.contains('a', '123 Example St').click()
        cy.getByTestId('current-data-value').should('contain.text', '$1,000,000.00')

        openEditAccountModal()

        cy.getByTestId('property-form').within(() => {
            cy.get('input[name="country]').should('have.value', 'GB').clear().select('FR')
            cy.get('input[name="line1"]')
                .should('have.value', '123 Example St')
                .clear()
                .type('456 Example St')
            cy.get('input[name="city"]')
                .should('have.value', 'New York')
                .clear()
                .type('Los Angeles')
            cy.get('input[name="state"]').should('have.value', 'NY').clear().type('CA')
            cy.get('input[name="zip"]').should('have.value', '12345').clear().type('56789')
            cy.root().submit()
        })
    })

    it('should interpolate and display manual "other asset" account data', () => {
        cy.getByTestId('add-account-button').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('manual-add-account').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('manual-add-asset').click()
        cy.contains('h4', 'Manual asset')

        // Details
        cy.get('input[name="name"]').type('Some Asset')

        // Purchase date
        cy.get('input[name="startDate"]')
            .clear()
            .type(DateTime.now().minus({ months: 1 }).toFormat('MMddyyyy'))

        // Valuation
        cy.get('input[name="originalBalance"]').type('5000')
        cy.get('input[name="currentBalance"]').type('10000')

        // Add account
        cy.getByTestId('asset-form-submit').click()

        // Check account sidebar names and balances
        assertSidebarAccounts([
            ['Assets', '$10,000'],
            ['Cash', '$10,000'],
            ['Some Asset', '$10,000'],
        ])

        cy.visit('/')

        cy.getByTestId('current-data-value', { timeout: 30000 }).should('contain.text', '$10,000')

        // Visit individual account page
        cy.contains('a', 'Some Asset').click()
        cy.getByTestId('current-data-value').should('contain.text', '$10,000.00')

        openEditAccountModal()

        cy.getByTestId('asset-form').within(() => {
            cy.get('input[name="name"]')
                .should('have.value', 'Some Asset')
                .clear()
                .type('Updated Asset')
            cy.get('input[name="categoryUser"]').should('have.value', 'cash')
            cy.root().submit()
        })
    })

    it('should interpolate and display manual "other liability" account data', () => {
        cy.getByTestId('add-account-button').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('manual-add-account').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('manual-add-debt').click()
        cy.contains('h4', 'Manual debt')

        // Details
        cy.get('input[name="name"]').type('Some Liability')

        // Purchase date
        cy.get('input[name="startDate"]')
            .clear()
            .type(DateTime.now().minus({ months: 1 }).toFormat('MMddyyyy'))

        // Valuation
        cy.get('input[name="originalBalance"]').type('5000')
        cy.get('input[name="currentBalance"]').type('10000')

        // Add account
        cy.getByTestId('liability-form-submit').click()

        // Check account sidebar names and balances
        assertSidebarAccounts([
            ['Debts', '$10,000'],
            ['Other', '$10,000'],
            ['Some Liability', '$10,000'],
        ])

        cy.visit('/')

        cy.getByTestId('current-data-value', { timeout: 30000 }).should('contain.text', '-$10,000')

        // Visit individual account page
        cy.contains('a', 'Some Liability').click()
        cy.getByTestId('current-data-value').should('contain.text', '$10,000.00')

        openEditAccountModal()

        cy.getByTestId('liability-form').within(() => {
            cy.get('input[name="name"]')
                .should('have.value', 'Some Liability')
                .clear()
                .type('Updated Liability')
            cy.get('input[name="categoryUser"]').should('have.value', 'other')
            cy.root().submit()
        })
    })

    it('should interpolate and display manual "loan" account data', () => {
        cy.getByTestId('add-account-button').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('manual-add-account').click()
        cy.contains('h4', 'Add account')
        cy.getByTestId('manual-add-debt').click()
        cy.contains('h4', 'Manual debt')
        cy.contains('label', 'Category').click()
        cy.contains('button', 'Loans').click()

        // Details
        cy.get('input[name="name"]').type('Manual Loan')

        // Purchase date
        cy.get('input[name="startDate"]')
            .clear()
            .type(DateTime.now().minus({ years: 1 }).toFormat('MMddyyyy'))

        // Valuation
        cy.get('input[name="originalBalance"]').type('10000')
        cy.get('input[name="currentBalance"]').type('9000')

        // Loan terms
        cy.get('input[name="maturityDate"]').type('360')
        cy.get('input[name="interestRate"]').clear().type('6')

        // Add account
        cy.getByTestId('liability-form-submit').click()

        // Check account sidebar names and balances
        assertSidebarAccounts([
            ['Debts', '$9,000'],
            ['Loans', '$9,000'],
            ['Manual Loan', '$9,000'],
        ])

        cy.visit('/')

        cy.getByTestId('current-data-value', { timeout: 30000 }).should('contain.text', '-$9,000')

        // Visit individual account page
        cy.contains('a', 'Manual Loan').click()
        cy.getByTestId('current-data-value').should('contain.text', '$9,000.00')

        openEditAccountModal()

        cy.getByTestId('liability-form').within(() => {
            cy.get('input[name="name"]')
                .should('have.value', 'Manual Loan')
                .clear()
                .type('Updated Loan')
            cy.get('input[name="categoryUser"]').should('have.value', 'loan')
            cy.get('input[name="loanType"]').should('have.value', 'mortgage')
            cy.get('input[name="interestType"]').should('have.value', 'fixed')
            cy.root().submit()
        })

        cy.getByTestId('loan-detail-cards').within(() => {
            cy.get('h3').should(($h3) => {
                expect($h3).to.have.length(3)
                expect($h3[0]).to.have.text('$10,000.00')
                expect($h3[1]).to.have.text('$9,000.00')
                expect($h3[2]).to.have.text('30 years')
            })
        })
    })
})

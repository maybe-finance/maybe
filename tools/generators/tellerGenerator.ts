import { faker } from '@faker-js/faker'
import { TellerTypes } from '../../libs/teller-api/src'

function generateSubType(
    type: TellerTypes.AccountTypes
): TellerTypes.DepositorySubtypes | TellerTypes.CreditSubtype {
    if (type === 'depository') {
        return faker.helpers.arrayElement([
            'checking',
            'savings',
            'money_market',
            'certificate_of_deposit',
            'treasury',
            'sweep',
        ]) as TellerTypes.DepositorySubtypes
    } else {
        return 'credit_card' as TellerTypes.CreditSubtype
    }
}

type GenerateAccountsParams = {
    count: number
    enrollmentId: string
    institutionName: string
    institutionId: string
}

export function generateAccounts({
    count,
    enrollmentId,
    institutionName,
    institutionId,
}: GenerateAccountsParams) {
    const accounts: TellerTypes.Account[] = []
    for (let i = 0; i < count; i++) {
        const accountId = faker.string.uuid()
        const lastFour = faker.finance.creditCardNumber().slice(-4)
        const type: TellerTypes.AccountTypes = faker.helpers.arrayElement(['depository', 'credit'])
        let subType: TellerTypes.DepositorySubtypes | TellerTypes.CreditSubtype
        subType = generateSubType(type)

        const accountStub = {
            enrollment_id: enrollmentId,
            links: {
                balances: `https://api.teller.io/accounts/${accountId}/balances`,
                self: `https://api.teller.io/accounts/${accountId}`,
                transactions: `https://api.teller.io/accounts/${accountId}/transactions`,
            },
            institution: {
                name: institutionName,
                id: institutionId,
            },
            name: faker.finance.accountName(),
            currency: 'USD',
            id: accountId,
            last_four: lastFour,
            status: faker.helpers.arrayElement(['open', 'closed']) as TellerTypes.AccountStatus,
        }

        if (faker.datatype.boolean()) {
            accounts.push({
                ...accountStub,
                type: 'depository',
                subtype: faker.helpers.arrayElement([
                    'checking',
                    'savings',
                    'money_market',
                    'certificate_of_deposit',
                    'treasury',
                    'sweep',
                ]),
            })
        } else {
            accounts.push({
                ...accountStub,
                type: 'credit',
                subtype: 'credit_card',
            })
        }
    }
    return accounts
}

export function generateBalance(account_id: string): TellerTypes.AccountBalance {
    const amount = faker.finance.amount()
    return {
        available: amount,
        ledger: amount,
        links: {
            account: `https://api.teller.io/accounts/${account_id}`,
            self: `https://api.teller.io/accounts/${account_id}/balances`,
        },
        account_id,
    }
}

type GenerateAccountsWithBalancesParams = {
    count: number
    enrollmentId: string
    institutionName: string
    institutionId: string
}

export function generateAccountsWithBalances({
    count,
    enrollmentId,
    institutionName,
    institutionId,
}: GenerateAccountsWithBalancesParams): TellerTypes.AccountWithBalances[] {
    const accountsWithBalances: TellerTypes.AccountWithBalances[] = []
    for (let i = 0; i < count; i++) {
        const account = generateAccounts({
            count,
            enrollmentId,
            institutionName,
            institutionId,
        })[0]
        const balance = generateBalance(account.id)
        accountsWithBalances.push({
            ...account,
            balance,
        })
    }
    return accountsWithBalances
}

export function generateTransactions(count: number, accountId: string): TellerTypes.Transaction[] {
    const transactions: TellerTypes.Transaction[] = []

    for (let i = 0; i < count; i++) {
        const transactionId = `txn_${faker.string.uuid()}`
        const transaction = {
            details: {
                processing_status: faker.helpers.arrayElement(['complete', 'pending']),
                category: faker.helpers.arrayElement([
                    'accommodation',
                    'advertising',
                    'bar',
                    'charity',
                    'clothing',
                    'dining',
                    'education',
                    'electronics',
                    'entertainment',
                    'fuel',
                    'general',
                    'groceries',
                    'health',
                    'home',
                    'income',
                    'insurance',
                    'investment',
                    'loan',
                    'office',
                    'phone',
                    'service',
                    'shopping',
                    'software',
                    'sport',
                    'tax',
                    'transport',
                    'transportation',
                    'utilities',
                ]),
                counterparty: {
                    name: faker.company.name(),
                    type: faker.helpers.arrayElement(['person', 'business']),
                },
            },
            running_balance: null,
            description: faker.word.words({ count: { min: 3, max: 10 } }),
            id: transactionId,
            date: faker.date.recent({ days: 30 }).toISOString().split('T')[0], // recent date in 'YYYY-MM-DD' format
            account_id: accountId,
            links: {
                account: `https://api.teller.io/accounts/${accountId}`,
                self: `https://api.teller.io/accounts/${accountId}/transactions/${transactionId}`,
            },
            amount: faker.finance.amount(),
            type: faker.helpers.arrayElement(['transfer', 'deposit', 'withdrawal']),
            status: faker.helpers.arrayElement(['pending', 'posted']),
        } as TellerTypes.Transaction
        transactions.push(transaction)
    }
    return transactions
}

export function generateEnrollment(): TellerTypes.Enrollment & { institutionId: string } {
    const institutionName = faker.company.name()
    const institutionId = institutionName.toLowerCase().replace(/\s/g, '_')
    return {
        accessToken: `token_${faker.string.alphanumeric(15)}`,
        user: {
            id: `usr_${faker.string.alphanumeric(15)}`,
        },
        enrollment: {
            id: `enr_${faker.string.alphanumeric(15)}`,
            institution: {
                name: institutionName,
            },
        },
        signatures: [faker.string.alphanumeric(15)],
        institutionId,
    }
}

export function generateConnections(count: number) {
    const enrollments: (TellerTypes.Enrollment & { institutionId: string })[] = []
    const accountsWithBalances: TellerTypes.AccountWithBalances[] = []
    const transactions: TellerTypes.Transaction[] = []
    for (let i = 0; i < count; i++) {
        enrollments.push(generateEnrollment())
    }
    enrollments.forEach((enrollment) => {
        const accountCount: number = faker.number.int({ min: 1, max: 5 })
        const transactionsCount: number = faker.number.int({ min: 1, max: 50 })
        const enrollmentId = enrollment.enrollment.id
        const institutionName = enrollment.enrollment.institution.name
        const institutionId = enrollment.institutionId
        accountsWithBalances.push(
            ...generateAccountsWithBalances({
                count: accountCount,
                enrollmentId,
                institutionName,
                institutionId,
            })
        )
        accountsWithBalances.forEach((account) => {
            transactions.push(...generateTransactions(transactionsCount, account.id))
        })
    })
}

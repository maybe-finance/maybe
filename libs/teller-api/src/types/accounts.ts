// https://teller.io/docs/api/accounts

export type AccountTypes = 'depository' | 'credit'

export type DepositorySubtypes =
    | 'checking'
    | 'savings'
    | 'money market'
    | 'certificate of deposit'
    | 'treasury'
    | 'sweep'

export type CreditSubtype = 'credit_card'

interface BaseAccount {
    enrollment_id: string
    links: {
        balances: string
        self: string
        transactions: string
    }
    institution: {
        name: string
        id: string
    }
    name: string
    currency: string
    id: string
    last_four: string
    status: 'open' | 'closed'
}

interface DepositoryAccount extends BaseAccount {
    type: 'depository'
    subtype: DepositorySubtypes
}

interface CreditAccount extends BaseAccount {
    type: 'credit'
    subtype: CreditSubtype
}

export type Account = DepositoryAccount | CreditAccount

export type GetAccountsResponse = { accounts: Account[] }
export type GetAccountResponse = Account
export type DeleteAccountResponse = void

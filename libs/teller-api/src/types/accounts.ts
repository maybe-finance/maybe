// https://teller.io/docs/api/accounts
import type { AccountBalance } from './account-balance'
import type { AuthenticatedRequest } from './authentication'

export type AccountTypes = 'depository' | 'credit'

export enum AccountType {
    'depository',
    'credit',
}

export type DepositorySubtypes =
    | 'checking'
    | 'savings'
    | 'money_market'
    | 'certificate_of_deposit'
    | 'treasury'
    | 'sweep'

export type CreditSubtype = 'credit_card'

export type AccountStatus = 'open' | 'closed'

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
    status: AccountStatus
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

export type AccountWithBalances = Account & {
    balance: AccountBalance
}

export type GetAccountsResponse = Account[]
export type GetAccountResponse = Account
export type DeleteAccountResponse = void

export interface GetAccountRequest extends AuthenticatedRequest {
    accountId: string
}

export type DeleteAccountRequest = GetAccountRequest

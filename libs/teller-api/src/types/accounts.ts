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

export type AccountWithBalances = Account & {
    balances: AccountBalance
}

export type GetAccountsResponse = Account[]
export type GetAccountResponse = Account
export type DeleteAccountResponse = void

export interface GetAccountRequest extends AuthenticatedRequest {
    accountId: string
}

export type DeleteAccountRequest = GetAccountRequest

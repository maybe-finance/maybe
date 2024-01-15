// https://teller.io/docs/api/account/balances
import type { AuthenticatedRequest } from './authentication'

export type AccountBalance = {
    account_id: string
    ledger: string
    available: string
    links: {
        self: string
        account: string
    }
}

export type GetAccountBalancesResponse = AccountBalance
export interface GetAccountBalancesRequest extends AuthenticatedRequest {
    accountId: string
}

// https://teller.io/docs/api/account/balances

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

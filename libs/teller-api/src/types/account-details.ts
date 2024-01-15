// https://teller.io/docs/api/account/details

export type AccountDetails = {
    account_id: string
    account_number: string
    links: {
        account: string
        self: string
    }
    routing_numbers: {
        ach?: string
        wire?: string
        bacs?: string
    }
}

export type GetAccountDetailsResponse = AccountDetails

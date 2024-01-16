// https://teller.io/docs/api/account/details

import type { AuthenticatedRequest } from './authentication'

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
export interface GetAccountDetailsRequest extends AuthenticatedRequest {
    accountId: string
}

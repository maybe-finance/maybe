// https://teller.io/docs/api/account/transactions

import type { AuthenticatedRequest } from './authentication'

type DetailCategory =
    | 'accommodation'
    | 'advertising'
    | 'bar'
    | 'charity'
    | 'clothing'
    | 'dining'
    | 'education'
    | 'electronics'
    | 'entertainment'
    | 'fuel'
    | 'general'
    | 'groceries'
    | 'health'
    | 'home'
    | 'income'
    | 'insurance'
    | 'investment'
    | 'loan'
    | 'office'
    | 'phone'
    | 'service'
    | 'shopping'
    | 'software'
    | 'sport'
    | 'tax'
    | 'transport'
    | 'transportation'
    | 'utilities'

type DetailProcessingStatus = 'pending' | 'complete'

export type Transaction = {
    details: {
        category?: DetailCategory
        processing_status: DetailProcessingStatus
        counterparty: {
            name?: string
            type?: 'organization' | 'person'
        }
    }
    running_balance: string | null
    description: string
    id: string
    date: string
    account_id: string
    links: {
        self: string
        account: string
    }
    amount: string
    status: string
    type: string
}

export type GetTransactionsResponse = Transaction[]
export type GetTransactionResponse = Transaction
export interface GetTransactionsRequest extends AuthenticatedRequest {
    accountId: string
}
export interface GetTransactionRequest extends AuthenticatedRequest {
    accountId: string
    transactionId: string
}

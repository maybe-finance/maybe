/** https://api-reference.finicity.com/#/rest/models/enumerations/transaction-type */
export type TransactionType =
    | 'atm'
    | 'cash'
    | 'check'
    | 'credit'
    | 'debit'
    | 'deposit'
    | 'directDebit'
    | 'directDeposit'
    | 'dividend'
    | 'fee'
    | 'interest'
    | 'other'
    | 'payment'
    | 'pointOfSale'
    | 'repeatPayment'
    | 'serviceCharge'
    | 'transfer'
    | 'DIV' // undocumented
    | 'SRVCHG' // undocumented

/** https://api-reference.finicity.com/#/rest/models/structures/categorization */
export type TransactionCategorization = {
    [key: string]: any
    normalizedPayeeName: string
    /** https://api-reference.finicity.com/#/rest/models/enumerations/categories */
    category: string
    city?: string
    state?: string
    postalCode?: string
    country: string
    bestRepresentation?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/transaction */
export type Transaction = {
    [key: string]: any
    id: number
    amount: number
    accountId: number
    customerId: number
    status: 'active' | 'pending' | 'shadow'
    description: string
    memo?: string
    postedDate: number
    transactionDate?: number
    effectiveDate?: number
    firstEffectiveDate?: number
    createdDate: number
    type?: TransactionType | string
    checkNum?: number
    escrowAmount?: number
    feeAmount?: number
    interestAmount?: number
    principalAmount?: number
    unitQuantity?: number
    unitPrice?: number
    categorization?: TransactionCategorization
    subaccountSecurityType?: string
    commissionAmount?: number
    symbol?: string
    ticker?: string
    investmentTransactionType?: string
    taxesAmount?: number
    currencySymbol?: string
    securityId?: string
    securityIdType?: string
}

/** https://api-reference.finicity.com/#/rest/api-endpoints/transactions/get-customer-account-transactions */
export type GetAccountTransactionsRequest = {
    customerId: string
    accountId: string
    fromDate: number
    toDate: number
    start?: number
    limit?: number
    sort?: 'asc' | 'desc'
    includePending?: boolean
}

/** https://api-reference.finicity.com/#/rest/models/structures/get-transactions-response */
export type GetAccountTransactionsResponse = {
    found: number
    displaying: number
    moreAvailable: string
    fromDate: string
    toDate: string
    sort: string
    transactions: Transaction[]
}

/** https://api-reference.finicity.com/#/rest/api-endpoints/accounts/load-historic-transactions-for-customer-account */
export type LoadHistoricTransactionsRequest = {
    customerId: string
    accountId: string
}

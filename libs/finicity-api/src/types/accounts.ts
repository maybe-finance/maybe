/** https://api-reference.finicity.com/#/rest/models/enumerations/account-type */
export type AccountType =
    | 'checking'
    | 'savings'
    | 'cd'
    | 'moneyMarket'
    | 'creditCard'
    | 'lineOfCredit'
    | 'investment'
    | 'brokerageAccount'
    | 'pension'
    | 'profitSharingPlan'
    | 'investmentTaxDeferred'
    | 'employeeStockPurchasePlan'
    | 'ira'
    | 'simpleIRA'
    | 'sepIRA'
    | '401k'
    | 'roth'
    | 'roth401k'
    | '403b'
    | '529'
    | '529plan'
    | 'rollover'
    | 'ugma'
    | 'utma'
    | 'keogh'
    | '457'
    | '457plan'
    | '401a'
    | 'cryptocurrency'
    | 'mortgage'
    | 'loan'
    | 'studentLoan'
    | 'studentLoanGroup'
    | 'studentLoanAccount'

/** https://api-reference.finicity.com/#/rest/models/structures/customer-account-position */
export type CustomerAccountPosition = {
    [key: string]: any
    id?: number
    description?: string
    securityId?: string
    securityIdType?: string
    symbol?: string
    /** @deprecated finicity still uses this field in lieu of `units` for some accounts (eg. Citibank) as of 2023-01-30 */
    quantity?: number
    units?: number
    currentPrice?: number
    securityName?: string
    /** @deprecated undocumented field */
    fundName?: string
    transactionType?: string
    marketValue?: number | string
    costBasis?: number
    status?: string
    currentPriceDate?: number
    invSecurityType?: string
    mfType?: string
    posType?: string
    totalGLDollar?: number
    totalGLPercent?: number
    securityType?: string
    securityCurrency?: string
    fiAssetClass?: string
    assetClass?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/customer-account-detail */
export type CustomerAccountDetail = {
    [key: string]: any
    availableBalanceAmount?: number
    availableCashBalance?: number
    interestRate?: string
    creditAvailableAmount?: number
    paymentMinAmount?: number
    statementCloseBalance?: number
    locPrincipalBalance?: number
    paymentDueDate?: number
    statementEndDate?: number
    vestedBalance?: number
    currentLoanBalance?: number
    payoffAmount?: number
    principalBalance?: number
    autoPayEnrolled?: 'Y' | 'N'
    firstMortgage?: 'Y' | 'N'
    recurringPaymentAmount?: number
    lender?: string
    endingBalanceAmount?: number
    loanTermType?: string
    paymentsMade?: number
    balloonAmount?: number
    paymentsRemaining?: number
    loanMinAmtDue?: number
    loanPaymentFreq?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/customer-account */
export type CustomerAccount = {
    [key: string]: any
    id: string
    accountNumberDisplay: string
    realAccountNumberLast4?: string
    name: string
    balance?: number
    type: AccountType
    aggregationStatusCode?: number
    status: string
    customerId: string
    institutionId: string
    balanceDate: number
    aggregationSuccessDate?: number
    aggregationAttemptDate?: number
    createdDate: number
    currency: string
    lastTransactionDate?: number
    /** Incorrectly shown as "Required" in Finicity docs */
    oldestTransactionDate?: number
    institutionLoginId: number
    detail?: CustomerAccountDetail
    position?: CustomerAccountPosition[]
    displayPosition: number
    parentAccount?: number

    /** Not in Finicity docs */
    accountNickname?: string
    /** Not in Finicity docs */
    marketSegment?: string

    /** @deprecated */
    number?: string
}

/** https://api-reference.finicity.com/#/rest/api-endpoints/accounts/get-customer-accounts */
export type GetCustomerAccountsRequest = {
    customerId: string
    status?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/customer-accounts */
export type GetCustomerAccountsResponse = {
    accounts: CustomerAccount[]
}

/** https://api-reference.finicity.com/#/rest/api-endpoints/accounts/get-customer-account */
export type GetCustomerAccountRequest = {
    customerId: string
    accountId: number
}

export type GetCustomerAccountResponse = CustomerAccount

export type RefreshCustomerAccountRequest = {
    customerId: string | number
}

/** https://api-reference.finicity.com/#/rest/api-endpoints/accounts/delete-customer-accounts-by-institution-login */
export type DeleteCustomerAccountsByInstitutionLoginRequest = {
    customerId: string
    institutionLoginId: number
}

export type DeleteCustomerAccountsByInstitutionLoginResponse = void

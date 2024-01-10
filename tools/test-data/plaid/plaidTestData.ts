import type {
    Item,
    Security,
    Transaction,
    AccountBase,
    InvestmentTransaction,
    CreditCardLiability,
    Holding,
} from 'plaid'

import {
    ItemUpdateTypeEnum,
    Products,
    TransactionPaymentChannelEnum,
    TransactionTransactionTypeEnum,
    AccountType,
    AccountSubtype,
    InvestmentTransactionSubtype,
    InvestmentTransactionType,
    APRAprTypeEnum,
} from 'plaid'

import { testDates } from './testDates'

const { now } = testDates

export const item: Item = {
    available_products: [Products.Balance, Products.Transactions, Products.Investments],
    billed_products: [],
    consent_expiration_time: null,
    error: null,
    institution_id: 'ins_3',
    item_id: 'DWVAAPWq4RHGlEaNyGKRTAnPLaEmo8Cvq7abc',
    update_type: ItemUpdateTypeEnum.Background,
    webhook: 'https://www.genericwebhookurl.com/webhook',
}

export const checkingAccount: AccountBase = {
    account_id: 'blgvvBlXw3cq5GMPwqB6s6q4dLKB9WcVqGabc',
    balances: {
        available: null,
        current: 5000,
        iso_currency_code: 'USD',
        limit: null,
        unofficial_currency_code: null,
    },
    mask: '1234',
    name: 'Checking',
    official_name: null,
    type: AccountType.Depository,
    subtype: AccountSubtype.Checking,
}

export const creditAccount: AccountBase = {
    account_id: '6PdjjRP6LmugpBy5NgQvUqpRXMWxzktg3rdef',
    balances: {
        available: null,
        current: 1000,
        iso_currency_code: 'USD',
        limit: null,
        unofficial_currency_code: null,
    },
    mask: '1234',
    name: 'Credit Card',
    official_name: null,
    type: AccountType.Credit,
    subtype: AccountSubtype.CreditCard,
}

export const brokerageAccount: AccountBase = {
    account_id: '6PdjjRP6LmugpBy5NgQvUqpRXMWxzktg3rghi',
    balances: {
        available: null,
        current: 10000,
        iso_currency_code: 'USD',
        limit: null,
        unofficial_currency_code: null,
    },
    mask: '5847',
    name: 'Brokerage Account',
    official_name: null,
    type: AccountType.Investment,
    subtype: AccountSubtype.Brokerage,
}

const baseTxn = {
    payment_meta: {
        by_order_of: null,
        payee: null,
        payer: null,
        payment_method: null,
        payment_processor: null,
        ppd_id: null,
        reason: null,
        reference_number: null,
    },
    location: {
        address: null,
        city: null,
        region: null,
        postal_code: null,
        country: null,
        lat: null,
        lon: null,
        store_number: null,
    },
    iso_currency_code: 'USD',
    unofficial_currency_code: null,
    check_number: null,
    datetime: null,
    authorized_date: null,
    authorized_datetime: null,
    payment_channel: TransactionPaymentChannelEnum.InStore,
    pending: false,
    pending_transaction_id: null,
    account_owner: null,
    transaction_code: null,
    transaction_type: TransactionTransactionTypeEnum.Place,
}

export const checkingTransactions: Transaction[] = [
    {
        account_id: checkingAccount.account_id,
        amount: -1500.0,
        date: '2021-12-20',
        name: 'Income: Paycheck',
        merchant_name: 'Acme Corp',
        category: ['Transfer', 'Payroll'],
        category_id: '21009000',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD01',
        ...baseTxn,
    },
    {
        account_id: checkingAccount.account_id,
        amount: 5,
        date: '2021-12-20',
        name: 'Expense: Starbucks',
        merchant_name: 'Starbucks',
        category: ['Shops', 'Food and Beverage Store'],
        category_id: '19025001',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD02',
        ...baseTxn,
    },
    {
        account_id: checkingAccount.account_id,
        amount: 10,
        date: '2021-12-29',
        name: 'Expense: CVS',
        merchant_name: 'CVS Pharmacy',
        category: ['Shops', 'Pharmacies'],
        category_id: '19043000',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD03',
        ...baseTxn,
    },
    {
        account_id: checkingAccount.account_id,
        amount: 25.55,
        date: '2022-01-01',
        name: 'CVS',
        merchant_name: 'CVS',
        category: ['Shops', 'Bookstores'],
        category_id: '19009000',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD04',
        ...baseTxn,
    },
    {
        account_id: checkingAccount.account_id,
        amount: 89.45,
        date: now.toISODate(),
        name: 'Expense: Amazon',
        merchant_name: 'Amazon',
        category: ['Shops', 'Bookstores'],
        category_id: '19009000',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD05',
        ...baseTxn,
    },
]

export const creditTransactions: Transaction[] = [
    {
        account_id: creditAccount.account_id,
        amount: 200.25,
        date: '2022-12-24',
        name: 'Grocery Store',
        merchant_name: 'Grocery Store Inc.',
        category: ['Shops', 'Food and Beverage Store'],
        category_id: '19025001',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD06',
        ...baseTxn,
    },
    {
        account_id: creditAccount.account_id,
        amount: -600,
        date: '2022-12-26',
        name: 'Credit Card Payment',
        merchant_name: 'None',
        category: ['Payment', 'Credit Card'],
        category_id: '16001000',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD07',
        ...baseTxn,
    },
    {
        account_id: creditAccount.account_id,
        amount: 10.0,
        date: '2022-01-01',
        name: 'Expense: CVS',
        merchant_name: 'CVS Pharmacy',
        category: ['Shops', 'Pharmacies'],
        category_id: '19043000',
        transaction_id: 'lPNjeW1nR6CDn5okmGQ6hEpMo4lLNoSrzqD08',
        ...baseTxn,
    },
]

export const creditCardLiability: CreditCardLiability = {
    account_id: creditAccount.account_id,
    aprs: [
        {
            apr_percentage: 15.24,
            apr_type: APRAprTypeEnum.BalanceTransferApr,
            balance_subject_to_apr: 0,
            interest_charge_amount: 0,
        },
        {
            apr_percentage: 27.95,
            apr_type: APRAprTypeEnum.CashApr,
            balance_subject_to_apr: 0,
            interest_charge_amount: 0,
        },
        {
            apr_percentage: 12.5,
            apr_type: APRAprTypeEnum.PurchaseApr,
            balance_subject_to_apr: 0,
            interest_charge_amount: 0,
        },
        {
            apr_percentage: 0,
            apr_type: APRAprTypeEnum.Special,
            balance_subject_to_apr: 0,
            interest_charge_amount: 0,
        },
    ],
    is_overdue: false,
    last_payment_amount: 600,
    last_payment_date: '2021-12-26', // see txn above
    last_statement_issue_date: '2022-01-01',
    last_statement_balance: 1400,
    minimum_payment_amount: 25,
    next_payment_due_date: '2022-12-26', // 1 month after last payment (above)
}

const appleStock = {
    id: 'JDdP7XPMklt5vwPmDN45t3KAoWAPmjtpaW7DP',
    name: 'Apple Inc.',
    cusip: '0378331006',
    ticker: 'AAPL',
}

const walmartStock = {
    id: 'NDVQrXQoqzt5v3bAe8qRt4A7mK7wvZCLEBBJk',
    name: 'Walmart Inc.',
    cusip: '93114210310',
    ticker: 'WMT',
}

const sp500IndexFund = {
    id: 'BDVQrXQoqzt5v3bAe8qRtjA7mK7wvZCLEBBJk',
    name: 'S&P 500 Index Fund',
    cusip: '922908363',
    ticker: 'VOO',
}

export const holdings: Holding[] = [
    {
        account_id: brokerageAccount.account_id,
        cost_basis: 432.2,
        institution_price: 439.25,
        institution_price_as_of: now.toISODate(), // 2022-01-03
        institution_value: 19766.25, // price * qty
        iso_currency_code: 'USD',
        quantity: 45,
        security_id: sp500IndexFund.id,
        unofficial_currency_code: null,
    },
    {
        account_id: brokerageAccount.account_id,
        cost_basis: 172.89, // actual cost basis (calculated based on txns)
        institution_price: 182.01,
        institution_price_as_of: now.toISODate(),
        institution_value: 1820.1,
        iso_currency_code: 'USD',
        quantity: 10,
        security_id: appleStock.id,
        unofficial_currency_code: null,
    },
    {
        account_id: brokerageAccount.account_id,
        cost_basis: 140.76,
        institution_price: 144.65,
        institution_price_as_of: now.toISODate(),
        institution_value: 1186.13,
        iso_currency_code: 'USD',
        quantity: 8.2,
        security_id: walmartStock.id,
        unofficial_currency_code: null,
    },
]

export const investmentTransactions: InvestmentTransaction[] = [
    {
        account_id: brokerageAccount.account_id,
        amount: -270,
        date: '2022-01-03',
        fees: 0,
        investment_transaction_id: 'pK99jB9e7mtwjA435GpVuMvmWQKVbVFLWm002',
        iso_currency_code: 'USD',
        name: `SELL ${appleStock.name}`,
        price: 182.01,
        quantity: -10,
        security_id: appleStock.id,
        subtype: InvestmentTransactionSubtype.Sell,
        type: InvestmentTransactionType.Sell,
        unofficial_currency_code: null,
    },
    {
        account_id: brokerageAccount.account_id,
        amount: 1154.23,
        date: '2021-12-27',
        fees: 0,
        investment_transaction_id: 'LKoo1ko93wtreBwM7yQnuQ3P5DNKbKSPRz003',
        iso_currency_code: 'USD',
        name: `BUY ${walmartStock.name}`,
        price: 140.76,
        quantity: 8.2,
        security_id: walmartStock.id,
        subtype: InvestmentTransactionSubtype.Buy,
        type: InvestmentTransactionType.Buy,
        unofficial_currency_code: null,
    },
    {
        account_id: brokerageAccount.account_id,
        amount: 3275.2, //  price * qty
        date: '2021-12-02',
        fees: 0,
        investment_transaction_id: 'LKoo1ko93wtreBwM7yQnuQ3P5DNKbKSPRz004',
        iso_currency_code: 'USD',
        name: `BUY ${appleStock.name}`,
        price: 163.76,
        quantity: 20,
        security_id: appleStock.id,
        subtype: InvestmentTransactionSubtype.Buy,
        type: InvestmentTransactionType.Buy,
        unofficial_currency_code: null,
    },
]

export const securities: Security[] = [
    {
        close_price: 439.25,
        close_price_as_of: now.toISODate(),
        cusip: sp500IndexFund.cusip,
        institution_id: null,
        institution_security_id: null,
        is_cash_equivalent: false,
        isin: null,
        iso_currency_code: 'USD',
        name: sp500IndexFund.name,
        proxy_security_id: null,
        security_id: sp500IndexFund.id,
        sedol: null,
        ticker_symbol: sp500IndexFund.ticker,
        type: 'etf',
        unofficial_currency_code: null,
    },
    {
        close_price: 182.01,
        close_price_as_of: now.toISODate(),
        cusip: appleStock.cusip,
        institution_id: null,
        institution_security_id: null,
        is_cash_equivalent: false,
        isin: null,
        iso_currency_code: 'USD',
        name: appleStock.name,
        proxy_security_id: null,
        security_id: appleStock.id,
        sedol: null,
        ticker_symbol: appleStock.ticker,
        type: 'equity',
        unofficial_currency_code: null,
    },
    {
        close_price: 144.65,
        close_price_as_of: now.toISODate(),
        cusip: walmartStock.cusip,
        institution_id: null,
        institution_security_id: null,
        is_cash_equivalent: false,
        isin: null,
        iso_currency_code: 'USD',
        name: walmartStock.name,
        proxy_security_id: null,
        security_id: walmartStock.id,
        sedol: null,
        ticker_symbol: walmartStock.ticker,
        type: 'equity',
        unofficial_currency_code: null,
    },
]

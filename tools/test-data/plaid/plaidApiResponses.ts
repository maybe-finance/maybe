import type { AxiosResponse } from 'axios'
import type {
    AccountsGetResponse,
    InstitutionsGetByIdResponse,
    InvestmentsHoldingsGetResponse,
    InvestmentsTransactionsGetResponse,
    LiabilitiesGetResponse,
    TransactionsGetResponse,
} from 'plaid'
import {
    CountryCode,
    ProductStatusStatusEnum,
    ProductStatusBreakdownRefreshIntervalEnum,
    Products,
} from 'plaid'
import {
    brokerageAccount,
    checkingAccount,
    checkingTransactions,
    creditAccount,
    creditCardLiability,
    creditTransactions,
    holdings,
    investmentTransactions,
    item,
    securities,
} from './plaidTestData'
import { TestUtil } from '../../../libs/shared/src/utils'

const accounts = [checkingAccount, creditAccount, brokerageAccount]

export const investmentsTransactionsGetResponse: AxiosResponse<InvestmentsTransactionsGetResponse> =
    TestUtil.axiosSuccess<InvestmentsTransactionsGetResponse>({
        accounts,
        investment_transactions: investmentTransactions,
        item,
        request_id: 'iv4q3ZlytOOthkv',
        securities,
        total_investment_transactions: investmentTransactions.length,
    })

export const investmentsHoldingsGetResponse = TestUtil.axiosSuccess<InvestmentsHoldingsGetResponse>(
    {
        accounts,
        holdings,
        securities,
        item,
        request_id: 'iv4q3ZlytOOt123',
    }
)

export const liabilitiesGetResponse = TestUtil.axiosSuccess<LiabilitiesGetResponse>({
    accounts,
    item,
    liabilities: { credit: [creditCardLiability], mortgage: null, student: null },
    request_id: '23kjf23ij2ekfj2ej',
})

export const accountsGetResponse = TestUtil.axiosSuccess<AccountsGetResponse>({
    accounts,
    item,
    request_id: 'bkVE1BHWMAZ9Rnr',
})

export const transactionsGetResponse = TestUtil.axiosSuccess<TransactionsGetResponse>({
    accounts,
    transactions: [...checkingTransactions, ...creditTransactions],
    item,
    total_transactions: checkingTransactions.length + creditTransactions.length, // 8
    request_id: '45QSn',
})

export const institutionsGetByIdResponse = TestUtil.axiosSuccess<InstitutionsGetByIdResponse>({
    institution: {
        country_codes: [CountryCode.Us],
        institution_id: 'ins_109512',
        name: 'Houndstooth Bank',
        products: [Products.Auth, Products.Balance, Products.Transactions, Products.Investments],
        routing_numbers: ['011000138', '011200365', '011400495'],
        oauth: false,
        status: {
            item_logins: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-15T15:53:00Z',
                breakdown: {
                    success: 0.9,
                    error_plaid: 0.01,
                    error_institution: 0.09,
                },
            },
            transactions_updates: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-12T08:22:00Z',
                breakdown: {
                    success: 0.95,
                    error_plaid: 0.02,
                    error_institution: 0.03,
                    refresh_interval: ProductStatusBreakdownRefreshIntervalEnum.Normal,
                },
            },
            auth: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-15T15:53:00Z',
                breakdown: {
                    success: 0.91,
                    error_plaid: 0.01,
                    error_institution: 0.08,
                },
            },
            identity: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-15T15:50:00Z',
                breakdown: {
                    success: 0.42,
                    error_plaid: 0.08,
                    error_institution: 0.5,
                },
            },
            investments: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-15T15:53:00Z',
                breakdown: {
                    success: 0.89,
                    error_plaid: 0.02,
                    error_institution: 0.09,
                },
                liabilities: {
                    status: ProductStatusStatusEnum.Healthy,
                    last_status_change: '2019-02-15T15:53:00Z',
                    breakdown: {
                        success: 0.89,
                        error_plaid: 0.02,
                        error_institution: 0.09,
                    },
                },
            },
            investments_updates: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-12T08:22:00Z',
                breakdown: {
                    success: 0.95,
                    error_plaid: 0.02,
                    error_institution: 0.03,
                    refresh_interval: ProductStatusBreakdownRefreshIntervalEnum.Normal,
                },
            },
            liabilities_updates: {
                status: ProductStatusStatusEnum.Healthy,
                last_status_change: '2019-02-12T08:22:00Z',
                breakdown: {
                    success: 0.95,
                    error_plaid: 0.02,
                    error_institution: 0.03,
                    refresh_interval: ProductStatusBreakdownRefreshIntervalEnum.Normal,
                },
            },
        },
        primary_color: '#004966',
        url: 'https://plaid.com',
        logo: null,
    },
    request_id: 'm8MDnv9okwxFNBV',
})

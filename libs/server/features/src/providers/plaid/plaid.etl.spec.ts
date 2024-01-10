import { PlaidApi, PlaidErrorType } from 'plaid'
import { PrismaClient } from '@prisma/client'
import { createLogger, transports } from 'winston'
import { CryptoService } from '@maybe-finance/server/shared'
import { TestUtil } from '@maybe-finance/shared'
import { PlaidTestData } from '../../../../../../tools/test-data'
import { PlaidETL } from './plaid.etl'
jest.mock('@prisma/client')
jest.mock('plaid')

const prisma = jest.mocked(new PrismaClient())
const plaid = jest.mocked(new PlaidApi())
const logger = createLogger({ transports: [new transports.Console()] })
const crypto = jest.mocked(new CryptoService('TEST_SECRET'))
const marketData = jest.mocked({
    source: 'TEST_MOCK',
    getDailyPricing: jest.fn(),
    getLivePricing: jest.fn(),
    getOptionDetails: jest.fn(),
})

describe('Plaid ETL', () => {
    it.each`
        errorType                   | errorCode                        | endpoints
        ${PlaidErrorType.ItemError} | ${'PRODUCTS_NOT_SUPPORTED'}      | ${['investmentsTransactionsGet', 'investmentsHoldingsGet', 'liabilitiesGet']}
        ${PlaidErrorType.ItemError} | ${'PRODUCT_NOT_READY'}           | ${['investmentsTransactionsGet', 'investmentsHoldingsGet', 'liabilitiesGet']}
        ${PlaidErrorType.ItemError} | ${'NO_INVESTMENT_ACCOUNTS'}      | ${['investmentsTransactionsGet', 'investmentsHoldingsGet']}
        ${PlaidErrorType.ItemError} | ${'NO_INVESTMENT_AUTH_ACCOUNTS'} | ${['investmentsTransactionsGet', 'investmentsHoldingsGet']}
        ${PlaidErrorType.ItemError} | ${'NO_LIABILITY_ACCOUNTS'}       | ${['liabilitiesGet']}
    `(
        `extracts ignoring errors ($errorType | $errorCode | $endpoints)`,
        async ({ errorType, errorCode, endpoints }) => {
            const item = PlaidTestData.item

            plaid.accountsGet.mockResolvedValue(
                TestUtil.axiosSuccess({
                    item,
                    accounts: [PlaidTestData.checkingAccount],
                    request_id: '1',
                })
            )

            if (endpoints.includes('transactionsGet')) {
                plaid.transactionsGet.mockRejectedValue(
                    TestUtil.mockPlaidError({
                        error_type: errorType,
                        error_code: errorCode,
                        error_message: '',
                        display_message: null,
                    })
                )
            } else {
                plaid.transactionsGet.mockResolvedValue(
                    TestUtil.axiosSuccess({
                        item,
                        accounts: [PlaidTestData.checkingAccount],
                        transactions: PlaidTestData.checkingTransactions,
                        total_transactions: PlaidTestData.checkingTransactions.length,
                        request_id: '2',
                    })
                )
            }

            if (endpoints.includes('investmentsTransactionsGet')) {
                plaid.investmentsTransactionsGet.mockRejectedValue(
                    TestUtil.mockPlaidError({
                        error_type: errorType,
                        error_code: errorCode,
                        error_message: '',
                        display_message: null,
                    })
                )
            } else {
                plaid.investmentsTransactionsGet.mockResolvedValue(
                    TestUtil.axiosSuccess({
                        item,
                        accounts: [PlaidTestData.brokerageAccount],
                        investment_transactions: PlaidTestData.investmentTransactions,
                        holdings: PlaidTestData.holdings,
                        securities: PlaidTestData.securities,
                        total_investment_transactions: PlaidTestData.investmentTransactions.length,
                        request_id: '3',
                    })
                )
            }

            if (endpoints.includes('investmentsHoldingsGet')) {
                plaid.investmentsHoldingsGet.mockRejectedValue(
                    TestUtil.mockPlaidError({
                        error_type: errorType,
                        error_code: errorCode,
                        error_message: '',
                        display_message: null,
                    })
                )
            } else {
                plaid.investmentsHoldingsGet.mockResolvedValue(
                    TestUtil.axiosSuccess({
                        item,
                        accounts: [PlaidTestData.brokerageAccount],
                        holdings: PlaidTestData.holdings,
                        securities: PlaidTestData.securities,
                        request_id: '4',
                    })
                )
            }

            if (endpoints.includes('liabilitiesGet')) {
                plaid.liabilitiesGet.mockRejectedValue(
                    TestUtil.mockPlaidError({
                        error_type: errorType,
                        error_code: errorCode,
                        error_message: '',
                        display_message: null,
                    })
                )
            } else {
                plaid.liabilitiesGet.mockResolvedValue(
                    TestUtil.axiosSuccess({
                        item,
                        accounts: [PlaidTestData.creditAccount],
                        liabilities: {
                            credit: [PlaidTestData.creditCardLiability],
                            mortgage: null,
                            student: null,
                        },
                        request_id: '5',
                    })
                )
            }

            const etl = new PlaidETL(logger, prisma, plaid, crypto, marketData)

            const data = await etl.extract({
                id: 123,
                plaidAccessToken: crypto.encrypt('DUMMY_PLAID_ACCESS_TOKEN'),
            })

            expect(data.item).toMatchObject(item)
            expect(data.accounts).toHaveLength(1)
            expect(data.holdings).toHaveLength(endpoints.includes('investmentsHoldingsGet') ? 0 : 3)
            expect(data.liabilities).toMatchObject({
                credit: endpoints.includes('liabilitiesGet') ? null : {},
                mortgage: null,
                student: null,
            })
            expect(data.transactions).toHaveLength(endpoints.includes('transactionsGet') ? 0 : 5)
            expect(data.investmentTransactions).toHaveLength(
                endpoints.includes('investmentsTransactionsGet') ? 0 : 3
            )
        }
    )

    it('extracts throwing unhandled errors', async () => {
        const item = PlaidTestData.item
        const error = TestUtil.mockPlaidError({
            error_type: PlaidErrorType.ItemError,
            error_code: 'ITEM_LOGIN_REQUIRED',
            error_message: '',
            display_message: null,
        })

        plaid.accountsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                item,
                accounts: [
                    PlaidTestData.checkingAccount,
                    PlaidTestData.brokerageAccount,
                    PlaidTestData.creditAccount,
                ],
                request_id: '1',
            })
        )

        plaid.transactionsGet.mockRejectedValue(error)

        plaid.investmentsTransactionsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                item,
                accounts: [PlaidTestData.brokerageAccount],
                investment_transactions: PlaidTestData.investmentTransactions,
                holdings: PlaidTestData.holdings,
                securities: PlaidTestData.securities,
                total_investment_transactions: PlaidTestData.investmentTransactions.length,
                request_id: '3',
            })
        )

        plaid.investmentsHoldingsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                item,
                accounts: [PlaidTestData.brokerageAccount],
                holdings: PlaidTestData.holdings,
                securities: PlaidTestData.securities,
                request_id: '4',
            })
        )

        plaid.liabilitiesGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                item,
                accounts: [PlaidTestData.creditAccount],
                liabilities: {
                    credit: [PlaidTestData.creditCardLiability],
                    mortgage: null,
                    student: null,
                },
                request_id: '5',
            })
        )

        const etl = new PlaidETL(logger, prisma, plaid, crypto, marketData)

        expect(
            etl.extract({
                id: 123,
                plaidAccessToken: crypto.encrypt('DUMMY_PLAID_ACCESS_TOKEN'),
            })
        ).rejects.toThrowError(error)
    })

    it.each`
        symbol                   | type            | expected
        ${'AAPL'}                | ${'equity'}     | ${'AAPL'}
        ${'AAPL240315P00115000'} | ${'equity'}     | ${'AAPL'}
        ${'AAPL240315P00115000'} | ${'derivative'} | ${'AAPL240315P00115000'}
    `(`maps security $symbol ($type) -> $expected`, async ({ symbol, type, expected }) => {
        const etl = new PlaidETL(logger, prisma, plaid, crypto, marketData)

        const data = await etl.transform(
            {
                id: 123,
                plaidAccessToken: crypto.encrypt('DUMMY_PLAID_ACCESS_TOKEN'),
            },
            {
                item: { error: null, consent_expiration_time: null },
                accounts: [],
                transactions: [],
                transactionsDateRange: { start: '', end: '' },
                investmentTransactions: [],
                investmentTransactionsDateRange: { start: '', end: '' },
                liabilities: { credit: null, mortgage: null, student: null },
                holdings: [
                    {
                        account_id: 'a1',
                        account: null,
                        cost_basis: 168.15,
                        institution_price_as_of: '2022-12-08',
                        institution_value: 1894.65,
                        iso_currency_code: 'USD',
                        quantity: 13.443,
                        unofficial_currency_code: null,
                        security_id: 's1',
                        security: {
                            close_price: null,
                            close_price_as_of: null,
                            cusip: '037833100',
                            is_cash_equivalent: false,
                            isin: 'US0378331005',
                            iso_currency_code: 'USD',
                            name: 'Apple Inc',
                            security_id: 's1',
                            ticker_symbol: symbol,
                            type,
                            unofficial_currency_code: null,
                        },
                    },
                ],
            }
        )

        expect(data.holdings).toHaveLength(1)
        expect(data.holdings[0].security!.ticker_symbol).toBe(expected)
    })
})

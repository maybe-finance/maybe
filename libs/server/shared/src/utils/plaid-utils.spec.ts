import { Prisma, type AccountBalanceStrategy } from '@prisma/client'
import { AccountType, AccountSubtype } from 'plaid'
import { isPlaidLiability, getAccountBalanceData } from './plaid-utils'

const { Credit, Depository, Loan, Investment } = AccountType
const { CreditCard, Paypal, Student, Mortgage, _401k } = AccountSubtype

describe('Plaid utils', () => {
    it.each`
        type          | subtype       | isLiability
        ${Credit}     | ${CreditCard} | ${true}
        ${Credit}     | ${Paypal}     | ${true}
        ${Loan}       | ${Student}    | ${true}
        ${Loan}       | ${Mortgage}   | ${true}
        ${Investment} | ${_401k}      | ${false}
        ${null}       | ${null}       | ${false}
    `(
        `should identify Plaid Liability: (type: $type, subtype: $subtype)`,
        ({ type, subtype, isLiability }) => {
            expect(isPlaidLiability(type, subtype)).toBe(isLiability)
        }
    )

    it.each`
        type          | plaidCurrent | plaidAvailable | currentBalanceProvider | currentBalanceStrategy | availableBalanceProvider | availableBalanceStrategy
        ${Depository} | ${10}        | ${20}          | ${10}                  | ${`current`}           | ${20}                    | ${`available`}
        ${Investment} | ${10}        | ${10}          | ${10}                  | ${`current`}           | ${10}                    | ${`available`}
        ${Investment} | ${10}        | ${20}          | ${10}                  | ${`sum`}               | ${20}                    | ${`available`}
    `(
        `should derive account balances: (type: $type, plaidCurrent: $plaidCurrent, plaidAvailable: $plaidAvailable)`,
        ({
            type,
            plaidCurrent,
            plaidAvailable,
            currentBalanceProvider,
            currentBalanceStrategy,
            availableBalanceProvider,
            availableBalanceStrategy,
        }: {
            type: AccountType
            plaidCurrent: number
            plaidAvailable: number
            currentBalanceProvider: number
            currentBalanceStrategy: AccountBalanceStrategy
            availableBalanceProvider: number
            availableBalanceStrategy: AccountBalanceStrategy
        }) => {
            expect(
                getAccountBalanceData(
                    {
                        current: plaidCurrent,
                        available: plaidAvailable,
                        iso_currency_code: 'USD',
                        unofficial_currency_code: null,
                    },
                    type
                )
            ).toEqual({
                currentBalanceProvider: new Prisma.Decimal(currentBalanceProvider),
                currentBalanceStrategy,
                availableBalanceProvider: new Prisma.Decimal(availableBalanceProvider),
                availableBalanceStrategy,
                currencyCode: 'USD',
            })
        }
    )
})

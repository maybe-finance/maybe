import type { AccountConnection, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import { SharedUtil, AccountUtil, type SharedType } from '@maybe-finance/shared'
import type { FinicityApi, FinicityTypes } from '@maybe-finance/finicity-api'
import type { TellerApi, TellerTypes } from '@maybe-finance/teller-api'
import { DbUtil, TellerUtil, type IETL } from '@maybe-finance/server/shared'
import { Prisma } from '@prisma/client'
import _ from 'lodash'
import { DateTime } from 'luxon'

export type TellerRawData = {
    accounts: TellerTypes.Account[]
    transactions: TellerTypes.Transaction[]
    transactionsDateRange: SharedType.DateRange<DateTime>
}

export type TellerData = {
    accounts: TellerTypes.Account[]
    transactions: TellerTypes.Transaction[]
    transactionsDateRange: SharedType.DateRange<DateTime>
}

type Connection = Pick<AccountConnection, 'id' | 'userId' | 'tellerInstitutionId'>

export class TellerETL implements IETL<Connection, TellerRawData, TellerData> {
    public constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly teller: Pick<TellerApi, 'getAccounts' | 'getTransactions'>
    ) {}

    async extract(connection: Connection): Promise<TellerRawData> {
        if (!connection.tellerInstitutionId) {
            throw new Error(`connection ${connection.id} is missing tellerInstitutionId`)
        }

        const user = await this.prisma.user.findUniqueOrThrow({
            where: { id: connection.userId },
            select: {
                id: true,
                tellerUserId: true,
            },
        })

        if (!user.tellerUserId) {
            throw new Error(`user ${user.id} is missing tellerUserId`)
        }

        // TODO: Check if Teller supports date ranges for transactions
        const transactionsDateRange = {
            start: DateTime.now().minus(TellerUtil.TELLER_WINDOW_MAX),
            end: DateTime.now(),
        }

        const accounts = await this._extractAccounts(user.tellerUserId)

        const transactions = await this._extractTransactions(
            user.tellerUserId,
            accounts.map((a) => a.id),
            transactionsDateRange
        )

        this.logger.info(
            `Extracted Teller data for customer ${user.tellerUserId} accounts=${accounts.length} transactions=${transactions.length}`,
            { connection: connection.id, transactionsDateRange }
        )

        return {
            accounts,
            transactions,
            transactionsDateRange,
        }
    }

    async transform(_connection: Connection, data: TellerData): Promise<TellerData> {
        return {
            ...data,
        }
    }

    async load(connection: Connection, data: TellerData): Promise<void> {
        await this.prisma.$transaction([
            ...this._loadAccounts(connection, data),
            ...this._loadTransactions(connection, data),
        ])

        this.logger.info(`Loaded Teller data for connection ${connection.id}`, {
            connection: connection.id,
        })
    }

    private async _extractAccounts(tellerUserId: string) {
        const { accounts } = await this.teller.getAccounts({ accessToken: undefined })

        return accounts.filter(
            (a) => a.institutionLoginId.toString() === institutionLoginId && a.currency === 'USD'
        )
    }

    private _loadAccounts(connection: Connection, { accounts }: Pick<TellerData, 'accounts'>) {
        return [
            // upsert accounts
            ...accounts.map((tellerAccount) => {
                return this.prisma.account.upsert({
                    where: {
                        accountConnectionId_tellerAccountId: {
                            accountConnectionId: connection.id,
                            tellerAccountId: tellerAccount.id,
                        },
                    },
                    create: {
                        type: TellerUtil.getType(tellerAccount.type),
                        provider: 'teller',
                        categoryProvider: PlaidUtil.plaidTypesToCategory(plaidAccount.type),
                        subcategoryProvider: plaidAccount.subtype ?? 'other',
                        accountConnectionId: connection.id,
                        plaidAccountId: plaidAccount.account_id,
                        name: tellerAccount.name,
                        plaidType: tellerAccount.type,
                        plaidSubtype: tellerAccount.subtype,
                        mask: plaidAccount.mask,
                        ...PlaidUtil.getAccountBalanceData(
                            plaidAccount.balances,
                            plaidAccount.type
                        ),
                    },
                    update: {
                        type: TellerUtil.getType(tellerAccount.type),
                        categoryProvider: PlaidUtil.plaidTypesToCategory(tellerAccount.type),
                        subcategoryProvider: tellerAccount.subtype ?? 'other',
                        plaidType: tellerAccount.type,
                        plaidSubtype: tellerAccount.subtype,
                        ..._.omit(
                            PlaidUtil.getAccountBalanceData(
                                plaidAccount.balances,
                                plaidAccount.type
                            ),
                            ['currentBalanceStrategy', 'availableBalanceStrategy']
                        ),
                    },
                })
            }),
            // any accounts that are no longer in Plaid should be marked inactive
            this.prisma.account.updateMany({
                where: {
                    accountConnectionId: connection.id,
                    AND: [
                        { tellerAccountId: { not: null } },
                        { tellerAccountId: { notIn: accounts.map((a) => a.id) } },
                    ],
                },
                data: {
                    isActive: false,
                },
            }),
        ]
    }

    private async _extractTransactions(
        customerId: string,
        accountIds: string[],
        dateRange: SharedType.DateRange<DateTime>
    ) {
        const accountTransactions = await Promise.all(
            accountIds.map((accountId) =>
                SharedUtil.paginate({
                    pageSize: 1000, // https://api-reference.finicity.com/#/rest/api-endpoints/transactions/get-customer-account-transactions
                    fetchData: async (offset, count) => {
                        const transactions = await SharedUtil.withRetry(
                            () =>
                                this.teller.getTransactions({
                                    accountId,
                                    accessToken: undefined,
                                    fromDate: dateRange.start.toUnixInteger(),
                                    toDate: dateRange.end.toUnixInteger(),
                                    start: offset + 1,
                                    limit: count,
                                }),
                            {
                                maxRetries: 3,
                            }
                        )

                        return transactions
                    },
                })
            )
        )

        return accountTransactions.flat()
    }

    private _loadTransactions(
        connection: Connection,
        {
            transactions,
            transactionsDateRange,
        }: Pick<TellerData, 'transactions' | 'transactionsDateRange'>
    ) {
        if (!transactions.length) return []

        const txnUpsertQueries = _.chunk(transactions, 1_000).map((chunk) => {
            return this.prisma.$executeRaw`
                INSERT INTO transaction (account_id, teller_transaction_id, date, name, amount, pending, currency_code, merchant_name, teller_type, teller_category)
                VALUES
                    ${Prisma.join(
                        chunk.map((tellerTransaction) => {
                            const {
                                id,
                                account_id,
                                description,
                                amount,
                                status,
                                type,
                                details,
                                date,
                            } = tellerTransaction

                            return Prisma.sql`(
                                (SELECT id FROM account WHERE account_connection_id = ${
                                    connection.id
                                } AND teller_account_id = ${account_id.toString()}),
                                ${id},
                                ${date}::date,
                                ${[description].filter(Boolean).join(' ')},
                                ${DbUtil.toDecimal(-amount)},
                                ${status === 'pending'},
                                ${'USD'},
                                ${details.counterparty.name ?? ''},
                                ${type},
                                ${details.category ?? ''},
                            )`
                        })
                    )}
                ON CONFLICT (teller_transaction_id) DO UPDATE
                SET
                    name = EXCLUDED.name,
                    amount = EXCLUDED.amount,
                    pending = EXCLUDED.pending,
                    merchant_name = EXCLUDED.merchant_name,
                    teller_type = EXCLUDED.teller_type,
                    teller_category = EXCLUDED.teller_category;
            `
        })

        return [
            // upsert transactions
            ...txnUpsertQueries,
            // delete teller-specific transactions that are no longer in teller
            this.prisma.transaction.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        { tellerTransactionId: { not: null } },
                        { tellerTransactionId: { notIn: transactions.map((t) => `${t.id}`) } },
                    ],
                    date: {
                        gte: transactionsDateRange.start.startOf('day').toJSDate(),
                        lte: transactionsDateRange.end.endOf('day').toJSDate(),
                    },
                },
            }),
        ]
    }
}

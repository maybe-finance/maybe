import type { AccountConnection, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import { AccountUtil, SharedUtil, type SharedType } from '@maybe-finance/shared'
import type { TellerApi, TellerTypes } from '@maybe-finance/teller-api'
import { DbUtil, TellerUtil, type IETL, type ICryptoService } from '@maybe-finance/server/shared'
import { Prisma } from '@prisma/client'
import _ from 'lodash'
import { DateTime } from 'luxon'

export type TellerRawData = {
    accounts: TellerTypes.Account[]
    transactions: TellerTypes.Transaction[]
    transactionsDateRange: SharedType.DateRange<DateTime>
}

export type TellerData = {
    accounts: TellerTypes.AccountWithBalances[]
    transactions: TellerTypes.Transaction[]
    transactionsDateRange: SharedType.DateRange<DateTime>
}

type Connection = Pick<
    AccountConnection,
    'id' | 'userId' | 'tellerInstitutionId' | 'tellerAccessToken'
>

export class TellerETL implements IETL<Connection, TellerRawData, TellerData> {
    public constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly teller: Pick<
            TellerApi,
            'getAccounts' | 'getTransactions' | 'getAccountBalances'
        >,
        private readonly crypto: ICryptoService
    ) {}

    async extract(connection: Connection): Promise<TellerRawData> {
        if (!connection.tellerInstitutionId) {
            throw new Error(`connection ${connection.id} is missing tellerInstitutionId`)
        }
        if (!connection.tellerAccessToken) {
            throw new Error(`connection ${connection.id} is missing tellerAccessToken`)
        }

        const accessToken = this.crypto.decrypt(connection.tellerAccessToken)

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

        const accounts = await this._extractAccounts(accessToken)

        const transactions = await this._extractTransactions(
            accessToken,
            accounts.map((a) => a.id)
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

    private async _extractAccounts(accessToken: string) {
        const accounts = await this.teller.getAccounts({ accessToken })
        return accounts
    }

    private _loadAccounts(connection: Connection, { accounts }: Pick<TellerData, 'accounts'>) {
        return [
            // upsert accounts
            ...accounts.map((tellerAccount) => {
                const type = TellerUtil.getType(tellerAccount.type)
                const classification = AccountUtil.getClassification(type)

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
                        categoryProvider: TellerUtil.tellerTypesToCategory(tellerAccount.type),
                        subcategoryProvider: tellerAccount.subtype ?? 'other',
                        accountConnectionId: connection.id,
                        userId: connection.userId,
                        tellerAccountId: tellerAccount.id,
                        name: tellerAccount.name,
                        tellerType: tellerAccount.type,
                        tellerSubtype: tellerAccount.subtype,
                        mask: tellerAccount.last_four,
                        ...TellerUtil.getAccountBalanceData(tellerAccount, classification),
                    },
                    update: {
                        type: TellerUtil.getType(tellerAccount.type),
                        categoryProvider: TellerUtil.tellerTypesToCategory(tellerAccount.type),
                        subcategoryProvider: tellerAccount.subtype ?? 'other',
                        tellerType: tellerAccount.type,
                        tellerSubtype: tellerAccount.subtype,
                        ..._.omit(TellerUtil.getAccountBalanceData(tellerAccount, classification), [
                            'currentBalanceStrategy',
                            'availableBalanceStrategy',
                        ]),
                    },
                })
            }),
            // any accounts that are no longer in Teller should be marked inactive
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

    private async _extractTransactions(accessToken: string, accountIds: string[]) {
        const accountTransactions = await Promise.all(
            accountIds.map((accountId) =>
                SharedUtil.paginate({
                    pageSize: 1000, // TODO: Check with Teller on max page size
                    fetchData: async () => {
                        const transactions = await SharedUtil.withRetry(
                            () =>
                                this.teller.getTransactions({
                                    accountId,
                                    accessToken: accessToken,
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
                                id: transactionId,
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
                                ${transactionId},
                                ${date}::date,
                                ${description},
                                ${DbUtil.toDecimal(-amount)},
                                ${status === 'pending'},
                                ${'USD'},
                                ${details.counterparty.name ?? ''},
                                ${type},
                                ${details.category ?? ''}
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

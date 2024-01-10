import type { Logger } from 'winston'
import type { AccountConnection, PrismaClient, Transaction, User } from '@prisma/client'
import type { Prisma } from '@prisma/client'
import { SharedType } from '@maybe-finance/shared'
import { DateTime } from 'luxon'

type TransactionWithConnection = Transaction & {
    account: SharedType.Account & {
        accountConnection: AccountConnection | null
    }
}

export interface ITransactionService {
    get(
        id: User['id'],
        pageIndex?: number,
        pageSize?: SharedType.PageSize
    ): Promise<TransactionWithConnection>
    getAll(userId: User['id']): Promise<{ transactions: Transaction[]; pageCount: number }>
    update(
        id: Transaction['id'],
        data: Prisma.TransactionUncheckedUpdateInput
    ): Promise<Transaction>
    markTransfers(userId: User['id'], startDate?: string): Promise<void>
}

export class TransactionService implements ITransactionService {
    constructor(private readonly logger: Logger, private readonly prisma: PrismaClient) {}

    async getAll(
        userId: User['id'],
        pageIndex = 0,
        pageSize = SharedType.PageSize.Transaction
    ): Promise<SharedType.TransactionsResponse> {
        const where = {
            OR: [{ account: { userId } }, { account: { accountConnection: { userId } } }],
        }

        const [transactions, count] = await this.prisma.$transaction([
            this.prisma.transaction.findMany({
                where,
                include: { account: { include: { accountConnection: true } } },
                skip: pageIndex * pageSize,
                take: pageSize,
                orderBy: [{ date: 'desc' }, { amount: 'desc' }, { name: 'desc' }],
            }),
            this.prisma.transaction.count({ where }),
        ])

        return {
            transactions,
            pageCount: Math.ceil(count / pageSize),
        }
    }

    async get(id: Transaction['id']) {
        return await this.prisma.transaction.findUniqueOrThrow({
            where: { id },
            include: { account: { include: { accountConnection: true } } },
        })
    }

    async update(id: Transaction['id'], data: Prisma.TransactionUncheckedUpdateInput) {
        const transaction = await this.prisma.transaction.update({
            where: { id },
            data,
        })

        this.logger.info(`Updated transaction id=${id} account=${transaction.accountId}`)

        return transaction
    }

    async markTransfers(
        userId: User['id'],
        startDate = DateTime.utc().minus({ years: 2 }).toISODate()
    ) {
        this.logger.debug(`Analyzing and enhancing transactions for user=${userId}`)

        const transferPairs = await this.prisma.$queryRaw<{ id: number; match_id: number }[]>`
            WITH txn_set AS (
                SELECT 
                    t.id, 
                    t.date,
                    t.amount, 
                    t.flow,
                    a.id AS account_id, 
                    a.type AS account_type,
                    a.classification AS account_classification
                FROM transaction t
                    INNER JOIN account a ON a.id = t.account_id
                    LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
                WHERE (a.user_id = ${userId} OR ac.user_id = ${userId})
                    AND t.date >= ${startDate}::date 
                    AND t.date <= ${DateTime.utc().toISODate()}::date
            ), txn_matches as (
                SELECT DISTINCT 
                    ON (t.id)
                    t.id,
                    tc.id AS match_id
                FROM txn_set t
                LEFT JOIN txn_set tc ON tc.id <> t.id
                    AND tc.account_id <> t.account_id
                    AND ABS(tc.date - t.date) <= 1 
                    AND tc.amount = - t.amount
                    AND (
                        (t.account_classification = 'asset' AND tc.account_classification = 'asset') -- asset transfer
                        OR (t.account_classification = 'asset' AND t.flow = 'OUTFLOW' AND tc.account_classification = 'liability') -- transfer from asset to liability
                        OR (t.account_classification = 'liability' AND t.flow = 'INFLOW' AND tc.account_classification = 'asset') -- payment received from asset to liability
                    )
                WHERE tc IS NOT NULL
            )
            UPDATE transaction t
            SET match_id = tm.match_id
            FROM txn_matches tm
            WHERE t.id = tm.id
            RETURNING t.id, tm.match_id 
        `

        if (transferPairs.length) {
            this.logger.info(
                `Marked ${transferPairs.length} transactions as transfer matches for user=${userId}`,
                transferPairs
            )
        }
    }
}

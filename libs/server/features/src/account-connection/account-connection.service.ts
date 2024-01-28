import type { SharedType } from '@maybe-finance/shared'
import type { SyncConnectionOptions, SyncConnectionQueue } from '@maybe-finance/server/shared'
import type { AccountConnection, User, PrismaClient, Prisma } from '@prisma/client'
import type { Logger } from 'winston'
import type { IAccountConnectionProviderFactory } from './account-connection.provider'
import type { IBalanceSyncStrategyFactory } from '../account-balance'
import type { ISecurityPricingService } from '../security-pricing'
import { DateTime } from 'luxon'

export interface IAccountConnectionService {
    get(id: AccountConnection['id']): Promise<SharedType.ConnectionWithAccounts>
    getAll(userId: User['id']): Promise<SharedType.ConnectionWithAccounts[]>
    sync(id: AccountConnection['id'], options?: SyncConnectionOptions): Promise<AccountConnection>
    syncBalances(id: AccountConnection['id']): Promise<AccountConnection>
    syncSecurities(id: AccountConnection['id']): Promise<void>
    disconnect(id: AccountConnection['id']): Promise<AccountConnection>
    reconnect(id: AccountConnection['id']): Promise<AccountConnection>
    update(
        id: AccountConnection['id'],
        data: Prisma.AccountConnectionUncheckedUpdateInput
    ): Promise<AccountConnection>
    delete(id: AccountConnection['id']): Promise<AccountConnection>
}

export class AccountConnectionService implements IAccountConnectionService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly providers: IAccountConnectionProviderFactory,
        private readonly balanceSyncStrategyFactory: IBalanceSyncStrategyFactory,
        private readonly securityPricingService: ISecurityPricingService,
        private readonly queue: SyncConnectionQueue
    ) {}

    async get(id: AccountConnection['id']) {
        return this.prisma.accountConnection.findUniqueOrThrow({
            where: { id },
            include: { accounts: { orderBy: { id: 'asc' } } },
        })
    }

    async getAll(userId: User['id']) {
        return this.prisma.accountConnection.findMany({
            where: { userId },
            include: { accounts: { orderBy: { id: 'asc' } } },
            orderBy: { id: 'asc' },
        })
    }

    async sync(id: AccountConnection['id'], options?: SyncConnectionOptions) {
        const connection = await this.prisma.accountConnection.findUniqueOrThrow({
            where: { id },
            include: { user: true },
        })

        await this.queue.add('sync-connection', {
            accountConnectionId: connection.id,
            options,
        })

        return this.prisma.accountConnection.update({
            where: { id },
            data: { syncStatus: 'PENDING' },
        })
    }

    async syncBalances(id: AccountConnection['id']) {
        const connection = await this.get(id)

        const profiler = this.logger.startTimer()

        await Promise.all(
            connection.accounts.map((account) =>
                this.balanceSyncStrategyFactory.for(account).syncAccountBalances(account)
            )
        )

        profiler.done({ message: `synced connection ${id} balances` })

        return connection
    }

    async syncSecurities(id: AccountConnection['id']) {
        const securities = await this.prisma.security.findMany({
            where: {
                AND: [
                    {
                        OR: [
                            {
                                holdings: {
                                    some: {
                                        account: {
                                            accountConnectionId: id,
                                            isActive: true,
                                        },
                                    },
                                },
                            },
                            {
                                investmentTransactions: {
                                    some: {
                                        account: {
                                            accountConnectionId: id,
                                            isActive: true,
                                        },
                                    },
                                },
                            },
                        ],
                    },
                    {
                        OR: [
                            { pricingLastSyncedAt: null },
                            {
                                pricingLastSyncedAt: {
                                    lt: DateTime.now().minus({ days: 1 }).toJSDate(),
                                },
                            },
                        ],
                    },
                ],
            },
            select: {
                assetClass: true,
                currencyCode: true,
                id: true,
                symbol: true,
            },
        })

        const profiler = this.logger.startTimer()

        await Promise.allSettled(
            securities.map((security) => this.securityPricingService.syncSecurity(security))
        )

        profiler.done({ message: `synced connection ${id} securities (${securities.length})` })
    }

    async disconnect(id: AccountConnection['id']) {
        const [connection] = await this.prisma.$transaction([
            this.prisma.accountConnection.update({
                where: { id },
                data: {
                    status: 'DISCONNECTED',
                },
            }),
            this.prisma.account.updateMany({
                where: { accountConnectionId: id },
                data: {
                    isActive: false,
                },
            }),
        ])

        this.logger.info(
            `Disconnected connection id=${connection.id} type=${connection.type} provider_connection_id=${connection.tellerEnrollmentId}`
        )

        return connection
    }

    async reconnect(id: AccountConnection['id']) {
        const [connection] = await this.prisma.$transaction([
            this.prisma.accountConnection.update({
                where: { id },
                data: {
                    status: 'OK',
                },
            }),
            this.prisma.account.updateMany({
                where: { accountConnectionId: id },
                data: {
                    isActive: true,
                },
            }),
        ])

        this.logger.info(
            `Reconnected connection id=${connection.id} type=${connection.type} provider_connection_id=${connection.tellerEnrollmentId}`
        )

        return connection
    }

    async update(id: AccountConnection['id'], data: Prisma.AccountConnectionUncheckedUpdateInput) {
        return this.prisma.accountConnection.update({
            where: { id },
            data,
        })
    }

    async delete(id: AccountConnection['id']) {
        const connection = await this.prisma.accountConnection.findUniqueOrThrow({
            where: { id },
        })

        await this.providers.for(connection).delete(connection)

        const deletedConnection = await this.prisma.accountConnection.delete({
            where: { id: connection.id },
        })

        this.logger.info(
            `Deleted connection id=${deletedConnection.id} type=${connection.type} provider_connection_id=${connection.tellerEnrollmentId}`
        )

        return deletedConnection
    }
}

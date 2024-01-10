import type { Logger } from 'winston'
import type { PrismaClient, User } from '@prisma/client'
import type { SyncUserQueueJobData } from '@maybe-finance/server/shared'
import type { IAccountService } from '../account'
import type { IUserService } from './user.service'
import type {
    IAccountConnectionProviderFactory,
    IAccountConnectionService,
} from '../account-connection'
import { ServerUtil } from '@maybe-finance/server/shared'

export interface IUserProcessor {
    sync(jobData: SyncUserQueueJobData): Promise<void>
    delete(jobData: SyncUserQueueJobData): Promise<void>
}

export class UserProcessor implements IUserProcessor {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly userService: IUserService,
        private readonly accountService: IAccountService,
        private readonly connectionService: IAccountConnectionService,
        private readonly connectionProviders: IAccountConnectionProviderFactory
    ) {}

    async sync(jobData: SyncUserQueueJobData) {
        const user = await this.userService.get(jobData.userId)

        await ServerUtil.useSync<User>({
            sync: async (user) => {
                const { connections, accounts } = await this.accountService.getAll(user.id)

                await Promise.allSettled([
                    ...connections.map((connection) => this.connectionService.sync(connection.id)),
                    ...accounts.map((account) => this.accountService.sync(account.id)),
                ])
            },
            onSyncSuccess: (user) => this.userService.syncBalances(user.id),
            onSyncError: async (user, error) => {
                this.logger.error(`error syncing user ${user.id}`, { error })
            },
        })(user)
    }

    async delete(jobData: SyncUserQueueJobData) {
        const { userId } = jobData

        this.logger.info(`deleting user ${userId}...`)

        const connections = await this.prisma.accountConnection.findMany({
            where: { userId },
        })

        // delete connection data
        this.logger.info(`deleting user ${userId} data for ${connections.length} connections...`)
        await Promise.allSettled(connections.map((c) => this.connectionProviders.for(c).delete(c)))

        // delete from database (will cascade to relations)
        this.logger.info(`deleting user ${userId} from database...`)
        await this.prisma.user.delete({ where: { id: userId } })

        this.logger.info(`user ${userId} deleted successfully`)
    }
}

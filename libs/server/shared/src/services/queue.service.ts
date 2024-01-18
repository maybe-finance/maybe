import type { AccountConnection, User, Account } from '@prisma/client'
import type { Logger } from 'winston'
import type { Job, JobOptions } from 'bull'
import type { SharedType } from '@maybe-finance/shared'

export type IJob<T> = Pick<Job<T>, 'id' | 'name' | 'data' | 'progress'>

export type { JobOptions }

export type IQueue<TData extends Record<string, any> = {}, TJobName extends string = string> = {
    name: string
    isHealthy(): Promise<boolean>
    add(name: TJobName, data: TData, options?: JobOptions): Promise<IJob<TData>>
    addBulk(
        jobs: { name: TJobName; data: TData; options?: JobOptions | undefined }[]
    ): Promise<IJob<TData>[]>
    process(
        name: TJobName,
        callback: (job: IJob<TData>) => Promise<void>,
        options?: { concurrency: number }
    ): Promise<void>
    getActiveJobs(): Promise<IJob<TData>[]>
    cancelJobs(): Promise<void>
}

export type SyncUserOptions = {}
export type SyncUserQueueJobData = {
    userId: User['id']
    options?: SyncUserOptions
}

export type SyncAccountOptions = {}
export type SyncAccountQueueJobData = {
    accountId: Account['id']
    options?: SyncAccountOptions
}

export type SyncConnectionOptions =
    | {
          type: 'plaid'
          products?: Array<'transactions' | 'investment-transactions' | 'holdings' | 'liabilities'>
      }
    | { type: 'finicity'; initialSync?: boolean }
    | { type: 'teller'; initialSync?: boolean }

export type SyncConnectionQueueJobData = {
    accountConnectionId: AccountConnection['id']
    options?: SyncConnectionOptions
}

export type SyncSecurityQueueJobData = {}

export type SendEmailQueueJobData =
    | {
          type: 'trial-reminders'
      }
    | {
          type: 'plain'
          messages: SharedType.PlainEmailMessage | SharedType.PlainEmailMessage[]
      }
    | {
          type: 'template'
          messages: SharedType.TemplateEmailMessage | SharedType.TemplateEmailMessage[]
      }

export type SyncUserQueue = IQueue<SyncUserQueueJobData, 'sync-user'>
export type SyncAccountQueue = IQueue<SyncAccountQueueJobData, 'sync-account'>
export type SyncConnectionQueue = IQueue<SyncConnectionQueueJobData, 'sync-connection'>
export type SyncSecurityQueue = IQueue<SyncSecurityQueueJobData, 'sync-all-securities'>
export type PurgeUserQueue = IQueue<{ userId: User['id'] }, 'purge-user'>
export type SyncInstitutionQueue = IQueue<
    {},
    'sync-finicity-institutions' | 'sync-plaid-institutions' | 'sync-teller-institutions'
>
export type SendEmailQueue = IQueue<SendEmailQueueJobData, 'send-email'>

export type QueueName =
    | 'sync-user'
    | 'sync-account-connection'
    | 'sync-account'
    | 'purge-user'
    | 'sync-security'
    | 'sync-institution'
    | 'send-email'

export interface IQueueFactory {
    createQueue(name: 'sync-user'): SyncUserQueue
    createQueue(name: 'sync-account'): SyncAccountQueue
    createQueue(name: 'sync-account-connection'): SyncConnectionQueue
    createQueue(name: 'sync-security'): SyncSecurityQueue
    createQueue(name: 'purge-user'): PurgeUserQueue
    createQueue(name: 'sync-institution'): SyncInstitutionQueue
    createQueue(name: 'send-email'): SendEmailQueue
    createQueue(name: QueueName): IQueue
}

export class QueueService {
    private readonly queues: Record<string, IQueue<any>> = {}

    constructor(private readonly logger: Logger, private readonly queueFactory: IQueueFactory) {
        this.createQueue('sync-user')
        this.createQueue('sync-account')
        this.createQueue('sync-account-connection')
        this.createQueue('sync-security')
        this.createQueue('purge-user')
        this.createQueue('sync-institution')
        this.createQueue('send-email')
    }

    get allQueues() {
        return Object.values(this.queues)
    }

    getQueue(name: 'sync-user'): SyncUserQueue
    getQueue(name: 'sync-account'): SyncAccountQueue
    getQueue(name: 'sync-account-connection'): SyncConnectionQueue
    getQueue(name: 'sync-security'): SyncSecurityQueue
    getQueue(name: 'purge-user'): PurgeUserQueue
    getQueue(name: 'sync-institution'): SyncInstitutionQueue
    getQueue(name: 'send-email'): SendEmailQueue
    getQueue<TData extends Record<string, any> = any>(name: QueueName): IQueue<TData> {
        return this.queues[name] ?? this.createQueue(name)
    }

    async cancelAllJobs() {
        await Promise.allSettled(this.allQueues.map((q) => q.cancelJobs()))
    }

    private createQueue(name: QueueName) {
        return (this.queues[name] = this.queueFactory.createQueue(name))
    }
}

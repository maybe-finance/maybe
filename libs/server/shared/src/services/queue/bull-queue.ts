import Queue from 'bull'
import * as Sentry from '@sentry/node'
import type { Transaction } from '@sentry/types'
import type { Logger } from 'winston'
import type { IJob, IQueue, IQueueFactory, QueueName } from '../queue.service'

const TRACE_ID_KEY = '__SENTRY_TRACE_ID__'
const PARENT_SPAN_ID_KEY = '__SENTRY_PARENT_SPAN_ID__'

export class BullQueue<TData extends Record<string, any> = any, TJobName extends string = string>
    implements IQueue<TData, TJobName>
{
    constructor(readonly logger: Logger, readonly queue: Queue.Queue<TData>) {}

    get name() {
        return this.queue.name
    }

    async isHealthy() {
        const isReady = await this.queue.isReady()
        return isReady && this.queue.clients.every((cli) => cli.status === 'ready')
    }

    async add(name: TJobName, data: TData, options?: Queue.JobOptions | undefined) {
        const parentSpan = Sentry.getCurrentHub().getScope()?.getSpan()
        const span = parentSpan?.startChild({
            op: `queue.send`,
            description: `${this.name} send`,
            tags: {
                'messaging.system': 'bull',
                'messaging.destination': this.name,
                'messaging.destination_kind': 'queue',
                'messaging.bull.job_name': name,
            },
        })

        try {
            const job = await this.queue.add(
                name,
                {
                    ...data,
                    [TRACE_ID_KEY]: span?.traceId,
                    [PARENT_SPAN_ID_KEY]: span?.parentSpanId,
                },
                options
            )
            span?.setTag('messaging.message_id', job.id)
            return job
        } finally {
            span?.finish()
        }
    }

    async addBulk(jobs: { name: TJobName; data: TData; options?: Queue.JobOptions | undefined }[]) {
        const parentSpan = Sentry.getCurrentHub().getScope()?.getSpan()

        const spans = jobs.map((job) =>
            parentSpan?.startChild({
                op: `queue.send`,
                description: `${this.name} send`,
                tags: {
                    'messaging.system': 'bull',
                    'messaging.destination': this.name,
                    'messaging.destination_kind': 'queue',
                    'messaging.bull.job_name': job.name,
                },
            })
        )

        try {
            const added = await this.queue.addBulk(jobs)
            spans.forEach((span, idx) => span?.setTag('messaging.message_id', added[idx]?.id))
            return added
        } finally {
            spans.forEach((span) => span?.finish())
        }
    }

    async process(
        name: TJobName,
        callback: (job: Queue.Job<TData>) => Promise<void>,
        options: { concurrency?: number } = {}
    ) {
        const { concurrency = 1 } = options

        return this.queue.process(name, concurrency, async (job) => {
            let transaction: Transaction | null = null

            try {
                // https://docs.sentry.io/platforms/javascript/performance/instrumentation/custom-instrumentation/
                transaction = Sentry.startTransaction({
                    op: 'queue.process',
                    name: `${this.name} process`,
                    tags: {
                        'messaging.system': 'bull',
                        'messaging.operation': 'process',
                        'messaging.destination': this.name,
                        'messaging.destination_kind': 'queue',
                        'messaging.message_id': job.id,
                        'messaging.bull.job_name': job.name,
                    },
                    traceId: job.data?.[TRACE_ID_KEY],
                    parentSpanId: job.data?.[PARENT_SPAN_ID_KEY],
                })

                Sentry.getCurrentHub().configureScope((scope) => scope.setSpan(transaction!))
            } catch (err) {
                this.logger.error(`error starting sentry transaction`, err)
            }

            try {
                await callback(job)
            } finally {
                transaction?.finish()
            }
        })
    }

    async getActiveJobs() {
        return this.queue.getActive()
    }

    async cancelJobs() {
        await this.queue.pause(true, true)
        await this.queue.removeJobs('*')
        const activeJobs = await this.queue.getActive()
        await Promise.all(
            activeJobs.map((job) => job.moveToFailed({ message: 'Force Remove' }, true))
        )
        await this.queue.removeJobs('*')
        await this.queue.resume(true)
    }

    on(event: 'active', callback: (job: IJob<TData>) => void): void
    on(event: 'completed', callback: (job: IJob<TData>) => void): void
    on(event: 'failed', callback: (job: IJob<TData>, error: Error) => void): void
    on(event: 'error', callback: (error: Error) => void): void
    on(event: string, callback: (...args: any[]) => void) {
        return this.queue.on(event, callback)
    }
}

export interface IBullQueueEventHandler {
    onQueueCreated(queue: BullQueue): void
}

/**
 * This service uses shared Bull queue connection, to avoid connection limit issues and easily share between apps and libs
 *
 * @see https://github.com/OptimalBits/bull/blob/HEAD/PATTERNS.md#reusing-redis-connections
 */
export class BullQueueFactory implements IQueueFactory {
    constructor(
        private readonly logger: Logger,
        private readonly redisUrl: string,
        private readonly eventHandler?: IBullQueueEventHandler
    ) {}

    createQueue(name: QueueName) {
        const logger = this.logger.child({ service: `BullQueue[${name}]` })
        const queue = new BullQueue(logger, new Queue(name, this.redisUrl))
        this.eventHandler?.onQueueCreated(queue)
        return queue
    }
}

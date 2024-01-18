import type { F } from 'ts-toolbelt'
import type { IQueue, IJob, JobOptions, IQueueFactory, QueueName } from '../queue.service'

/**
 * This is a mock implementation of a queue used for testing only.
 * @see BullQueue for a production implementation.
 */
export class InMemoryQueue<
    TData extends Record<string, any> = any,
    TJobName extends string = string
> implements IQueue<TData, TJobName>
{
    private readonly processFns: Record<
        string,
        F.Parameters<IQueue<TData, TJobName>['process']>[1]
    > = {}

    constructor(readonly name: string, private readonly ignoreJobNames: string[] = []) {}

    async isHealthy() {
        return true
    }

    async add(name: TJobName, data: TData, _options?: JobOptions | undefined) {
        const job: IJob<TData> = {
            id: `${name}.${new Date().getTime()}.${Math.random()}`,
            name,
            data,
            progress: () => Promise.resolve(),
        }

        if (!this.ignoreJobNames.includes(name)) {
            try {
                // immediately run job
                await this.processFns[name](job)
            } catch (err) {
                // ignore
            }
        }

        return job
    }

    async addBulk(jobs: { name: TJobName; data: TData; options?: JobOptions | undefined }[]) {
        return Promise.all(jobs.map((job) => this.add(job.name, job.data)))
    }

    async process(name: TJobName, fn: (job: IJob<TData>) => Promise<void>) {
        this.processFns[name] = fn
    }

    async getActiveJobs() {
        return []
    }

    async cancelJobs() {
        // no-op
    }
}

export class InMemoryQueueFactory implements IQueueFactory {
    constructor(
        private readonly ignoreJobNames: string[] = [
            'sync-all-securities',
            'sync-plaid-institutions',
            'trial-reminders',
            'send-email',
        ]
    ) {}

    createQueue(name: QueueName) {
        return new InMemoryQueue(name, this.ignoreJobNames)
    }
}

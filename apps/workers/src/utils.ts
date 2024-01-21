import type { IQueue } from '@maybe-finance/server/shared'
import type { JobInformation } from 'bull'

export async function cleanUpOutdatedJobs(queues: IQueue[]) {
    for (const queue of queues) {
        const repeatedJobs = await queue.getRepeatableJobs()

        const outdatedJobs = filterOutdatedJobs(repeatedJobs)
        for (const job of outdatedJobs) {
            await queue.removeRepeatableByKey(job.key)
        }
    }
}

function filterOutdatedJobs(jobs: JobInformation[]) {
    const jobGroups = new Map()

    jobs.forEach((job) => {
        if (!jobGroups.has(job.name)) {
            jobGroups.set(job.name, [])
        }
        jobGroups.get(job.name).push(job)
    })

    const mostRecentJobs = new Map()
    jobGroups.forEach((group, name) => {
        const mostRecentJob = group.reduce((mostRecent, current) => {
            if (current.id === null) return mostRecent
            const currentIdTime = current.id
            const mostRecentIdTime = mostRecent ? mostRecent.id : 0

            return currentIdTime > mostRecentIdTime ? current : mostRecent
        }, null)

        if (mostRecentJob) {
            mostRecentJobs.set(name, mostRecentJob.id)
        }
    })

    return jobs.filter((job: JobInformation) => {
        const mostRecentId = mostRecentJobs.get(job.name)
        return job.id === null || job.id !== mostRecentId
    })
}

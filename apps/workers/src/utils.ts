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

export async function stopJobsWithName(queue, jobName) {
    // Get all jobs that might be in a state that allows them to be stopped
    const jobs = await queue.getJobs(['active', 'waiting', 'delayed', 'paused'])

    // Filter jobs by name
    const jobsToStop = jobs.filter((job) => job.name === jobName)

    // Process each job to stop it
    for (const job of jobsToStop) {
        if (job.isActive()) {
            job.moveToFailed(new Error('Job stopped'), true)
            // For active jobs, you might need to implement a soft stop mechanism
            // This could involve setting a flag in your job processing logic to stop the job safely
        } else {
            // For non-active jobs, you can directly remove or fail them
            await job.remove() // or job.discard() or job.moveToFailed(new Error('Job stopped'), true)
        }
    }
}

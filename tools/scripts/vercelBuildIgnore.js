const https = require('https')

const VERCEL_GIT_COMMIT_REF = process.env.VERCEL_GIT_COMMIT_REF
const CI_PROJECT_NAME = process.env.CI_PROJECT_NAME
const CI_TEAM_ID = process.env.CI_TEAM_ID
const CI_PROJECT_ID = process.env.CI_PROJECT_ID
const CI_DEPLOY_HOOK_ID = process.env.CI_DEPLOY_HOOK_ID
const CI_VERCEL_TOKEN = process.env.CI_VERCEL_TOKEN

console.log(`VERCEL_GIT_COMMIT_REF: ${VERCEL_GIT_COMMIT_REF}`)
console.log(`CI_PROJECT_NAME: ${CI_PROJECT_NAME}`)

/**
 * Vercel currently has no easy way to determine whether a deploy was triggered
 * from a deploy hook, and therefore, all manual builds would be cancelled without this logic here.
 * @see https://github.com/vercel/community/discussions/285#discussioncomment-1696833
 *
 * We skip automatic deploys to main because our AWS resources (server, workers)
 * take longer to deploy.  Instead, we programmatically deploy after these AWS
 * services have successfully deployed to minimize any mismatches in app versions.
 *
 * We deploy the staging-client project on merge to main to avoid conflicting deploys
 * with our main app's PR preview deploys.
 */
if (process.env.VERCEL_GIT_COMMIT_REF === 'main') {
    if (CI_PROJECT_NAME === 'staging-client') {
        console.log('✅ - Build can proceed, staging-client auto-deploys on merge to main')
        process.exit(1)
    }

    let data = ''
    const req = https.request(
        {
            hostname: 'api.vercel.com',
            path: `/v6/deployments?limit=1&projectId=${CI_PROJECT_ID}&teamId=${CI_TEAM_ID}&state=BUILDING&target=production`,
            headers: {
                Authorization: `Bearer ${CI_VERCEL_TOKEN}`,
            },
        },
        (res) => {
            res.on('data', (d) => (data += d.toString()))
            res.on('end', (d) => {
                const parsed = JSON.parse(data)

                try {
                    const deployment = parsed.deployments[0]
                    const hookId = deployment.meta.deployHookId

                    if (hookId === CI_DEPLOY_HOOK_ID) {
                        console.log('✅ - Build can proceed, using deploy hook')
                        process.exit(1)
                    } else {
                        throw new Error('Could not find deployment triggered from deploy hook')
                    }
                } catch (e) {
                    console.error(e)
                    console.log('🛑 - Build skipped, error finding deployments')
                    process.exit(0)
                }
            })
        }
    )

    req.on('error', console.error)
    req.end()
} else {
    if (CI_PROJECT_NAME === 'staging-client') {
        console.log('🛑 - Build skipped, staging-client does not deploy PR previews')
        process.exit(0)
    }

    // Allow PR previews to deploy
    console.log('✅ - Build can proceed')
    process.exit(1)
}

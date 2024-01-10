import type { Express } from 'express'
import ldClient from '../lib/ldClient'

type MaintenanceOptions = {
    statusCode?: number
    path?: string
    featureKey?: string
}

export default function maintenance(
    app: Express,
    { statusCode = 503, path = '/maintenance', featureKey = 'maintenance' }: MaintenanceOptions = {}
) {
    let enabled = false

    function loadFeatureFlag() {
        ldClient
            .waitForInitialization()
            .then((ld) => {
                ld.variation(featureKey, { key: 'anonymous-server', anonymous: true }, false).then(
                    (flag) => (enabled = flag)
                )
            })
            .catch((err) => {
                console.error(`error loading feature flag`, err)
            })
    }

    loadFeatureFlag()

    ldClient.on(`update:${featureKey}`, () => {
        loadFeatureFlag()
    })

    app.get(path, async (req, res) => {
        res.status(200).json({ enabled })
    })

    app.use(async (req, res, next) => {
        if (enabled) {
            return res.status(statusCode).json({ message: 'Maintenance in progress' })
        }

        next()
    })
}

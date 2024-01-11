import type { Express } from 'express'

type MaintenanceOptions = {
    statusCode?: number
    path?: string
    featureKey?: string
}

export default function maintenance(
    app: Express,
    { statusCode = 503, path = '/maintenance' }: MaintenanceOptions = {}
) {
    const enabled = false

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

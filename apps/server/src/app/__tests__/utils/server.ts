import type { Server } from 'http'
import app from '../../app'

let server: Server

export const startServer = () => {
    return new Promise((resolve, _reject) => {
        server = app.listen(53333, () => {
            resolve(true)
        })
    })
}

export const stopServer = () => {
    return new Promise((resolve, _reject) => {
        server.close(() => {
            resolve(true)
        })
    })
}

import { createLogger } from '@maybe-finance/server/shared'
import ldClient from './ldClient'

const logger = createLogger({
    level: 'info',
})

function setLevel() {
    ldClient
        .variation('server-log-level', { key: 'anonymous-server', anonymous: true }, 'info')
        .then((level) => {
            logger.level = level
            logger[level](`Server logger using level: ${level}`)
        })
}

// Don't configure for Jest
if (process.env.NODE_ENV !== 'test') {
    ldClient.waitForInitialization().then(setLevel)
    ldClient.on('update:server-log-level', setLevel)
}

export default logger

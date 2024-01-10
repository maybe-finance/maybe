import { createLogger } from '@maybe-finance/server/shared'
import ldClient from './ldClient'

const logger = createLogger({
    level: 'info',
})

function setLevel() {
    ldClient
        .variation('workers-log-level', { key: 'anonymous-server', anonymous: true }, 'info')
        .then((level) => {
            logger.level = level
            logger[level](`Workers logger using level: ${level}`)
        })
}

// Don't configure for Jest
if (process.env.NODE_ENV !== 'test') {
    ldClient.waitForInitialization().then(setLevel)
    ldClient.on('update:workers-log-level', setLevel)
}

export default logger

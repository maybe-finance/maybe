import { createLogger } from '@maybe-finance/server/shared'

const logger = createLogger({
    level: process.env.LOG_LEVEL ?? 'info',
})

export default logger

import { createLogger } from '@maybe-finance/server/shared'

const logger = createLogger({
    level: process.env.DEBUG ?? 'info',
})

export default logger

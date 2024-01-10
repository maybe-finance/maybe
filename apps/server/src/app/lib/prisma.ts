import { PrismaClient } from '@prisma/client'
import { DbUtil } from '@maybe-finance/server/shared'
import globalLogger from './logger'

const logger = globalLogger.child({ service: 'PrismaClient' })

// https://stackoverflow.com/a/68328402
declare global {
    var prisma: PrismaClient // eslint-disable-line
}

function createPrismaClient() {
    const prisma = new PrismaClient({
        log: [
            { emit: 'event', level: 'query' },
            { emit: 'event', level: 'info' },
            { emit: 'event', level: 'warn' },
            { emit: 'event', level: 'error' },
        ],
    })

    prisma.$on('query', ({ query, params, duration, ...data }) => {
        logger.silly(`Query: ${query}, Params: ${params}, Duration: ${duration}`, { ...data })
    })

    prisma.$on('info', ({ message, ...data }) => {
        logger.info(message, { ...data })
    })

    prisma.$on('warn', ({ message, ...data }) => {
        logger.warn(message, { ...data })
    })

    prisma.$on('error', ({ message, ...data }) => {
        logger.error(message, { ...data })
    })

    prisma.$use(DbUtil.slowQueryMiddleware(logger))

    return prisma
}

// Prevent multiple instances of Prisma Client in development
// https://www.prisma.io/docs/guides/performance-and-optimization/connection-management#prevent-hot-reloading-from-creating-new-instances-of-prismaclient
// https://www.prisma.io/docs/concepts/components/prisma-client/working-with-prismaclient/instantiate-prisma-client#the-number-of-prismaclient-instances-matters
const prisma = global.prisma || createPrismaClient()

if (process.env.NODE_ENV === 'development') global.prisma = prisma

export default prisma

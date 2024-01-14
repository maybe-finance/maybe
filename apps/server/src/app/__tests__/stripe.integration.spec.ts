import type { User } from '@prisma/client'
import { PrismaClient } from '@prisma/client'
import { createLogger, transports } from 'winston'
import { AccountQueryService, UserService } from '@maybe-finance/server/features'
import { resetUser } from './utils/user'
import stripe from '../lib/stripe'
import { PgService } from '@maybe-finance/server/shared'
import { DateTime } from 'luxon'

const prisma = new PrismaClient()
const logger = createLogger({ transports: new transports.Console() })

const userService = new UserService(
    logger,
    prisma,
    new AccountQueryService(logger, new PgService(logger)),
    {} as any,
    {} as any,
    {} as any,
    stripe
)

let user: User

beforeEach(async () => {
    user = await resetUser()
})

afterAll(async () => {
    await prisma.$disconnect()
})

describe('stripe subscriptions', () => {
    it("derives a new user's subscription status", async () => {
        const subscription = await userService.getSubscription(user.id)
        const { trialEnd, ...rest } = subscription

        // Default 14-day trial
        expect(Math.round(trialEnd?.diffNow('days').days ?? 0)).toEqual(14)

        expect(rest).toEqual({
            subscribed: true,
            trialing: true,
            canceled: false,

            currentPeriodEnd: null,
            cancelAt: null,
        })
    })

    it("derives a lapsed trial user's subscription status", async () => {
        const trialEnd = DateTime.now().minus({ days: 1 })

        await prisma.user.update({
            where: { id: user.id },
            data: {
                trialEnd: trialEnd.toJSDate(),
            },
        })

        expect(await userService.getSubscription(user.id)).toEqual({
            subscribed: false,
            trialing: false,
            canceled: false,

            currentPeriodEnd: null,
            trialEnd: trialEnd,
            cancelAt: null,
        })
    })

    it("derives a paying user's subscription status", async () => {
        const currentPeriodEnd = DateTime.now().plus({ days: 30 })

        await prisma.user.update({
            where: { id: user.id },
            data: {
                stripeCancelAt: null,
                stripeCurrentPeriodEnd: currentPeriodEnd.toJSDate(),
                stripePriceId: 'price_test',
                stripeSubscriptionId: 'sub_test',
                trialEnd: null,
            },
        })

        expect(await userService.getSubscription(user.id)).toEqual({
            subscribed: true,
            trialing: false,
            canceled: false,

            currentPeriodEnd: currentPeriodEnd,
            trialEnd: null,
            cancelAt: null,
        })
    })
})

import type { OnboardingState } from '@maybe-finance/server/features'
import { Router } from 'express'
import { DateTime } from 'luxon'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

const testUserId = 'test_ec3ee8a4-fa01-4f11-8ac5-9c49dd7fbae4'

router.use((req, res, next) => {
    if (req.user?.sub === testUserId) {
        next()
    } else {
        res.status(401).send('Route only available to test users')
    }
})

// Validation endpoint for Cypress
router.get(
    '/',
    endpoint.create({
        resolve: async () => {
            return { success: true }
        },
    })
)

router.post(
    '/plaid/connect',
    endpoint.create({
        input: z.object({
            username: z.enum(['custom_ci_pos_nw']).default('custom_ci_pos_nw'),
        }),
        resolve: async ({ ctx, input: { username } }) => {
            return ctx.plaidService.createSandboxAccount(ctx.user!.id, username)
        },
    })
)

router.post(
    '/reset',
    endpoint.create({
        input: z.object({
            mainOnboardingDisabled: z.boolean().default(true),
            sidebarOnboardingDisabled: z.boolean().default(true),
            trialLapsed: z.boolean().default(false),
        }),
        resolve: async ({ ctx, input }) => {
            await ctx.prisma.$transaction([
                ctx.prisma.$executeRaw`DELETE FROM "user" WHERE auth_id=${testUserId};`,
                ctx.prisma.user.create({
                    data: {
                        authId: testUserId,
                        email: 'bond@007.com',
                        firstName: 'James',
                        lastName: 'Bond',
                        dob: new Date('1990-01-01'),
                        linkAccountDismissedAt: new Date(), // ensures our auto-account link doesn't trigger

                        // Override onboarding flows to be complete for e2e testing
                        onboarding: {
                            main: { markedComplete: input.mainOnboardingDisabled, steps: [] },
                            sidebar: { markedComplete: input.sidebarOnboardingDisabled, steps: [] },
                        } as OnboardingState,

                        trialEnd: input.trialLapsed
                            ? DateTime.now().minus({ days: 1 }).toJSDate()
                            : undefined,
                    },
                }),
            ])

            return { success: true }
        },
    })
)

export default router

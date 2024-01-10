import type { OnboardingState } from '@maybe-finance/server/features'
import { Router } from 'express'
import { DateTime } from 'luxon'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

router.use((req, res, next) => {
    const roles = req.user?.['https://maybe.co/roles']

    if (roles?.includes('CIUser') || roles?.includes('Admin')) {
        next()
    } else {
        res.status(401).send('Route only available to CIUser and Admin roles')
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
            ctx.logger.debug(`Resetting CI user ${ctx.user!.auth0Id}`)

            await ctx.prisma.$transaction([
                ctx.prisma.$executeRaw`DELETE FROM "user" WHERE auth0_id=${ctx.user!.auth0Id};`,
                ctx.prisma.user.create({
                    data: {
                        auth0Id: ctx.user!.auth0Id,
                        email: 'REPLACE_THIS',
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

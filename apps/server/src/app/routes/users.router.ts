import { Router } from 'express'
import axios from 'axios'
import type { UnlinkAccountsParamsProvider } from 'auth0'
import { keyBy, mapValues, uniqBy } from 'lodash'
import { subject } from '@casl/ability'
import { z } from 'zod'
import { DateUtil, type SharedType } from '@maybe-finance/shared'
import endpoint from '../lib/endpoint'
import env from '../../env'
import crypto from 'crypto'
import { DateTime } from 'luxon'
import {
    type OnboardingState,
    type RegisteredStep,
    UpdateOnboardingSchema,
} from '@maybe-finance/server/features'

const router = Router()

router.get(
    '/',
    endpoint.create({
        resolve: async ({ ctx }) => {
            return ctx.userService.get(ctx.user!.id)
        },
    })
)

router.get(
    '/onboarding/:flow',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            let onboarding: SharedType.OnboardingResponse

            switch (req.params.flow) {
                case 'main':
                    onboarding = await ctx.userService.buildMainOnboarding(ctx.user!.id)
                    break
                case 'sidebar':
                    onboarding = await ctx.userService.buildSidebarOnboarding(ctx.user!.id)
                    break
                default:
                    throw new Error(`${req.params.flow} is not a valid onboarding flow key`)
            }

            const { steps, currentStep, progress, isComplete, isMarkedComplete } = onboarding

            return {
                steps,
                currentStep,
                progress,
                isComplete,
                isMarkedComplete,
            }
        },
    })
)

router.put(
    '/onboarding',
    endpoint.create({
        input: UpdateOnboardingSchema,
        resolve: async ({ ctx, input }) => {
            const user = await ctx.prisma.user.findFirstOrThrow({
                where: { id: ctx.user!.id },
                select: { id: true, onboarding: true },
            })

            const onboardingState = user.onboarding as OnboardingState | null

            // Initialize onboarding state
            const onboarding = onboardingState
                ? onboardingState
                : ({
                      main: { markedComplete: false, steps: [] },
                      sidebar: { markedComplete: false, steps: [] },
                  } as OnboardingState)

            input.updates.forEach((update: RegisteredStep) => {
                const oldStepIdx = onboarding[input.flow].steps.findIndex(
                    (step) => step.key === update.key
                )

                // Create or update
                if (oldStepIdx < 0) {
                    onboarding[input.flow].steps.push(update)
                } else {
                    onboarding[input.flow].steps[oldStepIdx] = update
                }
            })

            if (input.flow === 'sidebar' && input.markedComplete != null) {
                onboarding['sidebar'].markedComplete = input.markedComplete
            }

            ctx.logger.info(
                `User onboarding updated. flow=${input.flow} updated=${input.updates.length} user=${
                    ctx.user!.id
                }`,
                input
            )

            return ctx.prisma.user.update({
                where: { id: ctx.user!.id },
                data: { onboarding },
            })
        },
    })
)

router.get(
    '/auth0-profile',
    endpoint.create({
        resolve: async ({ ctx }) => {
            return ctx.userService.getAuth0Profile(ctx.user!)
        },
    })
)

router.put(
    '/auth0-profile',
    endpoint.create({
        input: z.object({
            enrolled_mfa: z.boolean(),
        }),
        resolve: ({ input, ctx }) => {
            return ctx.managementClient.updateUser(
                { id: ctx.user!.auth0Id },
                { user_metadata: { enrolled_mfa: input.enrolled_mfa } }
            )
        },
    })
)

router.get(
    '/subscription',
    endpoint.create({
        resolve: async ({ ctx }) => {
            if (!ctx.user || !ctx.user.id) {
                throw new Error('User not found')
            }

            return ctx.userService.getSubscription(ctx.user.id)
        },
    })
)

router.put(
    '/',
    endpoint.create({
        input: z
            .object({
                monthlyDebtUser: z.number().nullable(),
                monthlyIncomeUser: z.number().nullable(),
                monthlyExpensesUser: z.number().nullable(),
                goals: z.string().array(),
                riskAnswers: z
                    .object({ questionKey: z.string(), choiceKey: z.string() })
                    .array()
                    .min(1),
                userNotes: z.string(),
                household: z.enum([
                    'single',
                    'singleWithDependents',
                    'dual',
                    'dualWithDependents',
                    'retired',
                ]),
                country: z.string().nullable(),
                state: z.string().nullable(),
                maybeGoals: z.enum(['aggregate', 'advice', 'plan']).array(),
                maybeGoalsDescription: z.string().nullable(),
                maybe: z.string().nullable(),
                title: z.string().nullable(),
                firstName: z.string(),
                lastName: z.string(),
                dob: z.string().transform((d) => DateUtil.datetimeTransform(d).toJSDate()),
                linkAccountDismissedAt: z.date(),
            })
            .partial(),
        resolve: ({ input, ctx }) => {
            if (!ctx.user || !ctx.user.id) {
                throw new Error('Could not update user.  User not found')
            }

            return ctx.userService.update(ctx.user.id, input)
        },
    })
)

router.get(
    '/net-worth',
    endpoint.create({
        input: z
            .object({
                start: z.string().transform(DateUtil.dateTransform),
                end: z.string().transform(DateUtil.dateTransform),
            })
            .partial(),
        resolve: ({ ctx, input: { start, end } }) => {
            return ctx.userService.getNetWorthSeries(ctx.user!.id, start, end)
        },
    })
)

router.get(
    '/:id/net-worth',
    endpoint.create({
        input: z
            .object({
                start: z.string().transform(DateUtil.dateTransform),
                end: z.string().transform(DateUtil.dateTransform),
            })
            .partial(),
        resolve: async ({ ctx, req, input: { start, end } }) => {
            const user = await ctx.userService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('User', user))
            return ctx.userService.getNetWorthSeries(user.id, start, end)
        },
    })
)

router.get(
    '/net-worth/:date',
    endpoint.create({
        resolve: ({ ctx, req }) => {
            return ctx.userService.getNetWorth(
                ctx.user!.id,
                DateUtil.dateTransform(req.params.date)
            )
        },
    })
)

router.get(
    '/:id/net-worth/:date',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const user = await ctx.userService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('User', user))
            return ctx.userService.getNetWorth(user.id, DateUtil.dateTransform(req.params.date))
        },
    })
)

router.get(
    '/:id/account-rollup',
    endpoint.create({
        input: z
            .object({
                start: z.string().transform(DateUtil.dateTransform),
                end: z.string().transform(DateUtil.dateTransform),
            })
            .partial(),
        resolve: async ({ ctx, input: { start, end }, req }) => {
            const user = await ctx.userService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('User', user))
            return ctx.accountService.getAccountRollup(user.id, start, end)
        },
    })
)

router.get(
    '/insights',
    endpoint.create({
        resolve: ({ ctx }) => {
            return ctx.insightService.getUserInsights({ userId: ctx.user!.id })
        },
    })
)

router.get(
    '/:id/insights',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const user = await ctx.userService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('User', user))
            return ctx.insightService.getUserInsights({ userId: user.id })
        },
    })
)

router.post(
    '/link-accounts',
    endpoint.create({
        input: z.object({
            secondaryJWT: z.string(),
            secondaryProvider: z.string(),
        }),
        resolve: async ({ input, ctx }) => {
            return ctx.userService.linkAccounts(ctx.user!.auth0Id, input.secondaryProvider, {
                token: input.secondaryJWT,
                domain: env.NX_AUTH0_CUSTOM_DOMAIN,
                audience: env.NX_AUTH0_AUDIENCE,
            })
        },
    })
)

router.post(
    '/unlink-account',
    endpoint.create({
        input: z.object({
            secondaryAuth0Id: z.string(),
            secondaryProvider: z.string(),
        }),
        resolve: async ({ input, ctx }) => {
            return ctx.userService.unlinkAccounts(
                ctx.user!.auth0Id,
                input.secondaryAuth0Id,
                input.secondaryProvider as UnlinkAccountsParamsProvider
            )
        },
    })
)

router.post(
    '/resend-verification-email',
    endpoint.create({
        input: z.object({
            auth0Id: z.string().optional(),
        }),
        resolve: async ({ input, ctx }) => {
            const auth0Id = input.auth0Id ?? ctx.user?.auth0Id
            if (!auth0Id) throw new Error('User not found')

            await ctx.managementClient.sendEmailVerification({ user_id: auth0Id })

            ctx.logger.info(`Sent verification email to ${auth0Id}`)

            return { success: true }
        },
    })
)

router.put(
    '/change-password',
    endpoint.create({
        input: z.object({
            newPassword: z.string(),
            currentPassword: z.string(),
        }),
        resolve: async ({ input, ctx, req }) => {
            if (!req.user || !req.user.sub) {
                throw new Error('Unable to update password.  No user found.')
            }

            const user = await ctx.managementClient.getUser({ id: req.user.sub })

            const { newPassword, currentPassword } = input

            /**
             * Auth0 doesn't have a verify password endpoint on the Management API, so this is a secure way to
             * verify that the old password was valid before changing it.  Why they don't have this feature still? ¯\_(ツ)_/¯
             *
             * @see https://community.auth0.com/t/change-password-validation/8158/10
             */
            try {
                // If this succeeds, we know the old password was correct
                await axios.post(
                    `https://${env.NX_AUTH0_DOMAIN}/oauth/token`,
                    {
                        grant_type: 'password',
                        username: user.email,
                        password: currentPassword,
                        audience: env.NX_AUTH0_AUDIENCE,
                        client_id: env.NX_AUTH0_CLIENT_ID,
                        client_secret: env.NX_AUTH0_CLIENT_SECRET,
                    },
                    { headers: { 'content-type': 'application/json' } }
                )
            } catch (err) {
                let errMessage = 'Could not reset password'

                if (axios.isAxiosError(err)) {
                    errMessage =
                        err.response?.status === 401
                            ? 'Invalid password, please try again'
                            : errMessage
                }

                // Do not log the full error here, the user's password could be in it!
                ctx.logger.error('Could not reset password')

                return { success: false, error: errMessage }
            }

            // https://auth0.com/docs/connections/database/password-change#use-the-management-api
            await ctx.managementClient.updateUser(
                { id: req.user?.sub },
                { password: newPassword, connection: 'Username-Password-Authentication' }
            )

            return { success: true }
        },
    })
)

router.post(
    '/checkout-session',
    endpoint.create({
        input: z.object({
            plan: z.string(),
        }),
        resolve: async ({ ctx, req, input }) => {
            if (!req.user?.sub || !ctx.user) {
                throw new Error('Unable to create checkout session. No user found.')
            }

            const session = await ctx.stripe.checkout.sessions.create({
                line_items: [
                    {
                        price:
                            input.plan === 'yearly'
                                ? env.NX_STRIPE_PREMIUM_YEARLY_PRICE_ID
                                : env.NX_STRIPE_PREMIUM_MONTHLY_PRICE_ID,
                        quantity: 1,
                    },
                ],
                mode: 'subscription',
                success_url: `${req.headers.origin}/settings?tab=billing&status=success`,
                cancel_url: `${req.headers.origin}/settings?tab=billing&status=cancelled`,
                allow_promotion_codes: true,

                client_reference_id: req.user.sub,

                // Provide customer ID or user email, not both
                ...(ctx.user.stripeCustomerId
                    ? {
                          customer: ctx.user.stripeCustomerId,
                      }
                    : {
                          customer_email: (
                              await ctx.managementClient.getUser({ id: req.user.sub })
                          ).email,
                      }),
            })

            if (!session.url) throw new Error('Failed to create checkout session with URL.')

            return { url: session.url }
        },
    })
)

router.post(
    '/customer-portal-session',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            if (!req.user?.sub || !ctx.user || !ctx.user.stripeCustomerId) {
                throw new Error('Unable to create customer portal session. No user/customer found.')
            }

            const session = await ctx.stripe.billingPortal.sessions.create({
                customer: ctx.user.stripeCustomerId,
                return_url: `${req.headers.origin}/settings?tab=billing`,
            })

            if (!session.url) throw new Error('Failed to create customer portal session with URL.')

            return { url: session.url }
        },
    })
)

/**
 * Fetches the latest public version of each agreement
 */
router.get(
    '/agreements/newest',
    endpoint.create({
        input: z.object({ type: z.enum(['public', 'user']) }),
        resolve: async ({ ctx, input }) => {
            const agreements = await (input.type === 'user'
                ? ctx.userService.getSignedAgreements(ctx.user!.id)
                : ctx.userService.getNewestAgreements())

            return agreements.map((agreement) => ({
                ...agreement,
                url: `${env.NX_CDN_URL}/${agreement.src}`,
            }))
        },
    })
)

router.post(
    '/agreements/sign',
    endpoint.create({
        input: z.object({ agreementIds: z.number().array().length(5) }),
        resolve: async ({ ctx, input }) => {
            return ctx.userService.signAgreements(ctx.user!.id, input.agreementIds, ctx.s3)
        },
    })
)

/**
 * Idempotent, admin-only route that should be run each time we update a legal agreement
 *
 * - Sends email notifications to users when agreements are updated
 * - Records acknowledgement in S3
 * - Bumps all successful users to latest agreement set in DB
 */
router.post(
    '/agreements/notify-email',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'User')

            const outdatedAgreements = await ctx.prisma.$queryRaw<
                {
                    email: string
                    first_name: string
                    user_id: number
                    current_agreement_id: number
                    newest_agreement_id: number
                }[]
            >`
                WITH signed_agreements AS (
                    SELECT DISTINCT ON (sa.user_id, a.type)
                        u.email,
                        u.first_name,
                        sa.user_id,
                        sa.agreement_id AS current_agreement_id,
                        na.id AS newest_agreement_id
                    FROM signed_agreement sa
                        LEFT JOIN "user" u ON u.id = sa.user_id
                        LEFT JOIN agreement a ON a.id = sa.agreement_id
                        LEFT JOIN LATERAL (
                            SELECT DISTINCT ON (a.type)
                                a.id, a.type
                            FROM agreement a
                            WHERE a.active
                            ORDER BY a.type, a.revision DESC
                        ) na ON na.type = a.type
                    ORDER BY sa.user_id, a.type, a.revision DESC
                )
                SELECT *
                FROM signed_agreements
                WHERE current_agreement_id <> newest_agreement_id;
            `

            if (!outdatedAgreements.length) {
                ctx.logger.info('All users have signed latest agreements, skipping email')
                return {
                    updatedAgreementCount: 0,
                }
            }

            ctx.logger.info(`Updating ${outdatedAgreements.length} outdated agreements`)

            const newestAgreements = (await ctx.userService.getNewestAgreements()).map((a) => ({
                ...a,
                url: `${env.NX_CDN_URL}/${a.src}`,
            }))

            // Only send 1 email per user that will cover all 4 agreements
            const uniqueAgreements = uniqBy(outdatedAgreements, 'user_id')

            // Send users a templated update email notifying them of document change
            const batchResponse = await ctx.emailService.sendTemplate(
                uniqueAgreements.map((agreement) => ({
                    to: agreement.email,
                    template: {
                        alias: 'agreements-update',
                        model: {
                            name: agreement.first_name ?? '',
                            urls: mapValues(keyBy(newestAgreements, 'type'), (a) => a.url),
                        },
                    },
                }))
            )

            // Save audit records of email sends
            ctx.logger.info(`Agreement update emails sent`, batchResponse)

            const Body = Buffer.from(JSON.stringify(batchResponse))
            const Key = `private/agreements/email-receipts/${DateTime.now().toISO()}-agreements-update-email-receipt.txt`
            await ctx.s3.upload({
                bucketKey: 'private',
                Key,
                Body,
                ContentMD5: crypto.createHash('md5').update(Body).digest('base64'),
            })

            ctx.logger.info(`Agreement email receipt uploaded to S3 key=${Key}`)

            // Find all successful emails and create new agreement signatures for each
            const successfulUpdateEmails = batchResponse
                .filter((result) => result.ErrorCode === 0 && result.To)
                .map((v) => v.To!)

            const agreementsToAcknowledge = outdatedAgreements.filter(
                (oa) => successfulUpdateEmails.find((email) => email === oa.email) != null
            )

            // Our signature record pointer in DB
            await ctx.prisma.signedAgreement.createMany({
                data: agreementsToAcknowledge.map((oa) => ({
                    userId: oa.user_id,
                    agreementId: oa.newest_agreement_id,
                    src: Key,
                })),
            })

            return {
                updatedAgreementCount: successfulUpdateEmails.length,
            }
        },
    })
)

router.delete(
    '/',
    endpoint.create({
        input: z.object({
            confirm: z.literal(true),
        }),
        resolve: async ({ ctx }) => {
            const { id } = ctx.user!
            ctx.ability.throwUnlessCan('delete', subject('User', ctx.user!))
            await ctx.userService.delete(id)
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        input: z.object({
            confirm: z.literal(true),
        }),
        resolve: async ({ ctx, req }) => {
            const user = await ctx.userService.get(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('User', user))
            await ctx.userService.delete(user.id)
        },
    })
)

router.get(
    '/card',
    endpoint.create({
        resolve: async ({ ctx }) => {
            return ctx.userService.getMemberCard(
                ctx.user!.memberId,
                env.NX_CLIENT_URL_CUSTOM || env.NX_CLIENT_URL
            )
        },
    })
)

export default router

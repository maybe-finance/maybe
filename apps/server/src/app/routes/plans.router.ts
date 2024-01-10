import { Router } from 'express'
import { subject } from '@casl/ability'
import {
    PlanCreateSchema,
    PlanTemplateSchema,
    PlanUpdateSchema,
} from '@maybe-finance/server/features'
import endpoint from '../lib/endpoint'
import { DateUtil, PlanUtil } from '@maybe-finance/shared'

const router = Router()

router.get(
    '/',
    endpoint.create({
        resolve: async ({ ctx }) => {
            const { plans } = await ctx.planService.getAll(ctx.user!.id)

            if (plans.length > 0) return { plans }

            /**
             * Generate a default plan so the user can start using the plan feature
             * without requiring any data inputs up-front.
             *
             * Defaults to "Retirement" template
             */
            const plan = await ctx.planService.createWithTemplate(ctx.user!, {
                type: 'retirement',
                data: {
                    // Defaults to user age of 30 and retirement age of 65
                    retirementYear: DateUtil.ageToYear(
                        PlanUtil.RETIREMENT_MILESTONE_AGE,
                        DateUtil.dobToAge(ctx.user?.dob) ?? PlanUtil.DEFAULT_AGE
                    ),
                },
            })

            return {
                plans: [plan],
            }
        },
    })
)

router.post(
    '/',
    endpoint.create({
        input: PlanCreateSchema,
        resolve: async ({ input: { events, milestones, ...data }, ctx }) => {
            ctx.ability.throwUnlessCan('create', 'Plan')

            return await ctx.planService.create({
                ...data,
                userId: ctx.user!.id,
                events: { create: events },
                milestones: { create: milestones },
            })
        },
    })
)

/** Create a new plan using a pre-defined template */
router.post(
    '/template',
    endpoint.create({
        input: PlanTemplateSchema,
        resolve: async ({ input, ctx }) => {
            ctx.ability.throwUnlessCan('create', 'Plan')

            return await ctx.planService.createWithTemplate(ctx.user!, input)
        },
    })
)

/**
 * Update an existing plan using a pre-defined template
 *
 * Can be used to reset a template to defaults or
 * add milestone-templates to an existing plan
 */
router.put(
    '/:id/template',
    endpoint.create({
        input: PlanTemplateSchema,
        resolve: async ({ ctx, req, input }) => {
            const plan = await ctx.planService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Plan', plan))

            const shouldReset = req.query.reset === 'true'

            return await ctx.planService.updateWithTemplate(plan.id, input, shouldReset)
        },
    })
)

router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const plan = await ctx.planService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Plan', plan))
            return plan
        },
    })
)

router.put(
    '/:id',
    endpoint.create({
        input: PlanUpdateSchema,
        resolve: async ({ input: { events, milestones, ...data }, ctx, req }) => {
            const plan = await ctx.planService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Plan', plan))
            const updatedPlan = await ctx.planService.update(plan.id, {
                ...data,
                events: events
                    ? {
                          create: events.create,
                          update: events.update
                              ? events.update.map(({ id, data }) => ({ where: { id }, data }))
                              : undefined,
                          deleteMany: events.delete ? { id: { in: events.delete } } : undefined,
                      }
                    : undefined,
                milestones: milestones
                    ? {
                          create: milestones.create,
                          update: milestones.update
                              ? milestones.update.map(({ id, data }) => ({ where: { id }, data }))
                              : undefined,
                          deleteMany: milestones.delete
                              ? { id: { in: milestones.delete } }
                              : undefined,
                      }
                    : undefined,
            })
            return updatedPlan
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const plan = await ctx.planService.get(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('Plan', plan))
            return ctx.planService.delete(plan.id)
        },
    })
)

router.get(
    '/:id/projections',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const plan = await ctx.planService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Plan', plan))
            return ctx.planService.projections(plan.id)
        },
    })
)

export default router

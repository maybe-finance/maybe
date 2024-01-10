import Decimal from 'decimal.js'
import { z } from 'zod'

const DecimalSchema = z.union([z.number(), z.string(), z.instanceof(Decimal)])
const IdSchema = z.number().int()
const YearSchema = z.number().int().positive()

const RetirementTemplateSchema = z.object({
    retirementYear: z.number(),
    annualIncome: DecimalSchema.nullish(),
    annualRetirementIncome: DecimalSchema.nullish(),
    annualExpenses: DecimalSchema.nullish(),
    annualRetirementExpenses: DecimalSchema.nullish(),
})

export const PlanTemplateSchema = z.discriminatedUnion('type', [
    z.object({
        type: z.literal('retirement'),
        data: RetirementTemplateSchema,
    }),
    z.object({
        type: z.literal('placeholder'),
        data: z.object({}).default({}),
    }),
])

export type RetirementTemplate = z.infer<typeof RetirementTemplateSchema>
export type PlanTemplate = z.infer<typeof PlanTemplateSchema>

const PlanEventCreateSchema = z.object({
    name: z.string(),
    category: z.string().nullish(),
    frequency: z.enum(['monthly', 'yearly']).optional(),
    initialValue: DecimalSchema.nullish(),
    initialValueRef: z.enum(['income', 'expenses']).nullish(),
    rate: DecimalSchema.optional(),
    startYear: YearSchema.nullish(),
    startMilestoneId: IdSchema.nullish(),
    endYear: YearSchema.nullish(),
    endMilestoneId: IdSchema.nullish(),
})

const PlanEventUpdateSchema = PlanEventCreateSchema.partial()

const PlanMilestoneBaseCreateSchema = z.object({
    name: z.string(),
    category: z.string().optional(),
})

const PlanMilestoneTypeCreateSchema = z.discriminatedUnion('type', [
    z.object({
        type: z.literal('year'),
        year: YearSchema,
    }),
    z.object({
        type: z.literal('net_worth'),
        expenseMultiple: z.number().nonnegative(),
        expenseYears: z.number().int().nonnegative(),
    }),
])

const PlanMilestoneCreateSchema = PlanMilestoneBaseCreateSchema.and(PlanMilestoneTypeCreateSchema)
const PlanMilestoneUpdateSchema = PlanMilestoneBaseCreateSchema.partial().and(
    PlanMilestoneTypeCreateSchema
)

export const PlanCreateSchema = z.object({
    name: z.string(),
    lifeExpectancy: z.number(),
    events: z.array(PlanEventCreateSchema).default([]),
    milestones: z.array(PlanMilestoneCreateSchema).default([]),
})

export const PlanUpdateSchema = PlanCreateSchema.omit({ events: true, milestones: true })
    .extend({
        events: z
            .object({
                create: z.array(PlanEventCreateSchema),
                update: z.array(z.object({ id: IdSchema, data: PlanEventUpdateSchema })),
                delete: z.array(IdSchema),
            })
            .partial(),
        milestones: z
            .object({
                create: z.array(PlanMilestoneCreateSchema),
                update: z.array(z.object({ id: IdSchema, data: PlanMilestoneUpdateSchema })),
                delete: z.array(IdSchema),
            })
            .partial(),
    })
    .partial()

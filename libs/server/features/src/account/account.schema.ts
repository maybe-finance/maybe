import { DateUtil } from '@maybe-finance/shared'
import { AccountCategory } from '@prisma/client'
import { z } from 'zod'

const CommonAccountFields = z.object({
    name: z.string(),
    currencyCode: z.string().default('USD'),
    isActive: z.boolean().default(true),
    startDate: z
        .string()
        .nullable()
        .transform((d) => (d ? DateUtil.datetimeTransform(d).toJSDate() : null)),
})

const ValuationAccountFields = z.object({
    provider: z.literal('user').default('user'),
    valuations: z.object({
        originalBalance: z.number(),
        currentBalance: z.number().nullish(),
        currentDate: z.string().transform((d) => DateUtil.datetimeTransform(d)),
    }),
})

// Property

const PropertyBaseSchema = z.object({
    type: z.literal('PROPERTY'),
    categoryUser: z.enum(['property']),
    propertyMeta: z
        .object({
            track: z.boolean().default(false),
            address: z.object({
                line1: z.string(),
                line2: z.string().optional(),
                city: z.string(),
                state: z.string(),
                zip: z.string(),
                country: z.string().default('United States'),
            }),
        })
        .optional(),
})

const PropertyCreateSchema =
    PropertyBaseSchema.merge(CommonAccountFields).merge(ValuationAccountFields)

const PropertyUpdateSchema = PropertyBaseSchema.merge(CommonAccountFields.partial())

// Vehicle

const VehicleBaseSchema = z.object({
    type: z.literal('VEHICLE'),
    categoryUser: z.enum(['vehicle']),
    vehicleMeta: z
        .object({
            track: z.boolean().default(false),
            make: z.string(),
            model: z.string(),
            year: z.number(),
        })
        .optional(),
})

const VehicleCreateSchema =
    VehicleBaseSchema.merge(CommonAccountFields).merge(ValuationAccountFields)

const VehicleUpdateSchema = VehicleBaseSchema.merge(CommonAccountFields.partial())

// Loan
const LoanBaseSchema = z.object({
    type: z.literal('LOAN'),
    categoryUser: z.enum(['loan']),
    currentBalance: z.number(),
    loanUser: z
        .object({
            originationDate: z.string(),
            maturityDate: z.string(),
            originationPrincipal: z.number(),
            interestRate: z.discriminatedUnion('type', [
                z.object({
                    type: z.literal('fixed'),
                    rate: z.number(),
                }),
                z.object({
                    type: z.literal('arm'),
                }),
                z.object({
                    type: z.literal('variable'),
                }),
            ]),
            loanDetail: z.discriminatedUnion('type', [
                z.object({
                    type: z.literal('student'),
                }),
                z.object({
                    type: z.literal('mortgage'),
                }),
                z.object({
                    type: z.literal('other'),
                }),
            ]),
        })
        .optional(),
})

const LoanCreateSchema = LoanBaseSchema.merge(CommonAccountFields).merge(
    z.object({ provider: z.literal('user').default('user') })
)
const LoanUpdateSchema = LoanBaseSchema.merge(CommonAccountFields.partial())

// Credit

const CreditBaseSchema = z.object({
    type: z.literal('CREDIT'),
    categoryUser: z.enum(['credit']),
    creditUser: z
        .object({
            isOverdue: z.boolean(),
            lastPaymentAmount: z.number(),
            lastPaymentDate: z.string(),
            lastStatementAmount: z.number(),
            lastStatementDate: z.string(),
            minimumPayment: z.number(),
        })
        .optional(),
})

const CreditCreateSchema = CreditBaseSchema.merge(CommonAccountFields).merge(ValuationAccountFields)
const CreditUpdateSchema = CreditBaseSchema.merge(CommonAccountFields.partial())

// Other Asset

const OtherAssetBaseSchema = z.object({
    type: z.literal('OTHER_ASSET'),
    categoryUser: z.enum(['cash', 'investment', 'crypto', 'valuable', 'other']),
})

const OtherAssetCreateSchema =
    OtherAssetBaseSchema.merge(CommonAccountFields).merge(ValuationAccountFields)
const OtherAssetUpdateSchema = OtherAssetBaseSchema.merge(CommonAccountFields.partial())

// Other Liability

const OtherLiabilityBaseSchema = z.object({
    type: z.literal('OTHER_LIABILITY'),
    categoryUser: z.enum(['other']),
})

const OtherLiabilityCreateSchema =
    OtherLiabilityBaseSchema.merge(CommonAccountFields).merge(ValuationAccountFields)
const OtherLiabilityUpdateSchema = OtherLiabilityBaseSchema.merge(CommonAccountFields.partial())

export const AccountCreateSchema = z.discriminatedUnion('type', [
    PropertyCreateSchema,
    VehicleCreateSchema,
    LoanCreateSchema,
    CreditCreateSchema,
    OtherAssetCreateSchema,
    OtherLiabilityCreateSchema,
])

const ProviderAccountUpdateSchema = z.discriminatedUnion('type', [
    PropertyUpdateSchema,
    VehicleUpdateSchema,
    LoanUpdateSchema,
    CreditUpdateSchema,
    OtherAssetUpdateSchema,
    OtherLiabilityUpdateSchema,
    z
        .object({
            type: z.literal('DEPOSITORY'),
            categoryUser: z.enum(['cash', 'other']),
        })
        .merge(CommonAccountFields),
    z
        .object({
            type: z.literal('INVESTMENT'),
            categoryUser: z.enum(['investment', 'cash', 'other']),
        })
        .merge(CommonAccountFields),
])

const UserAccountUpdateSchema = z.discriminatedUnion('type', [
    PropertyUpdateSchema,
    VehicleUpdateSchema,
    LoanUpdateSchema,
    CreditUpdateSchema,
    OtherAssetUpdateSchema,
    OtherLiabilityUpdateSchema,
])

export const AccountUpdateSchema = z.discriminatedUnion('provider', [
    z.object({
        provider: z.literal('plaid'),
        data: ProviderAccountUpdateSchema,
    }),
    z.object({
        provider: z.literal('user'),
        data: UserAccountUpdateSchema,
    }),
    z.object({
        provider: z.literal(undefined),
        data: CommonAccountFields.partial().and(
            z.object({ categoryUser: z.nativeEnum(AccountCategory).optional() })
        ),
    }),
])

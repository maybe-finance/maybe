import { DateTime } from 'luxon'
import { z } from 'zod'
import { DateUtil } from '@maybe-finance/shared'

export const TransactionPaginateParams = z.object({
    pageIndex: z.string().transform((val) => parseInt(val)),
    pageSize: z
        .string()
        .default('50')
        .transform((val) => parseInt(val)),
})

export const ISODateSchema = z
    .string()
    .default(DateTime.utc().toISODate())
    .transform((s) => DateUtil.datetimeTransform(s).toJSDate())

export const TransactionUpdateInputSchema = z
    .object({
        date: ISODateSchema,
        name: z.string(),
        amount: z.number(),
        categoryUser: z.string(),
        excluded: z.boolean(),
        typeUser: z.enum(['INCOME', 'EXPENSE', 'PAYMENT', 'TRANSFER']),
    })
    .partial()

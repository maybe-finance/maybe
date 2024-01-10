import { z } from 'zod'

export const HoldingUpdateInputSchema = z
    .object({
        excluded: z.boolean(),
        costBasisUser: z.number().nullable(),
    })
    .partial()

import { z } from 'zod'

// This schema should be kept in sync with templates maintained in the Postmark dashboard
export const EmailTemplateSchema = z.object({
    alias: z.literal('trial-ending'),
    model: z.object({
        endDate: z.string(),
    }),
})

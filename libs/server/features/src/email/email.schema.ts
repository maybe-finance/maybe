import { z } from 'zod'

// This schema should be kept in sync with templates maintained in the Postmark dashboard
export const EmailTemplateSchema = z.discriminatedUnion('alias', [
    z.object({
        alias: z.literal('trial-ending'),
        model: z.object({
            endDate: z.string(),
        }),
    }),
    z.object({
        alias: z.literal('agreements-update'),
        model: z.object({
            name: z.string(),
            urls: z.object({
                fee: z.string(),
                form_adv_2a: z.string(),
                form_adv_2b: z.string(),
                form_crs: z.string(),
                privacy_policy: z.string(),
            }),
        }),
    }),
])

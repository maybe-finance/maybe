import { z } from 'zod'

export const UpdateOnboardingSchema = z.discriminatedUnion('flow', [
    z.object({
        flow: z.literal('main'),
        updates: z
            .object({
                key: z.enum([
                    'intro',
                    'profile',
                    'verifyEmail',
                    'firstAccount',
                    'accountSelection',
                    'terms',
                    'maybe',
                    'welcome',
                ]),
                markedComplete: z.boolean(),
            })
            .array(),
    }),
    z.object({
        flow: z.literal('sidebar'),
        markedComplete: z.boolean().optional(),
        updates: z
            .object({
                key: z.enum([
                    'connect-depository',
                    'connect-investment',
                    'connect-liability',
                    'add-crypto',
                    'add-property',
                    'add-vehicle',
                    'add-other',
                    'upgrade-account',
                    'create-plan',
                    'ask-advisor',
                ]),
                markedComplete: z.boolean(),
            })
            .array(),
    }),
])

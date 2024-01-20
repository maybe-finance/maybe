import { z } from 'zod'

const envSchema = z.object({
    NX_PORT: z.string().default('3334'),

    NX_DATABASE_URL: z.string(),
    NX_DATABASE_SECRET: z.string(),

    NX_PLAID_ENV: z.string().default('sandbox'),
    NX_PLAID_CLIENT_ID: z.string().default('REPLACE_THIS'),
    NX_PLAID_SECRET: z.string(),

    NX_TELLER_SIGNING_SECRET: z.string().default('REPLACE_THIS'),
    NX_TELLER_APP_ID: z.string().default('REPLACE_THIS'),
    NX_TELLER_ENV: z.string().default('sandbox'),

    NX_SENTRY_DSN: z.string().optional(),
    NX_SENTRY_ENV: z.string().optional(),

    NX_REDIS_URL: z.string().default('redis://localhost:6379'),

    NX_POLYGON_API_KEY: z.string().default(''),

    NX_POSTMARK_FROM_ADDRESS: z.string().default('account@maybe.co'),
    NX_POSTMARK_REPLY_TO_ADDRESS: z.string().default('support@maybe.co'),
    NX_POSTMARK_API_TOKEN: z.string().optional(),
    NX_STRIPE_SECRET_KEY: z.string().default('sk_test_REPLACE_THIS'),

    NX_CDN_PRIVATE_BUCKET: z.string().default('REPLACE_THIS'),
    NX_CDN_PUBLIC_BUCKET: z.string().default('REPLACE_THIS'),

    STRIPE_API_KEY: z.string().optional(),
})

const env = envSchema.parse(process.env)

export default env

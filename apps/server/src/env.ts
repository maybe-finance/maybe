import { z } from 'zod'

const toOriginArray = (s?: string) => {
    if (!s) return []

    const originList = (s || '').split(',').map((s) => s.trim())

    return originList.map((origin) => {
        const originParts = origin.split('.')

        // Search for the specific pattern: domain.tld (e.g. maybe.co) and enable wildcard access on domain
        if (originParts.length === 2) {
            return new RegExp(`${originParts[0]}\\.${originParts[1]}`)
        } else {
            return origin
        }
    })
}

const envSchema = z.object({
    NX_API_URL: z.string().url().default('http://localhost:3333'),
    NX_CDN_URL: z.string().url().default('https://staging-cdn.maybe.co'),
    NX_WEBHOOK_URL: z.string().url().optional(),

    NX_CLIENT_URL: z.string().url().default('http://localhost:4200'),
    NX_CLIENT_URL_CUSTOM: z.string().url().default('http://localhost:4200'),

    NX_ADVISOR_URL: z.string().url().default('http://localhost:4201'),

    NX_REDIS_URL: z.string().default('redis://localhost:6379'),

    NX_DATABASE_URL: z.string(),
    NX_DATABASE_SECRET: z.string(),
    NX_SESSION_SECRET: z.string(),

    NX_NGROK_URL: z.string().default('http://localhost:4551'),

    // Dev doesn't have a custom domain, so replace with the original dev URL
    NX_AUTH0_DOMAIN: z.string().default('REPLACE_THIS'),
    NX_AUTH0_CUSTOM_DOMAIN: z.string().default('REPLACE_THIS'),
    NX_AUTH0_AUDIENCE: z.string().default('https://maybe-finance-api/v1'),
    NX_AUTH0_CLIENT_ID: z.string().default('REPLACE_THIS'),
    NX_AUTH0_CLIENT_SECRET: z.string(),
    NX_AUTH0_MGMT_CLIENT_ID: z.string().default('REPLACE_THIS'),
    NX_AUTH0_MGMT_CLIENT_SECRET: z.string(),

    NX_PLAID_CLIENT_ID: z.string().default('REPLACE_THIS'),
    NX_PLAID_SECRET: z.string(),
    NX_PLAID_ENV: z.string().default('sandbox'),

    NX_FINICITY_APP_KEY: z.string(),
    NX_FINICITY_PARTNER_ID: z.string().default('REPLACE_THIS'),
    NX_FINICITY_PARTNER_SECRET: z.string(),
    NX_FINICITY_ENV: z.string().default('sandbox'),

    NX_SENTRY_DSN: z.string().optional(),
    NX_SENTRY_ENV: z.string().optional(),

    NX_LD_SDK_KEY: z.string().default('REPLACE_THIS'),

    NX_POLYGON_API_KEY: z.string().default(''),

    NX_PORT: z.string().default('3333'),
    NX_CORS_ORIGINS: z.string().default('https://localhost.maybe.co').transform(toOriginArray),

    NX_MORGAN_LOG_LEVEL: z
        .string()
        .default(process.env.NODE_ENV === 'development' ? 'dev' : 'combined'),

    NX_INTERCOM_SECRET: z.string().optional(),

    NX_STRIPE_SECRET_KEY: z
        .string()
        .default(
            'REPLACE_THIS'
        ),
    NX_STRIPE_WEBHOOK_SECRET: z
        .string()
        .default('whsec_REPLACE_THIS'),
    NX_STRIPE_PREMIUM_MONTHLY_PRICE_ID: z.string().default('price_REPLACE_THIS'),
    NX_STRIPE_PREMIUM_YEARLY_PRICE_ID: z.string().default('price_REPLACE_THIS'),

    NX_CDN_PRIVATE_BUCKET: z
        .string()
        .default('REPLACE_THIS'),
    NX_CDN_PUBLIC_BUCKET: z
        .string()
        .default('REPLACE_THIS'),

    // Key to secrets manager value
    NX_CDN_SIGNER_SECRET_ID: z.string().default('/apps/maybe-app/CLOUDFRONT_SIGNER1_PRIV'),

    // Key to Cloudfront pub key
    NX_CDN_SIGNER_PUBKEY_ID: z.string().default('REPLACE_THIS'),

    NX_CONVERTKIT_SECRET: z.string(),
    NX_POSTMARK_FROM_ADDRESS: z.string().default('account@maybe.co'),
    NX_POSTMARK_REPLY_TO_ADDRESS: z.string().default('support@maybe.co'),
    NX_POSTMARK_API_TOKEN: z.string().default('REPLACE_THIS'),
})

const env = envSchema.parse(process.env)

export default env

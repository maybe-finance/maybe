const z = require('zod')

const envSchema = z.object({
    AUTH0_DEPLOY_CLIENT_SECRET: z.string(),
    AUTH0_ENV: z.string().default('development'),
    POSTMARK_SMTP_PASS: z.string(),
    APPLE_SIGN_IN_SECRET_KEY: z.string(),
})

const env = envSchema.parse(process.env)

module.exports = env

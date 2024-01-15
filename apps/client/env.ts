const env = {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333',
    NEXT_PUBLIC_LD_CLIENT_SIDE_ID: process.env.NEXT_PUBLIC_LD_CLIENT_SIDE_ID || 'REPLACE_THIS',
    NEXT_PUBLIC_SENTRY_DSN: process.env.NEXT_PUBLIC_SENTRY_DSN,
    NEXT_PUBLIC_SENTRY_ENV: process.env.NEXT_PUBLIC_SENTRY_ENV,
}

export default env

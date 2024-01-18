declare global {
    interface Window {
        __appenv: any
    }
}

function isBrowser() {
    return Boolean(typeof window !== 'undefined' && window.__appenv)
}

function getEnv(key: string): string | undefined {
    if (!key.length) {
        throw new Error('No env key provided')
    }

    if (isBrowser()) {
        return window.__appenv[key]
    }
}

const env = {
    NEXT_PUBLIC_API_URL:
        getEnv('NEXT_PUBLIC_API_URL') || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333',
    NEXT_PUBLIC_LD_CLIENT_SIDE_ID:
        getEnv('NEXT_PUBLIC_LD_CLIENT_SIDE_ID') ||
        process.env.NEXT_PUBLIC_LD_CLIENT_SIDE_ID ||
        'REPLACE_THIS',
    NEXT_PUBLIC_SENTRY_DSN: getEnv('NEXT_PUBLIC_SENTRY_DSN') || process.env.NEXT_PUBLIC_SENTRY_DSN,
    NEXT_PUBLIC_SENTRY_ENV: getEnv('NEXT_PUBLIC_SENTRY_ENV') || process.env.NEXT_PUBLIC_SENTRY_ENV,
}

export default env

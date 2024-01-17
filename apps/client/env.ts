function isBrowser() {
    return Boolean(typeof window !== "undefined" && (window.__env || window.__appenv));
}

function env(key: string) {
    if (!key.length) {
      throw new Error('No env key provided');
    }
  
    if (isBrowser()) {
      if (key in window.__appenv)
        return window.__appenv[key];
  
      return window.__env[key];
    }
  
    return process.env[key];
}

const env = {
    NEXT_PUBLIC_API_URL: env("NEXT_PUBLIC_API_URL") || 'http://localhost:3333',
    NEXT_PUBLIC_LD_CLIENT_SIDE_ID: env("process.env.NEXT_PUBLIC_LD_CLIENT_SIDE_ID") || 'REPLACE_THIS',
    NEXT_PUBLIC_SENTRY_DSN: env("process.env.NEXT_PUBLIC_SENTRY_DSN"),
    NEXT_PUBLIC_SENTRY_ENV: env("process.env.NEXT_PUBLIC_SENTRY_ENV"),
}

export default env

import { handleAuth, handleLogin } from '@auth0/nextjs-auth0'

export default handleAuth({
    login: handleLogin({
        authorizationParams: {
            audience: process.env.AUTH0_AUDIENCE || 'https://maybe-finance-api/v1',
            scope: process.env.AUTH0_SCOPE || 'openid profile email offline_access',
        },
    }),
})

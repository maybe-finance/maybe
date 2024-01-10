import type { Auth0ContextInterface } from '@auth0/auth0-react'
import { createContext } from 'react'
import type { PropsWithChildren } from 'react'
import { Auth0Provider, type Auth0ProviderOptions } from '@auth0/auth0-react'
import { useRouter } from 'next/router'

export const linkAuth0AccountCtx = createContext<Auth0ContextInterface | null>(
    null
) as Auth0ProviderOptions['context']

/**
 * Auth0 Context Provider
 *
 * Why 2 configs?
 *
 * For user account linking, we need two contexts so that when the secondary
 * user is authenticated prior to linking, it doesn't log the primary user out.
 *
 * @see https://github.com/auth0/auth0-react/issues/425#issuecomment-1303619555
 */
export function AuthProvider({ children }: PropsWithChildren) {
    const router = useRouter()

    const sharedConfig: Auth0ProviderOptions = {
        domain: process.env.NEXT_PUBLIC_AUTH0_DOMAIN || 'REPLACE_THIS',
        clientId: process.env.NEXT_PUBLIC_AUTH0_CLIENT_ID || 'REPLACE_THIS',
        onRedirectCallback: (appState) => router.replace(appState?.returnTo || '/'),
        authorizationParams: {
            audience: process.env.NEXT_PUBLIC_AUTH0_AUDIENCE || 'https://maybe-finance-api/v1',
            screen_hint: router.pathname === '/register' ? 'signup' : 'login',
        },
    }

    const isBrowser = typeof window !== 'undefined'

    return (
        <Auth0Provider
            {...sharedConfig}
            useRefreshTokens // https://auth0.com/docs/security/tokens/refresh-tokens/configure-refresh-token-rotation
            cacheLocation="localstorage"
            authorizationParams={{
                ...sharedConfig.authorizationParams,
                redirect_uri: isBrowser ? `${window.location.origin}?primary` : undefined,
            }}
            skipRedirectCallback={
                isBrowser ? window.location.href.includes('?secondary') : undefined
            }
        >
            <Auth0Provider
                {...sharedConfig}
                authorizationParams={{
                    ...sharedConfig.authorizationParams,
                    redirect_uri: isBrowser ? `${window.location.origin}?secondary` : undefined,
                }}
                skipRedirectCallback={
                    isBrowser ? window.location.href.includes('?primary') : undefined
                }
                context={linkAuth0AccountCtx}
            >
                {children}
            </Auth0Provider>
        </Auth0Provider>
    )
}

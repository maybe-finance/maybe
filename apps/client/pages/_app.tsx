import type { PropsWithChildren, ReactElement } from 'react'
import type { AppProps } from 'next/app'
import { ErrorBoundary } from 'react-error-boundary'
import { Analytics } from '@vercel/analytics/react'
import {
    AxiosProvider,
    QueryProvider,
    ErrorFallback,
    LogProvider,
    UserAccountContextProvider,
    AuthProvider,
} from '@maybe-finance/client/shared'
import type { ClientType } from '@maybe-finance/client/shared'
import { AccountsManager } from '@maybe-finance/client/features'
import { AccountContextProvider } from '@maybe-finance/client/shared'
import * as Sentry from '@sentry/react'
import { BrowserTracing } from '@sentry/tracing'
import { useFlags, withLDProvider } from 'launchdarkly-react-client-sdk'
import env from '../env'
import '../styles.css'
import { withAuthenticationRequired } from '@auth0/auth0-react'
import ModalManager from '../components/ModalManager'
import Maintenance from '../components/Maintenance'
import Meta from '../components/Meta'
import APM from '../components/APM'

Sentry.init({
    dsn: env.NEXT_PUBLIC_SENTRY_DSN,
    environment: env.NEXT_PUBLIC_SENTRY_ENV,
    integrations: [
        new BrowserTracing({
            tracingOrigins: ['localhost', new URL(env.NEXT_PUBLIC_API_URL).hostname],
        }),
    ],
    tracesSampleRate: 0.6,
})

// Providers and components only relevant to a logged-in user
const WithAuth = withAuthenticationRequired(function ({ children }: PropsWithChildren) {
    return (
        <ModalManager>
            <UserAccountContextProvider>
                <AccountContextProvider>
                    {children}

                    {/* Add, edit, delete connections and manual accounts */}
                    <AccountsManager />
                </AccountContextProvider>
            </UserAccountContextProvider>
        </ModalManager>
    )
})

function App({
    Component: Page,
    pageProps,
}: AppProps & {
    Component: AppProps['Component'] & {
        getLayout?: (component: ReactElement) => JSX.Element
        isPublic?: boolean
    }
}) {
    const flags = useFlags() as ClientType.ClientSideFeatureFlag

    const getLayout = Page.getLayout ?? ((page) => page)

    // Maintenance Guard
    if (flags.maintenance) {
        return <Maintenance />
    }

    return (
        <LogProvider logger={console}>
            <ErrorBoundary
                FallbackComponent={ErrorFallback}
                onError={(err) => {
                    Sentry.captureException(err)
                    console.error('React app crashed', err)
                }}
            >
                <Meta />
                <Analytics />
                <QueryProvider>
                    <AuthProvider>
                        <AxiosProvider>
                            <>
                                <APM />
                                {Page.isPublic === true ? (
                                    getLayout(<Page {...pageProps} />)
                                ) : (
                                    <WithAuth>{getLayout(<Page {...pageProps} />)}</WithAuth>
                                )}
                            </>
                        </AxiosProvider>
                    </AuthProvider>
                </QueryProvider>
            </ErrorBoundary>
        </LogProvider>
    )
}

export default withLDProvider<{ Component; pageProps }>({
    clientSideID: env.NEXT_PUBLIC_LD_CLIENT_SIDE_ID,
    // Prevent a new LD user being registered on each page load by always initializing with the same key
    user: { key: 'anonymous-client', anonymous: true },
})(App)

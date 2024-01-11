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
import { AccountsManager } from '@maybe-finance/client/features'
import { AccountContextProvider } from '@maybe-finance/client/shared'
import * as Sentry from '@sentry/react'
import { BrowserTracing } from '@sentry/tracing'
import env from '../env'
import '../styles.css'
import { withAuthenticationRequired } from '@auth0/auth0-react'
import ModalManager from '../components/ModalManager'
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
const WithAuth = function ({ children }: PropsWithChildren) {
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
}

export default function App({
    Component: Page,
    pageProps,
}: AppProps & {
    Component: AppProps['Component'] & {
        getLayout?: (component: ReactElement) => JSX.Element
        isPublic?: boolean
    }
}) {
    const getLayout = Page.getLayout ?? ((page) => page)

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

import { useEffect, useState, type PropsWithChildren, type ReactElement } from 'react'
import type { AppProps } from 'next/app'
import { ErrorBoundary } from 'react-error-boundary'
import { Analytics } from '@vercel/analytics/react'
import {
    AxiosProvider,
    QueryProvider,
    ErrorFallback,
    LogProvider,
    UserAccountContextProvider,
} from '@maybe-finance/client/shared'
import { AccountsManager, OnboardingGuard } from '@maybe-finance/client/features'
import { AccountContextProvider } from '@maybe-finance/client/shared'
import * as Sentry from '@sentry/react'
import { BrowserTracing } from '@sentry/tracing'
import env from '../env'
import '../styles.css'
import { SessionProvider, useSession } from 'next-auth/react'
import Meta from '../components/Meta'
import APM from '../components/APM'
import { useRouter } from 'next/router'

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
    const { data: session, status } = useSession()
    const [isLoading, setLoading] = useState(true)
    const router = useRouter()

    useEffect(() => {
        if (status === 'loading') return // Wait until the session status is not 'loading'
        setLoading(false)

        if (!session) {
            router.push('/login')
        }
    }, [session, status, router])

    if (session) {
        return (
            <OnboardingGuard>
                <UserAccountContextProvider>
                    <AccountContextProvider>
                        {children}
                        <AccountsManager />
                    </AccountContextProvider>
                </UserAccountContextProvider>
            </OnboardingGuard>
        )
    }
    return null
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
                    <SessionProvider>
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
                    </SessionProvider>
                </QueryProvider>
            </ErrorBoundary>
        </LogProvider>
    )
}

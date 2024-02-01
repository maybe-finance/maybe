import { QueryCache, QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import * as Sentry from '@sentry/react'
import Axios from 'axios'

export interface QueryClientProviderProps {
    children: React.ReactNode
}

const queryClient = new QueryClient({
    queryCache: new QueryCache({
        onError: (error, query) => {
            if (Axios.isAxiosError(error)) {
                const axiosMessage = Axios.isAxiosError(error)
                    ? error.response?.data?.errors?.[0]?.title
                    : null

                Sentry.captureException(
                    axiosMessage ? new Error(axiosMessage, { cause: error.cause }) : error,
                    (scope) => {
                        scope.setTransactionName(
                            `Query with key: [ ${query.queryKey.join(' > ')} ] failed`
                        )
                        scope.setContext('errors', {
                            errors: JSON.stringify(error.response?.data?.errors),
                        })

                        return scope
                    }
                )
            } else {
                Sentry.captureException(error)
            }
        },
    }),
})

export function QueryProvider({ children }: QueryClientProviderProps) {
    return (
        <QueryClientProvider client={queryClient}>
            {children}
            <ReactQueryDevtools position="bottom-right" />
        </QueryClientProvider>
    )
}

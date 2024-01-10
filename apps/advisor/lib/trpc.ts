import { createTRPCNext } from '@trpc/next'
import { httpBatchLink, loggerLink } from '@trpc/client'
import type { inferRouterInputs, inferRouterOutputs } from '@trpc/server'
import { superjson } from '@maybe-finance/shared'
// eslint-disable-next-line @nrwl/nx/enforce-module-boundaries
import type { AppRouter } from '@maybe-finance/trpc'

export type RouterInput = inferRouterInputs<AppRouter>
export type RouterOutput = inferRouterOutputs<AppRouter>

export const trpc = createTRPCNext<AppRouter>({
    config() {
        return {
            links: [
                loggerLink({
                    enabled: (opts) =>
                        process.env.NODE_ENV === 'development' ||
                        (opts.direction === 'down' && opts.result instanceof Error),
                }),
                httpBatchLink({ url: '/api/trpc' }),
            ],
            transformer: superjson,
        }
    },
})

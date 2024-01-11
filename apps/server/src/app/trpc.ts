import * as trpc from '@trpc/server'
import type * as trpcExpress from '@trpc/server/adapters/express'
import { superjson } from '@maybe-finance/shared'
import { createContext } from './lib/endpoint'

export async function createTRPCContext({ req }: trpcExpress.CreateExpressContextOptions) {
    return createContext(req)
}

type Context = trpc.inferAsyncReturnType<typeof createTRPCContext>

const t = trpc.initTRPC.context<Context>().create({
    transformer: superjson,
})

/**
 * Middleware
 */
const isUser = t.middleware(({ ctx, next }) => {
    if (!ctx.user) {
        throw new trpc.TRPCError({ code: 'UNAUTHORIZED', message: 'You must be a user' })
    }

    return next({
        ctx: {
            ...ctx,
            user: ctx.user,
        },
    })
})

/**
 * Routers
 */
export const appRouter = t.router({
    users: t.router({
        me: t.procedure.use(isUser).query(({ ctx }) => ctx.user),
    }),
})

export type AppRouter = typeof appRouter

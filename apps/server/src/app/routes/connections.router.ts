import { Router } from 'express'
import { subject } from '@casl/ability'
import { z } from 'zod'
import endpoint from '../lib/endpoint'
import { devOnly } from '../middleware'

const router = Router()

router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('AccountConnection', connection))
            return connection
        },
    })
)

router.put(
    '/:id',
    endpoint.create({
        input: z.object({ syncStatus: z.enum(['IDLE', 'PENDING', 'SYNCING']) }),
        resolve: async ({ input, ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('AccountConnection', connection))
            const updatedConnection = await ctx.accountConnectionService.update(
                connection.id,
                input
            )
            return updatedConnection
        },
    })
)

router.post(
    '/:id/disconnect',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('AccountConnection', connection))
            return ctx.accountConnectionService.disconnect(connection.id)
        },
    })
)

router.post(
    '/:id/reconnect',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('AccountConnection', connection))
            return ctx.accountConnectionService.reconnect(connection.id)
        },
    })
)

router.post(
    '/:id/sync',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('AccountConnection', connection))
            return ctx.accountConnectionService.sync(connection.id)
        },
    })
)

router.post(
    '/:id/sync/:sync',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('AccountConnection', connection))

            switch (req.params.sync) {
                case 'balances': {
                    await ctx.accountConnectionService.syncBalances(connection.id)
                    break
                }
                case 'securities': {
                    await ctx.accountConnectionService.syncSecurities(connection.id)
                    break
                }
                default:
                    throw new Error(`unknown sync command: ${req.params.sync}`)
            }

            return connection
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('AccountConnection', connection))
            return ctx.accountConnectionService.delete(connection.id)
        },
    })
)

router.delete(
    '/',
    devOnly,
    endpoint.create({
        resolve: async ({ ctx }) => {
            await ctx.prisma.accountConnection.deleteMany({ where: { userId: ctx.user!.id } })
            return { success: true }
        },
    })
)

export default router

import { Router } from 'express'
import { SandboxItemFireWebhookRequestWebhookCodeEnum } from 'plaid'
import type { SharedType } from '@maybe-finance/shared'
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
    '/:id/plaid/link-update-completed',
    endpoint.create({
        input: z.object({
            status: z.enum(['success', 'exit']),
        }),
        resolve: async ({ ctx, input, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)

            ctx.ability.throwUnlessCan('update', subject('AccountConnection', connection))

            await ctx.prisma.accountConnection.update({
                where: { id: connection.id },
                data: {
                    plaidNewAccountsAvailable: false,
                },
            })

            if (input.status === 'success') {
                await ctx.accountConnectionService.sync(connection.id)
            }
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
    '/:id/plaid/link-token',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const token = await ctx.plaidService.createLinkTokenForUpdateMode(
                ctx.user!.id,
                +req.params.id,
                req.query.mode as SharedType.PlaidLinkUpdateMode
            )

            await ctx.plaidService.cacheLinkToken(ctx.user!.id, token)

            return { token }
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

router.post(
    '/:id/plaid/sandbox/fire-webhook',
    devOnly,
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)

            if (!connection.plaidAccessToken)
                throw new Error(`connection does not have a plaidAccessToken`)

            // https://plaid.com/docs/api/sandbox/#sandboxitemfire_webhook
            await ctx.plaid.sandboxItemFireWebhook({
                access_token: ctx.cryptoService.decrypt(connection.plaidAccessToken),
                webhook_code: SandboxItemFireWebhookRequestWebhookCodeEnum.DefaultUpdate,
            })

            return { success: true }
        },
    })
)

router.post(
    '/:id/plaid/sandbox/item-reset-login',
    devOnly,
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const connection = await ctx.accountConnectionService.get(+req.params.id)

            if (!connection.plaidAccessToken)
                throw new Error(`connection does not have a plaidAccessToken`)

            await ctx.plaid.sandboxItemResetLogin({
                access_token: ctx.cryptoService.decrypt(connection.plaidAccessToken),
            })

            // Triggers the reset login error
            await ctx.accountConnectionService.sync(+req.params.id)

            return { success: true }
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

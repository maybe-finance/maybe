import { Router } from 'express'
import { subject } from '@casl/ability'
import endpoint from '../lib/endpoint'
import {
    TransactionPaginateParams,
    TransactionUpdateInputSchema,
} from '@maybe-finance/server/features'

const router = Router()

router.get(
    '/',
    endpoint.create({
        input: TransactionPaginateParams,
        resolve: async ({ ctx, input }) => {
            return ctx.transactionService.getAll(ctx.user!.id, input.pageIndex, input.pageSize)
        },
    })
)

router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const transaction = await ctx.transactionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Transaction', transaction))
            return transaction
        },
    })
)

router.put(
    '/:id',
    endpoint.create({
        input: TransactionUpdateInputSchema,
        resolve: async ({ input, ctx, req }) => {
            const transaction = await ctx.transactionService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Transaction', transaction))

            const updatedTransaction = await ctx.transactionService.update(+req.params.id, input)

            await ctx.accountService.syncBalances(transaction.accountId)

            return updatedTransaction
        },
    })
)

export default router

import { Router } from 'express'
import env from '../../env'
import endpoint from '../lib/endpoint'

const router = Router()

router.get(
    '/users/card/:memberId',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const memberId = req.params.memberId
            if (!memberId) throw new Error('No memberId provided for member details.')

            const clientUrl = env.NX_CLIENT_URL_CUSTOM || env.NX_CLIENT_URL

            return ctx.userService.getMemberCard(memberId, clientUrl)
        },
    })
)

export default router

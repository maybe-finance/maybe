import { Router } from 'express'
import { createBullBoard } from '@bull-board/api'
import { BullAdapter } from '@bull-board/api/bullAdapter'
import { ExpressAdapter } from '@bull-board/express'
import { BullQueue } from '@maybe-finance/server/shared'
import { queueService } from '../lib/endpoint'
import { validateAuthJwt } from '../middleware'

const router = Router()

const serverAdapter = new ExpressAdapter().setBasePath('/admin/bullmq')

createBullBoard({
    queues: queueService.allQueues
        .filter((q): q is BullQueue => q instanceof BullQueue)
        .map((q) => new BullAdapter(q.queue)),
    serverAdapter,
})

router.get('/', validateAuthJwt, (req, res) => {
    res.render('pages/dashboard', {
        user: req.user?.name,
        role: 'Admin',
    })
})

// Visit /admin/bullmq to see BullMQ Dashboard
router.use('/bullmq', validateAuthJwt, serverAdapter.getRouter())

export default router

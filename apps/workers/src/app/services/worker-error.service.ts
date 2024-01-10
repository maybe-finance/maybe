import type { Logger } from 'winston'
import * as Sentry from '@sentry/node'
import { ErrorUtil } from '@maybe-finance/server/shared'

type WorkerErrorContext = { variant: 'unhandled'; error: unknown }

export class WorkerErrorHandlerService {
    constructor(private readonly logger: Logger) {}

    async handleWorkersError(ctx: WorkerErrorContext) {
        const err = ErrorUtil.parseError(ctx.error)

        switch (ctx.variant) {
            case 'unhandled':
                this.logger.error(`[workers-unhandled] ${err.message}`, { error: err.metadata })

                Sentry.captureException(ctx.error, {
                    level: 'error',
                    tags: err.sentryTags,
                    contexts: err.sentryContexts,
                })

                break
            default:
                return
        }
    }
}

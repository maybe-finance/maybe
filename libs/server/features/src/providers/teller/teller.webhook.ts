import type { Logger } from 'winston'
import type { PrismaClient } from '@prisma/client'
import type { TellerApi, TellerTypes } from '@maybe-finance/teller-api'
import type { IAccountConnectionService } from '../../account-connection'

export interface ITellerWebhookHandler {
    handleWebhook(data: TellerTypes.WebhookData): Promise<void>
}

export class TellerWebhookHandler implements ITellerWebhookHandler {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly teller: TellerApi,
        private readonly accountConnectionService: IAccountConnectionService
    ) {}

    /**
     * Process Teller webhooks. These handlers should execute as quick as possible and
     * long-running operations should be performed in the background.
     */
    async handleWebhook(data: TellerTypes.WebhookData) {
        switch (data.type) {
            case 'webhook.test': {
                this.logger.info('Received Teller webhook test')
                break
            }
            default: {
                this.logger.warn('Unhandled Teller webhook', { data })
                break
            }
        }
    }
}

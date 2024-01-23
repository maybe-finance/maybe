import type { Logger } from 'winston'
import type { SyncSecurityQueueJobData } from '@maybe-finance/server/shared'
import type { ISecurityPricingService } from './security-pricing.service'

export interface ISecurityPricingProcessor {
    syncAll(jobData?: SyncSecurityQueueJobData): Promise<void>
    syncUSStockTickers(jobData?: SyncSecurityQueueJobData): Promise<void>
}

export class SecurityPricingProcessor implements ISecurityPricingProcessor {
    constructor(
        private readonly logger: Logger,
        private readonly securityPricingService: ISecurityPricingService
    ) {}

    async syncAll(_jobData?: SyncSecurityQueueJobData) {
        await this.securityPricingService.syncAll()
    }

    async syncUSStockTickers(_jobData?: SyncSecurityQueueJobData) {
        await this.securityPricingService.syncUSStockTickers()
    }
}

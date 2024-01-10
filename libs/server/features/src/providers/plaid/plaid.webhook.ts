import type { Logger } from 'winston'
import type { PrismaClient } from '@prisma/client'
import type { QueueService } from '@maybe-finance/server/shared'
import type { IAccountConnectionService } from '../../account-connection'
import type {
    PlaidApi,
    ItemErrorWebhook,
    NewAccountsAvailableWebhook,
    PendingExpirationWebhook,
    TransactionsRemovedWebhook,
    UserPermissionRevokedWebhook,
} from 'plaid'
import { Prisma } from '@prisma/client'

type PlaidWebhook = {
    [key: string]: any
    webhook_type: string
    webhook_code: string
    item_id: string
}

export interface IPlaidWebhookHandler {
    handleWebhook(webhook: PlaidWebhook): Promise<void>
}

export class PlaidWebhookHandler implements IPlaidWebhookHandler {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly plaid: PlaidApi,
        private readonly accountConnectionService: IAccountConnectionService,
        private readonly queueService: QueueService
    ) {}

    async handleWebhook(webhook: PlaidWebhook) {
        const { webhook_type, webhook_code, item_id } = webhook

        const accountConnection = await this.prisma.accountConnection.findUnique({
            where: { plaidItemId: item_id },
        })

        if (!accountConnection) {
            this.logger.warn(
                `Could not find Plaid item ${item_id} in DB, aborting webhook handler code=${webhook_code} type=${webhook_type}`
            )
            return
        }

        switch (webhook_type) {
            case 'ITEM':
                switch (webhook_code) {
                    case 'ERROR': {
                        const data = webhook as ItemErrorWebhook
                        await this.prisma.accountConnection.update({
                            where: { plaidItemId: data.item_id },
                            data: {
                                status: 'ERROR',
                                plaidError: (data.error as any) ?? Prisma.DbNull,
                            },
                        })
                        break
                    }
                    case 'PENDING_EXPIRATION': {
                        const data = webhook as PendingExpirationWebhook
                        await this.prisma.accountConnection.update({
                            where: { plaidItemId: data.item_id },
                            data: {
                                status: 'ERROR',
                                plaidConsentExpiration: data.consent_expiration_time,
                            },
                        })
                        break
                    }
                    case 'USER_PERMISSION_REVOKED': {
                        const data = webhook as UserPermissionRevokedWebhook
                        await this.prisma.accountConnection.update({
                            where: { plaidItemId: data.item_id },
                            data: {
                                status: 'ERROR',
                                plaidError: (data.error as any) ?? Prisma.DbNull,
                            },
                        })
                        break
                    }
                    case 'NEW_ACCOUNTS_AVAILABLE': {
                        const data = webhook as NewAccountsAvailableWebhook
                        await this.prisma.accountConnection.update({
                            where: { plaidItemId: data.item_id },
                            data: {
                                // set flag indicating new accounts available -> trigger plaid update mode
                                // https://plaid.com/docs/link/account-select-v2-migration-guide/#requesting-data-for-new-accounts
                                plaidNewAccountsAvailable: true,
                            },
                        })
                        break
                    }
                }
                break
            case 'TRANSACTIONS': {
                switch (webhook_code) {
                    case 'INITIAL_UPDATE':
                        break // skip because everything will be handled in historical / default updates
                    case 'HISTORICAL_UPDATE': {
                        await this.accountConnectionService.sync(accountConnection.id)
                        break
                    }
                    case 'DEFAULT_UPDATE': {
                        await this.accountConnectionService.sync(accountConnection.id, {
                            type: 'plaid',
                            products: ['transactions'],
                        })
                        break
                    }
                    case 'TRANSACTIONS_REMOVED': {
                        const data = webhook as TransactionsRemovedWebhook

                        this.logger.info(
                            `${data.removed_transactions.length} TRANSACTIONS_REMOVED, ids=${data.removed_transactions}`
                        )

                        await this.prisma.$executeRaw`
                          DELETE FROM "transaction" WHERE "plaid_transaction_id" IN (${Prisma.join(
                              data.removed_transactions
                          )})
                        `
                        break
                    }
                }
                break
            }
            case 'HOLDINGS': {
                switch (webhook_code) {
                    case 'DEFAULT_UPDATE': {
                        await this.accountConnectionService.sync(accountConnection.id, {
                            type: 'plaid',
                            products: ['holdings'],
                        })

                        break
                    }
                }
                break
            }
            case 'INVESTMENTS_TRANSACTIONS': {
                switch (webhook_code) {
                    case 'DEFAULT_UPDATE': {
                        await this.accountConnectionService.sync(accountConnection.id, {
                            type: 'plaid',
                            products: ['investment-transactions'],
                        })

                        break
                    }
                }
                break
            }
            case 'LIABILITIES': {
                switch (webhook_code) {
                    case 'DEFAULT_UPDATE': {
                        await this.accountConnectionService.sync(accountConnection.id, {
                            type: 'plaid',
                            products: ['liabilities'],
                        })

                        break
                    }
                }
                break
            }
            default:
                break
        }
    }
}

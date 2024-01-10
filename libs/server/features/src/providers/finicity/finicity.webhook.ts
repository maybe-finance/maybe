import type { Logger } from 'winston'
import _ from 'lodash'
import type { PrismaClient } from '@prisma/client'
import type { FinicityApi, FinicityTypes } from '@maybe-finance/finicity-api'
import type { IAccountConnectionService } from '../../account-connection'

export interface IFinicityWebhookHandler {
    handleWebhook(data: FinicityTypes.WebhookData): Promise<void>
    handleTxPushEvent(event: FinicityTypes.TxPushEvent): Promise<void>
}

export class FinicityWebhookHandler implements IFinicityWebhookHandler {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly finicity: FinicityApi,
        private readonly accountConnectionService: IAccountConnectionService,
        private readonly txPushUrl: string | Promise<string>
    ) {}

    /**
     * Process Finicity Connect webhooks. These handlers should execute as quick as possible and
     * long-running operations should be performed in the background.
     */
    async handleWebhook(data: FinicityTypes.WebhookData) {
        switch (data.eventType) {
            case 'added': {
                const { accounts, institutionId } = data.payload

                const { customerId, institutionLoginId } = accounts[0]

                const [user, providerInstitution] = await Promise.all([
                    this.prisma.user.findUniqueOrThrow({
                        where: {
                            finicityCustomerId: customerId,
                        },
                    }),
                    this.prisma.providerInstitution.findUnique({
                        where: {
                            provider_providerId: {
                                provider: 'FINICITY',
                                providerId: institutionId,
                            },
                        },
                        include: {
                            institution: true,
                        },
                    }),
                ])

                const connection = await this.prisma.accountConnection.create({
                    data: {
                        userId: user.id,
                        name:
                            providerInstitution?.institution?.name ||
                            providerInstitution?.name ||
                            'Institution',
                        type: 'finicity',
                        finicityInstitutionId: institutionId,
                        finicityInstitutionLoginId: String(institutionLoginId),
                    },
                })

                await Promise.allSettled([
                    // subscribe to TxPUSH
                    ...accounts.map(async (account) =>
                        this.finicity.subscribeTxPush({
                            accountId: account.id,
                            customerId: account.customerId,
                            callbackUrl: await this.txPushUrl,
                        })
                    ),
                ])

                // sync
                await this.accountConnectionService.sync(connection.id, {
                    type: 'finicity',
                    initialSync: true,
                })

                break
            }
            default: {
                this.logger.warn('Unhandled Finicity webhook', { data })
                break
            }
        }
    }

    async handleTxPushEvent(event: FinicityTypes.TxPushEvent) {
        switch (event.class) {
            case 'account': {
                const connections = await this.prisma.accountConnection.findMany({
                    where: {
                        accounts: {
                            some: {
                                finicityAccountId: {
                                    in: _.uniq(event.records.map((a) => String(a.id))),
                                },
                            },
                        },
                    },
                    select: {
                        id: true,
                    },
                })

                await Promise.allSettled(
                    connections.map((connection) =>
                        this.accountConnectionService.sync(connection.id)
                    )
                )
                break
            }
            case 'transaction': {
                const connections = await this.prisma.accountConnection.findMany({
                    where: {
                        accounts: {
                            some: {
                                finicityAccountId: {
                                    in: _.uniq(event.records.map((t) => String(t.accountId))),
                                },
                            },
                        },
                    },
                    select: {
                        id: true,
                    },
                })

                await Promise.allSettled(
                    connections.map((connection) =>
                        this.accountConnectionService.sync(connection.id)
                    )
                )
                break
            }
            default: {
                this.logger.warn(`unhandled Finicity TxPush event`, { event })
                break
            }
        }
    }
}

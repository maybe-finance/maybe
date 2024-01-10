import type { Logger } from 'winston'
import type { AccountConnection, PrismaClient, User } from '@prisma/client'
import type { IETL, SyncConnectionOptions } from '@maybe-finance/server/shared'
import type { FinicityApi, FinicityTypes } from '@maybe-finance/finicity-api'
import type { IInstitutionProvider } from '../../institution'
import type {
    AccountConnectionSyncEvent,
    IAccountConnectionProvider,
} from '../../account-connection'
import _ from 'lodash'
import axios from 'axios'
import { v4 as uuid } from 'uuid'
import { SharedUtil } from '@maybe-finance/shared'
import { etl } from '@maybe-finance/server/shared'

export interface IFinicityConnect {
    generateConnectUrl(userId: User['id'], institutionId: string): Promise<{ link: string }>

    generateFixConnectUrl(
        userId: User['id'],
        accountConnectionId: AccountConnection['id']
    ): Promise<{ link: string }>
}

export class FinicityService
    implements IFinicityConnect, IAccountConnectionProvider, IInstitutionProvider
{
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly finicity: FinicityApi,
        private readonly etl: IETL<AccountConnection>,
        private readonly webhookUrl: string | Promise<string>,
        private readonly testMode: boolean
    ) {}

    async generateConnectUrl(userId: User['id'], institutionId: string) {
        const customerId = await this.getOrCreateCustomerId(userId)

        this.logger.debug(
            `Generating Finicity connect URL with user=${userId} institution=${institutionId} customerId=${customerId}`
        )

        const res = await this.finicity.generateLiteConnectUrl({
            customerId,
            institutionId,
            webhook: await this.webhookUrl,
            webhookContentType: 'application/json',
        })

        return res
    }

    async generateFixConnectUrl(userId: User['id'], accountConnectionId: AccountConnection['id']) {
        const accountConnection = await this.prisma.accountConnection.findUniqueOrThrow({
            where: { id: accountConnectionId },
        })

        if (!accountConnection.finicityInstitutionLoginId) {
            throw new Error(
                `connection ${accountConnection.id} is missing finicityInstitutionLoginId`
            )
        }

        const res = await this.finicity.generateFixConnectUrl({
            customerId: await this.getOrCreateCustomerId(userId),
            institutionLoginId: accountConnection.finicityInstitutionLoginId,
            webhook: await this.webhookUrl,
            webhookContentType: 'application/json',
        })

        return res
    }

    async sync(connection: AccountConnection, options?: SyncConnectionOptions): Promise<void> {
        if (options && options.type !== 'finicity') throw new Error('invalid sync options')

        if (options?.initialSync) {
            const user = await this.prisma.user.findUniqueOrThrow({
                where: { id: connection.userId },
            })

            if (!user.finicityCustomerId) {
                throw new Error(`user ${user.id} missing finicityCustomerId`)
            }

            // refresh customer accounts
            try {
                this.logger.info(
                    `refreshing customer accounts for customer: ${user.finicityCustomerId}`
                )
                const { accounts } = await this.finicity.refreshCustomerAccounts({
                    customerId: user.finicityCustomerId,
                })

                // no need to await this - this is fire-and-forget and shouldn't delay the sync process
                this.logger.info(
                    `triggering load historic transactions for customer: ${
                        user.finicityCustomerId
                    } accounts: ${accounts.map((a) => a.id)}`
                )
                Promise.allSettled(
                    accounts
                        .filter(
                            (a) =>
                                a.institutionLoginId.toString() ===
                                connection.finicityInstitutionLoginId
                        )
                        .map((account) =>
                            this.finicity
                                .loadHistoricTransactions({
                                    accountId: account.id,
                                    customerId: account.customerId,
                                })
                                .catch((err) => {
                                    this.logger.warn(
                                        `error loading historic transactions for finicity account: ${account.id} customer: ${account.customerId}`,
                                        err
                                    )
                                })
                        )
                )
            } catch (err) {
                // gracefully handle error, this shouldn't prevent the sync process from continuing
                this.logger.error(`error refreshing customer accounts for initial sync`, err)
            }
        }

        await etl(this.etl, connection)
    }

    async onSyncEvent(connection: AccountConnection, event: AccountConnectionSyncEvent) {
        switch (event.type) {
            case 'success': {
                await this.prisma.accountConnection.update({
                    where: { id: connection.id },
                    data: {
                        status: 'OK',
                    },
                })
                break
            }
            case 'error': {
                const { error } = event

                await this.prisma.accountConnection.update({
                    where: { id: connection.id },
                    data: {
                        status: 'ERROR',
                        finicityError:
                            axios.isAxiosError(error) && error.response
                                ? _.pick(error.response, ['status', 'data'])
                                : undefined,
                    },
                })
                break
            }
        }
    }

    async delete(connection: AccountConnection): Promise<void> {
        if (connection.finicityInstitutionLoginId) {
            const user = await this.prisma.user.findUniqueOrThrow({
                where: { id: connection.userId },
                select: {
                    finicityCustomerId: true,
                    accountConnections: {
                        where: {
                            id: { not: connection.id },
                            finicityInstitutionLoginId: connection.finicityInstitutionLoginId,
                        },
                        select: { id: true },
                    },
                },
            })

            // ensure there are no other connections with the same `finicityInstitutionLoginId` before deleting the accounts from Finicity
            if (user.finicityCustomerId && !user.accountConnections.length) {
                try {
                    await this.finicity.deleteCustomerAccountsByInstitutionLogin({
                        customerId: user.finicityCustomerId,
                        institutionLoginId: +connection.finicityInstitutionLoginId,
                    })
                    this.logger.info(
                        `deleted finicity customer ${user.finicityCustomerId} accounts for institutionLoginId ${connection.finicityInstitutionLoginId}`
                    )
                } catch (err) {
                    this.logger.error(
                        `error deleting finicity customer ${user.finicityCustomerId} accounts for institutionLoginId ${connection.finicityInstitutionLoginId}`,
                        err
                    )
                }
            } else {
                this.logger.warn(
                    `skipping delete for finicity customer ${user.finicityCustomerId} accounts for institutionLoginId ${connection.finicityInstitutionLoginId} (duplicate_connections: ${user.accountConnections.length})`
                )
            }
        }
    }

    async getInstitutions() {
        const finicityInstitutions = await SharedUtil.paginate({
            pageSize: 1000,
            fetchData: (offset, count) =>
                SharedUtil.withRetry(
                    () =>
                        this.finicity
                            .getInstitutions({
                                start: offset / count + 1,
                                limit: count,
                            })
                            .then(({ institutions, found, displaying }) => {
                                this.logger.debug(
                                    `paginated finicity fetch inst=${displaying} (total=${found} offset=${offset} count=${count})`
                                )
                                return institutions
                            }),
                    {
                        maxRetries: 3,
                        onError: (error, attempt) => {
                            this.logger.error(
                                `Finicity fetch institutions request failed attempt=${attempt} offset=${offset} count=${count}`,
                                { error }
                            )
                            return (
                                !axios.isAxiosError(error) ||
                                (error.response && error.response.status >= 500)
                            )
                        },
                    }
                ),
        })

        return _.uniqBy(finicityInstitutions, (i) => i.id).map((finicityInstitution) => ({
            providerId: `${finicityInstitution.id}`,
            name: finicityInstitution.name || '',
            url: finicityInstitution.urlHomeApp
                ? SharedUtil.normalizeUrl(finicityInstitution.urlHomeApp)
                : null,
            logoUrl: finicityInstitution.branding?.icon,
            primaryColor: finicityInstitution.branding?.primaryColor,
            oauth: finicityInstitution.oauthEnabled,
            data: finicityInstitution,
        }))
    }

    private async getOrCreateCustomerId(
        userId: User['id']
    ): Promise<FinicityTypes.AddCustomerResponse['id']> {
        const user = await this.prisma.user.findUniqueOrThrow({
            where: { id: userId },
            select: { id: true, finicityCustomerId: true },
        })

        if (user.finicityCustomerId) {
            return user.finicityCustomerId
        }

        // See https://api-reference.finicity.com/#/rest/api-endpoints/customer/add-customer
        const finicityUsername = uuid()

        const { id: finicityCustomerId } = this.testMode
            ? await this.finicity.addTestingCustomer({ username: finicityUsername })
            : await this.finicity.addCustomer({ username: finicityUsername })

        await this.prisma.user.update({
            where: {
                id: userId,
            },
            data: {
                finicityUsername,
                finicityCustomerId,
            },
        })

        this.logger.info(
            `created finicity customer ${finicityCustomerId} for user ${userId} (testMode=${this.testMode})`
        )
        return finicityCustomerId
    }
}

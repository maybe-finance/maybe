import type { Logger } from 'winston'
import type { AccountConnection, PrismaClient, User } from '@prisma/client'
import type { IInstitutionProvider } from '../../institution'
import type {
    AccountConnectionSyncEvent,
    IAccountConnectionProvider,
} from '../../account-connection'
import { SharedUtil } from '@maybe-finance/shared'
import type { SharedType } from '@maybe-finance/shared'
import type { SyncConnectionOptions, CryptoService, IETL } from '@maybe-finance/server/shared'
import _ from 'lodash'
import { ErrorUtil, etl } from '@maybe-finance/server/shared'
import type { TellerApi, TellerTypes } from '@maybe-finance/teller-api'

export interface ITellerConnect {
    generateConnectUrl(userId: User['id'], institutionId: string): Promise<{ link: string }>

    generateFixConnectUrl(
        userId: User['id'],
        accountConnectionId: AccountConnection['id']
    ): Promise<{ link: string }>
}

export class TellerService implements IAccountConnectionProvider, IInstitutionProvider {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly teller: TellerApi,
        private readonly etl: IETL<AccountConnection>,
        private readonly crypto: CryptoService,
        private readonly webhookUrl: string | Promise<string>,
        private readonly testMode: boolean
    ) {}

    async sync(connection: AccountConnection, options?: SyncConnectionOptions) {
        if (options && options.type !== 'teller') throw new Error('invalid sync options')

        await etl(this.etl, connection)
    }

    async onSyncEvent(connection: AccountConnection, event: AccountConnectionSyncEvent) {
        switch (event.type) {
            case 'success': {
                await this.prisma.accountConnection.update({
                    where: { id: connection.id },
                    data: {
                        status: 'OK',
                        syncStatus: 'IDLE',
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
                        tellerError: ErrorUtil.isTellerError(error)
                            ? (error.response.data as any)
                            : undefined,
                    },
                })
                break
            }
        }
    }

    async delete(connection: AccountConnection) {
        // purge teller data
        if (connection.tellerAccessToken && connection.tellerEnrollmentId) {
            const accounts = await this.prisma.account.findMany({
                where: { accountConnectionId: connection.id },
            })

            for (const account of accounts) {
                if (!account.tellerAccountId) continue
                await this.teller.deleteAccount({
                    accessToken: this.crypto.decrypt(connection.tellerAccessToken),
                    accountId: account.tellerAccountId,
                })

                this.logger.info(`Teller account ${account.id} removed`)
            }

            this.logger.info(`Teller enrollment ${connection.tellerEnrollmentId} removed`)
        }
    }

    async getInstitutions() {
        const tellerInstitutions = await SharedUtil.paginate({
            pageSize: 10000,
            delay:
                process.env.NODE_ENV !== 'production'
                    ? {
                          onDelay: (message: string) => this.logger.debug(message),
                          milliseconds: 7_000, // Sandbox rate limited at 10 calls / minute
                      }
                    : undefined,
            fetchData: () =>
                SharedUtil.withRetry(
                    () =>
                        this.teller.getInstitutions().then((data) => {
                            this.logger.debug(
                                `teller fetch inst=${data.length} (total=${data.length})`
                            )
                            return data
                        }),
                    {
                        maxRetries: 3,
                        onError: (error, attempt) => {
                            this.logger.error(
                                `Teller fetch institutions request failed attempt=${attempt}`,
                                { error: ErrorUtil.parseError(error) }
                            )

                            return !ErrorUtil.isTellerError(error) || error.response.status >= 500
                        },
                    }
                ),
        })

        return _.uniqBy(tellerInstitutions, (i) => i.id).map((tellerInstitution) => {
            const { id, name } = tellerInstitution
            return {
                providerId: id,
                name,
                url: null,
                logo: null,
                logoUrl: `https://teller.io/images/banks/${id}.jpg`,
                primaryColor: null,
                oauth: false,
                data: tellerInstitution,
            }
        })
    }

    async handleEnrollment(
        userId: User['id'],
        institution: Pick<TellerTypes.Institution, 'name' | 'id'>,
        enrollment: TellerTypes.Enrollment
    ) {
        const connections = await this.prisma.accountConnection.findMany({
            where: { userId },
        })

        if (connections.length > 40) {
            throw new Error('MAX_ACCOUNT_CONNECTIONS')
        }

        const accounts = await this.teller.getAccounts({ accessToken: enrollment.accessToken })

        this.logger.info(`Teller accounts retrieved for enrollment ${enrollment.enrollment.id}`)

        // If all the accounts are Non-USD, throw an error
        if (accounts.every((a) => a.currency !== 'USD')) {
            throw new Error('USD_ONLY')
        }

        await this.prisma.user.update({
            where: { id: userId },
            data: {
                tellerUserId: enrollment.user.id,
            },
        })

        const accountConnection = await this.prisma.accountConnection.create({
            data: {
                name: enrollment.enrollment.institution.name,
                type: 'teller' as SharedType.AccountConnectionType,
                tellerEnrollmentId: enrollment.enrollment.id,
                tellerInstitutionId: institution.id,
                tellerAccessToken: this.crypto.encrypt(enrollment.accessToken),
                userId,
                syncStatus: 'PENDING',
            },
        })

        await this.sync(accountConnection, { type: 'teller', initialSync: true })

        await this.prisma.accountConnection.update({
            where: { id: accountConnection.id },
            data: {
                status: 'OK',
                syncStatus: 'IDLE',
            },
        })

        return accountConnection
    }
}

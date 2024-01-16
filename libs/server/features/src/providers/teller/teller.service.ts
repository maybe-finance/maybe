import type { Logger } from 'winston'
import type { AccountConnection, PrismaClient, User } from '@prisma/client'
import type { IInstitutionProvider } from '../../institution'
import type {
    AccountConnectionSyncEvent,
    IAccountConnectionProvider,
} from '../../account-connection'
import { SharedUtil } from '@maybe-finance/shared'
import type { SyncConnectionOptions, CryptoService, IETL } from '@maybe-finance/server/shared'
import _ from 'lodash'
import { ErrorUtil, etl } from '@maybe-finance/server/shared'
import type { TellerApi } from '@maybe-finance/teller-api'

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
        if (connection.tellerAccessToken && connection.tellerAccountId) {
            await this.teller.deleteAccount({
                accessToken: this.crypto.decrypt(connection.tellerAccessToken),
                accountId: connection.tellerAccountId,
            })

            this.logger.info(`Item ${connection.tellerAccountId} removed`)
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
}

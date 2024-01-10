import type { AccountConnection, PrismaClient, User } from '@prisma/client'
import type { Logger } from 'winston'
import type { LinkTokenCreateRequest, PlaidApi, Institution } from 'plaid'
import type { SharedType } from '@maybe-finance/shared'
import type { SyncConnectionOptions, CryptoService, IETL } from '@maybe-finance/server/shared'
import type { IInstitutionProvider } from '../../institution'
import type {
    AccountConnectionSyncEvent,
    IAccountConnectionProvider,
} from '../../account-connection'

import _ from 'lodash'
import { CountryCode, Products } from 'plaid'
import { SharedUtil } from '@maybe-finance/shared'
import { ErrorUtil, etl } from '@maybe-finance/server/shared'

export interface IPlaidConnect {
    createLinkToken(userId: User['id'], options?: Partial<LinkTokenCreateRequest>): Promise<string>

    createLinkTokenForUpdateMode(
        userId: User['id'],
        accountConnectionId: AccountConnection['id'],
        mode: SharedType.PlaidLinkUpdateMode
    ): Promise<string>

    exchangePublicToken(
        userId: User['id'],
        token: string,
        institution: Pick<Institution, 'name' | 'institution_id'>
    ): Promise<AccountConnection>
}

export class PlaidService
    implements IPlaidConnect, IAccountConnectionProvider, IInstitutionProvider
{
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly plaid: PlaidApi,
        private readonly etl: IETL<AccountConnection>,
        private readonly crypto: CryptoService,
        private readonly webhookUrl: string | Promise<string>,
        private readonly clientUrl: string
    ) {}

    async sync(connection: AccountConnection, options?: SyncConnectionOptions) {
        if (options && options.type !== 'plaid') throw new Error('invalid sync options')

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
                        plaidError: ErrorUtil.isPlaidError(error)
                            ? (error.response.data as any)
                            : undefined,
                    },
                })
                break
            }
        }
    }

    async delete(connection: AccountConnection) {
        // purge plaid data
        if (connection.plaidAccessToken) {
            const res = await this.plaid.itemRemove({
                access_token: this.crypto.decrypt(connection.plaidAccessToken),
            })

            this.logger.info(
                `Item ${connection.plaidItemId} removed with request ID ${res.data.request_id}`
            )
        }
    }

    async getInstitutions() {
        // Retrieve paginated institutions from Plaid - https://plaid.com/docs/api/institutions/#institutionsget
        const plaidInstitutions = await SharedUtil.paginate({
            pageSize: 500,
            delay:
                process.env.NODE_ENV !== 'production'
                    ? {
                          onDelay: (message: string) => this.logger.debug(message),
                          milliseconds: 7_000, // Sandbox rate limited at 10 calls / minute
                      }
                    : undefined,
            fetchData: (offset, count) =>
                SharedUtil.withRetry(
                    () =>
                        this.plaid
                            .institutionsGet({
                                country_codes: [CountryCode.Us],
                                count,
                                offset,
                                options: {
                                    include_optional_metadata: true,
                                },
                            })
                            .then(({ data }) => {
                                this.logger.debug(
                                    `paginated plaid fetch inst=${data.institutions.length} (total=${data.total} offset=${offset} count=${count})`,
                                    { request_id: data.request_id }
                                )
                                return data.institutions
                            }),
                    {
                        maxRetries: 3,
                        onError: (error, attempt) => {
                            this.logger.error(
                                `Plaid fetch institutions request failed attempt=${attempt} offset=${offset} count=${count}`,
                                { error: ErrorUtil.parseError(error) }
                            )

                            return !ErrorUtil.isPlaidError(error) || error.response.status >= 500
                        },
                    }
                ),
        })

        return _.uniqBy(plaidInstitutions, (i) => i.institution_id).map((plaidInstitution) => {
            const { institution_id, name, url, logo, primary_color } = plaidInstitution
            return {
                providerId: institution_id,
                name,
                url: url ? SharedUtil.normalizeUrl(url) : null,
                logo,
                primaryColor: primary_color,
                oauth: plaidInstitution.oauth,
                data: plaidInstitution,
            }
        })
    }

    /**
     * Returns existing link token for OAuth re-initialization
     */
    async getLinkToken(userId: User['id']) {
        const user = await this.prisma.user.findFirstOrThrow({
            where: { id: userId },
            select: { plaidLinkToken: true },
        })

        if (!user.plaidLinkToken)
            throw new Error('Could not re-initialize flow for OAuth, no link token found')

        return user.plaidLinkToken
    }

    // Save link token for later retrieval (needed for OAuth institutions) - this will be cleared upon connection
    async cacheLinkToken(userId: User['id'], token: string) {
        return await this.prisma.user.update({
            where: { id: userId },
            data: { plaidLinkToken: token },
        })
    }

    async createLinkToken(userId: User['id'], options?: Partial<LinkTokenCreateRequest>) {
        const config = await this.getLinkConfig(userId, {
            products: [Products.Transactions],
            ...options,
        })

        const {
            data: { link_token, request_id },
        } = await this.plaid.linkTokenCreate(config)

        this.logger.info(`Plaid link token created for user ${userId}`, {
            request_id,
        })

        return link_token
    }

    /**
     * @see https://plaid.com/docs/link/update-mode/#using-update-mode
     */
    async createLinkTokenForUpdateMode(
        userId: User['id'],
        accountConnectionId: AccountConnection['id'],
        mode: SharedType.PlaidLinkUpdateMode
    ) {
        const accountConnection = await this.prisma.accountConnection.findUniqueOrThrow({
            where: { id: accountConnectionId },
        })

        if (!accountConnection.plaidAccessToken) {
            throw new Error(`connection ${accountConnection.id} does not have a plaid access token`)
        }

        const config = await this.getLinkConfig(
            userId,
            mode === 'new-accounts'
                ? {
                      access_token: this.crypto.decrypt(accountConnection.plaidAccessToken),
                      update: { account_selection_enabled: true },
                  }
                : {
                      access_token: this.crypto.decrypt(accountConnection.plaidAccessToken),
                  }
        )

        const {
            data: { link_token, request_id },
        } = await this.plaid.linkTokenCreate(config)

        this.logger.info(`Plaid link token in update mode created for user ${userId}`, {
            request_id,
        })

        return link_token
    }

    async exchangePublicToken(
        userId: User['id'],
        token: string,
        institution: Pick<Institution, 'name' | 'institution_id'>
    ) {
        const connections = await this.prisma.accountConnection.findMany({
            where: { userId },
        })

        if (connections.length > 40) {
            throw new Error('MAX_ACCOUNT_CONNECTIONS')
        }

        const {
            data: { access_token, item_id, request_id },
        } = await this.plaid.itemPublicTokenExchange({ public_token: token })

        this.logger.info(`Plaid token exchanged for item ${item_id}`, { request_id })

        const {
            data: { accounts: plaidAccounts, request_id: accountsRequest, item },
        } = await this.plaid.accountsGet({ access_token })

        this.logger.info(`Plaid accounts retrieved for item ${item.item_id}`, {
            request_id: accountsRequest,
        })

        // If all the accounts are Non-USD, throw an error
        if (plaidAccounts.every((a) => a.balances.iso_currency_code !== 'USD')) {
            throw new Error('USD_ONLY')
        }

        // Create account connection on exchange; accounts + txns will sync later with webhook
        const [accountConnection] = await this.prisma.$transaction([
            this.prisma.accountConnection.create({
                data: {
                    name: institution.name,
                    type: 'plaid' as SharedType.AccountConnectionType,
                    plaidItemId: item_id,
                    plaidInstitutionId: institution.institution_id,
                    plaidAccessToken: this.crypto.encrypt(access_token),
                    userId,
                    syncStatus: 'PENDING',
                },
            }),
            // Once connection created, no longer allow the user's cached link token to be used
            this.prisma.user.update({
                where: { id: userId },
                data: { plaidLinkToken: null },
            }),
        ])

        return accountConnection
    }

    async createSandboxAccount(userId: User['id'], username?: string) {
        // https://plaid.com/docs/sandbox/institutions/
        const randomInstitution = _.sample([
            { name: 'First Platypus Bank', id: 'ins_109508' },
            { name: 'First Gingham Credit Union', id: 'ins_109509' },
            { name: 'Tattersall Federal Credit Union', id: 'ins_109510' },
            { name: 'Tartan Bank', id: 'ins_109511' },
            { name: 'Houndstooth Bank', id: 'ins_109512' },
        ])!

        // Does the same thing as Plaid Link flow, but all with code (great for dev testing)
        const {
            data: { public_token },
        } = await this.plaid.sandboxPublicTokenCreate({
            institution_id: randomInstitution.id,
            initial_products: [Products.Transactions],
            options: {
                webhook: await this.webhookUrl,
                override_username: username,
            },
        })

        return this.exchangePublicToken(userId, public_token, {
            name: randomInstitution.name,
            institution_id: randomInstitution.id,
        })
    }

    private async getLinkConfig(
        userId: User['id'],
        options: Partial<LinkTokenCreateRequest>
    ): Promise<LinkTokenCreateRequest> {
        return {
            user: {
                client_user_id: userId.toString(),
            },
            client_name: 'Maybe',
            country_codes: [CountryCode.Us],
            language: 'en',
            redirect_uri: `${this.clientUrl}/oauth`,
            webhook: await this.webhookUrl,
            link_customization_name: 'account_selection',
            ...options,
        }
    }
}

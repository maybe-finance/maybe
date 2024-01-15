import type { Logger } from 'winston'
import type { AccountConnection, PrismaClient, User } from '@prisma/client'
import type { IETL, SyncConnectionOptions } from '@maybe-finance/server/shared'
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
import type { TellerApi } from '@maybe-finance/teller-api'

export interface ITellerConnect {
    generateConnectUrl(userId: User['id'], institutionId: string): Promise<{ link: string }>

    generateFixConnectUrl(
        userId: User['id'],
        accountConnectionId: AccountConnection['id']
    ): Promise<{ link: string }>
}

export class TellerService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly teller: TellerApi,
        private readonly webhookUrl: string | Promise<string>,
        private readonly testMode: boolean
    ) {}
}

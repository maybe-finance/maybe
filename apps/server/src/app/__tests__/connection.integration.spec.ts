import type { AxiosInstance } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import type { Prisma, AccountConnection, AccountSyncStatus, User } from '@prisma/client'
import type { ItemRemoveResponse } from 'plaid'
import isCI from 'is-ci'
import { startServer, stopServer } from './utils/server'
import { getAxiosClient } from './utils/axios'
import prisma from '../lib/prisma'
import { TestUtil } from '@maybe-finance/shared'
import { InMemoryQueue } from '@maybe-finance/server/shared'
import { default as _plaid } from '../lib/plaid'
import nock from 'nock'
import { resetUser } from './utils/user'

jest.mock('../middleware/validate-plaid-jwt.ts')
jest.mock('plaid')

// For TypeScript support
const plaid = jest.mocked(_plaid)

const auth0Id = isCI ? 'auth0|61afd38f678a0c006895f046' : 'auth0|61afd340678a0c006895f000'
let axios: AxiosInstance
let user: User | null
let connection: AccountConnection
let connectionData: Prisma.AccountConnectionCreateArgs

// When debugging, we don't want the tests to time out
if (process.env.IS_VSCODE_DEBUG === 'true') {
    jest.setTimeout(100000)
}

beforeAll(async () => {
    await startServer()
    axios = await getAxiosClient()

    nock.enableNetConnect()
    nock.disableNetConnect()
    nock.enableNetConnect((host) => {
        return host.includes('127.0.0.1') || host.includes('maybe-finance-development.us.auth0.com')
    })
})

afterAll(async () => {
    await stopServer()
})

beforeEach(async () => {
    user = await resetUser(auth0Id)

    connectionData = {
        data: {
            name: 'Chase Test',
            type: 'plaid' as SharedType.AccountConnectionType,
            plaidItemId: 'test-plaid-item-server',
            plaidInstitutionId: 'ins_3',
            plaidAccessToken:
                'U2FsdGVkX1+WMq9lfTS9Zkbgrn41+XT1hvSK5ain/udRPujzjVCAx/lyPG7EumVZA+nVKXPauGwI+d7GZgtqTA9R3iCZNusU6LFPnmFOCE4=',
            userId: user!.id,
            syncStatus: 'PENDING' as AccountSyncStatus,
        },
    }

    connection = await prisma.accountConnection.create(connectionData)
})

afterEach(async () => {
    if (user) {
        await prisma.user.delete({ where: { id: user.id } })
    }
})

describe('/v1/connections API', () => {
    it('POST /:id/sync', async () => {
        const queueSpy = jest.spyOn(InMemoryQueue.prototype, 'add')

        const res = await axios.post<AccountConnection>(`/connections/${connection.id}/sync`)

        expect(res.status).toEqual(200)

        expect(queueSpy).toBeCalledWith(
            'sync-connection',
            expect.objectContaining({
                accountConnectionId: res.data.id,
            })
        )

        // Partial equality
        expect(res.data).toMatchObject({
            ...connectionData.data,
            syncStatus: 'PENDING',
        })
    })

    it('DELETE /:id', async () => {
        plaid.itemRemove.mockResolvedValueOnce(
            TestUtil.axiosSuccess<ItemRemoveResponse>({
                request_id: 'test request id',
            })
        )

        const res = await axios.delete<AccountConnection>(`/connections/${connection.id}`)

        expect(res.status).toEqual(200)
        expect(plaid.itemRemove).toHaveBeenCalledTimes(1)

        const res2 = await axios.get<AccountConnection>(`/connections/${connection.id}`)

        // Should not be able to retrieve a connection after deletion
        expect(res2.status).toEqual(500)
    })
})

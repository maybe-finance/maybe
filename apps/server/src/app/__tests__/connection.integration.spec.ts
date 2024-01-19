import type { AxiosInstance } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import type { Prisma, AccountConnection, User } from '@prisma/client'
import { startServer, stopServer } from './utils/server'
import { getAxiosClient } from './utils/axios'
import prisma from '../lib/prisma'
import { InMemoryQueue } from '@maybe-finance/server/shared'
import { default as _teller } from '../lib/teller'
import nock from 'nock'
import { resetUser } from './utils/user'

jest.mock('../lib/teller.ts')

// For TypeScript support
const teller = jest.mocked(_teller)

const authId = '__TEST_USER_ID__'
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
    user = await resetUser(authId)

    connectionData = {
        data: {
            name: 'Chase Test',
            type: 'teller' as SharedType.AccountConnectionType,
            tellerEnrollmentId: 'test-teller-item-workers',
            tellerInstitutionId: 'chase_test',
            tellerAccessToken:
                'U2FsdGVkX1+WMq9lfTS9Zkbgrn41+XT1hvSK5ain/udRPujzjVCAx/lyPG7EumVZA+nVKXPauGwI+d7GZgtqTA9R3iCZNusU6LFPnmFOCE4=', // need correct encoding here
            userId: user.id,
            syncStatus: 'PENDING',
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
        const res = await axios.delete<AccountConnection>(`/connections/${connection.id}`)

        expect(res.status).toEqual(200)

        const res2 = await axios.get<AccountConnection>(`/connections/${connection.id}`)

        // Should not be able to retrieve a connection after deletion
        expect(res2.status).toEqual(500)
    })
})

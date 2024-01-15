import type { User } from '@prisma/client'
import prisma from '../../lib/prisma'

const EMAIL = 'test@example.com'

export async function resetUser(authId = '__TEST_USER_ID__'): Promise<User> {
    const [_, [user]] = await prisma.$transaction([
        prisma.$executeRaw`DELETE FROM "user" WHERE auth_id=${authId}`,
        prisma.$queryRaw<
            [User]
        >`INSERT INTO "user" (auth_id, email) VALUES (${authId}, ${EMAIL}) ON CONFLICT DO NOTHING RETURNING *`,
    ])

    return user
}

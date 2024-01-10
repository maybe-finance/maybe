import type { User } from '@prisma/client'
import prisma from '../../lib/prisma'

const EMAIL = 'test@example.com'

export async function resetUser(auth0Id = '__TEST_USER_ID__'): Promise<User> {
    const [_, [user]] = await prisma.$transaction([
        prisma.$executeRaw`DELETE FROM "user" WHERE auth0_id=${auth0Id}`,
        prisma.$queryRaw<
            [User]
        >`INSERT INTO "user" (auth0_id, email) VALUES (${auth0Id}, ${EMAIL}) ON CONFLICT DO NOTHING RETURNING *`,
    ])

    return user
}

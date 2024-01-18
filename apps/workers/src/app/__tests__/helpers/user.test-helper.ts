import type { PrismaClient, User } from '@prisma/client'
import { faker } from '@faker-js/faker'

export async function resetUser(prisma: PrismaClient, authId = '__TEST_USER_ID__'): Promise<User> {
    try {
        // eslint-disable-next-line
        const [_, __, ___, user] = await prisma.$transaction([
            prisma.$executeRaw`DELETE FROM "user" WHERE auth_id=${authId};`,

            // Deleting a user does not cascade to securities, so delete all security records
            prisma.$executeRaw`DELETE from security;`,
            prisma.$executeRaw`DELETE from security_pricing;`,

            prisma.user.create({
                data: {
                    authId,
                    email: faker.internet.email(),
                    finicityCustomerId: faker.string.uuid(),
                    tellerUserId: faker.string.uuid(),
                },
            }),
        ])
        return user
    } catch (e) {
        console.error('error in reset user transaction', e)
        throw e
    }
}

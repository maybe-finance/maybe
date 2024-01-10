import type { PrismaClient, User } from '@prisma/client'

export async function resetUser(
    prisma: PrismaClient,
    auth0Id = 'auth0|workers-integration-test-id'
): Promise<User> {
    // eslint-disable-next-line
    const [_, __, ___, user] = await prisma.$transaction([
        prisma.$executeRaw`DELETE FROM "user" WHERE auth0_id=${auth0Id};`,

        // Deleting a user does not cascade to securities, so delete all security records
        prisma.$executeRaw`DELETE from security;`,
        prisma.$executeRaw`DELETE from security_pricing;`,

        prisma.user.create({
            data: {
                auth0Id,
                email: 'test@example.com',
                finicityCustomerId: 'TEST',
            },
        }),
    ])

    return user
}

import { AuthUser, AuthUserRole, Institution, PrismaClient, Provider } from '@prisma/client'
import { encodePassword } from '../apps/server/src/app/lib/bcrypt'

const prisma = new PrismaClient()

/*
 * NOTE: seeding should be idempotent
 */
async function main() {
    const institutions: (Pick<Institution, 'id' | 'name'> & {
        providers: { provider: Provider; providerId: string; logoUrl: string; rank?: number }[]
    })[] = [
        {
            id: 1,
            name: 'Capital One',
            providers: [
                {
                    provider: Provider.TELLER,
                    providerId: 'capital_one',
                    logoUrl: 'https://teller.io/images/banks/capital_one.jpg',
                    rank: 1,
                },
            ],
        },
        {
            id: 2,
            name: 'Wells Fargo',
            providers: [
                {
                    provider: Provider.TELLER,
                    providerId: 'wells_fargo',
                    logoUrl: 'https://teller.io/images/banks/wells_fargo.jpg',
                },
            ],
        },
    ]

    const users: AuthUser[] = [
        {
            id: '1',
            name: 'Test',
            firstName: 'Tester',
            lastName: 'Testing',
            email: 'test@test.com',
            emailVerified: new Date(),
            password: encodePassword('Password1'),
            image: 'assets/images/advisor-avatar.png',
            role: AuthUserRole.admin,
        },
        {
            id: '2',
            name: 'John Doe',
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@john.com',
            emailVerified: new Date(),
            password: encodePassword('Password2'),
            image: 'assets/images/advisor-avatar.png',
            role: AuthUserRole.user,
        },
        {
            id: '3',
            name: 'Jane Doe',
            firstName: 'Jane',
            lastName: 'Doe',
            email: 'jane@jane.com',
            emailVerified: new Date(),
            password: encodePassword('Password3'),
            image: 'assets/images/advisor-avatar.png',
            role: AuthUserRole.user,
        },
    ]

    await prisma.$transaction([
        // create institution linked to provider institutions
        ...institutions.map(({ id, name, providers }) =>
            prisma.institution.upsert({
                where: { id },
                create: {
                    name,
                    providers: {
                        connectOrCreate: providers.map(({ provider, providerId, rank = 0 }) => ({
                            where: {
                                provider_providerId: { provider, providerId },
                            },
                            create: {
                                provider,
                                providerId,
                                name,
                                rank,
                            },
                        })),
                    },
                },
                update: {},
            })
        ),
        ...users.map((user) =>
            prisma.authUser.upsert({
                where: { id: user.id },
                create: user,
                update: {},
            })
        ),
    ])
}

// Only run the seed in preview environments, not production
if (process.env.NODE_ENV !== 'production') {
    console.log('seeding...')
    main()
        .catch((e) => {
            console.error('prisma seed failed', e)
            process.exit(1)
        })
        .finally(async () => {
            await prisma.$disconnect()
        })
} else {
    console.warn('seeding skipped', process.env.NODE_ENV)
}

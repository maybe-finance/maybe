import { Institution, PrismaClient, Provider } from '@prisma/client'
import bcrypt from 'bcrypt'

const prisma = new PrismaClient()

/*
 * NOTE: seeding should be idempotent
 */
async function main() {
    const institutions: (Pick<Institution, 'id' | 'name'> & {
        providers: { provider: Provider; providerId: string; rank?: number }[]
    })[] = [
        {
            id: 1,
            name: 'Capital One',
            providers: [{ provider: 'PLAID', providerId: 'ins_9', rank: 1 }],
        },
        {
            id: 2,
            name: 'Discover Bank',
            providers: [{ provider: 'PLAID', providerId: 'ins_33' }],
        },
    ]

    const hashedPassword = await bcrypt.hash('TestPassword123', 10)

    await prisma.$transaction([
        // create testing auth user
        prisma.authUser.upsert({
            where: {
                id: 'test_ec3ee8a4-fa01-4f11-8ac5-9c49dd7fbae4',
            },
            create: {
                id: 'test_ec3ee8a4-fa01-4f11-8ac5-9c49dd7fbae4',
                firstName: 'James',
                lastName: 'Bond',
                email: 'bond@007.com',
                password: hashedPassword,
            },
            update: {},
        }),
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

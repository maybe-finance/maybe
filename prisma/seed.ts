import { Institution, PrismaClient, Provider } from '@prisma/client'

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
            providers: [
                { provider: 'PLAID', providerId: 'ins_9', rank: 1 },
            ],
        },
        {
            id: 2,
            name: 'Discover Bank',
            providers: [
                { provider: 'PLAID', providerId: 'ins_33' },
            ],
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

import { Institution, PrismaClient, Provider } from '@prisma/client'
import bcrypt from 'bcrypt'

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

    const hashedPassword = await bcrypt.hash('TestPassword123', 10)
    const onboarding = {
        main: {
            steps: [
                {
                    key: 'intro',
                    markedComplete: true,
                },
                {
                    key: 'profile',
                    markedComplete: true,
                },
                {
                    key: 'firstAccount',
                    markedComplete: true,
                },
                {
                    key: 'accountSelection',
                    markedComplete: true,
                },
                {
                    key: 'maybe',
                    markedComplete: true,
                },
                {
                    key: 'welcome',
                    markedComplete: true,
                },
            ],
            markedComplete: false,
        },
        sidebar: {
            steps: [
                {
                    key: 'connect-depository',
                    markedComplete: true,
                },
                {
                    key: 'add-vehicle',
                    markedComplete: true,
                },
                {
                    key: 'add-other',
                    markedComplete: false,
                },
            ],
            markedComplete: true,
        },
    }

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
        prisma.authUser.upsert({
            where: {
                id: 'test_f5ec79b4-8c49-4015-bc37-f2758923ef38',
            },
            create: {
                id: 'test_f5ec79b4-8c49-4015-bc37-f2758923ef38',
                firstName: 'Karan',
                lastName: 'Handa',
                email: 'test@maybe.com',
                password: hashedPassword,
            },
            update: {},
        }),
        prisma.user.upsert({
            where: {
                authId: 'test_f5ec79b4-8c49-4015-bc37-f2758923ef38',
            },
            create: {
                email: 'test@maybe.com',
                firstName: 'Michael',
                lastName: 'Jackson',
                authId: 'test_f5ec79b4-8c49-4015-bc37-f2758923ef38',
                onboarding: onboarding,
                household: 'single',
                country: 'US',
                maybe: 'Test',
                dob: new Date('2002-09-26T00:00:00.000Z'),
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

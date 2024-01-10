import type { PrismaClient, User } from '@prisma/client'
import { DateTime } from 'luxon'
import { z } from 'zod'

export const SandboxSchema = z.discriminatedUnion('action', [
    z.object({ action: z.literal('reset') }),
    z.object({ action: z.literal('assign-advisor'), conversationId: z.number() }),
])

// pre-defined Auth0 user with the Advisor role
const mockAdvisorAuth0Id = 'REPLACE_THIS'

export async function assignAdvisor(conversationId: number, prisma: PrismaClient) {
    await prisma.$transaction(async (tx) => {
        const advisorUser = await tx.user.findUnique({
            where: { auth0Id: mockAdvisorAuth0Id },
            include: { advisor: { select: { id: true } } },
        })

        const advisorId = advisorUser?.advisor?.id

        if (!advisorId) {
            throw new Error('No advisor found')
        }

        await prisma.conversation.update({
            where: {
                id: conversationId,
            },
            data: {
                advisors: {
                    create: {
                        advisorId,
                    },
                },
            },
        })
    })
}

export async function resetConversations(
    input: z.infer<typeof SandboxSchema> & { userId: User['id'] },
    prisma: PrismaClient
) {
    const { userId, action } = input

    await prisma.$transaction(async (tx) => {
        const mockAdvisor = await tx.user.upsert({
            where: {
                auth0Id: mockAdvisorAuth0Id,
            },
            create: {
                auth0Id: mockAdvisorAuth0Id,
                email: 'mock+advisor@maybe.co',
                advisor: {
                    create: {
                        approvalStatus: 'approved',
                        fullName: 'Travis Woods',
                        title: 'Maybe Co-Founder & CFO, CFP, CFA',
                        bio: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                        avatarSrc: '/assets/images/advisor-avatar.png',
                    },
                },
            },
            update: {},
            include: {
                advisor: true,
            },
        })

        if (action === 'reset') {
            await tx.conversation.deleteMany({
                where: {
                    userId,
                },
            })

            // Test conversation 1 - an example conversation that was completed in the past and archived.
            await tx.conversation.create({
                data: {
                    title: 'What can I do to minimize my taxes annually?',
                    userId,
                    status: 'closed',
                    advisors: {
                        create: {
                            advisorId: mockAdvisor.advisor!.id,
                            createdAt: DateTime.now().minus({ days: 4, hours: 4 }).toJSDate(),
                            updatedAt: DateTime.now().minus({ days: 4, hours: 4 }).toJSDate(),
                        },
                    },
                    messages: {
                        createMany: {
                            data: [
                                {
                                    type: 'text',
                                    userId,
                                    createdAt: DateTime.now()
                                        .minus({ days: 4, hours: 5 })
                                        .toJSDate(),
                                    updatedAt: DateTime.now()
                                        .minus({ days: 4, hours: 5 })
                                        .toJSDate(),
                                    body: 'For some additional context, I have switched jobs 3 times in the past year and was wondering if there were any things I need to look out for given that unique situation.',
                                },
                                {
                                    type: 'video',
                                    userId: mockAdvisor.id,
                                    createdAt: DateTime.now()
                                        .minus({ days: 4, hours: 3 })
                                        .toJSDate(),
                                    updatedAt: DateTime.now()
                                        .minus({ days: 4, hours: 3 })
                                        .toJSDate(),
                                    body: 'Please see my video response below where I explain more about personal income tax and what you can do based on your finances.',
                                    mediaSrc: '/assets/short-sample-video-file.mp4',
                                },
                                {
                                    type: 'text',
                                    userId,
                                    createdAt: DateTime.now()
                                        .minus({ days: 4, hours: 2 })
                                        .toJSDate(),
                                    updatedAt: DateTime.now()
                                        .minus({ days: 4, hours: 2 })
                                        .toJSDate(),
                                    body: 'I just have one follow up.  Would I have any benefit to the married filing separate status?  Or is my current filing status the best for me?',
                                },
                                {
                                    type: 'audio',
                                    userId: mockAdvisor.id,
                                    createdAt: DateTime.now()
                                        .minus({ days: 4, hours: 1 })
                                        .toJSDate(),
                                    updatedAt: DateTime.now()
                                        .minus({ days: 4, hours: 1 })
                                        .toJSDate(),
                                    body: 'No problem, here is a quick clip I recorded explaining those filing statuses.',
                                    mediaSrc: '/assets/short-sample-audio-file.mp3',
                                },
                                {
                                    type: 'text',
                                    userId,
                                    createdAt: DateTime.now().minus({ days: 3 }).toJSDate(),
                                    updatedAt: DateTime.now().minus({ days: 3 }).toJSDate(),
                                    body: 'Great, thank you for your helpful response!  I think I am all good now!',
                                },
                            ],
                        },
                    },
                },
            })

            // Test conversation 2 - an example conversation that is in progress, no advisor assigned yet
            await tx.conversation.create({
                data: {
                    title: 'Is my current investing strategy on track?',
                    userId,
                    messages: {
                        createMany: {
                            data: [
                                {
                                    type: 'text',
                                    userId,
                                    createdAt: DateTime.now().minus({ hours: 3 }).toJSDate(),
                                    updatedAt: DateTime.now().minus({ hours: 3 }).toJSDate(),
                                    body: 'I lost big with crypto last year and have decided to re-evaluate my strategy.  Does this strategy seem appropriate for my age and goals?',
                                },
                            ],
                        },
                    },
                },
            })

            // Test conversation 3 - an example conversation that is in progress, but will expire soon due to inactivity
            await tx.conversation.create({
                data: {
                    title: 'Can I make good money in the stock market?',
                    userId,
                    messages: {
                        createMany: {
                            data: [
                                {
                                    type: 'text',
                                    userId,
                                    createdAt: DateTime.now().minus({ days: 15 }).toJSDate(),
                                    updatedAt: DateTime.now().minus({ hours: 15 }).toJSDate(),
                                    body: 'sample context',
                                },
                            ],
                        },
                    },
                },
            })

            // Test conversation 4 - an example conversation that is in progress, but will be closed by cron job due to inactivity
            await tx.conversation.create({
                data: {
                    title: 'What is the best software for filing taxes?',
                    userId,
                    messages: {
                        createMany: {
                            data: [
                                {
                                    type: 'text',
                                    userId,
                                    createdAt: DateTime.now().minus({ days: 20 }).toJSDate(),
                                    updatedAt: DateTime.now().minus({ hours: 20 }).toJSDate(),
                                    body: 'Sample context',
                                },
                            ],
                        },
                    },
                },
            })
        }
    })
}

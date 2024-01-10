import * as trpc from '@trpc/server'
import type * as trpcExpress from '@trpc/server/adapters/express'
import { z } from 'zod'
import { subject } from '@casl/ability'
import _, { chain, groupBy } from 'lodash'
import sanitizeHtml from 'sanitize-html'
import { ATAUtil, superjson } from '@maybe-finance/shared'
import { createContext } from './lib/endpoint'
import mime from 'mime-types'
import env from '../env'
import { createPresignedPost } from '@aws-sdk/s3-presigned-post'
import { ServerUtil } from '@maybe-finance/server/shared'
import { GetSecretValueCommand } from '@aws-sdk/client-secrets-manager'
import { writeToString } from '@fast-csv/format'
import type { Prisma } from '@prisma/client'

export async function createTRPCContext({ req }: trpcExpress.CreateExpressContextOptions) {
    return createContext(req)
}

type Context = trpc.inferAsyncReturnType<typeof createTRPCContext>

const t = trpc.initTRPC.context<Context>().create({
    transformer: superjson,
})

/**
 * Middleware
 */
const isUser = t.middleware(({ ctx, next }) => {
    if (!ctx.user) {
        throw new trpc.TRPCError({ code: 'UNAUTHORIZED', message: 'You must be a user' })
    }

    return next({
        ctx: {
            ...ctx,
            user: ctx.user,
        },
    })
})

/**
 * Routers
 */
const Id = z.number().int()

const advisorRouter = t.router({
    users: t.router({
        get: t.procedure
            .use(isUser)
            .input(Id)
            .query(async ({ ctx, input }) => {
                return ctx.prisma.user.findUniqueOrThrow({
                    where: { id: input },
                })
            }),
        update: t.procedure
            .use(isUser)
            .input(
                z.object({
                    userId: z.number(),
                    dependents: z.number().min(0).nullable(),
                    taxStatus: z
                        .enum([
                            'single',
                            'married_joint',
                            'married_separate',
                            'head_of_household',
                            'qualifying_widow',
                        ])
                        .nullable(),
                    incomeType: z.string().nullable(),
                    grossIncome: z.number().nullable(),
                })
            )
            .mutation(async ({ ctx, input }) => {
                const { userId, ...data } = input
                return ctx.prisma.user.update({
                    where: { id: userId },
                    data,
                })
            }),
        getAll: t.procedure.use(isUser).query(({ ctx }) => {
            return ctx.prisma.user.findMany({
                where: { conversations: { some: {} } },
            })
        }),
        getConversations: t.procedure
            .use(isUser)
            .input(Id)
            .query(async ({ ctx, input }) => {
                const advisorId = ctx.user!.advisor?.id
                if (!advisorId) throw new Error('Could not find advisor')

                const conversations = await ctx.prisma.conversation.findMany({
                    where: {
                        userId: input,
                        advisors: { some: { advisorId } },
                    },
                    include: {
                        user: { select: { id: true } },
                        messages: {
                            include: {
                                user: { select: { advisor: true } },
                            },
                            take: 1,
                            orderBy: { createdAt: 'desc' },
                        },
                    },
                })

                return _(conversations)
                    .map(({ messages, ...conversation }) => ({
                        ...conversation,
                        lastMessage: messages.at(0) ?? null,
                    }))
                    .orderBy((c) => c.lastMessage?.createdAt ?? c.createdAt, 'desc')
                    .value()
            }),
        getNotes: t.procedure
            .use(isUser)
            .input(Id)
            .query(({ ctx, input }) => {
                return ctx.prisma.conversationNote.findMany({
                    where: { userId: ctx.user!.id, conversation: { userId: input } },
                    orderBy: { createdAt: 'desc' },
                })
            }),
        getHoldings: t.procedure
            .use(isUser)
            .input(Id)
            .query(async ({ ctx, input }) => {
                const holdings = await ctx.prisma.$queryRaw<
                    {
                        account_id: number
                        institution_name: number
                        account_name: string
                        security_name: string
                        symbol: string
                        quantity: Prisma.Decimal
                        value: Prisma.Decimal
                        cost_basis: Prisma.Decimal | null
                        cost_basis_per_share: Prisma.Decimal | null
                        price: Prisma.Decimal | null
                        price_prev: Prisma.Decimal | null
                    }[]
                >`
                    SELECT
                        a.id AS account_id,
                        ac.name as institution_name,
                        a.name AS account_name,
                        s.name AS security_name,
                        s.symbol,
                        he.quantity,
                        he.value,
                        he.cost_basis,
                        he.cost_basis_per_share,
                        he.price,
                        he.price_prev
                    FROM
                        "user" u
                        LEFT JOIN account_connection ac ON ac.user_id = u.id
                        LEFT JOIN account a ON a.account_connection_id = ac.id
                        INNER JOIN holdings_enriched he ON he.account_id = a.id
                        LEFT JOIN "security" s ON s.id = he.security_id
                    WHERE
                        u.id = ${input}
                    ORDER BY
                        a.name,
                        he.value DESC;
                `

                return {
                    csv: await writeToString(holdings, { headers: true }),
                    holdings: chain(holdings)
                        .groupBy('institution_name')
                        .mapValues((v) => groupBy(v, 'account_name'))
                        .value(),
                }
            }),
    }),
    conversations: t.router({
        getAll: t.procedure.use(isUser).query(async ({ ctx }) => {
            const conversations = await ctx.prisma.conversation.findMany({
                where: ctx.ability.where.Conversation,
                include: {
                    user: { select: { id: true } },
                    messages: {
                        include: {
                            user: { select: { advisor: true } },
                        },
                        take: 1,
                        orderBy: { createdAt: 'desc' },
                    },
                },
            })

            return _(conversations)
                .map(({ messages, ...conversation }) => ({
                    ...conversation,
                    lastMessage: messages.at(0) ?? null,
                }))
                .orderBy((c) => c.lastMessage?.createdAt ?? c.createdAt, 'desc')
                .value()
        }),
        get: t.procedure
            .use(isUser)
            .input(Id)
            .query(async ({ ctx, input }) => {
                const conversation = await ctx.prisma.conversation.findUniqueOrThrow({
                    where: { id: input },
                    include: {
                        user: true,
                        messages: {
                            include: {
                                user: {
                                    include: { advisor: true },
                                },
                            },
                            orderBy: { createdAt: 'asc' },
                        },
                        advisors: {
                            include: { advisor: true },
                        },
                    },
                })
                ctx.ability.throwUnlessCan('read', subject('Conversation', conversation))

                const insights = await ctx.insightService.getUserInsights({
                    userId: conversation.user.id,
                })

                const privKeyRes = await ctx.secretsClient.send(
                    new GetSecretValueCommand({
                        SecretId: env.NX_CDN_SIGNER_SECRET_ID,
                    })
                )

                if (!privKeyRes.SecretString) {
                    throw new Error(
                        'Failed to obtain private key for url signing. Make sure key is stored in secrets manager and IAM user can access it from app.'
                    )
                }

                return {
                    ...conversation,
                    messages: conversation.messages.map((msg) =>
                        ServerUtil.mapMessage(msg, {
                            cdnUrl: env.NX_CDN_URL,
                            pubKeyId: env.NX_CDN_SIGNER_PUBKEY_ID,
                            privKey: privKeyRes.SecretString!,
                        })
                    ),
                    user: {
                        ...conversation.user,
                        insights,
                    },
                }
            }),
        update: t.procedure
            .use(isUser)
            .input(z.object({ id: Id, status: z.enum(['open', 'closed']) }))
            .mutation(async ({ ctx, input }) => {
                const { id, ...data } = input
                const conversation = await ctx.prisma.conversation.findUniqueOrThrow({
                    where: { id },
                })
                ctx.ability.throwUnlessCan('update', subject('Conversation', conversation))
                return ctx.prisma.conversation.update({
                    where: { id: conversation.id },
                    data,
                })
            }),
        getNote: t.procedure
            .use(isUser)
            .input(Id)
            .query(({ ctx, input }) => {
                return ctx.prisma.conversationNote.findUnique({
                    where: {
                        userId_conversationId: { userId: ctx.user!.id, conversationId: input },
                    },
                })
            }),
        upsertNote: t.procedure
            .use(isUser)
            .input(
                z.object({
                    body: z.string(),
                    conversationId: z.number(),
                })
            )
            .mutation(async ({ ctx, input }) => {
                return ctx.prisma.conversationNote.upsert({
                    where: {
                        userId_conversationId: {
                            userId: ctx.user!.id,
                            conversationId: input.conversationId,
                        },
                    },
                    create: {
                        body: input.body,
                        userId: ctx.user!.id,
                        conversationId: input.conversationId,
                    },
                    update: { body: input.body },
                })
            }),
    }),
    conversationAdvisors: t.router({
        create: t.procedure
            .use(isUser)
            .input(z.object({ conversationId: Id, advisorId: Id }))
            .mutation(async ({ ctx, input }) => {
                const conversation = await ctx.prisma.conversation.findUniqueOrThrow({
                    where: { id: input.conversationId },
                })
                ctx.ability.throwUnlessCan('create', 'ConversationAdvisor')
                const advisor = await ctx.prisma.conversationAdvisor.create({
                    data: {
                        conversationId: conversation.id,
                        advisorId: input.advisorId,
                    },
                })

                // Notify user that the advisor has seen their message
                await ctx.queueService.getQueue('send-email').add('send-email', {
                    type: 'conversation-notification',
                    notification: {
                        type: 'review',
                        conversationId: conversation.id,
                    },
                })

                return advisor
            }),
        delete: t.procedure
            .use(isUser)
            .input(z.object({ conversationId: Id, advisorId: Id }))
            .mutation(async ({ ctx, input }) => {
                const conversation = await ctx.prisma.conversation.findUniqueOrThrow({
                    where: { id: input.conversationId },
                })
                ctx.ability.throwUnlessCan('delete', 'ConversationAdvisor')
                return ctx.prisma.conversationAdvisor.delete({
                    where: {
                        conversationId_advisorId: {
                            conversationId: conversation.id,
                            advisorId: input.advisorId,
                        },
                    },
                })
            }),
    }),
})

export const appRouter = t.router({
    advisor: advisorRouter,
    users: t.router({
        me: t.procedure.use(isUser).query(({ ctx }) => ctx.user),
    }),
    messages: t.router({
        signS3Url: t.procedure
            .use(isUser)
            .input(
                z.object({
                    conversationId: z.number(),
                    mimeType: z.string().optional(),
                })
            )
            .mutation(async ({ ctx, input }) => {
                const { url, fields } = await createPresignedPost(ctx.s3.cli, {
                    Bucket: ctx.s3.buckets['private'],
                    Key:
                        ATAUtil.generateS3Filename(input.conversationId) +
                        (input.mimeType ? `.${mime.extension(input.mimeType)}` : ''),
                    Fields: {
                        success_action_status: '201',
                    },
                })

                return {
                    method: 'POST',
                    url,
                    fields,
                }
            }),
        create: t.procedure
            .use(isUser)
            .input(
                z.object({
                    conversationId: Id,
                    type: z.enum(['text', 'audio', 'video']),
                    body: z
                        .string()
                        .transform((s) => sanitizeHtml(s))
                        .nullish(),
                    mediaSrc: z.string().nullish(),
                })
            )
            .mutation(async ({ ctx, input: { conversationId, ...data } }) => {
                const conversation = await ctx.prisma.conversation.findUniqueOrThrow({
                    where: { id: conversationId },
                })
                ctx.ability.throwUnlessCan('update', subject('Conversation', conversation))

                const newMessage = await ctx.messageService.create(
                    {
                        ...data,
                        conversationId: conversation.id,
                        userId: ctx.user.id,
                    },
                    ctx.user.id !== conversation.userId
                )

                return newMessage
            }),
        delete: t.procedure
            .use(isUser)
            .input(Id)
            .mutation(async ({ ctx, input }) => {
                const message = await ctx.messageService.get(input)
                ctx.ability.throwUnlessCan('delete', subject('Message', message))
                return ctx.prisma.message.delete({ where: { id: message.id } })
            }),
    }),
})

export type AppRouter = typeof appRouter

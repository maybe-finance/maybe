import { type Request, Router } from 'express'
import { subject } from '@casl/ability'
import {
    ConversationCreateSchema,
    ConversationUpdateSchema,
    MessageCreateSchema,
    Sandbox,
} from '@maybe-finance/server/features'
import endpoint from '../lib/endpoint'
import { devOnly } from '../middleware'
import multer from 'multer'
import multerS3Storage from '../lib/multerS3Storage'
import env from '../../env'
import logger from '../lib/logger'
import s3 from '../lib/s3'
import { ATAUtil } from '@maybe-finance/shared'
import { GetSecretValueCommand } from '@aws-sdk/client-secrets-manager'

const router = Router()

router.get(
    '/',
    endpoint.create({
        async resolve({ ctx }) {
            return ctx.conversationService.getAll(ctx.user!.id)
        },
    })
)

router.post(
    '/',
    endpoint.create({
        input: ConversationCreateSchema,
        resolve: async ({ input, ctx }) => {
            ctx.ability.throwUnlessCan('create', 'Conversation')

            const { initialMessage, ...conversation } = input

            return ctx.conversationService.create({
                ...conversation,
                userId: ctx.user!.id,
                messages: initialMessage
                    ? {
                          create: {
                              ...initialMessage,
                              userId: ctx.user!.id, // required so audit trigger has access to row-level user_id
                          },
                      }
                    : undefined,
            })
        },
    })
)

router.get(
    '/:id',
    endpoint.create({
        async resolve({ ctx, req }) {
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

            const conversation = await ctx.conversationService.get(+req.params.id, {
                cdnUrl: env.NX_CDN_URL,
                pubKeyId: env.NX_CDN_SIGNER_PUBKEY_ID,
                privKey: privKeyRes.SecretString,
            })

            ctx.ability.throwUnlessCan('read', subject('Conversation', conversation))
            return conversation
        },
    })
)

router.patch(
    '/:id',
    endpoint.create({
        input: ConversationUpdateSchema,
        async resolve({ ctx, req, input }) {
            const conversation = await ctx.conversationService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Conversation', conversation))
            return ctx.conversationService.update(conversation.id, input)
        },
    })
)

router.post(
    '/:id/messages',
    // Uploads message attachments to our S3 CDN storage bucket
    multer({
        storage: multerS3Storage(
            {
                s3,
                getFilename: (req: Request) => {
                    return ATAUtil.generateS3Filename(+req.params.id)
                },
            },
            logger.child({ service: 'MulterS3Storage' })
        ),
        limits: {
            // this is a fallback - size is checked client-side and handled there
            fileSize: 1_000_000 * 10, // 10 MB
            files: 1,
        },
    }).single('attachment'),
    endpoint.create({
        input: MessageCreateSchema,
        async resolve({ ctx, req, input }) {
            const conversation = await ctx.conversationService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Conversation', conversation))

            return ctx.messageService.create(
                {
                    ...input,
                    userId: ctx.user!.id, // required so audit trigger has access to row-level user_id
                    conversationId: conversation.id,
                    mediaSrc: req.file?.path,
                },
                ctx.user!.id !== conversation.userId
            )
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        async resolve({ ctx, req }) {
            const conversation = await ctx.conversationService.get(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('Conversation', conversation))
            return ctx.conversationService.delete(conversation.id)
        },
    })
)

// Endpoint for quickly generating and regenerating conversations to test
router.post(
    '/sandbox',
    devOnly,
    endpoint.create({
        input: Sandbox.SandboxSchema,
        resolve: async ({ ctx, input }) => {
            switch (input.action) {
                case 'assign-advisor':
                    await Sandbox.assignAdvisor(input.conversationId, ctx.prisma)
                    break
                case 'reset':
                    await Sandbox.resetConversations({ ...input, userId: ctx.user!.id }, ctx.prisma)
                    break
            }

            return { action: input.action, success: true }
        },
    })
)

export default router

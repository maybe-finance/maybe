import { z } from 'zod'
import { MessageCreateSchema } from './message.schema'

export const ConversationCreateSchema = z.object({
    title: z.string().min(1),
    status: z.enum(['open', 'closed']).optional(),
    initialMessage: MessageCreateSchema.optional(),
    accountId: z.number().optional(),
    planId: z.number().optional(),
})

export const ConversationUpdateSchema = ConversationCreateSchema.partial()

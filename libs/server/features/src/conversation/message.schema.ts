import { z } from 'zod'

export const MessageCreateSchema = z.object({
    type: z.enum(['text', 'audio', 'video']),
    body: z.string().nullish(),
})

export const MessageUpdateSchema = MessageCreateSchema.partial()

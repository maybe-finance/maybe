import type { MessageSendingResponse } from 'postmark/dist/client/models'
import type { SentMessageInfo } from 'nodemailer'

type EmailCommon = {
    from?: string
    to: string
    replyTo?: string
}

type EmailTemplate = { alias: string; model: Record<string, any> }

type PlainMessageContent = { subject: string; textBody?: string; htmlBody?: string }

export type PlainEmailMessage = EmailCommon & PlainMessageContent
export type TemplateEmailMessage = EmailCommon & { template: EmailTemplate }
export type EmailSendingResponse = MessageSendingResponse | SentMessageInfo

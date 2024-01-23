import type { IEmailProvider } from '../email.service'
import type { Logger } from 'winston'
import type { Message, ServerClient as PostmarkServerClient, TemplatedMessage } from 'postmark'
import type { MessageSendingResponse } from 'postmark/dist/client/models'
import type { SharedType } from '@maybe-finance/shared'
import { chunk, uniq } from 'lodash'
import { EmailTemplateSchema } from '../email.schema'

export class PostmarkEmailProvider implements IEmailProvider {
    constructor(
        private readonly logger: Logger,
        private readonly client: PostmarkServerClient | undefined,
        private readonly defaultAddresses: { from: string; replyTo?: string }
    ) {}

    /**
     * Sends plain email(s)
     *
     * @returns success boolean(s)
     */
    async send(messages: SharedType.PlainEmailMessage): Promise<MessageSendingResponse>
    async send(messages: SharedType.PlainEmailMessage[]): Promise<MessageSendingResponse[]>
    async send(
        messages: SharedType.PlainEmailMessage | SharedType.PlainEmailMessage[]
    ): Promise<MessageSendingResponse | MessageSendingResponse[]> {
        const mapToPostmark = (message: SharedType.PlainEmailMessage): Message => ({
            From: message.from ?? this.defaultAddresses.from,
            ReplyTo: message.replyTo ?? this.defaultAddresses.replyTo,
            To: message.to,
            Subject: message.subject,
            TextBody: message.textBody,
            HtmlBody: message.htmlBody,
        })

        return Array.isArray(messages)
            ? this.sendEmailBatch(messages.map(mapToPostmark))
            : this.sendEmail(mapToPostmark(messages))
    }

    /**
     * Sends template email(s)
     */
    async sendTemplate(messages: SharedType.TemplateEmailMessage): Promise<MessageSendingResponse>
    async sendTemplate(
        messages: SharedType.TemplateEmailMessage[]
    ): Promise<MessageSendingResponse[]>
    async sendTemplate(
        messages: SharedType.TemplateEmailMessage | SharedType.TemplateEmailMessage[]
    ): Promise<MessageSendingResponse | MessageSendingResponse[]> {
        const mapToPostmark = (message: SharedType.TemplateEmailMessage): TemplatedMessage => {
            const { alias, model } = EmailTemplateSchema.parse(message.template)

            return {
                From: message.from ?? this.defaultAddresses.from,
                ReplyTo: message.replyTo ?? this.defaultAddresses.replyTo,
                To: message.to,
                TemplateAlias: alias,
                TemplateModel: model,
            }
        }

        return Array.isArray(messages)
            ? this.sendEmailBatchWithTemplate(messages.map(mapToPostmark))
            : this.sendEmailWithTemplate(mapToPostmark(messages))
    }

    private async sendEmailWithTemplate(
        message: TemplatedMessage
    ): Promise<MessageSendingResponse> {
        this.logger.info(
            `Sending templated email template=${message.TemplateAlias} from=${message.From} to=${message.To}`,
            message.TemplateModel
        )

        if (!this.client) {
            this.logger.info('Postmark API key not provided, skipping email send')
            return undefined as unknown as MessageSendingResponse
        }

        return await this.client.sendEmailWithTemplate(message)
    }

    private async sendEmail(message: Message): Promise<MessageSendingResponse> {
        this.logger.info(
            `Sending plain email subject=${message.Subject} from=${message.From} to=${message.To}`,
            { text: message.TextBody, html: message.HtmlBody }
        )

        if (!this.client) {
            this.logger.info('Postmark API key not provided, skipping email send')
            return undefined as unknown as MessageSendingResponse
        }

        return await this.client.sendEmail(message)
    }

    private async sendEmailBatchWithTemplate(
        messages: TemplatedMessage[]
    ): Promise<MessageSendingResponse[]> {
        this.logger.info(
            `Sending templated email batch templates=[${uniq(
                messages.map(({ TemplateAlias }) => TemplateAlias)
            ).join(',')}] count=${messages.length}`
        )

        return (
            await Promise.all(
                chunk(messages, 500).map((chunk) => {
                    if (!this.client) {
                        this.logger.info('Postmark API key not provided, skipping email send')
                        return [] as MessageSendingResponse[]
                    }
                    return this.client.sendEmailBatchWithTemplates(chunk)
                })
            )
        ).flat()
    }

    private async sendEmailBatch(messages: Message[]): Promise<MessageSendingResponse[]> {
        this.logger.info(
            `Sending templated email batch subjects=[${uniq(
                messages.map(({ Subject }) => Subject)
            ).join(',')}] count=${messages.length}`
        )

        return (
            await Promise.all(
                chunk(messages, 500).map((chunk) => {
                    if (!this.client) {
                        this.logger.info('Postmark API key not provided, skipping email send')
                        return [] as MessageSendingResponse[]
                    }
                    return this.client.sendEmailBatch(chunk)
                })
            )
        ).flat()
    }
}

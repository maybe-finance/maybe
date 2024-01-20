import type { Logger } from 'winston'
import type { ServerClient as PostmarkServerClient } from 'postmark'
import type { MessageSendingResponse } from 'postmark/dist/client/models'
import type { SharedType } from '@maybe-finance/shared'

import { PostmarkEmailProvider } from './providers/postmark.provider'

export interface IEmailProvider {
    send(messages: SharedType.PlainEmailMessage): Promise<SharedType.EmailSendingResponse>
    send(messages: SharedType.PlainEmailMessage[]): Promise<SharedType.EmailSendingResponse[]>
    send(
        messages: SharedType.PlainEmailMessage | SharedType.PlainEmailMessage[]
    ): Promise<any | any[]>
    sendTemplate(
        messages: SharedType.TemplateEmailMessage
    ): Promise<SharedType.EmailSendingResponse>
    sendTemplate(
        messages: SharedType.TemplateEmailMessage[]
    ): Promise<SharedType.EmailSendingResponse[]>
    sendTemplate(
        messages: SharedType.TemplateEmailMessage | SharedType.TemplateEmailMessage[]
    ): Promise<SharedType.EmailSendingResponse | SharedType.EmailSendingResponse[]>
}

export class EmailService implements IEmailProvider {
    private emailProvider: IEmailProvider
    constructor(
        private readonly logger: Logger,
        private readonly client: PostmarkServerClient | undefined,
        private readonly defaultAddresses: { from: string; replyTo?: string }
    ) {
        const provider = process.env.EMAIL_PROVIDER

        switch (provider) {
            case 'postmark':
                this.emailProvider = new PostmarkEmailProvider(
                    this.logger.child({ service: 'PostmarkEmailProvider' }),
                    this.client,
                    this.defaultAddresses
                )
                break
            default:
                throw new Error('Unsupported email provider')
        }
    }

    /**
     * Sends plain email(s)
     *
     * @returns success boolean(s)
     */
    send(messages: SharedType.PlainEmailMessage): Promise<any>
    send(messages: SharedType.PlainEmailMessage[]): Promise<any[]>
    send(
        messages: SharedType.PlainEmailMessage | SharedType.PlainEmailMessage[]
    ): Promise<any | any[]> {
        return this.emailProvider.send(messages)
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
        return this.emailProvider.sendTemplate(messages)
    }
}

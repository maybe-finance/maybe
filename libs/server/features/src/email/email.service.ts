import type { Logger } from 'winston'
import type { ServerClient as PostmarkServerClient } from 'postmark'
import { PostmarkEmailProvider } from './providers'
import type { SharedType } from '@maybe-finance/shared'

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
    private emailProvider: IEmailProvider | undefined
    constructor(
        private readonly logger: Logger,
        private readonly client: PostmarkServerClient | undefined,
        private readonly defaultAddresses: { from: string; replyTo?: string }
    ) {
        const provider = process.env.NX_EMAIL_PROVIDER

        switch (provider) {
            case 'postmark':
                this.emailProvider = new PostmarkEmailProvider(
                    this.logger.child({ service: 'PostmarkEmailProvider' }),
                    this.client,
                    this.defaultAddresses
                )
                break
            default:
                undefined
        }
    }

    /**
     * Sends plain email(s)
     *
     * @returns success boolean(s)
     */
    async send(messages: SharedType.PlainEmailMessage): Promise<SharedType.EmailSendingResponse>
    async send(messages: SharedType.PlainEmailMessage[]): Promise<SharedType.EmailSendingResponse[]>
    async send(
        messages: SharedType.PlainEmailMessage | SharedType.PlainEmailMessage[]
    ): Promise<SharedType.EmailSendingResponse | SharedType.EmailSendingResponse[]> {
        if (!this.emailProvider || !this.client) {
            //no-op
            return undefined as unknown as SharedType.EmailSendingResponse
        }
        return await this.emailProvider.send(messages)
    }

    /**
     * Sends template email(s)
     */
    async sendTemplate(
        messages: SharedType.TemplateEmailMessage
    ): Promise<SharedType.EmailSendingResponse>
    async sendTemplate(
        messages: SharedType.TemplateEmailMessage[]
    ): Promise<SharedType.EmailSendingResponse[]>
    async sendTemplate(
        messages: SharedType.TemplateEmailMessage | SharedType.TemplateEmailMessage[]
    ): Promise<SharedType.EmailSendingResponse | SharedType.EmailSendingResponse[]> {
        if (!this.emailProvider || !this.client) {
            //no-op
            return undefined as unknown as SharedType.EmailSendingResponse
        }
        return this.emailProvider.sendTemplate(messages)
    }
}

import type { IEmailProvider } from '../email.service'
import type { Logger } from 'winston'
import type { SharedType } from '@maybe-finance/shared'
import { chunk, uniq } from 'lodash'
import type { Transporter, SentMessageInfo } from 'nodemailer'

type NodemailerMessage = {
    to: string
    from: string
    replyTo?: string
    sender?: string
    cc?: string
    bcc?: string
    subject: string
    text?: string
    html?: string
}

export class SmtpProvider implements IEmailProvider {
    constructor(
        private readonly logger: Logger,
        private readonly client: Transporter | undefined,
        private readonly defaultAddresses: { from: string; replyTo?: string }
    ) {}

    /**
     * Sends plain email(s)
     *
     * @returns success boolean(s)
     */

    async send(messages: SharedType.PlainEmailMessage): Promise<SentMessageInfo>
    async send(messages: SharedType.PlainEmailMessage[]): Promise<SentMessageInfo>
    async send(
        messages: SharedType.PlainEmailMessage | SharedType.PlainEmailMessage[]
    ): Promise<SentMessageInfo> {
        const mapToNodemailer = (message: SharedType.PlainEmailMessage): NodemailerMessage => ({
            from: message.from ?? this.defaultAddresses.from,
            replyTo: message.replyTo ?? this.defaultAddresses.replyTo,
            to: message.to,
            subject: message.subject,
            text: message.textBody,
            html: message.htmlBody,
        })

        return Array.isArray(messages)
            ? this.sendEmailBatch(messages.map(mapToNodemailer))
            : this.sendEmail(mapToNodemailer(messages))
    }

    private async sendEmail(message: NodemailerMessage): Promise<void> {
        this.logger.info(
            `Sending plain email subject=${message.subject} from=${message.from} to=${message.to}`,
            { text: message.text, html: message.html }
        )

        if (!this.client) {
            this.logger.info('SMTP config not set up, skipping email send')
            return undefined as void
        }

        return await this.client.sendMail(message)
    }

    private async sendEmailBatch(messages: NodemailerMessage[]): Promise<SentMessageInfo[]> {
        this.logger.info(
            `Sending email batch subjects=[${uniq(messages.map(({ subject }) => subject)).join(
                ','
            )}] count=${messages.length}`
        )

        if (!this.client) {
            this.logger.info('SMTP config not set up, skipping email send')
            return [] as SentMessageInfo[]
        }

        return (
            await Promise.all(
                chunk(messages, 500).map((chunk) => {
                    if (!this.client) {
                        this.logger.info('Postmark API key not provided, skipping email send')
                        return [] as SentMessageInfo[]
                    } else {
                        chunk.forEach((message) => {
                            return this.client?.sendMail(message)
                        })
                    }
                })
            )
        ).flat()
    }
}

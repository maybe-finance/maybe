import { ServerClient as PostmarkServerClient } from 'postmark'
import nodemailer from 'nodemailer'
import type SMTPTransport from 'nodemailer/lib/smtp-transport'
import env from '../../env'

export function initializeEmailClient() {
    switch (env.NX_EMAIL_PROVIDER) {
        case 'postmark':
            if (env.NX_EMAIL_PROVIDER_API_TOKEN) {
                return new PostmarkServerClient(env.NX_EMAIL_PROVIDER_API_TOKEN)
            } else {
                return undefined
            }

        case 'smtp':
            if (
                !process.env.NX_EMAIL_SMTP_HOST ||
                !process.env.NX_EMAIL_SMTP_PORT ||
                !process.env.NX_EMAIL_SMTP_USERNAME ||
                !process.env.NX_EMAIL_SMTP_PASSWORD
            ) {
                return undefined
            } else {
                const transportOptions: SMTPTransport.Options = {
                    host: process.env.NX_EMAIL_SMTP_HOST,
                    port: Number(process.env.NX_EMAIL_SMTP_PORT),
                    secure: process.env.NX_EMAIL_SMTP_SECURE === 'true',
                    auth: {
                        user: process.env.NX_EMAIL_SMTP_USERNAME,
                        pass: process.env.NX_EMAIL_SMTP_PASSWORD,
                    },
                }
                return nodemailer.createTransport(transportOptions)
            }
        default:
            return undefined
    }
}

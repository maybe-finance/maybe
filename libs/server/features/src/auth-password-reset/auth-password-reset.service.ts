import type { PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import type { EmailService } from '../email'
import bcrypt from 'bcrypt'

type ResetPasswordData = {
    newPassword: string
    token: string
}

export interface IAuthPasswordResetService {
    create(email: string): Promise<null>
    resetPassword(data: ResetPasswordData): Promise<null>
}

export class AuthPasswordResetsService implements IAuthPasswordResetService {
    constructor(
        private readonly logger: Logger,
        private readonly emailService: EmailService,
        private readonly prisma: PrismaClient
    ) {}

    async create(email: string): Promise<null> {
        const user = await this.prisma.authUser.findUnique({
            where: {
                email,
            },
        })

        if (!user) {
            this.logger.log({
                level: 'info',
                message: `No user found with email ${email}`,
            })

            return null
        }

        const token = crypto.randomUUID()

        await this.prisma.authPasswordResets.create({
            data: {
                token,
                email,
                expires: new Date(Date.now() + 1000 * 60 * 10), // 10 minutes
            },
        })

        await this.emailService.send({
            subject: 'Reset your password',
            to: email,
            // TODO: Use a template
            textBody: `Click here to reset your password: ${process.env.NEXTAUTH_URL}/auth/reset-password?token=${token}&email=${email}`,
        })

        return null
    }

    async resetPassword(data: {
        newPassword: string
        email: string
        token: string
    }): Promise<null> {
        const findResult = await this.prisma.authPasswordResets.findUnique({
            where: {
                token: data.token,
            },
        })

        if (!findResult) {
            throw new Error('Invalid token')
        }

        if (findResult.expires < new Date()) {
            throw new Error('Token expired')
        }

        const user = await this.prisma.authUser.findUnique({
            where: {
                email: data.email,
            },
        })

        if (!user) {
            throw new Error('No user found')
        }

        const hashedPassword = await bcrypt.hash(data.newPassword, 10)

        await this.prisma.authUser.update({
            where: {
                email: data.email,
            },
            data: {
                password: hashedPassword,
            },
        })

        return null
    }
}

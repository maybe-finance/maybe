import type { AuthUser, PrismaClient, Prisma } from '@prisma/client'
import type { Logger } from 'winston'

export interface IAuthUserService {
    get(id: AuthUser['id']): Promise<AuthUser>
    delete(id: AuthUser['id']): Promise<AuthUser>
}

export class AuthUserService implements IAuthUserService {
    constructor(private readonly logger: Logger, private readonly prisma: PrismaClient) {}

    async get(id: AuthUser['id']) {
        return await this.prisma.authUser.findUniqueOrThrow({
            where: { id },
        })
    }

    async getByEmail(email: AuthUser['email']) {
        if (!email) throw new Error('No email provided')
        return await this.prisma.authUser.findUnique({
            where: { email },
        })
    }

    async create(data: Prisma.AuthUserCreateInput) {
        const user = await this.prisma.authUser.create({ data: { ...data } })
        return user
    }

    async delete(id: AuthUser['id']) {
        const authUser = await this.get(id)

        // Delete user from prisma
        this.logger.info(`Removing user ${authUser.id} from Prisma`)
        const user = await this.prisma.authUser.delete({ where: { id } })
        return user
    }
}

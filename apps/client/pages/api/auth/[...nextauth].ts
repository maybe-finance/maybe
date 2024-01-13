import NextAuth from 'next-auth'
import type { SessionStrategy, NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { z } from 'zod'
import { PrismaClient, type Prisma } from '@prisma/client'
import { PrismaAdapter } from '@auth/prisma-adapter'
import bcrypt from 'bcrypt'

let prismaInstance: PrismaClient | null = null

function getPrismaInstance() {
    if (!prismaInstance) {
        prismaInstance = new PrismaClient()
    }
    return prismaInstance
}

const prisma = getPrismaInstance()

async function createAuthUser(
    data: Prisma.AuthUserCreateInput & { firstName: string; lastName: string }
) {
    const authUser = await prisma.authUser.create({ data: { ...data } })
    return authUser
}

async function getAuthUserByEmail(email: string) {
    if (!email) throw new Error('No email provided')
    return await prisma.authUser.findUnique({
        where: { email },
    })
}

const authPrisma = {
    account: prisma.authAccount,
    user: prisma.authUser,
    session: prisma.authSession,
    verificationToken: prisma.authVerificationToken,
} as unknown as PrismaClient

export const authOptions = {
    adapter: PrismaAdapter(authPrisma),
    secret: process.env.NEXTAUTH_SECRET || 'CHANGE_ME',
    pages: {
        signIn: '/login',
    },
    session: {
        strategy: 'jwt' as SessionStrategy,
        maxAge: 1 * 24 * 60 * 60, // 1 Day
    },

    providers: [
        CredentialsProvider({
            name: 'Credentials',
            type: 'credentials',
            credentials: {
                firstName: { label: 'First name', type: 'text', placeholder: 'First name' },
                lastName: { label: 'Last name', type: 'text', placeholder: 'Last name' },
                email: { label: 'Email', type: 'email', placeholder: 'hello@maybe.co' },
                password: { label: 'Password', type: 'password' },
            },
            async authorize(credentials) {
                const parsedCredentials = z
                    .object({
                        firstName: z.string().optional(),
                        lastName: z.string().optional(),
                        email: z.string().email({ message: 'Invalid email address' }),
                        password: z.string().min(6),
                    })
                    .safeParse(credentials)

                if (parsedCredentials.success) {
                    const { firstName, lastName, email, password } = parsedCredentials.data

                    const authUser = await getAuthUserByEmail(email)

                    if (!authUser) {
                        if (!firstName || !lastName)
                            throw new Error(`Could not find an account with that email`)
                        const hashedPassword = await bcrypt.hash(password, 10)
                        const newAuthUser = await createAuthUser({
                            firstName,
                            lastName,
                            name: `${firstName} ${lastName}`,
                            email,
                            password: hashedPassword,
                        })

                        if (newAuthUser) return newAuthUser
                        throw new Error('Could not create user')
                    }

                    const passwordsMatch = await bcrypt.compare(password, authUser.password!)
                    if (passwordsMatch) return authUser
                    throw new Error('Email or password is invalid')
                } else {
                    const errorMessages = parsedCredentials.error.issues.map(
                        (issue) => issue.message
                    )
                    throw new Error(errorMessages.join(', '))
                }
            },
        }),
    ],
    callbacks: {
        async jwt({ token, user: authUser, account }: { token: any; user: any; account: any }) {
            if (authUser && account) {
                token.sub = authUser.id
                token['https://maybe.co/email'] = authUser.email
                token.firstName = authUser.firstName
                token.lastName = authUser.lastName
                token.name = authUser.name
            }
            return token
        },
        async session({ session, token }: { session: any; token: any }) {
            session.user = token.sub
            session.sub = token.sub
            session['https://maybe.co/email'] = token['https://maybe.co/email']
            session.firstName = token.firstName
            session.lastName = token.lastName
            session.name = token.name
            return session
        },
    },
} as NextAuthOptions

export default NextAuth(authOptions)

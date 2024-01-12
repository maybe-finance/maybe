import NextAuth, { type SessionStrategy } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { z } from 'zod'
import { PrismaClient } from '@prisma/client'
import { PrismaAdapter } from '@auth/prisma-adapter'
import axios from 'axios'
import bcrypt from 'bcrypt'

const prisma = new PrismaClient()
axios.defaults.baseURL = `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333'}/v1`

const authPrisma = {
    account: prisma.authAccount,
    user: prisma.authUser,
    session: prisma.authSession,
    verificationToken: prisma.authVerificationToken,
} as unknown as PrismaClient

export const authOptions = {
    adapter: PrismaAdapter(authPrisma),
    secret: process.env.AUTH_SECRET || 'CHANGE_ME',
    pages: {
        signIn: '/login',
    },
    session: {
        strategy: 'jwt' as SessionStrategy,
        maxAge: 7 * 24 * 60 * 60, // 7 Days
    },
    providers: [
        CredentialsProvider({
            name: 'Credentials',
            type: 'credentials',
            credentials: {
                email: { label: 'Email', type: 'email', placeholder: 'hello@maybe.co' },
                password: { label: 'Password', type: 'password' },
            },
            async authorize(credentials) {
                const parsedCredentials = z
                    .object({
                        name: z.string().optional(),
                        email: z.string().email(),
                        password: z.string().min(6),
                    })
                    .safeParse(credentials)

                if (parsedCredentials.success) {
                    const { name, email, password } = parsedCredentials.data

                    const { data } = await axios.get(`/auth-users`, {
                        params: { email: email },
                        headers: { 'Content-Type': 'application/json' },
                    })

                    // TODO: use superjson to parse this more cleanly
                    const user = data.data['json']

                    if (!user) {
                        const hashedPassword = await bcrypt.hash(password, 10)
                        const { data } = await axios.post('/auth-users', {
                            name,
                            email,
                            password: hashedPassword,
                        })
                        const newUser = data.data['json']
                        if (newUser) return newUser
                        throw new Error('Could not create user')
                    }

                    const passwordsMatch = await bcrypt.compare(password, user.password)
                    if (passwordsMatch) return user
                }

                return null
            },
        }),
    ],
}

export default NextAuth(authOptions)

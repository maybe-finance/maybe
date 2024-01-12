import NextAuth from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { z } from 'zod'
import type { SharedType } from '@maybe-finance/shared'
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
    providers: [
        CredentialsProvider({
            name: 'Credentials',
            type: 'credentials',
            credentials: {
                email: { label: 'Email', type: 'email', placeholder: 'hello@maybe.co' },
                password: { label: 'Password', type: 'password' },
            },
            async authorize(credentials) {
                console.log('inside the authorize method')
                const parsedCredentials = z
                    .object({
                        email: z.string().email(),
                        password: z.string().min(6),
                        provider: z.string().optional(),
                    })
                    .safeParse(credentials)

                if (parsedCredentials.success) {
                    console.log("Credentials are valid, let's authorize")
                    const { email, password } = parsedCredentials.data
                    console.log('Here are the params', email, password)
                    const { data } = await axios.get(`/auth-users`, {
                        params: { email: email },
                        headers: { 'Content-Type': 'application/json' },
                    })

                    const user = data.data['json']

                    console.log('This is User', user)

                    if (!user.id) {
                        console.log('User does not exist, creating new user')
                        const hashedPassword = await bcrypt.hash(password, 10)
                        const { data: newUser } = await axios.post<SharedType.AuthUser>(
                            '/auth-users',
                            {
                                email,
                                password: hashedPassword,
                            }
                        )
                        console.log('Created new user', newUser)
                        if (newUser) return newUser
                        throw new Error('Could not create user')
                    }

                    const passwordsMatch = await bcrypt.compare(password, user.password)
                    if (passwordsMatch) return user
                }

                console.log('Invalid credentials')
                return null
            },
        }),
    ],
}

export default NextAuth(authOptions)

import { PrismaClient } from '@prisma/client'
import crypto from 'crypto'
import type { NextApiRequest, NextApiResponse } from 'next'

let prismaInstance: PrismaClient | null = null

function getPrismaInstance() {
    if (!prismaInstance) {
        prismaInstance = new PrismaClient()
    }
    return prismaInstance
}

const prisma = getPrismaInstance()

type ResponseData = {
    message: string
}

export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
    if (!req.body.email) {
        res.status(400).json({ message: 'No email provided.' })
        return
    }

    const user = await prisma.authUser.findUnique({
        where: {
            email: req.body.email,
        },
    })

    if (!user) {
        // No user found, we don't want to expose this information
        return res.status(200).json({ message: 'OK' })
    }

    const token = crypto.randomBytes(32).toString('hex')
    await prisma.authPasswordResets.create({
        data: {
            token,
            email: req.body.email,
            expires: new Date(Date.now() + 1000 * 60 * 10), // 10 minutes
        },
    })

    // 2. Send a password reset email

    res.status(200).json({ message: 'Hello from Next.js!' })
}

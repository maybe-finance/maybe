import cookieParser from 'cookie-parser'
import { decode } from 'next-auth/jwt'
import type { Request } from 'express'

const SECRET = process.env.NEXTAUTH_SECRET ?? 'REPLACE_THIS'

const getNextAuthCookie = (req: Request) => {
    if (req.cookies) {
        if ('__Secure-next-auth.session-token' in req.cookies) {
            return req.cookies['__Secure-next-auth.session-token']
        } else if ('next-auth.session-token' in req.cookies) {
            return req.cookies['next-auth.session-token']
        }
    }
    return undefined
}

export const validateAuthJwt = async (req, res, next) => {
    cookieParser(SECRET)(req, res, async (err) => {
        if (err) {
            return res.status(500).json({ message: 'Internal Server Error' })
        }

        if (req.cookies && getNextAuthCookie(req)) {
            try {
                const token = await decode({
                    token: getNextAuthCookie(req),
                    secret: SECRET,
                })

                if (token) {
                    req.user = token
                    return next()
                } else {
                    return res.status(401).json({ message: 'Unauthorized' })
                }
            } catch (error) {
                console.error('Error in token validation', error)
                return res.status(500).json({ message: 'Internal Server Error' })
            }
        } else if (req.headers.authorization) {
            const token = req.headers.authorization.split(' ')[1]
            const decoded = await decode({
                token,
                secret: SECRET,
            })
            if (decoded) {
                req.user = decoded
                return next()
            } else {
                return res.status(401).json({ message: 'Unauthorized' })
            }
        } else {
            return res.status(401).json({ message: 'Unauthorized' })
        }
    })
}

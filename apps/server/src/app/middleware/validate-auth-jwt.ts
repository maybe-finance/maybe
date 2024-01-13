import cookieParser from 'cookie-parser'
import { decode } from 'next-auth/jwt'

const SECRET = process.env.NEXTAUTH_SECRET ?? 'REPLACE_THIS'

export const validateAuthJwt = async (req, res, next) => {
    cookieParser(SECRET)(req, res, async (err) => {
        if (err) {
            return res.status(500).json({ message: 'Internal Server Error' })
        }

        if (req.cookies && 'next-auth.session-token' in req.cookies) {
            try {
                const token = await decode({
                    token: req.cookies['next-auth.session-token'],
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
        } else {
            return res.status(401).json({ message: 'Unauthorized' })
        }
    })
}

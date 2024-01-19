import cookieParser from 'cookie-parser'
import { decode } from 'next-auth/jwt'

const SECRET = process.env.NEXTAUTH_SECRET ?? 'REPLACE_THIS'
export const validateAuthJwt = async (req, res, next) => {
    cookieParser(SECRET)(req, res, async (err) => {
        if (err) {
            return res.status(500).json({ message: 'Internal Server Error' })
        }

        const cookieName = req.secure
            ? '__Secure-next-auth.session-token'
            : 'next-auth.session-token'

        if (req.cookies && cookieName in req.cookies) {
            try {
                const token = await decode({
                    token: req.cookies[cookieName],
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

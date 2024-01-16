import type { NextApiRequest, NextApiResponse } from 'next'

type ResponseData = {
    message: string
}

export default function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
    // TODO: implement password reset functionality

    // 1. Generate a password reset token
    // 2. Send a password reset email
    // 3. Redirect to a password reset page
    // 4. Verify the password reset token
    // 5. Reset the password
    // 6. Redirect to the login page
    // 7. Login with the new password

    res.status(200).json({ message: 'Hello from Next.js!' })
}

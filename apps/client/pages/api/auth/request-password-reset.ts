import type { NextApiResponse } from 'next'
import type { NextRequest } from 'next/server'
import env from '../../../env'

export default async function handler(req: NextRequest, res: NextApiResponse) {
    const r = await fetch(`${env.NEXT_PUBLIC_API_URL}/v1/request-new-password`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(req.body),
    })

    return res.status(200).json(await r.json())
}

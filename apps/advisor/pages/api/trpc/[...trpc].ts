import { getAccessToken, withApiAuthRequired } from '@auth0/nextjs-auth0'

const API_URL = process.env.API_URL || 'http://localhost:3333'

export default withApiAuthRequired(async function trpc(req, res) {
    const { accessToken } = await getAccessToken(req, res)
    if (!accessToken) {
        throw new Error(`failed to get access token`)
    }

    // construct tRPC request URL (/api/trpc/xyz -> {API_URL}/trpc/xyz)
    const url = new URL(req.url!.replace(/^\/api\//i, ''), API_URL)

    const response = await fetch(url, {
        method: req.method,
        body: req.method === 'POST' ? JSON.stringify(req.body) : null, // tRPC only uses GET|POST
        headers: {
            accept: 'application/json',
            'content-type': 'application/json',
            authorization: `Bearer ${accessToken}`,
        },
    })

    return res.status(response.status).json(await response.json())
})

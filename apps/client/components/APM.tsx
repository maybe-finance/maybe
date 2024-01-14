import { useEffect } from 'react'
import * as Sentry from '@sentry/react'
import { useSession } from 'next-auth/react'

export default function APM() {
    const { data: session } = useSession()

    // Identify Sentry user
    useEffect(() => {
        if (session && session.user) {
            Sentry.setUser({
                id: session.user['sub'] ?? undefined,
                email: session.user['https://maybe.co'] ?? undefined,
            })
        }
    }, [session])

    return null
}

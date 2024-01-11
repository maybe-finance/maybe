import { useAuth0 } from '@auth0/auth0-react'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import * as Sentry from '@sentry/react'

export default function APM() {
    const { user } = useAuth0()
    const router = useRouter()

    // Identify Sentry user
    useEffect(() => {
        if (user) {
            Sentry.setUser({
                id: user.sub,
                email: user.email,
            })
        }
    }, [user])

    return null
}

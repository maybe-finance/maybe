import { useAuth0 } from '@auth0/auth0-react'
import { useIntercom } from '@maybe-finance/client/shared'
import { useLDClient } from 'launchdarkly-react-client-sdk'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import * as Sentry from '@sentry/react'

export default function APM() {
    const { user } = useAuth0()
    const router = useRouter()
    const ld = useLDClient()
    const intercom = useIntercom()

    // Boot intercom
    useEffect(() => {
        const isBooted = intercom.boot()

        const handleRouteChange = () => {
            if (isBooted) {
                intercom.update()
            }
        }

        router.events.on('routeChangeComplete', handleRouteChange)

        return () => router.events.off('routeChangeComplete', handleRouteChange)
    }, [intercom, router.events])

    // Identify Sentry user
    useEffect(() => {
        if (user) {
            Sentry.setUser({
                id: user.sub,
                email: user.email,
            })
        }
    }, [user])

    // Identify LaunchDarkly user
    useEffect(() => {
        if (ld && user) {
            ld.waitUntilReady().then(() => {
                ld.identify({
                    key: user.sub,
                    email: user.email,
                    name: user.name,
                })
            })
        }
    }, [ld, user])

    return null
}

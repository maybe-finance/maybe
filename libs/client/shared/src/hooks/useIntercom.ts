import { useCallback } from 'react'
import { useAuth0 } from '@auth0/auth0-react'
import type { SharedType } from '@maybe-finance/shared'
import { useUserApi } from '../api'
import { BrowserUtil } from '..'

export function useIntercom() {
    const { user, isAuthenticated } = useAuth0<SharedType.Auth0ReactUser>()

    const { useIntercomMetadata } = useUserApi()
    const { data: intercomMetadata } = useIntercomMetadata({ enabled: isAuthenticated })

    const boot = useCallback(
        (data?: BrowserUtil.IntercomData) => {
            if (!user?.sub || !intercomMetadata?.hash) return false

            BrowserUtil.bootIntercom({
                user_id: user.sub,
                user_hash: intercomMetadata.hash,
                email: user.email,
                name: user.name,
                last_request_at: Math.floor(new Date().getTime() / 1000),
                ...data,
            })

            return true
        },
        [user, intercomMetadata]
    )

    const update = useCallback(
        (data?: BrowserUtil.IntercomData, updateLastRequestAt = true) => {
            if (!user?.sub || !intercomMetadata?.hash) return

            BrowserUtil.updateIntercom({
                user_id: user.sub,
                user_hash: intercomMetadata.hash,
                email: user.email,
                name: user.name,
                last_request_at: updateLastRequestAt
                    ? Math.floor(new Date().getTime() / 1000)
                    : undefined,
                ...data,
            })
        },
        [user, intercomMetadata]
    )

    return { boot, update }
}

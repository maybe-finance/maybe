import { signOut } from 'next-auth/react'
import { MainContentOverlay, useUserApi } from '@maybe-finance/client/shared'
import { LoadingSpinner } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { useRouter } from 'next/router'
import type { PropsWithChildren } from 'react'

function shouldRedirect(path: string, data?: SharedType.UserSubscription) {
    if (!data || data?.subscribed) return false

    // Redirect to upgrade for all paths except /accounts, /onboarding, /upgrade, and /settings
    if (
        !['/accounts', '/upgrade'].includes(path) &&
        !path.startsWith('/settings') &&
        !path.startsWith('/onboarding')
    ) {
        return true
    }

    return false
}

export function SubscriberGuard({ children }: PropsWithChildren) {
    const router = useRouter()
    const { useSubscription } = useUserApi()
    const subscription = useSubscription()

    if (subscription.isError) {
        return (
            <MainContentOverlay
                title="Unable to load subscription"
                actionText="Log out"
                onAction={() => signOut()}
            >
                <p>Contact us if this issue persists.</p>
            </MainContentOverlay>
        )
    }

    if (subscription.isLoading || shouldRedirect(router.asPath, subscription.data)) {
        return (
            <div className="absolute inset-0 flex items-center justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    // eslint-disable-next-line react/jsx-no-useless-fragment
    return <>{children}</>
}

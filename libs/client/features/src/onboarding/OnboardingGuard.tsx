import type { PropsWithChildren } from 'react'
import { MainContentOverlay, useUserApi } from '@maybe-finance/client/shared'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { useRouter } from 'next/router'
import type { SharedType } from '@maybe-finance/shared'
import { signOut } from 'next-auth/react'

function shouldRedirect(pathname: string, data?: SharedType.OnboardingResponse) {
    if (!data) return false
    if (pathname === '/onboarding') return false
    const isOnboardingComplete = data.isComplete || data.isMarkedComplete
    return !isOnboardingComplete
}

export function OnboardingGuard({ children }: PropsWithChildren) {
    const router = useRouter()
    const { useOnboarding } = useUserApi()
    const onboarding = useOnboarding('main', {
        onSuccess(data) {
            if (shouldRedirect(router.pathname, data)) {
                router.replace('/onboarding')
            }
        },
    })

    if (onboarding.isError) {
        return (
            <MainContentOverlay
                title="Unable to load onboarding"
                actionText="Logout"
                onAction={() => signOut()}
            >
                <p>Contact us if this issue persists.</p>
            </MainContentOverlay>
        )
    }

    if (onboarding.isLoading || shouldRedirect(router.pathname, onboarding.data)) {
        return (
            <div className="absolute inset-0 flex items-center justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    // eslint-disable-next-line react/jsx-no-useless-fragment
    return <>{children}</>
}

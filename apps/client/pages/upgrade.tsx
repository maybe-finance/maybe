import { UpgradeTakeover } from '@maybe-finance/client/features'
import { useUserApi } from '@maybe-finance/client/shared'
import { useRouter } from 'next/router'

export default function UpgradePage() {
    const router = useRouter()

    const { useSubscription } = useUserApi()
    const subscription = useSubscription()

    return (
        <UpgradeTakeover
            open
            onClose={() =>
                router.push(
                    !subscription.data || subscription.data?.subscribed
                        ? '/'
                        : '/settings?tab=billing'
                )
            }
        />
    )
}

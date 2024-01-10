import Link from 'next/link'
import { RiDraftLine } from 'react-icons/ri'
import { Button } from '@maybe-finance/design-system'
import { BlurredContentOverlay, useUserApi } from '@maybe-finance/client/shared'
import { useRouter } from 'next/router'

export function OnboardingOverlay() {
    const router = useRouter()
    const { useProfile, useSubscription } = useUserApi()

    const userProfile = useProfile()
    const subscription = useSubscription()

    const requiresOnboarding =
        !userProfile.isLoading &&
        (!userProfile.data?.goals.length || !userProfile.data?.riskAnswers.length)

    return requiresOnboarding && subscription.data?.subscribed ? (
        <BlurredContentOverlay icon={RiDraftLine} title="Before you ask an advisor">
            <p>
                We need to ask a few questions to get context around your goals and risk tolerance,
                both of which help our advisors give you the best advice. It'll take less than 60
                seconds.
            </p>
            <Link
                href={{ pathname: '/ask-the-advisor/questionnaire', query: { r: router.asPath } }}
                passHref
            >
                <Button className="w-full mt-6">Get started</Button>
            </Link>
        </BlurredContentOverlay>
    ) : null
}

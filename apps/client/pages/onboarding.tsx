import type { ReactElement } from 'react'
import { Transition } from '@headlessui/react'
import {
    AddFirstAccount,
    EmailVerification,
    FullPageLayout,
    Intro,
    OtherAccounts,
    Profile,
    OnboardingNavbar,
    Terms,
    Welcome,
    YourMaybe,
    OnboardingBackground,
    type StepProps,
} from '@maybe-finance/client/features'
import { MainContentOverlay, useQueryParam, useUserApi } from '@maybe-finance/client/shared'
import { LoadingSpinner } from '@maybe-finance/design-system'
import classNames from 'classnames'
import { useRouter } from 'next/router'

function getStepComponent(stepKey?: string): (props: StepProps) => JSX.Element {
    switch (stepKey) {
        case 'profile':
            return Profile
        case 'verifyEmail':
            return EmailVerification
        case 'firstAccount':
            return AddFirstAccount
        case 'accountSelection':
            return OtherAccounts
        case 'terms':
            return Terms
        case 'maybe':
            return YourMaybe
        case 'welcome':
            return Welcome
        case 'intro':
        default:
            return Intro
    }
}

export default function OnboardingPage() {
    const router = useRouter()
    const { useOnboarding, useUpdateOnboarding } = useUserApi()

    const stepParam = useQueryParam('step', 'string')

    const onboarding = useOnboarding('main', {
        onSuccess: (flow) => {
            if (!stepParam) {
                if (flow.currentStep) {
                    router.push({
                        pathname: '/onboarding',
                        query: { step: flow.currentStep.key },
                    })
                } else {
                    router.push('/')
                }
            }
        },
    })

    const updateOnboarding = useUpdateOnboarding()

    if (onboarding.isLoading || !stepParam) {
        return (
            <div className="absolute inset-0 flex items-center justify-center h-full">
                <LoadingSpinner />
            </div>
        )
    }

    if (onboarding.isError) {
        return (
            <MainContentOverlay
                title="Unable to load onboarding flow"
                actionText="Try again"
                onAction={() => window.location.reload()}
            >
                <p>Contact us if this issue persists.</p>
            </MainContentOverlay>
        )
    }

    const { steps } = onboarding.data
    const currentStep = steps.find((step) => step.key === stepParam)
    const currentStepIdx = steps.findIndex((step) => step.key === stepParam)
    const StepComponent = getStepComponent(stepParam)

    if (!currentStep) throw new Error('Could not load onboarding')

    async function prev() {
        if (currentStepIdx > 0) {
            router.push({ pathname: '/onboarding', query: { step: steps[currentStepIdx - 1].key } })
        }
    }

    async function next() {
        await updateOnboarding.mutateAsync({
            flow: 'main',
            updates: [{ key: currentStep!.key, markedComplete: true }],
        })

        if (currentStepIdx < steps.length - 1) {
            router.push({ pathname: '/onboarding', query: { step: steps[currentStepIdx + 1].key } })
        } else {
            router.push('/')
        }
    }

    return (
        <>
            <div className="fixed inset-0 z-auto overflow-hidden">
                <OnboardingBackground className="absolute -bottom-3 left-1/2 -translate-x-1/2" />
            </div>

            {currentStep.group && currentStep.group !== 'account' && (
                <OnboardingNavbar steps={steps} currentStep={currentStep} onBack={prev} />
            )}

            <Transition
                key={currentStep.key}
                className={classNames('px-6 mb-20 grow')}
                appear
                show
                enter="ease-in duration-100"
                enterFrom="opacity-0 translate-y-8"
                enterTo="opacity-100 translate-y-0"
                leave="ease-in duration-100"
                leaveFrom="opacity-100 translate-y-0"
                leaveTo="opacity-0 translate-y-8"
            >
                <StepComponent title={currentStep.title} onNext={next} onPrev={prev} />
            </Transition>
        </>
    )
}

OnboardingPage.getLayout = function getLayout(page: ReactElement) {
    return <FullPageLayout>{page}</FullPageLayout>
}

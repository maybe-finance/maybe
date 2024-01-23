import { Checkbox } from '@maybe-finance/design-system'
import { DateUtil, type SharedType } from '@maybe-finance/shared'

type UserDevToolsProps = {
    isAdmin: boolean
    setIsAdmin: (isAdmin: boolean) => void
    isOnboarded: boolean
    setIsOnboarded: (isOnboarded: boolean) => void
}

export function UserDevTools({
    isAdmin,
    setIsAdmin,
    isOnboarded,
    setIsOnboarded,
}: UserDevToolsProps) {
    return process.env.NODE_ENV === 'development' ? (
        <div className="my-2 p-2 border border-red-300 rounded-md">
            <h6 className="flex text-red">
                Dev Tools <i className="ri-tools-fill ml-1.5" />
            </h6>
            <p className="text-sm my-2">
                This section will NOT show in production and is solely for making testing easier.
            </p>

            <div className="flex flex-col">
                <Checkbox checked={isAdmin} onChange={setIsAdmin} label="Admin user" />
                <Checkbox checked={isOnboarded} onChange={setIsOnboarded} label="Onboarded user" />
            </div>
        </div>
    ) : null
}

interface OnboardingType {
    flow: SharedType.OnboardingFlow
    updates: { key: string; markedComplete: boolean }[]
    markedComplete?: boolean
}

export const completedOnboarding: OnboardingType = {
    flow: 'main',
    updates: [
        {
            key: 'intro',
            markedComplete: true,
        },
        {
            key: 'profile',
            markedComplete: true,
        },
        {
            key: 'firstAccount',
            markedComplete: true,
        },
        {
            key: 'accountSelection',
            markedComplete: true,
        },
        {
            key: 'maybe',
            markedComplete: true,
        },
        {
            key: 'welcome',
            markedComplete: true,
        },
    ],
}

export const onboardedProfile: SharedType.UpdateUser = {
    dob: DateUtil.dateTransform(new Date('2000-01-01')),
    household: 'single',
    country: 'US',
}

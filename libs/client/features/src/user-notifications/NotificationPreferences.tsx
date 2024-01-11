import { useUserApi } from '@maybe-finance/client/shared'

export function GeneralPreferences() {
    const { useProfile } = useUserApi()

    const userProfile = useProfile()

    if (!userProfile.data) {
        return null
    }

    return (
        <>
            <h4 className="mb-2 text-lg uppercase mt-8 mb-2">Ask the advisor</h4>

            {/* TODO: Update notifications or remove */}
            <div className="space-y-4"></div>
        </>
    )
}

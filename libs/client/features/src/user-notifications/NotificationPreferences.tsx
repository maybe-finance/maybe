import { useNotificationsApi, useUserApi } from '@maybe-finance/client/shared'
import { Toggle } from '@maybe-finance/design-system'

type PreferenceProps = {
    title: string
    description: string
    enabled: boolean
    onChange(enabled: boolean): void
}
function Preference({ title, description, enabled, onChange }: PreferenceProps) {
    return (
        <div className="flex items-center justify-between">
            <div className="mr-6">
                <p>{title}</p>
                <p className="text-gray-100">{description}</p>
            </div>
            <Toggle checked={enabled} screenReaderLabel={title} onChange={onChange} size="small" />
        </div>
    )
}

export function GeneralPreferences() {
    const { useProfile } = useUserApi()
    const { useUpdateATANotifications } = useNotificationsApi()

    const userProfile = useProfile()
    const updateAta = useUpdateATANotifications()

    if (!userProfile.data) {
        return null
    }

    return (
        <>
            <h4 className="mb-2 text-lg uppercase mt-8 mb-2">Ask the advisor</h4>

            <div className="space-y-4">
                <Preference
                    title="All updates"
                    description="You'll be notified for every update in your question"
                    enabled={userProfile.data.ataAll}
                    onChange={(isEnabled) => {
                        updateAta.mutate({
                            ataAll: isEnabled,
                        })
                    }}
                />

                <Preference
                    title="Question has been submitted"
                    description="You'll be notified when your question has been submitted"
                    enabled={userProfile.data.ataSubmitted}
                    onChange={(isEnabled) => {
                        updateAta.mutate({
                            ataSubmitted: isEnabled,
                        })
                    }}
                />

                <Preference
                    title="Question has been reviewed by advisor"
                    description="You'll be notified once the advisor has seen your message and is working on a response"
                    enabled={userProfile.data.ataReview}
                    onChange={(isEnabled) => {
                        updateAta.mutate({
                            ataReview: isEnabled,
                        })
                    }}
                />

                <Preference
                    title="Thread updated with answer"
                    description="You'll be notified once the advisor has replied with an answer"
                    enabled={userProfile.data.ataUpdate}
                    onChange={(isEnabled) => {
                        updateAta.mutate({
                            ataUpdate: isEnabled,
                        })
                    }}
                />

                <Preference
                    title="Thread marked as complete"
                    description="You'll be notified when the thread has been marked as complete"
                    enabled={userProfile.data.ataClosed}
                    onChange={(isEnabled) => {
                        updateAta.mutate({
                            ataClosed: isEnabled,
                        })
                    }}
                />

                <Preference
                    title="Thread expiry"
                    description="You’ll be notified when the question thread is going to expire if not marked as complete yet."
                    enabled={userProfile.data.ataExpire}
                    onChange={(isEnabled) => {
                        updateAta.mutate({
                            ataExpire: isEnabled,
                        })
                    }}
                />
            </div>
        </>
    )
}

import { useConversationApi, useUserApi } from '@maybe-finance/client/shared'

export function DevOnlyMenu() {
    const { useSendAgreementsEmail } = useUserApi()
    const updateAgreements = useSendAgreementsEmail()

    const { useSandbox } = useConversationApi()
    const sandbox = useSandbox()

    return (
        <div className="bg-gray-700 rounded-lg p-4 space-y-4">
            <p className="text-red">Dev only menu</p>
            <div className="flex items-center gap-4">
                <button
                    className="underline text-red"
                    onClick={() => {
                        sandbox.mutate({ action: 'reset' })
                    }}
                >
                    Reset
                </button>
                <button
                    className="underline text-red"
                    onClick={() => {
                        updateAgreements.mutate({})
                    }}
                >
                    Send agreement update emails
                </button>
            </div>
        </div>
    )
}

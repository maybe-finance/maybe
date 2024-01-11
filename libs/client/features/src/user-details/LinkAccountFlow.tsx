import { useAuth0 } from '@auth0/auth0-react'
import { BoxIcon, linkAuth0AccountCtx, useUserApi } from '@maybe-finance/client/shared'
import { Button, DialogV2 } from '@maybe-finance/design-system'
import { useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { RiAppleFill, RiCheckLine, RiLink, RiLinkUnlink, RiLoader4Fill } from 'react-icons/ri'

type Props = {
    secondaryProvider: string
    isOpen: boolean
    onClose(): void
}

const steps = ['authenticate', 'confirm', 'complete']

export function LinkAccountFlow({ secondaryProvider, isOpen, onClose }: Props) {
    const queryClient = useQueryClient()

    const secondaryAuth0 = useAuth0(linkAuth0AccountCtx)

    const [stepIdx, setStepIdx] = useState(0)
    const [error, setError] = useState<string | null>(null)

    const { useLinkAccounts } = useUserApi()
    const linkAccounts = useLinkAccounts({
        onSettled() {
            queryClient.invalidateQueries(['users', 'auth0-profile'])
        },
        onSuccess() {
            setStepIdx((prev) => prev + 1)
        },
        onError(err) {
            setError(
                err instanceof Error ? err.message : 'Something went wrong while linking accounts'
            )
        },
    })

    const { useUpdateProfile } = useUserApi()
    const updateUser = useUpdateProfile({
        onSettled: () => queryClient.invalidateQueries(['users', 'auth0-profile']),
        onSuccess: undefined,
    })

    function completeFlow() {
        updateUser.mutate({ linkAccountDismissedAt: new Date() })
        setError(null)
        setStepIdx(0)
        onClose()
    }

    return (
        <DialogV2
            open={isOpen}
            className="flex flex-col items-center text-center"
            onClose={completeFlow}
        >
            {error ? (
                <LinkError onClose={completeFlow} error={error} />
            ) : (
                (function () {
                    switch (steps[stepIdx]) {
                        case 'authenticate':
                            return (
                                <PromptStep
                                    secondaryProvider={secondaryProvider}
                                    onCancel={completeFlow}
                                    onNext={async () => {
                                        await secondaryAuth0.loginWithPopup({
                                            authorizationParams: {
                                                connection:
                                                    secondaryProvider === 'apple'
                                                        ? 'apple'
                                                        : 'Username-Password-Authentication',
                                                screen_hint:
                                                    secondaryProvider !== 'apple'
                                                        ? 'show-form-only'
                                                        : undefined,
                                                max_age: 0,
                                                display: 'page',
                                            },
                                        })

                                        setStepIdx((prev) => prev + 1)
                                    }}
                                />
                            )
                        case 'confirm':
                            return (
                                <ConfirmStep
                                    onCancel={completeFlow}
                                    onNext={async () => {
                                        const token = await secondaryAuth0.getAccessTokenSilently()

                                        linkAccounts.mutate({
                                            secondaryJWT: token,
                                            secondaryProvider,
                                        })
                                    }}
                                    isLoading={linkAccounts.isLoading}
                                    isReady={secondaryAuth0.isAuthenticated}
                                />
                            )
                        case 'complete':
                            return <LinkComplete onClose={completeFlow} />
                        default:
                            return null
                    }
                })()
            )}
        </DialogV2>
    )
}

type StepProps = {
    onCancel(): void
    onNext(): void
}

function PromptStep({
    secondaryProvider,
    onCancel,
    onNext,
}: StepProps & { secondaryProvider: string }) {
    return (
        <>
            <BoxIcon icon={RiLink} />

            <h4 className="text-white mt-6 mb-2">Link accounts?</h4>

            <p className="mb-6 text-gray-50 text-base">
                We found an {secondaryProvider === 'apple' ? 'Apple ' : ' '} account using the same
                email address as this one in our system. Do you want to link it?
            </p>

            <div className="flex w-full gap-4">
                <Button className="w-2/4" variant="secondary" onClick={onCancel}>
                    Close
                </Button>
                {secondaryProvider === 'apple' ? (
                    <button
                        onClick={onNext}
                        className="w-2/4 flex items-center px-4 py-2 rounded text-base bg-white text-black shadow hover:bg-gray-25 focus:bg-gray-25 focus:ring-gray-600 font-medium"
                    >
                        <RiAppleFill className="w-4 h-4 mx-2" /> Link with Apple
                    </button>
                ) : (
                    <Button className="w-2/4" onClick={onNext}>
                        Link accounts
                    </Button>
                )}
            </div>
        </>
    )
}

function ConfirmStep({
    isLoading,
    isReady,
    onCancel,
    onNext,
}: StepProps & { isLoading: boolean; isReady: boolean }) {
    if (!isReady) {
        return (
            <>
                <BoxIcon icon={RiLink} />

                <h4 className="text-white my-6 animate-pulse">Authentication in progress...</h4>

                <Button fullWidth variant="secondary" onClick={onCancel}>
                    Cancel
                </Button>
            </>
        )
    }

    return (
        <>
            <BoxIcon icon={isLoading ? RiLinkUnlink : RiLink} />

            <h4 className="text-white mt-6 mb-2">
                {isLoading ? 'Linking accounts ...' : 'Continue linking accounts?'}
            </h4>

            <div className="mb-6 text-base">
                {isLoading ? (
                    <p className="text-gray-50">
                        Your accounts are being linked and data is being merged. This may take a few
                        seconds.
                    </p>
                ) : (
                    <>
                        <p className="text-gray-50">
                            After linking, both logins will use the data in{' '}
                            <span className="text-white">the current</span> account. Any data you
                            have in your secondary account will be archived and no longer available
                            to you. If you ever wish to recover that data, you can reverse this
                            process by unlinking the account in your settings.{' '}
                        </p>

                        <p className="text-white mt-4">No data will be deleted.</p>
                    </>
                )}
            </div>

            <div className="flex w-full gap-4">
                <Button
                    className="w-2/4"
                    variant="secondary"
                    onClick={onCancel}
                    disabled={isLoading}
                >
                    Don't link
                </Button>

                <Button className="w-2/4" onClick={onNext} disabled={isLoading}>
                    {isLoading && (
                        <RiLoader4Fill className="w-4 h-4 mr-2 text-gray-200 animate-spin" />
                    )}
                    {isLoading ? 'Linking...' : 'Continue'}
                </Button>
            </div>
        </>
    )
}

function LinkComplete({ onClose }: { onClose(): void }) {
    return (
        <>
            <BoxIcon icon={RiCheckLine} variant="teal" />

            <h4 className="text-white mt-6 mb-2">Accounts linked successfully!</h4>

            <p className="mb-6 text-gray-50 text-base">
                Your accounts have been linked and the data has been merged successfully.
            </p>

            <div className="flex w-full gap-4">
                <Button fullWidth onClick={onClose}>
                    Done
                </Button>
            </div>
        </>
    )
}

function LinkError({ onClose, error }: { onClose(): void; error: string }) {
    return (
        <>
            <BoxIcon icon={RiLink} variant="red" />

            <h4 className="text-white mt-6 mb-2">Account linking failed</h4>

            <p className="mb-2 text-gray-50 text-base">{error}</p>

            <a className="underline text-cyan text-base mb-6" href="mailto:hello@maybe.co">
                Please contact us.
            </a>

            <div className="flex w-full gap-4">
                <Button fullWidth onClick={onClose}>
                    Close
                </Button>
            </div>
        </>
    )
}

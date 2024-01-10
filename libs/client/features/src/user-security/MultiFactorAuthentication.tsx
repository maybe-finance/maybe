import type { SharedType } from '@maybe-finance/shared'
import { useAuth0 } from '@auth0/auth0-react'
import { useUserApi } from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import { toast } from 'react-hot-toast'

export function MultiFactorAuthentication({ enabled }: { enabled: boolean }) {
    const { useUpdateAuth0Profile } = useUserApi()

    const { loginWithPopup } = useAuth0<SharedType.Auth0ReactUser>()

    const updateProfile = useUpdateAuth0Profile({
        onSuccess(data) {
            toast.success('MFA setting updated successfully')
            if (data?.user_metadata?.enrolled_mfa === true) {
                loginWithPopup(
                    {
                        authorizationParams: {
                            connection: 'Username-Password-Authentication',
                            screen_hint: 'show-form-only',
                            display: 'page',
                        },
                    },
                    { timeoutInSeconds: 360 }
                )
            }
        },
        onError() {
            toast.error('Something went wrong enabling MFA on this account.')
        },
    })

    return (
        <section className="mt-6">
            <header className="flex items-center bg-gray-800 rounded-lg p-4">
                <div className="flex items-center justify-center">
                    {enabled ? (
                        <i className="ri-lock-password-line text-4xl text-gray-50" />
                    ) : (
                        <i className="ri-lock-unlock-line text-4xl text-gray-50" />
                    )}
                </div>

                <div className="ml-4 flex flex-col justify-around text-white">
                    <div className="flex items-center">
                        <span className="mr-2 font-normal">Multi-factor authentication</span>
                        {enabled ? (
                            <span className="text-sm font-medium py-0.5 px-1 text-teal bg-teal/10 rounded-sm mr-1">
                                Enabled
                            </span>
                        ) : (
                            <span className="text-sm font-medium py-0.5 px-1 text-red bg-red/10 rounded-sm mr-1">
                                Not enabled
                            </span>
                        )}
                    </div>
                    {!enabled && (
                        <div className="text-gray-100 text-base">Requires authenticator app</div>
                    )}
                </div>

                <Button
                    variant="secondary"
                    className="ml-auto"
                    onClick={() => updateProfile.mutate({ enrolled_mfa: !enabled })}
                    disabled={updateProfile.isLoading}
                >
                    {enabled ? 'Remove' : 'Set up'}
                </Button>
            </header>
        </section>
    )
}

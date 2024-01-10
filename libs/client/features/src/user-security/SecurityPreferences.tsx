import { useUserApi } from '@maybe-finance/client/shared'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'
import { MultiFactorAuthentication } from './MultiFactorAuthentication'
import { PasswordReset } from './PasswordReset'

export function SecurityPreferences() {
    const { useAuth0Profile } = useUserApi()
    const profileQuery = useAuth0Profile()

    if (profileQuery.isLoading) {
        return <LoadingSpinner />
    }

    if (profileQuery.isError) {
        return (
            <p className="text-gray-50">
                Something went wrong loading your security preferences...
            </p>
        )
    }

    const { socialOnlyUser, mfaEnabled } = profileQuery.data

    return socialOnlyUser ? (
        <>
            <p className="text-base text-white">
                Your account credentials are managed by Apple. To reset your password, click the
                button below to go to your Apple settings.
            </p>
            <Button className="mt-4" href="https://appleid.apple.com/">
                Manage Apple Account
            </Button>
        </>
    ) : (
        <>
            <h4 className="mb-2 text-lg uppercase">Password</h4>
            <PasswordReset />

            <h4 className="mb-2 mt-8 text-lg uppercase">Multi-Factor Authentication</h4>
            <p className="text-base text-gray-100">
                Add an extra layer of security by setting up multi-factor authentication. This will
                need an app like Google Authenticator or Authy.
            </p>
            <MultiFactorAuthentication enabled={mfaEnabled} />
        </>
    )
}

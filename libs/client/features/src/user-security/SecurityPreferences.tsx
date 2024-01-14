import { useUserApi } from '@maybe-finance/client/shared'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'
import { PasswordReset } from './PasswordReset'

export function SecurityPreferences() {
    return (
        <>
            <h4 className="mb-2 text-lg uppercase">Password</h4>
            <PasswordReset />
        </>
    )
}

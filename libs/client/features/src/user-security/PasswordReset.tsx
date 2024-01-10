import { useUserApi } from '@maybe-finance/client/shared'
import { Button, InputPassword } from '@maybe-finance/design-system'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { useState } from 'react'

export function PasswordReset() {
    const [currentPassword, setCurrentPassword] = useState('')
    const [newPassword, setNewPassword] = useState('')
    const [isValid, setIsValid] = useState(false)

    const { useChangePassword } = useUserApi()

    const changePassword = useChangePassword()
    const onSubmit = async (event: any) => {
        event.preventDefault()

        setCurrentPassword('')
        setNewPassword('')

        changePassword.mutate({ currentPassword, newPassword })
    }

    return (
        <form className="space-y-4" onSubmit={onSubmit}>
            <InputPassword
                autoComplete="current-password"
                label="Current Password"
                value={currentPassword}
                showComplexityBar={false}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setCurrentPassword(e.target.value)
                }
            />

            <InputPassword
                autoComplete="new-password"
                label="New password"
                value={newPassword}
                showPasswordRequirements={!isValid}
                onValidityChange={(checks) => {
                    const passwordValid = checks.filter((c) => !c.isValid).length === 0
                    setIsValid(passwordValid)
                }}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setNewPassword(e.target.value)
                }
            />

            <Button
                type="submit"
                disabled={!isValid || changePassword.isLoading}
                variant={isValid || changePassword.isLoading ? 'primary' : 'secondary'}
            >
                {changePassword.isLoading ? (
                    <LoadingIcon className="w-3 h-3 animate-spin text-black inline mr-2 mb-0.5" />
                ) : null}
                {changePassword.isLoading ? 'Saving...' : 'Save changes'}
            </Button>
        </form>
    )
}

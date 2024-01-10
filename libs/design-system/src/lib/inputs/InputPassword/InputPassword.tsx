import type { InputProps } from '..'
import { useEffect, useMemo, useState } from 'react'
import classNames from 'classnames'
import type zxcvbnType from 'zxcvbn'
import {
    RiEyeLine as IconReveal,
    RiEyeOffLine as IconHide,
    RiCloseFill as IconClose,
    RiCheckFill as IconCheck,
} from 'react-icons/ri'
import { Input } from '..'
import { InputHint } from '../InputHint'
import { Tooltip } from '../../Tooltip/'

interface PasswordValidation {
    isValid: boolean
    message: string
}

interface PasswordValidator {
    (password: string): PasswordValidation
}

export interface InputPasswordProps extends Omit<InputProps, 'type'> {
    /** Whether to show and enable the button to reveal/hide the password */
    showRevealButton?: boolean

    /** Whether to show the complexity measurement bar */
    showComplexityBar?: boolean

    /** Custom password complexity function, returning a score from 0 to 4 */
    passwordComplexity?: (password: string) => number

    /** Whether or not to show a password requirements popover */
    showPasswordRequirements?: boolean

    /** Fires when password validity changes */
    onValidityChange?: (validations: { isValid: boolean; message: string }[]) => void
}

const COMPLEXITY_SCORE_NAMES = ['very weak', 'weak', 'fair', 'strong', 'very strong']

declare const zxcvbn: typeof zxcvbnType

/**
 * Input for password values
 */
function InputPassword({
    value,
    showRevealButton = true,
    showComplexityBar = true,
    showPasswordRequirements = false,
    passwordComplexity,
    disabled,
    hint,
    error,
    onValidityChange,
    ...rest
}: InputPasswordProps): JSX.Element {
    const [revealPassword, setRevealPassword] = useState(false)
    const [complexityScore, setComplexityScore] = useState(0)
    const [validations, setValidations] = useState<PasswordValidation[]>([])

    const _passwordComplexity = useMemo(
        () => passwordComplexity ?? ((password: string) => zxcvbn(password).score),
        [passwordComplexity]
    )

    const passwordRequirements = useMemo(() => {
        const validators: PasswordValidator[] = [
            (p) => ({
                isValid: p.length >= 8 && p.length <= 64,
                message: 'Between 8 - 64 characters',
            }),
            (p) => ({ isValid: /[a-z]+/.test(p), message: 'Contains 1+ lowercase characters' }),
            (p) => ({ isValid: /[A-Z]+/.test(p), message: 'Contains 1+ uppercase characters' }),
            (p) => ({
                isValid: /[*!@#$%^&(){}:;<>,.?/~_+-=|]+/.test(p),
                message: 'Contains 1+ special characters',
            }),
        ]

        return validators
    }, [])

    useEffect(() => {
        setComplexityScore(value ? _passwordComplexity(value as string) : 0)
    }, [value, _passwordComplexity])

    // Using Auth0 "Good" password requirements - https://auth0.com/docs/connections/database/password-strength#password-policies
    useEffect(() => {
        if (onValidityChange) {
            const checks = passwordRequirements.map((validatorFn) =>
                validatorFn((value as string) || '')
            )
            onValidityChange(checks)
            setValidations(checks)
        }
    }, [value, passwordRequirements, onValidityChange])

    return (
        <div>
            <Tooltip
                trigger="focusin"
                hideOnClick={false}
                placement="bottom-start"
                offset={({ placement }) => {
                    if (placement.includes('bottom')) {
                        return showComplexityBar ? [0, 20] : [0, 8]
                    } else {
                        return [0, 4]
                    }
                }}
                disabled={!showPasswordRequirements}
                content={
                    <div>
                        <p className="text-gray-25">Password requirements</p>

                        <div className="mt-2">
                            {validations
                                .sort((a, b) => {
                                    const aVal = a.isValid ? 1 : 0
                                    const bVal = b.isValid ? 1 : 0
                                    return bVal - aVal
                                })
                                .map((validation) => {
                                    return (
                                        <div key={validation.message}>
                                            <span className="inline-block pr-1">
                                                {validation.isValid ? (
                                                    <IconCheck className="w-3 h-3 text-green" />
                                                ) : (
                                                    <IconClose className="w-3 h-3 text-red" />
                                                )}
                                            </span>
                                            <span
                                                className={
                                                    validation.isValid
                                                        ? 'text-gray-200'
                                                        : 'text-gray-25'
                                                }
                                            >
                                                {validation.message}
                                            </span>
                                        </div>
                                    )
                                })}
                        </div>
                    </div>
                }
            >
                <div>
                    <Input
                        value={value}
                        type={revealPassword ? 'text' : 'password'}
                        fixedRightOverride={
                            showRevealButton ? (
                                <Tooltip
                                    content={revealPassword ? 'Hide password' : 'Show password'}
                                    delay={300}
                                    hideOnClick={false}
                                    offset={[0, 6]}
                                >
                                    <button
                                        type="button"
                                        onClick={() => setRevealPassword(!revealPassword)}
                                        aria-label={
                                            revealPassword ? 'Hide Password' : 'Show Password'
                                        }
                                        data-testid="reveal-password-button"
                                        className="text-xl text-gray-100 hover:text-gray-50 focus:text-gray-50 focus:outline-none"
                                    >
                                        {revealPassword ? <IconHide /> : <IconReveal />}
                                    </button>
                                </Tooltip>
                            ) : null
                        }
                        hasError={!!error}
                        disabled={disabled}
                        hint={hint}
                        error={error}
                        {...rest}
                    />
                </div>
            </Tooltip>
            {showComplexityBar && (
                <div
                    className="flex pt-2"
                    title={'Password is ' + COMPLEXITY_SCORE_NAMES[complexityScore]}
                >
                    {['bg-red', 'bg-orange', 'bg-yellow', 'bg-green'].map((bg, index) => (
                        <div
                            key={bg}
                            className={classNames(
                                'w-1/4 h-1 rounded transition-colors',
                                value && complexityScore > index ? bg : 'bg-gray-300',
                                index < 3 && 'mr-1.5'
                            )}
                        ></div>
                    ))}
                </div>
            )}

            {hint && !error && <InputHint disabled={disabled}>{hint}</InputHint>}
            {error && (
                <InputHint error={true} disabled={disabled}>
                    {error}
                </InputHint>
            )}
        </div>
    )
}

export default InputPassword

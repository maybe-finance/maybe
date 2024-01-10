import type { InputColorHintColor } from '../'
import type { InputHTMLAttributes, ReactNode } from 'react'
import classNames from 'classnames'
import { InputColorHint, InputHint } from '../'
import React, { forwardRef } from 'react'

const InputVariants = Object.freeze({
    default: 'focus-within:border-cyan focus-within:ring-cyan',
    positive: 'focus-within:border-teal focus-within:ring-teal',
    negative: 'focus-within:border-red focus-within:ring-red',
})

export type InputVariant = keyof typeof InputVariants

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
    variant?: InputVariant

    /** Label that shows up over input */
    label?: string

    /** Color to appear on the right side of the input */
    colorHint?: InputColorHintColor

    labelClassName?: string

    inputClassName?: string

    /** Hint message that appears below the input */
    hint?: string

    /** Error message that appears below the input */
    error?: string

    /** If there's no error message, but you want to color the border as red, pass `true` */
    hasError?: boolean

    /** Override content appearing on the left side of the input */
    fixedLeftOverride?: ReactNode

    /** Override content appearing on the right side of the input */
    fixedRightOverride?: ReactNode
}

/**
 * Simple input component
 */
function Input(
    {
        variant = 'default',
        disabled,
        readOnly,
        colorHint,
        className,
        label,
        labelClassName,
        inputClassName,
        hint,
        error,
        hasError,
        fixedLeftOverride,
        fixedRightOverride,
        ...rest
    }: InputProps,
    ref: React.Ref<HTMLInputElement>
): JSX.Element {
    const fixedLeft = fixedLeftOverride
    const fixedRight =
        fixedRightOverride || (colorHint ? <InputColorHint color={colorHint} /> : null)

    const bgClass = readOnly ? 'bg-gray-600' : 'bg-gray-500'

    return (
        <label className={classNames(className, 'flex w-full flex-col')}>
            {label && (
                <span
                    className={classNames(
                        labelClassName,
                        'block mb-1 text-base text-gray-50 font-light leading-6'
                    )}
                >
                    {label}
                </span>
            )}

            <div
                className={classNames(
                    'flex h-10 text-white rounded border overflow-hidden relative',
                    error || hasError ? 'border-red' : 'border-gray-700',
                    'focus-within:ring focus-within:ring-opacity-10',
                    InputVariants[variant],
                    (disabled || readOnly) && 'text-gray-100'
                )}
            >
                {fixedLeft && (
                    <span
                        className={classNames(
                            'absolute left-3 top-1/2 -translate-y-1/2 flex items-center justify-center text-gray-50 text-base select-none',
                            bgClass
                        )}
                    >
                        {fixedLeft}
                    </span>
                )}

                <input
                    className={classNames(
                        inputClassName,
                        'min-w-0 py-0 w-full', // Allows the input's flex container to work properly - https://stackoverflow.com/a/42421490/7437737
                        'text-base font-light leading-none border-0',
                        'focus:outline-none focus:ring-0',
                        'placeholder-gray-100 disabled:placeholder-gray-200 disabled:text-gray-100',
                        bgClass,
                        fixedLeft ? 'pl-8' : 'pl-3',
                        fixedRight ? 'pr-8' : 'pr-3'
                    )}
                    ref={ref}
                    disabled={disabled}
                    readOnly={readOnly}
                    {...rest}
                />

                {fixedRight && (
                    <span
                        className={classNames(
                            'absolute right-3 top-1/2 -translate-y-1/2 flex items-center justify-center text-gray-50 text-base select-none',
                            bgClass
                        )}
                    >
                        {fixedRight}
                    </span>
                )}
            </div>

            {hint && !error && <InputHint disabled={disabled}>{hint}</InputHint>}
            {error && (
                <InputHint error={true} disabled={disabled}>
                    {error}
                </InputHint>
            )}
        </label>
    )
}

export default forwardRef<HTMLInputElement, InputProps>(Input)

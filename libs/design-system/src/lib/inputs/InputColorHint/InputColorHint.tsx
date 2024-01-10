import type { HTMLAttributes } from 'react'
import classNames from 'classnames'

const InputColorHintColors = Object.freeze({
    cyan: 'bg-cyan',
    blue: 'bg-blue',
    pink: 'bg-pink',
    teal: 'bg-teal',
    green: 'bg-green',
    red: 'bg-red',
    yellow: 'bg-yellow',
})

export type InputColorHintColor = keyof typeof InputColorHintColors

export interface InputColorHintProps extends HTMLAttributes<HTMLSpanElement> {
    color: InputColorHintColor
    className?: string
}

export default function InputColorHint({
    color,
    className,
    ...rest
}: InputColorHintProps): JSX.Element {
    const combinedClassName = classNames(
        className,
        InputColorHintColors[color],
        'block w-1.5 rounded-lg leading-none'
    )

    return (
        <span className={combinedClassName} {...rest}>
            &nbsp; {/* Used to force a height matching the font size */}
        </span>
    )
}

import type { HTMLAttributes } from 'react'
import React, { useEffect, useState } from 'react'
import AnimateHeight from 'react-animate-height'
import { RiArrowRightSFill as Caret } from 'react-icons/ri'
import Link from 'next/link'
import cn from 'classnames'

const LevelClassMap = {
    0: { base: 'pl-3 bg-gray-500', interactions: 'hover:bg-gray-400 cursor-pointer' },
    1: { base: 'pl-6 bg-gray-700', interactions: 'hover:bg-gray-600 cursor-pointer' },
    2: { base: 'pl-14 bg-gray-800', interactions: 'hover:bg-gray-700 cursor-pointer' },
}

export interface AccordionRowProps extends HTMLAttributes<HTMLElement> {
    /** Label string or node */
    label: string | React.ReactNode

    /** Whether the label should be transformed to uppercase */
    uppercase?: boolean

    /** Level for indentation and color */
    level?: keyof typeof LevelClassMap

    /** Whether the AccordionRow can be collapsed/expanded */
    collapsible?: boolean

    /** Whether the AccordionRow is currently expanded */
    expanded?: boolean

    /** Optional link href */
    href?: string

    /** Whether the row is active (highlighted) */
    active?: boolean

    onClick?: () => void

    onToggle?: (expanded: boolean) => void

    className?: string

    children?: React.ReactNode
}

function AccordionRow({
    label,
    uppercase = false,
    level = 0,
    collapsible = true,
    expanded: expandedProp = true,
    href,
    active,
    onClick,
    onToggle,
    className,
    children,
    ...rest
}: AccordionRowProps): JSX.Element {
    const [isExpanded, setIsExpanded] = useState<boolean>(expandedProp)

    useEffect(() => setIsExpanded(expandedProp), [expandedProp])

    const handleClick = () => {
        onClick && onClick()
        if (!collapsible) return

        const expanded = !isExpanded
        setIsExpanded(expanded)
        onToggle && onToggle(expanded)
    }

    const component = (
        <>
            <div
                className={cn(
                    className,
                    'py-3 pr-3 mb-0.5 flex items-center justify-between space-x-3 rounded-lg leading-none text-base text-white',
                    collapsible && 'select-none',
                    active && '!bg-cyan !bg-opacity-10',
                    LevelClassMap[level].base,
                    (collapsible || href) && LevelClassMap[level].interactions
                )}
                onClick={handleClick}
                role={collapsible ? 'button' : undefined}
                {...rest}
            >
                {collapsible && (
                    <div className="shrink-0 w-4 text-gray-50">
                        <Caret
                            className={cn(
                                isExpanded && 'transform rotate-90',
                                'w-5 h-5 transition-transform'
                            )}
                        />
                    </div>
                )}
                <div className={cn('w-full', uppercase && 'uppercase')}>{label}</div>
            </div>
            {children && <AnimateHeight height={isExpanded ? 'auto' : 0}>{children}</AnimateHeight>}
        </>
    )

    return href ? (
        <Link href={href} legacyBehavior>
            <a>{component}</a>
        </Link>
    ) : (
        component
    )
}

export default AccordionRow

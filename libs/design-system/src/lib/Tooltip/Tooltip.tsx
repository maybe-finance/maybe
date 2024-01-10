import type { TippyProps } from '@tippyjs/react/headless'
import Tippy from '@tippyjs/react/headless'
import cn from 'classnames'

export type TooltipProps = TippyProps

export default function Tooltip({ content, children, className, ...rest }: TooltipProps) {
    return (
        <Tippy
            render={(attrs) => (
                <div
                    className={cn(
                        'px-2 py-1 rounded bg-gray-700 border border-gray-600 shadow max-w-[264px] text-sm font-light text-gray-50',
                        className
                    )}
                    role="tooltip"
                    tabIndex={-1}
                    {...attrs}
                >
                    {content}
                </div>
            )}
            {...rest}
        >
            {children}
        </Tippy>
    )
}

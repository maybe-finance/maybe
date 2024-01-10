import type { IconType } from 'react-icons'
import classNames from 'classnames'

export function BreakdownTableIcon({ className, Icon }: { className: string; Icon: IconType }) {
    return (
        <div
            className={classNames(
                'relative flex items-center justify-center rounded-xl w-12 h-12 overflow-hidden',
                className
            )}
        >
            {/* Use absolute element for background because we can't use bg-opacity with bg-current */}
            <div className="absolute w-full h-full bg-current opacity-10"></div>

            <Icon className="w-6 h-6" />
        </div>
    )
}

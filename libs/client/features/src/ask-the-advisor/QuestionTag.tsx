import classNames from 'classnames'
import type { IconType } from 'react-icons'

export function QuestionTag({
    text,
    icon: Icon,
    className,
    iconClassName,
}: {
    text: string
    icon: IconType
    className?: string
    iconClassName?: string
}) {
    return (
        <div
            className={classNames(
                'flex items-center gap-1.5 px-2 py-1 bg-gray-700 w-fit rounded-[11px]',
                className
            )}
        >
            <Icon size={16} className={iconClassName} />
            <span className="text-sm font-medium">{text}</span>
        </div>
    )
}

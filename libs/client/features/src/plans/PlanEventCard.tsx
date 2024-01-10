import type { PropsWithChildren } from 'react'
import type { SharedType } from '@maybe-finance/shared'
import { PlanUtil } from '@maybe-finance/shared'
import classNames from 'classnames'
import { NumberUtil } from '@maybe-finance/shared'
import { RiAddLine, RiSubtractLine } from 'react-icons/ri'
import { DateTime } from 'luxon'
import { BoxIcon } from '@maybe-finance/client/shared'

type PlanEventCardProps = PropsWithChildren<{
    event: SharedType.PlanEvent
    projection?: SharedType.PlanProjectionResponse['projection']
    onClick: () => void
    className?: string
}>

function toYearRange(
    event: Pick<
        SharedType.PlanEvent,
        'startYear' | 'startMilestoneId' | 'endYear' | 'endMilestoneId'
    >,
    projection?: SharedType.PlanProjectionResponse['projection']
) {
    const start =
        event.startYear ??
        (projection ? PlanUtil.resolveMilestoneYear(projection, event.startMilestoneId!) : null)

    const end =
        event.endYear ??
        (projection ? PlanUtil.resolveMilestoneYear(projection, event.endMilestoneId!) : null)

    if (start && end) {
        return `Years ${start} - ${end}`
    }

    if (start && !end) {
        return `Years ${start} - end of plan`
    }

    if (!start && end) {
        return `Years ${DateTime.now().year} - ${end}`
    }

    return `All years`
}

export function PlanEventCard({ event, projection, onClick, className }: PlanEventCardProps) {
    const isPositive = event.initialValue.isPositive()
    const Icon = isPositive ? RiAddLine : RiSubtractLine

    return (
        <div
            className={classNames(
                'flex items-start space-x-4 bg-gray-800 rounded-xl w-full p-4 text-base',
                'cursor-pointer transition-colors duration-50 hover:bg-gray-700',
                className
            )}
            role="button"
            onClick={onClick}
        >
            <BoxIcon variant={isPositive ? 'teal' : 'red'} icon={Icon} />

            <div className="grow">
                <div className="text-white">{event.name}</div>
                <div className="text-gray-100">{toYearRange(event, projection)}</div>
            </div>

            <div className="text-right">
                <div className="text-white">
                    {NumberUtil.format(event.initialValue, 'currency')}
                </div>
            </div>
        </div>
    )
}

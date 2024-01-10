import { RiMoneyDollarBoxLine, RiMoneyDollarCircleLine } from 'react-icons/ri'
import { GiPalmTree } from 'react-icons/gi'
import type { SharedType } from '@maybe-finance/shared'
import { PlanUtil } from '@maybe-finance/shared'
import { TSeries } from '@maybe-finance/client/shared'

export function getEventIcon(
    { event }: SharedType.PlanProjectionEvent,
    projection: SharedType.PlanProjectionResponse['projection'],
    currentYear?: number
) {
    const eventStartYear =
        event.startYear ?? PlanUtil.resolveMilestoneYear(projection, event.startMilestoneId!)
    const eventEndYear =
        event.endYear ?? PlanUtil.resolveMilestoneYear(projection, event.endMilestoneId!)

    const status =
        currentYear && eventStartYear === currentYear
            ? 'starting'
            : currentYear && eventEndYear === currentYear
            ? 'ending'
            : 'active'

    const color = event.initialValue.isNegative() ? 'red' : 'cyan'

    return {
        icon: RiMoneyDollarBoxLine,
        color: TSeries.tailwindScale(color),
        bgColor: TSeries.tailwindBgScale(color),
        label:
            status === 'starting'
                ? `Start of ${event.name}`
                : status === 'ending'
                ? `End of ${event.name}`
                : event.name,
    }
}

export function getMilestoneIcon(milestone: SharedType.PlanMilestone) {
    if (milestone.category === PlanUtil.PlanMilestoneCategory.Retirement) {
        return {
            icon: GiPalmTree,
            color: TSeries.tailwindScale('cyan'),
            bgColor: TSeries.tailwindBgScale('cyan'),
            label: milestone.name,
        }
    }

    return {
        icon: RiMoneyDollarCircleLine,
        color: TSeries.tailwindScale('cyan'),
        bgColor: TSeries.tailwindBgScale('cyan'),
        label: milestone.name,
    }
}

import type { SharedType } from '@maybe-finance/shared'
import { BoxIcon } from '@maybe-finance/client/shared'
import { Button, DialogV2, LoadingPlaceholder } from '@maybe-finance/design-system'
import { DateUtil, NumberUtil } from '@maybe-finance/shared'
import { GiPalmTree } from 'react-icons/gi'
import { RiAddLine, RiDeleteBin6Line, RiPencilLine } from 'react-icons/ri'
import { usePlanContext } from './PlanContext'
import toast from 'react-hot-toast'
import { useMemo, useState, Fragment } from 'react'

type MilestoneRange = {
    lower: SharedType.Decimal
    upper: SharedType.Decimal
    confidence: number // A percentage confidence in our range estimate
}

type Props = {
    isLoading: boolean
    onAdd: () => void
    onEdit: (id: SharedType.PlanMilestone['id']) => void
    onDelete: (id: SharedType.PlanMilestone['id']) => void
    milestones: (SharedType.PlanMilestone & MilestoneRange)[]
    events: SharedType.PlanEvent[]
}

export function PlanMilestones({ isLoading, onAdd, onEdit, onDelete, milestones, events }: Props) {
    const { userAge } = usePlanContext()

    const [confirmDeleteId, setConfirmDeleteId] = useState<SharedType.PlanMilestone['id'] | null>(
        null
    )

    const eventsToBeDeleted = useMemo(() => {
        if (!confirmDeleteId) return []

        return events.filter(
            (event) =>
                event.startMilestoneId === confirmDeleteId ||
                event.endMilestoneId === confirmDeleteId
        )
    }, [confirmDeleteId, events])

    return (
        <div className="mt-4">
            {isLoading ? (
                <div className="flex gap-4 items-start text-base">
                    <div className="relative w-12 h-12 rounded-xl bg-gray-800 overflow-hidden">
                        <div className="absolute inset-0 bg-shine animate-shine"></div>
                    </div>
                    <div className="flex flex-col gap-1 items-start">
                        <LoadingPlaceholder className="pr-12" overlayClassName="!bg-gray-800">
                            Milestone
                        </LoadingPlaceholder>
                        <LoadingPlaceholder className="pr-32" overlayClassName="!bg-gray-800">
                            Description
                        </LoadingPlaceholder>
                    </div>
                </div>
            ) : milestones.length ? (
                milestones.map((milestone) => {
                    return (
                        <Fragment key={milestone.id}>
                            <div className="group flex justify-between">
                                <div className="flex gap-4">
                                    {/* Icon and vertical line */}
                                    <div>
                                        <BoxIcon icon={GiPalmTree} />
                                        <div className="flex items-center justify-center my-4">
                                            <span className="bg-gray-500 h-[27px] w-[2px]" />
                                        </div>
                                    </div>

                                    <div className="max-w-[500px]">
                                        <p className="text-base font-medium">{milestone.name}</p>
                                        <p className="text-gray-100 text-base">
                                            Based on your current savings and portfolio, we project
                                            with a{' '}
                                            {NumberUtil.format(milestone.confidence, 'percent', {
                                                signDisplay: 'auto',
                                            })}{' '}
                                            confidence interval that you will have between{' '}
                                            <span className="text-gray-25">
                                                {NumberUtil.format(
                                                    milestone.lower,
                                                    'short-currency'
                                                )}
                                            </span>{' '}
                                            and{' '}
                                            <span className="text-gray-25">
                                                {NumberUtil.format(
                                                    milestone.upper,
                                                    'short-currency'
                                                )}
                                            </span>{' '}
                                            at age{' '}
                                            {milestone.type === 'year'
                                                ? DateUtil.yearToAge(milestone.year!, userAge)
                                                : '--'}
                                            .
                                        </p>
                                    </div>
                                </div>

                                {/* Edit and delete buttons on hover */}
                                <div className="group-hover:flex gap-2 hidden">
                                    <Button variant="icon" onClick={() => onEdit(milestone.id)}>
                                        <RiPencilLine className="w-6 h-6 text-gray-50 hover:text-white" />
                                    </Button>
                                    <Button
                                        variant="icon"
                                        onClick={() => setConfirmDeleteId(milestone.id)}
                                    >
                                        <RiDeleteBin6Line className="w-6 h-6 text-gray-50 hover:text-white" />
                                    </Button>
                                </div>
                            </div>
                            <div className="flex gap-4">
                                <div className="w-12 flex justify-center">
                                    <Button
                                        variant="icon"
                                        className="bg-gray-500 rounded-[10px]"
                                        onClick={onAdd}
                                    >
                                        <RiAddLine className="w-6 h-6 text-gray-50" />
                                    </Button>
                                </div>
                                <div className="max-w-[500px]">
                                    <p className="text-base font-medium">Add new milestone</p>
                                    <p className="text-gray-100 text-base">
                                        Tell us about any goals, what ifs, or windfalls you expect.
                                    </p>
                                </div>
                            </div>
                        </Fragment>
                    )
                })
            ) : (
                <div className="flex flex-col items-center">
                    <img alt="Maybe" className="h-14" src="/assets/plan-milestones.svg" />
                    <p className="max-w-[300px] mt-4 text-center text-base text-gray-50">
                        No milestones added yet.{' '}
                        <em className="not-italic text-white">Add a new one</em> to see how it
                        impacts your plan.
                    </p>
                </div>
            )}

            <DialogV2
                size="sm"
                open={confirmDeleteId !== null}
                onClose={() => setConfirmDeleteId(null)}
            >
                <div className="flex flex-col items-center">
                    <BoxIcon icon={GiPalmTree} variant="red" />
                    <h4 className="mt-4">Delete milestone?</h4>
                    <div className="text-center text-base text-gray-50">
                        <p className="mt-2">
                            This will impact your plan and forecast. You will not be able to undo
                            this action.
                        </p>
                        {eventsToBeDeleted.length > 0 && (
                            <p className="mt-2">
                                The following events will also be deleted:
                                <br />
                                {eventsToBeDeleted.map(({ name }, idx) => (
                                    <>
                                        <span className="text-white">{name}</span>
                                        {idx < eventsToBeDeleted.length - 1 && ', '}
                                    </>
                                ))}
                            </p>
                        )}
                    </div>
                    <div className="flex gap-3 w-full mt-5">
                        <Button
                            variant="secondary"
                            className="w-1/2"
                            onClick={() => setConfirmDeleteId(null)}
                        >
                            Cancel
                        </Button>
                        <Button
                            variant="danger"
                            className="w-1/2"
                            onClick={() => {
                                onDelete(confirmDeleteId!)
                                setConfirmDeleteId(null)
                            }}
                        >
                            Delete
                        </Button>
                    </div>
                </div>
            </DialogV2>
        </div>
    )
}

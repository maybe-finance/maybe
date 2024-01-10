import type { PropsWithChildren, ReactNode } from 'react'
import { useCallback } from 'react'
import type { SharedType } from '@maybe-finance/shared'
import classNames from 'classnames'
import { RiAddLine, RiArrowLeftDownLine, RiArrowRightUpLine } from 'react-icons/ri'
import { Button } from '@maybe-finance/design-system'
import { usePopoutContext } from '@maybe-finance/client/shared'
import { PlanEventCard } from './PlanEventCard'
import { PlanEventPopout } from './PlanEventPopout'
import { PlanEventForm } from './PlanEventForm'
import { PlanContext, usePlanContext } from './PlanContext'

type PlanCreateInput = Record<string, any>
type PlanUpdateInput = PlanCreateInput

type PlanEventListProps = PropsWithChildren<{
    events: SharedType.PlanEvent[]
    projection?: SharedType.PlanProjectionResponse['projection']
    isLoading: boolean
    className?: string

    onCreate(data: PlanCreateInput): void
    onUpdate(id: SharedType.PlanEvent['id'], data: PlanUpdateInput): void
    onDelete(id: SharedType.PlanEvent['id']): void
}>

export function PlanEventList({
    events,
    projection,
    isLoading,
    className,
    onCreate,
    onUpdate,
    onDelete,
}: PlanEventListProps) {
    const { open: openPopout, close: closePopout } = usePopoutContext()

    const planContext = usePlanContext()

    // Opens popout within a PlanContext.Provider (needed because popouts are rendered outside of this tree)
    const openPopoutWithContext = useCallback(
        (children: ReactNode) =>
            openPopout(<PlanContext.Provider value={planContext}>{children}</PlanContext.Provider>),
        [openPopout, planContext]
    )

    const incomeEvents = events.filter((event) => event.initialValue.gte(0))
    const expenseEvents = events.filter((event) => event.initialValue.lt(0))

    const createEvent = useCallback(
        (data: PlanCreateInput) => {
            onCreate(data)
            closePopout()
        },
        [onCreate, closePopout]
    )

    const updateEvent = useCallback(
        (id: SharedType.PlanEvent['id'], data: PlanUpdateInput) => {
            onUpdate(id, data)
            closePopout()
        },
        [onUpdate, closePopout]
    )

    const deleteEvent = useCallback(
        (id: SharedType.PlanEvent['id']) => {
            onDelete(id)
            closePopout()
        },
        [onDelete, closePopout]
    )

    return (
        <div
            className={classNames(
                'flex flex-wrap md:flex-nowrap space-y-8 md:space-y-0 md:space-x-8',
                className
            )}
        >
            <div className="w-full md:w-1/2">
                <div className="flex justify-between">
                    <h5 className="flex items-center uppercase">
                        <RiArrowLeftDownLine className="w-6 h-6 mr-1 text-teal" />
                        Income
                    </h5>
                    <Button
                        variant="icon"
                        disabled={isLoading}
                        onClick={() =>
                            openPopoutWithContext(
                                <PlanEventPopout key="new-income-event">
                                    <PlanEventForm
                                        mode="create"
                                        flow="income"
                                        onSubmit={(data) => createEvent(data)}
                                    />
                                </PlanEventPopout>
                            )
                        }
                        data-testid="income-events-add-button"
                    >
                        <RiAddLine className="w-6 h-6 text-gray-50" />
                    </Button>
                </div>
                <div className="mt-4">
                    {!isLoading && incomeEvents.length ? (
                        <div className="space-y-3">
                            {incomeEvents.map((event) => (
                                <PlanEventCard
                                    key={event.id}
                                    event={event}
                                    projection={projection}
                                    onClick={() =>
                                        openPopoutWithContext(
                                            <PlanEventPopout key={event.id}>
                                                <PlanEventForm
                                                    mode="update"
                                                    flow="income"
                                                    initialValues={event}
                                                    onSubmit={(data) => updateEvent(event.id, data)}
                                                    onDelete={() => deleteEvent(event.id)}
                                                />
                                            </PlanEventPopout>
                                        )
                                    }
                                />
                            ))}
                        </div>
                    ) : (
                        <EmptyStateCards
                            isLoading={isLoading}
                            message="No income events added yet"
                        />
                    )}
                </div>
            </div>
            <div className="w-full md:w-1/2">
                <div className="flex justify-between">
                    <h5 className="flex items-center uppercase">
                        <RiArrowRightUpLine className="w-6 h-6 mr-1 text-red" />
                        Expenses
                    </h5>
                    <Button
                        variant="icon"
                        disabled={isLoading}
                        onClick={() =>
                            openPopoutWithContext(
                                <PlanEventPopout key="new-expense-event">
                                    <PlanEventForm
                                        mode="create"
                                        flow="expense"
                                        onSubmit={({ initialValue, ...data }) =>
                                            createEvent({
                                                ...data,
                                                initialValue: initialValue?.negated(),
                                            })
                                        }
                                    />
                                </PlanEventPopout>
                            )
                        }
                    >
                        <RiAddLine className="w-6 h-6 text-gray-50" />
                    </Button>
                </div>
                <div className="mt-4">
                    {!isLoading && expenseEvents.length ? (
                        <div className="space-y-3">
                            {expenseEvents.map((event) => (
                                <PlanEventCard
                                    key={event.id}
                                    event={event}
                                    projection={projection}
                                    onClick={() =>
                                        openPopoutWithContext(
                                            <PlanEventPopout key={event.id}>
                                                <PlanEventForm
                                                    mode="update"
                                                    flow="expense"
                                                    initialValues={{
                                                        ...event,
                                                        initialValue: event.initialValue.negated(),
                                                    }}
                                                    onSubmit={({ initialValue, ...data }) =>
                                                        updateEvent(event.id, {
                                                            ...data,
                                                            initialValue: initialValue?.negated(),
                                                        })
                                                    }
                                                    onDelete={() => deleteEvent(event.id)}
                                                />
                                            </PlanEventPopout>
                                        )
                                    }
                                />
                            ))}
                        </div>
                    ) : (
                        <EmptyStateCards
                            isLoading={isLoading}
                            message="No expense events added yet"
                        />
                    )}
                </div>
            </div>
        </div>
    )
}

function EmptyStateCards({
    isLoading,
    message,
}: {
    isLoading: boolean
    message: string
}): JSX.Element {
    return (
        <div className="relative">
            <div className="space-y-2">
                {Array.from({ length: 3 }).map((_, idx) => (
                    <div
                        key={idx}
                        className="relative bg-gray-800 rounded-xl w-full p-4 overflow-hidden text-base"
                    >
                        {isLoading && (
                            <div className="absolute top-0 left-0 w-full h-full bg-shine animate-shine"></div>
                        )}
                        <div className="w-12 h-12 rounded-xl bg-gray-700"></div>
                    </div>
                ))}
            </div>
            <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-t from-black"></div>
            {!isLoading && (
                <div className="absolute flex items-center justify-center top-0 left-0 w-full h-full text-base text-gray-50">
                    {message}
                </div>
            )}
        </div>
    )
}

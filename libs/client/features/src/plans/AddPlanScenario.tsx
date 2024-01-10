import type { IconType } from 'react-icons'
import type { BoxIconProps } from '@maybe-finance/client/shared'
import type { ReactNode } from 'react'
import type { SharedType } from '@maybe-finance/shared'
import type { PlanEventValues } from './PlanEventForm'
import type { O } from 'ts-toolbelt'

import { BoxIcon, usePopoutContext } from '@maybe-finance/client/shared'
import { useCallback, useMemo, useState } from 'react'
import { GiPalmTree } from 'react-icons/gi'
import { RiArrowRightDownLine, RiArrowRightUpLine, RiSearchLine } from 'react-icons/ri'
import { DialogV2 } from '@maybe-finance/design-system'
import groupBy from 'lodash/groupBy'
import { RetirementMilestoneForm } from './RetirementMilestoneForm'
import { PlanContext, PlanEventPopout, usePlanContext } from '..'
import { DateUtil, PlanUtil } from '@maybe-finance/shared'
import { PlanEventForm } from './PlanEventForm'

// No typings available for this module
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fuzzysearch = require('fuzzysearch')

const scenarioOptions: ScenarioOption[] = [
    { scenario: 'retirement', name: 'Retirement', icon: GiPalmTree, group: 'Milestones' },
    { scenario: 'income', name: 'Custom Income', icon: RiArrowRightUpLine, group: 'What ifs' },
    { scenario: 'expense', name: 'Custom Expense', icon: RiArrowRightDownLine, group: 'What ifs' },

    // TODO - support additional options
    // {
    //     scenario: 'fi',
    //     name: 'Financial independence',
    //     icon: RiFlagLine,
    //     group: 'Goals',
    // },
    // { scenario: 'debt-free', name: 'Debt free', icon: RiCopperCoinLine, group: 'Goals' },
    // { scenario: 'buy-house', name: 'Buy new house', icon: RiHomeLine, group: 'What ifs' },
    // {
    //     scenario: 'start-business',
    //     name: 'Start a business',
    //     icon: RiBriefcase2Line,
    //     group: 'What ifs',
    // },
    // {
    //     scenario: 'reallocate',
    //     name: 'Portfolio reallocation',
    //     icon: RiEqualizerLine,
    //     group: 'What ifs',
    // },
]

// Different form shown based on scenario chosen (only retirement implemented)
type PlanScenario =
    | 'retirement'
    | 'income'
    | 'expense'
    | 'fi'
    | 'debt-free'
    | 'buy-house'
    | 'start-business'
    | 'reallocate'

type ScenarioOption = {
    group: string
    scenario: PlanScenario
    name: string
    icon: IconType
}

type ScenarioData =
    | {
          scenario: 'retirement'
          data: {
              year: number
              monthlySpending: number
          }
      }
    | { scenario: 'income'; data: O.Nullable<PlanEventValues, 'initialValue'> }
    | { scenario: 'expense'; data: O.Nullable<PlanEventValues, 'initialValue'> }
    | { scenario: 'fi' }
    | { scenario: 'debt-free' }
    | { scenario: 'buy-house' }
    | { scenario: 'start-business' }
    | { scenario: 'reallocate' }

type Props = {
    plan: SharedType.Plan
    isOpen: boolean
    scenarioYear: number
    onClose(): void
    onSubmit(data: ScenarioData): void
}

export function AddPlanScenario({ plan, isOpen, scenarioYear, onClose, onSubmit }: Props) {
    const [scenario, setScenario] = useState<PlanScenario | undefined>()
    const [error, setError] = useState('')

    const { open: openPopout } = usePopoutContext()

    const planContext = usePlanContext()

    // Opens popout within a PlanContext.Provider (needed because popouts are rendered outside of this tree)
    const openPopoutWithContext = useCallback(
        (children: ReactNode) =>
            openPopout(<PlanContext.Provider value={planContext}>{children}</PlanContext.Provider>),
        [openPopout, planContext]
    )

    const handleClose = useCallback(() => {
        setError('')
        setScenario(undefined)
        onClose()
    }, [onClose])

    const scenarioUI = useMemo(() => {
        switch (scenario) {
            case 'retirement':
                if (
                    plan.milestones.find(
                        (m) => m.category === PlanUtil.PlanMilestoneCategory.Retirement
                    )
                ) {
                    setError(
                        'We could not add a retirement milestone because one already exists.  Please delete that milestone first.'
                    )
                    return
                }

                return {
                    title: 'Retirement',
                    component: (
                        <RetirementMilestoneForm
                            mode="create"
                            defaultValues={
                                planContext.userAge
                                    ? {
                                          age: DateUtil.yearToAge(
                                              scenarioYear,
                                              planContext.userAge
                                          ),
                                          monthlySpending: 5000,
                                      }
                                    : { year: scenarioYear, monthlySpending: 5000 }
                            }
                            onSubmit={(data) => {
                                onSubmit({ scenario: 'retirement', data })
                                setScenario(undefined)
                            }}
                        />
                    ),
                }
            case 'income':
                openPopoutWithContext(
                    <PlanEventPopout key="new-income-event">
                        <PlanEventForm
                            mode="create"
                            flow="income"
                            onSubmit={(data) => onSubmit({ scenario: 'income', data })}
                            initialValues={{ startYear: scenarioYear, name: 'Income event' }}
                        />
                    </PlanEventPopout>
                )

                handleClose()

                return null
            case 'expense':
                openPopoutWithContext(
                    <PlanEventPopout key="new-expense-event">
                        <PlanEventForm
                            mode="create"
                            flow="expense"
                            onSubmit={(data) =>
                                onSubmit({
                                    scenario: 'expense',
                                    data: {
                                        ...data,
                                        initialValue: data.initialValue
                                            ? data.initialValue.negated()
                                            : undefined,
                                    },
                                })
                            }
                            initialValues={{ startYear: scenarioYear, name: 'Expense event' }}
                        />
                    </PlanEventPopout>
                )

                handleClose()

                return null
            default:
                return null
        }
    }, [
        scenario,
        onSubmit,
        scenarioYear,
        planContext.userAge,
        plan.milestones,
        openPopoutWithContext,
        handleClose,
    ])

    if (error) {
        return <DialogV2 open={isOpen} title="Oops!" description={error} onClose={handleClose} />
    }

    return scenarioUI ? (
        <DialogV2 open={isOpen} onClose={handleClose} title={scenarioUI.title}>
            {scenarioUI.component}
        </DialogV2>
    ) : (
        <DialogV2 open={isOpen} onClose={handleClose} disablePadding size="xl">
            <Search onSelect={setScenario} />
        </DialogV2>
    )
}

function Option({
    name,
    icon,
    onClick,
    variant,
}: {
    name: string
    icon: IconType
    onClick: () => void
    variant: BoxIconProps['variant']
}) {
    return (
        <button
            className="mx-2 p-2 hover:bg-gray-600 rounded-xl flex gap-3 items-center outline-none"
            onClick={onClick}
        >
            <BoxIcon icon={icon} size="md" variant={variant} />
            <span className="text-base">{name}</span>
        </button>
    )
}

function Search({ onSelect }: { onSelect(scenario: PlanScenario): void }) {
    const [search, setSearch] = useState<string | undefined>()

    const options = useMemo(() => {
        const filtered = scenarioOptions.filter((option) =>
            search ? fuzzysearch(search.toLowerCase(), option.name.toLowerCase()) : true
        )

        return groupBy(filtered, 'group')
    }, [search])

    return (
        <>
            <div className="flex items-center text-base gap-2 border-b border-b-gray-600 h-[56px] p-4 text-gray-100">
                <RiSearchLine className="w-5 h-5" />
                <input
                    className="w-full bg-transparent border-none outline-none focus:ring-0 focus-within:ring-0 placeholder:text-gray-100 text-base text-white p-0"
                    type="text"
                    placeholder="What's next in your plan?"
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                />
            </div>

            {/* Milestones  */}
            <div className="relative pb-8 h-[268px] custom-gray-scroll">
                {Object.entries(options).length === 0 ? (
                    <p className="text-sm text-gray-50 p-4">No scenarios found</p>
                ) : (
                    Object.entries(options).map(([group, scenarios]) => (
                        <div key={group} className="mt-4">
                            <span className="inline-block pl-4 mb-2 text-gray-100 text-sm font-medium">
                                {group}
                            </span>
                            {scenarios.map((s) => (
                                <div key={s.name} className="flex flex-col gap-1">
                                    <Option
                                        key={s.name}
                                        name={s.name}
                                        icon={s.icon}
                                        variant={
                                            s.scenario === 'income'
                                                ? 'teal'
                                                : s.scenario === 'expense'
                                                ? 'red'
                                                : 'cyan'
                                        }
                                        onClick={() => {
                                            onSelect(s.scenario)
                                        }}
                                    />
                                </div>
                            ))}
                        </div>
                    ))
                )}
            </div>
        </>
    )
}

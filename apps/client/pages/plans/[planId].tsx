import type { ReactElement } from 'react'
import {
    WithSidebarLayout,
    AccountSidebar,
    RetirementPlanChart,
    PlanEventList,
    PlanRangeSelector,
    PlanContext,
    PlanMenu,
    PlanMilestones,
    AddPlanScenario,
    RetirementMilestoneForm,
    InlineQuestionCardGroup,
} from '@maybe-finance/client/features'
import { useRouter } from 'next/router'
import { useState, useMemo } from 'react'
import {
    BlurredContentOverlay,
    MainContentOverlay,
    useAccountContext,
    usePlanApi,
    usePopoutContext,
    useQueryParam,
    useUserAccountContext,
    useUserApi,
} from '@maybe-finance/client/shared'
import { Breadcrumb, Button, DialogV2, LoadingSpinner } from '@maybe-finance/design-system'
import {
    RiAddLine,
    RiAlertLine,
    RiExchangeDollarLine,
    RiFileList2Line,
    RiFolderShieldLine,
    RiLineChartLine,
    RiPercentLine,
} from 'react-icons/ri'
import { DateTime } from 'luxon'
import classNames from 'classnames'
import { DateUtil, NumberUtil, PlanUtil } from '@maybe-finance/shared'

export default function PlanDetailPage() {
    const planId = useQueryParam('planId', 'string')!
    const router = useRouter()
    const { isReady, noAccounts, allAccountsDisabled } = useUserAccountContext()
    const { addAccount } = useAccountContext()
    const { close: closePopout } = usePopoutContext()
    const { usePlan, useUpdatePlan, usePlanProjections, useUpdatePlanTemplate } = usePlanApi()
    const { useProfile } = useUserApi()

    const plan = usePlan(+planId, { enabled: !!planId })
    const projections = usePlanProjections(+planId, { enabled: !!planId })
    const userProfile = useProfile()

    const updatePlan = useUpdatePlan()
    const updatePlanTemplate = useUpdatePlanTemplate()

    const [addScenario, setAddScenario] = useState<{ isOpen: boolean; scenarioYear?: number }>({
        isOpen: false,
    })

    const [editMilestoneId, setEditMilestoneId] = useState<number | undefined>()

    const [selectedYearRange, setSelectedYearRange] = useState<{ from: number; to: number } | null>(
        null
    )

    const [mode, setMode] = useState<'age' | 'year'>('age')

    const retirement = useMemo(() => {
        const retirementMilestone = plan.data?.milestones.find(
            (m) => m.category === PlanUtil.PlanMilestoneCategory.Retirement
        )
        if (!retirementMilestone) return null

        const projectionIdx = projections.data?.projection.data.findIndex(
            (p) => p.values.year === retirementMilestone.year
        )
        if (!projectionIdx || projectionIdx < 0) return null

        const upper = projections.data?.simulations.at(-1)?.simulation.data?.[projectionIdx]
        const lower = projections.data?.simulations.at(0)?.simulation.data?.[projectionIdx]
        const projection = projections.data?.projection.data?.[projectionIdx]

        if (!upper || !lower || !projection) return null

        return {
            milestone: retirementMilestone,
            projection,
            upper,
            lower,
        }
    }, [projections.data, plan.data])

    // Determines the maximum number of stackable icons that are present on any single year
    const maxIconsPerDatum = useMemo(() => {
        const eventCounts = projections.data?.projection.data.map(
            (datum) => datum.values.events.length + datum.values.milestones.length
        )

        return eventCounts ? Math.max(...eventCounts) : 4 // default makes room for 4 stacked icons
    }, [projections.data?.projection])

    const milestones = retirement?.milestone
        ? [
              {
                  ...retirement.milestone,
                  confidence: PlanUtil.CONFIDENCE_INTERVAL,
                  upper: retirement.upper.values.netWorth,
                  lower: retirement.lower.values.netWorth,
              },
          ]
        : []

    const failureDate = projections.data?.projection.data.find((p) =>
        p.values.netWorth.isNegative()
    )?.date

    if (plan.isError || userProfile.isError) {
        return (
            <MainContentOverlay
                title="Unable to load plan"
                actionText="Back home"
                onAction={() => {
                    router.push('/')
                }}
            >
                <p>
                    We&rsquo;re having some trouble loading this plan. Please contact us if the
                    issue persists.
                </p>
            </MainContentOverlay>
        )
    }

    // Don't render anything until we have a dob to use
    if (userProfile.isLoading || plan.isLoading) {
        return (
            <div className="absolute w-full h-full flex flex-col items-center justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    const planData = plan.data
    const user = userProfile.data

    const userAge = DateUtil.dobToAge(user.dob) ?? PlanUtil.DEFAULT_AGE
    const planStartYear = DateTime.now().year
    const planEndYear = DateUtil.ageToYear(
        plan.data?.lifeExpectancy ?? PlanUtil.DEFAULT_LIFE_EXPECTANCY,
        userAge
    )
    const selectedStartYear = selectedYearRange?.from ?? planStartYear
    const selectedEndYear = selectedYearRange?.to ?? planEndYear

    const projectionEndData = projections.data?.projection.data.find(
        (p) => p.values.year === selectedEndYear
    )

    const insufficientData = isReady && (noAccounts || allAccountsDisabled)

    return (
        <div className={classNames('relative', insufficientData && 'max-h-full')}>
            <PlanContext.Provider
                value={{
                    userAge,
                    planStartYear,
                    planEndYear,
                    milestones,
                }}
            >
                <div className="flex items-center justify-between mb-5">
                    <Breadcrumb.Group>
                        <Breadcrumb href="/plans">Plans</Breadcrumb>
                        <Breadcrumb>{planData.name}</Breadcrumb>
                    </Breadcrumb.Group>
                    <PlanMenu plan={planData} />
                </div>

                <h3 className="max-w-lg">
                    At this rate, you&lsquo;ll have
                    {retirement?.projection.values.netWorth ? (
                        ` ${NumberUtil.format(
                            retirement?.projection.values.netWorth,
                            'short-currency'
                        )} by ${retirement.milestone.year}`
                    ) : projectionEndData ? (
                        ` ${NumberUtil.format(
                            projectionEndData.values.netWorth,
                            'short-currency'
                        )} by ${DateTime.fromISO(projectionEndData.date).year}`
                    ) : (
                        <span className="animate-pulse">...</span>
                    )}
                </h3>

                {failureDate != null && (
                    <div className="bg-red bg-opacity-10 rounded px-4 py-2 my-4 flex items-center gap-3 text-red">
                        <RiAlertLine size={18} className="shrink-0" />
                        <p className="text-base">
                            Your plan is failing. This usually means that your current expenses
                            exceed your income. To fix this, please edit your income and expense
                            events.
                        </p>
                    </div>
                )}

                {/* Range selector */}
                <div className="mt-4">
                    <PlanRangeSelector
                        fromYear={selectedStartYear}
                        toYear={selectedEndYear}
                        onChange={(range) => setSelectedYearRange(range)}
                        mode={mode}
                        onModeChange={setMode}
                    />
                </div>

                {/* Chart area */}
                <div className="mt-4 mb-7 h-[450px]">
                    <RetirementPlanChart
                        isLoading={projections.isLoading || projections.isRefetching}
                        isError={projections.isError}
                        data={projections.data}
                        dateRange={{
                            start: DateTime.fromObject({ year: selectedStartYear }),
                            end: DateTime.fromObject({ year: selectedEndYear }),
                        }}
                        retirement={retirement}
                        onAddEvent={(date) => {
                            setAddScenario({
                                isOpen: true,
                                scenarioYear: DateTime.fromISO(date).year,
                            })
                        }}
                        maxStackCount={maxIconsPerDatum}
                        failsEarly={failureDate != null}
                        mode={mode}
                    />
                </div>

                <div className="flex items-center justify-between">
                    <h5 className="uppercase">Milestones</h5>
                    <Button
                        className="py-1 px-[8px]" // override default size
                        leftIcon={<RiAddLine className="w-5 h-5" />}
                        onClick={() => setAddScenario({ isOpen: true })}
                    >
                        New
                    </Button>
                </div>

                {/* TODO: Once we add the ability to create multiple, arbitrary milestones, we will need to update this data array */}
                <PlanMilestones
                    isLoading={projections.isLoading || plan.isLoading}
                    onAdd={() => setAddScenario({ isOpen: true })}
                    onEdit={(id) => setEditMilestoneId(id)}
                    onDelete={(id) => {
                        updatePlan.mutate({
                            id: planData.id,
                            data: {
                                milestones: {
                                    delete: [id],
                                },
                            },
                        })
                    }}
                    milestones={milestones}
                    events={plan.data?.events ?? []}
                />

                <InlineQuestionCardGroup
                    className="mt-8"
                    id={`plan_${planId}`}
                    heading="Ask My Advisor"
                    subheading="Get an advisor to review your plan and make adjustments for your goals and risk profile."
                    planId={planData.id}
                    questions={[
                        {
                            icon: RiPercentLine,
                            title: 'What are the tax implications of my retirement savings and investments?',
                        },
                        {
                            icon: RiFolderShieldLine,
                            title: 'What are some ways I can future proof my current plan? ',
                        },
                        {
                            icon: RiExchangeDollarLine,
                            title: 'How can I create a retirement income plan that will last throughout my lifetime?',
                        },
                        {
                            icon: RiFileList2Line,
                            title: 'What are the risks and benefits of different types of retirement accounts?',
                        },
                    ]}
                />

                {/* TODO - this will eventually need to be a switch statement to determine which form to open based on the milestone type  */}
                {plan.data && (
                    <DialogV2
                        open={editMilestoneId !== undefined}
                        title="Retirement"
                        onClose={() => setEditMilestoneId(undefined)}
                    >
                        <RetirementMilestoneForm
                            mode="update"
                            defaultValues={{
                                age: DateUtil.yearToAge(
                                    planData.milestones.find(
                                        (m) =>
                                            m.category === PlanUtil.PlanMilestoneCategory.Retirement
                                    )?.year ?? PlanUtil.RETIREMENT_MILESTONE_AGE,
                                    userAge
                                ),
                            }}
                            onSubmit={async (data) => {
                                await updatePlan.mutateAsync({
                                    id: planData.id,
                                    data: {
                                        milestones: {
                                            update: [
                                                {
                                                    id: editMilestoneId,
                                                    data: { type: 'year', year: data.year },
                                                },
                                            ],
                                        },
                                    },
                                })

                                setEditMilestoneId(undefined)
                            }}
                        />
                    </DialogV2>
                )}

                {plan.data && (
                    <AddPlanScenario
                        plan={planData}
                        isOpen={addScenario.isOpen}
                        scenarioYear={
                            addScenario.scenarioYear ??
                            retirement?.projection.values.year ??
                            DateUtil.ageToYear(
                                PlanUtil.RETIREMENT_MILESTONE_AGE,
                                userAge ?? PlanUtil.DEFAULT_AGE
                            )
                        }
                        onClose={() => setAddScenario({ isOpen: false })}
                        onSubmit={async (data) => {
                            switch (data.scenario) {
                                case 'retirement': {
                                    const { year, monthlySpending } = data.data

                                    await updatePlanTemplate.mutateAsync({
                                        id: planData.id,
                                        data: {
                                            type: 'retirement',
                                            data: {
                                                retirementYear: year,
                                                annualRetirementExpenses: monthlySpending * -12,
                                            },
                                        },
                                    })

                                    break
                                }
                                case 'income':
                                case 'expense': {
                                    await updatePlan.mutateAsync({
                                        id: planData.id,
                                        data: {
                                            events: {
                                                create: [data.data],
                                            },
                                        },
                                    })

                                    closePopout()

                                    break
                                }
                                default: {
                                    throw new Error('Scenario handler not implemented')
                                }
                            }

                            setAddScenario({ isOpen: false })
                        }}
                    />
                )}

                {/* Income/Expense Events */}

                <PlanEventList
                    className="mt-16"
                    isLoading={projections.isLoading}
                    events={planData.events}
                    projection={projections.data?.projection}
                    onCreate={(data) => {
                        updatePlan.mutate({
                            id: planData.id,
                            data: {
                                events: {
                                    create: [data],
                                },
                            },
                        })
                    }}
                    onUpdate={(id, data) => {
                        updatePlan.mutate({
                            id: planData.id,
                            data: {
                                events: {
                                    update: [{ id, data }],
                                },
                            },
                        })
                    }}
                    onDelete={(id) => {
                        updatePlan.mutate({
                            id: planData.id,
                            data: {
                                events: {
                                    delete: [id],
                                },
                            },
                        })
                    }}
                />

                {insufficientData && (
                    <BlurredContentOverlay icon={RiLineChartLine} title="Not enough data">
                        <p>
                            You haven&rsquo;t added enough assets or debts yet to be able to
                            generate a plan. Once you do, you&rsquo;ll be able to see your plan and
                            test different parameters.
                        </p>
                        <Button
                            className="w-full mt-6"
                            onClick={addAccount}
                            data-testid="not-enough-data-add-account-button"
                        >
                            Add account
                        </Button>
                    </BlurredContentOverlay>
                )}
            </PlanContext.Provider>
        </div>
    )
}

PlanDetailPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}

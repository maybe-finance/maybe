import { InsightPopout, usePopoutContext } from '@maybe-finance/client/shared'
import { type SharedType, NumberUtil } from '@maybe-finance/shared'
import type { UseQueryResult } from '@tanstack/react-query'
import { RiArrowLeftDownLine, RiArrowRightUpLine } from 'react-icons/ri'
import { NetWorthInsightCard } from './NetWorthInsightCard'
import { Listbox } from '@maybe-finance/design-system'
import { useMemo, useState } from 'react'
import classNames from 'classnames'
import Decimal from 'decimal.js'
import { IncomeDebtDialog } from './income-debt'
import NetWorthInsightBadge from './NetWorthInsightBadge'
import { NetWorthInsightStateAxis } from '.'
import { incomePayingDebtState, safetyNetState, Explainers } from '../insights'

type NetWorthPrimaryCardGroupProps = {
    query: UseQueryResult<SharedType.UserInsights, unknown>
}

export function NetWorthPrimaryCardGroup({ query }: NetWorthPrimaryCardGroupProps) {
    const { open: openPopout } = usePopoutContext()

    const [incomeDebtModalOpen, setIncomeDebtModalOpen] = useState(false)
    const [trendPeriod, setTrendPeriod] = useState<'Yearly' | 'Monthly' | 'Weekly'>('Yearly')

    const trendValue = useMemo(() => {
        const formatResponse = (data: SharedType.Trend, period: string) => ({
            amount: NumberUtil.format(data.amount, 'short-currency'),
            percent: NumberUtil.format(data.percentage, 'percent', { maximumFractionDigits: 2 }),
            label: ` ${data.direction === 'down' ? 'lost' : 'added'} in the past ${period}`,
            textClass: data.direction === 'down' ? 'text-red' : 'text-teal',
        })

        if (query.error || !query.data) {
            return { amount: '', percent: '', label: '', textClass: 'text-teal' }
        }

        const { yearly, monthly, weekly } = query.data.netWorth

        switch (trendPeriod) {
            case 'Yearly':
                return formatResponse(yearly, 'year')
            case 'Monthly':
                return formatResponse(monthly, 'month')
            case 'Weekly':
                return formatResponse(weekly, 'week')
            default:
                throw new Error('Invalid period specified')
        }
    }, [trendPeriod, query])

    const safetyNet = useMemo<SharedType.UserInsights['safetyNet'] | null>(() => {
        if (query.error || !query.data) {
            return null
        }

        return {
            months: query.data.safetyNet.months.round(),
            spending: query.data.transactionSummary.expenses,
        }
    }, [query])

    const debtIncome = useMemo<SharedType.UserInsights['debtIncome'] | null>(() => {
        if (query.error || !query.data) {
            return null
        }

        return query.data.debtIncome
    }, [query])

    const safetyNetMonths = safetyNet?.months ?? new Decimal(0)

    return (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
            <NetWorthInsightCard
                isLoading={query.isLoading}
                status={query.error ? 'under-construction' : 'active'}
                title="Net worth trend"
                metricValue={trendValue.percent}
                metricDetail={
                    <>
                        <span className={classNames('font-semibold', trendValue.textClass)}>
                            {trendValue.amount}
                        </span>
                        {trendValue.label}
                    </>
                }
                info="This is an indicator of how your net worth is changing over time."
                headerRight={
                    <Listbox
                        onChange={setTrendPeriod}
                        value={trendPeriod}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <Listbox.Button size="small" onClick={(e) => e.stopPropagation()}>
                            {trendPeriod}
                        </Listbox.Button>
                        <Listbox.Options>
                            <Listbox.Option value="Yearly">Yearly</Listbox.Option>
                            <Listbox.Option value="Monthly">Monthly</Listbox.Option>
                            <Listbox.Option value="Weekly">Weekly</Listbox.Option>
                        </Listbox.Options>
                    </Listbox>
                }
                onClick={() =>
                    openPopout(
                        <InsightPopout>
                            <Explainers.NetWorthTrend />
                        </InsightPopout>
                    )
                }
            />
            <NetWorthInsightCard
                isLoading={query.isLoading}
                status="active"
                title="Safety net"
                metricValue={`${
                    safetyNetMonths.lt(24)
                        ? safetyNetMonths.toFixed() + ' month'
                        : safetyNetMonths.lte(120)
                        ? safetyNetMonths.divToInt(12).toFixed() + ' year'
                        : 'Over 10 year'
                }${safetyNetMonths.equals(1) ? '' : 's'}`}
                metricDetail={`Spending ${NumberUtil.format(safetyNet?.spending, 'short-currency', {
                    signDisplay: 'auto',
                })} monthly`}
                info={
                    <>
                        This is the number of months you could pay expenses if you were to only rely
                        on your emergency funds.
                        <NetWorthInsightStateAxis
                            className="mt-3 mb-2"
                            steps={['at-risk', '3M', 'review', '6M', 'healthy', '12M', 'excessive']}
                        />
                    </>
                }
                infoTooltipClassName="!max-w-[450px]"
                headerRight={
                    safetyNet && <NetWorthInsightBadge variant={safetyNetState(safetyNet.months)} />
                }
                onClick={() =>
                    openPopout(
                        <InsightPopout>
                            <Explainers.SafetyNet
                                defaultState={
                                    safetyNet ? safetyNetState(safetyNet.months) : 'healthy'
                                }
                            />
                        </InsightPopout>
                    )
                }
            />
            <NetWorthInsightCard
                isLoading={query.isLoading}
                status="active"
                title="Income paying debt"
                metricValue={NumberUtil.format(debtIncome?.ratio, 'percent', {
                    signDisplay: 'auto',
                    maximumFractionDigits: 2,
                })}
                metricDetail={
                    <div className="flex items-center space-x-2">
                        <RiArrowRightUpLine className="w-5 h-5 text-teal" />
                        <span>{`${NumberUtil.format(
                            debtIncome?.income,
                            'short-currency'
                        )}/mo`}</span>
                        <RiArrowLeftDownLine className="w-5 h-5 text-red" />
                        <span>{`${NumberUtil.format(debtIncome?.debt, 'short-currency')}/mo`}</span>
                        <span
                            role="button"
                            className="ml-1 underline cursor-pointer"
                            onClick={(e) => {
                                e.stopPropagation()
                                setIncomeDebtModalOpen(true)
                            }}
                        >
                            Edit
                        </span>
                        {debtIncome && (
                            <IncomeDebtDialog
                                isOpen={incomeDebtModalOpen}
                                onClose={() => setIncomeDebtModalOpen(false)}
                                data={debtIncome}
                            />
                        )}
                    </div>
                }
                info={
                    <>
                        This is how much of your income is going towards paying debt.
                        <NetWorthInsightStateAxis
                            className="mx-auto w-auto mt-3 mb-2"
                            steps={['28%', 'review', '36%', 'at-risk']}
                        />
                    </>
                }
                infoTooltipClassName="!max-w-[300px]"
                headerRight={
                    debtIncome &&
                    incomePayingDebtState(debtIncome.ratio) !== 'healthy' && (
                        <NetWorthInsightBadge variant={incomePayingDebtState(debtIncome.ratio)} />
                    )
                }
                onClick={() =>
                    openPopout(
                        <InsightPopout>
                            <Explainers.IncomePayingDebt
                                defaultState={
                                    debtIncome ? incomePayingDebtState(debtIncome.ratio) : 'healthy'
                                }
                            />
                        </InsightPopout>
                    )
                }
            />
        </div>
    )
}

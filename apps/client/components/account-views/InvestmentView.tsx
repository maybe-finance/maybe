import {
    type InsightCardOption,
    InsightPopout,
    usePopoutContext,
    useAccountApi,
    InsightGroup,
    TSeries,
} from '@maybe-finance/client/shared'
import {
    AccountMenu,
    Explainers,
    HoldingList,
    InlineQuestionCardGroup,
    InvestmentTransactionList,
    PageTitle,
} from '@maybe-finance/client/features'
import {
    Checkbox,
    DatePickerRange,
    getRangeDescription,
    Listbox,
} from '@maybe-finance/design-system'
import { type SharedType, NumberUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { useCallback, useEffect, useMemo, useState } from 'react'
import {
    RiAddLine,
    RiArrowUpDownLine,
    RiCoinLine,
    RiFileChartLine,
    RiFileSearchLine,
    RiLineChartLine,
    RiPercentLine,
    RiScales3Line,
    RiScalesFill,
    RiStackLine,
    RiSubtractLine,
} from 'react-icons/ri'
import type { IconType } from 'react-icons'
import classNames from 'classnames'

type Props = {
    account?: SharedType.AccountDetail
    balances?: SharedType.AccountBalanceResponse
    dateRange: SharedType.DateRange
    onDateChange: (range: SharedType.DateRange) => void
    isLoading: boolean
    isError: boolean
}

const stockInsightCards: InsightCardOption[] = [
    {
        id: 'profit-loss',
        display: 'Potential gain or loss',
        category: 'General',
        tooltip:
            'The amount you would gain or lose if you sold this entire portfolio today.  This is commonly referred to as "capital gains / losses".',
    },
    {
        id: 'avg-return',
        display: 'Average return',
        category: 'General',
        tooltip:
            'The average return you have achieved over the time period on this portfolio of holdings',
    },
    {
        id: 'net-deposits',
        display: 'Contributions',
        category: 'General',
        tooltip:
            'The total amount you have contributed to this brokerage account.  Deposits increase this number and withdrawals decrease it.',
    },
    {
        id: 'fees',
        display: 'Fees',
        category: 'Cost',
        tooltip:
            'The total brokerage and other fees you have incurred while buying and selling holdings',
    },
    {
        id: 'sector-allocation',
        display: 'Sector allocation',
        category: 'Market',
        tooltip: 'Shows how diverse your portfolio is',
    },
]

const transactionsFilters: {
    name: string
    icon: IconType
    data: { category?: SharedType.InvestmentTransactionCategory }
}[] = [
    {
        name: 'Show all',
        icon: RiStackLine,
        data: {},
    },
    {
        name: 'Buys',
        icon: RiAddLine,
        data: { category: 'buy' },
    },
    {
        name: 'Sales',
        icon: RiSubtractLine,
        data: { category: 'sell' },
    },
    {
        name: 'Dividends',
        icon: RiPercentLine,
        data: { category: 'dividend' },
    },
    {
        name: 'Transfers',
        icon: RiArrowUpDownLine,
        data: { category: 'transfer' },
    },
    {
        name: 'Fees',
        icon: RiCoinLine,
        data: { category: 'fee' },
    },
]

const returnPeriods: { key: 'ytd' | '1y' | '1m'; display: string }[] = [
    { key: 'ytd', display: 'This year' },
    { key: '1y', display: 'Past year' },
    { key: '1m', display: 'Past month' },
]

const contributionPeriods = [
    { key: 'ytd', display: 'This year' },
    { key: 'lastYear', display: 'Last year' },
]

const chartViews = [
    { key: 'value', display: 'Value', icon: RiLineChartLine },
    { key: 'return', display: 'Return', icon: RiLineChartLine },
]

type Comparison = { ticker: string; display: string; color: string }

const comparisonTickers: Comparison[] = [
    {
        ticker: 'VOO',
        display: 'S&P 500',
        color: 'teal',
    },
    {
        ticker: 'DIA',
        display: 'Dow Jones Industrial Avg',
        color: 'red',
    },
    {
        ticker: 'VONE',
        display: 'Russell 1000',
        color: 'indigo',
    },
    {
        ticker: 'QQQ',
        display: 'NASDAQ 100',
        color: 'grape',
    },
    {
        ticker: 'VT',
        display: 'Total World Stock Index',
        color: 'yellow',
    },
    {
        ticker: 'GLDM',
        display: 'Gold',
        color: 'blue',
    },
    {
        ticker: 'X:BTCUSD',
        display: 'Bitcoin',
        color: 'orange',
    },
    {
        ticker: 'X:ETHUSD',
        display: 'Ethereum',
        color: 'gray',
    },
]

export default function InvestmentView({
    account,
    balances,
    dateRange,
    onDateChange,
    isLoading,
    isError,
}: Props) {
    const [selectedComparisons, setSelectedComparisons] = useState<Comparison[]>([])
    const [chartView, setChartView] = useState(chartViews[0])
    const [showContributions, setShowContributions] = useState(false)

    const { open: openPopout } = usePopoutContext()

    const [returnPeriod, setReturnPeriod] = useState(returnPeriods[0])
    const [contributionPeriod, setContributionPeriod] = useState(contributionPeriods[0])

    const { useAccountInsights, useAccountReturns } = useAccountApi()

    const returns = useAccountReturns(
        {
            id: account?.id ?? -1,
            start: dateRange.start,
            end: dateRange.end,
            compare: selectedComparisons.map((c) => c.ticker),
        },
        {
            enabled: !!account?.id,
            keepPreviousData: true,
        }
    )

    const insights = useAccountInsights(account?.id ?? -1, { enabled: !!account?.id })

    const stocksAllocation = useMemo(() => {
        const stockPercent =
            insights.data?.portfolio?.holdingBreakdown
                .find((hb) => hb.asset_class === 'stocks')
                ?.percentage.toNumber() ?? 0

        return {
            stocks: Math.round(stockPercent * 100),
            other: Math.round(100 - stockPercent * 100),
        }
    }, [insights.data])

    const allTimeRange = useMemo(() => {
        return {
            label: 'All',
            labelShort: 'All',
            start: balances?.minDate ?? DateTime.now().minus({ years: 2 }).toISODate(),
            end: DateTime.now().toISODate(),
        }
    }, [balances])

    const returnColorAccessorFn = useCallback<
        TSeries.AccessorFn<{ rateOfReturn: SharedType.Decimal }, string>
    >((datum) => {
        return datum.values?.rateOfReturn?.lessThan(0) ? '#FF8787' : '#38D9A9' // text-red and text-teal
    }, [])

    const [transactionFilter, setTransactionFilter] = useState(transactionsFilters[0])

    // Whenever user modifies the comparisons dropdown, always go to "Returns" view
    useEffect(() => {
        if (selectedComparisons.length > 0) {
            setChartView(chartViews[1])
        }
    }, [selectedComparisons])

    return (
        <div className="space-y-5">
            <div className="flex justify-between">
                <PageTitle
                    isLoading={isLoading}
                    title={account?.name}
                    value={NumberUtil.format(balances?.today?.balance, 'currency')}
                    trend={balances?.trend}
                    trendLabel={getRangeDescription(dateRange, balances?.minDate)}
                />
                <AccountMenu account={account} />
            </div>

            <div className="flex justify-between flex-wrap gap-2">
                <div className="flex items-center flex-wrap gap-2">
                    <Listbox className="inline-block" value={chartView} onChange={setChartView}>
                        <Listbox.Button icon={chartView.icon}>{chartView.display}</Listbox.Button>
                        <Listbox.Options>
                            {chartViews.map((view) => (
                                <Listbox.Option key={view.key} value={view}>
                                    {view.display}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox>
                    <Listbox value={selectedComparisons} onChange={setSelectedComparisons} multiple>
                        <Listbox.Button icon={RiScalesFill}>
                            <span className="text-white text-base font-medium">Compare</span>
                        </Listbox.Button>
                        <Listbox.Options placement="bottom-start" className="min-w-[210px]">
                            {comparisonTickers.map((comparison) => (
                                <Listbox.Option
                                    key={comparison.ticker}
                                    value={comparison}
                                    className="my-2 whitespace-nowrap"
                                >
                                    {comparison.display}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox>
                    {chartView.key === 'value' && (
                        <div className="py-2">
                            <Checkbox
                                label="Show contribution"
                                onChange={setShowContributions}
                                checked={showContributions}
                                className="ml-1"
                            />
                        </div>
                    )}
                </div>

                <DatePickerRange
                    variant="tabs-custom"
                    minDate={balances?.minDate}
                    maxDate={DateTime.now().toISODate()}
                    value={dateRange}
                    onChange={onDateChange}
                    selectableRanges={[
                        'last-7-days',
                        'last-30-days',
                        'last-90-days',
                        'last-365-days',
                        allTimeRange,
                    ]}
                />
            </div>

            <div className="h-96">
                <TSeries.Chart<Record<string, SharedType.Decimal>>
                    id="investment-account-chart"
                    isLoading={isLoading}
                    isError={isError || returns.isError}
                    dateRange={dateRange}
                    data={{
                        balances:
                            balances?.series.data.map((d) => ({
                                date: d.date,
                                values: { balance: d.balance },
                            })) ?? [],
                        returns:
                            returns.data?.data.map((d) => ({
                                date: d.date,
                                values: { ...d.account, ...d.comparisons },
                            })) ?? [],
                    }}
                    series={[
                        {
                            key: 'portfolio-balance',
                            dataKey: 'balances',
                            accessorFn: (d) => d?.values?.balance?.toNumber(),
                            isActive: chartView.key === 'value',
                        },
                        {
                            key: 'contributions',
                            dataKey: 'returns',
                            accessorFn: (d) => d.values.contributions?.toNumber(),
                            isActive: showContributions && chartView.key === 'value',
                            color: TSeries.tailwindScale('grape'),
                        },
                        {
                            key: 'portfolio-return',
                            dataKey: 'returns',
                            accessorFn: (d) => d.values.rateOfReturn?.toNumber(),
                            isActive: chartView.key === 'return',
                            format: 'percent',
                            label: 'Portfolio return',
                            color:
                                selectedComparisons.length > 0
                                    ? TSeries.tailwindScale('cyan')
                                    : returnColorAccessorFn,
                        },
                        ...selectedComparisons.map(({ ticker, display, color }) => ({
                            key: ticker,
                            dataKey: 'returns',
                            accessorFn: (d) => {
                                return d.values?.[ticker]?.toNumber()
                            },
                            isActive: chartView.key === 'return' && selectedComparisons.length > 0,
                            label: `${display} return`,
                            format: 'percent' as SharedType.FormatString,
                            color: TSeries.tailwindScale(color),
                        })),
                    ]}
                    y1Axis={
                        <TSeries.AxisLeft
                            tickFormat={(v) =>
                                NumberUtil.format(
                                    v as number,
                                    chartView.key === 'return' ? 'percent' : 'short-currency'
                                )
                            }
                        />
                    }
                    // If showing returns graph, render a date range for the tooltip title
                    tooltipOptions={
                        chartView.key === 'return' && returns.data && returns.data.data.length > 0
                            ? {
                                  tooltipTitle: (tooltipData) =>
                                      `${DateTime.fromISO(returns.data.data[0].date).toFormat(
                                          'MMM dd, yyyy'
                                      )} - ${DateTime.fromISO(tooltipData.date).toFormat(
                                          'MMM dd, yyyy'
                                      )}`,
                              }
                            : undefined
                    }
                >
                    <TSeries.Line seriesKey="portfolio-balance" />

                    <TSeries.Line seriesKey="portfolio-return" />

                    <TSeries.Line seriesKey="contributions" strokeDasharray={4} />

                    {selectedComparisons.map((comparison) => (
                        <TSeries.Line key={comparison.ticker} seriesKey={comparison.ticker} />
                    ))}
                </TSeries.Chart>
            </div>

            {account && (
                <div>
                    <InsightGroup
                        id="investment-account-insights"
                        options={stockInsightCards}
                        initialInsights={['avg-return', 'profit-loss', 'net-deposits']}
                    >
                        <InsightGroup.Card
                            id="avg-return"
                            isLoading={insights.isLoading}
                            status="active"
                            onClick={() =>
                                openPopout(
                                    <InsightPopout>
                                        <Explainers.AverageReturn />
                                    </InsightPopout>
                                )
                            }
                            headerRight={
                                <Listbox
                                    onChange={setReturnPeriod}
                                    value={returnPeriod}
                                    onClick={(e) => e.stopPropagation()}
                                >
                                    <Listbox.Button
                                        size="small"
                                        onClick={(e) => e.stopPropagation()}
                                    >
                                        {returnPeriod.display}
                                    </Listbox.Button>

                                    <Listbox.Options>
                                        {returnPeriods.map((rp) => (
                                            <Listbox.Option key={rp.key} value={rp}>
                                                {rp.display}
                                            </Listbox.Option>
                                        ))}
                                    </Listbox.Options>
                                </Listbox>
                            }
                        >
                            {(() => {
                                const returnValues =
                                    insights.data?.portfolio?.return?.[returnPeriod.key]

                                return (
                                    <>
                                        <h3>
                                            {NumberUtil.format(
                                                returnValues?.percentage,
                                                'percent',
                                                { signDisplay: 'auto', maximumFractionDigits: 1 }
                                            )}
                                        </h3>
                                        <span className="text-gray-100 text-base">
                                            <span
                                                className={classNames(
                                                    returnValues?.direction === 'up'
                                                        ? 'text-teal'
                                                        : returnValues?.direction === 'down'
                                                        ? 'text-red'
                                                        : null
                                                )}
                                            >
                                                {NumberUtil.format(
                                                    returnValues?.amount,
                                                    'currency',
                                                    {
                                                        signDisplay: 'exceptZero',
                                                    }
                                                )}
                                            </span>{' '}
                                            {returnPeriod.display.toLowerCase()}
                                        </span>
                                    </>
                                )
                            })()}
                        </InsightGroup.Card>

                        <InsightGroup.Card
                            id="profit-loss"
                            isLoading={false}
                            status="active"
                            onClick={() =>
                                openPopout(
                                    <InsightPopout>
                                        <Explainers.PotentialGainLoss />
                                    </InsightPopout>
                                )
                            }
                        >
                            <h3>
                                {NumberUtil.format(
                                    insights.data?.portfolio?.pnl?.amount,
                                    'currency',
                                    { signDisplay: 'exceptZero' }
                                )}
                            </h3>
                            <span className="text-base text-gray-100">as of today</span>
                        </InsightGroup.Card>

                        <InsightGroup.Card
                            id="net-deposits"
                            isLoading={false}
                            status="active"
                            onClick={() =>
                                openPopout(
                                    <InsightPopout>
                                        <Explainers.Contributions />
                                    </InsightPopout>
                                )
                            }
                            headerRight={
                                <Listbox
                                    onChange={setContributionPeriod}
                                    value={contributionPeriod}
                                    onClick={(e) => e.stopPropagation()}
                                >
                                    <Listbox.Button
                                        size="small"
                                        onClick={(e) => e.stopPropagation()}
                                    >
                                        {contributionPeriod.display}
                                    </Listbox.Button>

                                    <Listbox.Options>
                                        {contributionPeriods.map((cp) => (
                                            <Listbox.Option key={cp.key} value={cp}>
                                                {cp.display}
                                            </Listbox.Option>
                                        ))}
                                    </Listbox.Options>
                                </Listbox>
                            }
                        >
                            <h3>
                                {NumberUtil.format(
                                    insights?.data?.portfolio?.contributions[contributionPeriod.key]
                                        .amount,
                                    'currency',
                                    { signDisplay: 'exceptZero' }
                                )}
                            </h3>
                            <span className="text-gray-100 text-base">Average:</span>
                            <span className="text-gray-25 ml-1 text-base">
                                {NumberUtil.format(
                                    insights?.data?.portfolio?.contributions[contributionPeriod.key]
                                        .monthlyAvg,
                                    'short-currency',
                                    { signDisplay: 'exceptZero' }
                                )}
                                /mo
                            </span>
                        </InsightGroup.Card>

                        <InsightGroup.Card
                            id="fees"
                            isLoading={false}
                            status="active"
                            onClick={() =>
                                openPopout(
                                    <InsightPopout>
                                        <Explainers.TotalFees />
                                    </InsightPopout>
                                )
                            }
                        >
                            <h3>
                                {NumberUtil.format(insights.data?.portfolio?.fees, 'currency', {
                                    signDisplay: 'auto',
                                })}
                            </h3>
                            <span className="text-base text-gray-100">all time</span>
                        </InsightGroup.Card>

                        <InsightGroup.Card
                            id="sector-allocation"
                            isLoading={false}
                            status={'active'}
                            onClick={() =>
                                openPopout(
                                    <InsightPopout>
                                        <Explainers.SectorAllocation />
                                    </InsightPopout>
                                )
                            }
                        >
                            <h3>
                                {stocksAllocation.stocks}/{stocksAllocation.other} split
                            </h3>
                            <span className="text-base text-gray-100">
                                {stocksAllocation.stocks}% in stocks and {stocksAllocation.other}%
                                in other
                            </span>
                        </InsightGroup.Card>
                    </InsightGroup>

                    <InlineQuestionCardGroup
                        className="mb-8"
                        id={`investment_account_${account.id}`}
                        heading="Ask My Advisor"
                        subheading="Get an advisor to review this account and make adjustments for your goals and risk profile."
                        accountId={account.id}
                        questions={[
                            {
                                icon: RiFileSearchLine,
                                title: 'Can you review and give me feedback on my overall strategy?',
                            },
                            {
                                icon: RiScales3Line,
                                title: 'What do you make of my current allocation? Am I over/under weighted somewhere?',
                            },
                            {
                                icon: RiFileChartLine,
                                title: 'Where do you think my portfolio is currently underperforming or could do better?',
                            },
                            {
                                icon: RiLineChartLine,
                                title: 'Are there any benefits to having a mix of cyclical and defensive stocks in my portfolio?',
                            },
                        ]}
                    />

                    <h5 className="uppercase mb-5">Holdings</h5>
                    <HoldingList accountId={account.id} />

                    <div className="flex items-center justify-between mt-2 mb-4">
                        <h5 className="uppercase mt-2 mb-4">Transactions</h5>
                        <Listbox value={transactionFilter} onChange={setTransactionFilter}>
                            <Listbox.Button icon={transactionFilter.icon}>
                                {transactionFilter.name}
                            </Listbox.Button>
                            <Listbox.Options placement="bottom-end">
                                {transactionsFilters.map((filter) => (
                                    <Listbox.Option
                                        key={filter.name}
                                        value={filter}
                                        icon={filter.icon}
                                    >
                                        {filter.name}
                                    </Listbox.Option>
                                ))}
                            </Listbox.Options>
                        </Listbox>
                    </div>
                    <InvestmentTransactionList
                        accountId={account.id}
                        filter={transactionFilter.data}
                    />
                </div>
            )}
        </div>
    )
}

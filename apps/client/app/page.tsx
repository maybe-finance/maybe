'use client'

import type { ReactElement } from 'react'
import { useState } from 'react'
import {
    WithSidebarLayout,
    NetWorthInsightDetail,
    NetWorthPrimaryCardGroup,
    PageTitle,
    AccountSidebar,
} from '@maybe-finance/client/features'
import {
    MainContentOverlay,
    useAccountApi,
    useUserApi,
    useAccountContext,
    useUserAccountContext,
    TSeries,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import uniq from 'lodash/uniq'
import { NumberUtil } from '@maybe-finance/shared'
import { DatePickerRange, getRangeDescription, Listbox } from '@maybe-finance/design-system'
import { RiLineChartLine } from 'react-icons/ri'
import type { AccountCategory } from '@prisma/client'

function NoAccounts() {
    const { addAccount } = useAccountContext()

    return (
        <MainContentOverlay title="No accounts yet" actionText="Add account" onAction={addAccount}>
            <p>You currently have no connected or manual accounts. Start by adding an account.</p>
        </MainContentOverlay>
    )
}

function AllAccountsDisabled() {
    const { addAccount } = useAccountContext()

    // This user does not have any active accounts
    return (
        <MainContentOverlay
            title="No accounts enabled"
            actionText="Add account"
            onAction={addAccount}
        >
            <p>All your accounts are currently disabled. Enable one or connect a new account.</p>
        </MainContentOverlay>
    )
}

const chartViews = [
    {
        value: 'net-worth',
        display: 'Net worth value',
    },
    {
        value: 'assets-debts',
        display: 'Assets & debts',
    },
    {
        value: 'all',
        display: 'All categories',
    },
]

const categoryColors = ['blue', 'teal', 'orange', 'pink', 'grape', 'green', 'red', 'indigo', 'cyan']

export default function IndexPage() {
    const [chartView, setChartView] = useState(chartViews[0])

    const { useNetWorthSeries, useInsights } = useUserApi()
    const { useAccounts } = useAccountApi()

    const { isReady, someAccountsSyncing, noAccounts, allAccountsDisabled } =
        useUserAccountContext()

    const { dateRange, setDateRange } = useAccountContext()

    const accountsQuery = useAccounts()
    const insightsQuery = useInsights()

    const netWorthQuery = useNetWorthSeries(
        { start: dateRange.start, end: dateRange.end },
        { enabled: isReady && !noAccounts && !allAccountsDisabled }
    )

    const isLoading = someAccountsSyncing || accountsQuery.isLoading || netWorthQuery.isLoading

    if (netWorthQuery.error || accountsQuery.error) {
        return (
            <MainContentOverlay
                title="Unable to load data"
                actionText="Try again"
                onAction={() => {
                    netWorthQuery.refetch()
                }}
            >
                <p>
                    We&rsquo;re having some trouble loading your data. Please contact us if the
                    issue persists...
                </p>
            </MainContentOverlay>
        )
    }

    // This user has not created any accounts yet
    if (noAccounts) {
        return <NoAccounts />
    }

    if (allAccountsDisabled) {
        return <AllAccountsDisabled />
    }

    const seriesData = netWorthQuery.data?.series.data ?? []

    const categoriesWithData = uniq(
        seriesData.flatMap((d) =>
            Object.entries(d.categories)
                .filter(([_category, amount]) => !amount.isZero())
                .map(([category, _amount]) => category as AccountCategory)
        ) ?? []
    )

    return (
        <div className="space-y-5">
            <PageTitle
                isLoading={isLoading}
                title="Net worth"
                value={NumberUtil.format(netWorthQuery.data?.today?.netWorth, 'currency')}
                trend={netWorthQuery.data?.trend}
                trendLabel={getRangeDescription(dateRange, netWorthQuery.data?.minDate)}
            />

            <div className="flex flex-wrap justify-between items-center gap-2">
                <Listbox className="inline-block" value={chartView} onChange={setChartView}>
                    <Listbox.Button icon={RiLineChartLine}>{chartView.display}</Listbox.Button>
                    <Listbox.Options>
                        {chartViews.map((view) => (
                            <Listbox.Option key={view.value} value={view}>
                                {view.display}
                            </Listbox.Option>
                        ))}
                    </Listbox.Options>
                </Listbox>

                <DatePickerRange
                    variant="tabs-custom"
                    minDate={netWorthQuery.data && netWorthQuery.data.minDate}
                    maxDate={DateTime.now().toISODate()}
                    value={dateRange}
                    onChange={setDateRange}
                    selectableRanges={[
                        'last-30-days',
                        'last-90-days',
                        'last-365-days',
                        'this-year',
                        {
                            label: 'All time',
                            labelShort: 'All',
                            start: netWorthQuery.data
                                ? netWorthQuery.data.minDate
                                : DateTime.now().minus({ years: 3 }).toISODate(),
                            end: DateTime.now().toISODate(),
                        },
                    ]}
                />
            </div>

            <div className="h-96">
                <TSeries.Chart
                    id="net-worth-chart"
                    dateRange={dateRange}
                    interval={netWorthQuery.data?.series.interval}
                    tooltipOptions={{ renderInPortal: true }}
                    isLoading={netWorthQuery.isLoading}
                    isError={netWorthQuery.isError}
                    data={seriesData.map(({ date, ...values }) => ({ date, values }))}
                    series={[
                        {
                            key: 'net-worth',
                            label: chartView.value === 'net-worth' ? undefined : 'Net worth',
                            accessorFn: (d) => d.values?.netWorth?.toNumber(),
                            isActive: chartView.value !== 'all',
                            color: TSeries.tailwindScale('cyan'),
                        },
                        {
                            key: 'assets',
                            label: 'Assets',
                            accessorFn: (d) => d.values?.assets?.toNumber(),
                            isActive: chartView.value === 'assets-debts',
                            color: TSeries.tailwindScale('teal'),
                        },
                        {
                            key: 'liabilities',
                            label: 'Debts',
                            accessorFn: (d) => d.values?.liabilities?.toNumber(),
                            isActive: chartView.value === 'assets-debts',
                            color: TSeries.tailwindScale('red'),
                        },
                        ...categoriesWithData.map((category, idx) => ({
                            key: category,
                            accessorFn: (d) => d.values?.categories?.[category]?.toNumber(),
                            label: category,
                            isActive: chartView.value === 'all',
                            color: TSeries.tailwindScale(categoryColors[idx]),
                        })),
                    ]}
                >
                    <TSeries.Line seriesKey="assets" gradientOpacity={0.1} />
                    <TSeries.Line seriesKey="liabilities" gradientOpacity={0.1} />

                    {categoriesWithData.map((category) => (
                        <TSeries.Line key={category} seriesKey={category} gradientOpacity={0.1} />
                    ))}

                    {/* Keep at bottom so net worth line always has the highest stack index */}
                    <TSeries.Line
                        seriesKey="net-worth"
                        gradientOpacity={chartView.value === 'net-worth' ? 0.2 : 0.1}
                    />
                </TSeries.Chart>
            </div>

            <div>
                {insightsQuery.isError ? (
                    <div className="my-6 p-10 rounded-lg bg-gray-800 text-gray-100">
                        <p>Something went wrong loading your metrics. Please contact us.</p>
                    </div>
                ) : (
                    <div className="space-y-6">
                        <NetWorthPrimaryCardGroup query={insightsQuery} />
                        <NetWorthInsightDetail query={insightsQuery} />
                    </div>
                )}
            </div>
        </div>
    )
}

IndexPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}

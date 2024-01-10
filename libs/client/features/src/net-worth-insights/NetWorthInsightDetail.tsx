import type { PropsWithChildren } from 'react'
import type { UseQueryResult } from '@tanstack/react-query'
import { type SharedType, NumberUtil } from '@maybe-finance/shared'
import {
    type ClientType,
    useAccountApi,
    InsightPopout,
    usePopoutContext,
} from '@maybe-finance/client/shared'
import { NetWorthBreakdownSlider } from './breakdown-slider'
import { NetWorthBreakdownTable } from './breakdown-table'
import { NetWorthInsightCard } from './NetWorthInsightCard'
import { DateTime } from 'luxon'
import { Explainers } from '../insights'
import { InlineQuestionCardGroup } from '../ask-the-advisor'
import { RiBubbleChartLine, RiPercentLine, RiPieChartLine, RiScales3Line } from 'react-icons/ri'
import classNames from 'classnames'

type NetWorthInsightDetailProps = {
    query: UseQueryResult<SharedType.UserInsights, unknown>
}

export function NetWorthInsightDetail({ query }: NetWorthInsightDetailProps) {
    const { open: openPopout } = usePopoutContext()

    const { useAccountRollup } = useAccountApi()

    const accountRollupQuery = useAccountRollup(
        {
            start: DateTime.now().toISODate(),
            end: DateTime.now().toISODate(),
        },
        { enabled: true }
    )

    const hasAssets = !!accountRollupQuery.data?.find(({ key }) => key === 'asset')
    const hasDebts = !!accountRollupQuery.data?.find(({ key }) => key === 'liability')

    return (
        <div className="flex flex-col">
            <h5 className="uppercase">Assets</h5>
            <BreakdownTabPanel classification="asset" query={accountRollupQuery} status="active">
                <NetWorthInsightCard
                    isLoading={query.isLoading}
                    status="active"
                    title="Assets that work for you"
                    metricValue={NumberUtil.format(
                        query.data?.assetSummary.yielding.amount,
                        'currency',
                        {
                            minimumFractionDigits: 0,
                            maximumFractionDigits: 0,
                        }
                    )}
                    metricDetail={`${NumberUtil.format(
                        query.data?.assetSummary.yielding.percentage,
                        'percent',
                        { signDisplay: 'auto' }
                    )} of assets are adding to your net worth`}
                    info="These are assets that you own that provide some sort of return in the form of interest or recurring payments."
                    onClick={() =>
                        openPopout(
                            <InsightPopout>
                                <Explainers.YieldingAssets />
                            </InsightPopout>
                        )
                    }
                />
                <NetWorthInsightCard
                    isLoading={query.isLoading}
                    status="active"
                    title="Easy to cash in assets"
                    metricValue={NumberUtil.format(
                        query.data?.assetSummary.liquid.amount,
                        'currency',
                        { minimumFractionDigits: 0, maximumFractionDigits: 0 }
                    )}
                    metricDetail={`${NumberUtil.format(
                        query.data?.assetSummary.liquid.percentage,
                        'percent',
                        { signDisplay: 'auto' }
                    )} of all assets`}
                    info="These are assets you own that can easily be converted into spendable cash within a short period of time."
                    onClick={() =>
                        openPopout(
                            <InsightPopout>
                                <Explainers.LiquidAssets />
                            </InsightPopout>
                        )
                    }
                />
                <NetWorthInsightCard
                    isLoading={query.isLoading}
                    status="active"
                    title="Hard to cash in assets"
                    metricValue={NumberUtil.format(
                        query.data?.assetSummary.illiquid.amount,
                        'currency',
                        { minimumFractionDigits: 0, maximumFractionDigits: 0 }
                    )}
                    metricDetail={`${NumberUtil.format(
                        query.data?.assetSummary.illiquid.percentage,
                        'percent',
                        { signDisplay: 'auto' }
                    )} of all assets`}
                    info="These are assets you own that will take a significant amount of time to convert into spendable cash."
                    onClick={() =>
                        openPopout(
                            <InsightPopout>
                                <Explainers.IlliquidAssets />
                            </InsightPopout>
                        )
                    }
                />
            </BreakdownTabPanel>

            {(hasAssets || hasDebts) && (
                <InlineQuestionCardGroup
                    className={classNames('mt-12', !hasAssets && 'order-last')}
                    id="assets_debts"
                    heading="Ask My Advisor"
                    subheading="Get an advisor to review your asset allocation or debt situation."
                    questions={[
                        {
                            icon: RiPieChartLine,
                            title: 'Can you review my current allocation and suggest ways to rebalance?',
                        },
                        {
                            icon: RiScales3Line,
                            title: 'How can I go about consolidating or reducing my current debts?',
                        },
                        {
                            icon: RiPercentLine,
                            title: 'Can you explain how tax implications can impact my asset allocation strategy?',
                        },
                        {
                            icon: RiBubbleChartLine,
                            title: 'In my current state, do you recommend taking on more debt to finance new assets?',
                        },
                    ]}
                />
            )}

            <h5 className="mt-9 uppercase">Debts</h5>
            <BreakdownTabPanel
                classification="liability"
                query={accountRollupQuery}
                status="active"
            >
                <NetWorthInsightCard
                    isLoading={query.isLoading}
                    status="active"
                    title="Total debt ratio"
                    metricValue={NumberUtil.format(query.data?.debtAsset.ratio, 'percent', {
                        signDisplay: 'auto',
                        maximumFractionDigits: 2,
                    })}
                    metricDetail="debt as a % of total assets"
                    info="This is the measure of your borrowing ability in relation to your assets."
                    onClick={() =>
                        openPopout(
                            <InsightPopout>
                                <Explainers.TotalDebtRatio />
                            </InsightPopout>
                        )
                    }
                />
                <NetWorthInsightCard
                    isLoading={query.isLoading}
                    status="active"
                    title="Good debt"
                    metricValue={NumberUtil.format(
                        query.data?.debtSummary.good.percentage,
                        'percent',
                        { signDisplay: 'auto', maximumFractionDigits: 2 }
                    )}
                    metricDetail="of debt is building wealth"
                    info="This is debt that grows future wealth such as a student loan, or builds equity in a productive asset such as a mortgage."
                    onClick={() =>
                        openPopout(
                            <InsightPopout>
                                <Explainers.GoodDebt />
                            </InsightPopout>
                        )
                    }
                />
                <NetWorthInsightCard
                    isLoading={query.isLoading}
                    status="active"
                    title="Bad debt"
                    metricValue={NumberUtil.format(
                        query.data?.debtSummary.bad.percentage,
                        'percent',
                        { signDisplay: 'auto', maximumFractionDigits: 2 }
                    )}
                    metricDetail="of debt is not building wealth"
                    info="Bad debt is debt that provides no future value to you such as a personal loan or credit card debt."
                    onClick={() =>
                        openPopout(
                            <InsightPopout>
                                <Explainers.BadDebt />
                            </InsightPopout>
                        )
                    }
                />
            </BreakdownTabPanel>
        </div>
    )
}

function BreakdownTabPanel({
    query,
    classification,
    status,
    children,
}: PropsWithChildren<{
    classification: SharedType.AccountClassification
    query: UseQueryResult<SharedType.AccountRollup>
    status?: ClientType.MetricStatus
}>) {
    const rollup = query.data?.find(({ key }) => key === classification)
    if (rollup) {
        rollup.items.sort((a, b) =>
            b.balances.data[b.balances.data.length - 1].balance
                .minus(a.balances.data[a.balances.data.length - 1].balance)
                .toNumber()
        )
    }

    return (
        <div className="space-y-4">
            <div>
                <ComingSoonBlur metricStatus={status}>
                    {query.isError ? (
                        <p className="text-gray-100">
                            Failed to load {classification === 'asset' ? 'asset' : 'debt'} breakdown
                        </p>
                    ) : !query.isLoading && !rollup ? (
                        <p className="text-gray-100">
                            No {classification === 'asset' ? 'assets' : 'debts'} found
                        </p>
                    ) : (
                        <div>
                            <NetWorthBreakdownSlider isLoading={query.isLoading} rollup={rollup} />
                            <div className="mt-4 mb-7 grid gap-4 grid-cols-1 md:grid-cols-2 xl:grid-cols-3">
                                {children}
                            </div>
                            <NetWorthBreakdownTable isLoading={query.isLoading} rollup={rollup} />
                        </div>
                    )}
                </ComingSoonBlur>
            </div>
        </div>
    )
}

function ComingSoonBlur({
    children,
    metricStatus,
}: PropsWithChildren<{ metricStatus?: ClientType.MetricStatus }>) {
    if (metricStatus === 'active') return children as JSX.Element

    return (
        <div className="relative">
            {children}
            <div className="flex items-center justify-center absolute top-0 left-0 w-full h-full bg-black bg-opacity-70 backdrop-blur-sm">
                <div className="text-center w-2/3 -translate-y-12">
                    {metricStatus === 'coming-soon' && (
                        <>
                            <h4>Coming soon!</h4>
                            <p className="text-gray-50 text-base">
                                We're still working on this section, but instead of just telling
                                you, here's a blurred out teaser of what's coming soon.
                            </p>
                        </>
                    )}

                    {!metricStatus ||
                        (metricStatus === 'under-construction' && (
                            <>
                                <h4>Unavailable</h4>
                                <p className="text-gray-50 text-base">
                                    We're currently fixing this to make sure we show you accurate
                                    figures.
                                </p>
                            </>
                        ))}
                </div>
            </div>
        </div>
    )
}

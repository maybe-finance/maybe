import type { ColumnDef } from '@tanstack/react-table'
import { IndexTabs } from '@maybe-finance/design-system'
import { useMemo, useRef } from 'react'
import { RiArticleLine, RiYoutubeLine } from 'react-icons/ri'
import {
    ExplainerExternalLink,
    ExplainerInfoBlock,
    ExplainerSection,
} from '@maybe-finance/client/shared'
import { flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table'
import { NumberUtil } from '@maybe-finance/shared'
import classNames from 'classnames'

type Props = {
    initialSection?: 'overview' | 'methodology' | 'returns' | 'survival' | 'learn'
}

export function PlanExplainer({ initialSection }: Props) {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const overview = useRef<HTMLDivElement>(null)
    const forecastingMethodology = useRef<HTMLDivElement>(null)
    const returns = useRef<HTMLDivElement>(null)
    const survivalRate = useRef<HTMLDivElement>(null)
    const learnMore = useRef<HTMLDivElement>(null)

    const initialIndex = useMemo(() => {
        switch (initialSection) {
            case 'methodology':
                return 1
            case 'returns':
                return 2
            case 'survival':
                return 3
            case 'learn':
                return 4
            default:
                return 0
        }
    }, [initialSection])

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">How this works</h5>
            <div className="shrink-0 px-4 py-3">
                <IndexTabs
                    initialIndex={initialIndex}
                    scrollContainer={scrollContainer}
                    sections={[
                        { name: 'Overview', elementRef: overview },
                        {
                            name: 'Forecasting methodology',
                            elementRef: forecastingMethodology,
                        },
                        { name: 'Survival rate', elementRef: survivalRate },
                        {
                            name: 'Returns',
                            elementRef: returns,
                        },
                        {
                            name: 'Learn more',
                            elementRef: learnMore,
                        },
                    ]}
                />
            </div>
            <div ref={scrollContainer} className="grow px-4 pb-16 basis-px custom-gray-scroll">
                <ExplainerSection title="Definition" ref={overview} className="space-y-3">
                    <p>
                        To forecast your wealth in future years, we use a technique called a “Monte
                        Carlo simulation”. This is a common technique used by financial planners and
                        hedge funds to predict how a given portfolio of assets will perform based on
                        a variety of market conditions.
                    </p>

                    <p>
                        Luckily, this mathematical technique is not just available to money
                        managers. We can also apply this to your <em>personal</em> portfolio!
                    </p>
                </ExplainerSection>

                <ExplainerSection
                    title="Forecast methodology"
                    ref={forecastingMethodology}
                    className="space-y-3"
                >
                    <p>
                        At Maybe, we can guarantee accurate calculations, but{' '}
                        <span className="text-white font-semibold">
                            we cannot predict your future
                        </span>
                        . Forecasting outcomes over a long time-horizon includes significant
                        uncertainty.
                    </p>

                    <p>
                        We encourage you to treat these results{' '}
                        <span className="text-white font-semibold">
                            as a range of possibilities
                        </span>
                        , not a certainty.
                    </p>

                    <p>Here&rsquo;s an example interpretation of your results:</p>

                    <p>
                        At age 68, your portfolio ranges from, say $100 - $200 at the 10th and 90th
                        "percentiles".
                    </p>

                    <p>
                        This simply means, "We ran 1,000 simulations, and 90% of those simulations
                        resulted in a net worth between $100-$200 at age 68".
                    </p>
                </ExplainerSection>

                <ExplainerSection title="Survival Rate" ref={survivalRate} className="space-y-3">
                    <p className="italic">
                        <span className="font-semibold">Disclaimer:</span> this is an estimate. We
                        cannot guarantee the success of your plan.
                    </p>

                    <p>
                        In each tooltip, you will see a percentage indicator we call "Survival
                        rate". We use this to determine the percentage of simulations that ended up
                        with a positive net worth.
                    </p>

                    <p>
                        Let's say your survival rate is 70%. Assuming we run 1,000 simulations, this
                        means that 700/1000 simulations "survived" (i.e. positive net worth), while
                        300/1000 did not "survive" (i.e. negative net worth) in that year.
                    </p>

                    <ExplainerInfoBlock title="TL;DR">
                        It&rsquo;s your &ldquo;will I ever run out of money?&rdquo; metric.
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection title="Returns" ref={returns} className="space-y-3">
                    <p>
                        Below are the average returns by asset class that we use as <em>inputs</em>{' '}
                        to our Monte Carlo simulation:
                    </p>

                    <div>
                        <ReturnsTable />
                    </div>

                    <p>
                        Negative percentages mean that the asset is either a depreciating asset or
                        losing value due to inflation.
                    </p>
                </ExplainerSection>

                <ExplainerSection title="Learn more" ref={learnMore}>
                    <ExplainerExternalLink
                        icon={RiArticleLine}
                        href="https://www.investopedia.com/terms/m/montecarlosimulation.asp"
                    >
                        Article on Monte Carlo simulations
                    </ExplainerExternalLink>

                    <ExplainerExternalLink
                        icon={RiYoutubeLine}
                        href="https://www.youtube.com/watch?v=7TqhmX92P6U"
                    >
                        Video on Monte Carlo simulations
                    </ExplainerExternalLink>
                </ExplainerSection>
            </div>
        </div>
    )
}

type ReturnsData = {
    asset: string
    return: number
    volatility: number
}

// const columnHelper = createColumnHelper<ReturnsData>()

const returnsData: ReturnsData[] = [
    {
        asset: 'Stocks',
        return: 0.05,
        volatility: 0.186,
    },
    {
        asset: 'Bonds',
        return: 0.02,
        volatility: 0.052,
    },
    {
        asset: 'Cash',
        return: -0.02,
        volatility: 0.05,
    },
    {
        asset: 'Crypto',
        return: 1.0,
        volatility: 1.0,
    },
    {
        asset: 'Property',
        return: 0.1,
        volatility: 0.2,
    },
    {
        asset: 'Other',
        return: -0.02,
        volatility: 0,
    },
]

function ReturnsTable() {
    const columns = useMemo(() => {
        return [
            {
                header: 'Asset',
                accessorKey: 'asset',
            },
            {
                id: 'return',
                header: 'Return',
                accessorFn: (row) =>
                    NumberUtil.format(row.return, 'percent', { signDisplay: 'auto' }),
            } as ColumnDef<ReturnsData, ReturnsData['return']>,
            {
                id: 'volatility',
                header: 'Volatility',
                accessorFn: (row) =>
                    NumberUtil.format(row.volatility, 'percent', { signDisplay: 'auto' }),
            } as ColumnDef<ReturnsData, ReturnsData['volatility']>,
        ]
    }, [])

    const table = useReactTable({
        data: returnsData,
        columns,
        getCoreRowModel: getCoreRowModel(),
    })

    return (
        <table className="table-fixed min-w-full gap-x-5 text-base">
            <thead>
                {table.getHeaderGroups().map((headerGroup) => (
                    <tr key={headerGroup.id}>
                        {headerGroup.headers.map((header) => (
                            <th
                                key={header.id}
                                colSpan={header.colSpan}
                                className="whitespace-nowrap text-gray-100 text-right first:text-left font-normal"
                            >
                                {!header.isPlaceholder &&
                                    flexRender(header.column.columnDef.header, header.getContext())}
                            </th>
                        ))}
                    </tr>
                ))}
            </thead>
            <tbody>
                {table.getRowModel().rows.map((row) => (
                    <tr key={row.id} className="cursor-pointer hover:bg-gray-800">
                        {row.getVisibleCells().map((cell) => (
                            <td
                                key={cell.id}
                                className={classNames(
                                    'py-3 first:rounded-l-lg last:rounded-r-lg whitespace-nowrap truncate text-white font-medium border-b border-b-gray-700 text-right first:text-left'
                                )}
                            >
                                {flexRender(cell.column.columnDef.cell, cell.getContext())}
                            </td>
                        ))}
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

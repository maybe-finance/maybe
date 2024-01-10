import type { SharedType } from '@maybe-finance/shared'
import { NumberUtil } from '@maybe-finance/shared'
import { useMemo, useState } from 'react'
import classNames from 'classnames'
import { BrowserUtil } from '@maybe-finance/client/shared'
import { LoadingPlaceholder } from '@maybe-finance/design-system'
import { Prisma } from '@prisma/client'

interface SliderProps {
    isLoading: boolean
    rollup?: SharedType.AccountRollup[0]
}

const placeholderBalances: SharedType.AccountRollupTimeSeries = {
    interval: 'days',
    start: '',
    end: '',
    data: [
        {
            date: '',
            balance: new Prisma.Decimal(1),
            rollupPct: new Prisma.Decimal(1),
            totalPct: new Prisma.Decimal(1),
        },
    ],
}

export function NetWorthBreakdownSlider({ isLoading, rollup }: SliderProps) {
    const [hoveredItemIndex, setHoveredItemIndex] = useState<number | null>(null)

    const data: SharedType.AccountRollup[0] = useMemo(
        () =>
            isLoading || !rollup
                ? {
                      key: 'asset',
                      title: '',
                      balances: placeholderBalances,
                      items: [
                          {
                              key: 'cash',
                              title: '',
                              items: [],
                              balances: placeholderBalances,
                          },
                      ],
                  }
                : rollup,
        [isLoading, rollup]
    )

    return (
        <LoadingPlaceholder isLoading={isLoading} className="!block">
            <div className="flex flex-col gap-2">
                <div className="bg-gray-800 w-full p-2 rounded-lg flex-nowrap flex">
                    {data.items.map((item, index) => (
                        <div
                            key={`${item.title}-${index}`}
                            className={classNames(
                                'inline-block h-3 first:rounded-l last:rounded-r bg-current transition-opacity',
                                BrowserUtil.getCategoryColorClassName(item.key),
                                hoveredItemIndex != null &&
                                    hoveredItemIndex !== index &&
                                    'opacity-30'
                            )}
                            style={{
                                width: `${item.balances.data[
                                    item.balances.data.length - 1
                                ].rollupPct
                                    .times(100)
                                    .toNumber()}%`,
                            }}
                        />
                    ))}
                </div>
                <div className="flex flex-wrap">
                    {data.items.map((item, index) => (
                        <div
                            key={`${item.title}-${index}`}
                            className={classNames(
                                'flex items-center justify-between rounded-lg py-1 px-2 cursor-default transition',
                                hoveredItemIndex === index && 'bg-gray-800'
                            )}
                            onMouseEnter={() => setHoveredItemIndex(index)}
                            onMouseLeave={() => setHoveredItemIndex(null)}
                        >
                            <span
                                className={classNames(
                                    'w-[10px] h-[10px] rounded-full mr-2 bg-current',
                                    BrowserUtil.getCategoryColorClassName(item.key)
                                )}
                            ></span>
                            <span className="text-sm mr-2">{item.title}</span>
                            <span className="text-sm text-gray-100">
                                {NumberUtil.format(
                                    item.balances.data[item.balances.data.length - 1].rollupPct,
                                    'percent',
                                    {
                                        signDisplay: 'auto',
                                        maximumFractionDigits: 2,
                                    }
                                )}
                            </span>
                        </div>
                    ))}
                </div>
            </div>
        </LoadingPlaceholder>
    )
}

import type { PropsWithChildren, ReactNode } from 'react'
import type { ClientType } from '../..'
import { useLocalStorage } from '../..'

import { createContext, useMemo, useContext } from 'react'
import { Badge, Listbox, LoadingPlaceholder, Tooltip } from '@maybe-finance/design-system'
import { RiQuestionLine, RiSettings4Line } from 'react-icons/ri'
import { AnimatePresence, motion } from 'framer-motion'
import groupBy from 'lodash/groupBy'
import random from 'lodash/random'
import classNames from 'classnames'

export type InsightCardOption = {
    id: string
    display: string
    category: string
    tooltip: string
}

const InsightGroupContext = createContext<{ selectedInsights: InsightCardOption[] } | undefined>(
    undefined
)

export type InsightGroupProps = PropsWithChildren<{
    id: string
    options: InsightCardOption[]
    initialInsights: InsightCardOption['id'][]
}>

function InsightGroup({ id, options, initialInsights, children }: InsightGroupProps) {
    const [selectedInsights, setSelectedInsights] = useLocalStorage(
        `SELECTED_INSIGHTS_GROUP_${id}`,
        initialInsights
    )

    /**
     * Returns grouped arrays of insight cards
     *
     * ['key', [<InsightCard1 />, <InsightCard2 />]]
     */
    const insights = useMemo<[string, InsightCardOption[]][]>(() => {
        const groups: { [key: string]: InsightCardOption[] } = groupBy(options, 'category')
        return Object.entries(groups)
    }, [options])

    return (
        <InsightGroupContext.Provider
            value={{ selectedInsights: options.filter((o) => selectedInsights.includes(o.id)) }}
        >
            <div className="mb-8">
                <div className="flex items-center justify-between mb-4">
                    <h5 className="uppercase">highlights</h5>
                    <Listbox value={selectedInsights} onChange={setSelectedInsights} multiple>
                        <Listbox.Button icon={RiSettings4Line} hideRightIcon>
                            <span className="text-white text-base font-medium">Customize</span>
                        </Listbox.Button>
                        <Listbox.Options placement="bottom-end" className="min-w-[210px]">
                            {insights.map(([category, insights]) => (
                                <div key={category}>
                                    <span className="text-sm text-gray-100 font-medium inline-block">
                                        {category}
                                    </span>
                                    {insights.map((insight) => (
                                        <Listbox.Option
                                            key={insight.id}
                                            value={insight.id}
                                            className="my-2"
                                        >
                                            {insight.display}
                                        </Listbox.Option>
                                    ))}
                                </div>
                            ))}
                        </Listbox.Options>
                    </Listbox>
                </div>
                {selectedInsights.length ? (
                    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                        {children}
                    </div>
                ) : (
                    <p className="text-gray-100">Please select insights to show</p>
                )}
            </div>
        </InsightGroupContext.Provider>
    )
}

type InsightCardProps = PropsWithChildren<{
    id: string
    isLoading: boolean
    status?: ClientType.MetricStatus
    headerRight?: ReactNode
    placeholder?: ReactNode
    onClick?: () => void
}>

function Card({
    id,
    children,
    isLoading,
    status,
    headerRight,
    placeholder,
    onClick,
}: InsightCardProps) {
    const ctx = useContext(InsightGroupContext)

    if (!ctx) throw new Error('Must use Insight Card within group')

    const card = useMemo(() => ctx.selectedInsights.find((insight) => insight.id === id), [ctx, id])

    return (
        <AnimatePresence>
            {card && (
                <motion.div
                    layout
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className={classNames(
                        'flex flex-col h-[140px] gap-4 p-4 bg-gray-800 rounded-lg shadow-md',
                        onClick && status === 'active' && 'hover:bg-gray-700 cursor-pointer'
                    )}
                    onClick={status === 'active' ? onClick : undefined}
                >
                    <div className="h-8 flex items-center">
                        <p className="text-base text-gray-100">{card.display}</p>
                        <Tooltip
                            content={<div className="text-base text-gray-50">{card.tooltip}</div>}
                            className="max-w-[350px]"
                        >
                            <span>
                                <RiQuestionLine className="w-5 h-5 text-gray-50 mx-1.5" />
                            </span>
                        </Tooltip>
                        <div className="ml-auto whitespace-nowrap">
                            {status === 'under-construction' ? (
                                <Badge children="Unavailable" variant="gray" />
                            ) : status === 'coming-soon' ? (
                                <Badge children="Soon" variant="gray" />
                            ) : (
                                headerRight
                            )}
                        </div>
                    </div>
                    <div className="grow">
                        {!status || status === 'under-construction' ? (
                            <p className="text-gray-100 text-base">
                                We're currently fixing this to make sure we show you accurate
                                figures.
                            </p>
                        ) : status === 'active' && !isLoading ? (
                            children
                        ) : (
                            <LoadingPlaceholder isLoading={isLoading}>
                                <div className="relative h-full">
                                    <div className="absolute inset-0 bg-gray-800 bg-opacity-70 backdrop-blur-sm" />

                                    <div className="ml-0.5">
                                        {placeholder ? (
                                            placeholder
                                        ) : (
                                            <>
                                                <h3>{random(10, 100, true).toFixed(2)}</h3>
                                                <p>Placeholder subtext overlay</p>
                                            </>
                                        )}
                                    </div>
                                </div>
                            </LoadingPlaceholder>
                        )}
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
    )
}

export default Object.assign(InsightGroup, { Card })

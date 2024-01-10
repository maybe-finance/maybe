import type { ClientType } from '@maybe-finance/client/shared'
import type { PropsWithChildren, ReactNode } from 'react'
import { Badge, LoadingPlaceholder, Tooltip } from '@maybe-finance/design-system'
import { RiQuestionLine } from 'react-icons/ri'
import classNames from 'classnames'

type InsightCardProps = PropsWithChildren<{
    isLoading: boolean
    status?: ClientType.MetricStatus
    title: string
    metricValue: string
    metricDetail: ReactNode
    className?: string
    info?: ReactNode
    infoTooltipClassName?: string
    headerRight?: ReactNode
    onClick?: () => void
}>

export function NetWorthInsightCard({
    isLoading,
    status,
    title,
    metricValue,
    metricDetail,
    className,
    info,
    infoTooltipClassName,
    headerRight,
    onClick,
}: InsightCardProps) {
    return (
        <div
            className={classNames(
                'flex flex-col bg-gray-800 rounded-lg w-full p-4',
                onClick && 'hover:bg-gray-700 cursor-pointer',
                className
            )}
            onClick={onClick}
        >
            <div className="grow flex items-center justify-between space-x-1.5">
                <div className="flex items-center">
                    <p className="text-base text-gray-100">{title}</p>
                    {info && (
                        <Tooltip
                            content={<div className="text-base text-gray-50">{info}</div>}
                            className={classNames(infoTooltipClassName, 'max-w-[350px]')}
                        >
                            <span>
                                <RiQuestionLine className="w-5 h-5 text-gray-50 mx-1.5" />
                            </span>
                        </Tooltip>
                    )}
                </div>
                <div className="whitespace-nowrap">
                    {status === 'under-construction' && (
                        <Badge children="Unavailable" variant="gray" />
                    )}
                    {status === 'coming-soon' && <Badge children="Soon" variant="gray" />}
                    {status === 'active' && headerRight}
                </div>
            </div>

            <div className="mt-4">
                {!status || status === 'under-construction' ? (
                    <p className="text-gray-100 text-base">
                        We're currently fixing this to make sure we show you accurate figures.
                    </p>
                ) : (
                    <LoadingPlaceholder isLoading={isLoading}>
                        <h3 className="whitespace-nowrap">{metricValue}</h3>
                        <div className="mt-1 text-base text-gray-100">{metricDetail}</div>
                    </LoadingPlaceholder>
                )}
                {status === 'coming-soon' && (
                    <div className="absolute -inset-1 bg-gray-800 bg-opacity-70 backdrop-blur-sm" />
                )}
            </div>
        </div>
    )
}

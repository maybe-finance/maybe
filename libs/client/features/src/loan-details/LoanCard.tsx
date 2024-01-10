import type { PropsWithChildren, ReactNode } from 'react'

import { LoadingPlaceholder, Tooltip } from '@maybe-finance/design-system'
import { RiQuestionLine } from 'react-icons/ri'
import classNames from 'classnames'

export type LoanCardProps = PropsWithChildren<{
    isLoading: boolean
    title: string

    detail?: {
        metricValue: string
        metricDetail: ReactNode
    }
    className?: string
    info?: ReactNode
    headerRight?: ReactNode
}>

export function LoanCard({
    isLoading,
    title,
    detail,
    className,
    info,
    headerRight,
}: LoanCardProps) {
    return (
        <div className={classNames('bg-gray-800 rounded-lg w-full p-4', className)}>
            <div className="flex items-center justify-between space-x-1.5">
                <div className="flex items-center">
                    <p className="text-base text-gray-100">{title}</p>
                    {info && (
                        <Tooltip
                            content={<div className="text-base text-gray-50">{info}</div>}
                            className="max-w-[350px]"
                        >
                            <span>
                                <RiQuestionLine className="w-5 h-5 text-gray-50 mx-1.5" />
                            </span>
                        </Tooltip>
                    )}
                </div>
                <div className="whitespace-nowrap">{headerRight}</div>
            </div>

            <div className="mt-4">
                <LoadingPlaceholder isLoading={isLoading} className="">
                    {detail ? (
                        <>
                            <h3>{detail.metricValue}</h3>
                            <div className="mt-1 text-base text-gray-100">
                                {detail.metricDetail}
                            </div>
                        </>
                    ) : (
                        <p className="text-gray-100 text-base">
                            We need some data from your end to calculate this metric accurately
                        </p>
                    )}
                </LoadingPlaceholder>
            </div>
        </div>
    )
}

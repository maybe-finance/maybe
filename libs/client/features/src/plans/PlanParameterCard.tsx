import type { PropsWithChildren, ReactNode } from 'react'
import { LoadingPlaceholder, Tooltip } from '@maybe-finance/design-system'
import { RiQuestionLine } from 'react-icons/ri'
import classNames from 'classnames'

type PlanParameterCardProps = PropsWithChildren<{
    isLoading?: boolean
    title: string
    value: string
    detail: ReactNode
    className?: string
    info?: ReactNode
}>

export function PlanParameterCard({
    isLoading = false,
    title,
    value,
    detail,
    className,
    info,
}: PlanParameterCardProps) {
    return (
        <div className={classNames('flex flex-col bg-gray-800 rounded-lg w-full p-4', className)}>
            <div className="grow flex items-center justify-between space-x-1.5">
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
            </div>

            <div className="mt-4">
                <LoadingPlaceholder isLoading={isLoading} className="whitespace-nowrap">
                    <h3>{value}</h3>
                    <div className="mt-1 text-base text-gray-100">{detail}</div>
                </LoadingPlaceholder>
            </div>
        </div>
    )
}

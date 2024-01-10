import classNames from 'classnames'
import { Fragment } from 'react'
import type { InsightState } from '../insights'
import { InsightStateNames, InsightStateColorClasses } from '../insights'

export type NetWorthInsightStateAxisProps = {
    className?: string
    steps: (InsightState | string)[]
}

export function NetWorthInsightStateAxis({ className, steps }: NetWorthInsightStateAxisProps) {
    return (
        <div className={classNames('flex justify-center', className)}>
            <div
                className={classNames(
                    'inline-flex items-center gap-1.5 py-1 px-3 font-medium whitespace-nowrap',
                    'bg-gradient-to-r from-transparent via-gray-600 to-transparent'
                )}
            >
                {steps.map((step, index) => (
                    <Fragment key={index}>
                        {Object.keys(InsightStateNames).includes(step) ? (
                            <span className={InsightStateColorClasses[step as InsightState]}>
                                {InsightStateNames[step as InsightState]}
                            </span>
                        ) : (
                            <span className="text-gray-100">{step}</span>
                        )}
                        {index < steps.length - 1 && (
                            <>
                                <span className="w-0.5 h-0.5 rounded-full bg-gray-300">&nbsp;</span>
                                <span className="w-0.5 h-0.5 rounded-full bg-gray-300">&nbsp;</span>
                            </>
                        )}
                    </Fragment>
                ))}
            </div>
        </div>
    )
}

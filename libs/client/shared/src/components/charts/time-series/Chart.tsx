import type { ChartProps, Datum } from './types'
import type { FallbackProps } from 'react-error-boundary'

import { useMemo } from 'react'
import { ParentSize } from '@visx/responsive'
import { LoadingChart } from './LoadingChart'
import { ErrorBoundary } from 'react-error-boundary'
import { BaseChart } from './BaseChart'

import * as Sentry from '@sentry/react'

const defaultMargin = { top: 20, left: 75, bottom: 55, right: 10 }

export function Chart<TDatum extends Datum>({
    data,
    isLoading,
    isError,
    dateRange,
    margin: _margin,
    renderOverlay,
    ...rest
}: ChartProps<TDatum>) {
    const margin = useMemo(() => ({ ...defaultMargin, ..._margin }), [_margin])

    if (!dateRange?.start || !dateRange?.end) {
        if (!isLoading) {
            console.warn('No date range provided to chart')
        }

        return <LoadingChart margin={margin} />
    }

    if (isLoading || isError || renderOverlay != null) {
        return (
            <LoadingChart
                margin={margin}
                animate={!isError}
                isError={isError}
                renderOverlay={renderOverlay}
            />
        )
    }

    function ErrorFallback({ resetErrorBoundary: _ }: FallbackProps) {
        return <LoadingChart animate={false} margin={margin} isError />
    }

    return (
        // Prevent chart errors from crashing entire UI
        <ParentSize>
            {({ width, height }) => {
                return (
                    // Set to relative for error boundary overlay
                    <div className="relative w-full h-full">
                        <ErrorBoundary
                            FallbackComponent={ErrorFallback}
                            onError={(err) => {
                                Sentry.captureException(err)
                                console.error('Chart crashed', err)
                            }}
                        >
                            <BaseChart<TDatum>
                                data={data!} // if not loading or error, assume there is data
                                margin={margin}
                                width={width}
                                height={height}
                                isLoading={isLoading}
                                isError={isError}
                                dateRange={{ start: dateRange.start!, end: dateRange.end! }}
                                {...rest}
                            />
                        </ErrorBoundary>
                    </div>
                )
            }}
        </ParentSize>
    )
}

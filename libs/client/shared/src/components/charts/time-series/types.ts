import type { SharedType } from '@maybe-finance/shared'
import type { ScaleTypeToD3Scale } from '@visx/scale'
import type { ReactNode } from 'react'
import type { WithChildrenRenderProps } from '../../../types'
import type { O } from 'ts-toolbelt'

/**
 * Assumptions
 *
 * - Time series data uses Date in UTC timezone
 * - Accessor fns always return a number for y-axes
 */

export type Spacing = {
    top: number
    left: number
    bottom: number
    right: number
}

export type Datum = Record<string, any>

export type TSeriesDatum<TDatum extends Datum = any> = {
    date: string
    values: Partial<TDatum>
}

export type TSeriesDatumEnhanced<TDatum extends Datum = any> = TSeriesDatum<TDatum> & {
    dateJS: Date
}

export type AccessorFn<TDatum extends Datum, TValue = number> = (
    datum: TSeriesDatum<TDatum>
) => TValue | undefined

export type Series<TDatum extends Datum = any, TValue = number> = {
    key: string
    accessorFn: AccessorFn<TDatum, TValue>
    /* hex color value per datum or per series (defaults to cyan) */
    color?: string | AccessorFn<TDatum, string>
    format?: SharedType.FormatString
    isActive?: boolean
    dataKey?: string /* Required if data is provided in key:value format */
    label?: string /* A user-friendly label shown on default tooltips for this series */
    showVariance?: boolean /* Defaults to false, whether to show a percentage variance for this datum */
    negative?: boolean /* Whether to negate sentiment/colors for changes (up = red, down = green) */
}

export type SeriesEnhanced<TDatum extends Datum = any> = O.Required<
    Series<TDatum>,
    'isActive' | 'showVariance'
>

export type SeriesDatum = Omit<Series, 'color'> & { color: string } & {
    value?: number | SharedType.Decimal
    trend?: Pick<SharedType.Trend, 'direction'> & { amount: number; percentage: number }
}

export type TooltipOptions = {
    /**
     * If rendered in portal, will float outside chart bounds, otherwise stays within chart.
     * @see https://airbnb.io/visx/tooltip
     */
    renderInPortal?: boolean
    offsetX?: number
    offsetY?: number

    /* If specified, tooltip will snap to this series.  Otherwise, it snaps to closest point relative to the cursor. */
    referenceSeriesKey?: Series['key']

    /* Specify title for default tooltip component.  Defaults to date formatted as MMM dd, yyyy */
    tooltipTitle?: (data: TooltipData) => ReactNode
}

// For now, assume all charts will have time-based x-axis and linear y-axes that only deal with number values
export type ValidXScaleTypes = ScaleTypeToD3Scale<number>['utc']
export type ValidYScaleTypes = ScaleTypeToD3Scale<number>['linear']

export type ChartData<TDatum extends Datum> =
    | Record<string, TSeriesDatum<TDatum>[]>
    | TSeriesDatum<TDatum>[]

export type ChartDataEnhanced<TDatum extends Datum> =
    | Record<string, TSeriesDatumEnhanced<TDatum>[]>
    | TSeriesDatumEnhanced<TDatum>[]

export type RenderOverlay = () => ReactNode

type ChartPropsBase<TDatum extends Datum> = {
    id: string
    isLoading: boolean
    isError: boolean
    series: Series<TDatum>[]
    dateRange: Partial<SharedType.DateRange>
    data?: ChartData<TDatum>
    xAxis?: ReactNode
    y1Axis?: ReactNode
    xScale?: ValidXScaleTypes
    y1Scale?: ValidYScaleTypes
    interval?: SharedType.TimeSeriesInterval
    margin?: Partial<Spacing>
    padding?: Partial<Pick<Spacing, 'top' | 'bottom'>>
    tooltipOptions?: TooltipOptions
    renderTooltip?: (tooltipData: TooltipData<TDatum>) => ReactNode // Default tooltip rendered if not specified
    renderOverlay?: RenderOverlay
}

type TooltipSeriesData<TDatum extends Datum = any> =
    | Record<
          string,
          {
              originalSeries: SeriesEnhanced<TDatum>
              originalDatum: TSeriesDatumEnhanced<TDatum>
              value: number | null
          }
      >
    | undefined // If series are changed while user is hovering the chart, this will be undefined for a moment

export type TooltipData<TDatum extends Datum = any> = {
    date: string
    dateJS: Date
    series: TooltipSeriesData<TDatum> // original series and datum wrapped under a series key
    values: Array<number | null> // extracted values in arr format for convenience
}

export type ChartContext<TDatum extends Datum = any> = {
    /* A unique id for the chart which is used for internal SVG elements to avoid collisions */
    chartId: string
    xScale: ValidXScaleTypes
    y1Scale: ValidYScaleTypes
    margin: Spacing
    width: number
    height: number
    series: SeriesEnhanced[]
    data: ChartDataEnhanced<TDatum>
}

export type TooltipContext<TDatum extends Datum = any> = {
    tooltipOpen: boolean
    tooltipLeft?: number
    tooltipTop?: number
    tooltipData?: TooltipData<TDatum>
}

export type ChartDataContext<TDatum extends Datum = any> = ChartContext<TDatum> &
    TooltipContext<TDatum>

export type ChartProps<TDatum extends Datum> = WithChildrenRenderProps<
    ChartPropsBase<TDatum>,
    ChartDataContext<TDatum>
>

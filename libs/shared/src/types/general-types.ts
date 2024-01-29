import type { Prisma } from '@prisma/client'
import type { AxiosError } from 'axios'
import type { TellerTypes } from '@maybe-finance/teller-api'
import type { Contexts, Primitive } from '@sentry/types'
import type DecimalJS from 'decimal.js'
import type { O } from 'ts-toolbelt'

export type Decimal = DecimalJS | Prisma.Decimal

export type DateRange<TDate = string> = {
    start: TDate
    end: TDate
}

/**
 * ================================================================
 * ======                TimeSeries Data                     ======
 * ================================================================
 */
export type TimeSeriesInterval = 'days' | 'weeks' | 'months' | 'quarters' | 'years'

export type TimeSeries<
    TData extends { date: string },
    TInterval extends string = TimeSeriesInterval
> = {
    interval: TInterval
    start: string // yyyy-mm-dd
    end: string // yyyy-mm-dd
    data: TData[]
}

export type TimeSeriesResponseWithDetail<TSeries> = TSeries extends TimeSeries<
    infer TData,
    infer _TInterval // eslint-disable-line
>
    ? {
          series: TSeries
          today?: TData
          minDate: string
          trend: Trend
      }
    : never

/**
 * ================================================================
 * ======             Calculations / Metrics                 ======
 * ================================================================
 */

export type Trend = {
    direction: 'up' | 'down' | 'flat'
    amount: Decimal | null
    percentage: Decimal | null
}

export type FormatString = 'currency' | 'short-currency' | 'percent' | 'decimal' | 'short-decimal'

/**
 * ================================================================
 * ======             Error types                            ======
 * ================================================================
 */
export type ParsedError = {
    // Parser will attempt to produce a descriptive message from the error
    message: string

    // Any extra error data to include in logs
    metadata?: any

    // Not safe for production, but provided for local logs
    stackTrace?: any

    // This parser covers more than just HTTP errors, so this is optional
    statusCode?: string

    sentryContexts?: Contexts
    sentryTags?: { [key: string]: Primitive }
}

export type AxiosTellerError = O.Required<
    AxiosError<TellerTypes.TellerError>,
    'response' | 'config'
>

export type StatusPageResponse = {
    page?: {
        id?: string
        name?: string
        url?: string
        updated_at?: string
    }
    status?: {
        description?: string
        indicator?: 'none' | 'minor' | 'major' | 'critical'
    }
}

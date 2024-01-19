import type { SharedType } from '..'
import type { NiceTime } from '@visx/scale'
import type { TimeSeriesInterval } from '../types'
import { DateTime } from 'luxon'
import range from 'lodash/range'

export function generateDailySeries(start: string, end: string, zone = 'utc'): string[] {
    const s = DateTime.fromISO(start, { zone })
    const e = DateTime.fromISO(end, { zone })
    const daysBetween = Math.abs(s.diff(e, 'days').days)

    return range(0, daysBetween + 1, 1).map((idx) => s.plus({ days: idx }).toFormat('yyyy-MM-dd'))
}

export function isToday(date: Date | string | null | undefined, today = DateTime.utc()): boolean {
    if (!date) return false
    return isSameDate(datetimeTransform(date), today)
}

export function isSameDate(date: DateTime, as: DateTime): boolean {
    return date.toUTC().toISODate() === as.toUTC().toISODate()
}

export function datetimeTransform(val: Date | string): DateTime
export function datetimeTransform(val: Date | string | null): DateTime | null
export function datetimeTransform(val: Date | string | undefined): DateTime | undefined
export function datetimeTransform(
    val: Date | string | null | undefined
): DateTime | null | undefined {
    if (val === undefined) return undefined
    if (val === null) return null
    const dt =
        typeof val === 'string'
            ? DateTime.fromISO(val, { zone: 'utc' })
            : DateTime.fromJSDate(val, { zone: 'utc' })
    if (!dt.isValid) throw new Error(`invalid datetime: ${val}`)
    return dt
}

// Validates ISO string date and returns ISO string
export function dateTransform(val: Date | string): string
export function dateTransform(val: Date | string | null): string | null
export function dateTransform(val: Date | string | undefined): string | undefined
export function dateTransform(val: Date | string | null | undefined): string | null | undefined {
    if (val === undefined) return undefined
    if (val === null) return null
    const d =
        typeof val === 'string'
            ? DateTime.fromISO(val, { zone: 'utc' })
            : DateTime.fromJSDate(val, { zone: 'utc' })
    if (!d.isValid) throw new Error(`invalid ISO8601 date: ${val}`)
    return d.toISODate()
}

export function strToDate(val: string, zone = 'utc'): Date {
    return DateTime.fromISO(val, { zone }).toJSDate()
}

export function dateToStr(val: Date, zone = 'utc'): string {
    return DateTime.fromJSDate(val, { zone }).toISODate()
}

export function calculateTimeSeriesInterval(
    start: string | DateTime,
    end: string | DateTime,
    desiredChunks = 150
): SharedType.TimeSeriesInterval {
    const INTERVALS: [SharedType.TimeSeriesInterval, number][] = [
        ['days', 1],
        ['weeks', 7],
        ['months', 30],
        ['quarters', 91],
        ['years', 365],
    ]

    const startDate = typeof start === 'string' ? DateTime.fromISO(start) : start
    const endDate = typeof end === 'string' ? DateTime.fromISO(end) : end
    const diff = endDate.diff(startDate, 'days')

    // determine exact optimal interval and then find the closest actual interval
    const goal = Math.abs(diff.days) / desiredChunks
    const closestInterval = INTERVALS.reduce((best, curr) => {
        return Math.abs(curr[1] - goal) < Math.abs(best[1] - goal) ? curr : best
    })

    return closestInterval[0]
}

/**
 * Temporary mapping to avoid full refactor of all time-series values
 * @todo - update `TimeSeriesInterval` to have same types as `NiceTime`
 */
export function toD3Interval(interval: TimeSeriesInterval): NiceTime {
    switch (interval) {
        case 'days':
            return 'day'
        case 'weeks':
            return 'week'
        case 'months':
            return 'month'
        case 'quarters':
            return 'month' // no quarterly value available
        case 'years':
            return 'year'
        default:
            return 'day'
    }
}

/**
 * Converts a calendar year to an age based on the current age
 */
export function yearToAge(year: number, currentAge = 30, currentYear = DateTime.now().year) {
    return year - currentYear + currentAge
}

/**
 * Converts an age to a calendar year based on the current age
 */
export function ageToYear(age: number, currentAge = 30, currentYear = DateTime.now().year) {
    return age - currentAge + currentYear
}

/** Calculates an age from a DOB in ISO string format */
export function dobToAge(dob: string | Date | DateTime | null | undefined, now = DateTime.now()) {
    if (!dob) return null

    const normalizedDate =
        typeof dob === 'string'
            ? DateTime.fromISO(dob, { zone: 'utc' })
            : dob instanceof Date
            ? DateTime.fromJSDate(dob, { zone: 'utc' })
            : dob

    return Math.floor(now.diff(normalizedDate, 'years').years)
}

// We allow a maximum of 30 years of history for performance reasons (hypertable chunking)
export const MIN_SUPPORTED_DATE = DateTime.now().minus({ years: 30 })
export const MAX_SUPPORTED_DATE = DateTime.now()

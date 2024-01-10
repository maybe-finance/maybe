import type { Decimal, FormatString } from '../types'
import DecimalJS from 'decimal.js'

export function calculatePercentChange(_from: Decimal | null, _to: Decimal | null): Decimal
export function calculatePercentChange(_from: number | null, _to: number | null): number
export function calculatePercentChange(
    _from: Decimal | number | null,
    _to: Decimal | number | null
): Decimal | number {
    const isDecimal = DecimalJS.isDecimal(_from) || DecimalJS.isDecimal(_to)

    if (_from == null || _to == null) return isDecimal ? new DecimalJS(NaN) : NaN

    const from = new DecimalJS(_from.toString())
    const to = new DecimalJS(_to.toString())

    const diff = to.minus(from)

    const pctChange = diff.isZero() ? new DecimalJS(0) : diff.dividedBy(from.abs())

    return isDecimal ? pctChange : pctChange.toNumber()
}

export function format(
    value: Decimal | number | string | undefined | null,
    format: FormatString,
    options?: Intl.NumberFormatOptions
): string {
    if (value == null) return '--'
    const _value = +value

    // Catches anything that's not a valid number
    if (!Number.isFinite(_value)) {
        switch (_value) {
            case Infinity:
                return format === 'percent' ? `∞%` : `∞`
            case -Infinity:
                return format === 'percent' ? `-∞%` : `-∞`
            default:
                return '--'
        }
    }

    const defaultCurrencyOptions: Intl.NumberFormatOptions = {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2, // defaults to $X.XX
        maximumFractionDigits: 2,
    }

    const defaultDecimalOptions: Intl.NumberFormatOptions = {
        style: 'decimal',
        currency: 'USD',
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
    }

    if (format === 'currency') {
        return _value.toLocaleString('en-US', { ...defaultCurrencyOptions, ...options })
    }

    if (format === 'percent') {
        const defaultPercentageOptions: Intl.NumberFormatOptions = {
            style: 'percent',
            signDisplay: 'exceptZero',
            minimumFractionDigits: 0,
            maximumFractionDigits: 1,
        }

        return _value.toLocaleString('en-US', { ...defaultPercentageOptions, ...options })
    }

    if (format === 'decimal') {
        return _value.toLocaleString('en-US', { ...defaultDecimalOptions, ...options })
    }

    const shortUnits = [
        { value: 1e12, symbol: 't' },
        { value: 1e9, symbol: 'b' },
        { value: 1e6, symbol: 'm' },
        { value: 1e3, symbol: 'k' },
        { value: 1, symbol: '' },
    ]

    // This should always be the last case because regexp are expensive computations
    if (['short-currency', 'short-decimal'].includes(format)) {
        const defaultOptions =
            format === 'short-currency' ? defaultCurrencyOptions : defaultDecimalOptions

        const item = shortUnits.find(function (item) {
            return Math.abs(_value) >= item.value
        })

        if (!item) {
            return _value.toLocaleString('en-US', { ...defaultOptions, ...options })
        }

        const initialString = (_value / item.value).toLocaleString('en-US', {
            ...defaultOptions,
            ...options,
        })

        // For larger numbers like "$20.00k", strip the zeroes at the end ($20.00k => $20k)
        const rx = /\.0+$|(\.[0-9]*[1-9])0+$/
        const stripZeroString =
            Math.abs(_value) > 999 ? initialString.replace(rx, '$1') : initialString
        return stripZeroString + item.symbol
    }

    throw new Error('Invalid format type')
}

/**
 * Lodash `sumBy` equivalent that supports Decimal.js
 */
export function sumBy<T>(a: T[] | null | undefined, by: (item: T) => DecimalJS): DecimalJS {
    return a != null && a.length > 0 ? DecimalJS.sum(...a.map(by)) : new DecimalJS(0)
}

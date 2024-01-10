import range from 'lodash/range'
import { DateTime } from 'luxon'

type DisabledProps = {
    year: number
    minDate?: string
    maxDate?: string
}

// This custom disabled function because dayzed
// ignores the offset when calculating the disabled dates
// https://github.com/maybe-finance/maybe-app/pull/417#issuecomment-1208475083
export const disabled = ({ year, minDate, maxDate }: DisabledProps) => {
    if (minDate) {
        const minDateYear = DateTime.fromISO(minDate).year

        if (year < minDateYear) {
            return true
        }
    }

    if (maxDate) {
        const maxDateYear = DateTime.fromISO(maxDate).year

        if (year > maxDateYear) {
            return true
        }
    }

    return false
}

// Return a year grid of 12 years
// with the current year in the center position (index 4, position 2,2)
export const generateYearsRange = (year: number, currentYear = DateTime.now().year) => {
    const naturalIndex = currentYear % 12 // Which position the current year would be in the grid if the grid started with 0
    const desiredIndex = 4 // Which position we want the current year be in the grid
    const offset = (year + naturalIndex + desiredIndex) % 12

    return range(year - offset, year - offset + 12)
}

// We allow a maximum of 30 years of history for performance reasons (hypertable chunking)
export const MIN_SUPPORTED_DATE = DateTime.utc().minus({ years: 30 }).startOf('day')
export const MAX_SUPPORTED_DATE = DateTime.utc().startOf('day')

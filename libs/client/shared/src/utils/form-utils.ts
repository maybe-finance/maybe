import { DateTime } from 'luxon'
import { DateUtil } from '@maybe-finance/shared'
import defaults from 'lodash/defaults'

const { MIN_SUPPORTED_DATE, MAX_SUPPORTED_DATE, isToday } = DateUtil

type ValidateFormDateOpts = {
    required?: boolean
    minDate?: string
    maxDate?: string
}

export function validateFormDate(date: string | null, opts?: ValidateFormDateOpts) {
    const _opts = defaults({}, opts)

    if (!date) {
        const isRequired = _opts.required ?? true
        return isRequired ? 'Valid date required' : true
    }

    const _date = DateTime.fromISO(date)

    if (!_date.isValid) return 'Invalid date'

    const minDate = _opts.minDate ? DateTime.fromISO(_opts.minDate) : MIN_SUPPORTED_DATE
    const maxDate = _opts.maxDate ? DateTime.fromISO(_opts.maxDate) : MAX_SUPPORTED_DATE

    if (_date < minDate) {
        return `Date must be ${minDate.toFormat('MMM dd yyyy')} or later`
    }

    if (_date.endOf('day') > maxDate.endOf('day')) {
        return isToday(maxDate.toISODate(), DateTime.utc())
            ? 'Date cannot be in future'
            : `Date must be ${maxDate.toFormat('MMM yyyy')} or earlier`
    }

    return true
}

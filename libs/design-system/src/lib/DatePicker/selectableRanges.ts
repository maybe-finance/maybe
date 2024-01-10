import { DateTime } from 'luxon'

export type DateRange = {
    start: string
    end: string
}

export type SelectableRangeKeys =
    | 'day'
    | 'last-7-days'
    | 'this-month'
    | 'prior-month'
    | 'last-30-days'
    | 'last-90-days'
    | 'last-6-months'
    | 'this-year'
    | 'prior-year'
    | 'last-365-days'
    | 'last-3-years'
    | 'last-5-years'

export type SelectableDateRange = DateRange & {
    label: string
    labelShort: string
    alternateLabel?: string
}

export const getNormalizedRanges: (
    selections: Array<SelectableRangeKeys | SelectableDateRange> | 'all'
) => SelectableDateRange[] = (selections) => {
    const now = DateTime.now()
    const nowISO = now.toISODate()

    const ranges: { [key in SelectableRangeKeys]: SelectableDateRange } = {
        day: {
            label: 'Today',
            labelShort: '1D',
            alternateLabel: 'today',
            start: now.minus({ days: 1 }).toISODate(),
            end: nowISO,
        },
        'last-7-days': {
            label: 'Last 7 days',
            labelShort: '7D',
            alternateLabel: 'past week',
            start: now.minus({ days: 7 }).toISODate(),
            end: nowISO,
        },
        'this-month': {
            label: 'This month',
            labelShort: 'This month',
            alternateLabel: 'this month',
            start: now.startOf('month').toISODate(),
            end: nowISO,
        },
        'prior-month': {
            label: 'Last month',
            labelShort: 'Last month',
            alternateLabel: 'last month',
            start: now.minus({ months: 1 }).startOf('month').toISODate(),
            end: now.minus({ months: 1 }).endOf('month').toISODate(),
        },
        'last-30-days': {
            label: 'Last month',
            labelShort: '1M',
            alternateLabel: 'past month',
            start: now.minus({ days: 30 }).toISODate(),
            end: nowISO,
        },
        'last-90-days': {
            label: 'Last 3 months',
            labelShort: '3M',
            alternateLabel: 'past 3 months',
            start: now.minus({ days: 90 }).toISODate(),
            end: nowISO,
        },
        'last-6-months': {
            label: 'Last 6 months',
            labelShort: '6M',
            alternateLabel: 'past 6 months',
            start: now.minus({ months: 6 }).toISODate(),
            end: nowISO,
        },
        'prior-year': {
            label: 'Last year',
            labelShort: 'Last year',
            alternateLabel: 'last year',
            start: now.minus({ years: 1 }).startOf('year').toISODate(),
            end: now.minus({ years: 1 }).endOf('year').toISODate(),
        },
        'last-365-days': {
            label: 'Last 365 days',
            labelShort: '1Y',
            alternateLabel: 'past year',
            start: now.minus({ days: 365 }).toISODate(),
            end: nowISO,
        },
        'this-year': {
            label: 'This year',
            labelShort: 'YTD',
            alternateLabel: 'this year',
            start: now.startOf('year').toISODate(),
            end: nowISO,
        },
        'last-3-years': {
            label: 'Last 3 years',
            labelShort: '3Y',
            alternateLabel: 'past 3 years',
            start: now.minus({ years: 3 }).toISODate(),
            end: nowISO,
        },
        'last-5-years': {
            label: 'Last 5 years',
            labelShort: '5Y',
            alternateLabel: 'past 5 years',
            start: now.minus({ years: 5 }).toISODate(),
            end: nowISO,
        },
    }

    if (typeof selections === 'string' && selections === 'all') {
        return Object.values(ranges)
    }

    return selections.map((selection) => {
        if (typeof selection === 'string') {
            return ranges[selection]
        } else {
            return selection
        }
    })
}

export const getRangeDescription = (range?: DateRange, minDate?: string) => {
    if (!range) return 'in this period'

    const fromStartRange = {
        start: minDate,
        end: DateTime.now().toISODate(),
        alternateLabel: 'from the start',
    }

    const knownRanges = [...getNormalizedRanges('all'), fromStartRange]

    const knownRange = knownRanges.find(
        ({ start, end }) => range.start === start && range.end === end
    )

    if (knownRange) {
        return knownRange.alternateLabel || 'in this period'
    }

    return 'in this period'
}

import { DateTime } from 'luxon'
import { ageToYear, calculateTimeSeriesInterval, dobToAge, yearToAge } from './date-utils'

describe('calculateTimeSeriesInterval', () => {
    it.each`
        duration         | chunks | interval
        ${{ weeks: 1 }}  | ${150} | ${'days'}
        ${{ weeks: 1 }}  | ${250} | ${'days'}
        ${{ months: 1 }} | ${150} | ${'days'}
        ${{ months: 1 }} | ${250} | ${'days'}
        ${{ months: 3 }} | ${150} | ${'days'}
        ${{ months: 3 }} | ${250} | ${'days'}
        ${{ months: 6 }} | ${150} | ${'days'}
        ${{ months: 6 }} | ${250} | ${'days'}
        ${{ years: 1 }}  | ${150} | ${'days'}
        ${{ years: 1 }}  | ${250} | ${'days'}
        ${{ years: 2 }}  | ${150} | ${'weeks'}
        ${{ years: 2 }}  | ${250} | ${'days'}
        ${{ years: 3 }}  | ${150} | ${'weeks'}
        ${{ years: 3 }}  | ${250} | ${'weeks'}
        ${{ years: 5 }}  | ${150} | ${'weeks'}
        ${{ years: 5 }}  | ${250} | ${'weeks'}
        ${{ years: 10 }} | ${150} | ${'months'}
        ${{ years: 10 }} | ${250} | ${'weeks'}
        ${{ years: 20 }} | ${150} | ${'months'}
        ${{ years: 20 }} | ${250} | ${'months'}
    `(
        `should calculate properly for duration: $duration chunks: $chunks`,
        ({ duration, chunks, interval }) => {
            const d = DateTime.now()
            expect(calculateTimeSeriesInterval(d, d.plus(duration), chunks)).toBe(interval)
        }
    )
})

describe('converts between years and ages', () => {
    it.each`
        dateOfBirth                       | currentAge
        ${'1995-02-20'}                   | ${27}
        ${new Date('Feb 20 1995')}        | ${27}
        ${DateTime.fromISO('1995-02-20')} | ${27}
        ${null}                           | ${null}
        ${undefined}                      | ${null}
        ${'2022-10-15'}                   | ${0}
        ${'2021-10-12'}                   | ${1}
        ${'2021-10-18'}                   | ${0}
    `(`dob $dateOfBirth is $currentAge years old today`, ({ dateOfBirth, currentAge }) => {
        const now = DateTime.fromISO('2022-10-15')

        expect(dobToAge(dateOfBirth, now)).toBe(currentAge)
    })

    it.each`
        age   | year
        ${30} | ${2027}
        ${20} | ${2017}
    `(`at age $currentAge the year will be $year`, ({ age, year }) => {
        const currentAge = 25

        expect(ageToYear(age, currentAge, 2022)).toBe(year)
    })

    it.each`
        year    | age
        ${2027} | ${30}
        ${2017} | ${20}
    `(`at year $year the age will be $age`, ({ age, year }) => {
        const currentAge = 25

        expect(yearToAge(year, currentAge, 2022)).toBe(age)
    })
})

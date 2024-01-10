import { generateYearsRange, disabled } from './utils'

describe('disabled', () => {
    it('should return true if year is less than minDate', () => {
        const year = 2021
        const minDate = '2022-01-01'
        const result = disabled({ year, minDate })
        expect(result).toBe(true)
    })

    it('should return false if year is more or equal than minDate', () => {
        const year = 2022
        const minDate = '2022-01-01'
        const result = disabled({ year, minDate })
        expect(result).toBe(false)
    })

    it('should return false if year is less or equal than maxDate', () => {
        const year = 2022
        const maxDate = '2022-01-01'
        const result = disabled({ year, maxDate })
        expect(result).toBe(false)
    })

    it('should return true if year is more than maxDate', () => {
        const year = 2023
        const maxDate = '2022-01-01'
        const result = disabled({ year, maxDate })
        expect(result).toBe(true)
    })
})

describe('generateYearsRange', () => {
    const currentYear = 2022

    it('should return a range of years from a previous year', () => {
        const years = generateYearsRange(2006, currentYear)
        expect(years).toEqual([
            2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
        ])
    })

    it('should return a range of years from current year', () => {
        const years = generateYearsRange(2018, currentYear)
        expect(years).toEqual([
            2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029,
        ])
    })

    it('should return a range of years from next year', () => {
        const years = generateYearsRange(2030, currentYear)
        expect(years).toEqual([
            2030, 2031, 2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041,
        ])
    })
})

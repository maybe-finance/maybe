import user from '@testing-library/user-event'
import { fireEvent, getQueriesForElement, render, screen, waitFor } from '@testing-library/react'
import { DatePickerRange } from './DatePickerRange'
import { DateTime } from 'luxon'

// Set date to Oct 29, 2021 to keep snapshots consistent
beforeAll(() => jest.useFakeTimers().setSystemTime(new Date('2021-10-29 12:00:00')))

// DatePicker configuration
const minDate = DateTime.now().minus({ years: 2 })
const maxDate = DateTime.now()

describe('<DatePickerRange />', () => {
    describe('When datepicker is closed', () => {
        it('should have placeholder when empty', () => {
            const onChangeMock = jest.fn()

            const component = render(
                <DatePickerRange
                    selectableRanges={['this-month', 'prior-month']}
                    minDate={minDate.toISODate()}
                    maxDate={maxDate.toISODate()}
                    value={undefined}
                    onChange={onChangeMock}
                />
            )

            expect(screen.queryByText('Select a date range')).toBeInTheDocument()
            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })

        it('should have date when valid', () => {
            const onChangeMock = jest.fn()

            const component = render(
                <DatePickerRange
                    selectableRanges={['this-month', 'prior-month']}
                    minDate={'2021-01-01'}
                    maxDate={'2022-01-01'}
                    value={{ start: '2021-01-01', end: '2022-01-01' }}
                    onChange={onChangeMock}
                />
            )

            expect(screen.queryByText('Jan 01, 2021')).toBeInTheDocument()
            expect(screen.queryByText('to')).toBeInTheDocument()
            expect(screen.queryByText('Jan 01, 2022')).toBeInTheDocument()
            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('When datepicker is expanded', () => {
        it('should be able to select a date from the dropdown while clicking', async () => {
            const onChangeMock = jest.fn()

            const start = DateTime.fromISO('2021-12-01')
            const end = DateTime.fromISO('2022-01-31')

            render(
                <DatePickerRange
                    selectableRanges={['day', 'last-30-days']}
                    minDate={start.toISODate()}
                    maxDate={end.toISODate()}
                    value={{ start: start.toISODate(), end: end.toISODate() }}
                    onChange={onChangeMock}
                />
            )

            // Open the modal
            fireEvent.click(screen.getByTestId('datepicker-range-toggle-icon'))

            await waitFor(() =>
                expect(screen.getByTestId('datepicker-range-panel')).toBeInTheDocument()
            )

            expect(screen.queryByText('Cancel')).toBeInTheDocument()
            expect(screen.queryByText('Apply')).toBeInTheDocument()

            expect(screen.queryByText(end.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(end.year)).toBeInTheDocument()

            // Go back a month
            fireEvent.click(screen.getByTestId('datepicker-range-back-arrow'))
            expect(screen.queryByText(start.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(start.year)).toBeInTheDocument()

            // Select start date
            fireEvent.click(
                await getQueriesForElement(screen.getByTestId('day-cells')).findByText('1')
            )

            // Go forward a month
            fireEvent.click(screen.getByTestId('datepicker-range-next-arrow'))
            expect(screen.queryByText(end.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(end.year)).toBeInTheDocument()

            // Select end date
            fireEvent.click(
                await getQueriesForElement(screen.getByTestId('day-cells')).findByText('31')
            )

            // Submit
            fireEvent.click(screen.getByText('Apply'))

            expect(onChangeMock).toHaveBeenCalledWith({
                start: start.toISODate(),
                end: end.toISODate(),
            })

            await waitFor(() =>
                expect(screen.queryByTestId('datepicker-range-panel')).not.toBeInTheDocument()
            )

            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
        })
        it('should be able to select a date from the dropdown using inputs', async () => {
            const onChangeMock = jest.fn()

            const start = DateTime.fromISO('2022-01-01')
            const end = DateTime.fromISO('2022-01-20')

            render(
                <DatePickerRange
                    selectableRanges={['day', 'last-30-days']}
                    minDate={start.toISODate()}
                    maxDate={end.toISODate()}
                    value={{ start: start.toISODate(), end: end.toISODate() }}
                    onChange={onChangeMock}
                />
            )

            // Open the modal
            fireEvent.click(screen.getByTestId('datepicker-range-toggle-icon'))

            await waitFor(() =>
                expect(screen.getByTestId('datepicker-range-panel')).toBeInTheDocument()
            )

            expect(screen.queryByText('Cancel')).toBeInTheDocument()
            expect(screen.queryByText('Apply')).toBeInTheDocument()

            const dateInputs = screen.getAllByRole('textbox')

            user.type(dateInputs[0], start.toFormat('MMddyyyy'))
            user.type(dateInputs[1], end.toFormat('MMddyyyy'))

            expect(screen.queryByText(end.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(end.year)).toBeInTheDocument()

            // Submit
            fireEvent.click(screen.getByText('Apply'))

            expect(onChangeMock).toHaveBeenCalledWith({
                start: start.toISODate(),
                end: end.toISODate(),
            })

            await waitFor(() =>
                expect(screen.queryByTestId('datepicker-range-panel')).not.toBeInTheDocument()
            )

            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
        })

        it('should be able to select a date using the quick select sidebar', async () => {
            const onChangeMock = jest.fn()

            render(
                <DatePickerRange
                    selectableRanges={['prior-month', 'this-month']}
                    onChange={onChangeMock}
                />
            )

            // Open the modal
            fireEvent.click(screen.getByTestId('datepicker-range-toggle-icon'))

            await waitFor(() =>
                expect(screen.getByTestId('datepicker-range-panel')).toBeInTheDocument()
            )

            expect(screen.queryByText('Cancel')).toBeInTheDocument()
            expect(screen.queryByText('Apply')).toBeInTheDocument()

            fireEvent.click(screen.getByText('Last month'))

            const lastMonth = DateTime.now().minus({ months: 1 })

            expect(screen.queryByText(lastMonth.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(lastMonth.year)).toBeInTheDocument()

            // Submit
            fireEvent.click(screen.getByText('Apply'))

            expect(onChangeMock).toHaveBeenCalledWith({
                start: lastMonth.startOf('month').toISODate(),
                end: lastMonth.endOf('month').toISODate(),
            })

            await waitFor(() =>
                expect(screen.queryByTestId('datepicker-range-panel')).not.toBeInTheDocument()
            )

            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
        })
    })
})

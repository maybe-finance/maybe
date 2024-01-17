import user from '@testing-library/user-event'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { DatePicker } from './'
import { DateTime } from 'luxon'

// DatePicker configuration
const minDate = DateTime.now().minus({ years: 2 })
const maxDate = DateTime.now()

describe('<DatePicker />', () => {
    describe('When datepicker is closed', () => {
        it('should have placeholder when empty', () => {
            const onChangeMock = jest.fn()

            const component = render(
                <DatePicker
                    name="picker"
                    minCalendarDate={minDate.toISODate()}
                    maxCalendarDate={maxDate.toISODate()}
                    value={null}
                    onChange={onChangeMock}
                />
            )

            expect(screen.getByPlaceholderText('MM / DD / YYYY')).toBeInTheDocument()
            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })

        it('should have date when valid', () => {
            const onChangeMock = jest.fn()

            const component = render(
                <DatePicker
                    name="picker"
                    minCalendarDate={minDate.toISODate()}
                    maxCalendarDate={maxDate.toISODate()}
                    value={null}
                    onChange={onChangeMock}
                />
            )

            const input = component.getByPlaceholderText('MM / DD / YYYY') as HTMLInputElement

            user.type(input, '02012021')
            expect(onChangeMock).toHaveBeenCalledWith('2021-02-01')
            expect(screen.queryByText('Date must be')).not.toBeInTheDocument()

            expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
            expect(screen.queryByText('Apply')).not.toBeInTheDocument()
        })
    })

    describe('When datepicker is expanded', () => {
        it('should be able to open modal and select a date', async () => {
            const onChangeMock = jest.fn()

            render(
                <div id="container">
                    <DatePicker
                        name="picker"
                        minCalendarDate={minDate.toISODate()}
                        maxCalendarDate={maxDate.toISODate()}
                        value={null}
                        onChange={onChangeMock}
                    />
                </div>
            )

            const currentMonth = DateTime.now()
            const priorMonth = DateTime.now().minus({ months: 1 })

            console.log(DateTime.now(), 'date')

            // Open the modal
            fireEvent.click(screen.getByTestId('datepicker-toggle-icon'))

            await waitFor(() => expect(screen.getByTestId('datepicker-panel')).toBeInTheDocument())

            // Go back a month
            fireEvent.click(screen.getByTestId('datepicker-range-back-arrow'))
            expect(screen.queryByText(priorMonth.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(priorMonth.year)).toBeInTheDocument()

            // Go forward a month
            fireEvent.click(screen.getByTestId('datepicker-range-next-arrow'))
            expect(screen.queryByText(currentMonth.monthShort)).toBeInTheDocument()
            expect(screen.queryByText(currentMonth.year)).toBeInTheDocument()

            // Select a date
            fireEvent.click(screen.getByText('17'))
            fireEvent.click(screen.getByText('Apply'))
            expect(onChangeMock).toHaveBeenCalledWith(
                DateTime.fromObject(
                    {
                        day: 17,
                        month: currentMonth.month,
                        year: currentMonth.year,
                    },
                    { zone: 'utc' }
                ).toISODate()
            )
        })
    })
})

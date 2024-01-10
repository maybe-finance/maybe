import { render } from '@testing-library/react'
import TrendLine from './TrendLine'

describe('TrendLine', () => {
    describe('when rendered with a positive trendline', () => {
        it('should render correcly', () => {
            const component = render(
                <TrendLine
                    data={[
                        { key: 1, value: 1 },
                        { key: 2, value: 2 },
                        { key: 3, value: 3 },
                    ]}
                />
            )

            expect(component).toMatchSnapshot()
        })
    })

    describe('when rendered with a negative trendline', () => {
        it('should render correcly', () => {
            const component = render(
                <TrendLine
                    data={[
                        { key: 3, value: 3 },
                        { key: 2, value: 2 },
                        { key: 1, value: 1 },
                    ]}
                />
            )

            expect(component).toMatchSnapshot()
        })
    })

    describe('when rendered with a neutral trendline', () => {
        it('should render correcly', () => {
            const component = render(
                <TrendLine
                    data={[
                        { key: 1, value: 1 },
                        { key: 2, value: 2 },
                        { key: 3, value: 1 },
                    ]}
                />
            )

            expect(component).toMatchSnapshot()
        })
    })
})

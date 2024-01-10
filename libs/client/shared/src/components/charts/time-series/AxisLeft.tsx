import type { SharedAxisProps } from '@visx/axis'
import type { ValidYScaleTypes } from './types'

import { NumberUtil } from '@maybe-finance/shared'
import { AxisLeft as VisxAxisLeft } from '@visx/axis'
import { useChartData } from './BaseChart'

export function AxisLeft(props: Omit<SharedAxisProps<ValidYScaleTypes>, 'scale'>) {
    const { y1Scale, margin } = useChartData()

    return (
        <VisxAxisLeft
            scale={y1Scale}
            left={margin.left - 15}
            hideTicks
            hideAxisLine
            numTicks={5}
            axisClassName="text-gray-100"
            tickFormat={(datum) => NumberUtil.format(datum.valueOf(), 'short-currency')}
            tickLabelProps={() => {
                return {
                    fill: 'currentColor',
                    textAnchor: 'end',
                    verticalAnchor: 'middle',
                    fontSize: 12,
                }
            }}
            {...props}
        />
    )
}

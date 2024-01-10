import type { AccessorFn } from './types'

import { LinearGradient } from '@visx/gradient'
import { Fragment } from 'react'
import { useChartData } from './BaseChart'

type Props = {
    id: string
    dataKey: string
    accessorFn: AccessorFn<any, string>
}

export function MultiColorGradient({ id, dataKey, accessorFn }: Props) {
    const { data, width, xScale } = useChartData()

    const dataArr = Array.isArray(data) ? data : data[dataKey]

    return (
        <LinearGradient id={id} gradientUnits="userSpaceOnUse" x1={0} x2={width}>
            {dataArr.map((datum, idx, arr) => {
                if (idx > 0) {
                    const currColor = accessorFn(datum)
                    const prevColor = accessorFn(arr[idx - 1])
                    const prevDate = arr[idx - 1].dateJS
                    const offset = xScale(prevDate) / width

                    if (!Number.isFinite(offset)) return null

                    /**
                     * In order to make "hard color stops", there needs to be 2 stops
                     * for each color (start, end).
                     *
                     * Ex: Red line from 0-20%, blue line from 20-100%
                     * <stop offset="0%" stopColor="red" />
                     * <stop offset="20%" stopColor="red" />
                     * <stop offset="20%" stopColor="blue" />
                     * <stop offset="100%" stopColor="blue" />
                     */

                    return (
                        <Fragment key={idx}>
                            <stop offset={offset} stopColor={prevColor} />
                            <stop offset={offset} stopColor={currColor} />
                        </Fragment>
                    )
                } else return null
            })}
        </LinearGradient>
    )
}

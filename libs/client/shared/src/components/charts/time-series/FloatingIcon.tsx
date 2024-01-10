import type { IconType } from 'react-icons'
import type { SVGProps } from 'react'
import { Circle } from '@visx/shape'
import { Fragment } from 'react'

interface Props extends SVGProps<SVGCircleElement> {
    icon: IconType
    iconColor: string
    left: number
    top: number

    /* The index of this icon in relation to other icons with the same y coordinate */
    stackIdx: number
    verticalOffset?: number
}

/** Icon that floats above a chart element */
// eslint-disable-next-line no-empty-pattern
export function FloatingIcon({ left, top, stackIdx, icon: Icon, iconColor, ...rest }: Props) {
    return (
        <Fragment>
            <Circle cx={left} cy={top - stackIdx * 35} r={16} {...rest} />
            <Icon size={16} x={left - 8} y={top - 8 - stackIdx * 35} fill={iconColor} />
        </Fragment>
    )
}

import type { SVGProps } from 'react'

import { Glyph } from '@visx/glyph'
import { Circle, Line } from '@visx/shape'
import { Group } from '@visx/group'

interface Props extends SVGProps<SVGGElement> {
    left: number
    top: number
}

export function PlusCircleGlyph({ left, top, ...rest }: Props) {
    return (
        // Wrap in group to allow click handler
        <Group {...rest}>
            <Glyph left={left} top={top}>
                <Circle r={12} stroke="transparent" />
                <Line x1={-5} x2={5} y1={0} y2={0} strokeWidth={2} />
                <Line x1={0} x2={0} y1={-5} y2={5} strokeWidth={2} />
            </Glyph>
        </Group>
    )
}

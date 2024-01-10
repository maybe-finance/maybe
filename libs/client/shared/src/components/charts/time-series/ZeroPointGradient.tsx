import { LinearGradient } from '@visx/gradient'
import { useChartData } from './BaseChart'

type Props = {
    id: string
    opacity: number
}

// Vertical gradient that converges towards the "zero point"
export function ZeroPointGradient({ id, opacity }: Props) {
    const { y1Scale, height } = useChartData()

    return (
        <LinearGradient id={id} gradientUnits="userSpaceOnUse" y1={0} y2={height} x1={0} x2={0}>
            <stop stopColor="currentColor" offset={0} stopOpacity={opacity}></stop>
            <stop stopColor="currentColor" offset={y1Scale(0) / height} stopOpacity={0}></stop>
            <stop stopColor="currentColor" offset={1} stopOpacity={opacity}></stop>
        </LinearGradient>
    )
}

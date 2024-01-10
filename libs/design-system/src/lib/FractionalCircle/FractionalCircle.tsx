import classNames from 'classnames'

type CircleProps = {
    radius: number
    stroke: number
    className?: string
    fill?: boolean
    percent?: number
}

function Circle({ radius, stroke, className, percent = 100 }: CircleProps) {
    // validate
    const _percent = percent < 0 ? 0 : percent > 100 ? 100 : percent
    const circumference = Math.PI * 2 * radius
    const strokePercent = ((100 - _percent) * circumference) / 100

    return (
        <circle
            r={radius}
            cx={radius + stroke / 2}
            cy={radius + stroke / 2}
            strokeWidth={stroke}
            className={classNames('fill-transparent stroke-current', className)}
            strokeDasharray={circumference}
            strokeDashoffset={strokePercent}
            transform={`rotate(-90, ${radius + stroke / 2}, ${radius + stroke / 2})`}
            strokeLinecap="round"
        />
    )
}

export type FractionalCircleProps = {
    percent: number
    variant?: 'default' | 'yellow' | 'green' | 'red'
    radius?: number
    stroke?: number
}

const CircleVariant = Object.freeze({
    default: {
        ring: 'text-white',
        background: 'text-gray-300',
    },
    yellow: {
        ring: 'text-yellow',
        background: 'text-gray-300',
    },
    green: {
        ring: 'text-teal',
        background: 'text-teal-300',
    },
    red: {
        ring: 'text-red',
        background: 'text-red-300',
    },
})

export default function FractionalCircle({
    percent,
    variant = 'default',
    radius = 7,
    stroke = 2,
}: FractionalCircleProps) {
    return (
        <svg width={radius * 2 + stroke} height={radius * 2 + stroke}>
            <Circle radius={radius} stroke={stroke} className={CircleVariant[variant].background} />
            <Circle
                radius={radius}
                stroke={stroke}
                percent={percent}
                className={CircleVariant[variant].ring}
            />
        </svg>
    )
}

import { ParentSize } from '@visx/responsive'
import { scaleLinear, scaleQuantile } from '@visx/scale'

const riskScale = scaleQuantile({
    domain: [1, 2, 3, 4],
    range: ['Low', 'Moderate', 'High'],
})

// Shows a readonly slider with a tooltip (score is 1-4 sliding scale from least to most aggressive)
export default function RiskSlider({ score }: { score: number }) {
    const margin = {
        left: 40,
        right: 40,
        top: 5,
        bottom: 5,
    }

    return (
        <div className="relative w-full h-full">
            <ParentSize debounceTime={100}>
                {({ width, height }) => {
                    const xScaleIndicator = scaleLinear({
                        domain: [1, 4],
                        range: [margin.left, width - margin.right],
                    })

                    return (
                        <svg width={width} height={height} className="">
                            <defs>
                                <linearGradient id="scoreGradient">
                                    <stop offset="0%" stopColor="rgba(52, 54, 60, 0)" />
                                    <stop
                                        offset={`${xScaleIndicator(score) / 4}%`}
                                        stopColor="rgba(59, 201, 219, 0.1)"
                                    />
                                    <stop offset="98%" stopColor="rgba(52, 54, 60, 0)" />
                                </linearGradient>
                            </defs>

                            <g>
                                <rect
                                    className="fill-cyan"
                                    x={xScaleIndicator(score) - 35}
                                    y="0"
                                    rx="8"
                                    width={72}
                                    height={24}
                                ></rect>
                                <text
                                    className="text-sm font-medium"
                                    x={xScaleIndicator(score)}
                                    y="16"
                                    textAnchor="middle"
                                >
                                    {riskScale(score)}
                                </text>
                            </g>

                            {['10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%'].map(
                                (v) => (
                                    <circle
                                        key={v}
                                        r={4}
                                        className="fill-gray-500"
                                        cx={v}
                                        cy={41}
                                    />
                                )
                            )}

                            <rect
                                fill="url(#scoreGradient)"
                                height={12}
                                width="100%"
                                y={35}
                                rx="6"
                            ></rect>

                            <circle
                                r={4}
                                className="fill-cyan"
                                cx={xScaleIndicator(score)}
                                cy={41}
                            />

                            <text
                                className="text-gray-100 fill-current text-sm"
                                textAnchor="start"
                                x={0}
                                y={height - margin.bottom}
                            >
                                Cautious
                            </text>
                            <text
                                className="text-gray-100 fill-current text-sm"
                                textAnchor="end"
                                x={width}
                                y={height - margin.bottom}
                            >
                                Aggressive
                            </text>
                        </svg>
                    )
                }}
            </ParentSize>
        </div>
    )
}

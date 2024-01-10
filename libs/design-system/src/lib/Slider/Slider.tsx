import type { RangerOptions } from 'react-ranger'
import { useRanger } from 'react-ranger'
import classNames from 'classnames'
import { useState } from 'react'
import isEqual from 'lodash/isEqual'

const SliderHandleClassNames = Object.freeze({
    small: 'w-2 h-2 rounded-lg',
    default: 'w-3 h-3 rounded-lg',
    large: 'w-4 h-4 rounded-lg',
})

const SliderTrackClassNames = Object.freeze({
    small: 'h-1 rounded-lg',
    default: 'h-1.5 rounded-lg',
    large: 'h-2 rounded-lg',
})

const SliderVariantColor = Object.freeze({
    default: 'bg-cyan',
})

export type SliderProps = {
    variant?: 'default'
    size?: 'small' | 'default' | 'large'
    className?: string
    initialValue: number[]
    updateOnDrag?: boolean
    onChange: (values: number[]) => void
    rangerOptions?: Partial<Omit<RangerOptions, 'values' | 'onChange'>>
}

export default function Slider({
    variant = 'default',
    size = 'default',
    initialValue = [0],
    updateOnDrag = false,
    onChange,
    className,
    rangerOptions,
}: SliderProps) {
    const [internalValues, setInternalValues] = useState(initialValue)
    const [isDragging, setIsDragging] = useState(false)

    const { getTrackProps, segments, handles } = useRanger({
        values: internalValues,
        onChange: (values: number[]) => {
            onChange(values)
            setIsDragging(false)
        },
        min: rangerOptions?.min ?? 0,
        max: rangerOptions?.max ?? 100,
        stepSize: rangerOptions?.stepSize ?? 1,
        onDrag: (values: number[]) => {
            setInternalValues(values)

            // Possible react-ranger bug: seems to fire even after release, so use this workaround
            if (!isEqual(values, internalValues)) {
                setIsDragging(true)
            }

            if (updateOnDrag) {
                onChange(values)
            }
        },
    })

    return (
        <div className={className}>
            <div
                {...getTrackProps({
                    className: classNames(
                        SliderVariantColor[variant],
                        'bg-opacity-10',
                        SliderTrackClassNames[size]
                    ),
                })}
                data-testid="slider-track"
            >
                <div
                    {...segments[0].getSegmentProps({
                        className: classNames('h-full rounded-lg bg-cyan'),
                    })}
                />

                {handles.map(({ getHandleProps }) => {
                    const handleProps = getHandleProps({
                        className: classNames(
                            SliderVariantColor[variant],
                            SliderHandleClassNames[size],
                            isDragging ? 'cursor-grabbing' : 'cursor-grab'
                        ),
                    })

                    return <div {...handleProps} data-testid={`handle-${handleProps.key}`} />
                })}
            </div>
        </div>
    )
}

import { Slider, Tooltip } from '@maybe-finance/design-system'
import classNames from 'classnames'
import { RiQuestionLine } from 'react-icons/ri'

type SliderBlock = {
    title: string
    info: string
    value: number
    onChange: (value: number) => void
    className?: string
    maxValue?: number
    minValue?: number
    formatFn?: (value: number, minValue?: number, maxValue?: number) => string
}

export default function SliderBlock({
    title,
    info,
    value,
    minValue,
    maxValue,
    className,
    onChange,
    formatFn,
}: SliderBlock) {
    return (
        <div className={classNames('bg-gray-600 rounded-lg mt-4 p-3 w-full', className)}>
            <div className="flex items-center text-base text-gray-100 mb-4">
                <span>{title}</span>
                <Tooltip content={info}>
                    <span className="ml-1.5">
                        <RiQuestionLine className="w-4 h-4" />
                    </span>
                </Tooltip>

                {/* Did not implement first pass */}
                {/* <span className="ml-auto">
                    <RiPencilLine className="w-4 h-4 text-gray-50" />
                </span> */}
            </div>
            <h4>{formatFn ? formatFn(value, minValue, maxValue) : value}</h4>
            <Slider
                className="mt-2"
                initialValue={[value]}
                updateOnDrag={true}
                onChange={(v: number[]) => onChange(v[0])}
                rangerOptions={{
                    max: maxValue,
                    min: minValue,
                }}
            />
        </div>
    )
}

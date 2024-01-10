import { useState } from 'react'
import { NumericFormat } from 'react-number-format'
import { RiArrowRightLine as RightArrow } from 'react-icons/ri'
import { Input, Popover, Tab } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import { usePlanContext } from '.'

export type PlanRangeSelectorProps = {
    fromYear: number
    toYear: number
    onChange: (range: { from: number; to: number }) => void
    mode: 'age' | 'year'
    onModeChange(mode: 'age' | 'year'): void
}

export function PlanRangeSelector({
    fromYear,
    toYear,
    onChange,
    mode,
    onModeChange,
}: PlanRangeSelectorProps): JSX.Element {
    const { userAge: currentAge, planStartYear, planEndYear } = usePlanContext()

    const [from, setFrom] = useState(fromYear)
    const [to, setTo] = useState(toYear)

    const formattedFrom =
        fromYear === planStartYear
            ? 'Today'
            : mode === 'age'
            ? `Age ${DateUtil.yearToAge(fromYear, currentAge)}`
            : fromYear

    const formattedTo = mode === 'age' ? `Age ${DateUtil.yearToAge(toYear, currentAge)}` : toYear

    return (
        <Popover>
            <Popover.Button variant="secondary">
                <div className="flex items-center">
                    {formattedFrom}
                    <span className="mx-2 text-gray-100">
                        <RightArrow className="w-4 h-4 text-gray-100" />
                    </span>{' '}
                    {formattedTo}
                </div>
            </Popover.Button>
            <Popover.Panel>
                <div className="w-80 p-2">
                    <Tab.Group
                        onChange={(index) => {
                            onModeChange(index === 0 ? 'age' : 'year')
                        }}
                    >
                        <Tab.List className="mb-4 bg-gray-600 !flex">
                            <Tab>Age</Tab>
                            <Tab>Year</Tab>
                        </Tab.List>
                        <Tab.Panels>
                            {/* Age */}
                            <Tab.Panel>
                                <div className="flex items-center">
                                    <NumericFormat
                                        customInput={Input}
                                        inputClassName="w-full text-center"
                                        allowNegative={false}
                                        decimalScale={0}
                                        value={DateUtil.yearToAge(from, currentAge)}
                                        onValueChange={(value) => {
                                            if (value?.floatValue)
                                                setFrom(
                                                    DateUtil.ageToYear(value.floatValue, currentAge)
                                                )
                                        }}
                                    />
                                    <RightArrow className="shrink-0 w-5 h-5 mx-5 text-gray-50" />
                                    <NumericFormat
                                        customInput={Input}
                                        inputClassName="w-full text-center"
                                        allowNegative={false}
                                        decimalScale={0}
                                        value={to - (planStartYear - currentAge)}
                                        onValueChange={(value) => {
                                            if (value?.floatValue)
                                                setTo(
                                                    DateUtil.ageToYear(value.floatValue, currentAge)
                                                )
                                        }}
                                    />
                                </div>
                            </Tab.Panel>

                            {/* Absolute years */}
                            <Tab.Panel>
                                <div className="flex items-center">
                                    <NumericFormat
                                        customInput={Input}
                                        inputClassName="w-full text-center"
                                        allowNegative={false}
                                        decimalScale={0}
                                        value={from}
                                        onValueChange={(value) => {
                                            if (value?.floatValue) setFrom(value.floatValue)
                                        }}
                                    />
                                    <RightArrow className="shrink-0 w-5 h-5 mx-5 text-gray-50" />
                                    <NumericFormat
                                        customInput={Input}
                                        inputClassName="w-full text-center"
                                        allowNegative={false}
                                        decimalScale={0}
                                        value={to}
                                        onValueChange={(value) => {
                                            if (value?.floatValue) setTo(value.floatValue)
                                        }}
                                    />
                                </div>
                            </Tab.Panel>
                        </Tab.Panels>
                    </Tab.Group>

                    <div className="flex justify-end space-x-3 mt-4">
                        <Popover.PanelButton
                            variant="secondary"
                            onClick={() => {
                                setFrom(fromYear)
                                setTo(toYear)
                            }}
                        >
                            Cancel
                        </Popover.PanelButton>
                        <Popover.PanelButton
                            variant="primary"
                            disabled={from < planStartYear || to > planEndYear || from >= to}
                            onClick={() => onChange({ from, to })}
                        >
                            Apply
                        </Popover.PanelButton>
                    </div>
                </div>
            </Popover.Panel>
        </Popover>
    )
}

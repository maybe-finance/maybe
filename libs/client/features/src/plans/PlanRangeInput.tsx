import React, { useState } from 'react'
import type { MouseEventHandler, ReactNode } from 'react'
import { NumericFormat } from 'react-number-format'
import classNames from 'classnames'
import { DateTime } from 'luxon'
import AnimateHeight from 'react-animate-height'
import type { IconType } from 'react-icons'
import {
    RiCalendar2Line,
    RiCheckFill,
    RiHeartPulseLine,
    RiKeyboardBoxLine,
    RiPlayCircleLine,
} from 'react-icons/ri'
import { GiPalmTree } from 'react-icons/gi'
import { Input, Popover } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { DateUtil } from '@maybe-finance/shared'
import { usePlanContext } from '.'

type ValueType = { year: number | null; milestoneId: SharedType.PlanMilestone['id'] | null }

export type PlanRangeInputProps = {
    type: 'start' | 'end'
    value: ValueType
    onChange: (value: ValueType) => void
    className?: string
    error?: string
}

type OptionType = 'retirement' | 'start' | 'end' | 'now' | 'age' | 'year'

const OptionMeta: Record<OptionType, { label: string; icon: IconType; manual?: boolean }> = {
    retirement: { label: 'Retirement', icon: GiPalmTree },
    start: { label: 'Start of plan', icon: RiPlayCircleLine },
    end: { label: 'End of plan', icon: RiHeartPulseLine },
    now: { label: 'Now', icon: RiCalendar2Line },
    age: { label: 'Enter age', icon: RiKeyboardBoxLine, manual: true },
    year: { label: 'Enter year', icon: RiKeyboardBoxLine, manual: true },
}

export function PlanRangeInput({
    type,
    value: { year, milestoneId },
    onChange,
    className,
    error,
}: PlanRangeInputProps) {
    const { userAge: currentAge, milestones } = usePlanContext()

    const [selected, setSelected] = useState<OptionType>(
        milestoneId != null ? 'retirement' : year ? (currentAge ? 'age' : 'year') : type
    )

    const onOptionClick = (type: OptionType, close: () => void) => {
        switch (type) {
            case 'retirement':
                onChange({ year: null, milestoneId: milestones[0].id })
                close()
                break
            case 'now':
                onChange({ year: DateTime.now().year, milestoneId: null })
                close()
                break
            case 'start':
            case 'end':
                onChange({ year: null, milestoneId: null })
                close()
                break
            case 'age':
            case 'year':
                if (type === selected) close()
                else
                    onChange({
                        year: year ?? DateTime.now().year,
                        milestoneId: null,
                    })
                break
        }

        setSelected(type)
    }

    const { icon: SelectionIcon } = OptionMeta[selected]

    const selectionLabel =
        milestoneId != null
            ? 'Retirement'
            : year
            ? ['year', 'currentYear'].includes(selected)
                ? year
                : `Age ${DateUtil.yearToAge(year, currentAge)}`
            : type === 'start'
            ? 'Start of plan'
            : 'End of plan'

    return (
        <Popover className={className}>
            <label>
                <span className="block mb-1 text-base text-gray-50 font-light leading-6">
                    {type === 'start' ? 'Start' : 'End'}
                </span>
                <Popover.Button variant="secondary" className="w-full font-normal !px-2.5">
                    <div className="flex items-center space-x-2.5">
                        <SelectionIcon className="w-5 h-5 text-gray-100" />
                        <div className="text-left">{selectionLabel}</div>
                    </div>
                </Popover.Button>
                {error && (
                    <span className="block ml-1 mt-1 text-sm leading-4 text-red">{error}</span>
                )}
            </label>
            <Popover.Panel className="!p-0 flex flex-col w-48">
                {({ open, close }: { open: boolean; close: () => void }) => (
                    <>
                        <SectionLabel>Quick select</SectionLabel>
                        <Option
                            type={type}
                            selected={selected === type}
                            open={open}
                            onClick={() => onOptionClick(type, close)}
                        />
                        <Option
                            type="now"
                            selected={selected === 'now'}
                            open={open}
                            onClick={() => onOptionClick('now', close)}
                        />
                        {milestones.length > 0 && (
                            <>
                                {/* TODO: Handle multiple milestones, not just retirement */}
                                <SectionLabel>Milestones</SectionLabel>
                                <Option
                                    type="retirement"
                                    selected={selected === 'retirement'}
                                    open={open}
                                    onClick={() => onOptionClick('retirement', close)}
                                />
                            </>
                        )}

                        <SectionLabel>Manual</SectionLabel>
                        <Option
                            type="age"
                            selected={selected === 'age'}
                            open={open}
                            onClick={() => onOptionClick('age', close)}
                            value={DateUtil.yearToAge(year ?? DateTime.now().year, currentAge)}
                            onChange={(age) =>
                                age &&
                                onChange({
                                    year: DateUtil.ageToYear(age, currentAge),
                                    milestoneId: null,
                                })
                            }
                            onSubmit={close}
                        />
                        <Option
                            type="year"
                            selected={selected === 'year'}
                            open={open}
                            onClick={() => onOptionClick('year', close)}
                            value={year ?? DateTime.now().year}
                            onChange={(year) => {
                                year &&
                                    onChange({
                                        year,
                                        milestoneId: null,
                                    })
                            }}
                            onSubmit={close}
                        />
                    </>
                )}
            </Popover.Panel>
        </Popover>
    )
}

function SectionLabel({ children }: { children: ReactNode }) {
    return <span className="p-2 text-sm text-gray-100">{children}</span>
}

function Option({
    type,
    selected,
    open,
    onClick,
    value,
    onChange,
    onSubmit,
}: {
    type: OptionType
    selected: boolean
    open: boolean
    onClick: MouseEventHandler<HTMLDivElement>
    value?: number
    onChange?: (value: number | null) => void
    onSubmit?: () => void
}) {
    const { label, icon: Icon, manual } = OptionMeta[type]

    return (
        <div
            role="button"
            onClick={onClick}
            className={classNames('py-1.5 px-2 hover:bg-gray-500', selected && 'bg-gray-500')}
        >
            <span className="flex items-center">
                <Icon className="shrink-0 w-5 h-5 mr-2 text-gray-100" />
                <span className="grow shrink-0 text-left text-base text-gray-25">{label}</span>
                {selected && <RiCheckFill className="shrink-0 w-5 h-5 ml-8 text-white" />}
            </span>

            {manual && (
                <AnimateHeight height={selected ? 'auto' : 0} duration={100}>
                    <div className="mt-2">
                        <NumericFormat
                            customInput={Input}
                            className="grow"
                            allowNegative={false}
                            value={value}
                            onValueChange={(value) => {
                                selected &&
                                    open &&
                                    onChange &&
                                    onChange(value.value ? parseFloat(value.value) : null)
                            }}
                            onKeyDown={(e: React.KeyboardEvent) => {
                                if (e.key === 'Enter') {
                                    onSubmit && onSubmit()
                                    e.preventDefault()
                                }
                            }}
                            onClick={(e: React.MouseEvent) => e.stopPropagation()}
                        />
                    </div>
                </AnimateHeight>
            )}
        </div>
    )
}

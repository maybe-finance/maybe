import type { Modifier } from 'react-popper'
import { useEffect, useMemo, useState } from 'react'
import { Listbox } from '@headlessui/react'
import cn from 'classnames'
import { RiArrowDownSLine } from 'react-icons/ri'
import { usePopper } from 'react-popper'

export type EditableDropdownCellProps = {
    initialValue: string
    options: string[]
    onSubmit: (value: string) => void
    formatFn?: (option: string) => string
}

export function EditableDropdownCell({
    initialValue,
    options,
    onSubmit,
    formatFn,
}: EditableDropdownCellProps) {
    const [value, setValue] = useState(initialValue)

    const popperSameWidth = useMemo<Modifier<'sameWidth'>>(
        () => ({
            name: 'sameWidth',
            enabled: true,
            phase: 'beforeWrite',
            requires: ['computeStyles'],
            fn: ({ state }) => {
                state.styles.popper.width = `${state.rects.reference.width}px`
            },
            effect: ({ state }) => {
                state.elements.popper.style.width = `${
                    (state.elements.reference as HTMLElement).offsetWidth
                }px`
            },
        }),
        []
    )

    useEffect(() => {
        setValue(initialValue)
    }, [initialValue])

    const [referenceElement, setReferenceElement] = useState<HTMLDivElement | null>()
    const [popperElement, setPopperElement] = useState<HTMLUListElement | null>()
    const { styles, attributes } = usePopper(referenceElement, popperElement, {
        placement: 'bottom-start',
        modifiers: [popperSameWidth],
    })

    return (
        <div ref={setReferenceElement} className="text-white-300">
            <Listbox
                value={value}
                onChange={(value) => {
                    setValue(value)
                    onSubmit(value)
                }}
            >
                <Listbox.Button
                    placeholder="Select"
                    className="w-full p-2 text-base flex items-center justify-between"
                >
                    {formatFn ? formatFn(value) : value}
                    <RiArrowDownSLine className="w-4 h-4" />
                </Listbox.Button>

                <Listbox.Options
                    ref={setPopperElement}
                    className="w-full bg-gray-700 border border-gray-500 shadow-xl shadow-black z-10 translate-y-10"
                    style={styles.popper}
                    {...attributes.popper}
                >
                    {options.map((option) => (
                        <Listbox.Option key={option} value={option} className="w-full text-base">
                            {({ selected }) => (
                                <button
                                    type="button"
                                    className={cn(
                                        'text-left py-1 px-3 w-full inline-block',
                                        selected
                                            ? 'bg-gray-500 text-white'
                                            : 'hover:bg-gray-600 text-gray-25'
                                    )}
                                >
                                    {formatFn ? formatFn(option) : option}
                                </button>
                            )}
                        </Listbox.Option>
                    ))}
                </Listbox.Options>
            </Listbox>
        </div>
    )
}

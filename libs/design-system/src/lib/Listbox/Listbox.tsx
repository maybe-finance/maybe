import type { Dispatch, MouseEventHandler, PropsWithChildren, SetStateAction } from 'react'
import type { IconType } from 'react-icons'
import type { PopperProps } from 'react-popper'
import React, { createContext, useContext, useState, useEffect, useRef } from 'react'
import { Listbox as HeadlessListbox } from '@headlessui/react'
import classNames from 'classnames'
import { RiArrowDownSFill, RiCheckFill } from 'react-icons/ri'
import { usePopper } from 'react-popper'
import { Checkbox } from '../Checkbox'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

const ListboxButtonVariants = Object.freeze({
    default:
        'text-white bg-gray-500 border-gray-500 focus:border-cyan focus:ring-opacity-10 focus:ring-cyan',
    teal: 'text-teal bg-teal bg-opacity-10 border-transparent focus:border-teal focus:ring-opacity-10 focus:ring-teal',
    red: 'text-red bg-red bg-opacity-10 border-transparent focus:border-red focus:ring-opacity-10 focus:ring-red',
    yellow: 'text-yellow bg-yellow bg-opacity-10 border-transparent focus:border-yellow focus:ring-opacity-10 focus:ring-yellow',
})

export type ListboxButtonVariant = keyof typeof ListboxButtonVariants

export interface ListboxButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: ListboxButtonVariant

    /** Label that appears above the button */
    label?: string

    /** Icon that appears on the left side of the button */
    icon?: IconType

    /** Shows or hides down arrow dropdown icon */
    hideRightIcon?: boolean

    /** Placeholder that appears when there is no child value */
    placeholder?: string

    className?: string

    labelClassName?: string

    buttonClassName?: string

    size?: 'small' | 'default'

    onClick?: MouseEventHandler
}

const ListboxContext = createContext<{
    referenceElement: HTMLButtonElement | null
    setReferenceElement?: Dispatch<SetStateAction<HTMLButtonElement | null>>
    multiple: boolean
}>({ referenceElement: null, multiple: false })

function Listbox({
    className,
    onClick,
    multiple = false,
    ...rest
}: { onClick?: MouseEventHandler } & ExtractProps<typeof HeadlessListbox>) {
    const [referenceElement, setReferenceElement] = useState<HTMLButtonElement | null>(null)

    return (
        <ListboxContext.Provider value={{ referenceElement, setReferenceElement, multiple }}>
            <HeadlessListbox
                as="div"
                className={classNames(className, 'relative')}
                onClick={onClick}
                multiple={multiple}
                {...rest}
            />
        </ListboxContext.Provider>
    )
}

function Button({
    className,
    variant = 'default',
    label,
    icon: Icon,
    hideRightIcon = false,
    placeholder,
    labelClassName,
    buttonClassName,
    size = 'default',
    children,
    onClick,
    ...rest
}: ListboxButtonProps & ExtractProps<typeof HeadlessListbox.Button>) {
    const { setReferenceElement } = useContext(ListboxContext)

    return (
        <HeadlessListbox.Button
            as="label"
            className={classNames(className, 'relative flex w-full flex-col')}
            onClick={onClick}
        >
            {({ disabled }) => (
                <>
                    {label && (
                        <span
                            className={classNames(
                                labelClassName,
                                'block mb-1 text-base text-gray-50 font-light leading-6'
                            )}
                        >
                            {label}
                        </span>
                    )}

                    <button
                        type="button"
                        className={classNames(
                            buttonClassName,
                            ListboxButtonVariants[variant],
                            size === 'default' ? 'py-2 px-4 h-10' : 'py-1 px-2 h-8',
                            'flex items-center grow rounded border overflow-hidden',
                            'text-base text-left font-light leading-none',
                            'focus:ring',
                            'placeholder-gray-200 disabled:placeholder-gray-200',
                            disabled && 'text-gray-100'
                        )}
                        disabled={disabled}
                        ref={setReferenceElement}
                        {...rest}
                    >
                        {Icon && (
                            <Icon
                                className={classNames(
                                    'mr-2 text-2xl',
                                    variant === 'default' && 'text-gray-50'
                                )}
                            />
                        )}

                        <span className="grow">
                            {children ?? <span className="text-gray-200">{placeholder}</span>}
                        </span>

                        {!hideRightIcon && (
                            <RiArrowDownSFill
                                className={classNames(
                                    'ml-2 text-lg',
                                    variant === 'default' && 'text-gray-50'
                                )}
                            />
                        )}
                    </button>
                </>
            )}
        </HeadlessListbox.Button>
    )
}

type ListboxOptionsProps = ExtractProps<typeof HeadlessListbox.Options>

function Options({
    className,
    placement = 'bottom-start',
    children,
    ...rest
}: (Omit<ListboxOptionsProps, 'static'> | Omit<ListboxOptionsProps, 'unmount'>) & {
    placement?: PopperProps<any>['placement']
}) {
    const { referenceElement, multiple } = useContext(ListboxContext)
    const [popperElement, setPopperElement] = useState<HTMLDivElement | null>(null)
    const [isOpen, setIsOpen] = useState(false)

    const isOpenRef = useRef(false)

    const { styles, attributes, update } = usePopper(referenceElement, popperElement, {
        placement,
        modifiers: [
            {
                name: 'offset',
                options: {
                    offset: [0, 8],
                },
            },
        ],
    })

    useEffect(() => {
        if (isOpen && update) update()
        if (isOpenRef.current !== isOpen) setIsOpen(isOpenRef.current)
    }, [isOpen, update])

    return (
        <div
            ref={setPopperElement}
            className={classNames(
                'z-20 absolute min-w-full shadow-md rounded bg-gray-700',
                className
            )}
            style={styles.popper}
            {...attributes.popper}
        >
            <HeadlessListbox.Options
                className={classNames(multiple ? 'py-3 px-2' : 'py-2', className)}
                unmount={false}
                {...rest}
            >
                {({ open }) => {
                    isOpenRef.current = open
                    return children
                }}
            </HeadlessListbox.Options>
        </div>
    )
}

type Position = 'left' | 'right'

type ListboxOptionProps = {
    icon?: IconType
    iconPosition?: Position
    checkIconPosition?: Position
}

function Option({
    className,
    children,
    icon: Icon,
    iconPosition = 'left',
    checkIconPosition = 'right',
    ...rest
}: PropsWithChildren<ListboxOptionProps & ExtractProps<typeof HeadlessListbox.Option>>) {
    const { multiple } = useContext(ListboxContext)

    const renderIcon = (selected: boolean, position: Position) => {
        const iconClassName = selected ? 'text-white' : 'text-gray-100 group-hover:text-gray-50'

        if (selected && checkIconPosition === position) {
            return (
                <span className={iconClassName}>
                    <RiCheckFill className="w-5 h-5" />
                </span>
            )
        }

        if (Icon && iconPosition === position) {
            return (
                <span className={iconClassName}>
                    <Icon className="w-5 h-5" />
                </span>
            )
        }

        return null
    }

    return (
        <HeadlessListbox.Option {...rest}>
            {({ selected, disabled }) =>
                multiple ? (
                    <div className={classNames('flex items-center', className)}>
                        <Checkbox
                            className="pointer-events-none"
                            checked={selected}
                            label={children}
                        />
                    </div>
                ) : (
                    <button
                        type="button"
                        className={classNames(
                            className,
                            'group flex justify-between items-center px-2.5 gap-x-2 w-full text-base leading-8 whitespace-nowrap',
                            selected ? 'bg-gray-500 text-white' : 'text-gray-25 hover:bg-gray-600',
                            disabled && 'opacity-50'
                        )}
                    >
                        <div className="flex gap-x-2 items-center">
                            {renderIcon(selected, 'left')}

                            <span>{children}</span>
                        </div>

                        {renderIcon(selected, 'right')}
                    </button>
                )
            }
        </HeadlessListbox.Option>
    )
}

export default Object.assign(Listbox, { Button, Options, Option })

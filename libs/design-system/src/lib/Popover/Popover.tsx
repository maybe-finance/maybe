import React, { createContext, useContext, useEffect, useRef, useState } from 'react'
import type { ComponentProps, RefObject } from 'react'
import type { PopperProps } from 'react-popper'
import { Popover as HeadlessPopover } from '@headlessui/react'
import { usePopper } from 'react-popper'
import classNames from 'classnames'
import { Button as BaseButton, RenderValidChildren } from '../../'
import { RiArrowDownSFill } from 'react-icons/ri'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

const PopoverContext = createContext<{
    referenceElement?: RefObject<HTMLButtonElement>
}>({})

function Popover({ className, ...rest }: ExtractProps<typeof HeadlessPopover>) {
    const referenceElement = useRef<HTMLButtonElement>(null)

    return (
        <PopoverContext.Provider value={{ referenceElement }}>
            <HeadlessPopover
                as="div"
                className={classNames(className, 'relative inline-block')}
                {...rest}
            />
        </PopoverContext.Provider>
    )
}

function Button({
    variant,
    hideRightIcon = false,
    children,
    ...rest
}: { hideRightIcon?: boolean } & ExtractProps<typeof HeadlessPopover.Button> &
    ComponentProps<typeof BaseButton>) {
    const { referenceElement } = useContext(PopoverContext)

    return (
        <HeadlessPopover.Button as={BaseButton} ref={referenceElement} {...rest}>
            <span className="grow">{children}</span>
            {!hideRightIcon && (
                <RiArrowDownSFill
                    className={classNames(
                        'shrink-0 ml-2 text-lg',
                        variant === 'secondary' && 'text-gray-50'
                    )}
                />
            )}
        </HeadlessPopover.Button>
    )
}

function PanelButton(
    props: ExtractProps<typeof HeadlessPopover.Button> & ComponentProps<typeof BaseButton>
) {
    return <HeadlessPopover.Button as={BaseButton} {...props} />
}

type PopoverPanelProps = ExtractProps<typeof HeadlessPopover.Panel>

function Panel({
    children,
    className,
    placement = 'bottom-start',
    ...rest
}: (Omit<PopoverPanelProps, 'static'> | Omit<PopoverPanelProps, 'unmount'>) & {
    placement?: PopperProps<any>['placement']
}) {
    const { referenceElement } = useContext(PopoverContext)
    const [popperElement, setPopperElement] = useState<HTMLDivElement | null>(null)
    const [isOpen, setIsOpen] = useState(false)

    const { styles, attributes, update } = usePopper(referenceElement?.current, popperElement, {
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
    }, [isOpen, update])

    return (
        <div
            ref={(el) => setPopperElement(el)}
            className={classNames('z-20 absolute min-w-full', className)}
            style={styles.popper}
            {...attributes.popper}
        >
            <HeadlessPopover.Panel
                className={classNames(
                    'p-2 shadow-md rounded bg-gray-700 border border-gray-500 text-white',
                    className
                )}
                unmount={undefined}
                {...rest}
            >
                {(renderProps) => {
                    setIsOpen(renderProps.open)
                    return (
                        <RenderValidChildren renderProps={renderProps}>
                            {children}
                        </RenderValidChildren>
                    )
                }}
            </HeadlessPopover.Panel>
        </div>
    )
}

export default Object.assign(Popover, { Button, Panel, PanelButton })

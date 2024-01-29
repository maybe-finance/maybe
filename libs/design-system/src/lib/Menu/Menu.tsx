import React, { createContext, forwardRef, useContext, useEffect, useRef, useState } from 'react'
import type { ComponentProps, PropsWithChildren, Ref, RefObject } from 'react'
import { Menu as HeadlessMenu } from '@headlessui/react'
import type { PopperProps } from 'react-popper'
import { usePopper } from 'react-popper'
import classNames from 'classnames'
import Link from 'next/link'
import { Button as BaseButton, RenderValidChildren } from '../../'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

const PopoverContext = createContext<{
    referenceElement?: RefObject<HTMLButtonElement>
}>({})

function Menu({ className, ...rest }: ExtractProps<typeof HeadlessMenu>) {
    const referenceElement = useRef<HTMLButtonElement>(null)

    return (
        <PopoverContext.Provider value={{ referenceElement }}>
            <HeadlessMenu as="div" className={classNames(className, 'relative')} {...rest} />
        </PopoverContext.Provider>
    )
}

function Button({
    ...rest
}: ExtractProps<typeof HeadlessMenu.Button> & ComponentProps<typeof BaseButton>) {
    const { referenceElement } = useContext(PopoverContext)

    return <HeadlessMenu.Button as={BaseButton} ref={referenceElement} {...rest} />
}

type ItemsProps = ExtractProps<typeof HeadlessMenu.Items>

function Items({
    className,
    placement = 'bottom-start',
    children,
    ...rest
}: { placement?: PopperProps<any>['placement'] } & (
    | Omit<ItemsProps, 'static'>
    | Omit<ItemsProps, 'unmount'>
)) {
    const { referenceElement } = useContext(PopoverContext)
    const [popperElement, setPopperElement] = useState<HTMLDivElement | null>(null)
    const [isOpen, setIsOpen] = useState(false)

    const isOpenRef = useRef(false)

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
        if (isOpenRef.current !== isOpen) setIsOpen(isOpenRef.current)
    }, [isOpen, update])

    return (
        <div
            ref={(el) => setPopperElement(el)}
            className={classNames('z-10 absolute min-w-full', className)}
            style={styles.popper}
            {...attributes.popper}
        >
            <HeadlessMenu.Items
                className={classNames(className, 'py-2 rounded bg-gray-700 shadow-md')}
                unmount={undefined}
                {...rest}
            >
                {(renderProps) => {
                    isOpenRef.current = renderProps.open
                    return (
                        <RenderValidChildren renderProps={renderProps}>
                            {children}
                        </RenderValidChildren>
                    )
                }}
            </HeadlessMenu.Items>
        </div>
    )
}

type ItemProps<T extends React.ElementType | React.ComponentType> = PropsWithChildren<{
    as?: T
    icon?: React.ReactNode
    destructive?: boolean
    disabled?: boolean
}> &
    React.ComponentPropsWithoutRef<T>

function Item<T extends React.ElementType | React.ComponentType = 'button'>({
    as,
    className,
    children,
    icon,
    destructive = false,
    disabled = false,
    ...rest
}: ItemProps<T>) {
    const InnerComponent = as || 'button'

    return (
        <HeadlessMenu.Item disabled={disabled}>
            {({ active, disabled }) => (
                <InnerComponent
                    className={classNames(
                        className,
                        'flex items-center pl-3 pr-5 w-full text-base leading-8 whitespace-nowrap',
                        destructive ? 'text-red' : 'text-gray-25',
                        active && 'bg-gray-600',
                        disabled ? 'opacity-50' : 'hover:bg-gray-600'
                    )}
                    {...rest}
                >
                    {icon && (
                        <span
                            className={classNames(
                                'text-2xl mr-2.5',
                                destructive ? 'text-red' : 'text-gray-50',
                                disabled && 'opacity-50'
                            )}
                        >
                            {icon}
                        </span>
                    )}
                    {children}
                </InnerComponent>
            )}
        </HeadlessMenu.Item>
    )
}

const NextLink = forwardRef(
    (
        {
            href,
            children,
            ...rest
        }: { href: string } & PropsWithChildren<React.ComponentPropsWithoutRef<'a'>>,
        ref: Ref<HTMLAnchorElement>
    ) => {
        return (
            <Link href={href} ref={ref} {...rest}>
                {children}
            </Link>
        )
    }
)

function ItemNextLink(props: Omit<ItemProps<typeof NextLink>, 'as'>) {
    return <Item as={NextLink} {...props}></Item>
}

export default Object.assign(Menu, { Button, Items, Item, ItemNextLink })

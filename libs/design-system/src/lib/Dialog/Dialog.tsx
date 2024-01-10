import type { PropsWithChildren } from 'react'
import React, { Children, Fragment } from 'react'
import { Dialog as HeadlessDialog, Transition } from '@headlessui/react'
import { RiCloseFill as IconClose } from 'react-icons/ri'
import classNames from 'classnames'

const DialogSizeClassName = Object.freeze({
    xs: 'sm:max-w-xs',
    sm: 'sm:max-w-sm',
    md: 'sm:max-w-md',
    lg: 'sm:max-w-lg',
    xl: 'sm:max-w-xl',
    '2xl': 'sm:max-w-2xl',
})

export interface DialogProps {
    /** Boolean value that controls open/close states */
    isOpen?: boolean

    /** Function to run on dialog close—also used to connect to close icon, and should be function used to toggle `isOpen` prop */
    onClose: () => void

    /** Whether or not to show the close icon */
    showCloseButton?: boolean

    initialFocus?: React.MutableRefObject<HTMLElement | null>

    // defaults to 'md'
    size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl'
}

export function DialogRoot({
    isOpen = false,
    onClose,
    showCloseButton = true,
    initialFocus,
    size = 'md',
    children,
    ...rest
}: PropsWithChildren<DialogProps>): JSX.Element {
    let actions: React.ReactNode = null
    let title: React.ReactNode = null
    let content: React.ReactNode = null
    let description: React.ReactNode = null
    let unhandledChildren: React.ReactNode = null

    Children.forEach(children, (child) => {
        const name = (child as any).type?.name
        switch (name) {
            case 'Actions':
                actions = child
                break
            case 'Content':
                content = child
                break
            case 'Title':
                title = child
                break
            case 'Description':
                description = child
                break
            default:
                unhandledChildren = child
                console.warn(
                    'Unhanded child type. Wrap your child element in <Dialog.Actions/>, <Dialog.Content/>, <Dialog.Title/>, or <Dialog.Description/> to ensure proper placement.'
                )
                break
        }
    })

    return (
        <Transition.Root
            show={isOpen}
            as={Fragment}
            leave="ease-in duration-200"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
        >
            <HeadlessDialog
                as="div"
                className="relative z-10"
                onClose={onClose}
                initialFocus={initialFocus}
                {...rest}
            >
                <Transition.Child
                    as={Fragment}
                    enter="ease-out duration-300"
                    enterFrom="opacity-0"
                    enterTo="opacity-100"
                    leave="ease-in duration-200"
                    leaveFrom="opacity-100"
                    leaveTo="opacity-0"
                >
                    {/* The backdrop */}
                    <div
                        className="fixed inset-0 bg-gray-800 bg-opacity-80 transition-opacity"
                        aria-hidden="true"
                    />
                </Transition.Child>

                <div className="fixed z-20 inset-0 overflow-y-auto">
                    <div className="flex items-center justify-center p-4 sm:p-0 min-h-full text-center ">
                        <Transition.Child
                            as={Fragment}
                            enter="ease-out duration-300"
                            enterFrom="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                            enterTo="opacity-100 translate-y-0 sm:scale-100"
                            leave="ease-in duration-200"
                            leaveFrom="opacity-100 translate-y-0 sm:scale-100"
                            leaveTo="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                        >
                            {/* Modal contents */}
                            <HeadlessDialog.Panel
                                className={classNames(
                                    'relative p-4 sm:p-6 sm:my-8 w-full bg-gray-700 rounded text-left shadow-md shadow-black transform transition-all',
                                    DialogSizeClassName[size]
                                )}
                            >
                                <div className="w-full flex items-start justify-between">
                                    {title && title}
                                    {showCloseButton && (
                                        <div className="shrink-0 pl-6 ml-auto">
                                            <button
                                                type="button"
                                                className="h-8 w-8 flex items-center justify-center bg-transparent text-gray-50 hover:bg-gray-500 rounded focus:bg-gray-400 focus:outline-none"
                                                onClick={onClose}
                                            >
                                                <IconClose className="h-6 w-6" />
                                            </button>
                                        </div>
                                    )}
                                </div>
                                <div className="mt-6">
                                    {content}
                                    {description && description}
                                </div>

                                {unhandledChildren && (
                                    <div className="py-2">{unhandledChildren}</div>
                                )}

                                {actions && actions}
                            </HeadlessDialog.Panel>
                        </Transition.Child>
                    </div>
                </div>
            </HeadlessDialog>
        </Transition.Root>
    )
}

export type DialogChildProps = {
    children: React.ReactNode
    className?: string
}

function Title({ className, children, ...rest }: DialogChildProps) {
    return (
        <HeadlessDialog.Title className={className} as="h4" {...rest}>
            {children}
        </HeadlessDialog.Title>
    )
}

function Content({ className, children, ...rest }: DialogChildProps) {
    return (
        <div className={className} {...rest}>
            {children}
        </div>
    )
}

function Description({ className, children, ...rest }: DialogChildProps) {
    return (
        <HeadlessDialog.Description className={`text-base text-gray-50 ${className}`} {...rest}>
            {children}
        </HeadlessDialog.Description>
    )
}

function Actions({ className, children, ...rest }: DialogChildProps) {
    return (
        <div className={`flex space-x-2 mt-6 ${className}`} {...rest}>
            {children}
        </div>
    )
}

// This assigns components as "<Dialog.Title/>", "<Dialog.Description/>", etc.
const Dialog = Object.assign(DialogRoot, {
    Title,
    Description,
    Actions,
    Content,
})

export default Dialog

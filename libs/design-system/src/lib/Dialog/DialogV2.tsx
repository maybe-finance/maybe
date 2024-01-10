import type { ReactNode } from 'react'
import { Dialog as HeadlessDialog, Transition } from '@headlessui/react'
import { Fragment } from 'react'
import { RiCloseFill } from 'react-icons/ri'
import classNames from 'classnames'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

const DialogSize = Object.freeze({
    xs: 'sm:max-w-xs',
    sm: 'sm:max-w-sm',
    md: 'sm:max-w-md',
    lg: 'sm:max-w-lg',
    xl: 'sm:max-w-xl',
    '2xl': 'sm:max-w-2xl',
})

type Size = keyof typeof DialogSize

type DialogProps = {
    title?: ReactNode
    description?: ReactNode
    size?: Size

    /* Panel styles */
    className?: string

    disablePadding?: boolean
}

export default function DialogV2({
    title,
    description,
    size = 'md',
    className,
    disablePadding = false,
    children,
    open,
    onClose,
    ...rest
}: DialogProps & ExtractProps<typeof HeadlessDialog>) {
    return (
        <Transition.Root
            show={open}
            as={Fragment}
            leave="ease-in duration-200"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
        >
            <HeadlessDialog open={open} onClose={onClose} {...rest}>
                {/* Backdrop */}
                <Transition.Child
                    as={Fragment}
                    enter="ease-out duration-300"
                    enterFrom="opacity-0"
                    enterTo="opacity-100"
                    leave="ease-in duration-200"
                    leaveFrom="opacity-100"
                    leaveTo="opacity-0"
                >
                    <div
                        className="fixed inset-0 bg-gray-800 bg-opacity-80 transition-opacity"
                        aria-hidden="true"
                    />
                </Transition.Child>

                <div className="fixed z-20 inset-0 flex justify-center items-center">
                    <Transition.Child
                        as={Fragment}
                        enter="ease-out duration-300"
                        enterFrom="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                        enterTo="opacity-100 translate-y-0 sm:scale-100"
                        leave="ease-in duration-200"
                        leaveFrom="opacity-100 translate-y-0 sm:scale-100"
                        leaveTo="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                    >
                        <HeadlessDialog.Panel
                            className={classNames(
                                'custom-gray-scroll bg-gray-700 rounded shadow-md shadow-black transform transition-all max-h-[600px] w-full',
                                DialogSize[size],
                                !disablePadding && 'p-6',
                                className
                            )}
                        >
                            <>
                                {title && (
                                    <div className="flex items-center gap-4 justify-between mb-4">
                                        <HeadlessDialog.Title as="h4">{title}</HeadlessDialog.Title>
                                        <div className="shrink-0 pl-6 ml-auto">
                                            <button
                                                type="button"
                                                className="h-8 w-8 flex items-center justify-center bg-transparent text-gray-50 hover:bg-gray-500 rounded focus:bg-gray-400 focus:outline-none"
                                                onClick={() => onClose(false)}
                                            >
                                                <RiCloseFill className="h-6 w-6" />
                                            </button>
                                        </div>
                                    </div>
                                )}
                                {description && (
                                    <div className="text-base text-gray-50">{description}</div>
                                )}
                                {children}
                            </>
                        </HeadlessDialog.Panel>
                    </Transition.Child>
                </div>
            </HeadlessDialog>
        </Transition.Root>
    )
}

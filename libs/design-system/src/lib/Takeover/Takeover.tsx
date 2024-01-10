import type { RefObject } from 'react'
import { Fragment } from 'react'
import { Dialog, Transition } from '@headlessui/react'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

export type TakeoverProps = ExtractProps<typeof Dialog> & {
    scrollContainerRef?: RefObject<HTMLDivElement>
}

export default function Takeover({
    open,
    onClose,
    children,
    scrollContainerRef,
    ...rest
}: TakeoverProps) {
    return (
        <Transition.Root
            show={open}
            as={Fragment}
            enter="ease-in duration-100"
            enterFrom="opacity-0"
            enterTo="opacity-100"
            leave="ease-in duration-100"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
        >
            <Dialog onClose={onClose} {...rest}>
                <div
                    className="z-50 fixed inset-0 bg-black custom-gray-scroll"
                    ref={scrollContainerRef}
                >
                    <Transition.Child
                        as={Fragment}
                        enter="ease-out duration-300"
                        enterFrom="sm:scale-95"
                        enterTo="sm:scale-100"
                        leave="ease-in duration-200"
                        leaveFrom="sm:scale-100"
                        leaveTo="sm:scale-95"
                    >
                        <Dialog.Panel className="inset-0 overflow-hidden">{children}</Dialog.Panel>
                    </Transition.Child>
                </div>
            </Dialog>
        </Transition.Root>
    )
}

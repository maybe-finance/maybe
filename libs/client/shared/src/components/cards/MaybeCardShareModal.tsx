import { Fragment } from 'react'
import { Dialog, Transition } from '@headlessui/react'
import { toast } from 'react-hot-toast'
import { RiLink, RiTwitterFill } from 'react-icons/ri'
import { Button } from '@maybe-finance/design-system'
import { MaybeCard, type MaybeCardProps } from './MaybeCard'

export type MaybeCardShareModalProps = {
    isOpen: boolean
    onClose: () => void
    cardUrl: string
    card: Omit<MaybeCardProps, 'flipped'>
}

export function MaybeCardShareModal({ isOpen, onClose, cardUrl, card }: MaybeCardShareModalProps) {
    return (
        <Transition appear show={isOpen} as={Fragment}>
            <Dialog as="div" className="relative z-10" onClose={onClose}>
                <Transition.Child
                    as={Fragment}
                    enter="ease-out duration-300"
                    enterFrom="opacity-0"
                    enterTo="opacity-100"
                    leave="ease-in duration-200"
                    leaveFrom="opacity-100"
                    leaveTo="opacity-0"
                >
                    {/* Backdrop */}
                    <div
                        className="fixed inset-0 bg-gray-800 bg-opacity-80 transition-opacity"
                        aria-hidden="true"
                    />
                </Transition.Child>

                <div className="fixed inset-0 overflow-y-auto">
                    <div className="flex min-h-full items-center justify-center p-4 text-center">
                        <Transition.Child
                            as={Fragment}
                            enter="ease-out duration-300"
                            enterFrom="opacity-0 scale-95"
                            enterTo="opacity-100 scale-100"
                            leave="ease-in duration-200"
                            leaveFrom="opacity-100 scale-100"
                            leaveTo="opacity-0 scale-95"
                        >
                            <Dialog.Panel className="relative w-full sm:max-w-md p-4 sm:p-6 sm:my-8 bg-gray-700 rounded text-left shadow-md shadow-black transform transition-all">
                                <div className="rounded-lg overflow-hidden">
                                    <MaybeCard variant="settings" flipped={false} {...card} />
                                </div>
                                <div className="mt-6 flex flex-col space-y-3">
                                    <Button
                                        as="a"
                                        variant="primary"
                                        fullWidth
                                        href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(
                                            `I'm user #${card.details?.memberNumber} on @Maybe and I'm using it to manage my finances and investing!\n\nGive it a go: https://maybe.co\n\n${cardUrl}`
                                        )}`}
                                        target="_blank"
                                        onClick={() => onClose()}
                                    >
                                        Tweet
                                        <RiTwitterFill className="ml-2 w-5 h-5" />
                                    </Button>
                                    <Button
                                        type="button"
                                        variant="secondary"
                                        fullWidth
                                        onClick={() => {
                                            navigator.clipboard.writeText(cardUrl)
                                            toast('Link copied to clipboard')
                                            onClose()
                                        }}
                                    >
                                        Share link
                                        <RiLink className="ml-2 w-5 h-5 text-gray-50" />
                                    </Button>
                                </div>
                            </Dialog.Panel>
                        </Transition.Child>
                    </div>
                </div>
            </Dialog>
        </Transition>
    )
}

import { BrowserUtil, usePlaid } from '@maybe-finance/client/shared'
import { Disclosure, Transition } from '@headlessui/react'
import { RiArrowUpSFill } from 'react-icons/ri'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'
import Link from 'next/link'

// https://plaid.com/docs/link/oauth/#create-and-register-a-redirect-uri
export default function OAuth() {
    const { fetchTokenError } = usePlaid('oauth')

    // If our backend doesn't return a token to re-initialize with, show user troubleshooting message
    if (fetchTokenError) {
        return (
            <div className="fixed flex flex-col items-center w-full h-full gap-4 mt-48">
                <LoadingSpinner />
                {fetchTokenError && (
                    <>
                        <h4>Stuck on this page?</h4>
                        <div className="w-full max-w-md p-2 mx-auto bg-gray-800 rounded-2xl">
                            <Disclosure defaultOpen>
                                {({ open }) => (
                                    <>
                                        <Disclosure.Button className="flex items-center justify-between w-full px-4 py-2 text-sm font-medium text-left text-purple-900 bg-gray-700 rounded-lg hover:bg-purple-200 focus:outline-none focus-visible:ring focus-visible:ring-purple-500 focus-visible:ring-opacity-75">
                                            <span>Why did this happen?</span>
                                            <RiArrowUpSFill
                                                className={`${
                                                    open ? 'rotate-180 transform' : ''
                                                } h-5 w-5 text-purple-500`}
                                            />
                                        </Disclosure.Button>
                                        <Transition
                                            show={open}
                                            enter="transition duration-100 ease-out"
                                            enterFrom="transform scale-95 opacity-0"
                                            enterTo="transform scale-100 opacity-100"
                                            leave="transition duration-75 ease-out"
                                            leaveFrom="transform scale-100 opacity-100"
                                            leaveTo="transform scale-95 opacity-0"
                                        >
                                            <Disclosure.Panel className="px-4 pt-4 pb-2 text-base text-gray-50">
                                                <p>
                                                    If you are stuck on this page, it is most likely
                                                    because you are on a mobile device. Some Plaid
                                                    institutions have app-to-app login flows that
                                                    are subject to change and cause problems from
                                                    time to time. Here are some tips if you are
                                                    stuck.
                                                </p>

                                                <ul className="mt-4 ml-4 list-disc">
                                                    <li>
                                                        Try connecting this account on a desktop
                                                        device. We have a mobile app on our roadmap,
                                                        but for the time being, desktop browsers
                                                        will be your most reliable experience.
                                                    </li>
                                                    <li>Still not working? Let us know!</li>
                                                </ul>
                                            </Disclosure.Panel>
                                        </Transition>
                                    </>
                                )}
                            </Disclosure>
                        </div>
                        <Link href="/" passHref>
                            <Button as="a">Back home</Button>
                        </Link>
                    </>
                )}
            </div>
        )
    }

    // This page re-initializes Plaid link and if we show any loading state, it flickers on faster networks, so return empty page
    return <></>
}

import { useUserApi } from '@maybe-finance/client/shared'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'
import { useState } from 'react'
import { RiExternalLinkLine } from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { UpgradeTakeover } from '.'
import Link from 'next/link'

export function BillingPreferences() {
    const { useSubscription, useCreateCustomerPortalSession } = useUserApi()

    const { data, isLoading, isError } = useSubscription()
    const createCustomerPortalSession = useCreateCustomerPortalSession()

    const [takeoverOpen, setTakeoverOpen] = useState(false)

    if (isError) {
        return <p className="text-gray-50">Failed to load billing information.</p>
    }

    return (
        <>
            <div className="mt-6 max-w-lg text-base">
                <h4 className="mb-2 text-lg uppercase">Billing</h4>
                {isLoading || !data ? (
                    <div className="flex items-center justify-center w-lg max-w-full py-8">
                        <LoadingSpinner />
                    </div>
                ) : (
                    <div className="bg-gray-800 rounded-lg overflow-hidden">
                        <div className="flex items-center p-4">
                            <div className="grow text-gray-50 pr-4">
                                {data.trialing ? (
                                    <p>
                                        Your free trial will end on{' '}
                                        <span className="text-white">
                                            {data.trialEnd?.toFormat('MMMM d, yyyy')}
                                        </span>
                                    </p>
                                ) : data.subscribed ? (
                                    <p>
                                        Your current plan will {data.canceled ? 'end' : 'renew'} on{' '}
                                        <span className="text-white">
                                            {data.currentPeriodEnd?.toFormat('MMMM d, yyyy')}
                                        </span>
                                    </p>
                                ) : (
                                    <p>You&rsquo;re not currently subscribed to Maybe.</p>
                                )}
                            </div>
                            <div className="shrink-0">
                                {data.subscribed && !data.trialing ? (
                                    <Button
                                        variant="secondary"
                                        onClick={() =>
                                            createCustomerPortalSession
                                                .mutateAsync('monthly')
                                                .then(({ url }) => (window.location.href = url))
                                        }
                                    >
                                        Manage
                                        {createCustomerPortalSession.isLoading ||
                                        createCustomerPortalSession.isSuccess ? (
                                            <LoadingIcon className="text-gray-100 ml-2.5 mr-1 w-3.5 h-3.5 animate-spin" />
                                        ) : (
                                            <RiExternalLinkLine className="ml-2 w-5 h-5" />
                                        )}
                                    </Button>
                                ) : (
                                    <Button
                                        variant="primary"
                                        disabled
                                        onClick={() => setTakeoverOpen(true)}
                                    >
                                        Subscriptions disabled
                                    </Button>
                                )}
                            </div>
                        </div>
                        <div className="p-3 text-sm bg-gray-700 text-gray-100">
                            You&rsquo;ll be redirected to Stripe to manage billing.
                        </div>
                    </div>
                )}

                <div className="mt-8 bg-cyan text-white p-3 rounded">
                    <p className="">
                        Maybe will be shutting down on July 31.{' '}
                        <Link
                            className="text-white font-bold underline"
                            href="https://maybefinance.notion.site/To-Investors-Customers-The-Future-of-Maybe-6758bfc0e46f4ec68bf4a7a8f619199f"
                        >
                            Details and FAQ
                        </Link>
                    </p>
                </div>
            </div>
            <UpgradeTakeover open={takeoverOpen} onClose={() => setTakeoverOpen(false)} />
        </>
    )
}

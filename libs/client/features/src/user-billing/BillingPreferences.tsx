import { useUserApi } from '@maybe-finance/client/shared'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'
import { useState } from 'react'
import { RiExternalLinkLine } from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { UpgradeTakeover } from '.'

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
            <div className="max-w-lg mt-6 text-base">
                <h4 className="mb-2 text-lg uppercase">Billing</h4>
                {isLoading || !data ? (
                    <div className="flex items-center justify-center max-w-full py-8 w-lg">
                        <LoadingSpinner />
                    </div>
                ) : (
                    <div className="overflow-hidden bg-gray-800 rounded-lg">
                        <div className="flex items-center p-4">
                            <div className="pr-4 grow text-gray-50">
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
                                            <RiExternalLinkLine className="w-5 h-5 ml-2" />
                                        )}
                                    </Button>
                                ) : (
                                    <Button variant="primary" onClick={() => setTakeoverOpen(true)}>
                                        Subscribe
                                    </Button>
                                )}
                            </div>
                        </div>
                        <div className="p-3 text-sm text-gray-100 bg-gray-700">
                            You&rsquo;ll be redirected to Stripe to manage billing.
                        </div>
                    </div>
                )}
            </div>
            {process.env.STRIPE_API_KEY && (
                <UpgradeTakeover open={takeoverOpen} onClose={() => setTakeoverOpen(false)} />
            )}
        </>
    )
}

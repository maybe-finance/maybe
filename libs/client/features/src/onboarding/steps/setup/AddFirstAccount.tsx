import { Fragment, useState } from 'react'
import { Transition } from '@headlessui/react'
import { RiLoader4Fill, RiLockLine } from 'react-icons/ri'
import { motion } from 'framer-motion'
import { Button } from '@maybe-finance/design-system'
import { useAccountContext, useUserAccountContext } from '@maybe-finance/client/shared'
import { ExampleApp } from '../../ExampleApp'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import type { StepProps } from '../StepProps'

export function AddFirstAccount({ title, onNext }: StepProps) {
    const [isSubmitting, setIsSubmitting] = useState(false)
    const { addAccount } = useAccountContext()
    const { noAccounts, allAccountsDisabled, someAccountsSyncing } = useUserAccountContext()

    const accountAdded = !noAccounts && !allAccountsDisabled && !someAccountsSyncing

    return (
        <div className="min-h-[700px] overflow-x-hidden">
            <div className="flex max-w-5xl mx-auto gap-32 justify-center sm:justify-start">
                <div className="relative grow max-w-md sm:mt-12 text-center sm:text-start">
                    <Transition
                        show={!accountAdded}
                        as={Fragment}
                        enter="ease-in duration-100"
                        enterFrom="opacity-0 translate-y-8"
                        enterTo="opacity-100 translate-y-0"
                        leave="ease-in duration-100"
                        leaveFrom="opacity-100 translate-y-0"
                        leaveTo="opacity-0 translate-y-8"
                        unmount={false}
                    >
                        <div className="relative">
                            <h3>{title}</h3>
                            <div className="text-base text-gray-50">
                                <p className="mt-2">
                                    To get the most out of Maybe you need to add your financial
                                    accounts. Doing this gives you better insights, contextual
                                    financial planning, and relevant advice.
                                </p>
                                <p className="mt-6">
                                    You probably have quite a few assets and debts, so we&rsquo;ll
                                    add the one thing most people have &ndash; a bank account.
                                    You&rsquo;ll be able to add the rest of your accounts later.
                                </p>
                            </div>
                            <div className="mt-7 flex items-center justify-between">
                                {[
                                    ['Chase Bank', 'chase-bank'],
                                    ['Wells Fargo', 'wells-fargo'],
                                    ['Bank of America', 'bofa'],
                                    ['Charles Schwab', 'charles-schwab'],
                                    ['Capital One', 'capital-one'],
                                    ['Citibank', 'citi'],
                                ].map(([name, src]) => (
                                    <div key={name} className="h-6">
                                        <img
                                            src={`/assets/icons/financial-institutions/${src}.svg`}
                                            alt={name}
                                            className="h-full w-auto"
                                        />
                                    </div>
                                ))}
                            </div>
                            <p className="mt-4 text-center text-sm text-gray-50">
                                &amp; 10,000 other institutions available
                            </p>
                            <div className="mt-7">
                                {someAccountsSyncing ? (
                                    <div className="mt-3 flex flex-col items-center space-y-3">
                                        <RiLoader4Fill className="w-6 h-6 animate-spin text-white" />
                                        <p className="text-sm text-gray-100">
                                            Your account data is syncing
                                        </p>
                                    </div>
                                ) : (
                                    <>
                                        <Button fullWidth className="mt-7" onClick={addAccount}>
                                            Connect your primary bank account
                                        </Button>
                                        <button
                                            className="mt-2 w-full p-2 text-center text-base text-white hover:text-gray-25 flex items-center justify-center"
                                            onClick={async () => {
                                                setIsSubmitting(true)
                                                await onNext()
                                                setIsSubmitting(false)
                                            }}
                                        >
                                            I&rsquo;m not ready to connect accounts yet{' '}
                                            {isSubmitting && (
                                                <LoadingIcon className="ml-2 w-5 h-5 animate-spin" />
                                            )}
                                        </button>
                                        <div className="mt-6 flex space-x-2 text-sm text-gray-100">
                                            <RiLockLine className="shrink-0 w-4 h-4" />
                                            <p className="grow">
                                                Adding your accounts is a big step. That&rsquo;s why
                                                we take this seriously. No one can access your
                                                accounts but you. Your information is always
                                                protected and secure.
                                            </p>
                                        </div>
                                    </>
                                )}
                            </div>
                        </div>
                    </Transition>
                    <Transition
                        show={accountAdded}
                        as={Fragment}
                        enter="ease-in duration-100"
                        enterFrom="opacity-0 translate-y-8"
                        enterTo="opacity-100 translate-y-0"
                        leave="ease-in duration-100"
                        leaveFrom="opacity-100 translate-y-0"
                        leaveTo="opacity-0 translate-y-8"
                    >
                        <div className="absolute top-0">
                            <h3>Look at you go!</h3>
                            <div className="text-base text-gray-50">
                                <p className="mt-2">
                                    Way to go on successfully connecting your first account! Thanks
                                    for your trust in us to keep your financial information secure.
                                </p>
                                <p className="mt-6">
                                    If there are any data issues or something&rsquo;s looking wrong,
                                    you can reach out to us to try and resolve the issue or continue
                                    setting up your account and fix it later.
                                </p>
                            </div>
                            <Button
                                fullWidth
                                className="mt-7"
                                onClick={async () => {
                                    setIsSubmitting(true)
                                    await onNext()
                                    setIsSubmitting(false)
                                }}
                            >
                                Continue{' '}
                                {isSubmitting && (
                                    <LoadingIcon className="ml-2 w-5 h-5 animate-spin" />
                                )}
                            </Button>
                        </div>
                    </Transition>
                </div>
                <div className="relative grow hidden sm:block">
                    <motion.div
                        initial={{ translateX: 60 }}
                        animate={{ translateX: 0 }}
                        className="absolute left-0 top-0"
                        style={{
                            WebkitMaskImage:
                                'radial-gradient(ellipse at 0 0, #FFFF 0%, #FFFF 30%, #0000 65%)',
                        }}
                    >
                        <ExampleApp />
                    </motion.div>
                </div>
            </div>
        </div>
    )
}

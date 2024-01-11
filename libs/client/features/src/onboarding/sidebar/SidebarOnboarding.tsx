import { Disclosure, Transition } from '@headlessui/react'
import { useUserAccountContext, useUserApi } from '@maybe-finance/client/shared'
import { Button, LoadingSpinner, Menu } from '@maybe-finance/design-system'
import classNames from 'classnames'
import {
    RiArrowDownSFill,
    RiArrowLeftLine,
    RiArrowRightSLine,
    RiArrowUpSFill,
    RiCheckFill,
    RiCloseFill,
    RiEyeOffLine,
    RiMore2Fill,
} from 'react-icons/ri'
import { HiOutlineSparkles } from 'react-icons/hi'
import Link from 'next/link'
import { AnimatePresence, motion } from 'framer-motion'

type DescriptionProps = {
    summary: string
    examples: string[]
}

function Description({ summary, examples }: DescriptionProps) {
    return (
        <div className="text-gray-50 text-base mt-2">
            <p className="mb-4">{summary}</p>
            <ul>
                {examples.map((example) => (
                    <li key={example} className="list-disc ml-6">
                        {example}
                    </li>
                ))}
            </ul>
        </div>
    )
}

function getDescriptionComponent(key: string) {
    switch (key) {
        case 'connect-depository':
            return (
                <Description
                    summary="This includes primary bank accounts used for direct deposits, emergency funds, etc."
                    examples={['Checking account', 'Savings account']}
                />
            )

        case 'connect-investment':
            return (
                <Description
                    summary="This includes accounts you are using to grow your wealth over time."
                    examples={[
                        'Brokerage (e.g. Robinhood)',
                        "Retirement accounts (401k's, Roth IRA, Traditional IRA, etc.)",
                        'Savings accounts (HSA, ESA, etc.',
                    ]}
                />
            )

        case 'connect-liability':
            return (
                <Description
                    summary="This includes accounts that you make debt payments to."
                    examples={[
                        'Credit cards',
                        'Home loans (mortgage)',
                        'Student loans',
                        'Auto loans',
                    ]}
                />
            )

        case 'add-crypto':
            return (
                <Description
                    summary="This includes the market value of any cryptocurrency you own."
                    examples={['Bitcoin', 'Ethereum', 'Alt-Coins', 'NFTs']}
                />
            )

        case 'add-property':
            return (
                <Description
                    summary="This includes the market value of any property you own."
                    examples={['House', 'Condo', 'Land']}
                />
            )

        case 'add-vehicle':
            return (
                <Description
                    summary="This includes the market value of the current vehicles you own"
                    examples={[]}
                />
            )

        case 'add-other':
            return (
                <Description
                    summary="This includes any other accounts that don't fall into a category"
                    examples={['Physical cash', 'Collectibles and art', 'Alternative investments']}
                />
            )

        default:
            throw new Error(`${key} is not a valid step key `)
    }
}

type Props = {
    onClose(): void
    onHide(): void
}

export function SidebarOnboarding({ onClose, onHide }: Props) {
    const { useOnboarding, useUpdateOnboarding } = useUserApi()
    const onboarding = useOnboarding('sidebar')
    const updateOnboarding = useUpdateOnboarding()

    const { syncProgress } = useUserAccountContext()

    if (onboarding.isLoading) {
        return (
            <div className="w-full flex justify-center items-center h-full">
                <LoadingSpinner />
            </div>
        )
    }

    if (onboarding.isError) {
        return (
            <div className="text-base">
                <div className="flex items-center gap-2 mb-2">
                    <Button variant="icon" onClick={onClose}>
                        <RiArrowLeftLine size={18} />
                    </Button>
                    Back
                </div>

                <p className="text-gray-50">
                    Unable to load onboarding progress. Please contact us so we can get this fixed!
                </p>
            </div>
        )
    }

    const {
        progress: { completed, total, percent },
        steps,
    } = onboarding.data

    const minutesPerStep = 2

    const accountSteps = steps.filter((step) => step.group === 'accounts')
    const bonusSteps = steps.filter((step) => step.group === 'bonus')

    return (
        <>
            <div className="flex items-center gap-3.5 text-base w-full mb-5">
                <Button variant="icon" onClick={onClose}>
                    <RiArrowLeftLine size={18} className="text-gray-50" />
                </Button>

                <p className="mr-auto">Getting started</p>

                <Menu>
                    <Menu.Button variant="icon">
                        <RiMore2Fill size={18} />
                    </Menu.Button>
                    <Menu.Items>
                        <Menu.Item className="flex items-center gap-2" onClick={onHide}>
                            <RiEyeOffLine size={18} />
                            Hide "Getting started" widget
                        </Menu.Item>
                    </Menu.Items>
                </Menu>
            </div>

            <AnimatePresence>
                {syncProgress && (
                    <motion.div
                        className="overflow-hidden text-base text-gray-100"
                        key="importing-message"
                        initial={{ height: 0 }}
                        animate={{ height: 'auto' }}
                        exit={{ height: 0 }}
                    >
                        {syncProgress.description}...
                        <div className="my-4">
                            <div className="relative w-full h-[3px] rounded-full overflow-hidden bg-gray-200">
                                {syncProgress.progress ? (
                                    <motion.div
                                        key="progress-determinate"
                                        initial={{ width: 0 }}
                                        animate={{ width: `${syncProgress.progress * 100}%` }}
                                        transition={{ ease: 'easeOut', duration: 0.5 }}
                                        className="h-full rounded-full bg-gray-100"
                                    ></motion.div>
                                ) : (
                                    <motion.div
                                        key="progress-indeterminate"
                                        className="w-[40%] h-full rounded-full bg-gray-100"
                                        animate={{ translateX: ['-100%', '250%'] }}
                                        transition={{ repeat: Infinity, duration: 1.8 }}
                                    ></motion.div>
                                )}
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>

            <div className="text-base">
                <div className="flex items-center justify-between pb-3">
                    <p className="text-cyan">{`${completed} of ${total} done`}</p>
                    {completed === total ? (
                        <RiCheckFill size={20} className="text-cyan" />
                    ) : (
                        <p className="text-gray-100">
                            ~ {(total - completed) * minutesPerStep} mins
                        </p>
                    )}
                </div>
                <div className="relative h-2 bg-gray-600 rounded-sm">
                    <div
                        className="absolute inset-0 bg-cyan h-2 rounded-sm"
                        style={{
                            width: `${percent * 100}%`,
                        }}
                    ></div>
                </div>
            </div>

            <div className="flex flex-col items-start gap-2 text-base pr-4 -mr-4 custom-gray-scroll">
                {accountSteps.map((step, idx) => {
                    const description = getDescriptionComponent(step.key)

                    return (
                        <Disclosure>
                            {({ open }) => (
                                <div
                                    className={classNames(
                                        'p-3 w-full rounded-lg',
                                        open && 'bg-gray-700'
                                    )}
                                >
                                    <Disclosure.Button
                                        className={classNames(
                                            'flex items-center gap-3 w-full',
                                            open ? 'text-white' : 'text-gray-100'
                                        )}
                                    >
                                        <div className="flex items-center text-left leading-5 gap-3 mr-auto">
                                            <div
                                                className={classNames(
                                                    'rounded-full w-[28px] h-[28px] flex items-center justify-center shrink-0',
                                                    step.isComplete
                                                        ? 'bg-cyan bg-opacity-10'
                                                        : 'bg-gray-600'
                                                )}
                                            >
                                                {step.isComplete || step.isMarkedComplete ? (
                                                    <RiCheckFill size={20} className="text-cyan" />
                                                ) : (
                                                    <span className="font-medium text-sm">
                                                        {idx + 1}
                                                    </span>
                                                )}
                                            </div>
                                            <span
                                                className={
                                                    step.isComplete || step.isMarkedComplete
                                                        ? 'line-through'
                                                        : ''
                                                }
                                            >
                                                {step.title}
                                            </span>
                                        </div>
                                        {open ? (
                                            <RiArrowUpSFill
                                                size={18}
                                                className="text-gray-100 shrink-0"
                                            />
                                        ) : (
                                            <RiArrowDownSFill
                                                size={18}
                                                className="text-gray-100 shrink-0"
                                            />
                                        )}
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
                                        <Disclosure.Panel static>
                                            {description}

                                            <div className="bg-gray-600 my-4 h-[1px]"></div>

                                            {step.isComplete ? (
                                                <p className="text-gray-50 text-sm">
                                                    This step has been automatically marked complete
                                                    since you've added at least 1 of these account
                                                    types.
                                                </p>
                                            ) : (
                                                <Button
                                                    variant="link"
                                                    className="flex items-center gap-2 mx-auto"
                                                    fullWidth
                                                    onClick={() => {
                                                        updateOnboarding.mutate({
                                                            flow: 'sidebar',
                                                            updates: [
                                                                {
                                                                    key: step.key,
                                                                    markedComplete:
                                                                        !step.isMarkedComplete,
                                                                },
                                                            ],
                                                        })
                                                    }}
                                                >
                                                    {step.isMarkedComplete ? (
                                                        <>
                                                            Mark as incomplete
                                                            <RiCloseFill size={18} />
                                                        </>
                                                    ) : (
                                                        <>
                                                            Mark as done
                                                            <RiCheckFill size={18} />
                                                        </>
                                                    )}
                                                </Button>
                                            )}
                                        </Disclosure.Panel>
                                    </Transition>
                                </div>
                            )}
                        </Disclosure>
                    )
                })}
            </div>

            <Disclosure defaultOpen>
                {({ open }) => (
                    <div className={classNames('p-3 rounded-lg bg-grape bg-opacity-10 text-base')}>
                        <Disclosure.Button className="flex items-center gap-2 text-grape w-full font-medium">
                            <HiOutlineSparkles size={24} />
                            <span className="mr-auto">Bonus</span>
                            {open ? <RiArrowUpSFill size={18} /> : <RiArrowDownSFill size={18} />}
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
                            <Disclosure.Panel className="mt-4 space-y-3" static>
                                {bonusSteps.map((step, idx) => {
                                    return (
                                        <Link href={step.ctaPath!} className="block" key={step.key}>
                                            <div className="flex items-center gap-4 cursor-pointer group">
                                                <div className="text-grape w-[28px] h-[28px] rounded-full bg-grape bg-opacity-10 flex items-center justify-center">
                                                    {idx + 1}
                                                </div>
                                                <span
                                                    className={classNames(
                                                        'group-hover:underline',
                                                        step.isComplete && 'line-through'
                                                    )}
                                                >
                                                    {step.title}
                                                </span>
                                                <RiArrowRightSLine
                                                    size={24}
                                                    className="ml-auto text-grape group-hover:opacity-90"
                                                />
                                            </div>
                                        </Link>
                                    )
                                })}
                            </Disclosure.Panel>
                        </Transition>
                    </div>
                )}
            </Disclosure>

            <p className="text-sm text-gray-100">
                If you have any issues with connecting accounts,{' '}
                <a className="text-cyan underline" href="mailto:hello@maybe.co">
                    please let us know
                </a>
                .
            </p>
        </>
    )
}

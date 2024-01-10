import { useState } from 'react'
import classNames from 'classnames'
import { motion } from 'framer-motion'
import {
    RiBankCard2Line,
    RiBankLine,
    RiBitCoinLine,
    RiCarLine,
    RiHandCoinLine,
    RiHomeLine,
    RiLineChartLine,
    RiMoneyDollarBoxLine,
    RiVipCrown2Line,
} from 'react-icons/ri'
import { Button } from '@maybe-finance/design-system'
import { ExampleApp } from '../../ExampleApp'
import type { StepProps } from '../StepProps'
import { useUserApi } from '@maybe-finance/client/shared'
import uniqBy from 'lodash/uniqBy'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'

const accountTypes = [
    {
        icon: RiMoneyDollarBoxLine,
        label: 'Cash',
        name: 'cash',
        stepKey: 'add-other',
    },
    {
        icon: RiBankLine,
        label: 'Savings account',
        name: 'savings account',
        stepKey: 'connect-depository',
    },
    {
        icon: RiBankLine,
        label: 'Checking account',
        name: 'checking account',
        stepKey: 'connect-depository',
    },
    {
        icon: RiBankCard2Line,
        label: 'Credit card',
        name: 'credit card',
        stepKey: 'connect-liability',
    },
    {
        icon: RiLineChartLine,
        label: 'Brokerage (Robinhood, Fidelity, etc.)',
        name: 'brokerage account',
        stepKey: 'connect-investment',
    },
    {
        icon: RiLineChartLine,
        label: 'Retirement (401(k), IRA, etc.)',
        name: 'retirement account',
        stepKey: 'connect-investment',
    },
    {
        icon: RiBitCoinLine,
        label: 'Crypto',
        name: 'crypto',
        stepKey: 'add-crypto',
    },
    {
        icon: RiLineChartLine,
        label: 'Alternative investments',
        name: 'investment account',
        stepKey: 'add-other',
    },
    {
        icon: RiCarLine,
        label: 'Vehicle',
        name: 'vehicle',
        stepKey: 'add-vehicle',
    },
    {
        icon: RiHomeLine,
        label: 'Property (home, rental, etc.)',
        name: 'property',
        stepKey: 'add-property',
    },
    {
        icon: RiVipCrown2Line,
        label: 'Valuables (art, jewelry, etc.)',
        name: 'valuables',
        stepKey: 'add-other',
    },
    {
        icon: RiHandCoinLine,
        label: 'Loans (home, student, auto, etc.)',
        name: 'loans',
        stepKey: 'connect-liability',
    },
]

export function OtherAccounts({ title, onNext }: StepProps) {
    const [selected, setSelected] = useState<string[]>([])
    const [isSubmitting, setIsSubmitting] = useState(false)

    const { useUpdateOnboarding } = useUserApi()
    const updateOnboarding = useUpdateOnboarding()

    return (
        <div className="min-h-[700px] overflow-x-hidden">
            <div className="flex max-w-5xl mx-auto gap-32 justify-center sm:justify-start">
                <div className="grow max-w-md sm:mt-12 text-center sm:text-start">
                    <h3>{title}</h3>
                    <p className="mt-2 text-base text-gray-50">
                        You can select bank accounts if there are any other accounts you&rsquo;d
                        like to add. Feel free to select more than one. We&rsquo;ll add these to
                        your checklist to remind you around what to add.
                    </p>
                    <div className="mt-6 flex flex-wrap gap-2 justify-center sm:justify-start">
                        {accountTypes.map(({ icon: Icon, label, name }) => (
                            <button
                                key={name}
                                className={classNames(
                                    'flex items-center gap-2 py-2 px-3 text-base text-white rounded-xl border bg-cyan transition-colors duration-50',
                                    selected.includes(name)
                                        ? 'border-cyan bg-opacity-10'
                                        : 'border-gray-500 bg-opacity-0'
                                )}
                                onClick={() =>
                                    setSelected((selected) =>
                                        selected.includes(name)
                                            ? selected.filter((n) => n !== name)
                                            : [...selected, name]
                                    )
                                }
                            >
                                <Icon className="w-5 h-5 text-gray-100" />
                                {label}
                            </button>
                        ))}
                    </div>

                    <Button
                        className="mt-7 min-w-[50%]"
                        onClick={async () => {
                            setIsSubmitting(true)

                            const selections = accountTypes.filter(
                                (at) =>
                                    selected.includes(at.name) ||
                                    at.stepKey === 'connect-depository' // By default, every user will have depository acct for checklist
                            )
                            const uniqueKeys = uniqBy(selections, 'stepKey').map(({ stepKey }) => ({
                                stepKey,
                            }))

                            // Dynamically add steps based on user selections
                            await updateOnboarding.mutateAsync({
                                flow: 'sidebar',
                                updates: uniqueKeys.map((v) => ({
                                    key: v.stepKey,
                                    markedComplete: false,
                                })),
                            })

                            await onNext()

                            setIsSubmitting(false)
                        }}
                    >
                        Continue{' '}
                        {isSubmitting && <LoadingIcon className="ml-2 w-5 h-5 animate-spin" />}
                    </Button>
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
                        <ExampleApp checklist={selected} />
                    </motion.div>
                </div>
            </div>
        </div>
    )
}

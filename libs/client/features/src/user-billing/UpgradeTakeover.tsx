import type { IconType } from 'react-icons'
import { Fragment, useRef, useState } from 'react'
import { Button, Takeover } from '@maybe-finance/design-system'
import { PlanSelector, PremiumIcon } from '.'
import { Transition } from '@headlessui/react'
import {
    RiArrowUpLine,
    RiBankLine,
    RiCloseFill,
    RiFlagLine,
    RiLineChartLine,
    RiLinksLine,
    RiWechatLine,
} from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { TakeoverBackground, useUserApi } from '@maybe-finance/client/shared'
import upperFirst from 'lodash/upperFirst'
import { FeaturesGlow, SideGrid } from './graphics'

type UpgradeTakeoverProps = {
    open: boolean
    onClose: () => void
}

export function UpgradeTakeover({ open, onClose }: UpgradeTakeoverProps) {
    const scrollContainerRef = useRef<HTMLDivElement>(null)

    const { useProfile, useCreateCheckoutSession } = useUserApi()
    const profileQuery = useProfile()
    const user = profileQuery.data

    const createCheckoutSession = useCreateCheckoutSession()

    const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('yearly')

    return (
        <Takeover open={open} onClose={onClose} scrollContainerRef={scrollContainerRef}>
            <div className="absolute inset-0 z-auto overflow-hidden">
                <TakeoverBackground className="absolute -translate-x-1/2 -top-3 left-1/2" />
                <TakeoverBackground className="absolute rotate-180 -translate-x-1/2 -bottom-3 left-1/2" />
            </div>

            <div className="absolute z-10 top-12 right-12">
                <Button variant="icon" title="Close" onClick={onClose}>
                    <RiCloseFill className="w-6 h-6" />
                </Button>
            </div>

            <Transition.Child
                as={Fragment}
                enter="ease-out duration-300"
                enterFrom="translate-y-8"
                enterTo="translate-y-0"
                leave="ease-in duration-300"
                leaveFrom="translate-y-0"
                leaveTo="translate-y-8"
            >
                <div className="relative flex flex-col items-center max-w-3xl px-6 pt-16 pb-24 mx-auto">
                    <PremiumIcon size="xl" />

                    <h3 className="max-w-sm mt-10 text-center">
                        Take control of your financial future
                    </h3>

                    <div
                        className="relative mt-6 w-full p-[1px] rounded-2xl"
                        style={{
                            backgroundImage: `
                                linear-gradient(85deg, #1C1C20EE 5%, transparent, #1C1C20EE 95%),
                                linear-gradient(180deg, #4CC9F0 28.24%, #4361EE 46.15%, #7209B7 61.01%, #F72585 80.62%)
                            `,
                        }}
                    >
                        <div
                            className="flex flex-col items-center p-8 text-base text-center bg-gray-800 rounded-2xl text-gray-50"
                            style={{
                                backgroundImage: `
                                    radial-gradient(107% 89% at 23% -42%, #4CC9F040, transparent 100%),
                                    radial-gradient(87% 71% at 77% 139%, #F7258530, transparent 100%)
                                `,
                            }}
                        >
                            <p>Choose annual or monthly billing to start</p>

                            <PlanSelector
                                selected={selectedPlan}
                                onChange={setSelectedPlan}
                                className="w-full mt-6"
                            />

                            <Button
                                variant="primary"
                                className="min-w-[50%] mt-6"
                                onClick={() =>
                                    createCheckoutSession
                                        .mutateAsync(selectedPlan)
                                        .then(({ url }) => (window.location.href = url))
                                }
                                disabled={createCheckoutSession.isLoading}
                                data-testid="upgrade-takeover-upgrade-button"
                            >
                                {createCheckoutSession.isLoading && (
                                    <LoadingIcon className="inline w-3 h-3 mr-2 animate-spin text-gray" />
                                )}
                                Subscribe to Maybe
                            </Button>
                            <p className="max-w-sm mt-2 text-sm">
                                In the next step you&rsquo;ll be asked to enter your payment
                                details.
                            </p>
                        </div>
                    </div>

                    <div className="relative w-full max-w-2xl text-base mt-14">
                        <div className="relative -z-10">
                            <FeaturesGlow className="absolute -translate-x-1/2 -top-16 left-1/2" />
                            <SideGrid className="absolute left-0 -top-16" />
                        </div>

                        <h4 className="text-center">What&rsquo;s included</h4>

                        <div className="grid grid-cols-2 mt-6 sm:grid-cols-3 gap-y-6 gap-x-2">
                            {(
                                [
                                    [RiLinksLine, 'Net worth tracking'],
                                    [RiBankLine, 'Personal finance insights'],
                                    [RiLineChartLine, 'Investment planning & insights'],
                                    [RiFlagLine, 'Retirement planning & milestone simulation'],
                                    [RiWechatLine, 'Priority customer support'],
                                ] as [IconType, string][]
                            ).map(([Icon, description]) => (
                                <div key={description} className="flex flex-col items-center">
                                    <div
                                        className="p-[1px] rounded-2xl bg-black"
                                        style={{
                                            backgroundImage: `
                                                radial-gradient(107% 89% at 23% -42%, #4CC9F080, transparent 100%),
                                                radial-gradient(87% 73% at 84% 139%, #F7258580, transparent 100%)
                                            `,
                                        }}
                                    >
                                        <div className="p-3 bg-black bg-opacity-50 rounded-2xl">
                                            <Icon className="w-6 h-6 text-white" />
                                        </div>
                                    </div>
                                    <p className="mt-3 text-center text-white">{description}</p>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="w-full max-w-2xl p-6 text-base bg-gray-700 border border-gray-700 mt-14 rounded-2xl bg-opacity-10 backdrop-blur-lg">
                        <p className="text-sm text-gray-100">A message from the Maybe team</p>
                        <div className="flex flex-wrap mt-6 space-y-6 italic leading-5 text-white sm:flex-nowrap sm:space-y-0 sm:space-x-7">
                            <div className="w-full sm:w-1/2">
                                <p>
                                    Hey {user?.firstName},
                                    <br />
                                    <br />
                                    Thanks for considering Maybe.
                                    <br />
                                    <br />
                                    If the financial world is known for anything, it&rsquo;s for
                                    being opaque.
                                    <br />
                                    <br />
                                    Set it and forget it strategies, % of your assets &amp; returns,
                                    management fees, cold calls and upsells for products you never
                                    needed.
                                    <br />
                                    <br />
                                    With this subscription you're paying for control of your
                                    finances.
                                </p>
                            </div>
                            <div className="w-full sm:w-1/2">
                                <p>
                                    You deserve to know what your money is doing, why it's doing it
                                    and how to change it. You deserve to be equipped with the tools
                                    to live the life you want now and not decades down the road.
                                    <br />
                                    <br />
                                    This is our goal with Maybe. We make the tools, you make the
                                    rules.
                                    <br />
                                    <br />
                                    Thanks again,
                                    <br />
                                    Josh, Travis
                                </p>
                                <div className="flex mt-5 -space-x-2 shrink-0">
                                    {['josh', 'travis'].map((name) => (
                                        <img
                                            key={name}
                                            alt={upperFirst(name)}
                                            className="w-12 h-12 border-2 border-black rounded-full"
                                            src={`/assets/images/team/${name}.jpg`}
                                        />
                                    ))}
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="mt-8">
                        <Button
                            variant="icon"
                            className="p-2 text-gray-50 hover:text-white"
                            onClick={() =>
                                scrollContainerRef?.current?.scrollTo({
                                    top: 0,
                                    behavior: 'smooth',
                                })
                            }
                        >
                            <RiArrowUpLine className="w-6 h-6 shrink-0" />
                        </Button>
                    </div>
                </div>
            </Transition.Child>
        </Takeover>
    )
}

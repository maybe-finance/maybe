import type { Holding, Security } from '@prisma/client'
import { RiCloseFill, RiPencilLine, RiInformationLine, RiQuestionLine } from 'react-icons/ri'
import Image from 'next/legacy/image'
import { NumberUtil } from '@maybe-finance/shared'
import {
    BrowserUtil,
    TrendBadge,
    useHoldingApi,
    usePopoutContext,
    useSecurityApi,
} from '@maybe-finance/client/shared'
import { Button, Toggle, FractionalCircle, Tooltip } from '@maybe-finance/design-system'
import debounce from 'lodash/debounce'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { CostBasisForm } from './CostBasisForm'
import { SecurityPriceChart } from './SecurityPriceChart'
import AnimateHeight from 'react-animate-height'

export type HoldingPopoutProps = {
    holdingId: Holding['id']
    securityId: Security['id']
}

export function HoldingPopout({ holdingId, securityId }: HoldingPopoutProps) {
    const { close } = usePopoutContext()

    const { useHolding, useUpdateHolding, useHoldingInsights } = useHoldingApi()
    const { data: holding, isLoading } = useHolding(holdingId)
    const { useSecurity, useSecurityDetails } = useSecurityApi()

    const security = useSecurity(securityId)
    const securityDetails = useSecurityDetails(securityId)

    const updateHolding = useUpdateHolding()
    const holdingInsights = useHoldingInsights(holdingId)

    const [isEditingCost, setIsEditingCost] = useState(false)
    const [excluded, setExcluded] = useState<boolean | undefined>()

    useEffect(() => {
        setExcluded(holding?.excluded)
    }, [holding?.excluded])

    const mutate = useCallback(
        async (excluded: boolean) => {
            try {
                await updateHolding.mutateAsync({ id: holdingId, data: { excluded } })
            } catch (e) {
                setExcluded(!excluded)
            }
        },
        [updateHolding, holdingId]
    )

    const debouncedMutate = useMemo(() => debounce(mutate, 1000), [mutate])

    const onExcludedChange = useCallback(
        (excluded: boolean) => {
            setExcluded(excluded)
            debouncedMutate(excluded)
        },
        [debouncedMutate]
    )

    return (
        <div className="flex flex-col h-full overflow-hidden w-full lg:w-96">
            <div className="py-5 px-6">
                <Button variant="icon" title="Close" onClick={close}>
                    <RiCloseFill className="w-6 h-6" />
                </Button>
            </div>

            {isLoading ? (
                <div className="px-8 text-gray-100 animate-pulse">Loading holding...</div>
            ) : !holding ? (
                <div className="px-8 text-gray-100">
                    Sorry, we couldn't load this holding. Please try again or contact us.
                </div>
            ) : (
                <>
                    <div className="flex justify-between space-x-4 px-6 pb-2">
                        <div>
                            <h4 className="text-white">{holding.name}</h4>
                            <span className="block text-base text-gray-100">{holding.symbol}</span>
                        </div>
                        <div className="relative w-12 h-12 shrink-0 bg-gray-400 rounded-xl overflow-hidden">
                            <Image
                                loader={BrowserUtil.enhancerizerLoader}
                                src={JSON.stringify({
                                    kind: 'security',
                                    name: holding!.symbol ?? holding!.name,
                                })}
                                layout="fill"
                                sizes="48px, 64px, 96px, 128px"
                                onError={({ currentTarget }) => {
                                    // Fail gracefully and hide image
                                    currentTarget.onerror = null
                                    currentTarget.style.display = 'none'
                                }}
                            />
                        </div>
                    </div>
                    <div className="grow px-6 pb-32 space-y-5 custom-gray-scroll">
                        <AnimateHeight height={security.data?.pricing ? 'auto' : 0}>
                            {security.data?.pricing && (
                                <SecurityPriceChart pricing={security.data.pricing} />
                            )}
                        </AnimateHeight>

                        <dl className="grid grid-cols-2 gap-y-1 gap-x-3 text-sm text-gray-100">
                            <div className="flex items-center justify-between">
                                <dt>Open</dt>
                                <dd className="font-medium text-white">
                                    {NumberUtil.format(securityDetails.data?.day?.open, 'currency')}
                                </dd>
                            </div>
                            <div className="flex items-center justify-between">
                                <dt>Prev close</dt>
                                <dd className="font-medium text-white">
                                    {NumberUtil.format(
                                        securityDetails.data?.day?.prevClose,
                                        'currency'
                                    )}
                                </dd>
                            </div>
                            <div className="flex items-center justify-between">
                                <dt>High</dt>
                                <dd className="font-medium text-white">
                                    {NumberUtil.format(securityDetails.data?.day?.high, 'currency')}
                                </dd>
                            </div>
                            <div className="flex items-center justify-between">
                                <dt>52-wk high</dt>
                                <dd className="font-medium text-white">
                                    {NumberUtil.format(
                                        securityDetails.data?.year?.high,
                                        'currency'
                                    )}
                                </dd>
                            </div>
                            <div className="flex items-center justify-between">
                                <dt>Low</dt>
                                <dd className="font-medium text-white">
                                    {NumberUtil.format(securityDetails.data?.day?.high, 'currency')}
                                </dd>
                            </div>
                            <div className="flex items-center justify-between">
                                <dt>52-wk low</dt>
                                <dd className="font-medium text-white">
                                    {NumberUtil.format(securityDetails.data?.year?.low, 'currency')}
                                </dd>
                            </div>
                        </dl>

                        <div>
                            <h6 className="uppercase">Overview</h6>

                            <dl className="text-base mt-3 space-y-2 text-gray-100">
                                <div className="flex items-center justify-between">
                                    <dt>Holdings</dt>
                                    <dd className="font-medium text-white">
                                        {NumberUtil.format(holding.value, 'currency')}
                                    </dd>
                                </div>

                                <div className="flex items-center justify-between">
                                    <dt>Shares</dt>
                                    <dd className="font-medium text-white">
                                        {holding.quantity.toNumber()}
                                    </dd>
                                </div>

                                <div className="flex items-center justify-between">
                                    <dt>Weighting</dt>
                                    <dd className="flex items-center gap-2 font-medium text-white">
                                        {holdingInsights.data?.allocation ? (
                                            <>
                                                <FractionalCircle
                                                    percent={
                                                        holdingInsights.data.allocation.toNumber() *
                                                        100
                                                    }
                                                />
                                                <span>
                                                    {NumberUtil.format(
                                                        holdingInsights.data.allocation,
                                                        'percent',
                                                        { signDisplay: 'never' }
                                                    )}
                                                </span>
                                            </>
                                        ) : (
                                            <span className="text-gray-100">--</span>
                                        )}
                                    </dd>
                                </div>

                                <div>
                                    <div className="flex items-center justify-between">
                                        <dt>Average Cost</dt>
                                        <dd className="flex items-center font-medium text-white">
                                            {NumberUtil.format(
                                                holding.costBasis?.dividedBy(holding.quantity),
                                                'currency'
                                            )}
                                            <span className="ml-1 text-base text-gray-100">
                                                per share
                                            </span>
                                            <RiPencilLine
                                                className="w-5 h-5 text-gray-50 ml-2 mb-0.5 cursor-pointer hover:text-gray-100"
                                                onClick={() => setIsEditingCost((prev) => !prev)}
                                            />
                                        </dd>
                                    </div>

                                    <AnimatePresence>
                                        {isEditingCost && (
                                            <motion.div
                                                className="bg-gray-600 rounded-lg p-3 my-2"
                                                initial={{ opacity: 0 }}
                                                animate={{ opacity: 1 }}
                                                exit={{ opacity: 0 }}
                                            >
                                                <CostBasisForm
                                                    isEstimate={!holding.costBasisProvider}
                                                    defaultValues={
                                                        holding.costBasisUser
                                                            ? {
                                                                  type: 'manual',
                                                                  costBasisUser:
                                                                      holding.costBasisUser
                                                                          .dividedBy(
                                                                              holding.quantity
                                                                          )
                                                                          .toNumber(),
                                                              }
                                                            : {
                                                                  type: 'calculated',
                                                                  costBasisUser: null,
                                                              }
                                                    }
                                                    onSubmit={async (data) => {
                                                        await updateHolding.mutate({
                                                            id: holding.id,
                                                            data: {
                                                                costBasisUser:
                                                                    data.type === 'manual'
                                                                        ? data.costBasisUser *
                                                                          holding.quantity.toNumber()
                                                                        : null,
                                                            },
                                                        })

                                                        setIsEditingCost(false)
                                                    }}
                                                    onClose={() => setIsEditingCost(false)}
                                                />
                                            </motion.div>
                                        )}
                                    </AnimatePresence>
                                </div>

                                <div className="flex items-center justify-between">
                                    <dt>Daily gain</dt>
                                    <dd className="font-medium text-white">
                                        {holding.trend.today ? (
                                            <TrendBadge
                                                trend={holding.trend.today}
                                                badgeSize="sm"
                                                amountSize="md"
                                                displayAmount
                                            />
                                        ) : (
                                            '--'
                                        )}
                                    </dd>
                                </div>

                                <div className="flex items-center justify-between">
                                    <dt>Total gain</dt>
                                    <dd className="font-medium text-white">
                                        {holding.trend.total ? (
                                            <TrendBadge
                                                trend={holding.trend.total}
                                                badgeSize="sm"
                                                amountSize="md"
                                                displayAmount
                                            />
                                        ) : (
                                            '--'
                                        )}
                                    </dd>
                                </div>

                                <div className="flex items-center justify-between">
                                    <dt>Dividend yield</dt>
                                    <dd className="font-medium text-white">
                                        {NumberUtil.format(
                                            securityDetails?.data?.year?.dividends?.dividedBy(
                                                holding.price
                                            ),
                                            'percent',
                                            {
                                                signDisplay: 'auto',
                                                maximumFractionDigits: 2,
                                            }
                                        )}
                                    </dd>
                                </div>

                                <div className="flex items-center justify-between">
                                    <dt>Total dividend income</dt>
                                    <dd className="font-medium text-white">
                                        {holdingInsights?.data?.dividends ? (
                                            NumberUtil.format(
                                                holdingInsights?.data?.dividends
                                                    ?.negated()
                                                    .toNumber(),
                                                'currency'
                                            )
                                        ) : (
                                            <span className="text-gray-100">--</span>
                                        )}
                                    </dd>
                                </div>
                            </dl>
                        </div>

                        <div>
                            <h6 className="uppercase">Market</h6>

                            <dl className="text-base mt-3 space-y-2 text-gray-100">
                                <div className="flex items-center justify-between">
                                    <dt className="flex items-center">
                                        P/E ratio
                                        <Tooltip
                                            content={
                                                <div className="text-base text-gray-50">
                                                    Approximated from most recent quarterly EPS
                                                    value
                                                </div>
                                            }
                                        >
                                            <span>
                                                <RiInformationLine className="w-4 h-4 text-gray-50 mx-1.5" />
                                            </span>
                                        </Tooltip>
                                    </dt>
                                    <dd className="font-medium text-white">
                                        {securityDetails.data?.eps?.isPositive()
                                            ? holding.price
                                                  .dividedBy(securityDetails.data.eps.times(4))
                                                  .toFixed(2)
                                            : '--'}
                                    </dd>
                                </div>
                                <div className="flex items-center justify-between">
                                    <dt className="flex items-center">
                                        Earnings per share
                                        <Tooltip
                                            content={
                                                <div className="text-base text-gray-50">
                                                    Most recent quarterly value
                                                </div>
                                            }
                                        >
                                            <span>
                                                <RiQuestionLine className="w-4 h-4 text-gray-50 mx-1.5" />
                                            </span>
                                        </Tooltip>
                                    </dt>
                                    <dd className="font-medium text-white">
                                        {securityDetails.data?.eps?.toFixed(2) ?? '--'}
                                    </dd>
                                </div>
                                <div className="flex items-center justify-between">
                                    <dt>Average volume</dt>
                                    <dd className="font-medium text-white">
                                        {NumberUtil.format(
                                            securityDetails.data?.year?.volume?.dividedBy(52 * 5),
                                            'short-decimal'
                                        )}
                                    </dd>
                                </div>
                                <div className="flex items-center justify-between">
                                    <dt>Market cap</dt>
                                    <dd className="font-medium text-white">
                                        {NumberUtil.format(
                                            securityDetails?.data?.marketCap,
                                            'short-currency'
                                        )}
                                    </dd>
                                </div>
                            </dl>
                        </div>

                        <div className="p-3 rounded-lg bg-gray-700">
                            <label className="flex items-center justify-between text-base">
                                Exclude from chart and insights
                                <Toggle
                                    checked={excluded}
                                    onChange={onExcludedChange}
                                    size="small"
                                />
                            </label>
                        </div>
                    </div>
                </>
            )}
        </div>
    )
}

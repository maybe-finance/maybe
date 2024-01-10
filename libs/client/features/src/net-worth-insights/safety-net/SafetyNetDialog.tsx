import type { Prisma } from '@prisma/client'
import { Dialog } from '@maybe-finance/design-system'
import { NumberUtil } from '@maybe-finance/shared'
import { useState } from 'react'
import { RiCloseFill } from 'react-icons/ri'
import SafetyNetOpportunityCost from './SafetyNetOpportunityCost'
import SliderBlock from './SliderBlock'

type SafetyNetDialogProps = {
    isOpen: boolean
    onClose: () => void
    monthValue: Prisma.Decimal
    liquidAssets: Prisma.Decimal
}

export default function SafetyNetDialog({
    isOpen,
    onClose,
    monthValue,
    liquidAssets,
}: SafetyNetDialogProps) {
    const [safetyNetMonths, setSafetyNetMonths] = useState(monthValue.toNumber())
    const [potentialReturns, setPotentialReturns] = useState(8)
    const [costLiving, setCostLiving] = useState(3)

    return (
        <Dialog isOpen={isOpen} onClose={onClose} showCloseButton={false} size="lg">
            <Dialog.Content>
                <div className="flex items-center justify-between mb-2">
                    <h6 className="uppercase text-gray-100">tip</h6>
                    <span className="cursor-pointer" onClick={onClose}>
                        <RiCloseFill className="w-5 h-5 text-gray-50 hover:opacity-80" />
                    </span>
                </div>

                <h4>Make that extra cash in hand work for you</h4>
                <p className="text-base text-gray-50">
                    While{' '}
                    <span className="text-white font-medium">{monthValue.toFixed()} months</span> of
                    emergency funds is very healthy, too much cash on hand can be costly since it's
                    not working for you and may be potentially losing its value in an environment
                    where cost of living is rising.
                </p>

                <SliderBlock
                    value={safetyNetMonths}
                    onChange={setSafetyNetMonths}
                    minValue={1}
                    maxValue={48}
                    formatFn={(months: number, minMonths?: number, maxMonths?: number) => {
                        if (maxMonths && months >= maxMonths) {
                            return `${months}+ months`
                        }

                        return `${months} month${months !== 1 ? 's' : ''}`
                    }}
                    title="Safety net"
                    info="This represents how many months you can survive on no additional income based on how much you spend right now."
                />

                <div className="flex flex-col sm:flex-row items-center gap-3">
                    <SliderBlock
                        className="basis-1/2"
                        value={potentialReturns}
                        onChange={setPotentialReturns}
                        minValue={0}
                        maxValue={50}
                        formatFn={(percent: number) => NumberUtil.format(percent / 100, 'percent')}
                        title="Potential returns"
                        info="This is the rate of return that you believe you could get with your extra money (for example, investing in US Treasury bonds)"
                    />

                    <SliderBlock
                        className="basis-1/2"
                        value={costLiving}
                        onChange={setCostLiving}
                        minValue={0}
                        maxValue={50}
                        formatFn={(percent: number) => NumberUtil.format(percent / 100, 'percent')}
                        title="Cost of living increase"
                        info="This represents the rate in which you believe your cost of living will increase annually.  Generally, you would use the US inflation rate, which the Federal Reserve targets around 2% each year."
                    />
                </div>

                <SafetyNetOpportunityCost
                    lostEarnings={liquidAssets
                        .times(safetyNetMonths)
                        .dividedBy(monthValue)
                        .times(costLiving / 100)}
                    potentialEarnings={liquidAssets
                        .times(safetyNetMonths)
                        .dividedBy(monthValue)
                        .times(potentialReturns / 100)}
                />
            </Dialog.Content>
        </Dialog>
    )
}

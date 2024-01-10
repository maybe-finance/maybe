import type { Prisma } from '@prisma/client'
import { NumberUtil } from '@maybe-finance/shared'

export default function SafetyNetOpportunityCost({
    lostEarnings,
    potentialEarnings,
}: {
    lostEarnings: Prisma.Decimal
    potentialEarnings: Prisma.Decimal
}) {
    return (
        <div className="text-base text-gray-100 mt-4">
            <p>Based on the figures above and the value of your assets:</p>
            <div className="flex flex-col sm:flex-row items-center gap-3 mt-2">
                <div className="bg-gray-600 rounded-lg p-3 w-full basis-1/2">
                    <p>You're currently losing</p>
                    <h3 className="text-red">
                        {NumberUtil.format(lostEarnings, 'short-currency', {
                            minimumFractionDigits: 2,
                            maximumFractionDigits: 2,
                        })}
                    </h3>
                    <p>every year</p>
                </div>
                <div className="bg-gray-600 rounded-lg p-3 w-full basis-1/2">
                    <p>You could be making</p>
                    <h3 className="text-teal">
                        {NumberUtil.format(potentialEarnings, 'short-currency', {
                            minimumFractionDigits: 2,
                            maximumFractionDigits: 2,
                        })}
                    </h3>
                    <p>every year</p>
                </div>
            </div>
        </div>
    )
}

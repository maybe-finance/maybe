import type { ReactNode } from 'react'
import {
    RiAddLine as PlusIcon,
    RiSubtractLine as MinusIcon,
    RiPercentLine as PercentIcon,
    RiArrowUpLine as UpArrowIcon,
    RiArrowDownLine as DownArrowIcon,
    RiArrowRightUpLine as UpRightArrowIcon,
    RiArrowRightDownLine as DownRightArrowIcon,
    RiCloseLine as XIcon,
    RiCoinLine as CoinIcon,
} from 'react-icons/ri'
import { NumberUtil } from '@maybe-finance/shared'
import type { SharedType } from '@maybe-finance/shared'

const Em = ({ children }: { children: ReactNode }) => (
    <em className="not-italic text-gray-25">{children}</em>
)

export function InvestmentTransactionListItem({
    transaction,
}: {
    transaction: SharedType.AccountInvestmentTransaction
}) {
    const isPositive = transaction.amount.isPositive()

    const iconColor =
        transaction.category === 'buy' ||
        transaction.category === 'sell' ||
        transaction.category === 'dividend'
            ? { buy: 'text-teal', sell: 'text-red', dividend: 'text-teal' }[transaction.category]
            : 'text-white'

    const Icon = {
        buy: PlusIcon,
        sell: MinusIcon,
        dividend: PercentIcon,
        transfer:
            transaction.securityId == null
                ? isPositive
                    ? UpArrowIcon
                    : DownArrowIcon
                : isPositive
                ? DownRightArrowIcon
                : UpRightArrowIcon,
        tax: CoinIcon,
        fee: CoinIcon,
        cancel: XIcon,
        other: null,
    }[transaction.category]

    return (
        <tr>
            <td className="flex items-center py-4 pl-4">
                <div className="relative">
                    <div
                        className={`relative flex items-center justify-center w-12 h-12 rounded-xl overflow-hidden ${iconColor}`}
                    >
                        {/* Use absolute element for background because we can't use bg-opacity with bg-current */}
                        <div className="absolute w-full h-full bg-current opacity-10"></div>

                        {Icon && <Icon className={`w-5 h-5`} />}
                    </div>
                </div>
                <div className="ml-4 text-white font-normal">
                    {(() => {
                        const { category, security, amount, price } = transaction
                        const quantity = transaction.quantity.abs()

                        switch (category) {
                            case 'buy':
                            case 'sell':
                                return (
                                    <>
                                        {security?.name ?? transaction.name}
                                        <div className="text-gray-100">
                                            {category === 'buy' ? 'Bought ' : 'Sold '}
                                            <Em>
                                                {quantity.toDecimalPlaces(2).toNumber()}{' '}
                                                {security?.sharesPerContract == null
                                                    ? 'share'
                                                    : 'contract'}
                                                {!quantity.equals(1) && 's'}
                                            </Em>{' '}
                                            at{' '}
                                            <Em>
                                                {NumberUtil.format(price, 'currency')}
                                                {!quantity.equals(1) && ' each'}
                                            </Em>
                                        </div>
                                    </>
                                )
                            case 'dividend':
                                return (
                                    <>
                                        {security?.name ?? transaction.name}
                                        <div className="text-gray-100">
                                            Received{' '}
                                            <Em>{NumberUtil.format(amount, 'currency')}</Em> in
                                            dividends
                                        </div>
                                    </>
                                )
                            case 'transfer': {
                                const hasSecurity = security != null
                                return (
                                    <>
                                        {hasSecurity
                                            ? isPositive
                                                ? 'Received'
                                                : 'Sent'
                                            : isPositive
                                            ? 'Deposit'
                                            : 'Withdrawal'}
                                        <div className="text-gray-100">
                                            {hasSecurity ? (
                                                <>
                                                    {isPositive ? 'Received' : 'Sent'}{' '}
                                                    <Em>{NumberUtil.format(amount, 'currency')}</Em>{' '}
                                                    in holdings
                                                </>
                                            ) : (
                                                <>
                                                    {isPositive ? 'Deposited' : 'Withdrew'}{' '}
                                                    <Em>{NumberUtil.format(amount, 'currency')}</Em>{' '}
                                                    {isPositive ? 'into' : 'from'} account
                                                </>
                                            )}
                                        </div>
                                    </>
                                )
                            }
                            case 'fee':
                                return (
                                    <>
                                        {transaction.name}
                                        <div className="text-gray-100">
                                            Incurred a fee of{' '}
                                            <Em>{NumberUtil.format(amount, 'currency')}</Em>
                                        </div>
                                    </>
                                )
                        }

                        return <div>{transaction.name}</div>
                    })()}
                </div>
            </td>
            <td className="pr-4 md:pl-8 lg:pl-16 text-right font-semibold tabular-nums">
                {NumberUtil.format(
                    // Negate a buy transaction to keep it positive
                    transaction.amount.times(transaction.category === 'buy' ? -1 : 1),
                    'currency'
                )}
            </td>
        </tr>
    )
}

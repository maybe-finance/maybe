import type { IconType } from 'react-icons'
import type { BoxIconVariant } from '@maybe-finance/client/shared'

import {
    RiBankLine,
    RiBitCoinLine,
    RiCarLine,
    RiFolderLine,
    RiHome2Line,
    RiLineChartLine,
} from 'react-icons/ri'
import { BoxIcon } from '@maybe-finance/client/shared'

export type AccountSelectorView =
    | 'default'
    | 'search'
    | 'banks'
    | 'brokerages'
    | 'crypto'
    | 'manual'
    | 'property-form'
    | 'vehicle-form'

function AccountTypeGridItem({
    icon,
    variant,
    title,
    type,
    onClick,
}: {
    icon: IconType
    variant: BoxIconVariant
    title: string
    type: AccountSelectorView
    onClick: (view: AccountSelectorView) => void
}) {
    return (
        <div
            className="flex flex-col items-center justify-between p-4 bg-gray-600 rounded-xl cursor-pointer hover:bg-gray-500 "
            onClick={() => onClick(type)}
            data-testid={`${type}-add-account`}
        >
            <BoxIcon icon={icon} variant={variant} />
            <p className="text-base mt-4">{title}</p>
        </div>
    )
}

const items = [
    {
        type: 'banks',
        title: 'Bank account',
        icon: RiBankLine,
        variant: 'blue',
    },
    {
        type: 'crypto',
        title: 'Crypto',
        icon: RiBitCoinLine,
        variant: 'orange',
    },
    {
        type: 'brokerages',
        title: 'Investment',
        icon: RiLineChartLine,
        variant: 'teal',
    },
    {
        type: 'vehicle-form',
        title: 'Vehicle',
        icon: RiCarLine,
        variant: 'grape',
    },
    {
        type: 'property-form',
        title: 'Real estate',
        icon: RiHome2Line,
        variant: 'pink',
    },
    {
        type: 'manual',
        title: 'Manual account',
        icon: RiFolderLine,
        variant: 'yellow',
    },
]

export function AccountTypeGrid({ onChange }: { onChange: (view: AccountSelectorView) => void }) {
    return (
        <div className="grid grid-cols-2 gap-4">
            {items.map((item) => (
                <AccountTypeGridItem
                    key={item.title}
                    type={item.type as AccountSelectorView}
                    title={item.title}
                    variant={item.variant as BoxIconVariant}
                    icon={item.icon}
                    onClick={onChange}
                />
            ))}
        </div>
    )
}

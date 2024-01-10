import type { ValuationRowData } from './types'
import type { IconType } from 'react-icons'
import { useMemo } from 'react'
import { useValuationApi, useUserAccountContext } from '@maybe-finance/client/shared'
import { Button, Tooltip } from '@maybe-finance/design-system'
import classNames from 'classnames'
import { RiPriceTag3Line, RiKeyboardBoxLine, RiArrowUpLine, RiArrowDownLine } from 'react-icons/ri'
import { RiSubtractFill } from 'react-icons/ri'
import type { Row } from '@tanstack/react-table'

export function ValuationsDateCell({
    row,
    onEdit,
}: {
    row: Row<ValuationRowData>
    onEdit(rowId?: number): void
}) {
    const data = row.original!
    const { useDeleteValuation } = useValuationApi()
    const deleteQuery = useDeleteValuation()
    const { accountSyncing } = useUserAccountContext()

    const { canEdit, canDelete, label, icon } = useMemo(() => {
        const label =
            data.type === 'initial'
                ? 'Manually entered'
                : data.type === 'trend'
                ? 'Yearly trend'
                : 'Manually entered'

        let icon: React.ReactNode

        if (data.type === 'initial') {
            icon = <ValuationIcon className="bg-cyan text-cyan" Icon={RiPriceTag3Line} />
        } else if (data.type === 'manual') {
            icon = <ValuationIcon className="bg-pink text-pink" Icon={RiKeyboardBoxLine} />
        } else if (data.type === 'trend') {
            const { direction } = data.period
            if (direction === 'up') {
                icon = <ValuationIcon className="bg-teal text-teal" Icon={RiArrowUpLine} />
            }

            if (direction === 'down') {
                icon = <ValuationIcon className="bg-red text-red" Icon={RiArrowDownLine} />
            }

            if (direction === 'flat') {
                icon = <ValuationIcon className="bg-white text-gray-100" Icon={RiSubtractFill} />
            }
        } else {
            icon = <ValuationIcon className="bg-pink text-pink" Icon={RiKeyboardBoxLine} />
        }

        return {
            canEdit: data.type === 'manual',
            canDelete: data.type === 'manual',
            label,
            icon,
        }
    }, [data])

    return (
        <div className="group w-full h-full flex text-base gap-4">
            {icon}
            <div>
                <p>{data.date.toFormat('MMM d yyyy')}</p>
                <p className="text-gray-100 text-base">{label}</p>
            </div>
            <div className="hidden group-hover:flex">
                {canEdit && !accountSyncing(data.accountId || 0) && (
                    <Tooltip content="Edit" placement="bottom" offset={[0, 4]}>
                        <Button
                            className="ml-4 w-8"
                            variant="icon"
                            onClick={() => onEdit(row.index)}
                        >
                            <i className="ri-pencil-line text-gray-100 w-8" />
                        </Button>
                    </Tooltip>
                )}
                {canDelete && !accountSyncing(data.accountId || 0) && (
                    <Tooltip content="Delete" placement="bottom" offset={[0, 4]}>
                        <Button
                            className="ml-2 w-8"
                            variant="icon"
                            onClick={() =>
                                deleteQuery.mutate(
                                    {
                                        id: data.valuationId!,
                                    },
                                    {
                                        onSuccess: () => onEdit(),
                                    }
                                )
                            }
                        >
                            <i className="ri-delete-bin-line text-gray-100 w-8" />
                        </Button>
                    </Tooltip>
                )}
            </div>
        </div>
    )
}

function ValuationIcon({ className, Icon }: { className: string; Icon: IconType }) {
    return (
        <div
            className={classNames(
                'flex items-center justify-center rounded-xl bg-opacity-10 w-12 h-12',
                className
            )}
        >
            <Icon className="w-6 h-6" />
        </div>
    )
}

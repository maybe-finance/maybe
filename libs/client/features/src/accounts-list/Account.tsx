import type { SharedType } from '@maybe-finance/shared'
import cn from 'classnames'
import { Button, Menu, Toggle, Tooltip } from '@maybe-finance/design-system'
import { useAccountApi, useAccountContext } from '@maybe-finance/client/shared'
import { NumberUtil, AccountUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { useCallback, useEffect, useMemo, useState } from 'react'
import debounce from 'lodash/debounce'

type AccountProps = {
    account: SharedType.Account
    readonly?: boolean
    onEdit?(): void
    editLabel?: string
    canDelete?: boolean
    showAccountDescription?: boolean
}

export default function Account({
    account,
    readonly = false,
    onEdit,
    editLabel = 'Edit',
    canDelete = false,
    showAccountDescription = true,
}: AccountProps) {
    const { useSyncAccount, useAccountBalances } = useAccountApi()

    const { deleteAccount } = useAccountContext()

    const syncAccount = useSyncAccount()
    const accountBalancesQuery = useAccountBalances({
        id: account.id,
        start: DateTime.now().toISODate(),
        end: DateTime.now().toISODate(),
    })

    let accountTypeName = AccountUtil.getAccountTypeName(account.category, account.subcategory)
    accountTypeName = accountTypeName
        ? accountTypeName.charAt(0).toUpperCase() + accountTypeName.slice(1)
        : null

    const renderAccountDescription = () => {
        if (!showAccountDescription) return null

        if (!accountTypeName && !account.mask) return null

        return (
            <div className="text-base text-gray-100 truncate">
                {accountTypeName ?? 'Account'}
                {account.mask && <>&nbsp;ending in &#183;&#183;&#183;&#183; {account.mask}</>}
            </div>
        )
    }

    return (
        <li className="px-3 py-4 flex items-center space-x-4">
            <AccountToggle account={account} disabled={readonly} />
            <div className="flex-1 min-w-0 flex items-center space-x-3 group">
                <div
                    className={cn(
                        'text-base leading-normal overflow-x-hidden',
                        !account.isActive && 'text-gray-100'
                    )}
                >
                    <div className="truncate">{account.name}</div>
                    {renderAccountDescription()}
                </div>
                <div className="hidden group-hover:flex group-focus-within:flex items-center space-x-1">
                    {onEdit && (
                        <Tooltip content={editLabel} placement="bottom" offset={[0, 4]}>
                            <Button variant="icon" onClick={onEdit} disabled={readonly}>
                                <i className="ri-pencil-line text-gray-100" />
                            </Button>
                        </Tooltip>
                    )}
                    {canDelete && (
                        <Tooltip content="Delete" placement="bottom" offset={[0, 4]}>
                            <Button
                                variant="icon"
                                onClick={() => deleteAccount(account)}
                                disabled={readonly}
                            >
                                <i className="ri-delete-bin-line text-gray-100" />
                            </Button>
                        </Tooltip>
                    )}
                    {process.env.NODE_ENV === 'development' && (
                        <Menu>
                            <Menu.Button variant="icon">
                                <i className="ri-tools-fill text-red" />
                            </Menu.Button>
                            <Menu.Items placement="bottom-end">
                                <Menu.Item
                                    destructive
                                    onClick={() => syncAccount.mutate(account.id)}
                                >
                                    Sync
                                </Menu.Item>
                            </Menu.Items>
                        </Menu>
                    )}
                </div>
            </div>
            {accountBalancesQuery.data ? (
                <span
                    className={cn('font-semibold text-base', !account.isActive && 'text-gray-200')}
                >
                    {NumberUtil.format(accountBalancesQuery.data.today?.balance, 'currency')}
                </span>
            ) : (
                <span className="text-gray-200 animate-pulse">...</span>
            )}
        </li>
    )
}

function AccountToggle({
    account,
    disabled,
}: {
    account: SharedType.Account
    disabled: boolean
}): JSX.Element {
    const { useUpdateAccount } = useAccountApi()
    const { mutateAsync } = useUpdateAccount()

    const [isActive, setIsActive] = useState(account.isActive)

    useEffect(() => setIsActive(account.isActive), [account.isActive])

    const debouncedMutate = useMemo(
        () =>
            debounce(async (checked: boolean) => {
                try {
                    await mutateAsync({
                        id: account.id,
                        data: { data: { isActive: checked } },
                    })
                } catch (e) {
                    setIsActive(!checked)
                }
            }, 500),
        [mutateAsync, account.id]
    )

    const onChange = useCallback(
        (checked: boolean) => {
            setIsActive(checked)
            debouncedMutate(checked)
        },
        [debouncedMutate]
    )

    return (
        <Toggle
            screenReaderLabel="Toggle account"
            onChange={onChange}
            checked={isActive}
            disabled={disabled}
        />
    )
}

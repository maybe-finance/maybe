import type { SharedType } from '@maybe-finance/shared'
import { BrowserUtil, useAccountApi, useAccountContext } from '@maybe-finance/client/shared'
import { Menu } from '@maybe-finance/design-system'
import { RiDeleteBin5Line, RiPencilLine, RiRefreshLine } from 'react-icons/ri'
import { useRouter } from 'next/router'
import { useAuth0 } from '@auth0/auth0-react'

type Props = {
    account?: SharedType.AccountDetail
}

export function AccountMenu({ account }: Props) {
    const { user } = useAuth0()
    const { editAccount, deleteAccount } = useAccountContext()
    const { useSyncAccount } = useAccountApi()

    const router = useRouter()
    const syncAccount = useSyncAccount()

    if (!account) return null

    return (
        <Menu data-testid="account-menu">
            <Menu.Button variant="icon" data-testid="account-menu-btn">
                <i className="ri-more-2-fill text-white" />
            </Menu.Button>
            <Menu.Items placement="bottom-end">
                <Menu.Item icon={<RiPencilLine />} onClick={() => editAccount(account)}>
                    Edit
                </Menu.Item>
                {BrowserUtil.hasRole(user, 'Admin') && (
                    <Menu.Item
                        icon={<RiRefreshLine />}
                        destructive
                        onClick={() => syncAccount.mutate(account.id)}
                    >
                        Sync
                    </Menu.Item>
                )}
                {!account.accountConnectionId && (
                    <Menu.Item
                        icon={<RiDeleteBin5Line />}
                        destructive
                        onClick={() => deleteAccount(account, () => router.push('/'))}
                    >
                        Delete
                    </Menu.Item>
                )}
            </Menu.Items>
        </Menu>
    )
}

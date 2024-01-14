import type { SharedType } from '@maybe-finance/shared'
import { useAccountContext } from '@maybe-finance/client/shared'
import { Menu } from '@maybe-finance/design-system'
import { RiDeleteBin5Line, RiPencilLine } from 'react-icons/ri'
import { useRouter } from 'next/router'

type Props = {
    account?: SharedType.AccountDetail
}

export function AccountMenu({ account }: Props) {
    const { editAccount, deleteAccount } = useAccountContext()
    const router = useRouter()

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

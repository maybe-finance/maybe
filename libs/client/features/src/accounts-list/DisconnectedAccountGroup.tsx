import type { SharedType } from '@maybe-finance/shared'
import { Menu } from '@maybe-finance/design-system'
import Account from './Account'
import { AccountGroup } from './AccountGroup'
import { RiMore2Fill, RiLink } from 'react-icons/ri'
import { FaRegTrashAlt } from 'react-icons/fa'
import { DeleteConnectionDialog } from './DeleteConnectionDialog'
import { useState } from 'react'
import { useAccountConnectionApi, useLastUpdated } from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'

type DisconnectedAccountGroupProps = {
    connection: SharedType.ConnectionWithAccounts
}

export function DisconnectedAccountGroup({ connection }: DisconnectedAccountGroupProps) {
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

    const { useReconnectConnection } = useAccountConnectionApi()
    const reconnect = useReconnectConnection()

    const lastUpdatedString = useLastUpdated(DateTime.fromJSDate(connection.updatedAt))

    return (
        <>
            <AccountGroup
                title={connection.name}
                subtitle={lastUpdatedString}
                content={
                    <ul>
                        {connection.accounts.map((account) => (
                            <Account key={account.id} account={account} readonly />
                        ))}
                    </ul>
                }
                menu={
                    <Menu>
                        <Menu.Button variant="icon">
                            <RiMore2Fill />
                        </Menu.Button>
                        <Menu.Items placement="bottom-end">
                            <Menu.Item
                                icon={<RiLink />}
                                onClick={() => reconnect.mutate(connection.id)}
                            >
                                Reconnect account
                            </Menu.Item>
                            <Menu.Item
                                icon={<FaRegTrashAlt />}
                                destructive
                                onClick={() => setDeleteDialogOpen(true)}
                            >
                                Delete permanently
                            </Menu.Item>
                        </Menu.Items>
                    </Menu>
                }
            />

            <DeleteConnectionDialog
                connection={connection}
                isOpen={deleteDialogOpen}
                onClose={() => setDeleteDialogOpen(false)}
            />
        </>
    )
}

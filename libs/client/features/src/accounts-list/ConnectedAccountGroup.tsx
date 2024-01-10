import { useCallback } from 'react'
import { Button, Menu } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import Account from './Account'
import { AccountGroup } from './AccountGroup'
import { RiLinkUnlink as UnlinkIcon, RiRefreshLine, RiHistoryLine } from 'react-icons/ri'
import {
    useAccountConnectionApi,
    useAccountContext,
    useAxiosWithAuth,
    useLastUpdated,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import { AiOutlineSync, AiOutlineExclamationCircle } from 'react-icons/ai'
import { RiDownloadLine } from 'react-icons/ri'
import PlaidLinkUpdateButton from './PlaidLinkUpdateButton'

export interface ConnectedAccountGroupProps {
    connection: SharedType.ConnectionWithAccounts
}

export function ConnectedAccountGroup({ connection }: ConnectedAccountGroupProps) {
    const { axios } = useAxiosWithAuth()

    const { editAccount } = useAccountContext()

    const {
        useDisconnectConnection,
        useSyncConnection,
        usePlaidLinkUpdateCompleted,
        useDeleteConnection,
        useUpdateConnection,
    } = useAccountConnectionApi()

    const disconnectConnection = useDisconnectConnection()
    const deleteConnection = useDeleteConnection()
    const syncConnection = useSyncConnection()
    const updateConnection = useUpdateConnection()
    const plaidLinkUpdateCompleted = usePlaidLinkUpdateCompleted(connection.id)

    const onLinkUpdateSuccess = useCallback(() => {
        plaidLinkUpdateCompleted.mutate('success')
    }, [plaidLinkUpdateCompleted])

    const onLinkUpdateExit = useCallback(() => {
        plaidLinkUpdateCompleted.mutate('exit')
    }, [plaidLinkUpdateCompleted])

    const hasNewAccountsAvailable = connection.plaidNewAccountsAvailable
    const hasLoginError =
        connection.status === 'ERROR' &&
        (connection.plaidConsentExpiration ||
            (connection.plaidError as any)?.error_code === 'ITEM_LOGIN_REQUIRED')

    const { status, message } = useAccountConnectionStatus(connection)

    return (
        <AccountGroup
            title={connection.name}
            subtitle={status}
            content={
                connection.accounts.length > 0 ? (
                    <ul>
                        {connection.accounts.map((account) => (
                            <Account
                                key={account.id}
                                account={account}
                                onEdit={() => editAccount(account)}
                                editLabel="Edit"
                            />
                        ))}
                    </ul>
                ) : (
                    <p className="py-4 px-3 text-gray-100 text-sm">
                        {connection.syncStatus === 'PENDING' || connection.syncStatus === 'SYNCING'
                            ? 'Your accounts are currently syncing. Please check back later.'
                            : 'No accounts found. Try syncing again.'}
                    </p>
                )
            }
            menu={
                <>
                    {process.env.NODE_ENV === 'development' && (
                        <Menu>
                            <Menu.Button variant="icon">
                                <i className="ri-tools-fill text-red" />
                            </Menu.Button>
                            <Menu.Items placement="bottom-end">
                                <Menu.Item
                                    destructive
                                    onClick={() => {
                                        axios.post(
                                            `/connections/${connection.id}/plaid/sandbox/item-reset-login`
                                        )
                                    }}
                                >
                                    Reset Login
                                </Menu.Item>
                                <Menu.Item
                                    destructive
                                    onClick={() =>
                                        axios.post(
                                            `/connections/${connection.id}/plaid/sandbox/fire-webhook`
                                        )
                                    }
                                >
                                    Fire Webhook
                                </Menu.Item>
                                <Menu.Item
                                    destructive
                                    onClick={() =>
                                        axios.post(`/connections/${connection.id}/sync/balances`)
                                    }
                                >
                                    Sync Balances
                                </Menu.Item>
                                <Menu.Item
                                    destructive
                                    onClick={() =>
                                        axios.post(`/connections/${connection.id}/sync/investments`)
                                    }
                                >
                                    Sync Investments
                                </Menu.Item>
                                <Menu.Item
                                    destructive
                                    onClick={() => deleteConnection.mutate(connection.id)}
                                >
                                    Delete permanently
                                </Menu.Item>
                            </Menu.Items>
                        </Menu>
                    )}
                    <Menu>
                        <Menu.Button variant="icon">
                            <i className="ri-more-2-fill text-white" />
                        </Menu.Button>
                        <Menu.Items placement="bottom-end">
                            <Menu.Item
                                icon={<UnlinkIcon />}
                                destructive
                                onClick={() => disconnectConnection.mutate(connection.id)}
                            >
                                Disconnect account
                            </Menu.Item>
                        </Menu.Items>
                    </Menu>
                </>
            }
            footer={
                <div className="flex items-center space-x-2">
                    <div className="grow">{message}</div>
                    <div className="flex items-center space-x-4">
                        {connection.syncStatus === 'IDLE' && hasLoginError ? (
                            <PlaidLinkUpdateButton
                                accountConnectionId={connection.id}
                                onSuccess={onLinkUpdateSuccess}
                                onExit={onLinkUpdateExit}
                                mode="reconnect"
                            />
                        ) : connection.syncStatus === 'IDLE' && hasNewAccountsAvailable ? (
                            <PlaidLinkUpdateButton
                                accountConnectionId={connection.id}
                                onSuccess={onLinkUpdateSuccess}
                                onExit={onLinkUpdateExit}
                                mode="new-accounts"
                            />
                        ) : null}

                        {/* Provide user a fallback if their connection gets "stuck" in the syncing state */}
                        {connection.syncStatus !== 'IDLE' && (
                            <Button
                                variant="secondary"
                                onClick={async () => {
                                    await updateConnection.mutateAsync({
                                        id: connection.id,
                                        data: { syncStatus: 'IDLE' },
                                    })
                                }}
                            >
                                Cancel
                            </Button>
                        )}

                        <Button
                            variant="secondary"
                            onClick={() => syncConnection.mutate(connection.id)}
                            disabled={syncConnection.isLoading || connection.syncStatus !== 'IDLE'}
                        >
                            {syncConnection.isLoading || connection.syncStatus !== 'IDLE' ? (
                                <div className="flex items-center space-x-2">
                                    <AiOutlineSync className="h-4 w-4 animate-spin" />
                                    <span className="animate-pulse">Syncing...</span>
                                </div>
                            ) : (
                                'Sync Account'
                            )}
                        </Button>
                    </div>
                </div>
            }
        />
    )
}

function useAccountConnectionStatus(connection: SharedType.ConnectionWithAccounts): {
    status?: React.ReactNode
    message?: React.ReactNode
} {
    const lastUpdated = useLastUpdated(DateTime.fromJSDate(connection.updatedAt))

    switch (connection.syncStatus) {
        case 'PENDING':
        case 'SYNCING': {
            return {
                status: <span className="animate-pulse">Syncing...</span>,
            }
        }
    }

    switch (connection.status) {
        case 'OK': {
            if (connection.plaidNewAccountsAvailable) {
                return {
                    status: (
                        <div className="flex items-center space-x-1 text-cyan">
                            <RiDownloadLine className="h-4 w-4" />
                            <p>Account update available</p>
                        </div>
                    ),
                    message: (
                        <div className="flex items-center space-x-2 text-white">
                            <RiHistoryLine className="h-4 w-4" />
                            <p className="text-base">
                                Since the last sync there were a few updates. Update to pull in the
                                latest account data.
                            </p>
                        </div>
                    ),
                }
            }

            return {
                status: lastUpdated,
                message: null,
            }
        }
        case 'ERROR': {
            const hasLoginError =
                connection.plaidConsentExpiration ||
                (connection.plaidError as any)?.error_code === 'ITEM_LOGIN_REQUIRED'

            return {
                status: (
                    <div className="flex items-center space-x-1 text-red-500">
                        <AiOutlineExclamationCircle className="h-4 w-4" />
                        <p>
                            {hasLoginError
                                ? 'Unable to connect your account'
                                : 'Syncing issue detected'}
                        </p>
                    </div>
                ),
                message: (
                    <div className="flex items-center space-x-2 text-red-500">
                        <RiRefreshLine className="h-4 w-4" />
                        <p className="text-base">
                            {hasLoginError
                                ? 'Please try reconnecting your account to pull in the latest account data.'
                                : 'Please try syncing again'}
                        </p>
                    </div>
                ),
            }
        }
    }

    return {}
}

'use client'

import type { ReactElement } from 'react'
import { RiAddLine } from 'react-icons/ri'

import {
    AccountGroupContainer,
    ManualAccountGroup,
    AccountDevTools,
    ConnectedAccountGroup,
    DisconnectedAccountGroup,
    WithSidebarLayout,
    AccountSidebar,
} from '@maybe-finance/client/features'
import {
    MainContentLoader,
    MainContentOverlay,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import { AccountUtil } from '@maybe-finance/shared'

export default function AccountsPage() {
    const { useAccounts } = useAccountApi()
    const { addAccount } = useAccountContext()

    const { isLoading, error, data, refetch } = useAccounts()

    if (isLoading) {
        return <MainContentLoader />
    }

    if (error || !data) {
        return (
            <MainContentOverlay
                title="Unable to load accounts"
                actionText="Try again"
                onAction={() => refetch()}
            >
                <p>
                    We&lsquo;re having some trouble loading your accounts. Please contact us{' '}
                    <a href="mailto:hello@maybe.co" className="underline text-cyan">
                        here
                    </a>{' '}
                    if the issue persists.
                </p>
            </MainContentOverlay>
        )
    }

    const { accounts, connections } = data

    const disconnected = connections.filter((c) => c.status === 'DISCONNECTED')
    const connected = connections.filter((c) => c.status !== 'DISCONNECTED')

    if (
        !isLoading &&
        disconnected.length === 0 &&
        connected.length === 0 &&
        accounts.length === 0
    ) {
        return (
            <>
                <AccountDevTools />
                <MainContentOverlay
                    title="No accounts yet"
                    actionText="Add account"
                    onAction={addAccount}
                >
                    <p>
                        You currently have no connected or manual accounts. Start by adding an
                        account.
                    </p>
                </MainContentOverlay>
            </>
        )
    }

    return (
        <div>
            <AccountDevTools />

            <div className="flex items-center justify-between">
                <h3>Accounts</h3>
                <Button onClick={addAccount} leftIcon={<RiAddLine size={20} />}>
                    Add account
                </Button>
            </div>

            <div className="mt-8 space-y-8">
                {connected.length > 0 && (
                    <AccountGroupContainer title="CONNECTED">
                        {connected.map((connection) => (
                            <ConnectedAccountGroup key={connection.id} connection={connection} />
                        ))}
                    </AccountGroupContainer>
                )}

                {accounts.length > 0 && (
                    <AccountGroupContainer title="MANUAL">
                        {AccountUtil.groupAccountsByCategory(accounts).map(
                            ({ category, subtitle, accounts }) => (
                                <ManualAccountGroup
                                    key={category}
                                    title={category}
                                    subtitle={subtitle}
                                    accounts={accounts}
                                />
                            )
                        )}
                    </AccountGroupContainer>
                )}

                {disconnected.length > 0 && (
                    <AccountGroupContainer title="DISCONNECTED">
                        {disconnected.map((connection) => (
                            <DisconnectedAccountGroup key={connection.id} connection={connection} />
                        ))}
                    </AccountGroupContainer>
                )}
            </div>
        </div>
    )
}

AccountsPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}

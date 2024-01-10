import type { PropsWithChildren, SetStateAction, Dispatch } from 'react'
import type { SharedType } from '@maybe-finance/shared'
import { createContext, useState, useContext, useEffect, useMemo } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useAccountApi } from '../api'
import toast from 'react-hot-toast'
import uniqBy from 'lodash/uniqBy'
import { useInterval } from '../hooks'
import { invalidateAccountQueries } from '../utils'

export interface UserAccountContext {
    isReady: boolean
    noAccounts: boolean
    allAccountsDisabled: boolean
    someConnectionsSyncing: boolean
    someAccountsSyncing: boolean
    accountSyncing: (accountId: SharedType.Account['id']) => boolean
    accountsSyncing: SharedType.Account[]
    connectionsSyncing: SharedType.ConnectionWithAccounts[]
    syncProgress?: SharedType.AccountSyncProgress
    expectingAccounts: boolean
    setExpectingAccounts: Dispatch<SetStateAction<boolean>>
}

export const UserAccountContext = createContext<UserAccountContext | undefined>(undefined)

export function useUserAccountContext() {
    const context = useContext(UserAccountContext)

    if (!context) {
        throw new Error('useUserAccountContext() must be used within <UserAccountContextProvider>')
    }

    return context
}

export function UserAccountContextProvider({ children }: PropsWithChildren<{}>) {
    const queryClient = useQueryClient()

    const { useAccounts } = useAccountApi()

    const [noAccounts, setNoAccounts] = useState(false)
    const [allAccountsDisabled, setAllAccountsDisabled] = useState(false)
    const [someConnectionsSyncing, setSomeConnectionsSyncing] = useState(false)
    const [someAccountsSyncing, setSomeAccountsSyncing] = useState(false)
    const [accountsSyncing, setAccountsSyncing] = useState<SharedType.Account[]>([])
    const [connectionsSyncing, setConnectionsSyncing] = useState<
        (SharedType.ConnectionWithAccounts & SharedType.ConnectionWithSyncProgress)[]
    >([])
    const [expectingAccounts, setExpectingAccounts] = useState(false)

    const syncProgress: SharedType.AccountSyncProgress | undefined = useMemo(() => {
        if (expectingAccounts) {
            return { description: 'Importing accounts', progress: 0 }
        }

        if (!connectionsSyncing.length) {
            return undefined
        }

        const allSyncProgress = connectionsSyncing
            .map(({ syncProgress }) => syncProgress)
            .filter((sp): sp is SharedType.AccountSyncProgress => sp != null)
            .sort((a, b) => Number(a.progress) - Number(b.progress) ?? 0)

        return allSyncProgress.length
            ? allSyncProgress[0]
            : { description: 'Importing accounts', progress: 0.1 }
    }, [connectionsSyncing, expectingAccounts])

    const accountsQuery = useAccounts({
        onSuccess: ({ accounts, connections }) => {
            // determine connections to show "successfully synced" notification for
            accounts
                .filter(
                    (a) => a.syncStatus === 'IDLE' && accountsSyncing.some((sc) => sc.id === a.id)
                )
                .forEach((account) => {
                    toast.success(`${account.name} synced`)
                })

            // An account is "syncing" if the account itself is syncing OR its parent connection is syncing ("implicitly syncing")
            const individualAccountsSyncing = accounts.filter((a) => a.syncStatus !== 'IDLE')
            const childAccountsSyncing = connections
                .filter((c) => c.syncStatus !== 'IDLE')
                .flatMap((c) => c.accounts)

            const newAccountsSyncing = uniqBy(
                [...individualAccountsSyncing, ...childAccountsSyncing],
                'id'
            )

            setAccountsSyncing(newAccountsSyncing)

            connections
                .filter(
                    (c) =>
                        c.syncStatus === 'IDLE' && connectionsSyncing.some((sc) => sc.id === c.id)
                )
                .forEach((connection) => {
                    connection.status === 'ERROR'
                        ? toast.error(`${connection.name} failed to sync`)
                        : toast.success(`${connection.name} synced`)
                })

            setConnectionsSyncing(
                connections.filter((c) => c.syncStatus === 'PENDING' || c.syncStatus === 'SYNCING')
            )

            setNoAccounts(
                accounts.length === 0 && connections.every((c) => c.accounts.length === 0)
            )

            const allAccountsDisabled = accounts.every((a) => !a.isActive)
            const allConnectionsDisabled = connections.every((c) =>
                c.accounts.every((a) => !a.isActive)
            )

            setAllAccountsDisabled(allAccountsDisabled && allConnectionsDisabled)

            const someConnectionsSyncing = connections.some((c) => c.syncStatus !== 'IDLE')
            const someAccountsSyncing =
                accounts.some((a) => a.syncStatus !== 'IDLE') ||
                connections.some(
                    (c) => c.syncStatus !== 'IDLE' && c.accounts.some((a) => a.isActive)
                )

            setSomeConnectionsSyncing(someConnectionsSyncing)
            setSomeAccountsSyncing(someAccountsSyncing)
        },
    })

    useInterval(
        () => invalidateAccountQueries(queryClient),
        someAccountsSyncing || someConnectionsSyncing || expectingAccounts ? 2_000 : undefined
    )

    useEffect(() => {
        if (!someAccountsSyncing) invalidateAccountQueries(queryClient)
    }, [queryClient, someAccountsSyncing])

    useEffect(
        () => setExpectingAccounts(false),
        [accountsQuery.data?.connections.length, accountsQuery.data?.accounts.length]
    )

    return (
        <UserAccountContext.Provider
            value={{
                isReady: !accountsQuery.isLoading,
                noAccounts,
                allAccountsDisabled,
                someConnectionsSyncing,
                someAccountsSyncing,
                accountSyncing: (accountId: SharedType.Account['id']) => {
                    return !!accountsSyncing.find((a) => a.id === accountId)
                },
                accountsSyncing,
                connectionsSyncing,
                syncProgress,
                expectingAccounts,
                setExpectingAccounts,
            }}
        >
            {children}
        </UserAccountContext.Provider>
    )
}

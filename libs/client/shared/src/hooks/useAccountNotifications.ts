import { useMemo } from 'react'
import { useAccountApi } from '../api'

export function useAccountNotifications() {
    const { useAccounts } = useAccountApi()
    const accountsQuery = useAccounts()

    const accountsNotification = useMemo(() => {
        if (!accountsQuery.data) return null

        if (
            accountsQuery.data.connections.some(
                (connection) =>
                    connection.status === 'ERROR' &&
                    (connection.plaidConsentExpiration || connection.plaidError)
            )
        ) {
            return 'error'
        }

        if (
            accountsQuery.data.connections.some(
                (connection) => connection.plaidNewAccountsAvailable
            )
        ) {
            return 'update'
        }

        return null
    }, [accountsQuery])

    return accountsNotification
}

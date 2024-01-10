import { useEffect, useState } from 'react'
import { usePlaidApi } from '../api'

export function useProviderStatus() {
    const { usePlaidStatus } = usePlaidApi()
    const plaidStatus = usePlaidStatus()

    const [isCollapsed, setIsCollapsed] = useState(false)
    const [statusMessage, setStatusMessage] = useState('')

    useEffect(() => {
        const plaidIndicator = plaidStatus.data?.status?.indicator

        if (plaidIndicator && plaidIndicator !== 'none') {
            setStatusMessage(
                'Plaid, one of our data providers, is experiencing downtime.  As a result, some of your accounts may not sync correctly.'
            )
        }
    }, [plaidStatus])

    return {
        isCollapsed,
        statusMessage,
        dismiss: () => setIsCollapsed(true),
        expand: () => setIsCollapsed(false),
    }
}

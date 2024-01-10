import { DateTime } from 'luxon'
import { useEffect, useState } from 'react'

export const useLastUpdated: (lastUpdated?: DateTime | Date, showPrefix?: boolean) => string = (
    lastUpdated,
    showPrefix = true
) => {
    const lastUpdatedNormalized = DateTime.isDateTime(lastUpdated)
        ? lastUpdated
        : lastUpdated
        ? DateTime.fromJSDate(lastUpdated)
        : null

    const [lastUpdateString, setLastUpdateString] = useState(lastUpdatedNormalized?.toRelative())

    useEffect(() => {
        const initialVal = lastUpdatedNormalized?.toRelative()
        setLastUpdateString(
            initialVal === '0 seconds ago'
                ? 'just now'
                : lastUpdatedNormalized?.toRelative() ?? 'Never'
        )

        const intervalRef = setInterval(() => {
            setLastUpdateString(lastUpdatedNormalized?.toRelative() ?? 'Never')
        }, 60000)

        return () => clearInterval(intervalRef)
    }, [lastUpdatedNormalized])

    return (showPrefix ? 'Updated ' : '') + lastUpdateString || ''
}
